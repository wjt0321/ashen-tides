#!/usr/bin/env python3
"""《余烬潮汐》v2 自绘像素资产作者库。

作者网格 = 运行时尺寸 / 2（NEAREST ×2），统一像素语言：作者 1px 轮廓 = 运行时 2px。
色板角色锁定见 docs/current/art/ART_STYLE_BASELINE.md §4：
炭黑轮廓 / 冷青灰敌与环境 / 羊皮白高光 / 暖珊瑚己方 / 低饱和铜木。
值结构规则：暗部占主体面积，亮部只作顶左受光与焦点；轮廓 K 必须闭合。
"""
from PIL import Image

# --- 色板 -------------------------------------------------------------------
PAL = {
    ".": None,
    "K": (13, 21, 28, 255),       # 炭黑轮廓
    "k": (24, 34, 40, 255),       # 次轮廓/深缝
    "S": (49, 67, 70, 255),       # 石暗
    "T": (90, 113, 108, 255),     # 石中
    "L": (154, 184, 164, 255),    # 石亮
    "P": (232, 221, 200, 255),    # 羊皮白
    "p": (124, 118, 102, 255),    # 沙中（压暗）
    "q": (96, 92, 80, 255),       # 沙暗
    "s": (150, 142, 122, 255),    # 沙亮斑
    "W": (30, 74, 86, 255),       # 深海
    "V": (45, 104, 112, 255),     # 海中
    "w": (75, 176, 174, 255),     # 潮光
    "c": (156, 239, 220, 255),    # 潮高光
    "G": (66, 52, 40, 255),       # 铜木暗
    "g": (104, 82, 60, 255),      # 铜木中
    "b": (150, 118, 82, 255),     # 铜木亮
    "E": (239, 96, 55, 255),      # 余烬珊瑚
    "O": (255, 181, 87, 255),     # 灯暖
    "Y": (255, 241, 177, 255),    # 灯芯
    "M": (122, 102, 64, 255),     # 黄铜暗
    "m": (196, 168, 104, 255),    # 黄铜亮
    "D": (39, 58, 66, 255),       # 敌甲暗
    "d": (63, 96, 104, 255),      # 敌甲中
    "e": (111, 168, 168, 255),    # 敌甲亮
    "R": (126, 62, 48, 255),      # 锈红
    "r": (178, 96, 66, 255),      # 锈亮
}


def render(rows, scale=1):
    h = len(rows)
    w = max(len(r) for r in rows)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            c = PAL.get(ch)
            if c:
                px[x, y] = c
    if scale != 1:
        im = im.resize((w * scale, h * scale), Image.NEAREST)
    return im


def x2(im):
    return im.resize((im.width * 2, im.height * 2), Image.NEAREST)


def remap(im, preset):
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            rf, gf, bf = r / 255, g / 255, b / 255
            if preset in ("protan", "deutan"):
                if rf > bf + 0.15 and gf < rf:
                    rf, gf, bf = gf * 0.7 + 0.15, gf, min(bf + 0.35, 1)
                elif gf > bf + 0.15:
                    rf, gf, bf = rf, gf * 0.8, min(bf + 0.3, 1)
            elif preset == "tritan" and bf > rf + 0.15:
                rf, gf, bf = min(rf + 0.3, 1), gf, bf * 0.6
            px[x, y] = (round(rf * 255), round(gf * 255), round(bf * 255), a)
    return out


# --- 地形 tile（作者 16×16 → 运行时 32×32）-----------------------------------
TILE_WATER_A = [
    "VVVVVVVVVVVVVVVV",
    "VWVVVVVVVVVVVVVV",
    "VVwVVVVVVVVWVVVV",
    "VVVwVVVVVVVwVVVV",
    "VVWVVVVVVVVwVVVV",
    "VVVVVVcVVVVVVVVV",
    "VVVVWVVVVVVVVVVV",
    "VVVVVVwVVVVVVVVV",
    "VVVVVVwVVVVWVVVV",
    "VVVVVVVVVVVVVVVV",
    "VVWVVVVVVVVVVVVV",
    "VVVwVVVVVVVVVVVV",
    "VVVVwVVVVVVWwVVV",
    "VVVVWVVVVVVwVVVV",
    "VVVVVVVVcVVVVVVV",
    "VVVVVVVVVVVVVVVV",
]
TILE_WATER_B = [
    "VVVVVVVVVVVVVVVV",
    "VVVVVVVVVWVVVVVV",
    "VVVVVVVVVwVVVVVV",
    "VVVVVVVVVVVVVVVV",
    "VVwVVVVVVVVVVVVV",
    "VVwVVVVVVVVWVVVV",
    "VVVVVVcVVVVVVVVV",
    "VVVVVVVVVVVVVVVV",
    "VVVVVVVwVVVVVVVV",
    "VVVVVVVVwVVVVVVV",
    "VVVWVVVVVVVVVVVV",
    "VVVVwVVVVVVVVVVV",
    "VVVVVVVVVVVVWVVV",
    "VVVVVVVVVVVVwVVV",
    "VVVVVVVVVVVVVVVV",
    "VVVVVVVVVVVVVVVV",
]
TILE_REEF = [
    "WWWWWWWWWWWWWWWW",
    "WWWWWWWWWWWWWWWW",
    "WWWKKKKKKKKWWWWW",
    "WWKSSSSSSSSKWWWW",
    "WKSTTSSSSTTSKcWW",
    "WKSTTTSSSTTSKcWW",
    "WKSSSTTSSSTSKcWW",
    "WKSSSSSSSSSSKcWW",
    "WKkSSSSSSSSkKcWW",
    "WWKkkSSSSkkKKWcW",
    "WWWKKKKKKKKWWcWW",
    "WWWWWWWWWWWWWWWW",
    "WWWWWWWWWWWWWWWW",
    "WWWWWWWWWWWWWWWW",
    "WWWWWWWWWWWWWWWW",
    "WWWWWWWWWWWWWWWW",
]
TILE_SAND = [
    "pppppppppppppppp",
    "pqpppppppppppppp",
    "ppppppppppqppppp",
    "pppppppppppppppp",
    "ppppsppppppppppp",
    "ppppppppppppppqp",
    "pppppppppppppppp",
    "pppppppppppppppp",
    "pqpppppppppppppp",
    "ppppppppppppqppp",
    "pppppppppppppppp",
    "pppppppppppppppp",
    "ppppsppppppppppp",
    "pppppppppppppppp",
    "ppppppppppppqppp",
    "pppppppppppppppp",
]
TILE_DOCK = [
    "KKKKKKKKKKKKKKKK",
    "ggbbggggggbbgggg",
    "gggggggggggggggg",
    "GgggggggggggggGg",
    "KKKKKKKKKKKKKKKK",
    "ggggggbbgggggggg",
    "gggggggggggggggg",
    "gGggggggggggggGg",
    "KKKKKKKKKKKKKKKK",
    "ggbbggggggggbbgg",
    "gggggggggggggggg",
    "GgggggggggggggGg",
    "KKKKKKKKKKKKKKKK",
    "ggggggggbbgggggg",
    "gggggggggggggggg",
    "gGggggggggggggGg",
]
TILE_STONE_PATH = [
    "kkkkkkkkkkkkkkkk",
    "kTTkTTTkTTkTTTkk",
    "kTTkTTTkTTkTTTkk",
    "kkkkkkkkkkkkkkkk",
    "kTTTkTTkTTTkTTkk",
    "kTTTkTTkTTTkTTkk",
    "kkkkkkkkkkkkkkkk",
    "kTTkTTTkTTkTTTkk",
    "kTTkTTTkTTkTTTkk",
    "kkkkkkkkkkkkkkkk",
    "kTTTkTTkTTTkTTkk",
    "kTTTkTTkTTTkTTkk",
    "kkkkkkkkkkkkkkkk",
    "kTTkTTTkTTkTTTkk",
    "kTTkTTTkTTkTTTkk",
    "kkkkkkkkkkkkkkkk",
]
TILE_WALL_TOP = [
    "KKKKKKKKKKKKKKKK",
    "KLLLLLLLLLLLLLLK",
    "KTTTTTTTTTTTTTTK",
    "KTTTTTTTTTTTTTTK",
    "KKKKKKKKKKKKKKKK",
    "KSSSSSSSSSSSSSSK",
    "KSSkSSSSSSkSSSSK",
    "KSSSSSSSSSSSSSSK",
    "KKKKKKKKKKKKKKKK",
    "KTTTTTTTTTTTTTTK",
    "KSSSkSSSSSSkSSSK",
    "KSSSSSSSSSSSSSSK",
    "KKKKKKKKKKKKKKKK",
    "KSSSSSSSSSSSSSSK",
    "KSSSSSkSSSSSSSSK",
    "KKKKKKKKKKKKKKKK",
]
# ================= v2 主体资产（C01 + C02）=================================
# 作者网格 = 运行时 / 2（NEAREST ×2）。身体与腿分层：身体一次成形，腿 4 组相位，
# 8 帧步态 = 相位序列 + 身体 1px 起伏；塔分静体/轨梁/滑块三层以表现开火后座。


