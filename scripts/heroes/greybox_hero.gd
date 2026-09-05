class_name GreyboxHero
extends Node2D
## 灰盒英雄（M1/M3）：岚舟·苇（PRD §7.2）/ 铸手·穆恩（M3 前排与机关）。
## 点击地面移动（右键）；自动攻击射程内最近敌人；
## 技能 A 钩索转移（位移）/ B 照明标记（承伤 +25%）/ 终极技 航线扫掠（消耗 80 航标充能）。
## 倒地/复归（25 秒）为 M2 范围；灰盒敌人不攻击英雄。
## 模块C 视觉：按 data.id 剪影（苇叶舟 / 壮实锤手），朝向随移动/攻击方向旋转，
## 攻击时向目标前冲 2px 回弹（_lunge，sim_tick 衰减，暂停定格是特性）。

const COLOR_BODY := Color(0.35, 0.85, 0.85) ## 岚舟·苇 青蓝（默认/回退）
const COLOR_OUTLINE := Color(0.10, 0.30, 0.30)
const COLOR_MUEN_BODY := Color(0.92, 0.55, 0.26) ## 铸手·穆恩 橙铜
const COLOR_MUEN_OUTLINE := Color(0.34, 0.17, 0.07)

const LUNGE_TIME := 0.1 ## 攻击前冲动作时长（秒）
const LUNGE_PX := 2.0 ## 前冲峰值位移（px）

var data: HeroData
var enemies: Array = [] ## 由战斗场景注入（数组按引用共享）
var becon: BeconLedger
var devices: Array = [] ## M3：可交互环境装置引用
var barrier_seconds: float = 0.0
var forge_seconds: float = 0.0

var current_hp: float = 1.0
var move_target: Vector2
var distance_moved: float = 0.0
var skills_used: Dictionary = {} ## skill_id -> 使用次数（冒烟证据）
var is_down: bool = false ## 倒地（PRD §7.1：倒下 25 秒复归，不永久死亡）
var selected: bool = false ## 选中轮廓（PRD §7.3）

## 朝向角（弧度，+x 为 0）：随移动/攻击方向更新，仅影响剪影旋转，不影响 sim。
var facing: float = 0.0

var _attack_cd: float = 0.0
var _cooldowns: Dictionary = {} ## skill_id -> 剩余秒数
var _revive_left: float = 0.0
var _lunge: float = 0.0 ## 攻击前冲剩余秒（视觉，sim_tick 衰减）


func setup(p_data: HeroData, p_becon: BeconLedger) -> void:
	data = p_data
	becon = p_becon
	current_hp = data.max_hp
	move_target = position
	facing = 0.0
	for skill: SkillData in [data.skill_a, data.skill_b, data.ultimate]:
		_cooldowns[skill.id] = 0.0
		skills_used[skill.id] = 0


func sim_tick(delta: float) -> void:
	if _lunge > 0.0:
		_lunge = maxf(0.0, _lunge - delta)
	barrier_seconds = maxf(0.0, barrier_seconds - delta)
	forge_seconds = maxf(0.0, forge_seconds - delta)
	if is_down:
		_revive_left -= delta
		queue_redraw() # 复归进度弧逐 tick 生长
		if _revive_left <= 0.0:
			_revive()
		return
	for skill_id: StringName in _cooldowns:
		_cooldowns[skill_id] = maxf(0.0, _cooldowns[skill_id] - delta)
	_attack_cd -= delta
	# 移动
	var need_redraw := _lunge > 0.0
	var dist: float = position.distance_to(move_target)
	if dist > 2.0:
		var step: float = minf(data.move_speed * delta, dist)
		position = position.move_toward(move_target, step)
		distance_moved += step
		facing = position.direction_to(move_target).angle()
		need_redraw = true
	# 自动攻击最近敌人
	if _attack_cd <= 0.0:
		var target := _nearest_enemy(data.attack_range)
		if target != null:
			facing = position.direction_to(target.position).angle()
			_lunge = LUNGE_TIME # 攻击前冲动作（视觉）
			target.take_damage(data.damage, &"physical")
			_attack_cd = data.attack_period
			need_redraw = true
		else:
			_attack_cd = 0.1
	# 自动施放辅助（PRD §7.3 实验项，设置开关）：基础主动技 B 就绪且有目标时自动释放
	if bool(SettingsService.get_value("gameplay", "auto_cast_basic", false)):
		if _skill_ready(data.skill_b) and _nearest_enemy(200.0) != null:
			use_skill_b()
	if need_redraw:
		queue_redraw()


