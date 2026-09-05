class_name GreyboxEnemy
extends Node2D
## 灰盒敌人（M2）：沿预制 PathNetwork 路线折线插值移动，无实时寻路（RESEARCH_REPORT.md §5）。
## 由战斗场景以固定 tick 驱动 sim_tick（PRD §18.5 确定性模拟）。
## 抗性公式：实际伤害 = 基础 × 波动 × 100 / (100 + max(-50, 抗性))（PRD §3.3）。
## 状态：照明标记（承伤 ×n）、削甲（倒钩模块）、减速（迟滞弦）、沉默（断响，抑制支援光环）、
## 护盾（灯寄生体：先于生命承伤）、支援光环（潮背导航员：由战斗场景每 tick 注入 aura_boost）。
## 可读性：主体色数据驱动 + 按 data.id 剪影（模块C）+ 标签文字缩写浮标 + 护盾环 + 状态环
## （色/形/文字三重编码，PRD §3.4）。剪影朝移动方向旋转；受击闪白；减速整体覆蓝；精英金边。
## 视觉衰减动画刻意走 sim_tick（暂停定格是特性）。

signal died(enemy: GreyboxEnemy)
signal reached_goal(enemy: GreyboxEnemy)
signal boss_phase_changed(enemy: GreyboxEnemy, phase_index: int, label: String)

const HIT_FLASH_TIME := 0.06 ## 受击闪白持续时间（秒，sim_tick 衰减）
const SLOW_RGB := Color(0.45, 0.70, 1.0) ## 减速覆色 RGB（alpha 取自 VisualTheme.SLOW_TINT）
const COLOR_ELITE_EDGE := Color(0.98, 0.80, 0.35) ## 精英金色描边

## 标签缩写浮标（色+形+文字三重编码的文字腿，正式美术前占位）
const TAG_GLYPHS: Dictionary = {
	&"basic": "", &"swarm": "群", &"swift": "迅", &"heavy": "甲",
	&"shield": "盾", &"support": "援", &"glow": "辉", &"healer": "疗",
	&"engineer": "机", &"boss": "王",
}

var data: EnemyData
var hp: float = 1.0
var shield: float = 0.0
var marked_seconds: float = 0.0
var slow_seconds: float = 0.0
var slow_mult: float = 0.0 ## 减速比例（0.3 = -30%）
var silenced_seconds: float = 0.0
var aura_boost: float = 1.0 ## 由战斗场景每 tick 重置并注入（支援光环）
var boss_phase: int = 0 ## 0/1/2，由 _update_boss_phase 维护，main 亦读取用于证据记录
var _boss_speed_mult: float = 1.0
var _boss_armor_bonus: float = 0.0

## 朝向角（弧度，+x 为 0）：随路线位移方向更新，仅影响剪影旋转，不影响 sim。
var facing: float = 0.0
## 受击闪白剩余秒（视觉，sim_tick 衰减）
var _hit_flash: float = 0.0

var _route: PackedVector2Array
var _cum_lengths: PackedFloat32Array # 各顶点累计里程
var _total_length: float = 0.0
var _progress_px: float = 0.0
var _rng: RandomNumberGenerator
var _mark_multiplier: float = 1.25
var _shred_value: float = 0.0
var _shred_seconds: float = 0.0


func setup(p_data: EnemyData, route_points: PackedVector2Array, rng: RandomNumberGenerator) -> void:
	data = p_data
	hp = data.max_hp
	shield = data.shield_hp
	_route = route_points
	_rng = rng
	marked_seconds = 0.0
	slow_seconds = 0.0
	slow_mult = 0.0
	silenced_seconds = 0.0
	aura_boost = 1.0
	_shred_value = 0.0
	_shred_seconds = 0.0
	boss_phase = 0
	_boss_speed_mult = 1.0
	_boss_armor_bonus = 0.0
	_hit_flash = 0.0
	facing = (route_points[1] - route_points[0]).angle() if route_points.size() > 1 else 0.0
	_cum_lengths = PackedFloat32Array([0.0])
	_total_length = 0.0
	for i: int in range(1, _route.size()):
		_total_length += _route[i - 1].distance_to(_route[i])
		_cum_lengths.append(_total_length)
	position = _route[0]


## 目标选择用：沿路线的推进里程（"最前" = 最大 progress）。
func progress_px() -> float:
	return _progress_px


