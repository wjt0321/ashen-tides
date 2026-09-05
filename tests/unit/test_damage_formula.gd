extends TestBase
## 抗性公式（PRD §3.3）：实际伤害 = 基础 × 波动 × 100 / (100 + max(-50, 抗性))。
## 固定伤害模式下波动 = 1；照明标记为独立乘区（技能 B）。


func _make_enemy(armor: float, glow_resist: float) -> GreyboxEnemy:
	var data := EnemyData.new()
	data.max_hp = 100000.0
	data.speed_px_per_sec = 50.0
	data.armor = armor
	data.glow_resist = glow_resist
	data.radius_px = 10.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var enemy := GreyboxEnemy.new()
	enemy.setup(data, PackedVector2Array([Vector2.ZERO, Vector2(1000, 0)]), rng)
	return enemy


func test_physical_no_armor() -> void:
	SettingsService.set_value("gameplay", "fixed_damage", true)
	var enemy := _make_enemy(0.0, 0.0)
	check_approx(enemy.take_damage(100.0, &"physical"), 100.0, 0.01, "无护甲物理 = 基础值")
	enemy.free()


func test_armor_100_halves_damage() -> void:
	SettingsService.set_value("gameplay", "fixed_damage", true)
	var enemy := _make_enemy(100.0, 0.0)
	check_approx(enemy.take_damage(100.0, &"physical"), 50.0, 0.01, "护甲 100 → 系数 0.5")
	enemy.free()


func test_negative_armor_floor() -> void:
	SettingsService.set_value("gameplay", "fixed_damage", true)
	var enemy := _make_enemy(-25.0, 0.0)
	check_approx(enemy.take_damage(100.0, &"physical"), 133.33, 0.01, "负抗性 -25 → 系数 1.333")
	enemy.free()


func test_glow_uses_glow_resist() -> void:
	SettingsService.set_value("gameplay", "fixed_damage", true)
	var enemy := _make_enemy(100.0, 0.0)
	check_approx(enemy.take_damage(100.0, &"glow"), 100.0, 0.01, "辉光不受物理护甲影响")
	enemy.free()
	var enemy2 := _make_enemy(0.0, 100.0)
	check_approx(enemy2.take_damage(100.0, &"glow"), 50.0, 0.01, "辉光抗性 100 → 系数 0.5")
	enemy2.free()


func test_mark_multiplier() -> void:
	SettingsService.set_value("gameplay", "fixed_damage", true)
	var enemy := _make_enemy(0.0, 0.0)
	enemy.apply_mark(5.0, 1.25)
	check_approx(enemy.take_damage(100.0, &"physical"), 125.0, 0.01, "照明标记 → 承伤 ×1.25")
	enemy.free()
	SettingsService.set_value("gameplay", "fixed_damage", false)
