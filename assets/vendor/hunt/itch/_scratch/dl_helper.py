"""itch.io PWYW free-asset fetcher (verified flow).

Per candidate:
  1. GET  https://<author>.itch.io/<slug>             -> get csrf_token (in <meta>)
  2. POST /<slug>/download_url (csrf)                -> session download URL
  3. GET  session URL                                -> download page (has upload_id)
  4. POST /<slug>/file/<upload_id>?as_props=1 (csrf) -> CDN URL (AWS S3 signed)
  5. GET  CDN URL                                    -> the actual zip

Output: <out>/<original_zipname>.zip + extracted/ subfolder
"""
import os, re, sys, json, time, subprocess, urllib.parse, gzip, zipfile

PROXY = "socks5h://127.0.0.1:10808"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
COOKIE_JAR = "D:/mydev/games/Tower Defense/assets/vendor/hunt/itch/_cookie/jar.txt"
SCRATCH = "D:/mydev/games/Tower Defense/assets/vendor/hunt/itch/_scratch"

def _run(cmd):
    p = subprocess.run(cmd, capture_output=True)
    body = p.stdout
    try:
        if body[:2] == b'\x1f\x8b':
            body = gzip.decompress(body)
    except Exception:
        pass
    return body, p.stderr.decode("utf-8","replace"), p.returncode

def curl_get(url, max_time=30):
    cmd = ["curl","-x",PROXY,"-sL","--max-time",str(max_time),"-A",UA,
           "-c",COOKIE_JAR,"-b",COOKIE_JAR,"-o","-", url]
    return _run(cmd)

def curl_post(url, data, max_time=30, follow=True):
    cmd = ["curl","-x",PROXY,"-sL","--max-time",str(max_time),"-A",UA,
           "-c",COOKIE_JAR,"-b",COOKIE_JAR,
           "-H","Accept: application/json"]
    for k, v in data.items():
        cmd += ["-d", f"{k}={urllib.parse.quote(str(v))}"]
    cmd += ["-o","-", url]
    return _run(cmd)

def curl_save(url, out_path, max_time=180):
    cmd = ["curl","-x",PROXY,"-sL","--max-time",str(max_time),"-A",UA,
           "-c",COOKIE_JAR,"-b",COOKIE_JAR,"-o", out_path, url]
    return _run(cmd)

