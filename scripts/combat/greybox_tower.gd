class_name GreyboxTower
extends Node2D
## 灰盒塔（M2）：放置在固定 BuildNode 上，4 级升级 + II 级校准模块（PRD §6.1）。
## 目标策略：射程内路线进度最大者（"最前"，PRD §3.5 默认）。
## 数值模型：I 级 = TowerData 平铺字段；II–IV = tiers[] 非零字段覆盖；模块效果见 ModuleData。
## pair_link 塔（回声桩阵）不开火，由战斗场景的链路系统结算伤害。

signal fire_requested(tower: GreyboxTower, target: GreyboxEnemy)

const COLOR_BODY := Color(0.45, 0.65, 0.85) ## 未知塔回退色（现状方块）
const COLOR_OUTLINE := Color(0.15, 0.25, 0.35) ## 未知塔回退描边
const COLOR_ECHO_BODY := Color(0.70, 0.60, 0.95) ## 回声桩阵：紫灰
const TIER_PIP_COLORS: Array[Color] = [
	Color(0.6, 0.6, 0.6), Color(0.4, 0.8, 0.4), Color(0.3, 0.6, 1.0), Color(0.9, 0.7, 0.2),
]

## 各塔自家色系（无模块时主体色；正式美术期由图集/数据接管）。
## 有模块时 module.tint 做主色（保留现有语义）。
const FAMILY_COLORS: Dictionary = {
	&"tower_needle_rail": Color(0.42, 0.62, 0.85), # 针轨弩台：夜蓝钢
	&"tower_ember_well": Color(0.50, 0.42, 0.40), # 余烬喷井：炭灰岩
	&"tower_echo_pile": COLOR_ECHO_BODY, # 回声桩阵：紫灰
	&"tower_wind_nest": Color(0.58, 0.74, 0.68), # 风巢：青灰
	&"tower_tide_anvil": Color(0.34, 0.46, 0.62), # 潮汐砧：深蓝铁
	&"tower_prism_grove": Color(0.62, 0.82, 0.92), # 棱晶丛：青白
}
const COLOR_LIGHT_STEEL := Color(0.80, 0.90, 1.0) ## 针轨中央轨道亮线
const COLOR_EMBER_FLAME := Color(1.0, 0.60, 0.20) ## 余烬火口焰色
const COLOR_EMBER_INNER := Color(1.0, 0.86, 0.42) ## 火口内焰
const MUZZLE_FLASH_SECONDS := 0.12 ## 开火闪光时长（视觉走 sim_tick 衰减）
const WIND_BLADE_RAD_PER_SEC := 1.2 ## 风车叶片角速度（rad/s，固定 tick 累积）

var data: TowerData
var node_id: StringName
## 由战斗场景注入的敌人列表引用（数组按引用共享）。
var enemies: Array = []

var tier: int = 1 ## 当前等级 1–4
var module: ModuleData = null ## II 级选定的校准模块（本局锁定）
var invested_ember: int = 0 ## 累计投入（出售退款 70% 基数，PRD §3.7）
var total_kills: int = 0 ## 本塔击杀数（结算/战报统计）

var _cooldown: float = 0.0

## 选中/悬停高亮：为 true 时射程环更清晰（alpha 恢复常态）；默认 false = 常态减半。
var highlight_range: bool = false
var _muzzle_flash: float = 0.0 ## 开火闪光余量（0.12 → 0，随固定 tick 衰减）
var _blade_angle: float = 0.0 ## 风车叶片累积转角（风巢持续动画，sim_tick 驱动）


## suspend 存档：开火相位也是确定性状态（PRD §15.2）。
func get_cooldown() -> float:
	return _cooldown


func set_cooldown(value: float) -> void:
	_cooldown = value


func setup(p_data: TowerData, p_node_id: StringName) -> void:
	data = p_data
	node_id = p_node_id


# ---------------------------------------------------------------------------
# 等级 / 模块
# ---------------------------------------------------------------------------


func can_upgrade() -> bool:
	return tier < 4 and data.tiers.size() >= tier


## 升到下一级的成本；已满级返回 -1。
func upgrade_cost() -> int:
	if not can_upgrade():
		return -1
	return (data.tiers[tier - 1] as TowerTier).cost_to_upgrade


## II 级的模块候选；非升级临界点返回空。
func pending_module_choices() -> Array:
	if tier == 1 and data.tiers.size() >= 1:
		return (data.tiers[0] as TowerTier).module_choices
	return []


func upgrade() -> bool:
	if not can_upgrade():
		return false
	invested_ember += upgrade_cost()
	tier += 1
	queue_redraw()
	return true


