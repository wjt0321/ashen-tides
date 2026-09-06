extends Node
## CampaignService：战役进度领域服务（M2 Flow Shell 第一批）。
## 职责边界（OPEN_SOURCE_TD_RESEARCH §3.3：Campaign 决定解锁，不由结算面板推测）：
##   - 当前存档槽（PRD §15.1：3 个手动战役槽）、新档/继续/删除；
##   - 关卡解锁判定、本局选择（selected level / hero）；
##   - 结算结果推进：合并 level_results、按 ContentCatalog 官方顺序解锁下一关。
## 持久化只调用 SaveService（原子写/备份轮转不在此重复）；资源解析只调用 ContentCatalog。

signal campaign_changed ## 解锁/结果写入后广播，供流程 UI 刷新
signal slot_changed(slot: int)

const SLOTS: Array[int] = [1, 2, 3]
const PROFILE_ID_MAX_LEN: int = 24
const KEY_PROFILE_ID: StringName = &"profile_id"
const KEY_UNLOCKED: StringName = &"unlocked_levels"
const KEY_LEVEL_RESULTS: StringName = &"level_results"
const KEY_CURRENT_HERO: StringName = &"current_hero_id"
const KEY_LAST_LEVEL: StringName = &"last_level_id"
const KEY_LAST_PLAYED: StringName = &"last_played_at"

var current_slot: int = 1 ## CLI 直进战斗的兼容默认（历史行为 = 槽 1）
var selected_level: StringName = &""
var selected_hero: StringName = &""

var last_error: int = OK ## 最近一次持久化操作结果（OK=成功）；UI 必须据此判断成败

var _campaign: Dictionary = {} ## 当前槽内存副本（写盘前的权威）
var _loaded: bool = false
var _slot_summaries: Array = [] ## Array[Dictionary] 长度=SLOTS.size()


func _ready() -> void:
	# 红队 S2：注册战役档结构校验器（SaveService 不反向依赖 ContentCatalog，由属主注入）
	SaveService.campaign_validator = _validate_campaign_payload
	print("[M2-FLOW] CampaignService ready (slots=%d, current=%d)" % [SLOTS.size(), current_slot])
	_refresh_slot_summaries()


# ---------------------------------------------------------------------------
# 存档结构校验（红队 S2：坏结构 read 依次回退 main→bak1→bak2）
# ---------------------------------------------------------------------------

## 战役档严格结构校验：schema_version（SaveService 写入时注入）、unlocked_levels
## 为非空 Array[String] 且全是合法关卡 id、level_results 子项字段类型合理、
## profile_id / current_hero_id / last_level_id 类型与 id 合法。
func _validate_campaign_payload(data: Dictionary) -> bool:
	if int(data.get("schema_version", -1)) != SaveService.SCHEMA_VERSION:
		return false
	var unlocked: Variant = data.get("unlocked_levels")
	if not (unlocked is Array) or (unlocked as Array).is_empty():
		return false
	for raw_id: Variant in unlocked:
		if not (raw_id is String) or not ContentCatalog.is_valid_level(StringName(raw_id)):
			return false
	var results: Variant = data.get("level_results", {})
	if not (results is Dictionary):
		return false
	for key: Variant in results:
		if not (key is String) or not ContentCatalog.is_valid_level(StringName(key)):
			return false
		var entry: Variant = (results as Dictionary)[key]
		if not (entry is Dictionary):
			return false
		var e: Dictionary = entry
		if e.has("completed") and not (e["completed"] is bool):
			return false
		for num_field: String in ["integrity", "kills", "marks", "best_integrity"]:
			if e.has(num_field) and not ((e[num_field] is int) or (e[num_field] is float)):
				return false
	if data.has("profile_id") and not (data["profile_id"] is String):
		return false
	var hero: Variant = data.get(String(KEY_CURRENT_HERO), "")
	if not ((hero is String) or (hero is StringName)):
		return false
	if String(hero) != "" and ContentCatalog.hero(StringName(hero)) == null:
		return false
	var last: Variant = data.get(String(KEY_LAST_LEVEL), "")
	if not ((last is String) or (last is StringName)):
		return false
	if String(last) != "" and not ContentCatalog.is_valid_level(StringName(last)):
		return false
	return true


# ---------------------------------------------------------------------------
# 槽位
# ---------------------------------------------------------------------------

func has_save(slot: int) -> bool:
	# 审查修复：只看文件存在会把 delete_slot 写出的空壳 {} 误判为可继续档，改为有意义载荷判断。
	return FileAccess.file_exists(SaveService.slot_path(slot)) \
		and _is_meaningful(SaveService.read_campaign_slot(slot))


