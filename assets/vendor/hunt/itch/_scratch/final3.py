"""Final 3 candidates: tower (Kenney), sea enemy, ship."""
import os, sys, json, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dl_helper import fetch_one_game, SCRATCH

FINAL = [
    ("kenney-assets", "tower-defense-kit", "41_kenney_tower_defense"),
    ("gamedeveloperstudio", "animated-top-down-sea-life", "42_top_down_sea_life"),
    ("gegx", "boats-ships", "43_boats_ships"),
]
OUT_BASE = "D:/mydev/games/Tower Defense/assets/vendor/hunt/itch"
LOG = os.path.join(SCRATCH, "final3_log.txt")
if os.path.exists(LOG):
    try: os.remove(LOG)
    except: pass

results = []
for i, (author, slug, d) in enumerate(FINAL):
    save_dir = os.path.join(OUT_BASE, d)
    print(f"\n===== [{i+1}/3] {author}/{slug} =====")
    try:
        r = fetch_one_game(author, slug, save_dir, log_path=LOG)
    except Exception as e:
        r = {"author":author,"slug":slug,"error":f"exception: {e}"}
    summary = {k:v for k,v in r.items() if k not in ("page_html","purchase_page_html","download_page_html")}
    results.append(summary)
    if i < len(FINAL)-1:
        time.sleep(3)

with open(os.path.join(SCRATCH, "final3_results.json"), "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

print(f"\n=== FINAL 3 DONE ===")
for r in results:
    fcount = len([f for f in r.get('files',[]) if 'error' not in f])
    print(f"  {r['author']}/{r['slug'][:48]} -> files={fcount}  err={(r.get('error') or '')[:50]}")