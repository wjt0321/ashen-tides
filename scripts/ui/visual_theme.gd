class_name VisualTheme
extends RefCounted
## 视觉主题层（Polish 阶段，PRD §12.4 像素视觉规范）。
## 全部颜色集中在此：8 关主题调色板 + 相位氛围 + 共享绘制辅助。
## 所有绘制仍走 _draw 矢量图元（无第三方资产），经 UiPalette.apply 过无障碍重映射。

# ---- 相位氛围叠加色（全屏 tint，alpha 很低）----
const TINT_MINGCHAO := Color(1.0, 0.92, 0.78, 0.05) ## 明潮：暖
const TINT_MUCHAO := Color(0.55, 0.68, 1.0, 0.09) ## 暮潮：冷
const FLASH_LEAK := Color(0.9, 0.15, 0.12, 0.28) ## 漏怪红闪
const FLASH_WIN := Color(0.55, 0.95, 0.65, 0.20)
const FLASH_LOSE := Color(0.85, 0.10, 0.10, 0.35)

# ---- 通用 ----
const OUTLINE := Color(0.08, 0.08, 0.11)
const HP_BAR := Color(0.42, 0.92, 0.45)
const HP_BAR_BG := Color(0.10, 0.10, 0.13)
const SHIELD_BAR := Color(0.55, 0.75, 1.0)
const MARK_RING := Color(1.0, 0.85, 0.30)
const SLOW_TINT := Color(0.45, 0.70, 1.0, 0.45)
const SILENCE_MARK := Color(0.75, 0.55, 1.0)

