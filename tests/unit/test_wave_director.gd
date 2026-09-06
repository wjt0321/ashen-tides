extends TestBase
## WaveDirector 状态机（RESEARCH_REPORT.md §13.2）：
## BUILD → PRE_DELAY → SPAWNING → CLEARING → BUILD/WIN；生成计数、奖励与跳波/恢复接口。


func _make_wave(index: int, count: int) -> WaveData:
	var group := WaveGroup.new()
	group.enemy_id = &"dummy_enemy"
	group.count = count
	group.interval_seconds = 0.5
	var wave := WaveData.new()
	wave.id = StringName("wave_test_%d" % index)
	wave.wave_index = index
	wave.pre_delay_seconds = 5.0
	wave.groups = [group]
	wave.completion_reward_ember = 10 * index
	wave.completion_reward_becon = index
	return wave


func test_state_machine_full_run() -> void:
	var director := WaveDirector.new()
	director.setup([_make_wave(1, 3), _make_wave(2, 2)])
	# 注意：GDScript lambda 按值捕获局部变量，计数器必须用数组包裹。
	var spawns := [0]
	var pending := [0]
	var completed: Array = []
	var all_done := [false]
	director.spawn_requested.connect(func(_enemy: StringName, _route: StringName) -> void:
		spawns[0] += 1
		pending[0] += 1
	)
	director.wave_completed.connect(func(wave_index: int, _ember: int, _becon: int) -> void:
		completed.append(wave_index)
	)
	director.all_waves_completed.connect(func() -> void: all_done[0] = true)

	check_eq(director.state, WaveDirector.State.BUILD, "初始为 BUILD")
	check(director.start_wave(), "BUILD 可开波")
	check(not director.start_wave(), "非 BUILD 不可重复开波")

	var guard := 0
	while not all_done[0] and guard < 20000:
		director.tick(0.05)
		# 模拟敌人离场（击杀或到达出口）
		while pending[0] > 0 and director.state == WaveDirector.State.CLEARING:
			director.notify_enemy_removed()
			pending[0] -= 1
		# 回到 BUILD 后需要再次开波（与真实战斗流程一致）
		if director.state == WaveDirector.State.BUILD:
			director.start_wave()
		guard += 1
	check(all_done[0], "两波跑完收到 all_waves_completed")
	check_eq(spawns[0], 5, "总生成数 = 3 + 2")
	check_eq(completed, [0, 1], "wave_completed 按序发出")
	check_eq(director.state, WaveDirector.State.WIN, "终态 WIN")
	director.free() # 未入树的 Node 必须手动释放，避免退出时 ObjectDB 泄漏报告


func test_restore_progress() -> void:
	var director := WaveDirector.new()
	director.setup([_make_wave(1, 1), _make_wave(2, 1), _make_wave(3, 1)])
	director.restore_progress(2)
	check_eq(director.state, WaveDirector.State.BUILD, "恢复后回到 BUILD")
	check_eq(director.waves_started(), 2, "已完成 2 波")
	check(director.start_wave(), "恢复后可开第 3 波")
	director.free()


func test_debug_finish_wave() -> void:
	var director := WaveDirector.new()
	director.setup([_make_wave(1, 5)])
	check(not director.debug_finish_wave(), "BUILD 状态不能跳波")
	director.start_wave()
	check(director.debug_finish_wave(), "PRE_DELAY 可跳波")
	check_eq(director.state, WaveDirector.State.CLEARING, "跳波后进入清场")
	director.free()