func is_alive() -> bool:
	return hp > 0.0


func apply_mark(duration: float, multiplier: float) -> void:
	marked_seconds = maxf(marked_seconds, duration)
	_mark_multiplier = multiplier
	queue_redraw()


func apply_armor_shred(value: float, duration: float) -> void:
	_shred_value = maxf(_shred_value, value)
	_shred_seconds = maxf(_shred_seconds, duration)


func apply_slow(mult: float, duration: float) -> void:
	slow_mult = maxf(slow_mult, mult)
	slow_seconds = maxf(slow_seconds, duration)
	queue_redraw() # 减速覆蓝（视觉）即时生效


func apply_silence(duration: float) -> void:
	silenced_seconds = maxf(silenced_seconds, duration)
	queue_redraw()


func is_silenced() -> bool:
	return silenced_seconds > 0.0


## 有效速度：基础 × 支援光环 × (1 - 减速)。
func effective_speed() -> float:
	var slow_factor := 1.0 - slow_mult if slow_seconds > 0.0 else 1.0
	var elite_mult := 1.1 if data.elite and data.elite_affixes.has(&"tidebound") else 1.0
	return data.speed_px_per_sec * aura_boost * slow_factor * elite_mult * _boss_speed_mult


func take_damage(base: float, damage_type: StringName) -> float:
	var variance: float = 1.0
	if not bool(SettingsService.get_value("gameplay", "fixed_damage", false)):
		variance = _rng.randf_range(0.95, 1.05) # 伤害波动 ±5%（PRD §3.3）
	var resist: float = 0.0
	match damage_type:
		&"physical":
			resist = data.armor + _boss_armor_bonus + (20.0 if data.elite and data.elite_affixes.has(&"armored") else 0.0) - _shred_value
		&"glow":
			resist = data.glow_resist
	var coef: float = 100.0 / (100.0 + maxf(-50.0, resist))
	var actual: float = base * variance * coef
	if marked_seconds > 0.0:
		actual *= _mark_multiplier
	# 护盾先于生命承伤（灯寄生体，PRD §8.6）
	if shield > 0.0:
		var absorbed := minf(shield, actual)
		shield -= absorbed
		actual -= absorbed
	hp -= actual
	_hit_flash = HIT_FLASH_TIME # 受击闪白反馈（视觉）
	if data.boss:
		_update_boss_phase()
	queue_redraw()
	if hp <= 0.0:
		died.emit(self)
	return actual


func sim_tick(delta: float) -> void:
	if not is_alive():
		return
	if marked_seconds > 0.0:
		marked_seconds -= delta
		if marked_seconds <= 0.0:
			queue_redraw()
	if slow_seconds > 0.0:
		slow_seconds -= delta
		if slow_seconds <= 0.0:
			slow_mult = 0.0
			queue_redraw() # 撤减速覆蓝（视觉）
	if silenced_seconds > 0.0:
		silenced_seconds -= delta
		if silenced_seconds <= 0.0:
			queue_redraw()
	if data.elite and data.elite_affixes.has(&"regenerating"):
		hp = minf(data.max_hp, hp + data.max_hp * 0.002 * delta)
	if _shred_seconds > 0.0:
		_shred_seconds -= delta
		if _shred_seconds <= 0.0:
			_shred_value = 0.0
	var need_redraw := _hit_flash > 0.0 # 闪白期间逐 tick 衰减
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)
	var prev_pos := position
	_progress_px += effective_speed() * delta
	if _progress_px >= _total_length:
		reached_goal.emit(self)
		return
	position = _sample(_progress_px)
	var move_dir := position - prev_pos
	if move_dir.length_squared() > 0.0001:
		facing = move_dir.angle()
		need_redraw = true # 剪影朝向随移动逐 tick 更新
	if need_redraw:
		queue_redraw()


func _update_boss_phase() -> void:
	if not data.boss or data.boss_phases.is_empty():
		return
	var ratio := hp / maxf(data.max_hp, 1.0)
	var next_phase := boss_phase
	for i: int in range(data.boss_phases.size()):
		var phase: Dictionary = data.boss_phases[i]
		if ratio <= float(phase.get("threshold", 0.0)):
			next_phase = i + 1
	if next_phase <= boss_phase or next_phase > data.boss_phases.size():
		return
	boss_phase = next_phase
	var phase_data: Dictionary = data.boss_phases[boss_phase - 1]
	_boss_speed_mult = float(phase_data.get("speed_mult", 1.0))
	_boss_armor_bonus = float(phase_data.get("armor_bonus", 0.0))
	shield += float(phase_data.get("shield_restore", 0.0))
	var label := String(phase_data.get("label", "Boss phase %d" % boss_phase))
	boss_phase_changed.emit(self, boss_phase, label)
	print("[M3-BOSS] %s phase=%d label=%s hp=%.0f shield=%.0f" % [data.id, boss_phase, label, hp, shield])


