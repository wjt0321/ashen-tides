extends TestBase
## 存档（PRD §15 / RESEARCH_REPORT.md §14）：原子写、备份回退、suspend save 往返。

const TEST_SLOT_PATH := "user://saves/test_slot_99.json"


func test_atomic_write_read() -> void:
	var payload := {"level_id": "level_c02", "ember": 250, "rng_state": 123456789}
	check_eq(SaveService.save_json_atomic(TEST_SLOT_PATH, payload), OK, "原子写入成功")
	var loaded := SaveService.read_json_with_backup(TEST_SLOT_PATH)
	check_eq(loaded.get("ember"), 250, "读回 ember")
	check_eq(loaded.get("rng_state"), 123456789, "读回 rng_state")
	check_eq(loaded.get("schema_version"), SaveService.SCHEMA_VERSION, "自动写入 schema_version")


func test_backup_fallback() -> void:
	SaveService.save_json_atomic(TEST_SLOT_PATH, {"version_tag": "v1"})
	SaveService.save_json_atomic(TEST_SLOT_PATH, {"version_tag": "v2"}) # 生成 .bak1 = v1
	# 模拟主档损坏
	var file := FileAccess.open(TEST_SLOT_PATH, FileAccess.WRITE)
	file.store_string("{corrupted json")
	file.close()
	var loaded := SaveService.read_json_with_backup(TEST_SLOT_PATH)
	check_eq(loaded.get("version_tag"), "v1", "主档损坏时回退 .bak1")


func test_suspend_roundtrip() -> void:
	var payload := {
		"level_id": "level_c02",
		"completed_waves": 2,
		"current_phase_id": "muchao",
		"rng_state": 987654321,
		"fleet_integrity": 15,
		"ember": 120,
		"becon": 45,
		"towers": [{"tower_id": "tower_needle_rail", "node_id": "buildnode_c02_00"}],
		"hero": {"position": [320.0, 240.0], "current_hp": 300.0, "cooldowns": {"skill_grapple_shift": 3.0}},
	}
	check_eq(SaveService.write_suspend(payload), OK, "suspend 写入成功")
	check(SaveService.has_suspend(), "has_suspend=true")
	var loaded := SaveService.read_suspend()
	check_eq(loaded.get("completed_waves"), 2, "恢复 completed_waves")
	check_eq(loaded.get("current_phase_id"), "muchao", "恢复相位")
	check_eq(loaded.get("towers", []).size(), 1, "恢复塔列表")
	SaveService.clear_suspend()
	check(not SaveService.has_suspend(), "clear_suspend 生效")


func test_suspend_schema_mismatch_rejected() -> void:
	# save_json_atomic 会自动盖上当前 schema_version，这里直接写原始文件模拟旧版本存档。
	var file := FileAccess.open(SaveService.SUSPEND_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version": -1, "level_id": "x"}))
	file.close()
	check(SaveService.read_suspend().is_empty(), "schema 不匹配返回空")
	SaveService.clear_suspend()
