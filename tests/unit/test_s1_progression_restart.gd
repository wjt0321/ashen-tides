extends TestBase
## S1 修复回归（玩家流程集成测试，非纯数据）：
## 1) 重开后建造节点复位——上局占用节点不得黄锁（复现路径：放塔 → _on_pause_restart → 再放塔）；
## 2) 通关后解锁并推进下一关（复现路径：_enter_win → 结算「下一关」→ 新关可建造）。
## 直接实例化主场景驱动真实玩家路径；主存档先备份、测试后恢复，不污染用户存档。

const MAIN_SCENE := "res://scenes/boot/main.tscn"

## 手动调用 _ready() 不会让引擎置 ready 标记，需自行记录防止二次调用（AudioService 信号重复连接等）
var _forced_ready: Dictionary = {}


func _force_ready_once(n: Node) -> void:
	var id := n.get_instance_id()
	if _forced_ready.has(id):
		return
	_forced_ready[id] = true
	if n.has_method(&"_ready"):
		n._ready()


func _make_main() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	var inst := (load(MAIN_SCENE) as PackedScene).instantiate()
	tree.root.add_child(inst)
	# 测试运行器在 SceneTree._initialize 内同步执行，add_child 不触发 _ready；手动补齐生命周期。
	# 先补齐 autoload（LocalizationService._ready 才加载 ui.csv，否则 tr_key 全部 miss）。
	# AudioService 跳过：headless 下无音频设备，强制 ready 只会产生播放噪音报错，与 S1 断言无关。
	for c: Node in tree.root.get_children():
		if c != inst and c.name != &"AudioService":
			_force_ready_once(c)
	_force_ready_once(inst)
	_force_descendants_ready(inst)
	return inst


## main._ready 内 new 出来的面板/覆盖层同样收不到 _ready，递归补齐（先自身再子孙，与引擎顺序一致）
func _force_descendants_ready(n: Node) -> void:
	for c: Node in n.get_children():
		_force_ready_once(c)
		_force_descendants_ready(c)


func _read_bytes(path: String) -> PackedByteArray:
	if not FileAccess.file_exists(path):
		return PackedByteArray()
	var f := FileAccess.open(path, FileAccess.READ)
	var data := f.get_buffer(f.get_length())
	f.close()
	return data


func _write_bytes(path: String, data: PackedByteArray) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if data.is_empty():
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(data)
	f.close()


func test_restart_releases_build_nodes() -> void:
	var m := _make_main()
	var node: BuildNodeVisual = m._build_nodes[0]
	var tower_data: TowerData = m._towers_available[0]
	check(m._place_tower_at(node, tower_data), "首次放塔成功")
	check_eq(node.state, BuildNodeVisual.State.OCCUPIED, "放塔后节点占用")
	m._on_pause_restart() # 玩家路径：暂停/结算「重开本关」
	var locked := 0
	for n: BuildNodeVisual in m._build_nodes:
		if n.state != BuildNodeVisual.State.FREE:
			locked += 1
	check_eq(locked, 0, "重开后全部节点解除占用（S1-2 回归）")
	check(m._place_tower_at(node, tower_data), "重开后同节点可再次放塔")
	check_eq(m._towers.size(), 1, "重开后塔计数干净")
	m.free()


func test_win_unlocks_and_advances_next_level() -> void:
	# 备份主存档三件套（write_campaign_slot 原子写会轮转出 .bak1）
	var slot := SaveService.slot_path(1)
	var backups := {}
	for path: String in [slot, slot + ".bak1", slot + ".bak2"]:
		backups[path] = _read_bytes(path)
	SaveService.clear_suspend()
	var m := _make_main()
	check_eq(String(m._level_id), "level_c01", "默认关 c01")
	check_eq(String(m._next_level_id()), "level_c02", "下一关解析为 c02")
	m._enter_win() # 玩家路径：通关（all_waves_completed → win）
	check(bool(m._last_result.get("won", false)), "结算结果为胜")
	check_eq(String(m._last_result.get("next_level_id", "")), "level_c02", "结算携带下一关 id")
	var campaign := SaveService.read_campaign_slot(1)
	var c01: Dictionary = campaign.get("level_results", {}).get("level_c01", {})
	check(bool(c01.get("completed", false)), "主存档记录 c01 通关")
	check((campaign.get("unlocked_levels", []) as Array).has("level_c02"), "主存档解锁 c02（S1-1 回归）")
	m._on_next_level_requested() # 玩家路径：结算面板「下一关」
	check_eq(String(m._level_id), "level_c02", "推进到 c02")
	var locked := 0
	for n: BuildNodeVisual in m._build_nodes:
		if n.state != BuildNodeVisual.State.FREE:
			locked += 1
	check_eq(locked, 0, "c02 节点全部可建")
	check(m._place_tower_at(m._build_nodes[0], m._towers_available[0]), "c02 可正常放塔")
	check(not m._battle_over, "新关战斗状态复位")
	m.free()
	# 恢复主存档
	for path: String in backups:
		_write_bytes(path, backups[path])
