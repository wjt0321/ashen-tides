#!/usr/bin/env python3
"""M4-D 第二章收口（C13–C14）资产扩展生成器（项目自有原创）。

产出：C13/C14 主题地形 tile ×8、本批新单位精灵 ×3（雾母载体/雾中医正/沼冠孢王 64×64），
单位精灵自动带 protan/deutan/tritan 色弱变体（矩阵与 scripts/ui/ui_palette.gd 一致）。
调色板对齐 scripts/ui/visual_theme.gd THEMES c13/c14。
规范见 docs/current/engineering/M4_ASSET_SPEC.md。运行：python tools/gen_chapter2b_sprites.py
"""
from gen_chapter1_sprites import OUTLINE, c8, canvas, noise_dots, poly_outlined, save, terrain_for

# 关卡调色板（对齐 visual_theme.gd THEMES c13–c14，0-1 浮点）
LEVELS = {
    "c13": {"sea_a": (.12, .20, .19), "sea_b": (.09, .16, .15), "foam": (.55, .68, .62),
            "land_a": (.28, .33, .28), "land_b": (.23, .28, .23), "edge": (.50, .60, .52)},
    "c14": {"sea_a": (.08, .14, .12), "sea_b": (.06, .11, .09), "foam": (.38, .55, .42),
            "land_a": (.24, .28, .20), "land_b": (.19, .23, .16), "edge": (.45, .52, .36)},
}


# ---------------------------------------------------------------------------
# 单位（第二章收口 ×3）
# ---------------------------------------------------------------------------

def enemy_spore_mother_carrier():
    """雾母载体：背负孢囊群的宽体运输者（召唤编码：背上 3 个鼓胀孢囊 + 裂纹）。"""
    img, d = canvas()
    body = (140, 115, 174, 255)   # 0.55,0.45,0.68
    dark = (92, 74, 118, 255)
    sac = (200, 170, 220, 255)
    # 宽椭圆体（头朝右）
    d.ellipse([3, 10, 27, 26], fill=OUTLINE)
    d.ellipse([4, 11, 26, 25], fill=body)
    # 腹线
    d.arc([6, 14, 24, 26], 20, 160, fill=dark, width=1)
    # 背上三个鼓胀孢囊（召唤视觉编码）
    for box in [[5, 2, 12, 10], [12, 0, 19, 9], [19, 3, 26, 11]]:
        d.ellipse(box, fill=OUTLINE)
        d.ellipse([box[0] + 1, box[1] + 1, box[2] - 1, box[3] - 1], fill=sac)
    # 孢囊裂纹
    d.line([(9, 4), (10, 8)], fill=dark, width=1)
    d.line([(16, 2), (15, 7)], fill=dark, width=1)
    # 头眼
    d.point((23, 15), fill=OUTLINE)
    save(img, "enemies/enemy_spore_mother_carrier.png", unit=True)


def enemy_marsh_mist_physician():
    """雾中医正（精英）：医正长袍三角身 + 药钵 + 环绕孢雾点（治疗编码，精英金边由运行时提供）。"""
    img, d = canvas()
    robe = (115, 204, 166, 255)   # 0.45,0.80,0.65
    robe_dark = (76, 148, 118, 255)
    # 长袍（梯形身）
    poly_outlined(d, [(16, 6), (24, 28), (8, 28)], robe, grow=1)
    # 腰带
    d.line([(12, 20), (20, 20)], fill=robe_dark, width=2)
    # 头部兜帽
    d.ellipse([11, 1, 21, 11], fill=OUTLINE)
    d.ellipse([12, 2, 20, 10], fill=robe_dark)
    d.point((15, 6), fill=(230, 255, 235, 255))
    d.point((18, 6), fill=(230, 255, 235, 255))
    # 手持药钵（治疗编码）
    d.ellipse([22, 14, 29, 20], fill=OUTLINE)
    d.ellipse([23, 15, 28, 19], fill=(150, 120, 90, 255))
    d.point((25, 13), fill=(220, 255, 200, 255))
    # 环绕孢雾点
    d.point((5, 10), fill=(190, 255, 210, 200))
    d.point((27, 24), fill=(190, 255, 210, 200))
    save(img, "enemies/enemy_marsh_mist_physician.png", unit=True)


def boss_marsh_crown_spore_king():
    """沼冠孢王（Boss 2，64×64）：巨型菌冠 + 王冠状菌褶棘 + 根系触须 + 核心囊（暴露窗口编码）。"""
    img, d = canvas(64, 64)
    cap = (153, 89, 140, 255)     # 0.60,0.35,0.55
    cap_dark = (102, 58, 94, 255)
    gill = (196, 140, 180, 255)
    core = (255, 214, 150, 255)
    # 根系触须（底部外伸）
    for (x0, x1, y1) in [(16, 8, 58), (26, 22, 60), (38, 42, 60), (48, 56, 58)]:
        d.line([(x0, 48), (x1, y1)], fill=OUTLINE, width=3)
        d.line([(x0, 48), (x1, y1)], fill=cap_dark, width=1)
    # 菌柄
    d.rectangle([24, 34, 40, 52], fill=OUTLINE)
    d.rectangle([25, 35, 39, 51], fill=(222, 214, 190, 255))
    # 核心囊（柄中央——暴露核心编码）
    d.ellipse([28, 38, 36, 47], fill=OUTLINE)
    d.ellipse([29, 39, 35, 46], fill=core)
    # 菌冠（大圆顶）
    d.pieslice([6, 2, 58, 40], 180, 360, fill=OUTLINE)
    d.pieslice([7, 3, 57, 39], 180, 360, fill=cap)
    # 王冠状菌褶棘（冠缘 5 棘）
    for i in range(5):
        x = 12 + i * 10
        poly_outlined(d, [(x, 8), (x + 4, 8), (x + 2, 1)], cap_dark, grow=0)
    # 菌褶放射线
    for i in range(7):
        x = 12 + i * 7
        d.line([(x, 36), (32, 22)], fill=gill, width=1)
    # 冠面孢点
    for (x, y) in [(18, 12), (30, 8), (44, 12), (24, 20), (40, 22)]:
        d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=gill)
    save(img, "enemies/enemy_boss_marsh_crown_spore_king.png", unit=True)


def main():
    for level, pal in LEVELS.items():
        terrain_for(level, pal)
    enemy_spore_mother_carrier()
    enemy_marsh_mist_physician()
    boss_marsh_crown_spore_king()
    print("M4-D chapter-2b sprites complete")


if __name__ == "__main__":
    main()
