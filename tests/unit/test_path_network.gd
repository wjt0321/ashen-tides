extends TestBase
## PathNetwork 激活/停用 + 敌人沿预制路线插值移动（RESEARCH_REPORT.md §5）。
## 敌人在路线尽头发出 reached_goal；移动只依赖路线数据，不做实时寻路。


func test_route_activation() -> void:
	var network := PathNetwork.new()
	network.add_route(&"r1", PackedVector2Array([Vector2(0, 0), Vector2(100, 0)]), true)
	network.add_route(&"r2", PackedVector2Array([Vector2(0, 0), Vector2(0, 100)]), false)
	check(network.is_route_active(&"r1"), "r1 默认激活")
	check(not network.is_route_active(&"r2"), "r2 默认未激活")
	network.deactivate_route(&"r1")
	network.activate_route(&"r2")
	check(not network.is_route_active(&"r1"), "r1 已停用")
	check(network.is_route_active(&"r2"), "r2 已激活")
	network.free()


func test_enemy_traversal_and_goal() -> void:
	var data := EnemyData.new()
	data.max_hp = 100.0
	data.speed_px_per_sec = 50.0
	data.radius_px = 10.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var enemy := GreyboxEnemy.new()
	enemy.setup(data, PackedVector2Array([Vector2(0, 0), Vector2(100, 0)]), rng)
	var reached := [false]
	enemy.reached_goal.connect(func(_e: GreyboxEnemy) -> void: reached[0] = true)
	enemy.sim_tick(1.0)
	check_approx(enemy.position.x, 50.0, 0.01, "1 秒走 50px")
	enemy.sim_tick(1.0)
	check(reached[0], "走完全程触发 reached_goal")
	enemy.free()


func test_enemy_death_signal() -> void:
	SettingsService.set_value("gameplay", "fixed_damage", true)
	var data := EnemyData.new()
	data.max_hp = 50.0
	data.speed_px_per_sec = 50.0
	data.radius_px = 10.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var enemy := GreyboxEnemy.new()
	enemy.setup(data, PackedVector2Array([Vector2(0, 0), Vector2(100, 0)]), rng)
	var dead := [false]
	enemy.died.connect(func(_e: GreyboxEnemy) -> void: dead[0] = true)
	enemy.take_damage(60.0, &"physical")
	check(dead[0], "生命归零触发 died")
	check(not enemy.is_alive(), "死亡后 is_alive=false")
	enemy.free()
	SettingsService.set_value("gameplay", "fixed_damage", false)
