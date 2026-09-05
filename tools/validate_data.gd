extends SceneTree
## M0 数据校验器（PRD §19 校验规则 + §5.4 路径/建造点互斥）。
## 运行：godot --headless --path . -s tools/validate_data.gd
## 退出码：0 = 全部通过；1 = 存在校验错误。

const MIN_NODE_ROUTE_DISTANCE := 24.0 # BuildNode 到任意路线的最小距离（像素）
const MAP_SIZE := Vector2(640, 360)

var _errors: Array[String] = []
var _checked: int = 0
var _ids: Dictionary = {} # StringName -> 来源文件（全局重复 ID 检测）
var _tower_ids: Dictionary = {}
var _enemy_ids: Dictionary = {}
var _skill_ids: Dictionary = {}
var _hero_ids: Dictionary = {}
var _phase_event_ids: Dictionary = {}
var _module_ids: Dictionary = {}
var _device_ids: Dictionary = {}

## M2 模块效果操作合法值（scripts/data/module_data.gd 注释为契约）
const KNOWN_EFFECT_OPS: Array[String] = [
	"pierce_bonus", "armor_shred", "fire_rate_mult",
	"splash_radius_mult", "focus_damage_mult", "kill_becon",
	"link_slow", "link_silence", "link_chain",
	"barrier", "repair", "forge_wall",
]
## M2 策略目标判定合法值（scripts/boot/main.gd 结算判定为契约）
const KNOWN_STRATEGY_OPS: Array[String] = ["", "upgrade_any_tower", "use_tide_clock", "repair_device"]


func _initialize() -> void:
	print("[M1-VALIDATE] start")
	var towers := _load_dir("res://data/towers/", "TowerData")
	var enemies := _load_dir("res://data/enemies/", "EnemyData")
	var skills := _load_dir("res://data/skills/", "SkillData")
	var heroes := _load_dir("res://data/heroes/", "HeroData")
	var waves := _load_dir("res://data/waves/", "WaveData")
	var phase_events := _load_dir("res://data/phase_events/", "PhaseEventData")
	var levels := _load_dir("res://data/levels/", "LevelData")
	var modules := _load_dir("res://data/modules/", "ModuleData")
	var devices := _load_dir("res://data/devices/", "DeviceData")

	for res: Resource in devices:
		_check_device(res as DeviceData)
	for res: Resource in skills:
		_check_skill(res as SkillData)
	for res: Resource in heroes:
		_check_hero(res as HeroData)
	# 塔与模块互相引用（塔挂模块、模块指回塔）：先预注册模块 id 再双向检查
	for res: Resource in modules:
		_module_ids[(res as ModuleData).id] = true
	for res: Resource in towers:
		_check_tower(res as TowerData)
	for res: Resource in modules:
		_check_module(res as ModuleData) # 依赖 _tower_ids，须在塔之后
	for res: Resource in enemies:
		_check_enemy(res as EnemyData)
	for res: Resource in waves:
		_check_wave(res as WaveData)
	for res: Resource in phase_events:
		_check_phase_event(res as PhaseEventData)
	for res: Resource in levels:
		_check_level(res as LevelData)

	print("[M1-VALIDATE] checked=%d errors=%d" % [_checked, _errors.size()])
	if _errors.is_empty():
		print("[M1-VALIDATE] PASS")
		quit(0)
	else:
		for error: String in _errors:
			printerr("[M1-VALIDATE] FAIL: %s" % error)
		quit(1)


func _check_module(module: ModuleData) -> void:
	_module_ids[module.id] = true
	var where := "module %s" % module.id
	if not String(module.effect_op) in KNOWN_EFFECT_OPS:
		_error("%s: effect_op 非法（%s，合法值见 ModuleData 注释）" % [where, module.effect_op])
	if module.effect_value < 0.0:
		_error("%s: effect_value 不能为负（%.2f）" % [where, module.effect_value])
	if String(module.tower_id).is_empty():
		_error("%s: tower_id 为空" % where)
	elif not _tower_ids.has(module.tower_id):
		_error("%s: 引用了不存在的塔 id '%s'" % [where, module.tower_id])


