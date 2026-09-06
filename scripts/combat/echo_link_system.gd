class_name EchoLinkSystem
extends Node2D
## 回声桩阵链路系统（M2，PRD §6.2）：两座回声桩之间生成辉光伤害线。
## 链路在桩放置/移除时重建（同一对桩距 <= link_max_range 才成链）；
## 每座桩独立 tick 节奏取两者较快者；模块效果取两桩中已挂载者（迟滞弦减速/断响沉默/共振连锁）。
## 由战斗场景以固定 tick 驱动 sim_tick（确定性，PRD §18.5）。

const LINK_BAND_HALF_WIDTH := 10.0 ## 链路伤害带半宽（sim 判定，勿改）
const LINK_COLOR := Color(0.75, 0.65, 1.0, 0.55)
const LINK_COLOR_IDLE := Color(0.55, 0.50, 0.80, 0.30)
const LINK_VISUAL_BAND_WIDTH := 16.0 ## 链路视觉底带宽（原 20px 微调到 16px）
const LINK_FLOW_DOTS := 3 ## 链路流动光点数
const LINK_FLOW_FRAC_PER_SEC := 0.35 ## 光点流动速度（链路全长比例 / 秒，缓慢）
const COLOR_FLOW_CORE := Color(1.0, 1.0, 1.0)

var piles: Array = [] ## Array[GreyboxTower]（data.pair_link == true）
var enemies: Array = [] ## 由战斗场景注入（数组按引用共享）

var _links: Array = [] ## Array[Dictionary] {a, b, tick_left}
var _rng: RandomNumberGenerator
var pulses_total: int = 0 ## ET_DEBUG_SYNC 探针：链路脉冲次数
var _flow: float = 0.0 ## 光点流动相位（0..1，sim_tick 累积，暂停即定格）


func setup(rng: RandomNumberGenerator) -> void:
	_rng = rng


func reset() -> void:
	piles.clear()
	_links.clear()
	pulses_total = 0
	queue_redraw()


func add_pile(tower: GreyboxTower) -> void:
	piles.append(tower)
	_rebuild_links()


func remove_pile(tower: GreyboxTower) -> void:
	piles.erase(tower)
	_rebuild_links()


func link_count() -> int:
	return _links.size()


## suspend 存档：链路脉冲相位也是确定性状态（PRD §15.2），key = "nodeA|nodeB"。
func get_link_timers() -> Dictionary:
	var timers := {}
	for link: Dictionary in _links:
		var a: GreyboxTower = link["a"]
		var b: GreyboxTower = link["b"]
		timers["%s|%s" % [a.node_id, b.node_id]] = link["tick_left"]
	return timers


func restore_link_timers(timers: Dictionary) -> void:
	for link: Dictionary in _links:
		var a: GreyboxTower = link["a"]
		var b: GreyboxTower = link["b"]
		var key := "%s|%s" % [a.node_id, b.node_id]
		if timers.has(key):
			link["tick_left"] = float(timers[key])


func _rebuild_links() -> void:
	_links.clear()
	for i: int in piles.size():
		for j: int in range(i + 1, piles.size()):
			var a: GreyboxTower = piles[i]
			var b: GreyboxTower = piles[j]
			var max_range: float = minf(a.data.link_max_range, b.data.link_max_range)
			if a.position.distance_to(b.position) <= max_range:
				_links.append({"a": a, "b": b, "tick_left": 0.0})
	queue_redraw()


func sim_tick(delta: float) -> void:
	# 流动光点：随固定 tick 累积相位并重绘（无链路时不重绘，性能）
	if not _links.is_empty():
		_flow = wrapf(_flow + delta * LINK_FLOW_FRAC_PER_SEC, 0.0, 1.0)
		queue_redraw()
	for link: Dictionary in _links:
		link["tick_left"] -= delta
		if link["tick_left"] <= 0.0:
			var a: GreyboxTower = link["a"]
			var b: GreyboxTower = link["b"]
			link["tick_left"] += minf(a.eff_attack_period(), b.eff_attack_period())
			_link_pulse(a, b)