def _norm(rows):
    w = max(len(r) for r in rows)
    return [r.ljust(w, ".") for r in rows]


def render(rows, scale=1):
    rows = _norm(rows)
    h = len(rows)
    w = len(rows[0])
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            c = PAL.get(ch)
            if c:
                px[x, y] = c
    if scale != 1:
        im = im.resize((w * scale, h * scale), Image.NEAREST)
    return im


def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def paste(dst, src, dx, dy):
    dst.alpha_composite(src, (int(dx), int(dy)))
    return dst


def blit(dst, src, dx, dy, scale=1):
    if scale != 1:
        src = src.resize((src.width * scale, src.height * scale), Image.NEAREST)
    return paste(dst, src, dx, dy)


def walk_frames(body_rows, leg_rows_list, legs_y, bob, w=32, h=32):
    """8 帧步态：腿相位序列 [A,B,C,D,C,B,A,D] + 身体 bob（腿固定，身体 1px 起伏）。"""
    seq = [0, 1, 2, 3, 2, 1, 0, 3]
    body = render(body_rows)
    legs = [render(r) for r in leg_rows_list]
    out = []
    for i in range(8):
        im = canvas(w, h)
        paste(im, body, 0, bob[i])
        paste(im, legs[seq[i]], 0, legs_y)
        out.append(im)
    return out


# --- C01 针轨塔（作者 48×48 → 运行时 96×96；6 帧 = 待命 + 开火后座序列）-------
# 静体：珊瑚灯 + 石柱 + 阶梯八角基座（暗部主导，L 仅作顶左受光面）。
_NEEDLE_STATIC = [
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    ".......................KK.......................",
    "......................KYYK......................",
    "......................KOOK......................",
    "......................KEEK......................",
    ".......................KK.......................",
    ".....................KTTTTK.....................",
    ".....................KTTTTK.....................",
    ".....................KTTTTK.....................",
    ".....................KTTTTK.....................",
    ".....................KTTTTK.....................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    "...................KMMTTTTMMK...................",
    "...................KMmTTTTmMK...................",
    "..................KSSSTTTTSSSK..................",
    "..................KSTTTTTTTSK...................",
    ".................KKKKKKKKKKKK...................",
    "................KSTTTTTTTTTTSK..................",
    "................KSTTTTTTTTTTSK..................",
    "...............KKKKKKKKKKKKKK...................",
    "..............KSTTTTTTTTTTTTSK..................",
    "..............KSTLLLLLLLLLLTSK..................",
    "..............KSTTTTTTTTTTTTSK..................",
    ".............KKKKKKKKKKKKKKKK...................",
    "............KSTTTTTTTTTTTTTTSK..................",
    "............KSTTTTTTTTTTTTTTSK..................",
    "............KSTTTTTTTTTTTTTTSK..................",
    "...........KKKKKKKKKKKKKKKKKK...................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
    "................................................",
]
# 轨梁：横贯的黄铜轨（柱身从梁中穿过），压在静体之上。
_NEEDLE_BEAM = [
    "........KKKKKKKKKKKKKKKKKKKKKKKKKKKK............",
    "........KMMMMMMMMMMTTTTMMMMMMMMMMMMK............",
    "........KMmmmmmmmmTTTTmmmmmmmmmmmmK.............",
    "........KMmmmmmmmmTTTTmmmmmmmmmmmmK.............",
    "........KMMMMMMMMMTTTTMMMMMMMMMMMMK.............",
    "........KKKKKKKKKKKKKKKKKKKKKKKKKKK.............",
]
# 滑块：骑轨的黄铜滑块 + 右向针尖（沿梁平移表现开火）。
_NEEDLE_SLED = [
    "..KKKK....",
    ".KmmmmKK..",
    ".KMMMMmKK.",
    "..KKKK....",
]
_NEEDLE_FLASH = [
    "..O..O..",
    ".OYYO...",
    "OYYEYYO.",
    ".OYYO...",
    "..O..O..",
]


def needle_frame(frame):
    sled_x = [10, 27, 24, 20, 15, 10][frame]
    im = canvas(48, 48)
    paste(im, render(_NEEDLE_STATIC), 0, 0)
    paste(im, render(_NEEDLE_BEAM), 0, 14)
    paste(im, render(_NEEDLE_SLED), sled_x, 15)
    if frame == 1:
        paste(im, render(_NEEDLE_FLASH), 36, 14)
    elif frame == 2:
        paste(im, render(_NEEDLE_FLASH), 33, 15)
    return im


# --- C01 盐壳行者（作者 32×32；身体/腿分层）---------------------------------
_SALT_BODY = [
    "................................",
    "................................",
    "................................",
    "..........KK......KK............",
    "..........KPK....KPK............",
    "..........KK......KK............",
    "...........KKKKKKKK.............",
    ".........KKDDDDDDDDKK...........",
    "........KDdeedddddDDK...........",
    ".......KDdeddddddddDDK..........",
    ".......KDddKKKKKKddDDK..........",
    ".......KDDDKKKKKKDDDDK..........",
    ".......KDdddddddddDDK...........",
    ".......KDDDKKKKKKDDDK...........",
    ".......KDDDKKKKKKDDDDK..........",
    ".......KDdddddddddDDDK..........",
    "........KDdddddddDDDK...........",
    ".........KKDDDDDDDDKK...........",
]
_SALT_LEGS = [
    [  # A 外撑
        "........K..KKKKKK..K............",
        ".......KDDk.K..K.kDDK...........",
        "......KDDDK.K..K.KDDDK..........",
        "......KDDK..K..K..KDDK..........",
        ".....KDDK...KK.KK..KDDK.........",
        ".....KKK..............KKK.......",
    ],
    [  # B 收拢
        ".........K.KKKKKK.K.............",
        "........Kk.K....K.kK............",
        ".......KDDk.K..K.kDDK...........",
        "......KDDK..K..K..KDDK..........",
        ".....KDDK...KK.KK..KDDK.........",
        ".....KKK..............KKK.......",
    ],
    [  # C 前探
        "........K..KKKKKK..K............",
        ".......KDDK.K..K.KkDDK..........",
        "......KDDK..K..K...KDDK.........",
        ".....KDDK...K..K....KDDK........",
        ".....KDK....KK.KK....KDK........",
        ".....KKK..............KKK.......",
    ],
    [  # D 提腿
        ".........K.KKKKKK.K.............",
        "........KDDK....KDDK............",
        ".......KDDk.K..K.kDDK...........",
        ".......KDK..K..K..KDK...........",
        "......KKK...KK.KK..KKK..........",
        "................................",
    ],
]
_SALT_BOB = [0, 1, 1, 0, 0, 1, 1, 0]