## 槽位数量（PRD §15.1：固定 3 个手动战役槽）。
func slot_count() -> int:
	return SLOTS.size()


## 只有 schema 壳（无 unlocked_levels）的载荷视为空档（delete_slot/测试槽清空的兜底）。
static func _is_meaningful(data: Dictionary) -> bool:
	return data.has("unlocked_levels")


func _empty_meta(slot: int) -> Dictionary:
	return {"exists": false, "slot": slot, "profile_id": "", "unlocked_count": 0,
		"completed_count": 0, "last_level_id": "", "marks_total": 0}


## 主菜单槽位行展示用元信息（PRD §15.1：时间、章节/进度、完成度）。
## 不限制 slot 范围：正式槽 1–3，测试槽 90–99 走同一实现（契约 test_campaign_service.gd）。
func slot_meta(slot: int) -> Dictionary:
	if slot < 1:
		return _empty_meta(slot)
	var data := SaveService.read_campaign_slot(slot)
	if not _is_meaningful(data):
		return _empty_meta(slot)
	var results: Dictionary = data.get("level_results", {})
	var completed := 0
	var marks := 0
	for level_id: Variant in results:
		var r: Dictionary = results[level_id]
		if bool(r.get("completed", false)):
			completed += 1
		marks += int(r.get("marks", 0))
	var unlocked: Array = data.get("unlocked_levels", [])
	return {
		"exists": true,
		"slot": slot,
		"profile_id": String(data.get("profile_id", "")),
		"updated_at_utc": String(data.get("updated_at_utc", "")),
		"completed_count": completed,
		"marks_total": marks,
		"unlocked_count": unlocked.size(),
		"highest_level": String(unlocked[unlocked.size() - 1]) if not unlocked.is_empty() else "",
		"last_level_id": String(data.get("last_level_id", "")),
	}


## 三槽摘要（首次主菜单用：空槽=新游戏；占用槽=继续/覆盖）。
func slots_summary() -> Array:
	if _slot_summaries.size() != SLOTS.size():
		_refresh_slot_summaries()
	return _slot_summaries.duplicate()


func _refresh_slot_summaries() -> void:
	_slot_summaries = []
	for s: int in SLOTS:
		_slot_summaries.append(slot_meta(s))


## 覆盖新档：已有关卡进度清空，只保留首关解锁。覆盖前的二次确认由 Flow UI 负责（PRD §12.3）。
## profile_name 为空时回退到 "default"；超长截断到 PROFILE_ID_MAX_LEN。
## 原子语义：写盘失败回滚内存（current_slot/_campaign/选择不变）、不发信号，返回 false 并置 last_error。
func new_game(slot: int, profile_name: String = "") -> bool:
	last_error = OK
	if not SLOTS.has(slot):
		# 公共 API 非法输入：安静拒绝，不 push_error 污染验收日志（PRD §15.1 正式槽 1–3）
		last_error = ERR_INVALID_PARAMETER
		return false
	var safe := profile_name.strip_edges()
	if safe.is_empty():
		safe = "default"
	if safe.length() > PROFILE_ID_MAX_LEN:
		safe = safe.substr(0, PROFILE_ID_MAX_LEN)
	var now := Time.get_datetime_string_from_system(true)
	var fresh := {
		"profile_id": safe,
		"created_at_utc": now,
		"updated_at_utc": now,
		"unlocked_levels": [String(ContentCatalog.first_level_id())],
		"level_results": {},
		String(KEY_CURRENT_HERO): "",
		"last_level_id": String(ContentCatalog.first_level_id()),
	}
	# 暂存旧状态用于失败回滚
	var prev_slot := current_slot
	var prev_campaign: Dictionary = _campaign
	var prev_loaded := _loaded
	var prev_level := selected_level
	var prev_hero := selected_hero
	current_slot = slot
	_campaign = fresh
	_loaded = true
	selected_level = &""
	selected_hero = &""
	var err := _persist()
	if err != OK:
		current_slot = prev_slot
		_campaign = prev_campaign
		_loaded = prev_loaded
		selected_level = prev_level
		selected_hero = prev_hero
		last_error = err
		push_warning("[M2-FLOW] new_game 写档失败 slot=%d err=%d（进度未保存）" % [slot, err])
		return false
	_refresh_slot_summaries()
	slot_changed.emit(slot)
	campaign_changed.emit()
	print("[M2-FLOW] new game: slot=%d profile=%s first_level=%s" % [slot, safe, ContentCatalog.first_level_id()])
	return true