## 挂载校准模块（仅 II 级，本局锁定）。
func apply_module(p_module: ModuleData) -> bool:
	if tier != 2 or module != null or data.tiers.is_empty():
		return false
	if not (data.tiers[0] as TowerTier).module_choices.has(p_module):
		return false
	module = p_module
	queue_redraw()
	return true


# ---------------------------------------------------------------------------
# 有效数值（等级覆盖 + 模块修正）
# ---------------------------------------------------------------------------


func _tier_stat(field: StringName, base: float) -> float:
	if tier >= 2:
		var tier_data := data.tiers[tier - 2] as TowerTier
		var value: float = tier_data.get(field)
		if value > 0.0:
			return value
	return base


func eff_damage_min() -> float:
	var value := _tier_stat(&"damage_min", data.damage_min)
	if module != null and module.effect_op == &"focus_damage_mult":
		value *= module.effect_value
	return value


func eff_damage_max() -> float:
	var value := _tier_stat(&"damage_max", data.damage_max)
	if module != null and module.effect_op == &"focus_damage_mult":
		value *= module.effect_value
	return value


func eff_range() -> float:
	return _tier_stat(&"range_px", data.range_px)


func eff_attack_period() -> float:
	var value := _tier_stat(&"attack_period", data.attack_period)
	if module != null and module.effect_op == &"fire_rate_mult":
		value *= module.effect_value
	return value


func eff_pierce() -> int:
	var value := data.pierce
	if module != null and module.effect_op == &"pierce_bonus":
		value += int(module.effect_value)
	return value


func eff_splash_radius() -> float:
	var value := data.splash_radius
	if module != null:
		if module.effect_op == &"splash_radius_mult":
			value *= module.effect_value
		elif module.effect_op == &"focus_damage_mult":
			value = 0.0 # 凝焰：收束为单体
	return value


## 命中削甲值（倒钩模块）；0 = 无。
func eff_armor_shred() -> float:
	if module != null and module.effect_op == &"armor_shred":
		return module.effect_value
	return 0.0


## 击杀返还航标充能（回火模块）；0 = 无。
func eff_kill_becon() -> int:
	if module != null and module.effect_op == &"kill_becon":
		return int(module.effect_value)
	return 0


# ---------------------------------------------------------------------------
# 模拟
# ---------------------------------------------------------------------------


func sim_tick(delta: float) -> void:
	## 由战斗场景以固定 tick 驱动（PRD §18.5）。
	## 视觉动画（风车旋转 / 开火闪光衰减）刻意走 sim_tick：暂停即定格，确定性一致。
	if data.id == &"tower_wind_nest":
		_blade_angle = wrapf(_blade_angle + delta * WIND_BLADE_RAD_PER_SEC, 0.0, TAU)
		queue_redraw() # 持续动画：每个 sim tick 重绘
	if _muzzle_flash > 0.0:
		_muzzle_flash = maxf(0.0, _muzzle_flash - delta)
		queue_redraw() # 只在闪光持续期间重绘，结束即停（性能）
	if data.pair_link:
		return # 回声桩阵：伤害由链路系统结算
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var target := _acquire_target()
	if target == null:
		_cooldown = 0.1 # 无目标时短轮询，避免空转整周期
		return
	_cooldown = eff_attack_period()
	_muzzle_flash = MUZZLE_FLASH_SECONDS
	queue_redraw()
	fire_requested.emit(self, target)


func _acquire_target() -> GreyboxEnemy:
	var best: GreyboxEnemy = null
	var best_progress := -1.0
	for enemy: Variant in enemies:
		if not (enemy is GreyboxEnemy) or not enemy.is_alive():
			continue
		if position.distance_to(enemy.position) > eff_range():
			continue
		if enemy.progress_px() > best_progress:
			best_progress = enemy.progress_px()
			best = enemy
	return best


