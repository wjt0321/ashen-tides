#!/usr/bin/env python3
"""《余烬潮汐》爬取素材确定性派生管线。

把 assets/vendor/hunt/ 下已入库的 CC0/CC-BY 素材经裁帧/重组/调色/尺寸适配
转换为运行时资产（assets/art/）。规则：
- 只允许整数倍 NEAREST 缩放（×2、÷2、÷4、÷8），其余对齐靠裁切/居中/补透明边；
- 敌人 = 冷青灰/灰绿主体 + 深色轮廓；己方塔 = 暖珊瑚/余烬橙 + 低饱和铜木；
- 色弱变体（_protan/_deutan/_tritan）用 pixel_v2.remap 生成，
  与运行时 UiPalette.apply 同一矩阵；
- 全部输出带 SHA-256 清单（DERIVED_MANIFEST.json + out/sourced_assets_lineage.json）。

可重复运行：同一输入永远产生同一输出（derived_at 除外）。
"""
import hashlib
import json
import os
import sys
from datetime import date

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixel_v2 import PAL, remap, render, rail_tier, well_tier, canvas, paste, needle_frame  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
V = os.path.join(ROOT, "assets", "vendor", "hunt")
LPC_DIR = os.path.join(V, "oga-enemies", "06_lpc_animals_2022", "extracted",
                       "lpc animals 2022 v1.1", "combined creature spritesheets")
SHIP_DIR = os.path.join(V, "oga-terrain", "lpc-ship_bluecarrot16", "extracted", "lpc-ship")

P = {k: v for k, v in PAL.items() if v}  # 去透明键

# --- 归因表 -----------------------------------------------------------------
SRC = {
    "crab": {"path": "assets/vendor/hunt/oga-enemies/02_crab_topdown/extracted/Crab/Crab_Walk.png",
             "title": "Crab (top-down walk)", "author": "alizard", "license": "CC0-1.0"},
    "rat": {"path": "assets/vendor/hunt/oga-enemies/06_lpc_animals_2022/.../giant rat 80x64 (Sevarihk).png",
            "title": "LPC animals 2022 - giant rat", "author": "Sevarihk", "license": "CC-BY-4.0"},
    "mice": {"path": "assets/vendor/hunt/oga-enemies/06_lpc_animals_2022/.../mice 32x32.png",
             "title": "LPC animals 2022 - mice", "author": "Sevarihk", "license": "CC-BY-4.0"},
    "shark": {"path": "assets/vendor/hunt/oga-enemies/06_lpc_animals_2022/.../shark 160x160 (Sevarihk).png",
              "title": "LPC animals 2022 - shark", "author": "Sevarihk", "license": "CC-BY-4.0"},
    "turret": {"path": "assets/vendor/hunt/oga-towers/01_pixel_turret_animation/",
               "title": "Pixel Turret Animation", "author": "zerohero", "license": "CC0-1.0"},
    "fire": {"path": "assets/vendor/hunt/oga-towers/04_animated_fire/fire1_64.png",
             "title": "Animated Fire", "author": "benhickling", "license": "CC0-1.0"},
    "explosion": {"path": "assets/vendor/hunt/oga-towers/11_explosion_animations/explosion3.png",
                  "title": "Explosion Animations", "author": "Jetrel (Frogatto)", "license": "CC-BY-3.0"},
    "sparks": {"path": "assets/vendor/hunt/oga-towers/06_sparks_fire_ice_blood/sparks.png",
               "title": "Sparks / Fire / Ice / Blood", "author": "Clint Bellanger", "license": "CC-BY-3.0"},
    "ship_acc": {"path": "assets/vendor/hunt/oga-terrain/lpc-ship_bluecarrot16/extracted/lpc-ship/lpc-ship-accessories.png",
                 "title": "[LPC] Ship accessories", "author": "bluecarrot16", "license": "OGA-BY-3.0 / CC-BY-3.0"},
    "ship_cannon": {"path": "assets/vendor/hunt/oga-terrain/lpc-ship_bluecarrot16/extracted/lpc-ship/ship-cannon.png",
                    "title": "[LPC] Ship cannon", "author": "bluecarrot16", "license": "OGA-BY-3.0 / CC-BY-3.0"},
    "v2": {"path": "tools/pixel_v2.py",
           "title": "Ember Tide v2 hand-authored pixel art", "author": "Ember Tide dev", "license": "project-internal"},
}

TODAY = date.today().isoformat()
LINEAGE = {}  # 输出相对路径 -> {"sha256","size","bytes","sources":[key...]}


# --- 基础工具 ---------------------------------------------------------------
def load(*parts):
    return Image.open(os.path.join(*parts)).convert("RGBA")


def key_magenta(im):
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and r > 180 and b > 180 and g < 100:
                px[x, y] = (0, 0, 0, 0)
    return im


def flatten_alpha(im, thresh=100):
    """半透明（阴影/AA）按阈值二值化：>=thresh 变不透明，否则透明。"""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= thresh else (0, 0, 0, 0)
    return im


def content_bbox(im):
    return im.getbbox()


def crop_content(im, pad=0):
    bb = im.getbbox()
    if not bb:
        return im
    x0, y0, x1, y1 = bb
    return im.crop((max(0, x0 - pad), max(0, y0 - pad),
                    min(im.width, x1 + pad), min(im.height, y1 + pad)))


def center_into(im, w, h, align="center", margin=0):
    """把 im 居中（或底对齐）放入 w×h 透明画布；超出部分居中裁切，不缩放。"""
    out = canvas(w, h)
    cw, ch = min(im.width, w), min(im.height, h)
    sx = (im.width - cw) // 2
    sy = (im.height - ch) // 2
    im = im.crop((sx, sy, sx + cw, sy + ch))
    dx = (w - cw) // 2
    dy = (h - ch) // 2 if align == "center" else h - ch - margin
    paste(out, im, dx, dy)
    return out


