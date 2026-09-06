#!/usr/bin/env python3
"""M4-B 第一章（C01–C08）正式资产扩展生成器（项目自有原创）。

补齐：其余 3 塔、第二英雄、第一章实际出场的 9 种敌人（含 Boss）、C02–C08 主题地形 tile，
并为单位精灵生成色弱变体（protan/deutan/tritan，矩阵与 scripts/ui/ui_palette.gd 一致）。
规范见 docs/current/engineering/M4_ASSET_SPEC.md。运行：python tools/gen_chapter1_sprites.py
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUTLINE = (16, 16, 24, 255)
GLOW = (255, 191, 102, 255)
ACCENT = (242, 140, 64, 255)

# 关卡调色板（对齐 scripts/ui/visual_theme.gd THEMES，0-1 浮点）
LEVELS = {
    "c02": {"sea_a": (.12, .22, .26), "sea_b": (.09, .17, .21), "foam": (.45, .62, .65),
            "land_a": (.30, .30, .26), "land_b": (.25, .25, .22), "edge": (.50, .52, .45)},
    "c03": {"sea_a": (.07, .10, .22), "sea_b": (.05, .08, .17), "foam": (.30, .38, .62),
            "land_a": (.20, .18, .26), "land_b": (.16, .15, .22), "edge": (.38, .34, .50)},
    "c04": {"sea_a": (.14, .30, .34), "sea_b": (.11, .24, .28), "foam": (.62, .80, .80),
            "land_a": (.55, .54, .48), "land_b": (.47, .46, .41), "edge": (.75, .74, .66)},
    "c05": {"sea_a": (.10, .20, .16), "sea_b": (.08, .16, .13), "foam": (.38, .55, .42),
            "land_a": (.33, .26, .18), "land_b": (.27, .21, .15), "edge": (.52, .42, .28)},
    "c06": {"sea_a": (.08, .18, .22), "sea_b": (.06, .14, .18), "foam": (.35, .50, .52),
            "land_a": (.36, .24, .18), "land_b": (.30, .20, .15), "edge": (.58, .38, .25)},
    "c07": {"sea_a": (.11, .12, .24), "sea_b": (.08, .09, .19), "foam": (.42, .45, .66),
            "land_a": (.26, .24, .30), "land_b": (.21, .20, .25), "edge": (.45, .42, .55)},
    "c08": {"sea_a": (.06, .05, .12), "sea_b": (.04, .04, .09), "foam": (.28, .22, .42),
            "land_a": (.18, .12, .16), "land_b": (.14, .10, .13), "edge": (.35, .20, .26)},
}


def c8(rgb):
    return (round(rgb[0] * 255), round(rgb[1] * 255), round(rgb[2] * 255), 255)


def canvas(w=32, h=32):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def poly_outlined(d, points, fill, outline=OUTLINE, grow=1):
    cx = sum(p[0] for p in points) / len(points)
    cy = sum(p[1] for p in points) / len(points)
    outer = []
    for x, y in points:
        dx, dy = x - cx, y - cy
        dist = max(1e-6, (dx * dx + dy * dy) ** 0.5)
        outer.append((x + dx / dist * grow, y + dy / dist * grow))
    d.polygon(outer, fill=outline)
    d.polygon(points, fill=fill)


def noise_dots(d, n, box, colors, seed):
    rng = random.Random(seed)
    for _ in range(n):
        d.point((rng.randint(box[0], box[2]), rng.randint(box[1], box[3])), fill=rng.choice(colors))


def save(img, rel, unit=False):
    """unit=True 时同时生成 3 个色弱变体（_<preset>.png）。"""
    path = ROOT / "assets" / "art" / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)
    print("gen:", rel)
    if unit:
        for preset in ("protan", "deutan", "tritan"):
            variant = remap_preset(img, preset)
            vpath = path.with_name(path.stem + "_" + preset + path.suffix)
            variant.save(vpath)
        print("     +3 colorblind variants")


def remap_preset(img, preset):
    """逐像素重映射，矩阵与 UiPalette.apply 一致（0-1 浮点域）。"""
    out = img.copy()
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            rf, gf, bf = r / 255.0, g / 255.0, b / 255.0
            if preset in ("protan", "deutan"):
                if rf > bf + 0.15 and gf < rf:
                    rf, gf, bf = gf * 0.7 + 0.15, gf, min(bf + 0.35, 1.0)
                elif gf > bf + 0.15:
                    rf, gf, bf = rf, gf * 0.8, min(bf + 0.3, 1.0)
            elif preset == "tritan":
                if bf > rf + 0.15:
                    rf, gf, bf = min(rf + 0.3, 1.0), gf, bf * 0.6
            px[x, y] = (round(rf * 255), round(gf * 255), round(bf * 255), a)
    return out


# ---------------------------------------------------------------------------
# 地形（C02–C08 每关 sea/land 主题变体）
# ---------------------------------------------------------------------------

def terrain_for(level, pal):
    seed_base = int(level[1:]) * 100
    for name, key in [("sea_a", "sea_a"), ("sea_b", "sea_b")]:
        img, d = canvas()
        base = c8(pal[key])
        d.rectangle([0, 0, 31, 31], fill=base)
        noise_dots(d, 14, (1, 1, 30, 30),
                   [tuple(max(0, c - 6) for c in base[:3]) + (255,),
                    tuple(min(255, c + 8) for c in base[:3]) + (255,)], seed_base)
        foam = c8(pal["foam"])
        noise_dots(d, 4, (4, 4, 27, 27), [foam[:3] + (90,)], seed_base + 1)
        save(img, f"tilesets/{level}/terrain_{name}.png")
    for name, key in [("land_a", "land_a"), ("land_b", "land_b")]:
        img, d = canvas()
        base = c8(pal[key])
        d.rectangle([0, 0, 31, 31], fill=base)
        noise_dots(d, 12, (1, 1, 30, 30),
                   [tuple(max(0, c - 7) for c in base[:3]) + (255,),
                    tuple(min(255, c + 10) for c in base[:3]) + (255,)], seed_base + 3)
        rng = random.Random(seed_base + 5)
        edge = c8(pal["edge"])
        for _ in range(3):
            x, y = rng.randint(4, 26), rng.randint(4, 26)
            d.ellipse([x, y, x + 2, y + 2], fill=edge)
            d.point((x, y), fill=OUTLINE)
        save(img, f"tilesets/{level}/terrain_{name}.png")


# ---------------------------------------------------------------------------
# 塔（补 3：风巢 / 潮汐砧 / 棱光晶簇）
# ---------------------------------------------------------------------------

def tower_wind_nest():
    img, d = canvas()
    # 立杆 + 巢座
    d.rectangle([14, 12, 18, 28], fill=OUTLINE)
    d.rectangle([15, 13, 17, 27], fill=(90, 110, 95, 255))
    d.ellipse([8, 24, 24, 31], fill=OUTLINE)
    d.ellipse([9, 25, 23, 30], fill=(70, 88, 75, 255))
    # 四叶风车
    for ang_pts in [[(16, 3), (13, 9), (19, 9)], [(25, 12), (19, 9), (19, 15)],
                    [(16, 21), (19, 15), (13, 15)], [(7, 12), (13, 15), (13, 9)]]:
        poly_outlined(d, ang_pts, fill=(170, 200, 185, 255))
    d.ellipse([14, 10, 18, 14], fill=OUTLINE)
    d.ellipse([15, 11, 17, 13], fill=GLOW)
    save(img, "towers/tower_wind_nest.png", unit=True)


def tower_tide_anvil():
    img, d = canvas()
    # 砧体（横放）
    poly_outlined(d, [(5, 14), (12, 11), (20, 11), (27, 14), (22, 17), (10, 17)],
                  fill=(95, 120, 145, 255))
    # 砧柱 + 底座
    d.rectangle([12, 17, 20, 25], fill=OUTLINE)
    d.rectangle([13, 17, 19, 24], fill=(70, 90, 110, 255))
    d.rectangle([8, 25, 24, 29], fill=OUTLINE)
    d.rectangle([9, 25, 23, 28], fill=(55, 70, 88, 255))
    # 潮光锤纹
    d.line([(8, 13), (24, 13)], fill=(150, 190, 220, 255), width=1)
    d.point([(16, 6), (16, 8)], fill=GLOW)
    d.arc([13, 2, 19, 8], 0, 180, fill=(150, 190, 220, 180), width=1)
    save(img, "towers/tower_tide_anvil.png", unit=True)


def tower_prism_grove():
    img, d = canvas()
    # 三晶簇（高低错落）
    poly_outlined(d, [(7, 28), (7, 16), (10, 10), (13, 16), (13, 28)], fill=(150, 170, 220, 255))
    poly_outlined(d, [(13, 28), (13, 10), (16, 3), (19, 10), (19, 28)], fill=(190, 205, 245, 255))
    poly_outlined(d, [(19, 28), (19, 18), (23, 13), (26, 18), (26, 28)], fill=(130, 150, 200, 255))
    # 晶面高光
    d.line([(16, 5), (16, 26)], fill=(230, 240, 255, 255), width=1)
    d.line([(10, 12), (10, 26)], fill=(200, 215, 250, 255), width=1)
    d.rectangle([5, 27, 27, 30], fill=OUTLINE)
    d.rectangle([6, 28, 26, 29], fill=(70, 80, 110, 255))
    save(img, "towers/tower_prism_grove.png", unit=True)


# ---------------------------------------------------------------------------
# 英雄（筑守·暮恩：工匠锤影）
# ---------------------------------------------------------------------------

def hero_zhushou_muen():
    img, d = canvas()
    # 身体（敦实方块人形，面向右）
    poly_outlined(d, [(10, 28), (10, 16), (13, 12), (21, 12), (23, 16), (23, 28)],
                  fill=(140, 110, 90, 255))
    # 围裙
    d.rectangle([12, 18, 21, 27], fill=(90, 75, 65, 255))
    d.line([(12, 18), (21, 18)], fill=OUTLINE, width=1)
    # 头 + 护目镜
    d.ellipse([12, 4, 22, 13], fill=OUTLINE)
    d.ellipse([13, 5, 21, 12], fill=(170, 140, 110, 255))
    d.rectangle([14, 7, 21, 9], fill=(120, 180, 220, 255))
    # 锻锤（斜举）
    d.line([(22, 16), (27, 8)], fill=OUTLINE, width=3)
    d.line([(22, 16), (27, 8)], fill=(110, 85, 60, 255), width=1)
    d.rectangle([24, 3, 31, 9], fill=OUTLINE)
    d.rectangle([25, 4, 30, 8], fill=(150, 160, 175, 255))
    save(img, "characters/hero_zhushou_muen.png", unit=True)


# ---------------------------------------------------------------------------
# 敌人（9 种，+x 为前方；Boss 64×64）
# ---------------------------------------------------------------------------

def enemy_rust_armor_carrier():
    img, d = canvas()
    # 方块重甲（锈色铆板）
    poly_outlined(d, [(6, 24), (6, 10), (11, 6), (24, 6), (28, 10), (28, 24)],
                  fill=(120, 80, 55, 255))
    d.rectangle([8, 12, 26, 22], fill=(95, 62, 42, 255))
    d.line([(8, 17), (26, 17)], fill=OUTLINE, width=1)
    d.line([(17, 12), (17, 22)], fill=OUTLINE, width=1)
    for p in [(10, 14), (24, 14), (10, 20), (24, 20)]:
        d.point(p, fill=(160, 110, 75, 255))
    # 腿
    for x in (10, 22):
        d.line([(x, 24), (x, 28)], fill=OUTLINE, width=2)
    save(img, "enemies/enemy_rust_armor_carrier.png", unit=True)


def enemy_splitfin_dasher():
    img, d = canvas()
    # 长梭鱼 + 叉尾
    poly_outlined(d, [(4, 16), (10, 11), (22, 11), (28, 16), (22, 21), (10, 21)],
                  fill=(90, 140, 160, 255))
    poly_outlined(d, [(4, 16), (8, 11), (8, 21)], fill=(70, 110, 130, 255))
    d.line([(6, 13), (2, 9)], fill=OUTLINE, width=2)
    d.line([(6, 19), (2, 23)], fill=OUTLINE, width=2)
    d.ellipse([22, 13, 25, 16], fill=OUTLINE)
    d.point((23, 14), fill=(220, 240, 250, 255))
    d.line([(12, 12), (18, 12)], fill=(140, 190, 210, 255), width=1)
    save(img, "enemies/enemy_splitfin_dasher.png", unit=True)


def enemy_brine_spitter():
    img, d = canvas()
    # 喷吐者：圆腹 + 上扬喷管
    d.ellipse([6, 12, 24, 28], fill=OUTLINE)
    d.ellipse([7, 13, 23, 27], fill=(70, 110, 90, 255))
    d.line([(20, 14), (27, 6)], fill=OUTLINE, width=4)
    d.line([(20, 14), (27, 6)], fill=(100, 150, 120, 255), width=2)
    d.ellipse([25, 4, 29, 8], fill=(160, 210, 170, 255))
    d.ellipse([10, 15, 14, 19], fill=OUTLINE)
    d.point((12, 17), fill=(220, 255, 230, 255))
    d.point([(11, 24), (15, 25), (19, 23)], fill=(100, 150, 120, 255))
    save(img, "enemies/enemy_brine_spitter.png", unit=True)


def enemy_lamp_leech():
    img, d = canvas()
    # 水蛭身 + 诱灯
    poly_outlined(d, [(5, 20), (10, 15), (20, 14), (27, 18), (20, 22), (10, 23)],
                  fill=(80, 60, 95, 255))
    d.line([(24, 15), (27, 7)], fill=OUTLINE, width=2)
    d.ellipse([25, 3, 30, 8], fill=OUTLINE)
    d.ellipse([26, 4, 29, 7], fill=(255, 230, 140, 255))
    for i in range(3):
        d.arc([8 + i * 4, 15, 14 + i * 4, 23], 90, 270, fill=(110, 85, 130, 255), width=1)
    d.point((8, 19), fill=OUTLINE)
    save(img, "enemies/enemy_lamp_leech.png", unit=True)


def enemy_reef_sapper():
    img, d = canvas()
    # 掘进蟹：扁身 + 钻钳
    d.ellipse([6, 12, 24, 24], fill=OUTLINE)
    d.ellipse([7, 13, 23, 23], fill=(105, 85, 70, 255))
    d.line([(8, 14), (22, 14)], fill=(140, 115, 90, 255), width=1)
    poly_outlined(d, [(24, 13), (30, 10), (30, 15)], fill=(150, 125, 95, 255))
    poly_outlined(d, [(24, 20), (30, 18), (29, 23)], fill=(150, 125, 95, 255))
    for x in (9, 14, 19):
        d.line([(x, 23), (x - 1, 27)], fill=OUTLINE, width=2)
    d.point([(12, 17), (18, 17)], fill=OUTLINE)
    save(img, "enemies/enemy_reef_sapper.png", unit=True)


def enemy_salt_mender():
    img, d = canvas()
    # 修补者：圆顶 + 十字徽记（治疗者）
    d.ellipse([6, 8, 26, 24], fill=OUTLINE)
    d.ellipse([7, 9, 25, 23], fill=(170, 185, 175, 255))
    d.rectangle([14, 11, 18, 20], fill=(230, 245, 235, 255))
    d.rectangle([11, 14, 21, 17], fill=(230, 245, 235, 255))
    d.rectangle([14, 11, 18, 20], outline=OUTLINE)
    d.rectangle([11, 14, 21, 17], outline=OUTLINE)
    for x in (9, 15, 21):
        d.line([(x, 24), (x, 28)], fill=OUTLINE, width=2)
    d.arc([10, 9, 22, 19], 200, 340, fill=(210, 225, 215, 255), width=1)
    save(img, "enemies/enemy_salt_mender.png", unit=True)


def enemy_tide_back_navigator():
    img, d = canvas()
    # 引潮员：螺壳 + 导航天线旗
    d.ellipse([5, 10, 23, 26], fill=OUTLINE)
    d.ellipse([6, 11, 22, 25], fill=(85, 105, 135, 255))
    d.arc([9, 13, 19, 23], 0, 300, fill=(130, 155, 190, 255), width=2)
    d.line([(20, 12), (24, 4)], fill=OUTLINE, width=2)
    poly_outlined(d, [(24, 4), (30, 6), (24, 9)], fill=(255, 210, 120, 255))
    d.ellipse([22, 16, 27, 21], fill=OUTLINE)
    d.ellipse([23, 17, 26, 20], fill=(120, 145, 180, 255))
    save(img, "enemies/enemy_tide_back_navigator.png", unit=True)


def enemy_tideglass_runner():
    img, d = canvas()
    # 潮晶跑者：透明晶钻身 + 细腿快跑
    poly_outlined(d, [(16, 5), (24, 13), (20, 22), (12, 22), (8, 13)],
                  fill=(150, 200, 220, 200))
    d.line([(16, 5), (16, 22)], fill=(220, 245, 255, 220), width=1)
    d.line([(8, 13), (24, 13)], fill=(190, 225, 240, 180), width=1)
    for pts in [[(12, 22), (9, 28)], [(20, 22), (23, 28)], [(16, 22), (16, 28)]]:
        d.line(pts, fill=OUTLINE, width=1)
        d.line(pts, fill=(170, 210, 230, 255), width=1)
    d.point((18, 11), fill=OUTLINE)
    save(img, "enemies/enemy_tideglass_runner.png", unit=True)


def boss_anchor_crab_king():
    img, d = canvas(64, 64)
    # 巨螯 + 锚冠蟹王
    d.ellipse([10, 20, 54, 52], fill=OUTLINE)
    d.ellipse([11, 21, 53, 51], fill=(120, 45, 50, 255))
    # 壳甲片
    for arc_box in [[16, 24, 48, 46], [20, 27, 44, 44]]:
        d.arc(arc_box, 200, 340, fill=(160, 70, 70, 255), width=2)
    # 锚冠
    d.line([(32, 20), (32, 8)], fill=OUTLINE, width=4)
    d.line([(32, 20), (32, 8)], fill=(150, 160, 175, 255), width=2)
    d.arc([24, 8, 40, 22], 0, 180, fill=OUTLINE, width=4)
    d.arc([24, 8, 40, 22], 0, 180, fill=(150, 160, 175, 255), width=2)
    d.line([(26, 10), (26, 6)], fill=OUTLINE, width=3)
    d.line([(38, 10), (38, 6)], fill=OUTLINE, width=3)
    # 双螯
    poly_outlined(d, [(10, 34), (2, 26), (6, 40)], fill=(140, 55, 60, 255))
    poly_outlined(d, [(54, 34), (62, 26), (58, 40)], fill=(140, 55, 60, 255))
    # 眼
    d.ellipse([24, 28, 29, 33], fill=OUTLINE)
    d.ellipse([35, 28, 40, 33], fill=OUTLINE)
    d.point((26, 30), fill=(255, 220, 120, 255))
    d.point((37, 30), fill=(255, 220, 120, 255))
    # 腿
    for x in (16, 26, 38, 48):
        d.line([(x, 50), (x - 2, 58)], fill=OUTLINE, width=3)
    save(img, "enemies/enemy_anchor_crab_king.png", unit=True)


def main():
    for level, pal in LEVELS.items():
        terrain_for(level, pal)
    tower_wind_nest()
    tower_tide_anvil()
    tower_prism_grove()
    hero_zhushou_muen()
    enemy_rust_armor_carrier()
    enemy_splitfin_dasher()
    enemy_brine_spitter()
    enemy_lamp_leech()
    enemy_reef_sapper()
    enemy_salt_mender()
    enemy_tide_back_navigator()
    enemy_tideglass_runner()
    boss_anchor_crab_king()
    print("done: 28 terrain + 13 units (+39 variants)")


if __name__ == "__main__":
    main()
