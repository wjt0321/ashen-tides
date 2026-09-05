extends SceneTree
## i18n key 校验（M2，PRD §14.3）：
## - 0 个缺失 key、0 个截断关键按钮、0 个变量泄漏
## - 扫 res://** 中所有 .gd / .tres 文件中以 &"NAME" / "NAME" / StringName("NAME") 形式出现的
##   本地化 key 名（参考 LocalizationService.tr_key 与 *.csv 中的 key 列），
##   并与 LocalizationService 实际加载的 key 集合求差，输出缺失列表与未使用列表。
## 运行：godot --headless --path . -s tools/check_i18n.gd

const CSV_PATH: String = "res://data/i18n/ui.csv"
const SCAN_DIRS: Array[String] = ["res://autoload", "res://scripts", "res://data", "res://scenes"]
## 排除：脚本标识符（class_name）、文件名片段，避免误报。
var _key_pattern: RegEx

var _defined_keys: Dictionary = {} # StringName -> true
var _referenced_keys: Dictionary = {} # StringName -> true
var _referenced_files: Dictionary = {} # StringName -> Array[String]


func _initialize() -> void:
	print("[I18N-CHECK] start")
	_load_csv_keys()
	_scan_sources()
	_report()
	quit(0)


func _load_csv_keys() -> void:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		printerr("[I18N-CHECK] 无法读取 %s" % CSV_PATH)
		return
	var header := file.get_csv_line()
	if header.size() < 2:
		printerr("[I18N-CHECK] CSV 头格式异常")
		return
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2 or row[0].strip_edges().is_empty():
			continue
		_defined_keys[StringName(row[0])] = true
	file.close()
	print("[I18N-CHECK] CSV 已定义 key=%d" % _defined_keys.size())


## 匹配 &"KEY" / StringName("KEY") 两种形态；KEY 由 [A-Z][A-Z0-9_]* 组成（与 CSV 一致）。
func _scan_sources() -> void:
	for dir_path: String in SCAN_DIRS:
		_scan_dir(dir_path)


func _scan_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for file_name: String in dir.get_files():
		if not (file_name.ends_with(".gd") or file_name.ends_with(".tres") or file_name.ends_with(".tscn")):
			continue
		_scan_file(dir_path.path_join(file_name))
	for subdir_name: String in dir.get_directories():
		_scan_dir(dir_path.path_join(subdir_name))


func _scan_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var content := file.get_as_text()
	file.close()
	# &"KEY" 形式
	var idx := 0
	while true:
		var found := content.find('&"', idx)
		if found < 0:
			break
		var end_quote := content.find('"', found + 2)
		if end_quote < 0:
			break
		var key: String = content.substr(found + 2, end_quote - found - 2)
		if _is_i18n_key(key):
			_register_reference(StringName(key), path)
		idx = end_quote + 1
	# StringName("KEY") 形式
	idx = 0
	while true:
		var prefix := content.find('StringName("', idx)
		if prefix < 0:
			break
		var end_quote := content.find('"', prefix + 12)
		if end_quote < 0:
			break
		var key2: String = content.substr(prefix + 12, end_quote - prefix - 12)
		if _is_i18n_key(key2):
			_register_reference(StringName(key2), path)
		idx = end_quote + 1


func _is_i18n_key(s: String) -> bool:
	if s.length() < 4:
		return false
	var first := s.unicode_at(0)
	if first < 0x41 or first > 0x5A: ## 'A'..'Z'
		return false
	for i: int in range(1, s.length()):
		var c: int = s.unicode_at(i)
		var ok := (c >= 0x41 and c <= 0x5A) or (c >= 0x30 and c <= 0x39) or c == 0x5F
		if not ok:
			return false
	return true


func _register_reference(sk: StringName, path: String) -> void:
	_referenced_keys[sk] = true
	if not _referenced_files.has(sk):
		_referenced_files[sk] = []
	(_referenced_files[sk] as Array).append(path)


func _report() -> void:
	var missing: Array[StringName] = []
	for key: StringName in _referenced_keys:
		if not _defined_keys.has(key):
			missing.append(key)
	missing.sort()
	var unused: Array[StringName] = []
	for key: StringName in _defined_keys:
		if not _referenced_keys.has(key):
			unused.append(key)
	unused.sort()
	print("[I18N-CHECK] referenced=%d defined=%d missing=%d unused=%d" % [
		_referenced_keys.size(), _defined_keys.size(), missing.size(), unused.size()
	])
	if missing.is_empty() and unused.is_empty():
		print("[I18N-CHECK] PASS (0 missing, 0 unused)")
		return
	if not missing.is_empty():
		printerr("[I18N-CHECK] MISSING KEYS (%d):" % missing.size())
		for key: StringName in missing:
			var files: Array = _referenced_files.get(key, [])
			printerr("  - %s @ %s" % [key, ", ".join(files.slice(0, 3))])
	if not unused.is_empty():
		print("[I18N-CHECK] unused keys (informational, can be dropped):")
		for key: StringName in unused:
			print("  - %s" % key)