func _sample(dist: float) -> Vector2:
	for i: int in range(1, _cum_lengths.size()):
		if dist <= _cum_lengths[i]:
			var seg_t: float = (dist - _cum_lengths[i - 1]) / (_cum_lengths[i] - _cum_lengths[i - 1])
			return _route[i - 1].lerp(_route[i], seg_t)
	return _route[_route.size() - 1]


# ---------------------------------------------------------------------------
# 绘制（模块C：按 data.id 剪影，全部 _draw 矢量图元）
# ---------------------------------------------------------------------------


func _draw() -> void:
	if data == null:
		return
	var s := data.radius_px
	# 主体色：无障碍重映射 → 减速覆蓝 → Boss 相位泛红 → 受击闪白
	var mid := UiPalette.apply(data.body_color)
	if slow_seconds > 0.0:
		mid = VisualTheme.blend(mid, SLOW_RGB, VisualTheme.SLOW_TINT.a)
	if data.boss and boss_phase >= 1:
		mid = VisualTheme.blend(mid, Color(0.90, 0.18, 0.12), 0.18 + 0.08 * float(mini(boss_phase, 2)))
	if _hit_flash > 0.0:
		mid = VisualTheme.blend(mid, Color.WHITE, _hit_flash / HIT_FLASH_TIME)
	var light := VisualTheme.shade(mid, 1.16)
	var dark := VisualTheme.shade(mid, 0.66)
	var edge := COLOR_ELITE_EDGE if data.elite else VisualTheme.OUTLINE
	# 剪影（随 facing 旋转；生命条/状态环保持轴对齐，不旋转）
	draw_set_transform(Vector2.ZERO, facing, Vector2.ONE)
	# M4-A：正式精灵优先（modulate 表达减速/受击闪白，缺失回退程序化剪影）
	var tex := ArtLibrary.enemy_tex(data.id)
	if tex != null:
		var mod := Color(1.0, 1.0, 1.0)
		if slow_seconds > 0.0:
			mod = Color(0.62, 0.78, 1.05)
		if _hit_flash > 0.0:
			var f := _hit_flash / HIT_FLASH_TIME
			mod = mod.lerp(Color(2.6, 2.6, 2.6), f)
		draw_texture(tex, Vector2(-16.0, -16.0), mod)
	else:
		_draw_silhouette(s, mid, light, dark, edge)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_status_rings(s)
	_draw_bars_glyph(s)