def salt_frames():
    return walk_frames(_SALT_BODY, _SALT_LEGS, 18, _SALT_BOB)


# --- C01 桅鼠（作者 32×32；身体含尾与背插碎木，腿分层）-----------------------
_RAT_BODY = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "..........KK....................",
    ".........KbK....................",
    "........KbK.........KK..........",
    ".......KbK.........KPbK.........",
    "....KK.KbK.........KbbK.........",
    "...KGgKbK..........KbKK.........",
    "...KKgGK...KKKK....KGbgGK.......",
    "....KGgGKKKGggKKKKKGgggGK.......",
    ".....KGgggggggggggggggggGK......",
    "....KGggggggggggggggggggGK......",
    "....KGgRgggggggggggggggGGK......",
    "....KKGGgggggggggggggGGK........",
    ".....KGGGggggggggggGGGK.........",
    ".....KKKKKKKKKKKKKKKKK..........",
]
_RAT_LEGS = [
    [
        ".........K..K...K...K...........",
        "........Kk..K...K...kK..........",
        "........K...KK..KK..K...........",
        ".......KK.............KK........",
    ],
    [
        "........K..K...K...K............",
        ".......Kk..K...K...kK...........",
        ".......K...KK..KK..K............",
        "......KK.............KK.........",
    ],
    [
        ".........K..K...K...K...........",
        "........Kk..K...K...kK..........",
        "........KK...KK.KK...KK.........",
        "................................",
    ],
    [
        ".........K..K...K...K...........",
        "........Kk..K...K...kK..........",
        ".......Kk...KK.KK...kK..........",
        "......KK.............KK.........",
    ],
]
_RAT_BOB = [0, 1, 1, 0, 0, 1, 1, 0]


def rat_frames():
    return walk_frames(_RAT_BODY, _RAT_LEGS, 24, _RAT_BOB)


# --- C01 正视/背视（row1 向下、row2 向上；对称剪影，避免竖直航段侧身横走）-----
_SALT_FRONT = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    ".........KKKKKKKKKKKK...........",
    ".......KKDDDDDDDDDDDDKK.........",
    "......KDDddddddddddddDDK........",
    "......KDddddddddddddddDK........",
    ".....KDDddeeddddeeddDDK.........",
    ".....KDDddeeddddeeddDDK.........",
    ".....KDDddddddddddddDDK.........",
    ".....KKDddddddddddddDKK.........",
    "......KKDddddddddddDKK..........",
    ".......KKKDddddddddKKK..........",
    ".........KKKKKKKKKKKK...........",
]
_SALT_BACK = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    ".........KKKKKKKKKKKK...........",
    ".......KKDDDDDDDDDDDDKK.........",
    "......KDDddddddddddddDDK........",
    "......KDddddddddddddddDK........",
    ".....KDDddddmmmmddddDDK.........",
    ".....KDDddddmmmmddddDDK.........",
    ".....KDDddddddddddddDDK.........",
    ".....KKDddddddddddddDKK.........",
    "......KKDddddddddddDKK..........",
    ".......KKKDddddddddKKK..........",
    ".........KKKKKKKKKKKK...........",
]
_SALT_FRONT_LEGS = [
    [
        ".....KKK...KKK...KKK...KKK......",
        ".....KDK...KDK...KDK...KDK......",
        ".....KdK...KKK...KdK...KKK......",
        ".....KKK........KKK.............",
    ],
    [
        ".....KKK...KKK...KKK...KKK......",
        ".....KDK...KDK...KDK...KDK......",
        ".....KKK...KdK...KKK...KdK......",
        "...........KKK........KKK......",
    ],
]
_SALT_FRONT_LEGS = _SALT_FRONT_LEGS + _SALT_FRONT_LEGS


def salt_front_frames():
    return walk_frames(_SALT_FRONT, _SALT_FRONT_LEGS, 17, _SALT_BOB)


def salt_back_frames():
    return walk_frames(_SALT_BACK, _SALT_FRONT_LEGS, 17, _SALT_BOB)


_RAT_FRONT = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "........KK........KK............",
    ".......KbK........KbK...........",
    ".......KbKKKKKKKKKKbK...........",
    "......KbggggggggggggbK..........",
    "......KbgKKggggggKKgbK..........",
    "......KbgggggbbggggggK..........",
    ".......KKggggggggggKK...........",
    "........KKKKKKKKKKKK............",
]
_RAT_BACK = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "........KK........KK............",
    ".......KbK........KbK...........",
    ".......KbKKKKKKKKKKbK...........",
    "......KbggggggggggggbK..........",
    "......KbgggggggggggggK..........",
    "......KggggggbbggggggK..........",
    ".......KKggggbbgggKK............",
    "........KKKKbbKKKK..............",
]
_RAT_FRONT_LEGS = [
    [
        "......KK....KK....KK....KK......",
        "......Kg....KK....Kg....KK......",
        "......KK..........KK............",
    ],
    [
        "......KK....KK....KK....KK......",
        "......KK....Kg....KK....Kg......",
        "............KK..........KK......",
    ],
]
_RAT_FRONT_LEGS = _RAT_FRONT_LEGS + _RAT_FRONT_LEGS


def rat_front_frames():
    return walk_frames(_RAT_FRONT, _RAT_FRONT_LEGS, 16, _RAT_BOB)


def rat_back_frames():
    return walk_frames(_RAT_BACK, _RAT_FRONT_LEGS, 16, _RAT_BOB)


# --- C02 余烬喷井（作者 32×32 → 64×64，运行时 0.64 缩放 ≈41px）--------------
# 剪影：八角石盆 + 黄铜盆沿 + 中央余烬烟囱；暖色只集中在炉芯焦点。
_WELL_BASE = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "..............KKKK..............",
    ".............KSEESK.............",
    ".............KSOOSK.............",
    ".............KSEESK.............",
    "............KKSSSSKK............",
    "............KSTTTTSK............",
    "............KSTTTTSK............",
    "...........KKSTTTTSKK...........",
    "........KKKMMMMMMMMKKK..........",
    ".......KMmmmmmmmmmmmmMK.........",
    ".......KMMMMMMMMMMMMMMK.........",
    "......KKKKKKKKKKKKKKKKKK........",
    ".....KSTTTTTTTTTTTTTTTTSK.......",
    ".....KSTTLLLLLLLLLLLTTTSK.......",
    ".....KSTTTTTTTTTTTTTTTTSK.......",
    "....KSTTTTTTTTTTTTTTTTTTSK......",
    "....KSTTSSSSSSSSSSSSSTTSK.......",
    "....KSSSSSSSSSSSSSSSSSSSK.......",
    "....KKKKKKKKKKKKKKKKKKKKK.......",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
]


