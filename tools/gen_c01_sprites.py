#!/usr/bin/env python3
"""M4-A C01 正式切片精灵生成器（项目自有原创资产）。

全部输出 32×32（或帧条）RGBA PNG，遵循 docs/M4_ASSET_SPEC.md：
1px 深色外轮廓、C01 黄昏港岸调色板、剪影优先。
运行：python tools/gen_c01_sprites.py
产出：assets/art/{tilesets/c01,towers,enemies,characters,vfx,ui}/*.png
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUTLINE = (16, 16, 24, 255)  # #101018 深色外轮廓

# C01 黄昏港岸调色板（对齐 scripts/ui/visual_theme.gd THEMES[level_c01]）
SEA_A = (26, 43, 66, 255)
SEA_B = (20, 33, 54, 255)
FOAM = (89, 128, 153, 255)
LAND_A = (82, 69, 54, 255)
LAND_B = (69, 59, 48, 255)
LAND_EDGE = (140, 115, 82, 255)
ACCENT = (242, 140, 64, 255)
GLOW = (255, 191, 102, 255)
STEEL = (204, 230, 255, 255)
ECHO_BODY = (179, 153, 242, 255)


def canvas(w=32, h=32):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def save(img, rel):
    path = ROOT / "assets" / "art" / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print("gen:", rel)


def noise_dots(d, n, box, colors, seed):
    rng = random.Random(seed)
    for _ in range(n):
        x = rng.randint(box[0], box[2])
        y = rng.randint(box[1], box[3])
        d.point((x, y), fill=rng.choice(colors))


def poly_outlined(d, points, fill, outline=OUTLINE, grow=1):
    """先描外轮廓（各顶点向外扩 grow px 的凸包近似），再填主体。"""
    cx = sum(p[0] for p in points) / len(points)
    cy = sum(p[1] for p in points) / len(points)
    outer = []
    for x, y in points:
        dx, dy = x - cx, y - cy
        dist = max(1e-6, (dx * dx + dy * dy) ** 0.5)
        outer.append((x + dx / dist * grow, y + dy / dist * grow))
    d.polygon(outer, fill=outline)
    d.polygon(points, fill=fill)


# ---------------------------------------------------------------------------
# 地形（C01）
# ---------------------------------------------------------------------------

def terrain_sea(name, base, seed):
    img, d = canvas()
    d.rectangle([0, 0, 31, 31], fill=base)
    noise_dots(d, 14, (1, 1, 30, 30),
               [tuple(max(0, c - 6) for c in base[:3]) + (255,),
                tuple(min(255, c + 8) for c in base[:3]) + (255,)], seed)
    # 浪尖碎沫：两簇浅色小点
    noise_dots(d, 4, (4, 4, 27, 27), [tuple(list(FOAM[:3]) + [90])], seed + 1)
    save(img, f"tilesets/c01/{name}.png")


def terrain_land(name, base, seed):
    img, d = canvas()
    d.rectangle([0, 0, 31, 31], fill=base)
    noise_dots(d, 12, (1, 1, 30, 30),
               [tuple(max(0, c - 7) for c in base[:3]) + (255,),
                tuple(min(255, c + 10) for c in base[:3]) + (255,)], seed)
    # 石砾
    rng = random.Random(seed + 2)
    for _ in range(3):
        x, y = rng.randint(4, 26), rng.randint(4, 26)
        d.ellipse([x, y, x + 2, y + 2], fill=LAND_EDGE)
        d.point((x, y), fill=OUTLINE)
    save(img, f"tilesets/c01/{name}.png")


# ---------------------------------------------------------------------------
# 塔
# ---------------------------------------------------------------------------

def tower_needle_rail():
    img, d = canvas()
    # 八角基座
    poly_outlined(d, [(8, 26), (12, 22), (20, 22), (24, 26), (24, 29), (8, 29)],
                  fill=(52, 62, 78, 255))
    # 立式双轨
    d.rectangle([12, 6, 14, 23], fill=OUTLINE)
    d.rectangle([18, 6, 20, 23], fill=OUTLINE)
    d.rectangle([13, 7, 13, 22], fill=STEEL)
    d.rectangle([19, 7, 19, 22], fill=STEEL)
    # 中央轨道亮线 + 弩矢
    d.rectangle([15, 4, 17, 23], fill=OUTLINE)
    d.rectangle([16, 5, 16, 22], fill=(120, 160, 200, 255))
    poly_outlined(d, [(16, 2), (13, 8), (19, 8)], fill=STEEL)
    # 基座铆钉
    d.point([(11, 25), (21, 25)], fill=GLOW)
    save(img, "towers/tower_needle_rail.png")


def tower_ember_well():
    img, d = canvas()
    # 圆釜（椭圆 + 外轮廓）
    d.ellipse([6, 12, 26, 28], fill=OUTLINE)
    d.ellipse([7, 13, 25, 27], fill=(58, 44, 40, 255))
    # 釜口
    d.ellipse([9, 10, 23, 17], fill=OUTLINE)
    d.ellipse([10, 11, 22, 16], fill=(30, 22, 20, 255))
    # 火焰（两层）
    poly_outlined(d, [(16, 2), (11, 10), (21, 10)], fill=ACCENT)
    d.polygon([(16, 5), (13, 10), (19, 10)], fill=GLOW)
    # 铆带
    d.rectangle([8, 21, 24, 22], fill=(90, 70, 55, 255))
    d.point([(11, 21), (16, 21), (21, 21)], fill=OUTLINE)
    save(img, "towers/tower_ember_well.png")


def tower_echo_pile():
    img, d = canvas()
    # 三根桩（高低错落）
    for x, h in [(8, 16), (15, 21), (22, 13)]:
        d.rectangle([x - 1, 29 - h - 1, x + 3, 29], fill=OUTLINE)
        d.rectangle([x, 29 - h, x + 2, 28], fill=ECHO_BODY)
        d.point((x + 1, 29 - h), fill=GLOW)
    # 共鸣环（两道弧用折线近似）
    for r, alpha in [(7, 130), (11, 70)]:
        d.arc([16 - r, 20 - r, 16 + r, 20 + r], 200, 340,
              fill=(179, 153, 242, alpha), width=1)
    # 底座
    d.rectangle([5, 28, 27, 30], fill=OUTLINE)
    d.rectangle([6, 28, 26, 29], fill=(70, 60, 95, 255))
    save(img, "towers/tower_echo_pile.png")


# ---------------------------------------------------------------------------
# 敌人（C01：盐壳行者 / 桅鼠群）
# ---------------------------------------------------------------------------

def enemy_salt_shell_walker():
    img, d = canvas()
    # 腿（四只，先画在壳下）
    for x in (9, 14, 19, 24):
        d.line([(x, 20), (x - 1, 26)], fill=OUTLINE, width=2)
        d.line([(x, 20), (x - 1, 26)], fill=(120, 105, 85, 255), width=1)
    # 圆顶盐壳
    d.ellipse([5, 8, 27, 22], fill=OUTLINE)
    d.ellipse([6, 9, 26, 21], fill=(196, 190, 170, 255))
    # 壳脊高光 + 盐斑
    d.arc([9, 10, 23, 20], 200, 340, fill=(235, 230, 210, 255), width=1)
    d.point([(12, 13), (19, 11), (22, 15)], fill=(235, 230, 210, 255))
    # 头/眼
    d.ellipse([24, 14, 29, 19], fill=OUTLINE)
    d.ellipse([25, 15, 28, 18], fill=(120, 105, 85, 255))
    d.point((27, 16), fill=OUTLINE)
    save(img, "enemies/enemy_salt_shell_walker.png")


def enemy_mast_rat_swarm():
    img, d = canvas()

    def rat(cx, cy, s, body):
        d.ellipse([cx - s - 1, cy - s + 1 - 1, cx + s + 1, cy + s - 1 + 1], fill=OUTLINE)
        d.ellipse([cx - s, cy - s + 1, cx + s, cy + s - 1], fill=body)
        d.ellipse([cx + s - 1, cy - s - 1, cx + s + 3, cy - s + 3], fill=OUTLINE)
        d.ellipse([cx + s, cy - s, cx + s + 2, cy - s + 2], fill=body)
        d.point((cx + s + 1, cy - s + 1), fill=OUTLINE)
        d.line([(cx - s, cy + 1), (cx - s - 3, cy + 3)], fill=OUTLINE, width=1)

    rat(20, 18, 5, (110, 90, 80, 255))
    rat(9, 12, 4, (90, 74, 66, 255))
    rat(10, 24, 4, (90, 74, 66, 255))
    save(img, "enemies/enemy_mast_rat_swarm.png")


# ---------------------------------------------------------------------------
# 英雄（岚舟·苇：苇叶舟 + 帆，面向右，运行时按 facing 旋转）
# ---------------------------------------------------------------------------

def hero_lanzhou_wei():
    img, d = canvas()
    # 船体（梭形）
    poly_outlined(d, [(4, 18), (10, 14), (22, 14), (28, 18), (22, 22), (10, 22)],
                  fill=(74, 96, 88, 255))
    d.line([(6, 18), (26, 18)], fill=(50, 66, 60, 255), width=1)
    # 桅杆 + 苇帆
    d.line([(16, 14), (16, 4)], fill=OUTLINE, width=2)
    d.line([(16, 14), (16, 4)], fill=(120, 100, 70, 255), width=1)
    poly_outlined(d, [(17, 4), (17, 13), (25, 13)], fill=(196, 220, 190, 255))
    d.line([(18, 6), (24, 12)], fill=(150, 175, 145, 255), width=1)
    # 舟灯
    d.ellipse([6, 12, 10, 16], fill=OUTLINE)
    d.ellipse([7, 13, 9, 15], fill=GLOW)
    save(img, "characters/hero_lanzhou_wei.png")


# ---------------------------------------------------------------------------
# FX 帧条
# ---------------------------------------------------------------------------

def fx_muzzle_flash():
    img, d = canvas(48, 16)
    for i, (r, col) in enumerate([(7, (255, 240, 200, 255)), (5, (255, 200, 120, 220)),
                                  (3, (255, 160, 80, 160))]):
        cx, cy = i * 16 + 8, 8
        pts = [(cx + r, cy), (cx, cy + r), (cx - r, cy), (cx, cy - r)]
        d.polygon(pts, fill=col)
        d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=(255, 255, 240, 255))
    save(img, "vfx/fx_muzzle_flash_strip3.png")


def fx_hit_spark():
    img, d = canvas(32, 8)
    for i in range(4):
        cx, cy = i * 8 + 4, 4
        r = 3 - i * 0.6
        alpha = 255 - i * 55
        d.line([(cx - r, cy), (cx + r, cy)], fill=(255, 220, 150, alpha), width=1)
        d.line([(cx, cy - r), (cx, cy + r)], fill=(255, 220, 150, alpha), width=1)
        if i == 0:
            d.point((cx, cy), fill=(255, 255, 255, 255))
    save(img, "vfx/fx_hit_spark_strip4.png")


# ---------------------------------------------------------------------------
# UI 图标（16×16）
# ---------------------------------------------------------------------------

def icon_ember():
    img, d = canvas(16, 16)
    poly_outlined(d, [(8, 2), (4, 9), (5, 13), (11, 13), (12, 9)], fill=ACCENT)
    d.polygon([(8, 5), (6, 9), (7, 12), (9, 12), (10, 9)], fill=GLOW)
    d.polygon([(8, 8), (7, 10), (9, 10)], fill=(255, 250, 230, 255))
    save(img, "ui/icon_ember.png")


def icon_integrity():
    img, d = canvas(16, 16)
    # 舰队舷盾
    poly_outlined(d, [(8, 2), (13, 4), (13, 9), (8, 14), (3, 9), (3, 4)],
                  fill=(90, 140, 190, 255))
    d.polygon([(8, 4), (11, 5), (11, 9), (8, 12), (5, 9), (5, 5)],
              fill=(150, 200, 240, 255))
    d.line([(8, 4), (8, 12)], fill=OUTLINE, width=1)
    save(img, "ui/icon_integrity.png")


def icon_becon():
    img, d = canvas(16, 16)
    # 航标灯
    d.polygon([(8, 2), (5, 8), (11, 8)], fill=OUTLINE)
    d.polygon([(8, 3), (6, 7), (10, 7)], fill=GLOW)
    d.rectangle([6, 8, 10, 13], fill=OUTLINE)
    d.rectangle([7, 9, 9, 12], fill=(90, 140, 190, 255))
    d.point([(4, 5), (12, 5)], fill=(255, 220, 150, 160))
    save(img, "ui/icon_becon.png")


def icon_wave():
    img, d = canvas(16, 16)
    d.arc([2, 3, 10, 11], 180, 360, fill=OUTLINE, width=3)
    d.arc([2, 3, 10, 11], 180, 360, fill=FOAM, width=2)
    d.arc([7, 7, 15, 15], 180, 360, fill=OUTLINE, width=3)
    d.arc([7, 7, 15, 15], 180, 360, fill=SEA_A, width=2)
    save(img, "ui/icon_wave.png")


def main():
    terrain_sea("terrain_sea_a", SEA_A, 101)
    terrain_sea("terrain_sea_b", SEA_B, 102)
    terrain_land("terrain_land_a", LAND_A, 103)
    terrain_land("terrain_land_b", LAND_B, 104)
    tower_needle_rail()
    tower_ember_well()
    tower_echo_pile()
    enemy_salt_shell_walker()
    enemy_mast_rat_swarm()
    hero_lanzhou_wei()
    fx_muzzle_flash()
    fx_hit_spark()
    icon_ember()
    icon_integrity()
    icon_becon()
    icon_wave()
    print("done: 16 sprites")


if __name__ == "__main__":
    main()