## 倒地与复归（PRD §7.1：25 秒后 30% HP 复归）。M2 灰盒敌人不主动攻击英雄，
## 本接口供装置脉冲反噬/未来敌人攻击与单元测试使用。
func take_damage(amount: float) -> void:
	if is_down:
		return
	current_hp -= amount
	queue_redraw()
	if current_hp <= 0.0:
		is_down = true
		_revive_left = data.revive_seconds
		EventBus.hero_down.emit()
		print("[M2] hero down, revive in %.0fs" % data.revive_seconds)


func revive_progress() -> float:
	return 1.0 - _revive_left / data.revive_seconds if is_down else 1.0


func _revive() -> void:
	is_down = false
	current_hp = data.max_hp * 0.3
	EventBus.hero_revived.emit()
	queue_redraw()
	print("[M2] hero revived (hp=%.0f)" % current_hp)


## 移动指令：目标必须在地图内（PRD §7.3 路径失败反馈）；返回 false 表示不可达。
func command_move(pos: Vector2) -> bool:
	if is_down:
		return false
	if pos.x < 0.0 or pos.x > 640.0 or pos.y < 0.0 or pos.y > 360.0:
		return false
	move_target = pos
	return true


## 技能 A：钩索转移 —— 跃至可达点（灰盒：直接位移，落点夹在地图内）。
func use_skill_a(target_pos: Vector2 = Vector2.ZERO) -> bool:
	if is_down or not _skill_ready(data.skill_a):
		return false
	if data.skill_a.effect == &"dash":
		position = Vector2(clampf(target_pos.x, 0.0, 640.0), clampf(target_pos.y, 0.0, 360.0))
		move_target = position
	elif data.skill_a.effect == &"barrier":
		barrier_seconds = maxf(barrier_seconds, data.skill_a.duration_seconds)
		for enemy: Variant in enemies:
			if enemy is GreyboxEnemy and enemy.is_alive() and enemy.position.distance_to(position) <= data.skill_a.radius_px:
				enemy.apply_slow(0.35, data.skill_a.duration_seconds)
	_commit_skill(data.skill_a)
	return true


## 技能 B：照明标记 —— 200px 内最近敌人承伤 +mark_multiplier，持续 duration 秒。
func use_skill_b() -> bool:
	if is_down or not _skill_ready(data.skill_b):
		return false
	if data.skill_b.effect == &"mark":
		var target := _nearest_enemy(200.0)
		if target == null:
			return false
		target.apply_mark(data.skill_b.duration_seconds, data.skill_b.mark_multiplier)
	elif data.skill_b.effect == &"repair":
		var repaired := false
		for device: Variant in devices:
			if device is GreyboxDevice and not device.online and device.position.distance_to(position) <= data.skill_b.radius_px + 24.0:
				device.force_repair()
				repaired = true
		if not repaired:
			return false
	_commit_skill(data.skill_b)
	return true


## 终极技：航线扫掠 —— 消耗航标充能，对所有存活敌人造成辉光伤害（与潮汐仪竞争资源）。
func use_ultimate() -> bool:
	if is_down or _cooldowns[data.ultimate.id] > 0.0:
		return false
	if not becon.try_spend(data.ultimate.becon_cost):
		EventBus.ultimate_failed_no_becon.emit()
		print("[M1] ultimate refused: becon %d < %d" % [becon.current, data.ultimate.becon_cost])
		return false
	if data.ultimate.effect == &"route_sweep":
		for enemy: Variant in enemies.duplicate():
			if enemy is GreyboxEnemy and enemy.is_alive():
				enemy.take_damage(data.ultimate.damage, data.ultimate.damage_type)
	elif data.ultimate.effect == &"forge_wall":
		forge_seconds = maxf(forge_seconds, data.ultimate.duration_seconds)
		barrier_seconds = maxf(barrier_seconds, data.ultimate.duration_seconds)
		for enemy: Variant in enemies:
			if enemy is GreyboxEnemy and enemy.is_alive() and enemy.position.distance_to(position) <= data.ultimate.radius_px:
				enemy.apply_slow(0.55, data.ultimate.duration_seconds)
				enemy.take_damage(data.ultimate.damage, data.ultimate.damage_type)
	_commit_skill(data.ultimate)
	return true


