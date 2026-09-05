class_name GreyboxProjectile
extends Node2D
## 灰盒投射物（M2）：追踪单体 / 溅射 / 直线穿透（针轨弩台）三种弹道。
## 由战斗场景以固定 tick 驱动 sim_tick；由对象池复用，TTL 5 秒（RESEARCH_REPORT.md §8.3）。
## 直线穿透：pierce > 1 时沿发射方向直线飞行， corridor 内命中最多 pierce 个敌人。
## 命中携带 source_tower 引用（回火模块击杀返能、削甲、击杀统计）。

signal resolved(projectile: GreyboxProjectile) # 命中或过期，归还对象池

const COLOR := Color(1.0, 0.72, 0.30)
const COLOR_PIERCE := Color(0.60, 0.82, 1.0)
const COLOR_STEEL := Color(0.78, 0.90, 1.0) ## 钢针尾迹渐隐色
const COLOR_EMBER_OUT := Color(0.95, 0.45, 0.16) ## 火球外焰橙
const COLOR_EMBER_IN := Color(1.0, 0.82, 0.35) ## 火球内焰黄
const COLOR_GLOW := Color(0.82, 0.72, 1.0) ## 辉光菱形（紫白）
const COLOR_GLOW_CORE := Color(1.0, 0.97, 1.0) ## 辉光菱形亮芯
const HIT_CORRIDOR := 8.0 ## 穿透弹道判定半宽
const PIERCE_MAX_RANGE_BONUS := 64.0 ## 穿透弹道超出射程的延伸

var damage: float = 0.0
var damage_type: StringName = &"physical"
var speed: float = 320.0
var splash_radius: float = 0.0
var pierce: int = 1
var armor_shred: float = 0.0
var source_tower: GreyboxTower = null
var enemies: Array = [] ## 溅射/穿透判定用，由战斗场景注入（数组按引用共享）
var blockers: Array = [] ## 可破坏掩体（C12）：阻挡投射物，由战斗场景注入（_devices 引用共享）

var _target: GreyboxEnemy
var _last_target_pos: Vector2
var _ttl: float = 5.0
var _resolved_damage: float = 0.0 # 本次飞行造成的实际伤害（统计用）
var _fly_dir: Vector2 = Vector2.RIGHT
var _max_fly: float = 0.0 ## 穿透模式最大飞行距离
var _flown: float = 0.0
var _hit_set: Array = [] ## 穿透模式已命中敌人


func setup(from: Vector2, target: GreyboxEnemy, p_damage: float, p_type: StringName, p_speed: float,
		p_splash: float = 0.0, p_pierce: int = 1, p_shred: float = 0.0, p_source: GreyboxTower = null,
		p_range: float = 320.0) -> void:
	position = from
	_target = target
	_last_target_pos = target.position
	damage = p_damage
	damage_type = p_type
	speed = p_speed
	splash_radius = p_splash
	pierce = p_pierce
	armor_shred = p_shred
	source_tower = p_source
	_ttl = 5.0
	_resolved_damage = 0.0
	_hit_set.clear()
	_flown = 0.0
	visible = true
	if pierce > 1:
		var dir := (_last_target_pos - from)
		_fly_dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
		_max_fly = p_range + PIERCE_MAX_RANGE_BONUS
	queue_redraw() # 对象池复用时刷新旧弹体缓存内容


func resolved_damage() -> float:
	return _resolved_damage


func sim_tick(delta: float) -> void:
	## 由战斗场景以固定 tick 驱动（PRD §18.5）
	_ttl -= delta
	if _ttl <= 0.0:
		resolved.emit(self)
		return
	if pierce > 1:
		_sim_tick_pierce(delta)
		return
	if is_instance_valid(_target) and _target.is_alive():
		_last_target_pos = _target.position
	if _check_blockers():
		return
	var step: float = speed * delta
	if position.distance_to(_last_target_pos) <= step + 4.0:
		_impact()
		resolved.emit(self)
		return
	position = position.move_toward(_last_target_pos, step)
	if _check_blockers():
		return
	queue_redraw() # 追踪弹体视觉尾迹随转弯刷新（sim tick 驱动）


## 掩体阻挡（C12 沉船温室）：投射物进入存活掩体半径即被吸收并削减掩体耐久。
func _check_blockers() -> bool:
	for blocker: Variant in blockers:
		if not (blocker is GreyboxDevice) or blocker.destroyed or not blocker.data.blocks_projectiles:
			continue
		if position.distance_to(blocker.position) <= blocker.data.radius_px:
			blocker.take_damage(damage)
			resolved.emit(self)
			return true
	return false