## 12 种敌人剪影（未知 id 回退现有圆）。统一以 +x 为"前方"，_draw 里已按 facing 旋转。
func _draw_silhouette(s: float, mid: Color, light: Color, dark: Color, edge: Color) -> void:
	match data.id:
		&"mast_rat_swarm":
			# 桅鼠群：三只小三角聚散簇，领队居中偏前、两只稍落后两侧
			_draw_rat(Vector2(0.12 * s, 0.0), s, mid, edge)
			_draw_rat(Vector2(-0.45 * s, -0.52 * s), s * 0.8, dark, edge)
			_draw_rat(Vector2(-0.45 * s, 0.52 * s), s * 0.8, dark, edge)
		&"splitfin_dasher":
			# 裂鳍疾行者：流线鱼雷形 + 分叉尾鳍 + 眼点
			var fish_body := PackedVector2Array([
				Vector2(1.05 * s, 0.0), Vector2(0.1 * s, -0.34 * s),
				Vector2(-0.78 * s, -0.22 * s), Vector2(-0.98 * s, 0.0),
				Vector2(-0.78 * s, 0.22 * s), Vector2(0.1 * s, 0.34 * s),
			])
			draw_colored_polygon(fish_body, mid)
			_stroke(fish_body, edge, 1.6)
			var tail := PackedVector2Array([
				Vector2(-0.5 * s, -0.4 * s), Vector2(-1.5 * s, 0.0), Vector2(-0.5 * s, 0.4 * s),
			])
			draw_colored_polygon(tail, light)
			_stroke(tail, edge, 1.4)
			draw_circle(Vector2(0.34 * s, -0.14 * s), maxf(0.8, 0.1 * s), dark)
		&"tideglass_runner":
			# 潮璃奔行者：半透明菱形（奔跑的潮汐玻璃碎体）
			var gem := PackedVector2Array([
				Vector2(1.05 * s, 0.0), Vector2(0.0, -0.7 * s),
				Vector2(-1.05 * s, 0.0), Vector2(0.0, 0.7 * s),
			])
			draw_colored_polygon(gem, Color(mid, 0.5))
			_stroke(gem, edge, 1.5)
			draw_circle(Vector2.ZERO, maxf(0.8, 0.14 * s), Color(light, 0.85))
		&"salt_shell_walker":
			# 盐壳行者：圆壳 + 四周步足点
			var dome := Vector2(0.0, -0.06 * s)
			draw_circle(dome, 0.8 * s, mid)
			draw_arc(dome, 0.8 * s, 0.0, TAU, 18, edge, 1.6)
			draw_arc(dome, 0.62 * s, PI * 0.15, PI * 0.85, 8, light, 1.2)
			for m: float in [-1.0, 1.0]:
				for lr: float in [-1.0, 1.0]:
					draw_circle(Vector2(lr * 0.62 * s, m * 0.62 * s), maxf(0.9, 0.13 * s), dark)
		&"rust_armor_carrier":
			# 锈甲运输者：大方甲 + 铆钉点
			var plate := PackedVector2Array([
				Vector2(-0.95 * s, -0.72 * s), Vector2(0.95 * s, -0.72 * s),
				Vector2(0.95 * s, 0.72 * s), Vector2(-0.95 * s, 0.72 * s),
			])
			draw_colored_polygon(plate, mid)
			_stroke(plate, edge, 1.8)
			var lid := PackedVector2Array([
				Vector2(-0.62 * s, -0.48 * s), Vector2(0.62 * s, -0.48 * s),
				Vector2(0.62 * s, 0.48 * s), Vector2(-0.62 * s, 0.48 * s),
			])
			draw_colored_polygon(lid, Color(light, 0.5))
			for mx: float in [-1.0, 1.0]:
				for my: float in [-1.0, 1.0]:
					draw_circle(Vector2(mx * 0.7 * s, my * 0.5 * s), maxf(0.8, 0.09 * s), dark)
		&"lamp_leech":
			# 灯芯蛭：椭圆蛭身 + 前探头灯小点（护盾弧在外层保留）
			var leech_body := _ellipse(0.8 * s, 0.4 * s)
			draw_colored_polygon(leech_body, mid)
			_stroke(leech_body, edge, 1.5)
			draw_circle(Vector2(0.55 * s, 0.0), maxf(1.0, 0.2 * s), Color(1.0, 0.9, 0.55))
			draw_circle(Vector2(0.55 * s, -0.06 * s), maxf(0.5, 0.09 * s), Color(1.0, 1.0, 0.92))
		&"brine_spitter":
			# 卤水喷吐者：圆身 + 前伸管状吻部
			draw_circle(Vector2.ZERO, 0.76 * s, mid)
			draw_arc(Vector2.ZERO, 0.76 * s, 0.0, TAU, 18, edge, 1.6)
			var snout := PackedVector2Array([
				Vector2(0.3 * s, -0.2 * s), Vector2(1.2 * s, -0.1 * s),
				Vector2(1.2 * s, 0.1 * s), Vector2(0.3 * s, 0.2 * s),
			])
			draw_colored_polygon(snout, dark)
			_stroke(snout, edge, 1.4)
			draw_circle(Vector2(1.2 * s, 0.0), maxf(0.8, 0.08 * s), Color(0.2, 0.35, 0.4))
			draw_circle(Vector2(0.2 * s, -0.34 * s), maxf(0.9, 0.12 * s), Color(0.12, 0.25, 0.3))
		&"salt_mender":
			# 盐愈者：圆身 + 头顶白十字（治疗编码）
			draw_circle(Vector2.ZERO, 0.78 * s, mid)
			draw_arc(Vector2.ZERO, 0.78 * s, 0.0, TAU, 18, edge, 1.6)
			var cx := 0.28 * s
			var cy := -0.42 * s
			var arm := 0.2 * s
			draw_line(Vector2(cx - arm, cy), Vector2(cx + arm, cy), Color(1.0, 1.0, 1.0, 0.92), 1.6)
			draw_line(Vector2(cx, cy - arm), Vector2(cx, cy + arm), Color(1.0, 1.0, 1.0, 0.92), 1.6)
		&"tide_back_navigator":
			# 潮背导航员：宽椭圆 + 支援光环（aura_radius > 0 时画淡淡 aura 圈）
			var nav_body := _ellipse(0.9 * s, 0.42 * s)
			draw_colored_polygon(nav_body, mid)
			_stroke(nav_body, edge, 1.5)
			draw_circle(Vector2(-0.08 * s, 0.0), maxf(1.4, 0.3 * s), light)
			draw_circle(Vector2(0.72 * s, 0.0), maxf(0.9, 0.12 * s), Color(0.3, 0.2, 0.45))
		&"reef_sapper":
			# 暗礁破坏者：三角凿形（前尖后宽的凿身）
			var wedge := PackedVector2Array([
				Vector2(1.18 * s, 0.0), Vector2(-0.42 * s, -0.66 * s),
				Vector2(-0.9 * s, -0.42 * s), Vector2(-0.9 * s, 0.42 * s),
				Vector2(-0.42 * s, 0.66 * s),
			])
			draw_colored_polygon(wedge, mid)
			_stroke(wedge, edge, 1.6)
			draw_circle(Vector2(0.42 * s, -0.2 * s), maxf(0.9, 0.11 * s), dark)
		&"anchor_crab_guardian":
			# 锚蟹卫（精英）：大蟹壳 + 双钳 + 步足（金色描边由 edge 提供）
			_draw_crab(s, mid, light, dark, edge, 0.66, 0.52, 2.2)
		&"anchor_crab_king":
			# 吞锚蟹王（Boss）：巨壳 + 王冠棘刺 + 双大钳 + 步足；phase≥1 泛红、phase 2 裂纹
			_draw_crab(s, mid, light, dark, edge, 0.9, 0.7, 3.0, true)
		_:
			# 未知 id 回退：现有圆形占位
			draw_circle(Vector2.ZERO, s, mid)
			draw_arc(Vector2.ZERO, s, 0.0, TAU, 18, edge, 1.6)


