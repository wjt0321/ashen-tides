extends SceneTree
## 最小测试运行器（GUT 等价物，M1；RESEARCH_REPORT.md §18 允许等价方案，不下载第三方插件）。
## 运行：godot --headless --path . -s tools/run_tests.gd
## 约定：tests/unit/test_*.gd 继承 TestBase，所有 test_* 方法自动执行。
## 退出码：0 = 全过；1 = 有失败；2 = 运行器自身错误。

const TEST_DIR := "res://tests/unit/"


func _initialize() -> void:
	print("[M1-TEST] start")
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		printerr("[M1-TEST] 目录不存在: %s" % TEST_DIR)
		quit(2)
		return
	var files: Array[String] = []
	for file_name: String in dir.get_files():
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			files.append(file_name)
	files.sort()
	if files.is_empty():
		printerr("[M1-TEST] 未发现任何测试文件")
		quit(2)
		return

	var total_pass := 0
	var total_fail := 0
	for file_name: String in files:
		var script := load(TEST_DIR + file_name) as GDScript
		if script == null:
			printerr("[M1-TEST] 加载失败: %s" % file_name)
			total_fail += 1
			continue
		var instance: Variant = script.new()
		if not (instance is TestBase):
			printerr("[M1-TEST] %s 未继承 TestBase" % file_name)
			total_fail += 1
			continue
		instance.run_all()
		var passed: int = instance.passes
		var failed: int = instance.failures.size()
		total_pass += passed
		total_fail += failed
		print("[M1-TEST] %s: pass=%d fail=%d" % [file_name, passed, failed])
	print("[M1-TEST] total: pass=%d fail=%d" % [total_pass, total_fail])
	if total_fail == 0:
		print("[M1-TEST] PASS")
		quit(0)
	else:
		print("[M1-TEST] FAIL")
		quit(1)