# ---- 关卡主题调色板 ----
# sea_a/sea_b 海底双色，sea_foam 浪尖，land_a/land_b 陆地双色，land_edge 岸线，
# road_bed/road_inner 路面，accent 主题强调色（装饰/出入口），glow 夜景微光
const THEMES: Dictionary = {
	&"level_c01": { # 离港火线：黄昏港岸
		"sea_a": Color(0.10, 0.17, 0.26), "sea_b": Color(0.08, 0.13, 0.21),
		"sea_foam": Color(0.35, 0.50, 0.60), "land_a": Color(0.32, 0.27, 0.22),
		"land_b": Color(0.27, 0.23, 0.19), "land_edge": Color(0.55, 0.45, 0.32),
		"road_bed": Color(0.16, 0.13, 0.11), "road_inner": Color(0.42, 0.34, 0.25),
		"accent": Color(0.95, 0.55, 0.25), "glow": Color(1.0, 0.75, 0.40),
	},
	&"level_c02": { # 潮门初启：雾中潮门
		"sea_a": Color(0.12, 0.22, 0.26), "sea_b": Color(0.09, 0.17, 0.21),
		"sea_foam": Color(0.45, 0.62, 0.65), "land_a": Color(0.30, 0.30, 0.26),
		"land_b": Color(0.25, 0.25, 0.22), "land_edge": Color(0.50, 0.52, 0.45),
		"road_bed": Color(0.14, 0.15, 0.14), "road_inner": Color(0.38, 0.40, 0.34),
		"accent": Color(0.55, 0.85, 0.85), "glow": Color(0.65, 0.90, 0.90),
	},
	&"level_c03": { # 失火灯塔：夜航
		"sea_a": Color(0.07, 0.10, 0.22), "sea_b": Color(0.05, 0.08, 0.17),
		"sea_foam": Color(0.30, 0.38, 0.62), "land_a": Color(0.20, 0.18, 0.26),
		"land_b": Color(0.16, 0.15, 0.22), "land_edge": Color(0.38, 0.34, 0.50),
		"road_bed": Color(0.10, 0.09, 0.15), "road_inner": Color(0.32, 0.28, 0.42),
		"accent": Color(1.0, 0.80, 0.35), "glow": Color(1.0, 0.85, 0.45),
	},
	&"level_c04": { # 白盐岬：盐壳浅滩
		"sea_a": Color(0.14, 0.30, 0.34), "sea_b": Color(0.11, 0.24, 0.28),
		"sea_foam": Color(0.62, 0.80, 0.80), "land_a": Color(0.55, 0.54, 0.48),
		"land_b": Color(0.47, 0.46, 0.41), "land_edge": Color(0.75, 0.74, 0.66),
		"road_bed": Color(0.30, 0.29, 0.26), "road_inner": Color(0.62, 0.60, 0.52),
		"accent": Color(0.95, 0.90, 0.60), "glow": Color(0.95, 0.95, 0.75),
	},
	&"level_c05": { # 漂木渡口：朽木绿水
		"sea_a": Color(0.10, 0.20, 0.16), "sea_b": Color(0.08, 0.16, 0.13),
		"sea_foam": Color(0.38, 0.55, 0.42), "land_a": Color(0.33, 0.26, 0.18),
		"land_b": Color(0.27, 0.21, 0.15), "land_edge": Color(0.52, 0.42, 0.28),
		"road_bed": Color(0.18, 0.14, 0.10), "road_inner": Color(0.45, 0.35, 0.22),
		"accent": Color(0.80, 0.60, 0.30), "glow": Color(0.85, 0.70, 0.40),
	},
	&"level_c06": { # 锈帆滩：锈蚀残骸
		"sea_a": Color(0.08, 0.18, 0.22), "sea_b": Color(0.06, 0.14, 0.18),
		"sea_foam": Color(0.35, 0.50, 0.52), "land_a": Color(0.36, 0.24, 0.18),
		"land_b": Color(0.30, 0.20, 0.15), "land_edge": Color(0.58, 0.38, 0.25),
		"road_bed": Color(0.16, 0.12, 0.10), "road_inner": Color(0.48, 0.32, 0.22),
		"accent": Color(0.90, 0.45, 0.20), "glow": Color(0.95, 0.55, 0.30),
	},
	&"level_c07": { # 潮脊断桥：风暴灰紫
		"sea_a": Color(0.11, 0.12, 0.24), "sea_b": Color(0.08, 0.09, 0.19),
		"sea_foam": Color(0.42, 0.45, 0.66), "land_a": Color(0.26, 0.24, 0.30),
		"land_b": Color(0.21, 0.20, 0.25), "land_edge": Color(0.45, 0.42, 0.55),
		"road_bed": Color(0.13, 0.12, 0.17), "road_inner": Color(0.40, 0.37, 0.48),
		"accent": Color(0.70, 0.60, 1.0), "glow": Color(0.75, 0.65, 1.0),
	},
	&"level_c08": { # 吞锚蟹巢：深渊巢穴
		"sea_a": Color(0.06, 0.05, 0.12), "sea_b": Color(0.04, 0.04, 0.09),
		"sea_foam": Color(0.28, 0.22, 0.42), "land_a": Color(0.18, 0.12, 0.16),
		"land_b": Color(0.14, 0.10, 0.13), "land_edge": Color(0.35, 0.20, 0.26),
		"road_bed": Color(0.09, 0.06, 0.09), "road_inner": Color(0.30, 0.18, 0.24),
		"accent": Color(0.90, 0.25, 0.30), "glow": Color(0.95, 0.35, 0.40),
	},
}

const FALLBACK_THEME := &"level_c01"


static func palette_for(level_id: StringName) -> Dictionary:
	return THEMES.get(level_id, THEMES[FALLBACK_THEME])


## 确定性单元格 hash（装饰散布用，同一格永远同一值，不消耗战斗 RNG）。
static func cell_hash(col: int, row: int, seed: int) -> float:
	var h := col * 73856093 ^ row * 19349663 ^ seed * 83492791
	h = (h ^ (h >> 13)) * 1103515245 + 12345
	return float(h & 0x7FFFFFFF) / float(0x7FFFFFFF)


## 明度缩放（剪影层次）。
static func shade(color: Color, factor: float) -> Color:
	return Color(clampf(color.r * factor, 0.0, 1.0), clampf(color.g * factor, 0.0, 1.0),
		clampf(color.b * factor, 0.0, 1.0), color.a)


## 混色。
static func blend(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, clampf(t, 0.0, 1.0))
