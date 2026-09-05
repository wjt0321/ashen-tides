class_name GreyboxDevice
extends Node2D
## 环境装置运行时（M2，相位模板 2：C03 失火灯塔）。
## 在线且相位匹配 active_phase 时按 interval 脉冲（glow_pulse：范围内辉光伤害）；
## 相位事件 environment_changes: device_offline 可令其离线；
## 离线时英雄驻守 repair_seconds 秒修复（PRD §5.3 C03：英雄修复装置）。

signal repair_progressed(device: GreyboxDevice, ratio: float)

const COLOR_ONLINE := Color(1.0, 0.85, 0.40)
const COLOR_OFFLINE := Color(0.35, 0.35, 0.45)
const COLOR_RING := Color(1.0, 0.85, 0.40, 0.35)
const COLOR_PALE_BAND := Color(0.97, 0.96, 0.92) ## 灯塔白横带（离线时退为灰白）

var data: DeviceData
var enemies: Array = [] ## 由战斗场景注入（数组按引用共享）
var hero: GreyboxHero = null ## 修复判定用，由战斗场景注入
var online: bool = true
var current_phase: StringName = &"mingchao"
var hp: float = 0.0 ## 可破坏掩体耐久（C12；data.max_hp == 0 时不用）
var destroyed: bool = false ## 掩体被击破：停止阻挡/脉冲，不可修复

var _pulse_left: float = 0.0
var _pulse_anim: float = 0.0 ## 脉冲动画 1.0 → 0.0
var _repair_left: float = -1.0 ## <0 = 未在修复


func setup(p_data: DeviceData) -> void:
	data = p_data
	position = data.position
	online = true
	hp = data.max_hp
	destroyed = false
	_pulse_left = data.interval_seconds


## 掩体承伤（C12）：被阻挡的投射物削减耐久，归零即摧毁。
func take_damage(amount: float) -> void:
	if destroyed or data.max_hp <= 0.0:
		return
	hp -= amount
	queue_redraw()
	if hp <= 0.0:
		hp = 0.0
		destroyed = true
		online = false
		print("[M4C] cover destroyed: %s" % data.id)
		EventBus.device_offline.emit(data.id)


func set_online(value: bool) -> void:
	if online == value:
		return
	online = value
	_repair_left = -1.0
	queue_redraw()
	if online:
		EventBus.device_online.emit(data.id)
	else:
		EventBus.device_offline.emit(data.id)


func sim_tick(delta: float) -> void:
	_pulse_anim = maxf(0.0, _pulse_anim - delta * 1.5)
	if _pulse_anim > 0.0:
		queue_redraw()
	if destroyed:
		return # 掩体残骸：无脉冲、不可修复
	if online:
		_repair_left = -1.0
		if data.active_phase == &"both" or data.active_phase == current_phase:
			_pulse_left -= delta
			if _pulse_left <= 0.0:
				_pulse_left += data.interval_seconds
				_pulse()
	elif data.repairable:
		_tick_repair(delta)


func _pulse() -> void:
	match data.effect_op:
		&"glow_pulse":
			for enemy: Variant in enemies:
				if enemy is GreyboxEnemy and enemy.is_alive():
					if enemy.position.distance_to(position) <= data.radius_px:
						enemy.take_damage(data.effect_value, &"glow")
		&"reveal_pulse":
			# C09 侦测装置：揭示半径内隐匿敌 effect_value 秒
			for enemy: Variant in enemies:
				if enemy is GreyboxEnemy and enemy.is_alive() and enemy.data.stealthed:
					if enemy.position.distance_to(position) <= data.radius_px:
						enemy.reveal(data.effect_value)
		&"spore_heal":
			# C10 孢子扩散区：敌方区域，每跳治疗半径内敌军
			for enemy: Variant in enemies:
				if enemy is GreyboxEnemy and enemy.is_alive():
					if enemy.position.distance_to(position) <= data.radius_px:
						enemy.hp = minf(enemy.data.max_hp, enemy.hp + data.effect_value)
		# cover：无脉冲，仅阻挡投射物
	_pulse_anim = 1.0
	queue_redraw()


