extends TestBase
## M4-C content & mechanics tests: C09–C12 数据契约 + 隐匿/治疗/双相/掩体机制。

const ROOT := "res://data/"
const M4C_LEVELS := ["level_c09", "level_c10", "level_c11", "level_c12"]


func _make_enemy(data: EnemyData) -> GreyboxEnemy:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var enemy := GreyboxEnemy.new()
	enemy.setup(data, PackedVector2Array([Vector2.ZERO, Vector2(1000, 0)]), rng)
	return enemy


func test_m4c_chapter2_data_contract() -> void:
	for level_id in M4C_LEVELS:
		var level := load(ROOT + "levels/" + level_id + ".tres") as LevelData
		check(level != null, "level exists: " + level_id)
		if level == null:
			continue
		check_eq(level.chapter_index, 2, "chapter 2: " + level_id)
		check(level.route_ids.size() >= 2, "multi-route: " + level_id)
		check(level.build_node_positions.size() >= 8 and level.build_node_positions.size() <= 22,
			"BuildNode range: " + level_id)
		check_eq(level.waves.size(), 12, "12 waves: " + level_id)
		check(level.phase_events.size() >= 1, "phase event: " + level_id)
		check(level.allowed_heroes.size() >= 2, "both heroes allowed: " + level_id)
	# 机制绑定：C09 侦测装置 / C10 双孢子区 / C11 双相位事件 / C12 三掩体
	var c09 := load(ROOT + "levels/level_c09.tres") as LevelData
	check_eq(c09.devices.size(), 1, "C09 has reveal lens")
	check_eq(String((c09.devices[0] as DeviceData).effect_op), "reveal_pulse", "C09 lens op")
	var c10 := load(ROOT + "levels/level_c10.tres") as LevelData
	check_eq(c10.devices.size(), 2, "C10 has two spore zones")
	var c11 := load(ROOT + "levels/level_c11.tres") as LevelData
	check_eq(c11.phase_events.size(), 2, "C11 has two phase shifts")
	check_eq(String((c11.phase_events[1] as PhaseEventData).to_phase), "mingchao", "C11 returns to mingchao")
	var c12 := load(ROOT + "levels/level_c12.tres") as LevelData
	check_eq(c12.devices.size(), 3, "C12 has three covers")
	for d: Variant in c12.devices:
		check((d as DeviceData).blocks_projectiles, "C12 cover blocks projectiles")
		check((d as DeviceData).max_hp > 0.0, "C12 cover destructible")


func test_m4c_new_enemy_contract() -> void:
	var stalker := load(ROOT + "enemies/reed_stalker.tres") as EnemyData
	check(stalker != null and stalker.stealthed, "reed_stalker stealthed")
	var mender := load(ROOT + "enemies/spore_mender.tres") as EnemyData
	check(mender != null and mender.heal_radius > 0.0 and mender.heal_per_sec > 0.0, "spore_mender heal aura")
	var shade := load(ROOT + "enemies/mirror_shade.tres") as EnemyData
	check(shade != null and shade.phase_resist_swap, "mirror_shade phase swap")
	# 新敌人必须在对应关卡的波次中出场
	var found := {"reed_stalker": false, "spore_mender": false, "mirror_shade": false}
	for level_id in M4C_LEVELS:
		var level := load(ROOT + "levels/" + level_id + ".tres") as LevelData
		for wave: Variant in level.waves:
			for group: Variant in (wave as WaveData).groups:
				var eid := String((group as WaveGroup).enemy_id)
				if found.has(eid):
					found[eid] = true
	for eid: String in found:
		check(found[eid], "enemy appears in waves: " + eid)


func test_m4c_stealth_targeting() -> void:
	SettingsService.set_value("gameplay", "fixed_damage", true)
	var data := EnemyData.new()
	data.max_hp = 100.0
	data.speed_px_per_sec = 50.0
	data.radius_px = 10.0
	data.stealthed = true
	var enemy := _make_enemy(data)
	check(not enemy.is_targetable(), "stealthed enemy not targetable")
	enemy.reveal(2.0)
	check(enemy.is_targetable(), "revealed enemy targetable")
	enemy.revealed_seconds = 0.0
	enemy.apply_mark(3.0, 1.25)
	check(enemy.is_targetable(), "marked enemy targetable (hero mark reveals)")
	enemy.free()
	var plain_data := EnemyData.new()
	plain_data.max_hp = 100.0
	plain_data.speed_px_per_sec = 50.0
	plain_data.radius_px = 10.0
	var plain := _make_enemy(plain_data)
	check(plain.is_targetable(), "non-stealth enemy always targetable")
	plain.free()