func _check_device(device: DeviceData) -> void:
	_device_ids[device.id] = true
	var where := "device %s" % device.id
	if device.radius_px <= 0.0:
		_error("%s: radius_px 必须 > 0" % where)
	if device.interval_seconds <= 0.0:
		_error("%s: interval_seconds 必须 > 0" % where)
	if device.effect_value < 0.0:
		_error("%s: effect_value 不能为负" % where)
	if not String(device.active_phase) in ["mingchao", "muchao", "both"]:
		_error("%s: active_phase 非法（%s）" % [where, device.active_phase])
	if device.repairable and device.repair_seconds <= 0.0:
		_error("%s: repair_seconds 必须 > 0" % where)
	var pos: Vector2 = device.position
	if pos.x < 0.0 or pos.x > MAP_SIZE.x or pos.y < 0.0 or pos.y > MAP_SIZE.y:
		_error("%s: position 在地图外 %s" % [where, pos])


func _check_skill(skill: SkillData) -> void:
	_skill_ids[skill.id] = true
	var where := "skill %s" % skill.id
	if skill.cooldown_seconds <= 0.0:
		_error("%s: cooldown_seconds 必须 > 0（%.1f）" % [where, skill.cooldown_seconds])
	if skill.becon_cost < 0:
		_error("%s: becon_cost 不能为负（%d）" % [where, skill.becon_cost])
	if not String(skill.effect) in ["dash", "mark", "route_sweep", "barrier", "repair", "forge_wall"]:
		_error("%s: effect 非法（%s）" % [where, skill.effect])
	if skill.damage < 0.0:
		_error("%s: damage 不能为负" % where)


func _check_hero(hero: HeroData) -> void:
	_hero_ids[hero.id] = true
	var where := "hero %s" % hero.id
	if hero.max_hp <= 0.0 or hero.move_speed <= 0.0:
		_error("%s: max_hp / move_speed 必须 > 0" % where)
	if hero.attack_range <= 0.0 or hero.attack_period <= 0.0 or hero.damage < 0.0:
		_error("%s: 攻击参数非法" % where)
	for skill: SkillData in [hero.skill_a, hero.skill_b, hero.ultimate]:
		if skill == null:
			_error("%s: 技能引用缺失（skill_a/skill_b/ultimate 必须齐全）" % where)
			continue
		if not _skill_ids.has(skill.id):
			_error("%s: 引用了不存在的技能 id '%s'" % [where, skill.id])
	if hero.ultimate != null and hero.ultimate.becon_cost <= 0:
		_error("%s: 终极技必须消耗航标充能（PRD §7.1）" % where)


func _check_phase_event(event: PhaseEventData) -> void:
	_phase_event_ids[event.id] = true
	var where := "phase_event %s" % event.id
	if event.starts_at_wave < 2:
		_error("%s: starts_at_wave 必须 >= 2（%d）" % [where, event.starts_at_wave])
	if event.from_phase == event.to_phase:
		_error("%s: from_phase 与 to_phase 相同" % where)
	if event.warning_seconds < 20.0:
		_error("%s: warning_seconds 必须 >= 20（PRD §4.1，当前 %.1f）" % [where, event.warning_seconds])
	if event.becon_cost < 0:
		_error("%s: becon_cost 不能为负（%d）" % [where, event.becon_cost])