## 英雄驻守修复：在装置半径 + 16px 内且未倒地时累积进度。
func _tick_repair(delta: float) -> void:
	var hero_near: bool = hero != null and not hero.is_down \
		and hero.position.distance_to(position) <= data.radius_px + 16.0
	if not hero_near:
		if _repair_left >= 0.0:
			_repair_left = -1.0
			queue_redraw()
		return
	if _repair_left < 0.0:
		_repair_left = data.repair_seconds
	_repair_left -= delta
	repair_progressed.emit(self, repair_ratio())
	queue_redraw()
	if _repair_left <= 0.0:
		set_online(true)
		EventBus.device_repaired.emit(data.id)
		print("[M2] device repaired: %s" % data.id)


## M3 英雄技能快速修复：仍遵循“离线装置”边界，不影响在线装置状态。
func force_repair() -> void:
	if online or destroyed:
		return
	_repair_left = 0.0
	set_online(true)
	EventBus.device_repaired.emit(data.id)
	print("[M3] device repaired by hero skill: %s" % data.id)


func repair_ratio() -> float:
	if online or _repair_left < 0.0:
		return 0.0
	return 1.0 - _repair_left / data.repair_seconds


func get_save_state() -> Dictionary:
	return {"online": online, "repair_left": _repair_left, "pulse_left": _pulse_left, "hp": hp, "destroyed": destroyed}


func restore_save_state(state: Dictionary) -> void:
	online = bool(state.get("online", true))
	_repair_left = float(state.get("repair_left", -1.0)) # 修复进度也是确定性状态
	_pulse_left = float(state.get("pulse_left", data.interval_seconds if online else 0.0))
	hp = float(state.get("hp", data.max_hp)) # 掩体耐久（C12）也是确定性状态
	destroyed = bool(state.get("destroyed", false))
	queue_redraw()


func _draw() -> void:
	if data.effect_op == &"cover":
		_draw_cover()
		return
	if data.effect_op == &"spore_heal":
		_draw_spore_zone()
		return
	# 主体色（无障碍重映射）：在线暖黄 / 离线灰
	var accent := COLOR_ONLINE if online else COLOR_OFFLINE
	accent = UiPalette.apply(accent)
	var pale := UiPalette.apply(COLOR_PALE_BAND)
	if not online:
		pale = VisualTheme.shade(accent, 1.5) # 离线：灰暗塔身中仍保留可辨条带
	# 影响范围（低透明度常显）
	draw_arc(Vector2.ZERO, data.radius_px, 0.0, TAU, 40, Color(accent, 0.12), 1.0)
	_draw_lighthouse(accent, pale)
	# 脉冲动画（在线每 interval 触发的扩张光环，保留 _pulse_anim 原逻辑）
	if _pulse_anim > 0.0:
		draw_arc(Vector2.ZERO, data.radius_px * (1.0 - _pulse_anim * 0.4), 0.0, TAU, 40,
			Color(COLOR_RING, _pulse_anim * 0.5), 2.0)
	# 修复进度弧（离线且英雄驻守中；半径随塔身加大微调）
	if not online and _repair_left >= 0.0:
		draw_arc(Vector2.ZERO, 18.0, -PI / 2.0, -PI / 2.0 + TAU * repair_ratio(), 24, COLOR_ONLINE, 3.0)


## 小灯塔塔身：条纹横带（accent / 白 3 段）+ 顶部灯室。
func _draw_lighthouse(accent: Color, pale: Color) -> void:
	# 基座 + 三段横带（自下而上：白 / accent / 白），塔身轻微收窄
	draw_rect(Rect2(-6.5, 2.5, 13.0, 3.0), VisualTheme.shade(accent, 0.55), true)
	draw_rect(Rect2(-6.5, -1.0, 13.0, 3.5), pale, true)
	draw_rect(Rect2(-6.0, -4.8, 12.0, 3.8), accent, true)
	draw_rect(Rect2(-5.5, -8.6, 11.0, 3.8), pale, true)
	# 灯台（暗沿）与灯室玻璃
	draw_rect(Rect2(-5.0, -10.6, 10.0, 2.0), VisualTheme.shade(accent, 0.7), true)
	draw_rect(Rect2(-3.8, -15.0, 7.6, 4.8), VisualTheme.shade(accent, 0.35), true)
	var lamp_c := Vector2(0, -12.6)
	if online:
		# 在线：灯室 glow 光球 + 外晕（静态，脉冲扩张另走 _pulse_anim 光环）
		draw_circle(lamp_c, 4.8, Color(accent, 0.14))
		draw_circle(lamp_c, 2.6, accent)
		draw_circle(lamp_c, 1.3, UiPalette.apply(Color(1.0, 1.0, 0.95)))
	else:
		# 离线：灯室熄灭
		draw_circle(lamp_c, 2.6, VisualTheme.shade(accent, 0.7))
		draw_circle(lamp_c, 1.3, VisualTheme.shade(accent, 0.5))
	# 轮廓描边（阶梯剪影）
	var outline := PackedVector2Array([
		Vector2(6.5, 5.5), Vector2(6.5, -1.0), Vector2(6.0, -4.8), Vector2(5.5, -8.6),
		Vector2(5.0, -10.6), Vector2(3.8, -10.6), Vector2(3.8, -15.0), Vector2(-3.8, -15.0),
		Vector2(-3.8, -10.6), Vector2(-5.0, -10.6), Vector2(-5.5, -8.6), Vector2(-6.0, -4.8),
		Vector2(-6.5, -1.0), Vector2(-6.5, 5.5), Vector2(6.5, 5.5),
	])
	draw_polyline(outline, VisualTheme.OUTLINE, 1.2)


