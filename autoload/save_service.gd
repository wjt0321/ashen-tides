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


## 静默 JSON 解析：JSON.parse_string 静态方法对损坏数据会向引擎日志打 ERROR（污染验收日志）；
## 实例 parse() 只返回错误码，由调用方决定告警级别（损坏备份回退属预期路径，用 warning 即可）。
static func _parse_json_silent(text: String) -> Variant:
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data


## 原子写入：写 .tmp -> 校验 JSON 可解析 -> 备份轮转（bak1→bak2、main→bak1）-> tmp→main。
## 浮点以 "f64:<var_to_str>" 字符串编码（Godot JSON 只有 15 位有效数字，直接存 float 会丢精度，
## suspend 恢复的逐 tick 确定性依赖计时器浮点精确往返，PRD §15.2）。
## 红队 S1 真实轮转：每步检查 Error；Windows 上 rename 目标已存在会失败，轮转前先清目标。
## tmp→main 失败时尝试从 bak1 回滚主档；任何失败返回 Error 且尽量保留主档可读。
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
	var parsed: Variant = _parse_json_silent(check.get_as_text())
	check.close()
	if parsed == null:
		DirAccess.remove_absolute(tmp_path)
		push_error("SaveService: JSON validation failed for %s" % path)
		return ERR_PARSE_ERROR

	var bak1 := path + ".bak1"
	var bak2 := path + ".bak2"
	# 轮转 1：bak1 → bak2
	if FileAccess.file_exists(bak1):
		if FileAccess.file_exists(bak2):
			var rm_err := DirAccess.remove_absolute(bak2)
			if rm_err != OK:
				DirAccess.remove_absolute(tmp_path)
				push_warning("SaveService: 无法清理旧 bak2 (%d)，放弃写入: %s" % [rm_err, path])
				return rm_err
		var rot_err := DirAccess.rename_absolute(bak1, bak2)
		if rot_err != OK:
			DirAccess.remove_absolute(tmp_path)
			push_warning("SaveService: bak1→bak2 轮转失败 (%d)，放弃写入: %s" % [rot_err, path])
			return rot_err
	# 轮转 2：main → bak1
	if FileAccess.file_exists(path):
		var mv_err := DirAccess.rename_absolute(path, bak1)
		if mv_err != OK:
			DirAccess.remove_absolute(tmp_path)
			push_warning("SaveService: main→bak1 轮转失败 (%d)，主档保留: %s" % [mv_err, path])
			return mv_err
	# 替换：tmp → main
	var fin_err := DirAccess.rename_absolute(tmp_path, path)
	if fin_err != OK:
		# 尽量保留主档：从 bak1 回滚
		if FileAccess.file_exists(bak1):
			var rb_err := DirAccess.rename_absolute(bak1, path)
			push_warning("SaveService: tmp→main 失败 (%d)，主档回滚 %s: %s" % [
				fin_err, "成功" if rb_err == OK else "失败(%d)" % rb_err, path,
			])
		return fin_err
	return OK


## 读取：主档失败时依次回退 .bak1 / .bak2；全部失败返回空字典。
## validator（可选，func(Dictionary) -> bool）：结构校验失败同样继续回退备份（红队 S2）。
func read_json_with_backup(path: String, validator: Callable = Callable()) -> Dictionary:
	for candidate: String in [path, path + ".bak1", path + ".bak2"]:
		if not FileAccess.file_exists(candidate):
			continue
		var file := FileAccess.open(candidate, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = _parse_json_silent(file.get_as_text())
		file.close()
		if not (parsed is Dictionary):
			push_warning("SaveService: corrupted save ignored: %s" % candidate)
			continue
		# 先解码 f64 浮点标记再校验：校验器看到的是真实数值类型，不被编码字符串误伤
		var decoded: Dictionary = _decode_floats(parsed)
		if validator.is_valid() and not bool(validator.call(decoded)):
			push_warning("SaveService: 结构校验失败，回退备份: %s" % candidate)
			continue
		return decoded
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


## 战役档结构校验器（func(Dictionary) -> bool），由 CampaignService 在 _ready 注册。
## 红队 S2：SaveService 不反向依赖 ContentCatalog；校验逻辑由数据属主注入。
var campaign_validator: Callable = Callable()


## 主存档骨架：战役进度（3 手动槽，M2 接入界面）。
func write_campaign_slot(slot: int, payload: Dictionary) -> Error:
	return save_json_atomic(slot_path(slot), payload)


## 读取战役槽：main/bak1/bak2 依次解析 + 结构校验，任一损坏回退下一级。
func read_campaign_slot(slot: int) -> Dictionary:
	return read_json_with_backup(slot_path(slot), campaign_validator)


## 删除战役槽全部文件（main/bak1/bak2）；返回 OK 或首个错误。
## 删除必须清文件而非写空壳：空壳校验失败会回退到备份档，导致「删除后复活」。
func remove_campaign_slot(slot: int) -> Error:
	var first_err := OK
	for p: String in [slot_path(slot), slot_path(slot) + ".bak1", slot_path(slot) + ".bak2"]:
		if FileAccess.file_exists(p):
			var err := DirAccess.remove_absolute(p)
			if err != OK and first_err == OK:
				first_err = err
	return first_err


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