func test_m4c_phase_resist_swap() -> void:
	SettingsService.set_value("gameplay", "fixed_damage", true)
	var data := EnemyData.new()
	data.max_hp = 100000.0
	data.speed_px_per_sec = 50.0
	data.armor = 90.0
	data.glow_resist = 10.0
	data.radius_px = 10.0
	data.phase_resist_swap = true
	var enemy := _make_enemy(data)
	enemy.current_phase = &"mingchao"
	var phys_ming := enemy.take_damage(100.0, &"physical")
	var glow_ming := enemy.take_damage(100.0, &"glow")
	enemy.current_phase = &"muchao"
	var phys_mu := enemy.take_damage(100.0, &"physical")
	var glow_mu := enemy.take_damage(100.0, &"glow")
	check(phys_ming < phys_mu, "muchao swaps: physical stronger in muchao (%.1f vs %.1f)" % [phys_ming, phys_mu])
	check(glow_mu < glow_ming, "muchao swaps: glow stronger in mingchao (%.1f vs %.1f)" % [glow_mu, glow_ming])
	check_approx(phys_ming, glow_mu, 0.01, "swap is symmetric")
	enemy.free()


func test_m4c_device_new_ops() -> void:
	# reveal_pulse：揭示半径内隐匿敌
	var lens_data := DeviceData.new()
	lens_data.id = &"test_lens"
	lens_data.effect_op = &"reveal_pulse"
	lens_data.effect_value = 4.0
	lens_data.radius_px = 100.0
	var lens := GreyboxDevice.new()
	lens.setup(lens_data)
	var stalker_data := EnemyData.new()
	stalker_data.max_hp = 100.0
	stalker_data.speed_px_per_sec = 50.0
	stalker_data.radius_px = 10.0
	stalker_data.stealthed = true
	var stalker := _make_enemy(stalker_data)
	stalker.position = Vector2(50, 0)
	lens.enemies = [stalker]
	lens._pulse()
	check(stalker.revealed_seconds > 0.0, "reveal pulse reveals stealthed enemy")
	# spore_heal：治疗半径内敌军
	var spore_data := DeviceData.new()
	spore_data.id = &"test_spore"
	spore_data.effect_op = &"spore_heal"
	spore_data.effect_value = 20.0
	spore_data.radius_px = 100.0
	var spore := GreyboxDevice.new()
	spore.setup(spore_data)
	stalker.hp = 50.0
	spore.enemies = [stalker]
	spore._pulse()
	check_approx(stalker.hp, 70.0, 0.01, "spore zone heals enemy in radius")
	# cover：阻挡并承伤、归零摧毁
	var cover_data := DeviceData.new()
	cover_data.id = &"test_cover"
	cover_data.effect_op = &"cover"
	cover_data.blocks_projectiles = true
	cover_data.max_hp = 30.0
	var cover := GreyboxDevice.new()
	cover.setup(cover_data)
	cover.take_damage(20.0)
	check(not cover.destroyed, "cover survives partial damage")
	check_approx(cover.hp, 10.0, 0.01, "cover hp reduced")
	cover.take_damage(20.0)
	check(cover.destroyed, "cover destroyed at zero hp")
	# 存档往返保持掩体状态
	var state := cover.get_save_state()
	var cover2 := GreyboxDevice.new()
	cover2.setup(cover_data)
	cover2.restore_save_state(state)
	check(cover2.destroyed and cover2.hp == 0.0, "cover save/restore keeps destroyed state")
	lens.free()
	spore.free()
	cover.free()
	cover2.free()
	stalker.free()


func test_m4c_heal_aura_silence_contract() -> void:
	# 治疗光环字段契约（数值生效路径在 main._apply_support_auras，数据层校验见 validate_data.gd）
	var mender := load(ROOT + "enemies/spore_mender.tres") as EnemyData
	check(mender.tags.has(&"healer"), "spore_mender tagged healer")
	var walker := load(ROOT + "enemies/salt_shell_walker.tres") as EnemyData
	check_eq(walker.heal_radius, 0.0, "chapter-1 walker unchanged (no heal)")
	check(not walker.stealthed and not walker.phase_resist_swap, "chapter-1 walker unchanged (no stealth/swap)")