## 直线穿透弹道：固定方向飞行，命中 corridor 内未命中过的敌人。
func _sim_tick_pierce(delta: float) -> void:
	var step: float = speed * delta
	position += _fly_dir * step
	_flown += step
	if _check_blockers():
		return
	for enemy: Variant in enemies:
		if not (enemy is GreyboxEnemy) or not enemy.is_targetable() or _hit_set.has(enemy):
			continue
		if position.distance_to(enemy.position) <= HIT_CORRIDOR + enemy.data.radius_px:
			_hit_set.append(enemy)
			_hit(enemy)
			if _hit_set.size() >= pierce:
				resolved.emit(self)
				return
	if _flown >= _max_fly:
		resolved.emit(self)


func _hit(enemy: GreyboxEnemy) -> void:
	if armor_shred > 0.0:
		enemy.apply_armor_shred(armor_shred, 4.0)
	_resolved_damage += enemy.take_damage(damage, damage_type)
	if not enemy.is_alive() and source_tower != null and is_instance_valid(source_tower):
		source_tower.total_kills += 1
		var refund := source_tower.eff_kill_becon()
		if refund > 0:
			EventBus.becon_kill_refund.emit(refund, source_tower.data.id)


func _impact() -> void:
	if splash_radius > 0.0:
		for enemy: Variant in enemies.duplicate():
			if enemy is GreyboxEnemy and enemy.is_targetable(): # 溅射不波及未揭示隐匿敌（C09）
				if enemy.position.distance_to(_last_target_pos) <= splash_radius:
					_hit(enemy)
	elif is_instance_valid(_target) and _target.is_targetable():
		_hit(_target)


func _draw() -> void:
	# 弹体视觉按 damage_type + 弹道特征分类（damage_type 合法值见 PRD §3.2）：
	#  - glow + 穿透（棱晶丛辉光）：紫白小菱形 —— glow/link 类
	#  - glow 单发（余烬喷井溅射）：橙红火球 —— splash/ember 类
	#  - 其他 + 穿透（针轨弩台直线穿透）：细长钢针 —— needle/pierce 类
	#  - 其余（风巢/潮汐砧单体）：默认圆点回退
	if pierce > 1:
		if damage_type == &"glow":
			_draw_glow_diamond(_fly_dir)
		else:
			_draw_steel_needle()
		return
	if damage_type == &"glow":
		_draw_fireball(_aim_dir())
		return
	if damage_type == &"physical":
		draw_circle(Vector2.ZERO, 3.0, COLOR_STEEL) # 物理单体默认浅钢白
	else:
		draw_circle(Vector2.ZERO, 3.0, COLOR) # 原回退圆点


## 追踪弹朝向（火球尾焰反方向）。
func _aim_dir() -> Vector2:
	return (_last_target_pos - position).normalized()


## 针轨钢针：保留原线形，加尾迹两点渐隐（越靠后越小越淡）。
func _draw_steel_needle() -> void:
	draw_line(-_fly_dir * 5.0, _fly_dir * 5.0, COLOR_PIERCE, 2.0)
	draw_circle(-_fly_dir * 7.0, 1.5, Color(COLOR_STEEL, 0.35))
	draw_circle(-_fly_dir * 11.0, 1.0, Color(COLOR_STEEL, 0.15))


## 余烬火球：外橙内黄双圆 + 1px 尾焰。
func _draw_fireball(dir: Vector2) -> void:
	draw_circle(Vector2.ZERO, 3.4, COLOR_EMBER_OUT)
	draw_circle(Vector2.ZERO, 2.0, COLOR_EMBER_IN)
	draw_circle(Vector2.ZERO, 0.9, Color(1.0, 0.97, 0.85))
	draw_line(Vector2.ZERO, -dir * 6.0, Color(COLOR_EMBER_OUT, 0.5), 1.0)


## 辉光小菱形：沿飞行方向的紫白菱形 + 亮芯。
func _draw_glow_diamond(dir: Vector2) -> void:
	var fore := dir * 3.0
	var side := dir.orthogonal() * 1.8
	draw_colored_polygon(PackedVector2Array([fore, side, -fore, -side]), Color(COLOR_GLOW, 0.90))
	draw_circle(Vector2.ZERO, 1.1, COLOR_GLOW_CORE)