func cooldown_remaining(skill_id: StringName) -> float:
	return _cooldowns.get(skill_id, 0.0)


func get_save_state() -> Dictionary:
	return {
		"position": [position.x, position.y],
		"move_target": [move_target.x, move_target.y], # 移动途中存档也需恢复（确定性）
		"current_hp": current_hp,
		"cooldowns": _cooldowns.duplicate(),
		"is_down": is_down,
		"revive_left": _revive_left,
		"attack_cd": _attack_cd, # 普攻相位（确定性）
		"barrier_seconds": barrier_seconds,
		"forge_seconds": forge_seconds,
	}


func restore_save_state(state: Dictionary) -> void:
	var pos: Array = state.get("position", [position.x, position.y])
	position = Vector2(pos[0], pos[1])
	var target: Array = state.get("move_target", pos)
	move_target = Vector2(target[0], target[1])
	current_hp = float(state.get("current_hp", data.max_hp))
	is_down = bool(state.get("is_down", false))
	_revive_left = float(state.get("revive_left", 0.0))
	_attack_cd = float(state.get("attack_cd", 0.0))
	barrier_seconds = float(state.get("barrier_seconds", 0.0))
	forge_seconds = float(state.get("forge_seconds", 0.0))
	var cooldowns: Dictionary = state.get("cooldowns", {})
	for skill_id: StringName in cooldowns:
		_cooldowns[StringName(skill_id)] = float(cooldowns[skill_id])


func _skill_ready(skill: SkillData) -> bool:
	return _cooldowns[skill.id] <= 0.0


func _commit_skill(skill: SkillData) -> void:
	_cooldowns[skill.id] = skill.cooldown_seconds
	skills_used[skill.id] += 1
	EventBus.hero_skill_used.emit(skill.id)
	print("[M1] hero skill used: %s" % skill.id)


func _nearest_enemy(max_range: float) -> GreyboxEnemy:
	var best: GreyboxEnemy = null
	var best_dist := max_range
	for enemy: Variant in enemies:
		if not (enemy is GreyboxEnemy) or not enemy.is_alive():
			continue
		var dist: float = position.distance_to(enemy.position)
		if dist <= best_dist:
			best_dist = dist
			best = enemy
	return best


# ---------------------------------------------------------------------------
# 绘制（模块C：按 data.id 剪影 + 朝向旋转 + 攻击前冲）
# ---------------------------------------------------------------------------


## 英雄主色（无障碍重映射后）。
func _hero_colors() -> Array:
	if data != null and data.id == &"hero_zhushou_muen":
		return [UiPalette.apply(COLOR_MUEN_BODY), UiPalette.apply(COLOR_MUEN_OUTLINE)]
	return [UiPalette.apply(COLOR_BODY), UiPalette.apply(COLOR_OUTLINE)]


func _draw() -> void:
	if data == null:
		return
	var palette: Array = _hero_colors()
	var body: Color = palette[0]
	var edge: Color = palette[1]
	if is_down:
		# 倒地：剪影变暗 + 复归进度弧（不随朝向旋转，进度逐 tick 生长）
		var dim := body.darkened(0.6)
		var dim_edge := edge.darkened(0.6)
		_draw_silhouette(dim, dim_edge)
		draw_arc(Vector2.ZERO, 14.0, -PI / 2.0, -PI / 2.0 + TAU * revive_progress(), 24, Color(0.4, 0.9, 0.9), 2.0)
		return
	# 攻击范围环（可读性辅助，低 alpha）
	draw_arc(Vector2.ZERO, data.attack_range, 0.0, TAU, 40, Color(body, 0.06), 1.0)
	# 剪影：按 facing 旋转 + 攻击前冲位移（sin 回弹，LUNGE_TIME 内从 0 → 2px → 0）
	var push := 0.0
	if _lunge > 0.0:
		push = sin(PI * (1.0 - _lunge / LUNGE_TIME)) * LUNGE_PX
	draw_set_transform(Vector2.from_angle(facing) * push, facing, Vector2.ONE)
	_draw_silhouette(body, edge)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if selected:
		# 选中轮廓（PRD §7.3）
		draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.9), 1.5)
	# 生命条
	var bar_w := 24.0
	var ratio: float = clampf(current_hp / data.max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_w / 2.0, -18.0), Vector2(bar_w, 3.0)), edge, true)
	draw_rect(Rect2(Vector2(-bar_w / 2.0, -18.0), Vector2(bar_w * ratio, 3.0)), Color(0.4, 0.9, 0.9), true)