func _link_pulse(a: GreyboxTower, b: GreyboxTower) -> void:
	pulses_total += 1
	# C01 第二批候选音频：链路脉冲音（回声桩阵不开火，攻击音在这里；candidate 非最终）
	AudioService.play_event(&"tower_echo_pulse")
	var damage: float = _rng.randf_range(
		(a.eff_damage_min() + b.eff_damage_min()) * 0.5, (a.eff_damage_max() + b.eff_damage_max()) * 0.5)
	var slow_mult := 0.0
	var silence := false
	var chain := 0
	for pile: GreyboxTower in [a, b]:
		if pile.module == null:
			continue
		match pile.module.effect_op:
			&"link_slow":
				slow_mult = maxf(slow_mult, pile.module.effect_value)
			&"link_silence":
				silence = true
			&"link_chain":
				chain += int(pile.module.effect_value)
	var hit: Array = []
	for enemy: Variant in enemies:
		if not (enemy is GreyboxEnemy) or not enemy.is_targetable(): # 隐匿敌不可被链路命中（C09）
			continue
		if _point_segment_distance(enemy.position, a.position, b.position) <= LINK_BAND_HALF_WIDTH + enemy.data.radius_px * 0.5:
			hit.append(enemy)
	for enemy: GreyboxEnemy in hit:
		if slow_mult > 0.0:
			enemy.apply_slow(slow_mult, 0.6)
		if silence:
			enemy.apply_silence(0.6)
		enemy.take_damage(damage, a.data.damage_type)
		if not enemy.is_alive():
			a.total_kills += 1
	# 共振：伤害跳跃到受影响敌人附近的额外目标
	if chain > 0 and not hit.is_empty():
		var chained: Array = []
		for enemy: GreyboxEnemy in hit:
			for other: Variant in enemies:
				if chained.size() >= chain:
					break
				if not (other is GreyboxEnemy) or not other.is_targetable() or hit.has(other) or chained.has(other):
					continue
				if other.position.distance_to(enemy.position) <= 48.0:
					chained.append(other)
		for other: GreyboxEnemy in chained:
			other.take_damage(damage * 0.5, a.data.damage_type)


func total_link_damage_potential() -> float:
	## 战报/平衡统计用
	var total := 0.0
	for link: Dictionary in _links:
		var a: GreyboxTower = link["a"]
		var b: GreyboxTower = link["b"]
		total += (a.eff_damage_min() + a.eff_damage_max() + b.eff_damage_min() + b.eff_damage_max()) * 0.25
	return total


func _point_segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return (a + ab * t - p).length()


func _draw() -> void:
	for link: Dictionary in _links:
		var a: GreyboxTower = link["a"]
		var b: GreyboxTower = link["b"]
		var color := LINK_COLOR
		for pile: GreyboxTower in [a, b]:
			if pile.module != null:
				color = pile.module.tint
		color = UiPalette.apply(color)
		var tan := b.position - a.position
		var length := tan.length()
		if length <= 0.01:
			continue
		tan /= length
		# 链路本体：16px 底带 + 2px 亮芯
		draw_line(a.position, b.position, Color(color, 0.25), LINK_VISUAL_BAND_WIDTH)
		draw_line(a.position, b.position, Color(color, 0.95), 2.0)
		# 流动感：3 个沿链路缓慢移动的小菱形光点（模块 tint 着色）
		for i: int in LINK_FLOW_DOTS:
			var t := wrapf(_flow + float(i) / float(LINK_FLOW_DOTS), 0.0, 1.0)
			_draw_flow_dot(a.position.lerp(b.position, t), tan, color)


## 链路流动光点：沿链路切线方向的小菱形 + 白芯。
func _draw_flow_dot(p: Vector2, tan: Vector2, color: Color) -> void:
	var fore := tan * 2.8
	var side := tan.orthogonal() * 1.6
	draw_colored_polygon(PackedVector2Array([p + fore, p + side, p - fore, p - side]),
		Color(color, 0.85))
	draw_circle(p, 0.9, Color(COLOR_FLOW_CORE, 0.9))