## 小三角鼠（桅鼠群单元）。
func _draw_rat(center: Vector2, size: float, color: Color, edge: Color) -> void:
	var tri := PackedVector2Array([
		center + Vector2(0.5 * size, 0.0),
		center + Vector2(-0.5 * size, -0.34 * size),
		center + Vector2(-0.5 * size, 0.34 * size),
	])
	draw_colored_polygon(tri, color)
	_stroke(tri, edge, 1.2)


## 通用蟹类剪影：壳 + 王冠棘刺（仅王）+ 双钳 + 步足 + 裂纹（仅王 phase2）。
func _draw_crab(s: float, mid: Color, light: Color, dark: Color, edge: Color,
		rx: float, ry: float, limb_w: float, is_king: bool = false) -> void:
	# 王冠棘刺：先画、后盖壳，只露出壳缘外的刺尖（仅王）
	if is_king:
		for i: int in range(5):
			var a := -PI / 2.0 + (float(i) - 2.0) * 0.62
			var base_p := Vector2(cos(a) * 0.86 * s, sin(a) * 0.72 * s)
			var tip := base_p + Vector2(cos(a), sin(a)) * 0.3 * s
			var tan_v := Vector2(-sin(a), cos(a)) * 0.17 * s
			draw_colored_polygon(PackedVector2Array([base_p - tan_v, base_p + tan_v, tip]), dark)
	# 步足（壳缘外短腿线）
	for m: float in [-1.0, 1.0]:
		for wx: float in [-0.72, 0.0, 0.62]:
			var bx := wx * s
			var by := m * ry * s
			draw_line(Vector2(bx, by), Vector2(bx + 0.14 * s, by + m * 0.4 * s), dark, 1.5)
	# 壳
	var shell := _ellipse(rx * s, ry * s, 16)
	draw_colored_polygon(shell, mid)
	_stroke(shell, edge, 2.4 if is_king else 2.0)
	draw_arc(Vector2(0.0, -0.12 * s), 0.4 * s, PI * 1.05, PI * 1.95, 8, light, 1.4) # 壳顶高光
	# 双钳（左右对称）：臂线 + 腕节 + 上下指
	for sm: float in [-1.0, 1.0]:
		var elbow := Vector2(0.3 * s, sm * ry * s)
		var wrist := Vector2((0.72 if is_king else 0.95) * s, sm * (0.8 if is_king else 0.9) * s)
		draw_line(elbow, wrist, mid, limb_w)
		draw_circle(wrist, maxf(1.2, 0.16 * s), mid)
		draw_circle(wrist + Vector2(0.18 * s, -0.22 * s), maxf(1.0, 0.11 * s), dark)
		draw_circle(wrist + Vector2(0.18 * s, 0.22 * s), maxf(1.0, 0.11 * s), dark)
	# 王 phase2：壳上白色裂纹线
	if is_king and boss_phase >= 2:
		draw_polyline(PackedVector2Array([
			Vector2(-0.25 * s, -0.4 * s), Vector2(0.02 * s, -0.22 * s),
			Vector2(-0.12 * s, 0.05 * s), Vector2(0.1 * s, 0.32 * s),
		]), Color(0.98, 0.98, 0.98, 0.9), 1.6)
		draw_polyline(PackedVector2Array([
			Vector2(0.34 * s, -0.28 * s), Vector2(0.52 * s, -0.02 * s),
			Vector2(0.42 * s, 0.22 * s),
		]), Color(0.98, 0.98, 0.98, 0.9), 1.4)


