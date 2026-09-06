extends TestBase
## CampaignService：3 槽战役服务，解锁、选关、结算推进。
## 正式 API 只允许槽 1–3（PRD §15.1）；测试用真实槽 + _backup_files/_restore_files 隔离，
## after_each 可靠恢复用户存档（含不存在哨兵），不再使用 90–99 越权测试槽。

const _TEST_SLOTS: Array[int] = [1, 2, 3]

var _slot_backups: Dictionary = {}


func setup() -> void:
	pass


func teardown() -> void:
	pass


func before_each() -> void:
	_slot_backups = _slot_backup_all()
	CampaignService.reset_internal()


func after_each() -> void:
	_restore_files(_slot_backups)
	_slot_backups = {}
	CampaignService.reset_internal()


func _slot_backup_all() -> Dictionary:
	var paths: Array = []
	for s: int in _TEST_SLOTS:
		var path := SaveService.slot_path(s)
		paths.append(path)
		paths.append(path + ".bak1")
		paths.append(path + ".bak2")
	return _backup_files(paths)


func test_slot_count_is_three() -> void:
	check_eq(CampaignService.slot_count(), 3, "PRD §15.1: 3 手动槽")


func test_empty_slot_summary() -> void:
	CampaignService.delete_slot(2)
	var meta := CampaignService.slot_meta(2)
	check_eq(bool(meta.get("exists", false)), false, "空槽 exists=false")
	check_eq(String(meta.get("profile_id", "x")), "", "空槽 profile_id 为空")
	check_eq(int(meta.get("unlocked_count", -1)), 0, "空槽解锁数 0")


func test_has_save_false_after_delete_shell() -> void:
	# 审查修复：delete_slot 写出空壳 {} 后 has_save 必须为 false（Title 继续按钮判定依据）
	CampaignService.new_game(1, "p1")
	check(CampaignService.has_save(1), "有档时 has_save=true")
	CampaignService.delete_slot(1)
	check(not CampaignService.has_save(1), "空壳档 has_save=false")


func test_new_game_writes_profile_and_first_unlock() -> void:
	CampaignService.new_game(1, "  Tester  ")
	var meta := CampaignService.slot_meta(1)
	check(bool(meta.get("exists", false)), "new_game 后槽占用")
	check_eq(String(meta.get("profile_id", "")), "Tester", "profile_id 已 strip + 写入")
	check_eq(int(meta.get("unlocked_count", 0)), 1, "首关解锁")
	var c := CampaignService.current_campaign()
	check_eq(String(c.get("profile_id", "")), "Tester", "current_campaign 一致")


func test_new_game_truncates_long_profile() -> void:
	var long_name := "X".repeat(60)
	CampaignService.new_game(2, long_name)
	var meta := CampaignService.slot_meta(2)
	var pid: String = String(meta.get("profile_id", ""))
	check(pid.length() <= 24, "profile_id 截断到 24 字符")


func test_continue_game_loads_existing() -> void:
	CampaignService.new_game(3, "p1")
	CampaignService.reset_internal()
	check(CampaignService.continue_game(3), "continue 返回 true")
	check_eq(int(CampaignService.current_slot), 3, "current_slot 切到 3")


func test_continue_empty_slot_returns_false() -> void:
	CampaignService.delete_slot(1)
	CampaignService.reset_internal()
	check(not CampaignService.continue_game(1), "空槽 continue 返回 false")


