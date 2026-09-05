class_name UiPalette
extends RefCounted
## 无障碍调色板（M2，PRD §13.1）：色弱预设 / 高对比 / 低特效的运行时颜色重映射。
## 静态工具类：敌人 body_color、路线颜色等经 apply() 重映射后再绘制。
## 预设矩阵为简化线性映射（灰盒切片够用；正式美术期换 LUT 贴图方案）。

static var _preset: StringName = &"default"
static var _cache: Dictionary = {}


static func configure_from_settings() -> void:
	_preset = StringName(SettingsService.get_value("accessibility", "color_preset", "default"))
	_cache.clear()


static func preset() -> StringName:
	return _preset


## 按色弱预设重映射颜色（提高敌我/路线在对应色弱下的可区分度）。
static func apply(color: Color) -> Color:
	if _preset == &"default":
		return color
	var key := "%s:%s" % [_preset, color.to_html()]
	if _cache.has(key):
		return _cache[key]
	var out := color
	match _preset:
		&"protan", &"deutan":
			# 红/绿色弱：把偏红绿的颜色拉向蓝黄轴
			if color.r > color.b + 0.15 and color.g < color.r:
				out = Color(color.g * 0.7 + 0.15, color.g, minf(color.b + 0.35, 1.0), color.a)
			elif color.g > color.b + 0.15:
				out = Color(color.r, color.g * 0.8, minf(color.b + 0.3, 1.0), color.a)
		&"tritan":
			# 蓝色弱：把偏蓝的颜色拉向红绿轴
			if color.b > color.r + 0.15:
				out = Color(minf(color.r + 0.3, 1.0), color.g, color.b * 0.6, color.a)
	_cache[key] = out
	return out


static func high_contrast() -> bool:
	return bool(SettingsService.get_value("accessibility", "high_contrast", false))


static func low_fx() -> bool:
	return bool(SettingsService.get_value("accessibility", "low_fx", false))
