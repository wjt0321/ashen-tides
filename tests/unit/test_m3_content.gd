extends TestBase
## M3 content contract tests: intentionally red until M3 resources/runtime schema land.

const ROOT := "res://data/"

func test_m3_tower_and_module_contract() -> void:
	var tower_ids := ["tower_needle_rail", "tower_ember_well", "tower_echo_pile", "tower_wind_nest", "tower_tide_anvil", "tower_prism_grove"]
	for tower_id in tower_ids:
		var tower := load(ROOT + "towers/" + tower_id + ".tres") as TowerData
		check(tower != null, "tower exists: " + tower_id)
		if tower == null:
			continue
		check_eq(tower.tiers.size(), 3, "tower has II-IV tiers: " + tower_id)
		check_eq((tower.tiers[0] as TowerTier).module_choices.size(), 3, "tower has 3 modules: " + tower_id)

func test_m3_second_hero_contract() -> void:
	var hero := load(ROOT + "heroes/hero_zhushou_muen.tres") as HeroData
	check(hero != null, "second hero exists")
	if hero == null:
		return
	check(hero.skill_a != null, "Muen skill A exists")
	check(hero.skill_b != null, "Muen skill B exists")
	check(hero.ultimate != null, "Muen ultimate exists")
	check_eq(String(hero.skill_a.effect), "barrier", "Muen skill A effect")
	check_eq(String(hero.skill_b.effect), "repair", "Muen skill B effect")
	check_eq(String(hero.ultimate.effect), "forge_wall", "Muen ultimate effect")

func test_m3_chapter_data_contract() -> void:
	for level_id in ["level_c01", "level_c02", "level_c03", "level_c04", "level_c05", "level_c06", "level_c07", "level_c08"]:
		var level := load(ROOT + "levels/" + level_id + ".tres") as LevelData
		check(level != null, "level exists: " + level_id)
		if level == null:
			continue
		check(level.route_ids.size() >= 2, "multi-route PathNetwork: " + level_id)
		check(level.build_node_positions.size() >= 8 and level.build_node_positions.size() <= 22, "BuildNode range: " + level_id)
		check(level.waves.size() >= 6, "waves present: " + level_id)
		if level_id >= "level_c03":
			check(level.allowed_heroes.size() >= 1, "hero allowed: " + level_id)
	var boss := load(ROOT + "enemies/anchor_crab_king.tres") as EnemyData
	check(boss != null, "C08 boss exists")
	if boss != null:
		check(boss.boss, "C08 boss flag")
		check_eq(boss.boss_phase_count, 3, "C08 boss has 3 phases")

func test_m3_runtime_contract() -> void:
	var skill_script := load("res://scripts/data/skill_data.gd")
	check(skill_script != null, "skill schema loads")
	var enemy_script := load("res://scripts/data/enemy_data.gd")
	check(enemy_script != null, "enemy schema loads")
	check(FileAccess.file_exists("res://tools/m3_smoke.gd"), "M3 smoke tool exists")
	check(FileAccess.file_exists("res://tools/m3_perf.gd"), "M3 perf tool exists")