func _draw() -> void:
	# 主体色：有模块用 module.tint 做主色，无模块用塔自家色系（未知 id 回退现状逻辑），
	# 主色过 UiPalette.apply 无障碍重映射。
	var body := _resolve_body_color()
	# 射程环：默认常态 alpha 减半，选中/悬停（highlight_range=true）时更清晰
	if not data.pair_link:
		var ring_alpha := 0.10 if highlight_range else 0.05
		var ring_width := 1.5 if highlight_range else 1.0
		draw_arc(Vector2.ZERO, eff_range(), 0.0, TAU, 48, Color(body, ring_alpha), ring_width)
	# M4-A：正式精灵优先（docs/M4_ASSET_SPEC.md §6 程序化回退）
	var tex := ArtLibrary.tower_tex(data.id)
	if tex != null:
		draw_texture(tex, Vector2(-16.0, -16.0))
	else:
		match data.id:
			&"tower_needle_rail":
				_draw_needle_rail(body)
			&"tower_ember_well":
				_draw_ember_well(body)
			&"tower_echo_pile":
				_draw_echo_pile(body)
			&"tower_wind_nest":
				_draw_wind_nest(body)
			&"tower_tide_anvil":
				_draw_tide_anvil(body)
			&"tower_prism_grove":
				_draw_prism_grove(body)
			_:
				_draw_legacy_block(body) # 未知 id：回退现状方块
	_draw_tier_pips()
	if _muzzle_flash > 0.0:
		# M4-A：开火闪光优先用 3 帧条（16×16/帧），缺失回退程序化圆闪
		var strip := ArtLibrary.vfx_tex("fx_muzzle_flash_strip3")
		var mz := _muzzle_offset()
		var k := clampf(_muzzle_flash / MUZZLE_FLASH_SECONDS, 0.0, 1.0)
		if strip != null:
			var frame := clampi(int((1.0 - k) * 3.0), 0, 2)
			draw_texture_rect_region(strip, Rect2(mz - Vector2(8, 8), Vector2(16, 16)),
				Rect2(frame * 16, 0, 16, 16), Color(1, 1, 1, 0.35 + 0.65 * k))
		else:
			draw_circle(mz, 2.0 + 40.0 * _muzzle_flash, Color(1.0, 1.0, 1.0, 0.30 * k))
			draw_circle(mz, 1.0 + 26.0 * _muzzle_flash, Color(1.0, 1.0, 1.0, 0.90 * k))


func _resolve_body_color() -> Color:
	var body: Color
	if module != null:
		body = module.tint
	else:
		body = FAMILY_COLORS.get(data.id, COLOR_ECHO_BODY if data.pair_link else COLOR_BODY)
	return UiPalette.apply(body)


## 等级角标 I–IV 色点（位置相对新剪影微调上移）。
func _draw_tier_pips() -> void:
	for i: int in tier:
		var pip_color: Color = TIER_PIP_COLORS[i]
		draw_circle(Vector2(-9.0 + i * 6.0, -13.5), 2.2, pip_color)


func _muzzle_offset() -> Vector2:
	## 各剪影的开火口位置（闪光锚点）。
	match data.id:
		&"tower_needle_rail":
			return Vector2(10.5, 0)
		&"tower_ember_well":
			return Vector2(0, -1.5)
		&"tower_wind_nest":
			return Vector2(0, -7.0)
		&"tower_tide_anvil":
			return Vector2(0, -12.6)
		&"tower_prism_grove":
			return Vector2(0, -9.5)
	return Vector2(0, -9.0)


## 未知 id 回退：现状方块（保留原逻辑）。
func _draw_legacy_block(body: Color) -> void:
	var rect := Rect2(Vector2(-8, -8), Vector2(16, 16))
	draw_rect(rect, body, true)
	draw_rect(rect, module.tint if module != null else COLOR_OUTLINE, false, 2.0)


## 针轨弩台：深色底座方块 + 弩臂横杆 + 中央轨道亮线（浅钢色）。
func _draw_needle_rail(body: Color) -> void:
	var dark := VisualTheme.shade(body, 0.55)
	var lit := VisualTheme.shade(body, 1.30)
	# 底座暗面
	draw_rect(Rect2(-8, -8, 16, 16), dark, true)
	# 顶面受光
	draw_rect(Rect2(-6.5, -6.5, 13, 13), body, true)
	# 顶光（上/左两条亮边，伪高度）
	draw_line(Vector2(-6.5, -6.5), Vector2(6.5, -6.5), lit, 1.2)
	draw_line(Vector2(-6.5, -6.5), Vector2(-6.5, 6.5), lit, 1.2)
	# 弩臂横杆（横贯底座的暗色杆）
	draw_rect(Rect2(-11, -1.6, 22, 3.2), VisualTheme.shade(body, 0.80), true)
	# 中央轨道亮线（浅钢色）
	draw_line(Vector2(-8.5, 0), Vector2(8.5, 0), COLOR_LIGHT_STEEL, 2.0)
	# 外描边
	draw_rect(Rect2(-11.5, -8.5, 23, 17), VisualTheme.OUTLINE, false, 1.0)


## 余烬喷井：圆炉体 + 顶部火口（橙黄，待机静态微光，避免持续 redraw）。
func _draw_ember_well(body: Color) -> void:
	var c := Vector2(0, -1.5)
	# 炉体（暗底 + 受光面）
	draw_circle(Vector2.ZERO, 9.0, VisualTheme.shade(body, 0.55))
	draw_circle(Vector2.ZERO, 6.8, body)
	# 顶光弧（上沿受光）
	draw_arc(Vector2.ZERO, 8.7, PI * 1.05, PI * 1.95, 12, VisualTheme.shade(body, 1.3), 1.4)
	# 火口微光（低 alpha 外圈静态待机）
	draw_circle(c, 5.4, Color(COLOR_EMBER_FLAME, 0.16))
	# 火口双焰 + 白热芯
	draw_circle(c, 3.6, COLOR_EMBER_FLAME)
	draw_circle(c, 2.0, COLOR_EMBER_INNER)
	draw_circle(c, 0.9, Color(1.0, 0.96, 0.80))
	# 外描边
	draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, VisualTheme.OUTLINE, 1.2)


