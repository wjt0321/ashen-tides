extends TestBase
## M4-D content & mechanics tests: C13–C14 数据契约 + 召唤敌/精英/Boss 2 机制。

const ROOT := "res://data/"
const M4D_LEVELS := ["level_c13", "level_c14"]
const TICK := 1.0 / 60.0


func _make_enemy(data: EnemyData) -> GreyboxEnemy:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var enemy := GreyboxEnemy.new()
	enemy.setup(data, PackedVector2Array([Vector2.ZERO, Vector2(1000, 0)]), rng)
	return enemy


func _make_summoner(interval: float = 1.0) -> GreyboxEnemy:
	var data := EnemyData.new()
	data.max_hp = 500.0
	data.speed_px_per_sec = 30.0
	data.radius_px = 14.0
	data.summon_enemy_id = &"mast_rat_swarm"
	data.summon_interval_seconds = interval
	return _make_enemy(data)


func test_m4d_chapter2_data_contract() -> void:
	for level_id in M4D_LEVELS:
		var level := load(ROOT + "levels/" + level_id + ".tres") as LevelData
		check(level != null, "level exists: " + level_id)
		if level == null:
			continue
		check_eq(level.chapter_index, 2, "chapter 2: " + level_id)
		check_eq(level.waves.size(), 12, "12 waves: " + level_id)
		check(level.phase_events.size() >= 1, "phase event: " + level_id)
		check(level.allowed_heroes.size() >= 2, "both heroes allowed: " + level_id)
	# C13：三入口 / 18 节点 / 双雾透镜视野脉冲
	var c13 := load(ROOT + "levels/level_c13.tres") as LevelData
	check_eq(c13.route_ids.size(), 3, "C13 three entrances")
	check_eq(c13.build_node_positions.size(), 18, "C13 18 build nodes")
	check_eq(c13.initial_active_routes.size(), 2, "C13 starts with two routes")
	check_eq(c13.devices.size(), 2, "C13 has two mist lenses")
	for d: Variant in c13.devices:
		check_eq(String((d as DeviceData).effect_op), "reveal_pulse", "C13 lens op")
	check_eq(String((c13.phase_events[0] as PhaseEventData).activates_routes[0]), "route_c13_c",
		"C13 phase activates third entrance")
	# C14：Boss 场 / 16 节点 / 三孢巢（供疗 + 阻挡）+ 根系改道
	var c14 := load(ROOT + "levels/level_c14.tres") as LevelData
	check_eq(c14.build_node_positions.size(), 16, "C14 16 build nodes")
	check_eq(String(c14.boss_enemy_id), "boss_marsh_crown_spore_king", "C14 boss id")
	check_eq(c14.devices.size(), 3, "C14 has three spore nests")
	for d: Variant in c14.devices:
		var device := d as DeviceData
		check(device.blocks_projectiles and device.max_hp > 0.0, "C14 nest blocks and destructible")
		check_eq(String(device.effect_op), "spore_heal", "C14 nest heals (孢巢供疗)")
	check_eq(String((c14.phase_events[0] as PhaseEventData).activates_routes[0]), "route_c14_b",
		"C14 root reroute activates second route")


func test_m4d_new_enemy_contract() -> void:
	var carrier := load(ROOT + "enemies/spore_mother_carrier.tres") as EnemyData
	check(carrier != null, "spore_mother_carrier exists")
	check_eq(String(carrier.summon_enemy_id), "mast_rat_swarm", "carrier summon target")
	check(carrier.summon_interval_seconds > 0.0, "carrier summon interval > 0")
	check(carrier.tags.has(&"summon"), "carrier tagged summon")
	var physician := load(ROOT + "enemies/marsh_mist_physician.tres") as EnemyData
	check(physician != null and physician.elite, "marsh_mist_physician elite")
	check(physician.elite_affixes.has(&"regenerating"), "physician regenerating affix")
	check(physician.heal_radius > 0.0 and physician.heal_per_sec > 0.0, "physician heal aura")
	var boss := load(ROOT + "enemies/boss_marsh_crown_spore_king.tres") as EnemyData
	check(boss != null and boss.boss, "boss exists")
	check_eq(boss.boss_phase_count, 3, "boss 3 phases")
	check_eq(boss.boss_phases.size(), 3, "boss phase table size")
	# 短暂暴露核心：至少两个相位为负 armor_bonus（爆发窗口）；禁止长时间无敌回血（shield_restore 有界）
	var exposure_windows := 0
	for ph: Variant in boss.boss_phases:
		if float((ph as Dictionary).get("armor_bonus", 0.0)) < 0.0:
			exposure_windows += 1
		check(float((ph as Dictionary).get("shield_restore", 0.0)) <= 200.0, "shield_restore bounded")
	check(exposure_windows >= 2, "boss has exposure windows (negative armor bonus)")
	# 新敌人必须在对应关卡的波次中出场
	var found := {"spore_mother_carrier": false, "marsh_mist_physician": false, "boss_marsh_crown_spore_king": false}
	for level_id in M4D_LEVELS:
		var level := load(ROOT + "levels/" + level_id + ".tres") as LevelData
		for wave: Variant in level.waves:
			for group: Variant in (wave as WaveData).groups:
				var eid := String((group as WaveGroup).enemy_id)
				if found.has(eid):
					found[eid] = true
	for eid: String in found:
		check(found[eid], "enemy appears in waves: " + eid)
	# Boss 必须在 C14 最后一波出场
	var c14 := load(ROOT + "levels/level_c14.tres") as LevelData
	var final_wave := c14.waves[11] as WaveData
	var boss_in_final := false
	for group: Variant in final_wave.groups:
		if String((group as WaveGroup).enemy_id) == "boss_marsh_crown_spore_king":
			boss_in_final = true
	check(boss_in_final, "boss appears in C14 wave 12")