def scale_int(im, factor):
    """整数倍 NEAREST 缩放；factor 为分数（如 1/2）表示整数倍缩小。"""
    if factor >= 1:
        return im.resize((im.width * factor, im.height * factor), Image.NEAREST)
    return im.resize((im.width // round(1 / factor), im.height // round(1 / factor)), Image.NEAREST)


def down2_bright(im, factor=2):
    """整数倍降采样：每 factor×factor 块取最亮不透明像素（比 NEAREST 保轮廓/高光）。"""
    w, h = im.width // factor, im.height // factor
    src = im.load()
    out = canvas(w, h)
    px = out.load()
    for y in range(h):
        for x in range(w):
            best, best_lum = None, -1
            for dy in range(factor):
                for dx in range(factor):
                    r, g, b, a = src[x * factor + dx, y * factor + dy]
                    if not a:
                        continue
                    lum = 0.299 * r + 0.587 * g + 0.114 * b
                    if lum > best_lum:
                        best, best_lum = (r, g, b, a), lum
            if best:
                px[x, y] = best
    return out


def lum_map(im, stops, lo_pct=2, hi_pct=98):
    """按亮度百分位把不透明像素映射到色阶 stops=[(t0,(r,g,b,a)),...]（t 升序）。"""
    lums = []
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a:
                lums.append(0.299 * r + 0.587 * g + 0.114 * b)
    if not lums:
        return im
    lums.sort()
    lo = lums[min(len(lums) - 1, len(lums) * lo_pct // 100)]
    hi = lums[max(0, len(lums) * hi_pct // 100 - 1)]
    span = max(1.0, hi - lo)
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            t = ((0.299 * r + 0.587 * g + 0.114 * b) - lo) / span
            col = stops[-1][1]
            for ts, c in stops:
                if t <= ts:
                    col = c
                    break
            px[x, y] = col[:3] + (a,)
    return im


def add_outline(im, color=P["K"], diag=False):
    """在透明-不透明边界外扩 1px 深色轮廓。"""
    out = im.copy()
    src = im.load()
    px = out.load()
    neigh = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    if diag:
        neigh += [(-1, -1), (1, -1), (-1, 1), (1, 1)]
    marks = []
    for y in range(im.height):
        for x in range(im.width):
            if src[x, y][3]:
                continue
            for dx, dy in neigh:
                nx, ny = x + dx, y + dy
                if 0 <= nx < im.width and 0 <= ny < im.height and src[nx, ny][3]:
                    marks.append((x, y))
                    break
    for x, y in marks:
        px[x, y] = color
    return out


def dusk_tint(im, desat=0.22):
    """冷灰暮色调色：去饱和 + 轻微蓝移。"""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            lum = 0.299 * r + 0.587 * g + 0.114 * b
            r = r + (lum - r) * desat
            g = g + (lum - g) * desat
            b = b + (lum - b) * desat
            px[x, y] = (round(min(255, r * 0.94)), round(min(255, g * 0.99)),
                        round(min(255, b * 1.05 + 3)), a)
    return im


def find_clusters(im, region, min_px=20):
    """在 region=(x0,y0,x1,y1) 内做 4 连通组件检测，返回 [(bbox,size)] 按面积降序。"""
    x0, y0, x1, y1 = region
    sub = im.crop(region)
    px = sub.load()
    w, h = sub.size
    seen = [[False] * w for _ in range(h)]
    out = []
    for sy in range(h):
        for sx in range(w):
            if seen[sy][sx] or not px[sx, sy][3]:
                continue
            stack = [(sx, sy)]
            seen[sy][sx] = True
            xs, ys, n = [], [], 0
            while stack:
                cx, cy = stack.pop()
                xs.append(cx)
                ys.append(cy)
                n += 1
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and px[nx, ny][3]:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            if n >= min_px:
                out.append(((min(xs) + x0, min(ys) + y0, max(xs) + 1 + x0, max(ys) + 1 + y0), n))
    out.sort(key=lambda t: -t[1])
    return out


def save(rel_path, im, sources, variants=False):
    """写出 PNG（可选 3 色弱变体），登记 lineage。返回 (绝对路径, sha256)。"""
    abs_path = os.path.join(ROOT, rel_path)
    os.makedirs(os.path.dirname(abs_path), exist_ok=True)
    targets = [(rel_path, im)]
    if variants:
        stem, ext = os.path.splitext(rel_path)
        for preset in ("protan", "deutan", "tritan"):
            targets.append(("%s_%s%s" % (stem, preset, ext), remap(im, preset)))
    result = []
    for rel, img in targets:
        ap = os.path.join(ROOT, rel)
        img.save(ap)
        data = open(ap, "rb").read()
        sha = hashlib.sha256(data).hexdigest()
        LINEAGE[rel] = {"sha256": sha, "size": list(img.size), "bytes": len(data),
                        "sources": [SRC[s] for s in sources], "derived_at": TODAY,
                        "builder": "tools/build_sourced_assets.py"}
        result.append((rel, sha))
    return result


# --- 源素材载入 ---------------------------------------------------------------
def src_crab():
    return load(V, "oga-enemies", "02_crab_topdown", "extracted", "Crab", "Crab_Walk.png")


def src_rat():
    return load(LPC_DIR, "giant rat 80x64 (Sevarihk).png")


def src_mice():
    return load(LPC_DIR, "mice 32x32.png")


def src_shark():
    return load(LPC_DIR, "shark 160x160 (Sevarihk).png")


def src_turret(name):
    return load(V, "oga-towers", "01_pixel_turret_animation", name)


def src_fire():
    return load(V, "oga-towers", "04_animated_fire", "fire1_64.png")


def src_explosion():
    return load(V, "oga-towers", "11_explosion_animations", "explosion3.png")


def src_sparks():
    return load(V, "oga-towers", "06_sparks_fire_ice_blood", "sparks.png")


def src_ship_acc():
    return load(SHIP_DIR, "lpc-ship-accessories.png")


def src_ship_cannon():
    return load(SHIP_DIR, "ship-cannon.png")


# --- 调色色阶（暗→亮；全部落在 PAL 色板，与 remap 矩阵行为一致）----------------
RAMP_SALT = [(0.16, P["K"]), (0.30, P["k"]), (0.46, P["D"]), (0.62, P["d"]),
             (0.78, P["L"]), (0.92, P["e"]), (1.01, P["P"])]
RAMP_RAT = [(0.15, P["K"]), (0.35, P["q"]), (0.55, P["p"]), (0.75, P["s"]), (1.01, P["P"])]
RAMP_MICE = [(0.22, P["K"]), (0.48, P["q"]), (0.82, P["p"]), (1.01, P["L"])]
RAMP_BRASS = [(0.18, P["K"]), (0.38, P["M"]), (0.62, P["g"]), (0.82, P["m"]), (1.01, P["P"])]
RAMP_EMBER = [(0.30, P["R"]), (0.55, P["E"]), (0.78, P["O"]), (1.01, P["Y"])]


# =============================================================================
# A. C01 runtime
# =============================================================================
def build_c01_enemy_salt_shell():
    """512×192（8帧×3行 64×64）。螃蟹映射：行0=侧面朝左、行1=正面朝下、行2=背面朝上。
    8 帧 = F1/F2 交替 + ±1px 垂直浮动。"""
    crab = flatten_alpha(src_crab(), 100)
    # Crab_Walk 布局：row0=[up_F1,up_F2,down_F1,down_F2]，row1=[left_F1,left_F2,right_F1,right_F2]
    cells = {
        0: [(128, 64), (192, 64)],   # side = left（源帧即朝左）
        1: [(128, 0), (192, 0)],     # front = down
        2: [(0, 0), (64, 0)],        # back = up
    }
    bob = [0, 1, 1, 0, 0, 1, 1, 0]
    sheet = canvas(512, 192)
    for row, pair in cells.items():
        frames = []
        for cx, cy in pair:
            cell = crab.crop((cx, cy, cx + 64, cy + 64))
            cell = center_into(crop_content(cell), 64, 64)
            cell = lum_map(cell, RAMP_SALT)
            # 暖色眼点/甲壳锈斑（让通用 32×32 派生图的 protan/deutan 变体有差异）
            bb = cell.getbbox()
            if bb:
                front_x = bb[0] + 3 if row == 0 else (bb[0] + bb[2]) // 2
                eye_y = bb[1] + (bb[3] - bb[1]) // 3
                _paint_eye(cell, front_x, eye_y, P["r"])
                if row != 0:
                    _paint_eye(cell, front_x + 5, eye_y, P["r"])
            frames.append(cell)
        for i in range(8):
            f = frames[i % 2]
            paste(sheet, f, i * 64, row * 64 + bob[i])
    return sheet


def build_c01_enemy_mast_rat():
    """512×192 同规格。LPC 巨鼠：抠品红、去半透明阴影、80×64→64×64 居中，
    每方向从 12 帧行走循环挑 8 帧；冷灰棕色阶。"""
    rat = key_magenta(src_rat())
    # 行序实测：row0=up(背)、row1=left(侧，朝左)、row2=right、row3=down(正)
    rows = {0: 1, 1: 3, 2: 0}
    pick = [0, 1, 2, 3, 4, 6, 8, 10]  # 12 帧均匀挑 8（col11 为空格）
    sheet = canvas(512, 192)
    for out_row, src_row in rows.items():
        last = None
        for i, fi in enumerate(pick):
            cell = rat.crop((fi * 80, src_row * 64, (fi + 1) * 80, (src_row + 1) * 64))
            cell = flatten_alpha(cell, 200)  # 去掉 alpha140 的阴影椭圆
            if cell.getbbox() is None and last is not None:
                cell = last
            else:
                cell = center_into(crop_content(cell), 64, 64, align="bottom", margin=2)
                cell = lum_map(cell, RAMP_RAT)
                last = cell
            paste(sheet, cell, i * 64, out_row * 64)
    return sheet


def _turret_head_recolor(im):
    """zerohero 橄榄绿炮头 → 黄铜/铜木 + 余烬珊瑚红点；白色闪光 → 灯芯/灯暖。"""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            if r > 150 and g < 120 and b < 110:      # 红色指示灯 → 余烬珊瑚
                px[x, y] = P["E"]
            elif r > 200 and g > 200 and b > 190:    # 白闪光 → 灯芯
                px[x, y] = P["Y"]
    return lum_map(im, RAMP_BRASS)


def build_c01_tower_needle_rail():
    """576×96（6帧 96×96；帧0待机，帧1–5开火包络）。
    合成：pixel_v2 阶梯石基座 + 珊瑚灯顶（自绘底层）+ zerohero 炮身/炮管 shot 帧。"""
    base_full = scale_int(needle_frame(0), 2)        # 作者48×48 → 96×96
    lamp = base_full.crop((40, 2, 56, 22))           # 珊瑚灯顶
    pyramid = base_full.crop((6, 62, 90, 96))        # 阶梯石基座下半
    body = crop_content(src_turret("turret-sprites-body.png").crop((0, 0, 54, 47)))
    shots = [crop_content(src_turret("turret-sprites-head-shot.png").crop((i * 54, 0, (i + 1) * 54, 47)))
             for i in range(3)]
    body = _turret_head_recolor(body)                # 35×25
    shots = [_turret_head_recolor(s) for s in shots]
    barrel = scale_int(shots[0], 2)                  # 48×16
    flash1 = scale_int(shots[1], 2)                  # 带大闪光
    flash2 = scale_int(shots[2], 2)                  # 带小闪光

    def frame(mode):
        im = canvas(96, 96)
        paste(im, pyramid, 6, 62)
        paste(im, body, (96 - body.width) // 2, 40)  # 炮身骑在基座上
        head_dx = 24
        if mode == 0:
            paste(im, barrel, head_dx, 26)
        elif mode == 1:
            paste(im, flash1, head_dx, 26)
        elif mode == 2:
            paste(im, flash2, head_dx, 26)
        elif mode == 3:
            paste(im, barrel, head_dx - 6, 26)       # 后座
        elif mode == 4:
            paste(im, barrel, head_dx - 3, 26)
        else:
            paste(im, barrel, head_dx, 26)
        paste(im, lamp, 40, 2)
        return im

    sheet = canvas(576, 96)
    for i in range(6):
        paste(sheet, frame(i), i * 96, 0)
    return sheet


def build_c01_harbor_props():
    """1024×128（8格 128×128）。索引语义沿用 pixel_v2.props_atlas：
    0木箱 1木桶 2绳圈 3锚 4灯柱 5网 6小船 7舵轮。
    0/1/2/3/5 用 LPC ship 素材派生（5=货网格栅板），4/6/7 保留 pixel_v2 自绘格
    （灯柱自带暖光点）。 sourced 格全部冷灰暮色调色。"""
    from pixel_v2 import props_atlas
    acc = src_ship_acc()
    cannon = src_ship_cannon()
    v2 = scale_int(props_atlas(), 2)                 # 作者 512×64 → 1024×128

    def grab(image, region, score, pad=2):
        clusters = find_clusters(image, region)
        if not clusters:
            raise RuntimeError("no cluster in %s" % (region,))
        bb = max(clusters, key=lambda t: score(t[0], t[1]))[0]
        return image.crop((max(0, bb[0] - pad), max(0, bb[1] - pad),
                           min(image.width, bb[2] + pad), min(image.height, bb[3] + pad)))

    def squarish(target_ratio, w_pref):
        def score(bb, n):
            w, h = bb[2] - bb[0], bb[3] - bb[1]
            return -abs(w / max(1, h) - target_ratio) * 400 - abs(w - w_pref) + n * 0.01
        return score

    # 0 木箱：配件图大板条箱（90×124 → 上下各裁 14 收为 90×96，重描边保持闭合）
    crate = grab(acc, (0, 218, 96, 352), squarish(0.75, 90))
    crate = crate.crop((0, 14, crate.width, crate.height - 14))
    crate = add_outline(crate, P["G"], diag=True)
    # 1 木桶：炮图板条圆桶 ×2 + 深箍，垫 PAL 木板托盘补齐视觉体量（≈84×70）
    barrel = grab(cannon, (5, 145, 62, 200), squarish(1.3, 40))
    barrel = scale_int(barrel, 2)
    px = barrel.load()
    for x in range(barrel.width):                    # 桶箍
        for y in (4, 5, barrel.height - 8, barrel.height - 7):
            if 0 <= y < barrel.height and px[x, y][3]:
                px[x, y] = P["G"]
    pallet = canvas(max(barrel.width + 12, 84), barrel.height + 10)
    pp = pallet.load()
    for y in range(pallet.height - 8, pallet.height - 2):   # 托盘：3 块铜木板
        for x in range(pallet.width):
            if (x // 12) % 2 == 0:
                pp[x, y] = P["g"] if y < pallet.height - 5 else P["G"]
    for x in range(pallet.width):                    # 托盘包边
        for y in (pallet.height - 9, pallet.height - 2):
            pp[x, y] = P["K"]
    paste(pallet, barrel, (pallet.width - barrel.width) // 2, 0)
    barrel = pallet
    # 2 绳圈：配件图圆形螺旋绳卷 ×3（25×20 → 75×60）
    coil = scale_int(grab(acc, (2, 160, 34, 195), squarish(1.1, 25)), 3)
    # 3 锚：配件图大银锚（约 55×95，已达标）
    anchor = grab(acc, (250, 85, 330, 200), squarish(0.65, 55))
    # 5 网：配件图格栅/货网板（约 90×90，已达标）
    net = grab(acc, (350, 225, 450, 325), squarish(1.1, 85))
    # 4 灯柱：pixel_v2 自绘格内容 ×2（18×36 → 36×72，自带暖光点）
    lamp = crop_content(v2.crop((4 * 128, 0, 5 * 128, 128)))
    lamp = scale_int(lamp, 2)

    sheet = canvas(1024, 128)

    def put(i, cell_im, tint=True, align="bottom"):
        c = center_into(cell_im, 128, 128, align=align, margin=10)
        if tint:
            c = dusk_tint(c)
        paste(sheet, c, i * 128, 0)

    def put_v2(i):
        paste(sheet, v2.crop((i * 128, 0, (i + 1) * 128, 128)), i * 128, 0)

    put(0, crate)
    put(1, barrel)
    put(2, coil)
    put(3, anchor)
    put(4, lamp, tint=False)                         # 灯柱：自带暖光（暖灯点）
    put(5, net)
    put_v2(6)                                        # 小船
    put_v2(7)                                        # 舵轮
    return sheet


# =============================================================================
# B. C02 runtime（原图 + 3 色弱变体）
# =============================================================================
def _paint_eye(im, x, y, color):
    px = im.load()
    for dx in range(2):
        for dy in range(2):
            if 0 <= x + dx < im.width and 0 <= y + dy < im.height:
                px[x + dx, y + dy] = color
    return im


def paint_nearest(im, x, y, color, max_r=8):
    """把离 (x,y) 最近的不透明像素涂成 color（降采样后补画小尺寸强调点）。"""
    px = im.load()
    best, best_d = None, max_r * max_r + 1
    for yy in range(im.height):
        for xx in range(im.width):
            if px[xx, yy][3]:
                d = (xx - x) ** 2 + (yy - y) ** 2
                if d < best_d:
                    best, best_d = (xx, yy), d
    if best:
        px[best] = color
    return im


def build_c02_mast_rat_swarm():
    """64×62 单帧：3 只 LPC 小鼠错位组合（朝右 = +x 前方），冷灰棕。
    潮光青眼（tritan 触发）+ 锈橙耳尖（protan/deutan 触发）。"""
    mice = flatten_alpha(key_magenta(src_mice()), 200)
    # row1 = 侧面朝右行走；取灰鼠 col0..2 三种步态
    frames = []
    for c in range(3):
        cell = mice.crop((c * 32, 32, (c + 1) * 32, 64))
        cell = crop_content(cell)
        frames.append(lum_map(cell, RAMP_MICE))
    im = canvas(64, 62)
    paste(im, frames[1], 2, 30)    # 后随 1（左下）
    paste(im, frames[2], 32, 33)   # 后随 2（右下）
    paste(im, frames[0], 14, 12)   # 领队（中上偏前）
    for ex, ey in ((34, 18), (54, 39), (22, 36)):  # 眼 = 潮光青
        _paint_eye(im, ex, ey, P["w"])
    for ex, ey in ((33, 15), (53, 36), (21, 33)):  # 耳尖 = 锈橙
        px = im.load()
        if px[ex, ey][3]:
            px[ex, ey] = P["r"]
    return im


def build_c02_splitfin_dasher():
    """64×64 单帧：LPC 鲨鱼侧面帧（朝右），压暗水痕，冷青 + 潮高光脊线。"""
    shark = src_shark()
    cell = shark.crop((0, 320, 160, 480))            # row2 col0 = 侧面朝右
    px = cell.load()
    for y in range(cell.height):                     # 不透明亮斑 = 水面泡沫痕 → 压成身色
        for x in range(cell.width):
            r, g, b, a = px[x, y]
            if a >= 200:
                px[x, y] = (r, g, b, 145)            # 与身体(alpha140)同档，随后统一提亮
    cell = flatten_alpha(cell, 100)
    cell = crop_content(cell)                        # ~120×40
    cell = scale_int(cell, 0.5)                      # ÷2 → ~60×20
    # 源鲨鱼身体是纯平深色剪影（无内部明暗），改为结构填色：
    # 轮廓 K（贴透明边的像素），背部 V、体侧 d、腹部 e（鲨鱼类反荫蔽），脊线 c。
    im = center_into(cell, 64, 64)
    px = im.load()
    bb = im.getbbox()
    for y in range(bb[1], bb[3]):
        for x in range(bb[0], bb[2]):
            if not px[x, y][3]:
                continue
            edge = False
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < im.width and 0 <= ny < im.height) or not px[nx, ny][3]:
                    edge = True
                    break
            if edge:
                px[x, y] = P["K"]
                continue
            t = (y - bb[1]) / max(1, bb[3] - bb[1] - 1)
            px[x, y] = P["V"] if t < 0.35 else (P["d"] if t < 0.70 else P["e"])
    for x in range(bb[0], bb[2]):                    # 脊线潮高光（body_color 0.45,0.85,0.90 ≈ PAL c）
        for y in range(bb[1], bb[3]):
            if px[x, y][3]:
                px[x, y] = P["c"]
                if y + 1 < im.height and px[x, y + 1][3]:
                    px[x, y + 1] = P["c"]
                break
    _paint_eye(im, bb[2] - 10, (bb[1] + bb[3]) // 2 - 3, P["E"])  # 余烬橙眼（protan 触发）
    return im


def build_c02_rust_armor_carrier():
    """64×62 单帧：螃蟹甲壳（朝右）+ 锈橙装甲板，重甲厚轮廓。"""
    crab = flatten_alpha(src_crab(), 100)
    cell = crab.crop((128, 64, 192, 128)).transpose(Image.FLIP_LEFT_RIGHT)  # 朝左→朝右
    cell = lum_map(center_into(crop_content(cell), 64, 62),
                   [(0.16, P["K"]), (0.32, P["k"]), (0.50, P["D"]), (0.72, P["d"]), (1.01, P["e"])])
    im = cell
    bb = im.getbbox()
    px = im.load()
    w = bb[2] - bb[0]
    # 三块锈装甲板横贯甲壳（R 底 + r 顶棱 + K 包边），避开钳/腿
    for band, (yt, yb) in enumerate(((0.20, 0.30), (0.40, 0.50), (0.60, 0.70))):
        x0 = bb[0] + 8 + band
        x1 = bb[2] - 8 - band
        y0 = round(bb[1] + (bb[3] - bb[1]) * yt)
        y1 = round(bb[1] + (bb[3] - bb[1]) * yb)
        for y in range(y0, y1):
            for x in range(x0, x1):
                if px[x, y][3]:
                    px[x, y] = P["r"] if y == y0 else P["R"]
        for x in range(x0, x1):
            for y in (y0 - 1, y1):
                if 0 <= y < im.height and px[x, y][3]:
                    px[x, y] = P["K"]
    # 背顶货包（铜木）
    cw = max(6, w // 4)
    cx = (bb[0] + bb[2]) // 2 - cw // 2
    for y in range(bb[1] - 5, bb[1] + 1):
        for x in range(cx, cx + cw):
            if 0 <= y < im.height:
                px[x, y] = P["g"] if y < bb[1] - 1 else P["G"]
    for y in range(bb[1] - 5, bb[1] + 1):
        for x in (cx, cx + cw - 1):
            if 0 <= y < im.height:
                px[x, y] = P["K"]
    im = add_outline(im, P["K"], diag=True)          # 重甲厚轮廓
    _paint_eye(im, bb[2] - 4, (bb[1] + bb[3]) // 2 - 4, P["E"])
    return im


def _tide_rivets(im, spots):
    """塔基潮光铆钉：让 tritan 变体对暖色塔也能生效（b>r+0.15 触发）。"""
    px = im.load()
    for x, y in spots:
        if 0 <= x < im.width and 0 <= y < im.height and px[x, y][3]:
            px[x, y] = P["w"]
    return im


def build_c02_rail_tiers():
    """64×64 ×4：pixel_v2 rail_tier 递进基座/横梁 + zerohero 炮管（黄铜化）嵌梁。"""
    shots = src_turret("turret-sprites-head-shot.png")
    barrel = crop_content(shots.crop((0, 0, 54, 47)))  # 24×8 朝右
    barrel = _turret_head_recolor(barrel)
    out = []
    for tier in (1, 2, 3, 4):
        im = scale_int(rail_tier(tier), 2)             # 作者32×32 → 64×64
        paste(im, barrel, 20, 25)                      # 炮管骑梁，枪口朝右
        _tide_rivets(im, [(11, 53), (52, 53)])
        out.append(im)
    return out


def _fire_flame(height):
    """从 Animated Fire 取一静态帧，裁火焰主体，÷2 缩放到指定高度附近的火苗。"""
    fire = src_fire()
    frame = fire.crop((3 * 64, 2 * 64, 4 * 64, 3 * 64))  # 中期饱满帧
    flame = crop_content(frame)                          # ~27×48
    flame = center_into(flame, 24, 48)
    flame = scale_int(flame, 0.5)                        # 12×24
    flame = flame.crop((0, 24 - height // 2, 12, 24))    # 底部对齐截取
    # 色阶：暗红边 → 余烬珊瑚 → 灯暖 → 灯芯（保持琥珀光）
    return lum_map(flame, RAMP_EMBER, lo_pct=0, hi_pct=100)


def build_c02_well_tiers():
    """64×64 ×4：pixel_v2 well_tier 石质井座 + Animated Fire 井口火焰。"""
    out = []
    flame_h = {1: 30, 2: 36, 3: 44, 4: 48}
    for tier in (1, 2, 3, 4):
        im = scale_int(well_tier(tier), 2)
        px = im.load()
        for y in range(2, 26):                         # 抹掉程序化火锥/烟囱区
            for x in range(24, 40):
                px[x, y] = (0, 0, 0, 0)
        flame = _fire_flame(flame_h[tier])
        paste(im, flame, 26, 24 - flame.height)
        if tier == 4:                                  # 白热炉芯
            for y in range(10, 16):
                for x in range(30, 34):
                    if px[x, y][3]:
                        px[x, y] = P["Y"]
        _tide_rivets(im, [(9, 45), (54, 45)])
        out.append(im)
    return out


def build_c02_projectile_ember_burst():
    """16×16 单帧：从 sparks 火系帧取最亮 16×16 窗口，余烬色阶。"""
    sparks = src_sparks()
    cell = sparks.crop((64, 128, 128, 192))            # row2 col1 橙系中期散射
    best, best_score = (0, 0), -1
    px = cell.load()
    for y in range(0, 49, 4):
        for x in range(0, 49, 4):
            s = 0
            for dy in range(16):
                for dx in range(16):
                    r, g, b, a = px[x + dx, y + dy]
                    s += a * (r + g + b)
            if s > best_score:
                best, best_score = (x, y), s
    ember = cell.crop((best[0], best[1], best[0] + 16, best[1] + 16))
    return lum_map(ember, RAMP_EMBER, lo_pct=0, hi_pct=100)


# =============================================================================
# C. 通用目录（同尺寸替换 + 3 色弱变体）
# =============================================================================
def build_generic(c01_salt, swarm, dasher, carrier, rail_tiers, well_tiers):
    out = {}
    # 敌人 32×32：c02 版本亮像素优先 ÷2；盐壳用 c01 侧面帧并翻转到朝右（+x 前方）
    salt = c01_salt.crop((0, 0, 64, 64)).transpose(Image.FLIP_LEFT_RIGHT)
    out["assets/art/enemies/enemy_salt_shell_walker.png"] = down2_bright(salt)
    sw = center_into(down2_bright(swarm), 32, 32)
    paint_nearest(sw, 17, 9, P["r"])  # 耳尖锈橙在 ÷2 后补画（protan/deutan 触发点）
    out["assets/art/enemies/enemy_mast_rat_swarm.png"] = sw
    out["assets/art/enemies/enemy_splitfin_dasher.png"] = down2_bright(dasher)
    ca = center_into(down2_bright(carrier), 32, 32)
    out["assets/art/enemies/enemy_rust_armor_carrier.png"] = ca
    # 塔 32×32：c02 tier2 ÷2
    out["assets/art/towers/tower_needle_rail.png"] = down2_bright(rail_tiers[1])
    out["assets/art/towers/tower_ember_well.png"] = down2_bright(well_tiers[1])
    return out


def _brightest_window(cell, size, stride=2):
    """在 cell 内按 stride 滑窗找亮度质量最大的 size×size 窗口，返回 (x, y)。"""
    px = cell.load()
    best, best_score = (0, 0), -1
    for y in range(0, cell.height - size + 1, stride):
        for x in range(0, cell.width - size + 1, stride):
            s = 0
            for dy in range(size):
                for dx in range(size):
                    r, g, b, a = px[x + dx, y + dy]
                    s += a * (r + g + b)
            if s > best_score:
                best, best_score = (x, y), s
    return best


def build_fx_hit_spark():
    """32×8 = 4帧 8×8：sparks 橙系大火花行，每帧取最亮 16×16 窗口 ÷2，
    保证每帧有可辨认的星形/十字闪光（≥5 个内容像素）。"""
    sparks = src_sparks()
    sheet = canvas(32, 8)
    for i in range(4):
        cell = sparks.crop((i * 64, 128, (i + 1) * 64, 192))  # row2 橙系大火花
        wx, wy = _brightest_window(cell, 16)
        cell = cell.crop((wx, wy, wx + 16, wy + 16))
        cell = down2_bright(cell, 2)                           # 16→8，亮像素优先
        cell = flatten_alpha(cell, 60)                         # 压成清晰像素点
        cell = lum_map(cell, RAMP_EMBER, lo_pct=0, hi_pct=100)
        paste(sheet, cell, i * 8, 0)
    px = sheet.load()                                # 尾帧冷烟点（tritan 触发）
    for x, y in ((26, 2), (29, 5), (31, 3)):
        px[x, y] = P["d"]
    return sheet


def build_fx_muzzle_flash():
    """48×16 = 3帧 16×16：explosion3 星芒帧，帧0 最强盛放 → 帧2 消散余星。
    每帧取 cell 中心 64×64 ÷4，暗辉光阈值裁掉，只留轮廓清晰的星芒。"""
    ex = src_explosion()
    px = ex.load()
    for y in range(ex.height):                         # 抠底色+红参考线
        for x in range(ex.width):
            r, g, b, a = px[x, y]
            if (r > 180 and g < 90 and b < 90) or (abs(r - 122) < 26 and abs(g - 126) < 26 and abs(b - 86) < 30):
                px[x, y] = (0, 0, 0, 0)
    # 帧0=row1c0 致密星花（最强），帧1=row1c2 四瓣花轮（衰减），帧2=row1c3 细轮廓星（消散）
    stages = [(0, 1), (2, 1), (3, 1)]
    row_y = {0: (2, 88), 1: (94, 180)}
    sheet = canvas(48, 16)
    for i, (c, r) in enumerate(stages):
        x0, x1 = c * 96 + 2, c * 96 + 94
        y0, y1 = row_y[r]
        cell = ex.crop((x0, y0, x1, y1))
        cx, cy = cell.width // 2, cell.height // 2
        cell = cell.crop((cx - 32, cy - 32, cx + 32, cy + 32))   # 中心 64×64
        cp = cell.load()                             # 暗辉光→透明，星芒轮廓浮现
        for yy in range(64):
            for xx in range(64):
                rr, gg, bb, aa = cp[xx, yy]
                if aa and (0.299 * rr + 0.587 * gg + 0.114 * bb) < 70:
                    cp[xx, yy] = (0, 0, 0, 0)
        cell = down2_bright(cell, 4)                           # 64→16
        cell = lum_map(cell, RAMP_EMBER, lo_pct=0, hi_pct=100)
        paste(sheet, cell, i * 16, 0)
    px = sheet.load()                                # 尾帧冷烟点（tritan 触发）
    for x, y in ((34, 3), (38, 12), (42, 6), (45, 10)):
        px[x, y] = P["d"]
    return sheet


# =============================================================================
# D. 清单
# =============================================================================
def write_manifests():
    for d in ("assets/art/c01/runtime", "assets/art/c02/runtime"):
        abs_d = os.path.join(ROOT, d)
        old = {}
        mp = os.path.join(abs_d, "DERIVED_MANIFEST.json")
        if os.path.exists(mp):
            old = json.load(open(mp, encoding="utf-8")).get("files", {})
        files = {}
        for name in sorted(os.listdir(abs_d)):
            if not name.endswith(".png"):
                continue
            rel = "%s/%s" % (d, name)
            ap = os.path.join(abs_d, name)
            data = open(ap, "rb").read()
            sha = hashlib.sha256(data).hexdigest()
            if rel in LINEAGE:
                entry = dict(LINEAGE[rel])
            else:
                im = Image.open(ap)
                entry = {"sha256": sha, "size": list(im.size), "bytes": len(data),
                         "sources": [dict(SRC["v2"], note="hand-authored v2 (tools/build_v2_assets.py)")],
                         "derived_at": old.get(name, {}).get("derived_at", TODAY),
                         "builder": "tools/build_v2_assets.py"}
            files[name] = entry
        manifest = {"generated_by": "tools/build_sourced_assets.py", "derived_at": TODAY,
                    "files": files}
        with open(mp, "w", encoding="utf-8") as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2, sort_keys=True)


def write_lineage():
    out = os.path.join(ROOT, "out", "sourced_assets_lineage.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump({"generated_by": "tools/build_sourced_assets.py", "derived_at": TODAY,
                   "files": LINEAGE}, f, ensure_ascii=False, indent=2, sort_keys=True)
    print("lineage ->", out)


# =============================================================================
# 审阅拼图
# =============================================================================
def build_montage():
    """out/sourced_review_montage.png：全部新资产按帧拆开平铺，NEAREST ×3，标注文件名。"""
    from PIL import ImageDraw, ImageFont
    try:
        font = ImageFont.load_default(size=20)
    except TypeError:
        font = ImageFont.load_default()
    pad, label_h, max_w = 6, 26, 1800
    blocks = []  # (label, [images])

    def strip_frames(rel, fw, fh, count, row=0):
        im = load(ROOT, rel)
        return [im.crop((i * fw, row * fh, (i + 1) * fw, (row + 1) * fh)) for i in range(count)]

    salt = load(ROOT, "assets/art/c01/runtime/enemy_salt_shell.png")
    for r, name in enumerate(("side(L)", "front(down)", "back(up)")):
        blocks.append(("c01/enemy_salt_shell row%d %s" % (r, name),
                       [salt.crop((i * 64, r * 64, (i + 1) * 64, (r + 1) * 64)) for i in range(8)]))
    rat = load(ROOT, "assets/art/c01/runtime/enemy_mast_rat.png")
    for r, name in enumerate(("side(L)", "front(down)", "back(up)")):
        blocks.append(("c01/enemy_mast_rat row%d %s" % (r, name),
                       [rat.crop((i * 64, r * 64, (i + 1) * 64, (r + 1) * 64)) for i in range(8)]))
    blocks.append(("c01/tower_needle_rail 6f", strip_frames(
        "assets/art/c01/runtime/tower_needle_rail.png", 96, 96, 6)))
    blocks.append(("c01/harbor_props 8格", strip_frames(
        "assets/art/c01/runtime/harbor_props.png", 128, 128, 8)))

    def with_variants(rel):
        stem, ext = os.path.splitext(rel)
        return [load(ROOT, rel)] + [load(ROOT, "%s_%s%s" % (stem, p, ext))
                                    for p in ("protan", "deutan", "tritan")]

    for name in ("enemy_mast_rat_swarm", "enemy_splitfin_dasher", "enemy_rust_armor_carrier"):
        blocks.append(("c02/%s base|protan|deutan|tritan" % name,
                       with_variants("assets/art/c02/runtime/%s.png" % name)))
    for name in ("tower_needle_rail", "tower_ember_well"):
        imgs = []
        for t in (1, 2, 3, 4):
            imgs += with_variants("assets/art/c02/runtime/%s_tier%d.png" % (name, t))
        blocks.append(("c02/%s tier1-4 × (base|protan|deutan|tritan)" % name, imgs))
    blocks.append(("c02/projectile_ember_burst", [load(
        ROOT, "assets/art/c02/runtime/projectile_ember_burst.png")]))
    for name in ("enemy_salt_shell_walker", "enemy_mast_rat_swarm",
                 "enemy_splitfin_dasher", "enemy_rust_armor_carrier"):
        blocks.append(("art/enemies/%s +variants" % name,
                       with_variants("assets/art/enemies/%s.png" % name)))
    for name in ("tower_needle_rail", "tower_ember_well"):
        blocks.append(("art/towers/%s +variants" % name,
                       with_variants("assets/art/towers/%s.png" % name)))
    blocks.append(("art/vfx/fx_hit_spark_strip4", strip_frames(
        "assets/art/vfx/fx_hit_spark_strip4.png", 8, 8, 4)))
    blocks.append(("art/vfx/fx_muzzle_flash_strip3", strip_frames(
        "assets/art/vfx/fx_muzzle_flash_strip3.png", 16, 16, 3)))

    # 排版
    rows = []  # (height, [(im,x,y)], label, y)
    y = pad
    placements = []
    for label, imgs in blocks:
        placements.append(("label", label, y))
        y += label_h
        x = pad
        row_h = 0
        for im in imgs:
            w3, h3 = im.width * 3, im.height * 3
            if x + w3 > max_w:
                x = pad
                y += row_h + pad
                row_h = 0
            placements.append(("img", im, x, y))
            x += w3 + pad
            row_h = max(row_h, h3)
        y += row_h + pad * 2
    sheet = Image.new("RGBA", (max_w, y), (30, 34, 40, 255))
    dr = ImageDraw.Draw(sheet)
    for item in placements:
        if item[0] == "label":
            dr.text((pad, item[2] + 2), item[1], fill=(220, 220, 210, 255), font=font)
        else:
            _, im, px_, py_ = item
            bg = Image.new("RGBA", (im.width * 3, im.height * 3), (48, 52, 60, 255))
            bg.alpha_composite(im.resize((im.width * 3, im.height * 3), Image.NEAREST))
            sheet.alpha_composite(bg, (px_, py_))
    out = os.path.join(ROOT, "out", "sourced_review_montage.png")
    sheet.save(out)
    print("montage ->", out, sheet.size)


# =============================================================================
def main():
    # A. c01
    salt = build_c01_enemy_salt_shell()
    save("assets/art/c01/runtime/enemy_salt_shell.png", salt, ["crab"])
    rat = build_c01_enemy_mast_rat()
    save("assets/art/c01/runtime/enemy_mast_rat.png", rat, ["rat"])
    save("assets/art/c01/runtime/tower_needle_rail.png", build_c01_tower_needle_rail(),
         ["turret", "v2"])
    save("assets/art/c01/runtime/harbor_props.png", build_c01_harbor_props(),
         ["ship_acc", "ship_cannon", "v2"])

    # B. c02（含色弱变体）
    swarm = build_c02_mast_rat_swarm()
    save("assets/art/c02/runtime/enemy_mast_rat_swarm.png", swarm, ["mice"], variants=True)
    dasher = build_c02_splitfin_dasher()
    save("assets/art/c02/runtime/enemy_splitfin_dasher.png", dasher, ["shark"], variants=True)
    carrier = build_c02_rust_armor_carrier()
    save("assets/art/c02/runtime/enemy_rust_armor_carrier.png", carrier, ["crab"], variants=True)
    for tier, im in enumerate(build_c02_rail_tiers(), 1):
        save("assets/art/c02/runtime/tower_needle_rail_tier%d.png" % tier, im,
             ["turret", "v2"], variants=True)
    for tier, im in enumerate(build_c02_well_tiers(), 1):
        save("assets/art/c02/runtime/tower_ember_well_tier%d.png" % tier, im,
             ["fire", "v2"], variants=True)
    save("assets/art/c02/runtime/projectile_ember_burst.png",
         build_c02_projectile_ember_burst(), ["sparks"])

    # C. 通用目录
    rail_tiers = build_c02_rail_tiers()
    well_tiers = build_c02_well_tiers()
    generic_src = {"rat": ["mice"], "crab": ["crab"], "shark": ["shark"]}
    for rel, im in build_generic(salt, swarm, dasher, carrier, rail_tiers, well_tiers).items():
        if "salt_shell" in rel:
            s = ["crab"]
        elif "mast_rat" in rel:
            s = ["mice"]
        elif "splitfin" in rel:
            s = ["shark"]
        elif "rust_armor" in rel:
            s = ["crab"]
        elif "needle_rail" in rel:
            s = ["turret", "v2"]
        else:
            s = ["fire", "v2"]
        save(rel, im, s, variants=True)
    save("assets/art/vfx/fx_hit_spark_strip4.png", build_fx_hit_spark(), ["sparks"], variants=True)
    save("assets/art/vfx/fx_muzzle_flash_strip3.png", build_fx_muzzle_flash(),
         ["explosion"], variants=True)

    # D. 清单
    write_manifests()
    write_lineage()
    build_montage()

    # 变体有效性自检：每个需要变体的文件，3 个变体的 SHA 都必须与基底不同
    bad = []
    for rel, info in LINEAGE.items():
        stem, ext = os.path.splitext(rel)
        for preset in ("protan", "deutan", "tritan"):
            vrel = "%s_%s%s" % (stem, preset, ext)
            if vrel in LINEAGE and LINEAGE[vrel]["sha256"] == info["sha256"]:
                bad.append(vrel)
    if bad:
        print("WARNING 色弱变体与基底完全相同（remap 未生效）：")
        for b in bad:
            print("  -", b)
    else:
        print("OK 全部色弱变体均与基底有差异。")
    print("共派生 %d 个文件。" % len(LINEAGE))


if __name__ == "__main__":
    main()