def fetch_one_game(author, slug, save_dir, log_path=None):
    """Attempt full flow. Returns dict."""
    os.makedirs(save_dir, exist_ok=True)
    game_url = f"https://{author}.itch.io/{slug}"
    out = {"author":author,"slug":slug,"url":game_url,"steps":[],"files":[],"error":None,
           "page_html":None, "download_page_html":None, "license_text":None}

    def log(msg):
        line = f"[{author}/{slug}] {msg}"
        print(line)
        if log_path:
            with open(log_path,"a",encoding="utf-8") as f:
                f.write(line+"\n")

    # 1. Game page
    body, err, rc = curl_get(game_url)
    if rc != 0 or not body:
        out["error"] = f"game page rc={rc} err={err[:120]}"
        log(out["error"]); return out
    page = body.decode("utf-8","replace")
    if "just a moment" in page.lower()[:1500]:
        out["error"] = "cloudflare challenge"
        log(out["error"]); return out
    out["page_html"] = page
    # extract license description if present
    desc = re.search(r'<meta[^>]*name="description"[^>]*content="([^"]+)"', page)
    out["page_description"] = desc.group(1) if desc else ""
    out["steps"].append("got_game_page")

    # 2. Purchase page (to get csrf + check free/PWYW)
    time.sleep(1.5)
    purchase_url = f"https://{author}.itch.io/{slug}/purchase"
    body, err, rc = curl_get(purchase_url)
    if rc != 0 or not body:
        out["error"] = f"purchase rc={rc}"; log(out["error"]); return out
    ppage = body.decode("utf-8","replace")
    out["purchase_page_html"] = ppage
    if "just a moment" in ppage.lower()[:1500]:
        out["error"] = "cloudflare challenge on purchase"; log(out["error"]); return out
    out["steps"].append("got_purchase_page")

    # extract csrf
    csrf = re.search(r'<meta[^>]*name="csrf_token"[^>]*value="([^"]+)"', ppage)
    if not csrf:
        out["error"] = "no csrf (login required or not free)"; log(out["error"]); return out
    csrf = csrf.group(1)

    # detect paid-only
    price_match = re.search(r'price=\\\?"(\$[0-9.]+)"', ppage) or re.search(r'data-price="([0-9.]+)"', ppage)
    actual_price = None
    if price_match:
        actual_price = price_match.group(1)
    # check if "free" in description text
    is_free = ('free but the developer accepts' in ppage) or ('No thanks, just take me' in ppage) or ('is free' in ppage.lower())
    out["actual_price"] = actual_price
    out["is_pwyw_free"] = is_free
    # look for "Buy $X" button text meaning paid
    buy_price = re.search(r'class="button buy_btn"[^>]*>\s*(?:Buy|Download)[^<]*\$([0-9.]+)', ppage) or \
                re.search(r'<span class="dollars">\$</span><span[^>]*>([0-9.]+)</span>', ppage)
    if buy_price and not is_free:
        out["error"] = f"paid item (${buy_price.group(1)})"
        log(out["error"]); return out
    if not is_free and actual_price and float(actual_price.replace('$','')) > 0:
        out["error"] = f"paid item (price={actual_price})"
        log(out["error"]); return out
    # hard rejection: if no "No thanks, just take me to the downloads" link AND no "free but the developer accepts"
    # then it's not PWYW free — likely paid
    if 'No thanks, just take me to the downloads' not in ppage:
        # check if there's any "Free" or PWYW indicator
        has_free_pwyw = ('free but the developer accepts' in ppage) or \
                        ('is free' in ppage.lower()) or \
                        ('this asset pack is free' in ppage.lower()) or \
                        ('class="price_free"' in ppage)
        if not has_free_pwyw:
            out["error"] = "not PWYW free (no 'No thanks' link, no free indicator)"
            log(out["error"]); return out
    out["free_uncertain"] = False

    # included file names from purchase page
    file_names = re.findall(r'<strong class="name">([^<]+)</strong>', ppage)
    out["included_files"] = [x.strip() for x in file_names]

    # 3. POST /<slug>/download_url with csrf -> session URL
    time.sleep(1.5)
    body, err, rc = curl_post(f"https://{author}.itch.io/{slug}/download_url", {"csrf_token": csrf})
    if rc != 0 or not body:
        out["error"] = f"download_url POST rc={rc}"; log(out["error"]); return out
    try:
        j = json.loads(body.decode("utf-8","replace"))
        session_url = j.get("url")
    except Exception:
        out["error"] = f"download_url returned non-JSON: {body[:200]!r}"; log(out["error"]); return out
    if not session_url:
        out["error"] = f"no session url in response: {j}"; log(out["error"]); return out
    out["session_url"] = session_url
    out["steps"].append("got_session_url")

    # 4. Visit session URL -> download page
    time.sleep(1.5)
    body, err, rc = curl_get(session_url)
    if rc != 0 or not body:
        out["error"] = f"session GET rc={rc}"; log(out["error"]); return out
    dl_page = body.decode("utf-8","replace")
    out["download_page_html"] = dl_page[:30000]
    # extract upload_id(s)
    upload_ids = re.findall(r'data-upload_id="(\d+)"', dl_page)
    if not upload_ids:
        out["error"] = "no upload_id in download page"; log(out["error"]); return out
    out["upload_ids"] = upload_ids
    out["steps"].append("got_upload_ids")

    # 5. POST /<slug>/file/<upload_id> -> CDN URL
    cdn_urls = []
    for uid in upload_ids:
        time.sleep(1.5)
        body, err, rc = curl_post(f"https://{author}.itch.io/{slug}/file/{uid}?source=view_game&as_props=1", {"csrf_token": csrf})
        if rc != 0:
            out["error"] = f"file POST rc={rc} for uid={uid}"; log(out["error"]); continue
        try:
            j = json.loads(body.decode("utf-8","replace"))
            url = j.get("url")
            if url:
                cdn_urls.append((uid, url))
        except Exception:
            log(f"file POST uid={uid} returned non-JSON: {body[:200]!r}")
    if not cdn_urls:
        out["error"] = "no CDN URL"; log(out["error"]); return out
    out["cdn_urls"] = [u for _, u in cdn_urls]
    out["steps"].append("got_cdn_urls")

    # 6. Download each CDN URL
    for uid, cdn in cdn_urls:
        time.sleep(2)
        # filename from URL or upload_id
        try:
            u = urllib.parse.urlparse(cdn)
            fname = os.path.basename(u.path).split("?")[0] or f"{uid}.bin"
        except Exception:
            fname = f"{uid}.bin"
        fname = re.sub(r'[^a-zA-Z0-9._-]', '_', fname)[:120]
        out_path = os.path.join(save_dir, fname)
        body, err, rc = curl_save(cdn, out_path, max_time=180)
        size = os.path.getsize(out_path) if os.path.exists(out_path) else 0
        if rc == 0 and size > 100:
            # Detect file type from magic bytes and rename if needed
            with open(out_path, 'rb') as f:
                magic = f.read(8)
            if magic[:2] == b'PK' and not out_path.lower().endswith('.zip'):
                new_path = out_path + '.zip'
                os.rename(out_path, new_path)
                out_path = new_path
            elif magic[:4] == b'\x89PNG' and not out_path.lower().endswith('.png'):
                new_path = out_path + '.png'
                os.rename(out_path, new_path)
                out_path = new_path
            elif magic[:3] == b'GIF' and not out_path.lower().endswith('.gif'):
                new_path = out_path + '.gif'
                os.rename(out_path, new_path)
                out_path = new_path
            out["files"].append({"upload_id": uid, "url": cdn, "path": out_path, "size": os.path.getsize(out_path)})
            log(f"OK {os.path.getsize(out_path):>8} bytes  upload_id={uid}  -> {os.path.basename(out_path)}")
        else:
            out["files"].append({"upload_id": uid, "path": out_path, "error": f"rc={rc} size={size}"})
            log(f"FAIL {rc} {size} uid={uid}")
    out["steps"].append("downloaded")

    # 7. Auto-extract any zip files
    for f in out["files"]:
        if "error" in f: continue
        p = f["path"]
        if p.lower().endswith(".zip"):
            try:
                with zipfile.ZipFile(p) as z:
                    z.extractall(os.path.join(save_dir, "extracted"))
                log(f"extracted: {os.path.basename(p)}")
            except Exception as e:
                log(f"extract failed: {e}")

    # 8. Try to find license/README
    for root, dirs, files in os.walk(os.path.join(save_dir, "extracted")):
        for fn in files:
            if any(k in fn.lower() for k in ["readme","license","credit","terms"]):
                try:
                    with open(os.path.join(root, fn), "r", encoding="utf-8", errors="ignore") as f:
                        out["license_text"] = f.read()[:5000]
                    log(f"license file: {fn}")
                    break
                except Exception:
                    pass
        if out["license_text"]: break

    return out

if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--author", required=True)
    ap.add_argument("--slug", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    args.out = args.out.replace("\\","/")
    log_path = os.path.join(SCRATCH, "dl_log.txt")
    r = fetch_one_game(args.author, args.slug, args.out, log_path=log_path)
    # print compact summary (exclude HTML)
    summary = {k:v for k,v in r.items() if k not in ("page_html","purchase_page_html","download_page_html")}
    print(json.dumps(summary, indent=2, ensure_ascii=False))