## 状态环（aura / mark / shield / 沉默），轴对齐、不随 facing 旋转。
func _draw_status_rings(s: float) -> void:
	if data.aura_radius > 0.0:
		draw_arc(Vector2.ZERO, data.aura_radius, 0.0, TAU, 48, Color(0.75, 0.55, 0.95, 0.09), 1.0)
	if marked_seconds > 0.0:
		draw_arc(Vector2.ZERO, s + 4.0, 0.0, TAU, 18, VisualTheme.MARK_RING, 2.0)
	if shield > 0.0:
		draw_arc(Vector2.ZERO, s + 2.5, 0.0, TAU, 18, VisualTheme.SHIELD_BAR, 2.0)
	if silenced_seconds > 0.0:
		draw_arc(Vector2.ZERO, s + 6.5, 0.0, TAU, 18, VisualTheme.SILENCE_MARK, 1.5)


## 生命/护盾条 + 标签浮标。Boss 血条加宽至 48px 且整体上移（y 偏移随半径）。
func _draw_bars_glyph(s: float) -> void:
	var boss := data.boss
	var bar_w := 48.0 if boss else 20.0
	var bar_h := 4.0 if boss else 3.0
	var top := -s - (16.0 if boss else 8.0)
	var ratio: float = clampf(hp / data.max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_w / 2.0, top), Vector2(bar_w, bar_h)), VisualTheme.HP_BAR_BG, true)
	draw_rect(Rect2(Vector2(-bar_w / 2.0, top), Vector2(bar_w * ratio, bar_h)), VisualTheme.HP_BAR, true)
	if data.shield_hp > 0.0:
		var shield_ratio: float = clampf(shield / data.shield_hp, 0.0, 1.0)
		var sh_y := top - bar_h - 1.0
		draw_rect(Rect2(Vector2(-bar_w / 2.0, sh_y), Vector2(bar_w, 2.0)), VisualTheme.HP_BAR_BG, true)
		draw_rect(Rect2(Vector2(-bar_w / 2.0, sh_y), Vector2(bar_w * shield_ratio, 2.0)), VisualTheme.SHIELD_BAR, true)
	# 标签文字缩写（三重编码的文字腿）
	var glyph := ""
	for tag: Variant in data.tags:
		glyph += String(TAG_GLYPHS.get(tag, "?"))
	if not glyph.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(-bar_w / 2.0, top - bar_h - 4.0), glyph,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 1.0, 1.0))


## 闭合折线描边辅助。
func _stroke(pts: PackedVector2Array, color: Color, width: float) -> void:
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, color, width)


## 椭圆多边形顶点（多边形填充 1 个图元，描边 1 个图元）。
func _ellipse(half_x: float, half_y: float, segs: int = 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in range(segs):
		var a := TAU * float(i) / float(segs)
		pts.append(Vector2(cos(a) * half_x, sin(a) * half_y))
	return pts