## C12 可破坏掩体：沉船船壳板 + 耐久条；摧毁后画暗色残骸（不再阻挡）。
func _draw_cover() -> void:
	var r := data.radius_px
	if destroyed:
		var wreck := Color(0.22, 0.18, 0.16, 0.8)
		draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 20, wreck, 3.0)
		draw_line(Vector2(-r * 0.5, -r * 0.3), Vector2(r * 0.4, r * 0.35), wreck, 2.0)
		draw_line(Vector2(-r * 0.4, r * 0.35), Vector2(r * 0.5, -r * 0.3), wreck, 2.0)
		return
	var hull := UiPalette.apply(Color(0.48, 0.38, 0.28))
	var rim := VisualTheme.OUTLINE
	# 阻挡半径（低透明常显，提示投射物会被挡）
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(hull, 0.14), 1.0)
	# 船壳板：斜置圆角矩形感（六边形厚板 + 铆钉）
	var plate := PackedVector2Array([
		Vector2(-r * 0.62, -r * 0.38), Vector2(r * 0.55, -r * 0.5), Vector2(r * 0.68, 0.0),
		Vector2(r * 0.5, r * 0.45), Vector2(-r * 0.58, r * 0.38), Vector2(-r * 0.7, 0.0),
	])
	draw_colored_polygon(plate, hull)
	_stroke_poly(plate, rim, 1.8)
	draw_circle(Vector2(-r * 0.3, -r * 0.12), 1.6, VisualTheme.shade(hull, 0.6))
	draw_circle(Vector2(r * 0.28, r * 0.1), 1.6, VisualTheme.shade(hull, 0.6))
	# 耐久条
	var ratio: float = clampf(hp / maxf(data.max_hp, 1.0), 0.0, 1.0)
	var bw := r * 1.2
	draw_rect(Rect2(Vector2(-bw / 2.0, -r - 7.0), Vector2(bw, 3.0)), VisualTheme.HP_BAR_BG, true)
	draw_rect(Rect2(Vector2(-bw / 2.0, -r - 7.0), Vector2(bw * ratio, 3.0)), Color(0.75, 0.62, 0.40), true)


## C10 孢子扩散区：敌方治疗场（菌丘 + 孢子点 + 绿色范围环）。
func _draw_spore_zone() -> void:
	var mound := UiPalette.apply(Color(0.40, 0.72, 0.42))
	draw_arc(Vector2.ZERO, data.radius_px, 0.0, TAU, 40, Color(mound, 0.12), 1.0)
	draw_circle(Vector2.ZERO, 9.0, VisualTheme.shade(mound, 0.7))
	draw_circle(Vector2(-4.0, -3.0), 3.2, mound)
	draw_circle(Vector2(4.5, -1.5), 2.6, mound)
	draw_circle(Vector2(0.5, 4.0), 2.2, VisualTheme.shade(mound, 1.2))
	draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 16, VisualTheme.OUTLINE, 1.2)
	if _pulse_anim > 0.0:
		draw_arc(Vector2.ZERO, data.radius_px * (1.0 - _pulse_anim * 0.4), 0.0, TAU, 40,
			Color(mound, _pulse_anim * 0.5), 2.0)


## 闭合折线描边辅助（掩体用；敌人的 _stroke 是同类私有辅助）。
func _stroke_poly(pts: PackedVector2Array, color: Color, width: float) -> void:
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, color, width)
