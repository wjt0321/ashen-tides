extends Node
## ContentCatalog：稳定 id → typed resource 的唯一解析入口（autoload，纯服务，无 presentation）。
## 设计原则（PROJECT_EXECUTION_BASELINE.md §3 / OPEN_SOURCE_TD_RESEARCH.md §3.3）：
##   - 同一脚本/CLI/玩家 UI 共享；不在 main.gd 重复 load() 路径；
##   - id 排序保证 Campaign Map / 下一关 / 测试的稳定性；
##   - 失败返回 null + push_error，不抛异常（不破坏 60Hz tick）；
##   - 不修改数据契约；不引入 Resources 之外的目录解析方式。
##
## 接口（仅本文件维护，避免散落到其他脚本）：
##   level(id) / hero(id) / tower(id) / enemy(id) / device(id)
##   all_level_ids() / is_valid_level(id) / next_level_id(id) / first_level_id() / last_level_id()

const LEVEL_DIR: String = "res://data/levels/"
const TOWER_DIR: String = "res://data/towers/"
const ENEMY_DIR: String = "res://data/enemies/"
const HERO_DIR: String = "res://data/heroes/"
const DEVICE_DIR: String = "res://data/devices/"
const PHASE_EVENT_DIR: String = "res://data/phase_events/"

## 缓存：StringName -> Resource。空值缓存为 null，避免重复 IO/错误。
var _level_cache: Dictionary = {}
var _tower_cache: Dictionary = {}
var _enemy_cache: Dictionary = {}
var _hero_cache: Dictionary = {}
var _device_cache: Dictionary = {}

## 关卡 id 列表缓存（首查一次性扫盘）。
var _level_ids_cached: PackedStringArray = PackedStringArray()
var _level_ids_dirty: bool = true


func _ready() -> void:
	print("[M2] ContentCatalog ready (stable id resolver)")


# ---------------------------------------------------------------------------
# 关卡
# ---------------------------------------------------------------------------

func level(id: StringName) -> LevelData:
	if id == &"":
		return null
	if _level_cache.has(id):
		return _level_cache[id]
	var path := LEVEL_DIR + String(id) + ".tres"
	if not ResourceLoader.exists(path, "LevelData"):
		_level_cache[id] = null
		return null
	var res := load(path) as LevelData
	_level_cache[id] = res
	return res


func is_valid_level(id: StringName) -> bool:
	return level(id) != null


## 全关卡 id，按字典序；用于 Campaign Map 和集成测试的稳定排序。
func all_level_ids() -> PackedStringArray:
	if _level_ids_dirty:
		_level_ids_cached = _scan_level_ids()
		_level_ids_dirty = false
	return _level_ids_cached


func _scan_level_ids() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var dir := DirAccess.open(LEVEL_DIR)
	if dir == null:
		push_error("[M2] ContentCatalog: 关卡目录不存在 %s" % LEVEL_DIR)
		return out
	var ids: Array[String] = []
	for file_name: String in dir.get_files():
		if file_name.begins_with("level_") and file_name.ends_with(".tres"):
			ids.append(file_name.trim_suffix(".tres"))
	ids.sort()
	for s: String in ids:
		out.append(s)
	return out


## 关卡表当前最小 id（战役起点）；失败返回空。
func first_level_id() -> StringName:
	var ids := all_level_ids()
	if ids.is_empty():
		return &""
	return StringName(ids[0])


## 关卡表当前最大 id（战役终点 / 序章末尾）；失败返回空。
func last_level_id() -> StringName:
	var ids := all_level_ids()
	if ids.is_empty():
		return &""
	return StringName(ids[ids.size() - 1])


## 当前 id 在关卡序列中的下一个；已是末关或非法返回空。
func next_level_id(id: StringName) -> StringName:
	if id == &"":
		return &""
	var ids := all_level_ids()
	var idx := ids.find(String(id))
	if idx < 0 or idx + 1 >= ids.size():
		return &""
	return StringName(ids[idx + 1])


## 当前 id 在关卡序列中的上一个；非法返回空。
func prev_level_id(id: StringName) -> StringName:
	if id == &"":
		return &""
	var ids := all_level_ids()
	var idx := ids.find(String(id))
	if idx <= 0:
		return &""
	return StringName(ids[idx - 1])


## 索引便于 M2 CampaignMap 按章节铺图。
func level_index(id: StringName) -> int:
	var ids := all_level_ids()
	return ids.find(String(id))


# ---------------------------------------------------------------------------
# 塔 / 敌人 / 英雄 / 装置
# ---------------------------------------------------------------------------

func tower(id: StringName) -> TowerData:
	if id == &"":
		return null
	if _tower_cache.has(id):
		return _tower_cache[id]
	var path := TOWER_DIR + String(id) + ".tres"
	if not ResourceLoader.exists(path, "TowerData"):
		_tower_cache[id] = null
		return null
	var res := load(path) as TowerData
	_tower_cache[id] = res
	return res


func enemy(id: StringName) -> EnemyData:
	if id == &"":
		return null
	if _enemy_cache.has(id):
		return _enemy_cache[id]
	var path := ENEMY_DIR + String(id) + ".tres"
	if not ResourceLoader.exists(path, "EnemyData"):
		_enemy_cache[id] = null
		return null
	var res := load(path) as EnemyData
	_enemy_cache[id] = res
	return res


func hero(id: StringName) -> HeroData:
	if id == &"":
		return null
	if _hero_cache.has(id):
		return _hero_cache[id]
	var path := HERO_DIR + String(id) + ".tres"
	if not ResourceLoader.exists(path, "HeroData"):
		_hero_cache[id] = null
		return null
	var res := load(path) as HeroData
	_hero_cache[id] = res
	return res


func device(id: StringName) -> DeviceData:
	if id == &"":
		return null
	if _device_cache.has(id):
		return _device_cache[id]
	var path := DEVICE_DIR + String(id) + ".tres"
	if not ResourceLoader.exists(path, "DeviceData"):
		_device_cache[id] = null
		return null
	var res := load(path) as DeviceData
	_device_cache[id] = res
	return res


# ---------------------------------------------------------------------------
# 测试 / 调试接口
# ---------------------------------------------------------------------------

func clear_cache() -> void:
	_level_cache.clear()
	_tower_cache.clear()
	_enemy_cache.clear()
	_hero_cache.clear()
	_device_cache.clear()
	_level_ids_dirty = true
	_level_ids_cached = PackedStringArray()


## 当前已加载的关卡数（缓存命中数）。用于测试断言。
func cached_level_count() -> int:
	return _level_cache.size()