## 英雄剪影：+x 为"前方"，由 _draw 按 facing 旋转。M4-A：正式精灵优先，缺失回退程序化剪影。
func _draw_silhouette(body: Color, edge: Color) -> void:
	if data != null:
		var tex := ArtLibrary.hero_tex(data.id)
		if tex != null:
			draw_texture(tex, Vector2(-16.0, -16.0), Color(1, 1, 1) if not is_down else Color(0.4, 0.4, 0.45))
			return
	if data != null and data.id == &"hero_zhushou_muen":
		_draw_muen_smith(body, edge)
	elif data != null and data.id == &"hero_lanzhou_wei":
		_draw_lanzhou_boat(body, edge)
	else:
		# 回退：现有菱形占位
		var points := PackedVector2Array([Vector2(0, -11), Vector2(8, 0), Vector2(0, 11), Vector2(-8, 0)])
		draw_colored_polygon(points, body)
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), edge, 1.5)


## 岚舟·苇：尖头苇叶舟梭形 + 中桅杆点。
func _draw_lanzhou_boat(body: Color, edge: Color) -> void:
	var hull := PackedVector2Array([
		Vector2(11.5, 0.0), Vector2(3.0, -4.6), Vector2(-8.5, -3.2),
		Vector2(-10.5, 0.0), Vector2(-8.5, 3.2), Vector2(3.0, 4.6),
	])
	draw_colored_polygon(hull, body)
	var loop := hull.duplicate()
	loop.append(hull[0])
	draw_polyline(loop, edge, 1.6)
	# 船舷内侧深色线（明暗层次）
	draw_polyline(PackedVector2Array([Vector2(5.0, -1.6), Vector2(-7.0, -1.2), Vector2(-8.6, 0.0)]),
		VisualTheme.shade(body, 0.55), 1.2)
	draw_polyline(PackedVector2Array([Vector2(5.0, 1.6), Vector2(-7.0, 1.2), Vector2(-8.6, 0.0)]),
		VisualTheme.shade(body, 0.55), 1.2)
	# 桅杆点
	draw_circle(Vector2(-0.6, -0.8), 1.4, Color(0.98, 0.96, 0.9))
	draw_circle(Vector2(-0.6, 1.0), 1.0, VisualTheme.shade(body, 0.7))


## 铸手·穆恩：壮实方肩躯干 + 前置锤（顶部俯视剪影，锤横在身前）。
func _draw_muen_smith(body: Color, edge: Color) -> void:
	var torso := PackedVector2Array([
		Vector2(-7.5, -4.4), Vector2(-5.0, -5.6), Vector2(1.5, -5.9),
		Vector2(5.5, -4.4), Vector2(5.9, 0.0), Vector2(5.5, 4.4),
		Vector2(1.5, 5.9), Vector2(-5.0, 5.6), Vector2(-7.5, 4.4),
	])
	draw_colored_polygon(torso, body)
	var loop := torso.duplicate()
	loop.append(torso[0])
	draw_polyline(loop, edge, 1.7)
	# 肩甲亮线（明暗层次）
	draw_polyline(PackedVector2Array([Vector2(-4.5, -4.8), Vector2(1.5, -5.0), Vector2(4.6, -3.9)]),
		VisualTheme.shade(body, 1.18), 1.3)
	# 头部（俯视偏前圆点）
	draw_circle(Vector2(0.4, 0.0), 2.6, VisualTheme.shade(body, 1.1))
	# 锤柄横在身前 + 锤头（前）
	draw_line(Vector2(1.0, 0.0), Vector2(9.8, 0.0), VisualTheme.shade(body, 0.55), 2.0)
	draw_rect(Rect2(Vector2(9.2, -4.8), Vector2(3.0, 9.6)), body, true)
	draw_rect(Rect2(Vector2(9.2, -4.8), Vector2(3.0, 9.6)), edge, false, 1.2)
	# 锤头高光
	draw_rect(Rect2(Vector2(9.8, -3.6), Vector2(1.2, 2.4)), VisualTheme.shade(body, 1.2), true)