## 继续旧档；槽位越界或无有效存档返回 false（正式槽 1–3，PRD §15.1）。纯读操作，无持久化。
func continue_game(slot: int) -> bool:
	last_error = OK
	if not SLOTS.has(slot):
		return false # 非法槽位：安静拒绝
	var data := SaveService.read_campaign_slot(slot)
	if not _is_meaningful(data):
		return false
	current_slot = slot
	_campaign = data
	_loaded = true
	_ensure_schema_defaults()
	_refresh_slot_summaries()
	slot_changed.emit(slot)
	campaign_changed.emit()
	print("[M2-FLOW] continue: slot=%d unlocked=%d results=%d" % [
		slot, (_campaign["unlocked_levels"] as Array).size(), (_campaign["level_results"] as Dictionary).size()
	])
	return true


## 删除槽位：移除 main/bak1/bak2 全部文件（写空壳会被结构校验回退成旧备份档，导致删除后复活）。
## Flow UI 须在调用前二次确认（PRD §12.3）。失败返回 false 并置 last_error，内存不回滚（未改动）。
func delete_slot(slot: int) -> bool:
	last_error = OK
	if not SLOTS.has(slot):
		last_error = ERR_INVALID_PARAMETER
		return false # 非法槽位：安静拒绝，无文件副作用
	var err := SaveService.remove_campaign_slot(slot)
	if err != OK:
		last_error = err
		push_warning("[M2-FLOW] delete_slot 删除失败 slot=%d err=%d" % [slot, err])
		return false
	if _loaded and current_slot == slot:
		_campaign = {}
		_loaded = false
		selected_level = &""
		selected_hero = &""
	_refresh_slot_summaries()
	campaign_changed.emit()
	print("[M2-FLOW] slot %d cleared" % slot)
	return true


## 切换当前操作槽位并把内存状态对齐（不修改存档）。
## 返回当前槽位加载后的 campaign 字典副本；无效/空槽返回空字典且 current_slot 不变。
func set_current_slot(slot: int) -> Dictionary:
	if not SLOTS.has(slot):
		return {} # 非法槽位：安静返回空且 current_slot 不变
	var data := SaveService.read_campaign_slot(slot)
	if not _is_meaningful(data):
		return {}
	current_slot = slot
	_campaign = data
	_loaded = true
	_ensure_schema_defaults()
	slot_changed.emit(slot)
	return _campaign.duplicate(true)


## 旧档/异常档缺字段时补默认值（PRD §15.4：缺失字段使用明确默认值）。
func _ensure_schema_defaults() -> void:
	if not _campaign.has("unlocked_levels") or (_campaign["unlocked_levels"] as Array).is_empty():
		_campaign["unlocked_levels"] = [String(ContentCatalog.first_level_id())]
	if not _campaign.has("level_results"):
		_campaign["level_results"] = {}
	if not _campaign.has("profile_id"):
		_campaign["profile_id"] = "default"
	if not _campaign.has(KEY_CURRENT_HERO):
		_campaign[KEY_CURRENT_HERO] = &""


## CLI/直进战斗路径（不入 Flow）：懒加载默认槽，保持历史行为。
func _ensure_loaded() -> void:
	if _loaded:
		return
	_campaign = SaveService.read_campaign_slot(current_slot)
	_loaded = true
	_ensure_schema_defaults()


## 测试 / 调试：重置 CampaignService 内存状态（不删用户存档）。在多测试之间隔离 current_slot / _campaign / selected_*。
func reset_internal() -> void:
	current_slot = 1
	_campaign = {}
	_loaded = false
	selected_level = &""
	selected_hero = &""
	_slot_summaries = []


## 当前战役内存快照（深拷贝）；未加载则空字典。
func current_campaign() -> Dictionary:
	if not _loaded:
		_ensure_loaded()
	return _campaign.duplicate(true)


## 当前战役中的出战英雄 id（持久化）。未设置返回空 StringName。
func current_hero_id() -> StringName:
	if not _loaded:
		_ensure_loaded()
	if not _campaign.has(KEY_CURRENT_HERO):
		return &""
	return _campaign.get(KEY_CURRENT_HERO, &"")


## 原子语义：写盘失败回滚英雄字段，返回 false 并置 last_error，不发信号。
func set_current_hero(hero_id: StringName) -> bool:
	last_error = OK
	_ensure_loaded()
	var prev: Variant = _campaign.get(KEY_CURRENT_HERO, &"")
	_campaign[KEY_CURRENT_HERO] = hero_id
	var err := _persist()
	if err != OK:
		_campaign[KEY_CURRENT_HERO] = prev
		last_error = err
		push_warning("[M2-FLOW] set_current_hero 写档失败 slot=%d err=%d" % [current_slot, err])
		return false
	campaign_changed.emit()
	return true


