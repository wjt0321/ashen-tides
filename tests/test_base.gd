class_name TestBase
extends RefCounted
## 最小测试基类（GUT 等价物，M1；不下载第三方插件）。
## 子类放在 tests/unit/test_*.gd，所有 test_* 方法由 tools/run_tests.gd 自动执行。

var failures: Array[String] = []
var passes: int = 0


func check(condition: bool, message: String) -> void:
	if condition:
		passes += 1
	else:
		failures.append(message)
		printerr("    FAIL: %s" % message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s（期望 %s，实际 %s）" % [message, expected, actual])


func check_approx(actual: float, expected: float, epsilon: float, message: String) -> void:
	check(absf(actual - expected) <= epsilon, "%s（期望≈%s，实际 %s）" % [message, expected, actual])


func run_all() -> void:
	for method: Dictionary in get_method_list():
		var method_name := String(method.name)
		if method_name.begins_with("test_"):
			# GUT 风格钩子（契约测试 test_campaign_service.gd 依赖 before_each 隔离测试槽）
			if has_method(&"before_each"):
				call(&"before_each")
			Callable(self, method_name).call()
			if has_method(&"after_each"):
				call(&"after_each")


# ---------------------------------------------------------------------------
# 集成测试共用：手动生命周期（run_tests 在 SceneTree._initialize 内同步执行，
# 引擎不派发 _ready；手动调用 _ready() 不会置引擎 ready 标记，需记录防二次调用）
# ---------------------------------------------------------------------------

var _forced_ready: Dictionary = {}


func _force_ready_once(n: Node) -> void:
	var id := n.get_instance_id()
	if _forced_ready.has(id):
		return
	_forced_ready[id] = true
	# 节点已入树时引擎已同步派发 _ready（add_child 到 root 即触发）；
	# 手动再调会重复 connect/重复构建子节点，is_node_ready() 守卫优先于手动调用。
	if n.is_node_ready():
		return
	if n.has_method(&"_ready"):
		n._ready()


func _force_descendants_ready(n: Node) -> void:
	for c: Node in n.get_children():
		_force_ready_once(c)
		_force_descendants_ready(c)


## 补齐 autoload 生命周期（LocalizationService._ready 才加载 ui.csv）。
## 默认跳过 AudioService：headless 无音频设备，强制 ready 只产生播放噪音报错。
func _force_autoloads_ready(skip_names: Array = [&"AudioService"]) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for c: Node in tree.root.get_children():
		if not skip_names.has(c.name):
			_force_ready_once(c)


## 备份/恢复存档文件（集成测试会真实写盘；用空 PackedByteArray 表示文件原本不存在）
func _backup_files(paths: Array) -> Dictionary:
	var backups := {}
	for path: String in paths:
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			backups[path] = f.get_buffer(f.get_length())
			f.close()
		else:
			backups[path] = PackedByteArray()
	return backups


func _restore_files(backups: Dictionary) -> void:
	for path: String in backups:
		var data: PackedByteArray = backups[path]
		if data.is_empty():
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
			continue
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_buffer(data)
		f.close()
