extends Node
## SaveService：存档读写、迁移、suspend save（M0 骨架）。
## 契约：RESEARCH_REPORT.md §14 —— user://saves/、JSON + 原子写、.bak1/.bak2 轮转备份。
## 迁移规则：schema 变化必须 bump SCHEMA_VERSION 并提供 vN -> vN+1 单向迁移。

const SCHEMA_VERSION: int = 1
const SAVE_DIR: String = "user://saves/"
const SUSPEND_DIR: String = "user://suspend/"
const LOG_DIR: String = "user://logs/"


func _ready() -> void:
	for dir_path: String in [SAVE_DIR, SUSPEND_DIR, LOG_DIR]:
		DirAccess.make_dir_recursive_absolute(dir_path)
	print("[M0] SaveService ready (schema_version=%d)" % SCHEMA_VERSION)


## 原子写入：写 .tmp -> 校验 JSON 可解析 -> 旧档备份为 .bak1 -> rename 替换。
## 浮点以 "f64:<var_to_str>" 字符串编码（Godot JSON 只有 15 位有效数字，直接存 float 会丢精度，
## suspend 恢复的逐 tick 确定性依赖计时器浮点精确往返，PRD §15.2）。
func save_json_atomic(path: String, payload: Dictionary) -> Error:
	payload["schema_version"] = SCHEMA_VERSION
	var tmp_path: String = path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(_encode_floats(payload), "\t"))
	file.close()

	var check := FileAccess.open(tmp_path, FileAccess.READ)
	if check == null:
		return FileAccess.get_open_error()
	var parsed: Variant = JSON.parse_string(check.get_as_text())
	check.close()
	if parsed == null:
		DirAccess.remove_absolute(tmp_path)
		push_error("SaveService: JSON validation failed for %s" % path)
		return ERR_PARSE_ERROR

	if FileAccess.file_exists(path):
		var copy_err := DirAccess.copy_absolute(path, path + ".bak1")
		if copy_err != OK:
			push_warning("SaveService: backup failed (%d) for %s" % [copy_err, path])
	return DirAccess.rename_absolute(tmp_path, path)


## 读取：主档失败时依次回退 .bak1 / .bak2；全部失败返回空字典。
func read_json_with_backup(path: String) -> Dictionary:
	for candidate: String in [path, path + ".bak1", path + ".bak2"]:
		if not FileAccess.file_exists(candidate):
			continue
		var file := FileAccess.open(candidate, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary:
			return _decode_floats(parsed)
		push_warning("SaveService: corrupted save ignored: %s" % candidate)
	return {}


const FLOAT_MARKER: String = "f64:"


func _encode_floats(value: Variant) -> Variant:
	if value is float:
		return FLOAT_MARKER + var_to_str(value)
	if value is Dictionary:
		var out := {}
		for key: Variant in value:
			out[key] = _encode_floats(value[key])
		return out
	if value is Array:
		var out: Array = []
		for item: Variant in value:
			out.append(_encode_floats(item))
		return out
	return value


func _decode_floats(value: Variant) -> Variant:
	if value is String and value.begins_with(FLOAT_MARKER):
		return value.trim_prefix(FLOAT_MARKER).to_float()
	if value is Dictionary:
		var out := {}
		for key: Variant in value:
			out[_decode_floats(key)] = _decode_floats(value[key])
		return out
	if value is Array:
		var out: Array = []
		for item: Variant in value:
			out.append(_decode_floats(item))
		return out
	return value


# ---------------------------------------------------------------------------
# M1：主存档槽骨架 + suspend save（PRD §15）
# ---------------------------------------------------------------------------

const SUSPEND_PATH: String = SUSPEND_DIR + "suspend_save.json"


static func slot_path(slot: int) -> String:
	return "%sslot_%02d.save.json" % [SAVE_DIR, slot]


## 主存档骨架：战役进度（3 手动槽，M2 接入界面）。
func write_campaign_slot(slot: int, payload: Dictionary) -> Error:
	return save_json_atomic(slot_path(slot), payload)


func read_campaign_slot(slot: int) -> Dictionary:
	return read_json_with_backup(slot_path(slot))


## Suspend save：波次完成 / Boss 阶段 / 退出前写入（PRD §15.2）。
## payload 由战斗场景组装，必须包含 level_id / completed_waves / current_phase_id /
## rng_state / fleet_integrity / ember / becon / towers / hero。
func write_suspend(payload: Dictionary) -> Error:
	var err := save_json_atomic(SUSPEND_PATH, payload)
	if err == OK:
		EventBus.suspend_save_written.emit(StringName(payload.get("level_id", "")), int(payload.get("completed_waves", 0)))
	return err


func has_suspend() -> bool:
	return FileAccess.file_exists(SUSPEND_PATH)


## 读取并校验 schema_version；损坏或不匹配返回空字典。
func read_suspend() -> Dictionary:
	var payload := read_json_with_backup(SUSPEND_PATH)
	if payload.is_empty():
		return {}
	if int(payload.get("schema_version", -1)) != SCHEMA_VERSION:
		push_warning("SaveService: suspend schema mismatch, ignored")
		return {}
	return payload


func clear_suspend() -> void:
	for path: String in [SUSPEND_PATH, SUSPEND_PATH + ".bak1", SUSPEND_PATH + ".bak2"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