def well_tier(tier):
    im = render(_WELL_BASE)
    px = im.load()
    if tier >= 2:  # 侧 vents + 盆沿加亮
        for y in (18, 19):
            px[3, y] = PAL["K"]
            px[4, y] = PAL["E"]
            px[27, y] = PAL["E"]
            px[28, y] = PAL["K"]
        for x in range(8, 24):
            px[x, 14] = PAL["m"]
    if tier >= 3:  # 烟囱加高 + 黄铜线圈
        for y in range(2, 5):
            px[13, y] = PAL["K"]
            px[14, y] = PAL["O"]
            px[15, y] = PAL["O"]
            px[16, y] = PAL["K"]
        px[14, 1] = PAL["K"]
        px[15, 1] = PAL["K"]
        for y in (10, 12):
            px[11, y] = PAL["m"]
            px[18, y] = PAL["m"]
    if tier >= 4:  # 双喷口 + 珊瑚战旗 + 炉芯白热
        for y in range(6, 12):
            px[8, y] = PAL["E"]
            px[9, y] = PAL["E"]
            px[22, y] = PAL["E"]
            px[23, y] = PAL["E"]
        px[7, 6] = PAL["K"]
        px[10, 6] = PAL["K"]
        px[21, 6] = PAL["K"]
        px[24, 6] = PAL["K"]
        px[14, 6] = PAL["Y"]
        px[15, 6] = PAL["Y"]
        px[14, 7] = PAL["Y"]
        px[15, 7] = PAL["Y"]
    return im


# --- C02 针轨塔（作者 32×32 浓缩版；横梁剪影与喷井的竖直剪影区分）-------------
_RAIL_BASE = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "..............KK................",
    ".............KYYK...............",
    ".............KEEK...............",
    ".............KTTK...............",
    ".............KTTK...............",
    "....KKKKKKKKKTTKKKKKKKKK........",
    "....KMmmmmmmmTTmmmmmmmmK........",
    "....KMmmmmmmmTTmmmmmmmmK........",
    "....KMMMMMMMMTTMMMMMMMMK........",
    "....KKKKKKKKKTTKKKKKKKKK........",
    "..........KMMTTMMK..............",
    "..........KMmTTmMK..............",
    ".........KSSSTTSSSK.............",
    ".........KSTTTTTTSK.............",
    "........KKKKKKKKKKK.............",
    ".......KSTTTTTTTTSK.............",
    ".......KSTLLLLLLTSK.............",
    ".......KSTTTTTTTTSK.............",
    "......KKKKKKKKKKKKK.............",
    ".....KSTTTTTTTTTTSK.............",
    ".....KKKKKKKKKKKKK..............",
    "................................",
    "................................",
    "................................",
    "................................",
]


def rail_tier(tier):
    im = render(_RAIL_BASE)
    px = im.load()
    if tier >= 2:
        for x in range(6, 25):
            px[x, 10] = PAL["M"]
            px[x, 11] = PAL["m"]
        px[5, 10] = PAL["K"]
        px[25, 10] = PAL["K"]
        px[24, 9] = PAL["O"]
    if tier >= 3:
        for y in range(12, 17):
            px[26, y] = PAL["m"]
            px[27, y] = PAL["M"]
        px[14, 6] = PAL["Y"]
        px[13, 7] = PAL["O"]
        px[15, 7] = PAL["O"]
    if tier >= 4:
        for x in range(6, 25):
            px[x, 8] = PAL["M"]
            px[x, 9] = PAL["m"]
        for y in range(3, 8):
            px[10, y] = PAL["E"]
            px[11, y] = PAL["E"]
        px[9, 3] = PAL["K"]
        px[12, 3] = PAL["K"]
    return im


# --- C02 裂鳍疾行者（作者 32×32；鱼雷体 + 分叉尾鳍 + 背鳍，冷青=威胁）----------
_DASHER = [
    "................................",
    "................................",
    "..KK............................",
    ".KwK............................",
    "KWVK..........KKK...............",
    "KWVK.........KcccK..............",
    "KWVKKKKKKKKKKwwwwKKKKKKKK.......",
    "KWVVVKwwwwwwwwwwwwwwwwwwKK......",
    "KWVVVVwWVwwwwwwwwwwwwwwwwKK.....",
    "KWVVVVVVVVVVVVVVVVVVVVVVVKcwKK..",
    "KWVVVVVVVVVVVVVVVVVVVVVVVVwK....",
    "KWVVVVVVVVVVVVVVVVVVVVVVVVwK....",
    "KWVKKWWVVVVVVVVVVVVVVVVVVwKK....",
    ".KwK.KKKWWWWWWWWWWWWWWWWKKK.....",
    "..KK....KKKKKKKKKKKKKKKK........",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
]


def dasher_frames():
    a = render(_DASHER)
    b = render(_DASHER)
    px = b.load()
    for y in range(2, 15):
        for x in range(0, 5):
            px[x, y] = (0, 0, 0, 0)
    tail_b = render([
        "...KK.",
        "..KwK.",
        ".KWVK.",
        "KWVVK.",
        "KWVVK.",
        "KWVVK.",
        ".KWVK.",
        "..KwK.",
        "...KK.",
    ])
    paste(b, tail_b, 0, 4)
    return [a, b]


# --- C02 桅鼠群（作者 32×32；三只小鼠聚簇，运行时单张贴图 0.52 缩放）----------
_RAT_SWARM = [
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "......KKK.......................",
    ".....KGbGK......................",
    ".....KGggGKK....................",
    "....KGgggggGK...................",
    "....KKKKKKKGK...................",
    "................................",
    "...................KKK..........",
    "..................KGbGKK........",
    ".................KGgggggGK......",
    ".................KKKKKKKGK......",
    "................................",
    ".....KKK........................",
    "....KGbGK.......................",
    "....KGggGKK.....................",
    "...KGgggggGK....................",
    "...KKKKKKKGK....................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
]


# --- C02 锈甲搬运者（作者 32×32；宽重甲壳 + 货包 + 短腿，慢速重敌）-------------
_CARRIER = [
    "................................",
    "................................",
    "................................",
    "..........KKKKKKKK..............",
    ".........KRrrrrrrRK.............",
    ".........KRrMMrrRK..............",
    "........KKRrMMrRKK..............",
    ".......KRrrrrrrrrRKK............",
    ".......KRRRRRRRRRRbK............",
    "......KKKKKKKKKKKKKK............",
    ".....KRrrrrrrrrrrrRK............",
    ".....KRkRrrrrrrRkrRK............",
    ".....KRrrrrrrrrrrrRK............",
    ".....KKKKKKKKKKKKKKK............",
    ".....KRrrrrrrrrrrrRK............",
    ".....KRkRrrrrrrRkrRK............",
    ".....KRrrrrrrrrrrrRK............",
    ".....KKKKKKKKKKKKKKK............",
    "......KGGK.KGGK.KGGK............",
    "......KGGK.KGGK.KGGK............",
    "......KKK..KKK..KKK.............",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
]


def carrier_frames():
    a = render(_CARRIER)
    b = render(_CARRIER)
    px = b.load()
    # B 帧：腿相位互换
    for y in range(18, 22):
        for x in range(4, 24):
            px[x, y] = (0, 0, 0, 0)
    legs_b = render([
        "..KGGK.KGGK.KGGK...",
        "..KGGK.KGGK.KGGK...",
        "..KKK..KKK..KKK....",
    ])
    paste(b, legs_b, 6, 18)
    return [a, b]


# --- C02 潮门（作者 80×56 → 运行时 160×112，1:1 地标）-------------------------
def _brick_block(w, h, mortar="K", stone="S", light="T", hi="L"):
    """石砌块：K 灰缝 + S 石面 + 顶左 T/L 受光，错缝砌筑。"""
    rows = []
    for y in range(h):
        row = ["."] * w
        course = y // 3
        off = 0 if course % 2 == 0 else 2
        for x in range(w):
            row[x] = stone
        if y % 3 == 2:
            row = [mortar] * w
        else:
            for x in range(w):
                if (x + off) % 6 == 0:
                    row[x] = mortar
        if y == 0:
            row = [hi if x % 6 else mortar for x in range(w)]
        elif y == 1:
            row = [light if x % 6 else mortar for x in range(w)]
        rows.append("".join(row))
    return rows