## 回声桩阵：三根叠环石柱（紫灰，三角形布置）。
func _draw_echo_pile(body: Color) -> void:
	# 底座土台
	draw_circle(Vector2(0, 0.5), 8.0, VisualTheme.shade(body, 0.45))
	var pillar_pos := [Vector2(0, -4.6), Vector2(-3.8, 3.8), Vector2(3.8, 3.8)]
	for p: Vector2 in pillar_pos:
		# 柱底阴影
		draw_circle(p + Vector2(0.6, 0.9), 3.1, VisualTheme.shade(body, 0.40))
		# 柱顶受光面（顶光偏移）
		draw_circle(p + Vector2(-0.7, -0.8), 3.0, VisualTheme.shade(body, 1.25))
		# 叠环：柱顶内芯暗环 + 柱沿描边
		draw_circle(p, 1.6, VisualTheme.shade(body, 0.65))
		draw_arc(p, 3.0, 0.0, TAU, 14, VisualTheme.OUTLINE, 1.0)


## 风巢：三叶风车（长三角叶，固定 tick 慢旋转）。
func _draw_wind_nest(body: Color) -> void:
	# 巢台（暗底 + 台面）
	draw_circle(Vector2.ZERO, 7.8, VisualTheme.shade(body, 0.45))
	draw_circle(Vector2.ZERO, 6.4, VisualTheme.shade(body, 0.85))
	# 三叶：长三角叶片绕轴旋转
	for i: int in range(3):
		var ang := _blade_angle + float(i) * TAU / 3.0
		var tip := Vector2(0, -9.0).rotated(ang)
		var w := Vector2(2.0, 0).rotated(ang)
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, tip - w, tip + w]),
			VisualTheme.shade(body, 1.35 if i % 2 == 0 else 1.10))
	# 轴心
	draw_circle(Vector2.ZERO, 1.9, VisualTheme.shade(body, 0.5))
	draw_circle(Vector2.ZERO, 0.8, VisualTheme.shade(body, 1.4))


## 潮汐砧：铁砧块 + 锤头（深蓝铁色）。
func _draw_tide_anvil(body: Color) -> void:
	# 砧座（暗面）
	draw_rect(Rect2(-8, 1, 16, 8), VisualTheme.shade(body, 0.5), true)
	# 砧面受光
	draw_rect(Rect2(-8, -6, 16, 8), body, true)
	draw_line(Vector2(-8, -6), Vector2(8, -6), VisualTheme.shade(body, 1.35), 1.2)
	# 锤头（悬于砧面上方）+ 锤柄
	draw_line(Vector2(0, -6.4), Vector2(0, -10.4), VisualTheme.shade(body, 0.65), 2.4)
	draw_rect(Rect2(-6.2, -12.6, 12.4, 2.8), VisualTheme.shade(body, 1.2), true)
	# 外描边
	draw_rect(Rect2(-9.2, -13.2, 18.4, 24), VisualTheme.OUTLINE, false, 1.0)


## 棱晶丛：2–3 颗高低不一的水晶菱形（青白半透明）。
func _draw_prism_grove(body: Color) -> void:
	var crystals := [
		{"c": Vector2(0, -1.5), "s": 8.0, "a": 0.92},
		{"c": Vector2(-4.8, 4.2), "s": 5.2, "a": 0.70},
		{"c": Vector2(4.8, 3.8), "s": 4.4, "a": 0.60},
	]
	for cr: Dictionary in crystals:
		var c: Vector2 = cr["c"]
		var s: float = cr["s"]
		var a: float = cr["a"]
		var tip := c + Vector2(0, -s)
		var btm := c + Vector2(0, s)
		var lf := c + Vector2(-s * 0.62, 0)
		var rt := c + Vector2(s * 0.62, 0)
		# 晶体主体（半透明）+ 白亮棱边 + 晶尖高光
		draw_colored_polygon(PackedVector2Array([tip, rt, btm, lf]), Color(body, a))
		draw_polyline(PackedVector2Array([tip, rt, btm, lf, tip]), Color(1.0, 1.0, 1.0, a), 1.0)
		draw_line(c + Vector2(-s * 0.30, -s * 0.55), tip, Color(1.0, 1.0, 1.0, 0.55), 1.0)