func _load_dir(dir_path: String, expected_class: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		_error("目录不存在: %s" % dir_path)
		return result
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var path := dir_path.path_join(file_name)
		var res := ResourceLoader.load(path)
		if res == null:
			_error("资源加载失败: %s" % path)
			continue
		if res.get_script() == null or String(res.get_script().get_global_name()) != expected_class:
			_error("类型不符（期望 %s）: %s" % [expected_class, path])
			continue
		_register_id(res.get("id"), path)
		_check_common(res, path)
		result.append(res)
	if result.is_empty():
		_error("目录无任何有效 %s: %s" % [expected_class, dir_path])
	return result


func _register_id(id: Variant, path: String) -> void:
	_checked += 1
	if id == null or String(id).is_empty():
		_error("空 id: %s" % path)
		return
	if _ids.has(id):
		_error("重复 id '%s': %s 与 %s" % [id, _ids[id], path])
	else:
		_ids[id] = path


func _check_common(res: Resource, path: String) -> void:
	if int(res.get("schema_version")) <= 0:
		_error("schema_version 必须 > 0: %s" % path)
	var name_key_val: Variant = res.get("display_name_key")
	if name_key_val == null:
		return # 该 schema 无 display_name_key 字段（如 WaveData），跳过
	var name_key := String(name_key_val)
	if name_key.is_empty():
		_error("display_name_key 为空: %s" % path)
	elif name_key != name_key.to_upper():
		_error("display_name_key 应为大写下划线（本地化 key 规范 PRD §14.2）: %s -> %s" % [path, name_key])


func _check_tower(tower: TowerData) -> void:
	_tower_ids[tower.id] = true
	var where := "tower %s" % tower.id
	if tower.base_cost <= 0:
		_error("%s: base_cost 必须 > 0（%d）" % [where, tower.base_cost])
	if tower.range_px < 32.0 or tower.range_px > 320.0:
		_error("%s: range_px 越界 32–320（%.1f）" % [where, tower.range_px])
	if tower.attack_period < 0.08 or tower.attack_period > 10.0:
		_error("%s: attack_period 越界 0.08–10（%.2f）" % [where, tower.attack_period])
	if tower.damage_min < 0.0 or tower.damage_max < tower.damage_min:
		_error("%s: damage 需满足 0 <= min <= max（%.1f/%.1f）" % [where, tower.damage_min, tower.damage_max])
	if not String(tower.damage_type) in ["physical", "glow", "true"]:
		_error("%s: damage_type 非法（%s，仅 physical/glow/true）" % [where, tower.damage_type])
	if tower.projectile_speed <= 0.0 and not tower.pair_link:
		_error("%s: projectile_speed 必须 > 0" % where)
	# M2：穿透与等级结构（PRD §6.1）
	if tower.pierce < 1:
		_error("%s: pierce 必须 >= 1（%d）" % [where, tower.pierce])
	if tower.pair_link and tower.link_max_range <= 0.0:
		_error("%s: pair_link 塔的 link_max_range 必须 > 0" % where)
	if tower.tiers.size() != 3:
		_error("%s: tiers 必须恰好 3 个（II–IV，PRD §6.1，当前 %d）" % [where, tower.tiers.size()])
	var prev_cost := 0
	for i: int in tower.tiers.size():
		var tier: Variant = tower.tiers[i]
		if not (tier is TowerTier):
			_error("%s: tiers[%d] 不是 TowerTier" % [where, i])
			continue
		if tier.tier != i + 2:
			_error("%s: tiers[%d].tier 应为 %d（实际 %d）" % [where, i, i + 2, tier.tier])
		if tier.cost_to_upgrade <= 0:
			_error("%s: tier %d cost_to_upgrade 必须 > 0" % [where, tier.tier])
		if tier.cost_to_upgrade < prev_cost:
			_error("%s: 升级成本必须递增（tier %d = %d < %d）" % [where, tier.tier, tier.cost_to_upgrade, prev_cost])
		prev_cost = tier.cost_to_upgrade
		if tier.tier == 2:
			if tier.module_choices.size() != 3:
				_error("%s: II 级必须提供 3 个校准模块候选（PRD §6.1，当前 %d）" % [where, tier.module_choices.size()])
			for module: Variant in tier.module_choices:
				if not (module is ModuleData):
					_error("%s: II 级模块候选不是 ModuleData" % where)
					continue
				if not _module_ids.has(module.id):
					_error("%s: 引用了未注册的模块 '%s'" % [where, module.id])
				elif module.tower_id != tower.id:
					_error("%s: 模块 '%s' 的 tower_id 为 '%s'，挂载不匹配" % [where, module.id, module.tower_id])
		elif not tier.module_choices.is_empty():
			_error("%s: III/IV 级不应有模块候选（PRD §6.1）" % where)


func _check_enemy(enemy: EnemyData) -> void:
	_enemy_ids[enemy.id] = true
	var where := "enemy %s" % enemy.id
	if enemy.max_hp <= 0.0:
		_error("%s: max_hp 必须 > 0（%.1f）" % [where, enemy.max_hp])
	if enemy.speed_px_per_sec <= 0.0:
		_error("%s: speed_px_per_sec 必须 > 0（%.1f）" % [where, enemy.speed_px_per_sec])
	if enemy.armor < -25.0 or enemy.armor > 150.0 or enemy.glow_resist < -25.0 or enemy.glow_resist > 150.0:
		_error("%s: 抗性越界 -25–150（armor=%.1f glow=%.1f）" % [where, enemy.armor, enemy.glow_resist])
	if enemy.leak_damage <= 0:
		_error("%s: leak_damage 必须 > 0（%d）" % [where, enemy.leak_damage])
	if enemy.kill_reward_ember < 0:
		_error("%s: kill_reward_ember 不能为负（%d）" % [where, enemy.kill_reward_ember])
	if enemy.radius_px <= 0.0:
		_error("%s: radius_px 必须 > 0" % where)
	if enemy.tags.size() > 2 and not enemy.elite:
		_error("%s: 普通敌人最多 2 个核心标签（PRD §8.1，当前 %d）" % [where, enemy.tags.size()])
	if enemy.elite and enemy.tags.size() > 3:
		_error("%s: 精英最多 3 个核心标签（PRD §8.1，当前 %d）" % [where, enemy.tags.size()])
	# M2：能力字段
	if enemy.shield_hp < 0.0:
		_error("%s: shield_hp 不能为负（%.1f）" % [where, enemy.shield_hp])
	if enemy.aura_radius < 0.0:
		_error("%s: aura_radius 不能为负" % where)
	if enemy.aura_radius > 0.0 and enemy.aura_speed_mult <= 0.0:
		_error("%s: 有光环时 aura_speed_mult 必须 > 0" % where)


func _check_wave(wave: WaveData) -> void:
	var where := "wave %s" % wave.id
	if wave.wave_index <= 0:
		_error("%s: wave_index 必须 > 0（%d）" % [where, wave.wave_index])
	if wave.pre_delay_seconds < 5.0:
		_error("%s: pre_delay_seconds 必须 >= 5（%.1f）" % [where, wave.pre_delay_seconds])
	if wave.groups.is_empty():
		_error("%s: groups 为空" % where)
	if wave.completion_reward_ember < 0 or wave.completion_reward_becon < 0:
		_error("%s: 奖励不能为负" % where)
	for group: Variant in wave.groups:
		if not (group is WaveGroup):
			_error("%s: groups 元素必须是 WaveGroup" % where)
			continue
		if group.count <= 0:
			_error("%s: 组 count 必须 > 0（%d）" % [where, group.count])
		if group.interval_seconds <= 0.0:
			_error("%s: 组 interval_seconds 必须 > 0（%.2f）" % [where, group.interval_seconds])
		if group.delay_after_prev_seconds < 0.0:
			_error("%s: 组 delay 不能为负（%.2f）" % [where, group.delay_after_prev_seconds])
		if not _enemy_ids.has(group.enemy_id):
			_error("%s: 引用了不存在的敌人 id '%s'" % [where, group.enemy_id])
		elif not _enemy_enabled(group.enemy_id):
			_error("%s: 引用的敌人被禁用 '%s'" % [where, group.enemy_id])


var _enemy_enabled_cache: Dictionary = {}


func _enemy_enabled(enemy_id: StringName) -> bool:
	if not _enemy_enabled_cache.has(enemy_id):
		var res := ResourceLoader.load("res://data/enemies/%s.tres" % enemy_id) as EnemyData
		_enemy_enabled_cache[enemy_id] = res != null and res.enabled
	return _enemy_enabled_cache[enemy_id]


func _check_level(level: LevelData) -> void:
	var where := "level %s" % level.id
	if level.initial_fleet_integrity <= 0:
		_error("%s: initial_fleet_integrity 必须 > 0（%d）" % [where, level.initial_fleet_integrity])
	if level.initial_ember < 0:
		_error("%s: initial_ember 不能为负（%d）" % [where, level.initial_ember])
	if level.allowed_towers.is_empty():
		_error("%s: allowed_towers 为空" % where)
	for tower_id: Variant in level.allowed_towers:
		if not _tower_ids.has(tower_id):
			_error("%s: 引用了不存在的塔 id '%s'" % [where, tower_id])
	if level.waves.is_empty():
		_error("%s: waves 为空" % where)
	else:
		for i: int in level.waves.size():
			var wave: Variant = level.waves[i]
			if not (wave is WaveData):
				_error("%s: waves[%d] 不是 WaveData" % [where, i])
			elif wave.wave_index != i + 1:
				_error("%s: waves[%d] 的 wave_index 应为 %d（实际 %d）" % [where, i, i + 1, wave.wave_index])
	# 路线
	if level.route_ids.size() != level.route_points.size():
		_error("%s: route_ids 与 route_points 数量不一致" % where)
	if not level.route_ids.has(level.default_active_route):
		_error("%s: default_active_route '%s' 不在 route_ids 中" % [where, level.default_active_route])
	for i: int in level.route_points.size():
		var points: PackedVector2Array = level.route_points[i]
		if points.size() < 2:
			_error("%s: route '%s' 少于 2 个点" % [where, level.route_ids[i]])
			continue
		if not _on_map_edge(points[0]) or not _on_map_edge(points[points.size() - 1]):
			_error("%s: route '%s' 入口/出口必须贴地图边缘" % [where, level.route_ids[i]])
	# BuildNode：数量 8–22，且不在任何路线上（数据层互斥，PRD §5.4）
	if level.build_node_positions.size() < 8 or level.build_node_positions.size() > 22:
		_error("%s: BuildNode 数量 %d 越界 8–22" % [where, level.build_node_positions.size()])
	for node_pos: Variant in level.build_node_positions:
		for i: int in level.route_points.size():
			var dist := _point_polyline_distance(node_pos, level.route_points[i])
			if dist < MIN_NODE_ROUTE_DISTANCE:
				_error("%s: BuildNode %s 距路线 '%s' 仅 %.1fpx（<%0.f，违反路径/建造点互斥）" % [
					where, node_pos, level.route_ids[i], dist, MIN_NODE_ROUTE_DISTANCE
				])
	# 英雄与相位事件引用
	for hero_id: Variant in level.allowed_heroes:
		if not _hero_ids.has(hero_id):
			_error("%s: 引用了不存在的英雄 id '%s'" % [where, hero_id])
	if not level.allowed_heroes.is_empty():
		if level.hero_spawn.x < 0.0 or level.hero_spawn.x > MAP_SIZE.x or level.hero_spawn.y < 0.0 or level.hero_spawn.y > MAP_SIZE.y:
			_error("%s: hero_spawn 在地图外 %s" % [where, level.hero_spawn])
	for event: Variant in level.phase_events:
		if not (event is PhaseEventData):
			_error("%s: phase_events 元素必须是 PhaseEventData" % where)
			continue
		if not _phase_event_ids.has(event.id):
			_error("%s: 引用了未注册的相位事件 '%s'" % [where, event.id])
		if event.level_id != level.id:
			_error("%s: 相位事件 '%s' 的 level_id 为 '%s'，不匹配" % [where, event.id, event.level_id])
		if event.starts_at_wave > level.waves.size():
			_error("%s: 相位事件 '%s' starts_at_wave=%d 超出波次总数 %d" % [where, event.id, event.starts_at_wave, level.waves.size()])
		for route_id: Variant in event.activates_routes + event.deactivates_routes:
			if not level.route_ids.has(route_id):
				_error("%s: 相位事件 '%s' 引用了不存在的路线 '%s'" % [where, event.id, route_id])
	# 波次组的路线引用
	for wave: Variant in level.waves:
		if not (wave is WaveData):
			continue
		for group: Variant in wave.groups:
			if group is WaveGroup and String(group.route_id) != "" and not level.route_ids.has(group.route_id):
				_error("%s: %s 引用了不存在的路线 '%s'" % [where, wave.id, group.route_id])
	# M2：多路线开局 / 目标 / 装置
	for route_id: Variant in level.initial_active_routes:
		if not level.route_ids.has(route_id):
			_error("%s: initial_active_routes 引用了不存在的路线 '%s'" % [where, route_id])
	if not level.route_ids.has(level.default_active_route):
		_error("%s: default_active_route 非法" % where)
	if String(level.primary_objective_key).is_empty():
		_error("%s: primary_objective_key 为空（结算印记 1，PRD §9.2）" % where)
	if String(level.strategy_objective_key).is_empty() != String(level.strategy_objective_op).is_empty():
		_error("%s: strategy_objective_key 与 strategy_objective_op 必须同时设置" % where)
	if not String(level.strategy_objective_op) in KNOWN_STRATEGY_OPS:
		_error("%s: strategy_objective_op 非法（%s）" % [where, level.strategy_objective_op])
	if level.integrity_mark_threshold <= 0 or level.integrity_mark_threshold > level.initial_fleet_integrity:
		_error("%s: integrity_mark_threshold 越界（%d / 上限 %d）" % [where, level.integrity_mark_threshold, level.initial_fleet_integrity])
	if not String(level.boss_enemy_id).is_empty() and not _enemy_ids.has(level.boss_enemy_id):
		_error("%s: boss_enemy_id 引用了不存在的敌人 %s" % [where, level.boss_enemy_id])
	var level_device_ids: Dictionary = {}
	for device: Variant in level.devices:
		if not (device is DeviceData):
			_error("%s: devices 元素必须是 DeviceData" % where)
			continue
		if not _device_ids.has(device.id):
			_error("%s: 引用了未注册的装置 '%s'" % [where, device.id])
		level_device_ids[device.id] = true
	# 相位事件 environment_changes 的装置引用
	for event: Variant in level.phase_events:
		if not (event is PhaseEventData):
			continue
		for change: Variant in event.environment_changes:
			if not (change is Dictionary):
				_error("%s: 相位事件 '%s' 的 environment_changes 元素必须是 Dictionary" % [where, event.id])
				continue
			if String(change.get("op", "")) != "device_offline":
				_error("%s: 相位事件 '%s' 未知 environment op '%s'" % [where, event.id, change.get("op", "")])
			if not level_device_ids.has(change.get("device_id", &"")):
				_error("%s: 相位事件 '%s' 引用了本关未配置的装置 '%s'" % [where, event.id, change.get("device_id", "")])


func _on_map_edge(p: Vector2) -> bool:
	return p.x <= 0.0 or p.y <= 0.0 or p.x >= MAP_SIZE.x or p.y >= MAP_SIZE.y


func _point_polyline_distance(p: Vector2, points: PackedVector2Array) -> float:
	var best := INF
	for i: int in range(1, points.size()):
		best = minf(best, _point_segment_distance(p, points[i - 1], points[i]))
	return best


func _point_segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return (a + ab * t - p).length()


func _error(message: String) -> void:
	_errors.append(message)
