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

var _pulse_left: float = 0.0
var _pulse_anim: float = 0.0 ## 脉冲动画 1.0 → 0.0
var _repair_left: float = -1.0 ## <0 = 未在修复


func setup(p_data: DeviceData) -> void:
	data = p_data
	position = data.position
	online = true
	_pulse_left = data.interval_seconds


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
	if data.effect_op == &"glow_pulse":
		for enemy: Variant in enemies:
			if enemy is GreyboxEnemy and enemy.is_alive():
				if enemy.position.distance_to(position) <= data.radius_px:
					enemy.take_damage(data.effect_value, &"glow")
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
	if online:
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
	return {"online": online, "repair_left": _repair_left, "pulse_left": _pulse_left}


func restore_save_state(state: Dictionary) -> void:
	online = bool(state.get("online", true))
	_repair_left = float(state.get("repair_left", -1.0)) # 修复进度也是确定性状态
	_pulse_left = float(state.get("pulse_left", data.interval_seconds if online else 0.0))
	queue_redraw()


func _draw() -> void:
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