## 当前战役序列中下一关未玩关卡：按字典序找首个未 completed 的 unlocked。
func next_unplayed_level() -> StringName:
	if not _loaded:
		_ensure_loaded()
	var unlocked: Array = _campaign.get("unlocked_levels", [])
	var results: Dictionary = _campaign.get("level_results", {})
	for raw_id: Variant in unlocked:
		var id := StringName(raw_id)
		var r: Dictionary = results.get(String(id), {})
		if not bool(r.get("completed", false)):
			return id
	return &""


## 原子写当前槽；成功返回 OK。信号由调用方在成功路径发恰好一次（此处不发）。
func _persist() -> Error:
	_campaign["updated_at_utc"] = Time.get_datetime_string_from_system(true)
	return SaveService.write_campaign_slot(current_slot, _campaign)


# ---------------------------------------------------------------------------
# 解锁与本局选择
# ---------------------------------------------------------------------------

func is_unlocked(level_id: StringName) -> bool:
	_ensure_loaded()
	return (_campaign["unlocked_levels"] as Array).has(String(level_id))


func unlocked_level_ids() -> Array:
	_ensure_loaded()
	return _campaign["unlocked_levels"]


func level_result(level_id: StringName) -> Dictionary:
	_ensure_loaded()
	return (_campaign["level_results"] as Dictionary).get(String(level_id), {})


func total_marks() -> int:
	_ensure_loaded()
	var sum := 0
	for level_id: Variant in (_campaign["level_results"] as Dictionary):
		sum += int((_campaign["level_results"] as Dictionary)[level_id].get("marks", 0))
	return sum


## 选择参战关卡（仅允许已解锁且存在的关卡）；返回是否接受。
func select_level(level_id: StringName) -> bool:
	if not ContentCatalog.is_valid_level(level_id) or not is_unlocked(level_id):
		return false
	selected_level = level_id
	# 切换关卡后英雄选择回落到该关允许名单的第一名
	var level := ContentCatalog.level(level_id)
	if level != null and not level.allowed_heroes.is_empty():
		if not level.allowed_heroes.has(selected_hero):
			selected_hero = level.allowed_heroes[0]
	else:
		selected_hero = &""
	return true


## 选择出战英雄（必须在该关 allowed_heroes 内）；返回是否接受。
func select_hero(hero_id: StringName) -> bool:
	var level := ContentCatalog.level(selected_level)
	if level == null or not level.allowed_heroes.has(hero_id):
		return false
	selected_hero = hero_id
	return true


# ---------------------------------------------------------------------------
# 结算推进（PRD §15.1：自动保存发生在结算后；§15.3 level_results）
# ---------------------------------------------------------------------------

## 战斗结算：仅胜利生效——合并关卡成绩（印记取历史最高）、解锁下一关、写当前槽。
## 返回被解锁/推进到的下一关 id；失败结算或无下一关返回空。
## 原子语义：写盘失败回滚内存（不解锁/不合并印记）、不发 campaign_changed、返回空并置 last_error。
func record_battle_result(level_id: StringName, result: Dictionary) -> StringName:
	last_error = OK
	if not bool(result.get("won", false)):
		return &""
	_ensure_loaded()
	var snapshot: Dictionary = _campaign.duplicate(true)
	var results: Dictionary = _campaign["level_results"]
	var prev: Dictionary = results.get(String(level_id), {})
	results[String(level_id)] = {
		"completed": true,
		"integrity": int(result.get("integrity", 0)),
		"kills": int(result.get("kills", 0)),
		"marks": maxi(int(result.get("mark_count", 0)), int(prev.get("marks", 0))),
		"best_integrity": maxi(int(result.get("integrity", 0)), int(prev.get("best_integrity", 0))),
	}
	# 关卡解锁（PRD §7：完成关卡解锁下一关）：官方顺序由 ContentCatalog 决定
	var next_id := ContentCatalog.next_level_id(level_id)
	if next_id != &"":
		var unlocked: Array = _campaign["unlocked_levels"]
		if not unlocked.has(String(next_id)):
			unlocked.append(String(next_id))
	var err := _persist()
	if err != OK:
		_campaign = snapshot
		last_error = err
		push_warning("[M2-FLOW] record_battle_result 写档失败 slot=%d err=%d（解锁未生效）" % [current_slot, err])
		return &""
	campaign_changed.emit()
	return next_id