def tide_gate(open_state):
    im = canvas(80, 56)
    water = render([
        "WWWWWWWWWWWWWWWWWWWW",
        "WVWWWWWWWWWWWWWWWWWW",
        "WWWWwWWWWWWWWWWWWWWW",
        "WWWWWWWWWWWWWWWWWWWW",
    ])
    for y in range(0, 56, 4):
        for x in range(0, 80, 20):
            paste(im, water, x, y)
    # 门顶灯 + 门楣横梁
    paste(im, render([
        "...KK...",
        "..KYYK..",
        "..KOOK..",
        "...KK...",
    ]), 36, 0)
    paste(im, render([
        "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK",
        "KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK",
        "KMmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmK",
        "KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK",
        "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK",
    ]), 0, 4)
    # 双石柱（亮石）与门叶（暗石）之间留 K 缝，结构一眼可分
    for px_x in (6, 58):
        paste(im, render(_brick_block(16, 44, stone="T", light="L", hi="L")), px_x, 10)
    pxg = im.load()
    for y in range(10, 54):
        for x in (22, 23, 56, 57):
            pxg[x, y] = PAL["K"]
    # 门叶
    if open_state:
        leaf_h = 12
        paste(im, render(_brick_block(32, leaf_h, stone="D", light="d")), 24, 10)
        paste(im, render([
            "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK",
            "KMmmmmmmmmmmmmmmmmmmmmmmmmmmMK",
            "KMMMMMMMMMMMMMMMMMMMMMMMMMMMMK",
            "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK",
        ]), 24, 10 + leaf_h)
        surge = render([
            "..c..c....c..c....c..c....c..c",
            ".cwc.cwc.cwc.cwc.cwc.cwc.cwc.c",
            "wwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
            "VwVVwVVwVVwVVwVVwVVwVVwVVwVVwV",
            "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
        ])
        paste(im, surge, 24, 28)
        paste(im, surge, 24, 42)
    else:
        paste(im, render(_brick_block(32, 32, stone="D", light="d")), 24, 10)
        for y in (16, 26, 36):
            paste(im, render([
                "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK",
                "KMmmmmmmmmmmmmmmmmmmmmmmmmmmMK",
                "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK",
            ]), 24, y)
        paste(im, render([
            "c..c...c..c...c..c...c..c...c.",
            "cwc.cwc.cwc.cwc.cwc.cwc.cwc.cw",
            "wwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
        ]), 24, 44)
    # 柱基涌沫
    for px_x in (4, 56):
        paste(im, render([
            "c.c..c.c",
            "wcwcwcwc",
            "wwwwwwww",
        ]), px_x, 51)
    return im


# --- C02 FX：潮门涌浪 3 帧（作者 48×16 → 96×32）与余烬弹（作者 8×8 → 16×16）----
def tide_fx_strip():
    im = canvas(48, 16)
    px = im.load()
    for i in range(3):
        ox = i * 16
        cx, cy = ox + 8, 8
        radii = (4,) if i == 0 else ((4, 7) if i == 1 else (6,))
        for y in range(16):
            for x in range(ox, ox + 16):
                d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                for r in radii:
                    if abs(d - r) < 0.7:
                        px[x, y] = PAL["c"] if r <= 4 else PAL["w"]
        if i == 2:
            paste(im, render([
                "..O..",
                ".OYO.",
                "OYEYO",
                ".OYO.",
                "..O..",
            ]), ox + 6, 6)
    return im


def ember_burst():
    return render([
        "..E..E..",
        ".EOOOE..",
        "EOYYE...",
        ".EOOE...",
        "..E..E..",
    ], 2)
# ================= 道具图集与背景合成器 ======================================
# 道具：人造规则结构用图案代码生成（板条/箍/辐条），高光与阴影手工定位。
# 背景：环境层（天空/海水渐变）1:1 有序抖动；物体层沿用 ×2 像素语言。

BAYER4 = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
]


def hsh(x, y, s=0):
    return (((x * 73856093) ^ (y * 19349663) ^ (s * 83492791)) & 0xFFFF) / 65535.0


def _mix(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(4))


def vgrad(im, y0, y1, stops):
    """竖直渐变：stops=[(t0..1, rgba), ...]，段内 Bayer 有序抖动，禁线性模糊。"""
    px = im.load()
    span = max(1, y1 - y0 - 1)
    for y in range(y0, y1):
        t = (y - y0) / span
        seg = 0
        while seg < len(stops) - 2 and t > stops[seg + 1][0]:
            seg += 1
        ta, ca = stops[seg]
        tb, cb = stops[seg + 1]
        u = 0.0 if tb <= ta else (t - ta) / (tb - ta)
        u = min(1.0, max(0.0, u))
        for x in range(im.width):
            th = (BAYER4[y % 4][x % 4] + 0.5) / 16.0
            px[x, y] = ca if u < th else cb


def glow(im, cx, cy, r, color, density=0.5):
    px = im.load()
    for y in range(max(0, int(cy - r)), min(im.height, int(cy + r) + 1)):
        for x in range(max(0, int(cx - r)), min(im.width, int(cx + r) + 1)):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if d > r:
                continue
            a = density * (1.0 - d / r)
            if (BAYER4[y % 4][x % 4] + 0.5) / 16.0 < a:
                px[x, y] = color


def hline_dither(im, y, x0, x1, color, density=1.0, s=0):
    if y < 0 or y >= im.height:
        return
    px = im.load()
    for x in range(max(0, x0), min(im.width, x1)):
        if hsh(x, y, s) < density:
            px[x, y] = color


