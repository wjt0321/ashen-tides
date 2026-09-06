extends SceneTree
## 最小测试运行器（GUT 等价物，M1；RESEARCH_REPORT.md §18 允许等价方案，不下载第三方插件）。
## 运行：godot --headless --path . -s tools/run_tests.gd
## 约定：tests/unit/test_*.gd 与 tests/integration/test_*.gd 继承 TestBase，test_* 方法自动执行。
## 退出码：0 = 全过；1 = 有失败；2 = 运行器自身错误。
## 生命周期：全部测试在 _initialize 同步跑完；每个文件结束清扫孤儿子节点
## （queue_free 挂起的节点先 cancel_free 再同步 free，避免删除队列悬挂指针），
## 使退出时无 "instances leaked / resources still in use" 噪声。

const TEST_DIRS: Array[String] = ["res://tests/unit/", "res://tests/integration/"]

var _exit_code: int = -1


func _initialize() -> void:
	print("[M1-TEST] start")
	var files: Array[String] = []
	for dir_path: String in TEST_DIRS:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			printerr("[M1-TEST] 目录不存在: %s" % dir_path)
			continue
		for file_name: String in dir.get_files():
			if file_name.begins_with("test_") and file_name.ends_with(".gd"):
				files.append(dir_path + file_name)
	files.sort()
	if files.is_empty():
		printerr("[M1-TEST] 未发现任何测试文件")
		quit(2)
		return

	# 记录启动时已存在的 root 子节点（autoload），测试结束清扫时不得销毁它们
	var autoload_ids: Array[int] = []
	for c: Node in root.get_children():
		autoload_ids.append(c.get_instance_id())

	var total_pass := 0
	var total_fail := 0
	for file_name: String in files:
		var script := load(file_name) as GDScript
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
		_sweep_orphan_nodes(autoload_ids)
	print("[M1-TEST] total: pass=%d fail=%d" % [total_pass, total_fail])
	if total_fail == 0:
		print("[M1-TEST] PASS")
		_exit_code = 0
	else:
		print("[M1-TEST] FAIL")
		_exit_code = 1
	quit(_exit_code)


## 销毁测试遗留的非 autoload 根节点（app/battle 实例及其子树）。
## queue_free 挂起的节点先 cancel_free 取消删除队列项，再同步 free 整棵子树
## （同步 runner 无帧尾冲刷；直接 free 已排队节点会留下悬挂的删除队列指针）。
func _sweep_orphan_nodes(autoload_ids: Array[int]) -> void:
	for c: Node in root.get_children():
		if autoload_ids.has(c.get_instance_id()):
			continue
		if c.is_queued_for_deletion():
			c.cancel_free()
		c.free() # 同步释放整棵子树
