extends TestBase
## ContentCatalog：稳定 id → typed resource 单例解析。
## 覆盖：合法/非法 id、关卡序、缓存命中、目录扫描稳定性。

func test_resolve_known_ids() -> void:
	check(ContentCatalog.level(&"level_c01") != null, "level_c01 可解析")
	check(ContentCatalog.hero(&"hero_lanzhou_wei") != null, "hero_lanzhou_wei 可解析")
	check(ContentCatalog.hero(&"hero_zhushou_muen") != null, "hero_zhushou_muen 可解析")
	check(ContentCatalog.tower(&"tower_needle_rail") != null, "tower_needle_rail 可解析")
	check(ContentCatalog.enemy(&"salt_shell_walker") != null, "salt_shell_walker 可解析")
	check(ContentCatalog.device(&"device_c03_lighthouse") != null, "device_c03_lighthouse 可解析")


func test_resolve_unknown_returns_null() -> void:
	check(ContentCatalog.level(&"level_does_not_exist") == null, "未知关卡返回 null")
	check(ContentCatalog.hero(&"") == null, "空 id 返回 null")
	check(ContentCatalog.tower(&"tower_xxx") == null, "未知塔返回 null")


func test_is_valid_level() -> void:
	check(ContentCatalog.is_valid_level(&"level_c01"), "c01 valid")
	check(ContentCatalog.is_valid_level(&"level_c14"), "c14 valid（provisional M4 内容，仅 catalog 可达）")
	check(not ContentCatalog.is_valid_level(&"level_zzz"), "未知 invalid")


func test_level_ordering_is_stable() -> void:
	var ids: PackedStringArray = ContentCatalog.all_level_ids()
	check(ids.size() >= 3, "关卡目录至少 3 项")
	for i: int in range(1, ids.size()):
		check(String(ids[i - 1]) < String(ids[i]), "字典序：" + String(ids[i - 1]) + " < " + String(ids[i]))
	check(String(ids[0]) == "level_c01", "首关 c01")
	# last_level_id 与 all_level_ids 末位一致
	var last := ContentCatalog.last_level_id()
	check(String(last) == String(ids[ids.size() - 1]), "last_level_id 末位一致")


func test_next_prev_level() -> void:
	var ids: PackedStringArray = ContentCatalog.all_level_ids()
	check_eq(String(ContentCatalog.next_level_id(&"level_c01")), ids[1], "c01 的下一关")
	check_eq(String(ContentCatalog.last_level_id()), ids[ids.size() - 1], "末关无下一关")
	check_eq(String(ContentCatalog.next_level_id(ContentCatalog.last_level_id())), "", "末关 next 必空")
	check_eq(String(ContentCatalog.prev_level_id(&"level_c01")), "", "首关无上一关")
	check_eq(String(ContentCatalog.prev_level_id(StringName(ids[1]))), ids[0], "第二关上一关是首关")


func test_level_index_round_trip() -> void:
	var ids: PackedStringArray = ContentCatalog.all_level_ids()
	for i: int in ids.size():
		check_eq(ContentCatalog.level_index(StringName(ids[i])), i, "索引一致：" + String(ids[i]))


func test_cache_is_idempotent() -> void:
	var a := ContentCatalog.level(&"level_c02")
	var b := ContentCatalog.level(&"level_c02")
	check(a == b, "缓存命中同一资源实例")
	check(ContentCatalog.cached_level_count() >= 1, "缓存计数 >= 1")


func test_clear_cache_releases() -> void:
	ContentCatalog.level(&"level_c01")
	var before := ContentCatalog.cached_level_count()
	check(before >= 1, "解析前缓存计数 >= 1")
	ContentCatalog.clear_cache()
	var after := ContentCatalog.cached_level_count()
	check_eq(after, 0, "clear_cache 后缓存清空")


func test_first_level_id_is_c01() -> void:
	check_eq(String(ContentCatalog.first_level_id()), "level_c01", "首关 c01")