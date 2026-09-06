#!/usr/bin/env python3
"""M4-C 第二章首批（C09–C12）资产扩展生成器（项目自有原创）。

产出：C09–C12 主题地形 tile ×16、本批新敌人精灵 ×3（芦丛潜行者/孢光医者/倒映影魅），
单位精灵自动带 protan/deutan/tritan 色弱变体（矩阵与 scripts/ui/ui_palette.gd 一致）。
调色板对齐 scripts/ui/visual_theme.gd THEMES（第二章「玻璃沼泽」）。
规范见 docs/current/engineering/M4_ASSET_SPEC.md。运行：python tools/gen_chapter2_sprites.py
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw

from gen_chapter1_sprites import OUTLINE, c8, canvas, noise_dots, poly_outlined, save, terrain_for

# 关卡调色板（对齐 visual_theme.gd THEMES c09–c12，0-1 浮点）
LEVELS = {
    "c09": {"sea_a": (.10, .24, .22), "sea_b": (.08, .19, .18), "foam": (.50, .75, .68),
            "land_a": (.30, .38, .28), "land_b": (.25, .32, .24), "edge": (.55, .68, .50)},
    "c10": {"sea_a": (.09, .20, .14), "sea_b": (.07, .16, .11), "foam": (.45, .72, .45),
            "land_a": (.26, .34, .20), "land_b": (.21, .28, .17), "edge": (.50, .62, .38)},
    "c11": {"sea_a": (.12, .16, .26), "sea_b": (.09, .13, .21), "foam": (.55, .62, .78),
            "land_a": (.30, .30, .36), "land_b": (.25, .25, .30), "edge": (.55, .55, .65)},
    "c12": {"sea_a": (.07, .16, .15), "sea_b": (.05, .12, .12), "foam": (.35, .55, .50),
            "land_a": (.32, .26, .18), "land_b": (.26, .21, .15), "edge": (.55, .45, .30)},
}


# ---------------------------------------------------------------------------
# 敌人（第二章首批 ×3）
# ---------------------------------------------------------------------------

def enemy_reed_stalker():
    """芦丛潜行者：苇叶绿狭长梭形 + 苇叶背饰 +  slit 眼（隐匿编码：低饱和青绿）。"""
    img, d = canvas()
    body = (89, 140, 102, 255)   # 0.35,0.55,0.40
    light = (115, 168, 128, 255)
    dark = (58, 92, 66, 255)
    # 背饰苇叶（后缘三片）
    for i, (bx, by, ang) in enumerate([(8, 10, -1), (7, 16, 0), (8, 22, 1)]):
        poly_outlined(d, [(bx, by), (bx - 5, by + ang * 3), (bx + 2, by + ang * 2)], dark, grow=1)
    # 梭形身体（头朝右）
    poly_outlined(d, [(26, 16), (14, 10), (6, 13), (4, 16), (6, 19), (14, 22)], body, grow=1)
    # 体侧高光
    d.line([(10, 13), (20, 14)], fill=light, width=1)
    # slit 眼（隐匿者竖瞳）
    d.line([(20, 13), (20, 17)], fill=OUTLINE, width=1)
    d.point((20, 15), fill=(200, 230, 200, 255))
    save(img, "enemies/enemy_reed_stalker.png", unit=True)


def enemy_spore_mender():
    """孢光医者：菌盖圆顶 + 荧光孢点 + 头顶白十字（治疗编码，对齐 salt_mender 语言）。"""
    img, d = canvas()
    cap = (140, 217, 140, 255)   # 0.55,0.85,0.55
    cap_dark = (96, 160, 102, 255)
    glow_spot = (220, 255, 170, 255)
    # 菌柄
    d.rectangle([13, 18, 19, 27], fill=OUTLINE)
    d.rectangle([14, 18, 18, 26], fill=(222, 230, 200, 255))
    # 菌盖（半圆顶）
    d.pieslice([6, 4, 26, 22], 180, 360, fill=OUTLINE)
    d.pieslice([7, 5, 25, 21], 180, 360, fill=cap)
    d.chord([9, 8, 23, 20], 200, 340, fill=cap_dark)
    # 孢点
    d.ellipse([11, 8, 14, 11], fill=glow_spot)
    d.ellipse([18, 9, 21, 12], fill=glow_spot)
    # 头顶白十字（治疗编码）
    d.rectangle([15, 0, 17, 5], fill=(255, 255, 255, 235))
    d.rectangle([13, 2, 19, 4], fill=(255, 255, 255, 235))
    save(img, "enemies/enemy_spore_mender.png", unit=True)


def enemy_mirror_shade():
    """倒映影魅：左右半明半暗菱形（双相编码）+ 中央镜面分割线 + 浮光点。"""
    img, d = canvas()
    light = (153, 140, 217, 255)  # 0.60,0.55,0.85
    dark = (70, 62, 115, 255)
    sheen = (220, 225, 255, 255)
    # 外轮廓菱形（头朝右的整体微前倾）
    poly_outlined(d, [(16, 3), (28, 16), (16, 29), (4, 16)], dark, grow=1)
    # 左暗右明两半
    d.polygon([(16, 5), (10, 16), (16, 27), (6, 16)], fill=dark)
    d.polygon([(16, 5), (26, 16), (16, 27), (10, 16)], fill=light)
    # 镜面分割线
    d.line([(16, 5), (16, 27)], fill=sheen, width=1)
    # 浮光点（双相各一）
    d.point((12, 12), fill=sheen)
    d.point((20, 20), fill=sheen)
    save(img, "enemies/enemy_mirror_shade.png", unit=True)


def main():
    for level, pal in LEVELS.items():
        terrain_for(level, pal)
    enemy_reed_stalker()
    enemy_spore_mender()
    enemy_mirror_shade()
    print("M4-C chapter-2 sprites complete")


if __name__ == "__main__":
    main()