func test_m4d_summon_deterministic_timer() -> void:
	var summoner := _make_summoner(1.0)
	var count := [0]
	summoner.summon_requested.connect(func(_e: GreyboxEnemy) -> void: count[0] += 1)
	for i: int in range(70): # 1.0s 间隔 + 10 tick 余量（浮点安全）
		summoner.sim_tick(TICK)
	check_eq(count[0], 1, "summon fires once per interval (tick=%d)" % count[0])
	for i: int in range(60):
		summoner.sim_tick(TICK)
	check_eq(count[0], 2, "summon fires twice after two intervals")
	summoner.free()


func test_m4d_summon_suppressed_by_silence() -> void:
	var summoner := _make_summoner(1.0)
	var count := [0]
	summoner.summon_requested.connect(func(_e: GreyboxEnemy) -> void: count[0] += 1)
	summoner.apply_silence(10.0) # 沉默抑制召唤（与支援光环同规则）
	for i: int in range(120):
		summoner.sim_tick(TICK)
	check_eq(count[0], 0, "silenced summoner never summons")
	summoner.free()


func test_m4d_spawn_progress_birth() -> void:
	# 召唤物出生里程：沿父路线从父位置稍后出生（main 处理器契约）
	var data := EnemyData.new()
	data.max_hp = 50.0
	data.speed_px_per_sec = 50.0
	data.radius_px = 8.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var child := GreyboxEnemy.new()
	child.setup(data, PackedVector2Array([Vector2.ZERO, Vector2(1000, 0)]), rng, 120.0)
	check_approx(child.progress_px(), 120.0, 0.01, "spawn progress applied")
	check_approx(child.position.x, 120.0, 0.01, "spawn position on route")
	# 默认 0 = 路线起点（既有调用零回归）
	var plain := _make_enemy(data)
	check_approx(plain.progress_px(), 0.0, 0.01, "default spawn at route start")
	child.free()
	plain.free()


func test_m4d_boss_phase_exposure_window() -> void:
	SettingsService.set_value("gameplay", "fixed_damage", true)
	var data := EnemyData.new()
	data.max_hp = 1000.0
	data.speed_px_per_sec = 16.0
	data.armor = 50.0
	data.radius_px = 22.0
	data.boss = true
	data.boss_phase_count = 3
	data.boss_phases = [
		{"threshold": 0.67, "label": "p1", "armor_bonus": -25.0, "speed_mult": 1.15, "shield_restore": 0.0},
		{"threshold": 0.34, "label": "p2", "armor_bonus": 15.0, "speed_mult": 0.9, "shield_restore": 100.0},
		{"threshold": 0.0, "label": "p3", "armor_bonus": -15.0, "speed_mult": 1.4, "shield_restore": 0.0},
	]
	var boss := _make_enemy(data)
	var phases_seen: Array[int] = []
	boss.boss_phase_changed.connect(func(_e: GreyboxEnemy, idx: int, _l: String) -> void: phases_seen.append(idx))
	# 打入相位 1（hp 670 → ratio 0.67）：暴露核心 armor 50-25=25 → 伤害高于基础抗性
	boss.take_damage(330.0 * 1.5, &"physical") # 抗性 50：实际 330
	check(phases_seen.has(1), "phase 1 entered (hp=%.0f)" % boss.hp)
	var base_coef := 100.0 / 150.0 # armor 50
	var exposed_coef := 100.0 / 125.0 # armor 50 - 25
	var dmg := boss.take_damage(100.0, &"physical")
	check_approx(dmg, 100.0 * exposed_coef, 0.5, "exposure window: bonus damage (%.1f vs base %.1f)" % [dmg, 100.0 * base_coef])
	# 打入相位 2：护盾回复 + 护甲加成
	boss.take_damage(400.0 * 1.25, &"physical")
	check(phases_seen.has(2), "phase 2 entered")
	check(boss.shield > 0.0, "phase 2 shield restore applied")
	boss.free()