# --- 道具构造（作者 64×64 单元格内居中）--------------------------------------
def _center(grid, cell=64):
    h = len(grid)
    w = max(len(r) for r in grid)
    out = ["." * cell for _ in range((cell - h) // 2)]
    for r in _norm(grid):
        out.append("." * ((cell - w) // 2) + r)
    while len(out) < cell:
        out.append("." * cell)
    return out


def prop_crate():
    n = 26
    g = [["K"] * n for _ in range(n)]
    for y in range(1, n - 1):
        for x in range(1, n - 1):
            g[y][x] = "g" if (x % 6) else "G"
    for i in range(1, n - 1):
        g[i][i] = "b"
        g[i][n - 1 - i] = "b"
    for x in range(1, n - 1):
        g[1][x] = "b"
    return _center(["".join(r) for r in g])


def prop_barrel():
    n = 26
    rows = []
    for y in range(n):
        dy = abs(y - n / 2) / (n / 2)
        half = int((n / 2) * (1.0 - 0.28 * dy * dy))
        cx = n // 2
        row = ["."] * n
        for x in range(cx - half, cx + half):
            row[x] = "g" if (x % 5) else "G"
        if x_ok := (cx - half) >= 0:
            row[cx - half] = "K"
            row[cx + half - 1] = "K"
        if y in (6, 7, 18, 19):
            for x in range(cx - half, cx + half):
                row[x] = "M" if (x % 4) else "m"
        if y in (0, n - 1):
            row = ["K" if c != "." else "." for c in row]
        rows.append("".join(row))
    return _center(rows)


def prop_coil():
    n = 28
    rows = [["."] * n for _ in range(n)]
    c = n / 2
    for y in range(n):
        for x in range(n):
            d = ((x - c) ** 2 + ((y - c) * 1.5) ** 2) ** 0.5
            band_i = int(d / 3)
            if d > c - 1:
                continue
            rows[y][x] = ["g", "G", "b", "G", "g", "K", "g", "G", "b"][band_i % 9] if band_i else "K"
    return _center(["".join(r) for r in rows])


def prop_anchor():
    return _center([
        "....KKKK....",
        "...Km..mK...",
        "...Km..mK...",
        "....KKKK....",
        "......KK....",
        ".KKKKKmMK...",
        "......KmK...",
        "......KmK...",
        "......KmK...",
        "......KmK...",
        ".K....KmK...K",
        "KmK...KmK..KmK",
        ".KmK..KmK..KmK",
        "..KmKKmMKKmK..",
        "...KKKKKKKK...",
    ])


def prop_post():
    return _center([
        "....KKKK....",
        "...KYYK.....",
        "...KOOK.....",
        "...KEEK.....",
        "....KKK.....",
        "...KKgKK....",
        "...KgggK....",
        "...KgggK....",
        "..KMgggMK...",
        "..KMgggMK...",
        "...KgggK....",
        "...KgggK....",
        "...KGgGK....",
        "...KGgGK....",
        "...KGgGK....",
        "..KKgggKK...",
        ".KGGgggGGK..",
        ".KKKKKKKKK..",
    ])


def prop_net():
    n = 28
    rows = [["."] * n for _ in range(n)]
    for y in range(8, n):
        h = int((n / 2) * ((y - 6) / (n - 6)) ** 0.7)
        c = n // 2
        for x in range(c - h, c + h):
            rows[y][x] = "g"
        if h:
            rows[y][c - h] = "K"
            rows[y][c + h - 1] = "K"
    for y in range(8, n):
        for x in range(n):
            if rows[y][x] == "g" and ((x + y) % 5 == 0 or (x - y) % 5 == 0):
                rows[y][x] = "K"
            if rows[y][x] == "g" and hsh(x, y, 4) < 0.06:
                rows[y][x] = "m"
    return _center(["".join(r) for r in rows])


def prop_boat():
    return _center([
        "..KKKKKKKKKKKKKKKKKKKK..",
        ".KgggggggggggggggggggK..",
        "KgDDDDDDDDDDDDDDDDDDgK..",
        "KgDbbbbbbbDDbbbbbbDDgK..",
        "KgDDDDDDDDDDDDDDDDDDgK..",
        "KgDbbbbbbbDDbbbbbbDDgK..",
        "KgDDDDDDDDDDDDDDDDDDgK..",
        ".KggggggggggggggggggK...",
        "..KKKKKKKKKKKKKKKKKK....",
    ])


def prop_wheel():
    n = 26
    rows = [["."] * n for _ in range(n)]
    c = n / 2 - 0.5
    for y in range(n):
        for x in range(n):
            dx, dy = x - c, y - c
            d = (dx * dx + dy * dy) ** 0.5
            if d > c:
                continue
            if d > c - 3:
                rows[y][x] = "K" if (x + y) % 2 else "g"
            elif d < 3:
                rows[y][x] = "M"
            elif abs(dx) < 1.5 or abs(dy) < 1.5 or abs(dx - dy) < 1.5 or abs(dx + dy) < 1.5:
                rows[y][x] = "b"
    return _center(["".join(r) for r in rows])


def props_atlas():
    im = canvas(512, 64)
    for i, fn in enumerate([prop_crate, prop_barrel, prop_coil, prop_anchor,
                            prop_post, prop_net, prop_boat, prop_wheel]):
        paste(im, render(fn()), i * 64, 0)
    return im


# --- 背景物体（作者网格 ×2）--------------------------------------------------
_SHIP_TOP = [
    "....KKKKKKKKKKKKKKKKKKKKKKKK....",
    "..KKggggggggggggggggggggggggKK..",
    ".KgDDDDDDDDDDDDDDDDDDDDDDDDDDgK.",
    "KgDDbbbbbbDDDDMMDDDDbbbbbbDDDDgK",
    "KgDDbbbbbbDDDDMMDDDDbbbbbbDDDDgK",
    "KgDDDDDDDDDDDDMMDDDDDDDDDDDDDDgK",
    ".KgDDDDDDDDDDDDDDDDDDDDDDDDDDgK.",
    "..KKggggggggggggggggggggggggKK..",
    "....KKKKKKKKKKKKKKKKKKKKKKKK....",
]
_SHIP_TOP_SAIL = [
    "..KKKKKKKKKKKKKKKKKK..",
    ".KPppppppppppppppppK..",
    ".KPppppppppppppppppK..",
    "..KKKKKKKKKKKKKKKKKK..",
]
_ROCK_LEFT = [
    "....KKKKKKKKKKKKKKKKKK............",
    "..KKSSSTTTTTTTTTTTSSSKK...........",
    ".KSTTLLLLLLLLTTTTTTSSSK...........",
    ".KSTLLLLLLLLLTTTTTTSSSK...........",
    "KSTTLLLLLTTTTTTTTTTTSSSK..........",
    "KSTTTTTTTTTTTTTTTTTTSSSK..........",
    "KSTTTTTTTSSSTTTTTTTTSSSK..........",
    "KSTTTTTSSSSSSTTTTTTTSSSK..........",
    "KSTTTTSSSSSSSSTTTTTTSSSK..........",
    "KSTTTSSSSSSSSSSTTTTTSSSK..........",
    "KSTTSSSSSSSSSSSTTTTSSSSK..........",
    "KSTSSSSSSSSSSSSSTTSSSSSK..........",
    "KSSSSSSSSSSSSSSSSSSSSSSK..........",
    "KSSSSSSSSkSSSSSSkSSSSSSK..........",
    "KSSSSSSSSSSSSSSSSSSSSSSK..........",
    "KkSSSSSSSSSSSSSSSSSSSSkK..........",
    ".KKSSSSSSSSSSSSSSSSSSKK...........",
    "..KKkSSSSSSSSSSSSSSkKK............",
    "....KKKKKKKKKKKKKKKK..............",
]
_REEF_RIGHT = [
    "......KKKKKKKKKKKK............",
    "....KKSSSTTTTTTSSSKK..........",
    "...KSTLLLLLTTTTTSSSK..........",
    "..KSTLLLLLLTTTTTSSSK..........",
    "..KSTTTLLLLTTTTTTSSK..........",
    ".KSTTTTTTTTTTTTTTSSK..........",
    ".KSTTTTSSSTTTTTTSSSK..........",
    ".KSTTSSSSSSTTTTTSSSK..........",
    ".KSSSSSSSSSSSTTSSSSK..........",
    ".KSSSSSSSSSSSSSSSSSK..........",
    ".KkSSSSSSkSSSSSSSSkK..........",
    "..KKSSSSSSSSSSSSSSKK..........",
    "....KKKKKKKKKKKKKK............",
]
_LIGHTHOUSE = [
    "........KKKK........",
    ".......KYYYYK.......",
    ".......KOOOOK.......",
    ".......KEEEEK.......",
    "......KKKKKKKK......",
    ".....KMMMMMMMMK.....",
    ".....KKKKKKKKKK.....",
    "......KPPPPPPK......",
    "......KPPPPPPK......",
    "......KPPPPPPK......",
    "......KPPPPPPK......",
    "......KPPPPPPK......",
    "......KEEEEEEK......",
    "......KEEEEEEK......",
    ".....KPPPPPPPPK.....",
    ".....KPPPPPPPPK.....",
    ".....KPPPPPPPPK.....",
    ".....KPPPPPPPPK.....",
    ".....KPPPPPPPPK.....",
    ".....KPPPPPPPPK.....",
    "....KPPPPPPPPPPK....",
    "....KPPPPPPPPPPK....",
    "....KEEEEEEEEEEK....",
    "....KEEEEEEEEEEK....",
    "...KPPPPPPPPPPPPK...",
    "...KPPPPPPPPPPPPK...",
    "...KPPPPPPPPPPPPK...",
    "...KPPPPPPPPPPPPK...",
    "..KKKKKKKKKKKKKKKK..",
    "..KSSSSSSSSSSSSSSK..",
    "..KKKKKKKKKKKKKKKK..",
]
_SHIP_SIDE = [
    "..............mm................",
    "....mm.......mMMm......mm.......",
    "...KPpK.....KPpppK....KPpK......",
    "..KPpppK...KPpppppK...KPpppK....",
    ".KPpppppK.KPpppppppK.KPpppppK...",
    ".KPpppppK.KPpppppppK.KPpppppK...",
    "..KPppppK..KPppppppK.KPppppK....",
    "...KppppK..KppppppK..KppppK.....",
    "....KKKK....KKKKKK....KKKK......",
    "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK..",
    "KGGggggggggggggggggggggggggGGK..",
    ".KKGGggggggggggggggggggggGGKK...",
    "...KKKKGGGGGGGGGGGGGGGGKKKK.....",
    "......KKKKKKKKKKKKKKKKK.........",
]


# --- C01 战斗背景（640×360，俯视港池；几何与 level_c01 路线/陆块严格对齐）-----
ROUTE_MAIN = [(0, 192), (320, 192), (320, 320), (640, 320)]
ROUTE_TIDE = [(0, 192), (480, 192), (480, 80), (640, 80)]
BUILD_NODES = [(160, 112), (352, 112), (512, 144), (96, 256),
               (256, 256), (416, 256), (544, 224), (64, 320)]


def _lane(im, pts, width, wake_seed):
    """航迹：更深的航道水 + 密集潮光短划 + 两侧泡沫边线。"""
    px = im.load()
    for i in range(len(pts) - 1):
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        steps = int(max(abs(x1 - x0), abs(y1 - y0)))
        for s in range(steps + 1):
            t = s / max(1, steps)
            cx = x0 + (x1 - x0) * t
            cy = y0 + (y1 - y0) * t
            horiz = abs(x1 - x0) >= abs(y1 - y0)
            for o in range(-width // 2, width // 2 + 1):
                x = int(cx)
                y = int(cy + o) if horiz else int(cy)
                if horiz:
                    y = int(cy + o)
                else:
                    x = int(cx + o)
                if not (0 <= x < im.width and 0 <= y < im.height):
                    continue
                edge = abs(o) == width // 2
                if edge:
                    px[x, y] = PAL["c"] if hsh(x, y, wake_seed) < 0.3 else PAL["w"]
                elif abs(o) == width // 2 - 1:
                    px[x, y] = PAL["V"]
                else:
                    px[x, y] = PAL["k"] if hsh(x, y, wake_seed + 2) < 0.12 else PAL["W"]


def _build_pad(im, cx, cy):
    px = im.load()
    for y in range(cy - 12, cy + 12):
        for x in range(cx - 12, cx + 12):
            dx, dy = x - cx, y - cy
            d = max(abs(dx), abs(dy))
            if d > 11:
                continue
            if d == 11:
                px[x, y] = PAL["K"] if (x + y) % 2 == 0 else PAL["k"]
            elif d == 10:
                px[x, y] = PAL["L"] if (dx < 0 and dy < 0) else PAL["T"]
            elif d >= 8:
                px[x, y] = PAL["T"] if (dx < 0 and dy < 0) else PAL["S"]
            elif d <= 2:
                px[x, y] = PAL["m"] if d else PAL["M"]
            else:
                px[x, y] = PAL["S"]


def battle_background():
    im = canvas(640, 360)
    # 海水底：双 tile 哈希混铺（暗部主导）
    ta = render(TILE_WATER_A, 2)
    tb = render(TILE_WATER_B, 2)
    for ty in range(0, 360, 32):
        for tx in range(0, 640, 32):
            paste(im, ta if hsh(tx, ty, 21) < 0.5 else tb, tx, ty)
    # 北岸码头：栈板 + 石砌岸壁 + 压顶亮线 + 岸脚泡沫
    dock = render(TILE_DOCK, 2)
    wall = render(TILE_WALL_TOP, 2)
    for tx in range(0, 640, 32):
        paste(im, dock, tx, 0)
        paste(im, wall, tx, 32)
    px = im.load()
    for x in range(640):
        px[x, 31] = PAL["L"] if x % 4 else PAL["T"]
        if hsh(x, 64, 5) < 0.7:
            px[x, 64] = PAL["w"]
        if hsh(x, 65, 6) < 0.35:
            px[x, 65] = PAL["c"]
    # 陆块：左礁 / 右礁 / 底缘岩唇
    blit(im, render(_ROCK_LEFT), 0, 64, 2)
    blit(im, render(_REEF_RIGHT), 576, 128, 2)
    for x in range(640):
        for y in range(352, 360):
            px[x, y] = PAL["k"] if (x + y) % 3 else PAL["K"]
        if hsh(x, 351, 9) < 0.5:
            px[x, 351] = PAL["w"]
    # 航迹（主航道宽、潮道窄）
    _lane(im, ROUTE_MAIN, 26, 31)
    _lane(im, ROUTE_TIDE, 16, 47)
    # 航标浮筒：暖色只作导航焦点
    for (bx, by) in [(120, 176), (240, 208), (430, 176), (348, 300), (520, 336)]:
        paste(im, render([
            ".KK.",
            "KEEK",
            "KOEK",
            ".KK.",
        ]), bx, by)
    # 建造位石垫
    for (cx, cy) in BUILD_NODES:
        _build_pad(im, cx, cy)
    # 码头陈设：货箱/木桶/灯柱/系缆桩 + 泊船
    paste(im, render(prop_crate()), 88, 2)
    paste(im, render(prop_barrel()), 130, 6)
    paste(im, render(prop_post()), 210, 0)
    paste(im, render(prop_crate()), 300, 4)
    paste(im, render(prop_coil()), 360, 6)
    paste(im, render(prop_post()), 470, 0)
    paste(im, render(prop_barrel()), 520, 6)
    ship = render(_SHIP_TOP)
    sail = render(_SHIP_TOP_SAIL)
    blit(im, ship, 96, 72, 2)
    blit(im, sail, 106, 78, 2)
    blit(im, ship, 380, 330, 2)
    # 右端灯塔（岸壁尽头）
    blit(im, render(_LIGHTHOUSE), 596, 4, 2)
    glow(im, 616, 14, 26, PAL["O"], 0.35)
    # 岸壁灯柱暖光
    glow(im, 220, 10, 18, PAL["O"], 0.22)
    glow(im, 480, 10, 18, PAL["O"], 0.22)
    # 暗角（抖动，禁线性渐变模糊）
    for y in range(360):
        for x in range(640):
            d = min(x, y, 639 - x, 359 - y)
            if d < 10 and (BAYER4[y % 4][x % 4] + 0.5) / 16.0 < (10 - d) / 14.0:
                px[x, y] = PAL["k"]
    return im


# --- 菜单海报背景（640×360 侧视）---------------------------------------------
def _poster_base(im, sky_stops, horizon, sea_stops):
    vgrad(im, 0, horizon, sky_stops)
    vgrad(im, horizon, 360, sea_stops)
    px = im.load()
    for y in range(horizon + 6, 356, 5):
        for x0 in range(0, 640, 26):
            ox = x0 + int(hsh(y, x0, 15) * 12)
            if hsh(x0, y, 12) < 0.55:
                ln = 6 + int(hsh(x0, y, 14) * 10)
                hline_dither(im, y, ox, ox + ln, PAL["w"], 0.9, y)
            if hsh(x0, y, 13) < 0.18:
                hline_dither(im, y + 2, ox + 4, ox + 9, PAL["c"], 0.9, y + 3)


def _fleet(im, ox, oy, count, scale=2):
    ship = render(_SHIP_SIDE)
    for i in range(count):
        row = i % 3
        col = i // 3
        blit(im, ship, ox + col * 90 + row * 26, oy + row * 34, scale if row == 0 else scale - 1 if scale > 1 else 1)


def _tide_front(im, ox, oy, n=5):
    px = im.load()
    for i in range(n):
        cx = ox + i * 36
        for a in range(0, 60):
            t = a / 59.0
            x = int(cx - 20 + 40 * t)
            y = int(oy - 10 * (1 - (2 * t - 1) ** 2))
            if 0 <= x < 640 and 0 <= y < 360 and hsh(x, y, 77) < 0.8:
                px[x, y] = PAL["c"]
                if y + 1 < 360:
                    px[x, y + 1] = PAL["w"]
        px[cx + 2, oy - 12] = PAL["E"]
        px[cx + 3, oy - 12] = PAL["E"]


def _rock_mass(im, ox, oy, w, h):
    px = im.load()
    for y in range(oy, min(360, oy + h)):
        k = (y - oy) / max(1, h - 1)
        half = int(w * (0.35 + 0.65 * k) * (0.80 + 0.40 * hsh(0, y, 57)))
        cx = ox + w // 2 + int((hsh(1, y, 58) - 0.5) * 14)
        for x in range(max(0, cx - half), min(640, cx + half)):
            edge = abs(x - (cx - half)) < 2 or abs(x - (cx + half - 1)) < 2
            if edge:
                px[x, y] = PAL["K"]
            elif x < cx - half + 6 and k < 0.5:
                px[x, y] = PAL["T"]
            else:
                px[x, y] = PAL["k"] if hsh(x, y, 55) < 0.25 else PAL["S"]


def poster(mode):
    """mode: 0 title / 1 slot(campaign) / 2 briefing / 3 result win / 4 result lose"""
    im = canvas(640, 360)
    night = [(0.0, PAL["K"]), (0.55, PAL["k"]), (0.85, PAL["S"]), (1.0, PAL["V"])]
    dawn = [(0.0, PAL["k"]), (0.5, PAL["D"]), (0.8, PAL["M"]), (1.0, PAL["O"])]
    storm = [(0.0, PAL["K"]), (0.6, PAL["K"]), (0.9, PAL["k"]), (1.0, PAL["D"])]
    sea_n = [(0.0, PAL["V"]), (0.35, PAL["W"]), (1.0, PAL["K"])]
    sea_d = [(0.0, PAL["w"]), (0.3, PAL["V"]), (1.0, PAL["W"])]
    sea_s = [(0.0, PAL["d"]), (0.3, PAL["D"]), (1.0, PAL["K"])]
    dusk = [(0.0, PAL["K"]), (0.6, PAL["k"]), (0.85, PAL["D"]), (1.0, PAL["E"])]
    sea_k = [(0.0, PAL["D"]), (0.35, PAL["W"]), (1.0, PAL["K"])]
    if mode == 3:
        _poster_base(im, dawn, 190, sea_d)
    elif mode == 4:
        _poster_base(im, storm, 170, sea_s)
    elif mode == 1:
        _poster_base(im, dusk, 196, sea_k)
    else:
        _poster_base(im, night, 196, sea_n)
    px = im.load()
    # 月 / 日
    mx, my = (480, 84) if mode != 3 else (500, 96)
    disc = PAL["P"] if mode != 3 else PAL["Y"]
    for y in range(my - 16, my + 16):
        for x in range(mx - 16, mx + 16):
            d = ((x - mx) ** 2 + (y - my) ** 2) ** 0.5
            if d < 14:
                px[x, y] = disc
            elif d < 16 and hsh(x, y, 3) < 0.6:
                px[x, y] = disc
    glow(im, mx, my, 46, PAL["c"] if mode != 3 else PAL["O"], 0.20)
    # 远景舰队
    _fleet(im, 300 if mode != 2 else 340, 176, 5 if mode != 4 else 3)
    if mode == 4:
        wreck = render(_SHIP_SIDE)
        wreck = wreck.rotate(-18, resample=Image.NEAREST, expand=True)
        paste(im, wreck, 420, 210)
    # 前景岩 + 灯塔
    _rock_mass(im, -20, 250, 240, 130)
    blit(im, render(_LIGHTHOUSE), 120, 168, 2)
    glow(im, 140, 178, 60, PAL["E"], 0.16)
    # 灯束（抖动三角）
    for y in range(156, 212):
        t = abs(y - 182) / 28.0
        for x in range(150, 640):
            u = (x - 150) / 490.0
            half = 4 + u * 46
            if abs(y - 182) < half and hsh(x, y, 88) < 0.30 * (1 - u) * (1 - t * 0.5):
                px[x, y] = PAL["O"] if hsh(x, y, 89) < 0.5 else PAL["E"]
    # 潮锋
    _tide_front(im, 380 if mode != 4 else 300, 236 if mode != 4 else 250, 6 if mode == 4 else 4)
    # 前景浪
    for y in range(330, 360):
        for x in range(640):
            if hsh(x, y, 91) < 0.5 * (y - 328) / 32.0:
                px[x, y] = PAL["K"]
    # 模式差异
    if mode == 2:
        for y in range(360):
            for x in range(300, 640):
                d = (x - 300) / 340.0
                if hsh(x, y, 95) < 0.62 * d:
                    px[x, y] = PAL["K"]
    if mode == 4:
        for y in range(212, 360):
            for x in range(640):
                if hsh(x, y, 96) < 0.3:
                    px[x, y] = PAL["k"]
    # 暗角
    for y in range(360):
        for x in range(640):
            d = min(x, y, 639 - x, 359 - y)
            if d < 14 and (BAYER4[y % 4][x % 4] + 0.5) / 16.0 < (14 - d) / 18.0:
                px[x, y] = PAL["K"]
    return im


def briefing_map():
    """羊皮航海图：p/q/s 纸面 + 海岸 S 块 + M 虚线航路 + 罗盘。"""
    im = canvas(320, 180)
    px = im.load()
    for y in range(180):
        for x in range(320):
            v = hsh(x // 3, y // 3, 101)
            px[x, y] = PAL["s"] if v < 0.06 else (PAL["q"] if v < 0.16 else PAL["p"])
    # 海岸（左下陆块 + 右上礁）
    for y in range(180):
        for x in range(320):
            if y > 150 - x * 0.35 or (x > 250 and y < 40 + (x - 250) * 0.4):
                px[x, y] = PAL["S"] if hsh(x, y, 102) < 0.8 else PAL["T"]
            if abs(y - (150 - x * 0.35)) < 2 or abs(y - (40 + (x - 250) * 0.4)) < 2 and x > 250:
                px[x, y] = PAL["K"]
    # 航路虚线
    pts = [(20, 90), (120, 90), (160, 60), (250, 60), (290, 90)]
    for i in range(len(pts) - 1):
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        steps = int(max(abs(x1 - x0), abs(y1 - y0)))
        for s in range(steps + 1):
            if s % 4 >= 2:
                continue
            x = int(x0 + (x1 - x0) * s / steps)
            y = int(y0 + (y1 - y0) * s / steps)
            px[x, y] = PAL["M"]
            px[x, y + 1] = PAL["M"]
    # 起终点 X
    for (ex, ey) in [(20, 90), (290, 90)]:
        for d in range(-3, 4):
            px[ex + d, ey + d] = PAL["R"]
            px[ex + d, ey - d] = PAL["R"]
    # 罗盘
    cx, cy = 280, 140
    for d in range(-10, 11):
        px[cx + d, cy] = PAL["M"]
        px[cx, cy + d] = PAL["M"]
    for d in range(-6, 7):
        px[cx + d, cy + d] = PAL["q"]
        px[cx + d, cy - d] = PAL["q"]
    px[cx, cy - 11] = PAL["E"]
    px[cx, cy - 12] = PAL["E"]
    return im
