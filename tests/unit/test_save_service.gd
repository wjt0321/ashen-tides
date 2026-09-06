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


## 精确读取单个文件（不走备份回退），用于轮转断言。
func _read_exact(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		f.close()
		return {}
	f.close()
	return json.data if json.data is Dictionary else {}


func test_backup_rotation_three_generations() -> void:
	# 红队 S1 真实轮转：bak1→bak2、main→bak1、tmp→main
	SaveService.save_json_atomic(TEST_SLOT_PATH, {"version_tag": "v1"})
	SaveService.save_json_atomic(TEST_SLOT_PATH, {"version_tag": "v2"})
	SaveService.save_json_atomic(TEST_SLOT_PATH, {"version_tag": "v3"})
	check_eq(String(_read_exact(TEST_SLOT_PATH).get("version_tag", "")), "v3", "main = v3")
	check_eq(String(_read_exact(TEST_SLOT_PATH + ".bak1").get("version_tag", "")), "v2", "bak1 = v2")
	check_eq(String(_read_exact(TEST_SLOT_PATH + ".bak2").get("version_tag", "")), "v1", "bak2 = v1")


func test_bak2_fallback_when_main_and_bak1_corrupt() -> void:
	SaveService.save_json_atomic(TEST_SLOT_PATH, {"version_tag": "v1"})
	SaveService.save_json_atomic(TEST_SLOT_PATH, {"version_tag": "v2"})
	SaveService.save_json_atomic(TEST_SLOT_PATH, {"version_tag": "v3"})
	# 主档 + bak1 均损坏
	for p: String in [TEST_SLOT_PATH, TEST_SLOT_PATH + ".bak1"]:
		var f := FileAccess.open(p, FileAccess.WRITE)
		f.store_string("{corrupted json")
		f.close()
	var loaded := SaveService.read_json_with_backup(TEST_SLOT_PATH)
	check_eq(String(loaded.get("version_tag", "")), "v1", "main+bak1 损坏时回退 .bak2")


func test_remove_campaign_slot_clears_all_files() -> void:
	var slot := 99 # 测试专用路径族（slot_path 只是路径格式化，不受 1–3 限制）
	SaveService.write_campaign_slot(slot, {"version_tag": "v1"})
	SaveService.write_campaign_slot(slot, {"version_tag": "v2"})
	check(FileAccess.file_exists(SaveService.slot_path(slot)), "主档存在")
	check(FileAccess.file_exists(SaveService.slot_path(slot) + ".bak1"), "bak1 存在")
	check_eq(SaveService.remove_campaign_slot(slot), OK, "删除返回 OK")
	check(not FileAccess.file_exists(SaveService.slot_path(slot)), "主档已删")
	check(not FileAccess.file_exists(SaveService.slot_path(slot) + ".bak1"), "bak1 已删")
	check(not FileAccess.file_exists(SaveService.slot_path(slot) + ".bak2"), "bak2 已删")


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