func test_slots_out_of_range_rejected() -> void:
	# 审查修复：正式 API 只允许 1–3
	# 先清理历史测试运行遗留的 slot_90 污染文件（旧版测试曾用 90–99 越权槽）
	for p: String in [SaveService.slot_path(90), SaveService.slot_path(90) + ".bak1", SaveService.slot_path(90) + ".bak2"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	CampaignService.new_game(90, "p1")
	check(not CampaignService.has_save(90), "new_game(90) 被拒绝未写档")
	check(not CampaignService.continue_game(90), "continue_game(90) 返回 false")
	CampaignService.delete_slot(90)
	check(not FileAccess.file_exists(SaveService.slot_path(90)), "delete_slot(90) 无文件副作用")


func test_slots_summary_returns_three() -> void:
	var s := CampaignService.slots_summary()
	check_eq(s.size(), 3, "slots_summary 返回 3 项")
	CampaignService.new_game(1, "p1")
	s = CampaignService.slots_summary()
	check_eq(bool(s[0].get("exists", false)), true, "槽 1 已占用")


func test_is_unlocked_after_new_game() -> void:
	CampaignService.new_game(1, "p1")
	var first := ContentCatalog.first_level_id()
	check(CampaignService.is_unlocked(first), "首关已解锁")
	var second := ContentCatalog.next_level_id(first)
	check(not CampaignService.is_unlocked(second), "第二关未解锁")


func _make_result(won: bool, integrity: int, kills: int, leaks: int, marks: int, sim_seconds: float) -> Dictionary:
	return {
		"won": won,
		"integrity": integrity,
		"kills": kills,
		"leaks": leaks,
		"mark_count": marks,
		"sim_seconds": sim_seconds,
	}


func test_record_battle_result_unlocks_next() -> void:
	CampaignService.new_game(1, "p1")
	var first := ContentCatalog.first_level_id()
	var next := ContentCatalog.next_level_id(first)
	CampaignService.record_battle_result(first, _make_result(true, 18, 80, 0, 3, 120.0))
	check(CampaignService.is_unlocked(next), "通关后下一关解锁")
	var entry: Dictionary = CampaignService.level_result(first)
	check_eq(int(entry.get("marks", -1)), 3, "印记数")
	check_eq(int(entry.get("best_integrity", -1)), 18, "best_integrity")


func test_record_battle_result_lose_does_not_unlock() -> void:
	CampaignService.new_game(2, "p1")
	var first := ContentCatalog.first_level_id()
	var next := ContentCatalog.next_level_id(first)
	CampaignService.record_battle_result(first, _make_result(false, 0, 30, 10, 0, 60.0))
	check(not CampaignService.is_unlocked(next), "失败不解锁下一关")


func test_next_unplayed_level_returns_first_pending() -> void:
	CampaignService.new_game(3, "p1")
	var first := ContentCatalog.first_level_id()
	check_eq(CampaignService.next_unplayed_level(), first, "新档未玩返回首关")
	CampaignService.record_battle_result(first, _make_result(true, 18, 80, 0, 3, 100.0))
	var next := ContentCatalog.next_level_id(first)
	if next != &"":
		check_eq(CampaignService.next_unplayed_level(), next, "首关通关后返回下一关")


func test_record_battle_result_keeps_max_marks() -> void:
	CampaignService.new_game(1, "p1")
	var first := ContentCatalog.first_level_id()
	CampaignService.record_battle_result(first, _make_result(true, 18, 80, 0, 3, 100.0))
	# 再通关但印记更低，不应回退
	CampaignService.record_battle_result(first, _make_result(true, 12, 60, 4, 1, 100.0))
	var entry: Dictionary = CampaignService.level_result(first)
	check_eq(int(entry.get("marks", -1)), 3, "印记保持历史最高")


func test_current_hero_id_round_trip() -> void:
	CampaignService.new_game(1, "p1")
	check_eq(CampaignService.current_hero_id(), &"", "初始无英雄")
	CampaignService.set_current_hero(&"hero_lanzhou_wei")
	check_eq(CampaignService.current_hero_id(), &"hero_lanzhou_wei", "英雄选择持久化")
	# 重新加载
	CampaignService.reset_internal()
	CampaignService.continue_game(1)
	check_eq(CampaignService.current_hero_id(), &"hero_lanzhou_wei", "英雄选择跨加载保持")


func test_set_current_slot_out_of_range() -> void:
	var out := CampaignService.set_current_slot(99)
	check(out.is_empty(), "越界槽返回空字典")
	check_eq(int(CampaignService.current_slot), 1, "current_slot 不变")


func test_delete_slot_clears_existing() -> void:
	CampaignService.new_game(1, "p1")
	CampaignService.delete_slot(1)
	var meta := CampaignService.slot_meta(1)
	check_eq(bool(meta.get("exists", false)), false, "删除后 exists=false")


func test_campaign_changed_signal_fires_on_new_game() -> void:
	var fired := [false]
	CampaignService.campaign_changed.connect(func() -> void: fired[0] = true)
	CampaignService.new_game(1, "p1")
	check(fired[0], "campaign_changed 信号触发")


func test_campaign_changed_exactly_once_per_op() -> void:
	# 红队 S2：每种持久化操作恰好一次 campaign_changed（修复 new_game 双发）
	var count := [0]
	CampaignService.campaign_changed.connect(func() -> void: count[0] += 1)
	CampaignService.new_game(1, "p1")
	check_eq(count[0], 1, "new_game 恰好一次")
	CampaignService.record_battle_result(&"level_c01", _make_result(true, 18, 80, 0, 3, 100.0))
	check_eq(count[0], 2, "record_battle_result 恰好一次")
	CampaignService.set_current_hero(&"hero_lanzhou_wei")
	check_eq(count[0], 3, "set_current_hero 恰好一次")
	CampaignService.reset_internal()
	CampaignService.continue_game(1)
	check_eq(count[0], 4, "continue_game 恰好一次")
	CampaignService.delete_slot(1)
	check_eq(count[0], 5, "delete_slot 恰好一次")


func test_corrupt_structure_falls_back_to_backup() -> void:
	# 红队 S2：合法 JSON 但结构非法（非法关卡 id）→ read 回退 bak1
	CampaignService.new_game(1, "p1")
	CampaignService.record_battle_result(&"level_c01", _make_result(true, 18, 80, 0, 3, 100.0))
	# 此时 main = 含 c01 通关 + 解锁 c02；bak1 = new_game 状态（只解锁 c01）
	var bad := SaveService.read_campaign_slot(1)
	bad["unlocked_levels"] = ["level_c99"] # 非法 id
	var f := FileAccess.open(SaveService.slot_path(1), FileAccess.WRITE)
	f.store_string(JSON.stringify(bad)) # 直接写文件模拟磁盘损坏/手改
	f.close()
	var loaded := SaveService.read_campaign_slot(1)
	var unlocked: Array = loaded.get("unlocked_levels", [])
	check(unlocked.has("level_c01"), "回退到 bak1 有效档")
	check(not unlocked.has("level_c99"), "非法 id 载荷被拒绝")
	check(not unlocked.has("level_c02"), "bak1 为 new_game 状态（未含 c02）")


func test_validator_rejects_bad_types() -> void:
	# 结构校验单元断言：类型错误的载荷直接判负
	check(not CampaignService._validate_campaign_payload({}), "空载荷拒绝")
	check(not CampaignService._validate_campaign_payload({"schema_version": 1, "unlocked_levels": []}), "空解锁拒绝")
	check(not CampaignService._validate_campaign_payload(
		{"schema_version": 1, "unlocked_levels": ["level_c01"], "level_results": {"level_c01": "broken"}}),
		"level_results 子项非 Dictionary 拒绝")
	check(not CampaignService._validate_campaign_payload(
		{"schema_version": 1, "unlocked_levels": ["level_c01"], "level_results": {"level_c01": {"marks": "three"}}}),
		"印记非数值拒绝")
	check(not CampaignService._validate_campaign_payload(
		{"schema_version": 1, "unlocked_levels": ["level_c01"], "current_hero_id": "hero_not_exist"}),
		"非法英雄 id 拒绝")
	check(CampaignService._validate_campaign_payload(
		{"schema_version": 1, "unlocked_levels": ["level_c01"], "level_results": {}, "profile_id": "p"}),
		"合法载荷通过")


func test_persist_failure_rolls_back_and_reports() -> void:
	# 红队 S2 原子语义：写盘失败 → 内存回滚、不发 campaign_changed、last_error 记录
	CampaignService.new_game(1, "p1")
	var path := SaveService.slot_path(1)
	# 移除主档文件并以同名目录占位，强制 tmp→main rename 失败（Windows 安全替换失败路径）
	DirAccess.remove_absolute(path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	var count := [0]
	CampaignService.campaign_changed.connect(func() -> void: count[0] += 1)
	var next := CampaignService.record_battle_result(&"level_c01", _make_result(true, 18, 80, 0, 3, 100.0))
	# 先清理目录占位，保证 after_each 备份恢复能写文件
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check_eq(next, &"", "写失败返回空 next_level_id")
	check(CampaignService.last_error != OK, "last_error 记录失败")
	check_eq(count[0], 0, "失败不发 campaign_changed")
	check(not CampaignService.is_unlocked(&"level_c02"), "失败回滚：c02 未解锁")
	check(not bool(CampaignService.level_result(&"level_c01").get("completed", false)), "失败回滚：无通关记录")
