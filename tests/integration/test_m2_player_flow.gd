extends TestBase
## M2 玩家路径集成测试（PROJECT_EXECUTION_BASELINE §5 验收脚本）。
## 完整路径：启动 → Title → Slot（新档）→ Campaign（首关解锁）→ Briefing（无英雄关）
##          → Battle → 胜负 → Result → 下一关（自动解锁 c02）→ 退出
##          → 再次启动 → Continue → 槽 2 → Campaign（c02 解锁）→ Briefing → Battle → 退出
##          → 选槽 3（新档）→ 槽 2 不受影响。
##
## 正式 API 只允许槽 1–3（PRD §15.1）：测试用真实槽 + TestBase._backup_files/_restore_files
## （含不存在哨兵），before_each 备份、after_each 可靠恢复用户存档与 suspend。

const APP_SCENE := "res://scenes/app/app.tscn"
const _TEST_SLOTS: Array[int] = [1, 2, 3]

var _backups: Dictionary = {}


func before_each() -> void:
	var paths: Array = []
	for s: int in _TEST_SLOTS:
		var path := SaveService.slot_path(s)
		paths.append(path)
		paths.append(path + ".bak1")
		paths.append(path + ".bak2")
	paths.append(SaveService.SUSPEND_PATH)
	_backups = _backup_files(paths)
	_clear_test_state()


func after_each() -> void:
	_restore_files(_backups)
	_backups = {}
	CampaignService.reset_internal()


func _clear_test_state() -> void:
	# 清档必须移除文件：写空壳 {} 会被结构校验拒绝并回退到 bak1 旧档（删除后复活）
	for s: int in _TEST_SLOTS:
		SaveService.remove_campaign_slot(s)
	SaveService.clear_suspend()
	CampaignService.reset_internal()


func _make_app() -> Control:
	var tree := Engine.get_main_loop() as SceneTree
	var inst := (load(APP_SCENE) as PackedScene).instantiate() as Control
	tree.root.add_child(inst)
	_force_autoloads_ready()
	_force_ready_once(inst)
	_force_descendants_ready(inst)
	return inst


# ---------------------------------------------------------------------------
# 路径 1：全新一局 + 通关 + Result → 下一关解锁（PRD §5 验收脚本：first launch）
# 审查断言：flow 托管结算写档恰好一次（campaign_changed 一次）且 battle_finished 恰好一次。
# ---------------------------------------------------------------------------

func test_first_launch_new_game_to_next_level() -> void:
	var app := _make_app()
	check_eq(app._state, app.State.TITLE, "启动进 Title")
	# 新游戏 → 选空槽 → 进入战役
	app._show_slots(true)
	app._new_game_slot(1)
	check_eq(app._state, app.State.CAMPAIGN, "新档进 Campaign")
	check_eq(CampaignService.current_slot, 1, "current_slot = 1")
	# c01 解锁且可点，c02 锁定
	var c01_btn := app._screen.find_child("Level_level_c01", true, false) as Button
	var c02_btn := app._screen.find_child("Level_level_c02", true, false) as Button
	check(c01_btn != null and not c01_btn.disabled, "c01 可点")
	check(c02_btn != null and c02_btn.disabled, "c02 锁定")
	# Briefing（c01 无英雄）
	app._select_level(&"level_c01")
	check_eq(app._state, app.State.BRIEFING, "进入 Briefing")
	# 没有 hero select 区域（c01.allowed_heroes 为空）
	var hero_btn := app._screen.find_child("Hero_hero_lanzhou_wei", true, false) as Button
	check_eq(hero_btn, null, "c01 不显示英雄选择（allowed_heroes 为空）")
	# 战斗
	app._enter_battle(false)
	_force_ready_once(app._battle)
	_force_descendants_ready(app._battle)
	check_eq(app._state, app.State.BATTLE, "进入 Battle")
	check_eq(String(app._battle._level_id), "level_c01", "战斗载入 c01")
	# 审查断言计数器：写档信号 / battle_finished 各恰好一次
	var write_count := [0]
	var finish_count := [0]
	CampaignService.campaign_changed.connect(func() -> void: write_count[0] += 1)
	app._battle.battle_finished.connect(func(_r: Dictionary) -> void: finish_count[0] += 1)
	# 胜利结算
	app._battle._enter_win()
	check_eq(finish_count[0], 1, "battle_finished 恰好发出一次")
	check_eq(write_count[0], 1, "flow 结算写档恰好一次（唯一入口）")
	check_eq(app._state, app.State.RESULT, "胜进 Result")
	check(bool(app._last_result.get("won", false)), "结果为胜")
	check(CampaignService.is_unlocked(&"level_c02"), "Flow 推进解锁 c02")
	# 「下一关」按钮存在且 next_level_id 由写档方（AppFlow）回填
	var next_btn := app._screen.find_child("NextLevel", true, false) as Button
	check(next_btn != null, "Result 有 NextLevel 按钮")
	check_eq(String(app._last_result.get("next_level_id", "")), "level_c02", "next_level_id 由 AppFlow 写档回填")
	# 点下一关
	next_btn.pressed.emit()
	check_eq(app._state, app.State.BRIEFING, "NextLevel 进 Briefing")
	check_eq(CampaignService.selected_level, &"level_c02", "选中 c02")
	app.free()


# ---------------------------------------------------------------------------
# 路径 2：退出 → 再次启动 → Continue → Campaign 显示已解锁关卡
# ---------------------------------------------------------------------------

func test_quit_then_relaunch_continue_shows_unlocked() -> void:
	# 第一次启动：c01 通关并写档
	var app := _make_app()
	app._show_slots(true)
	app._new_game_slot(2)
	app._select_level(&"level_c01")
	app._enter_battle(false)
	_force_ready_once(app._battle)
	_force_descendants_ready(app._battle)
	app._battle._enter_win()
	app.queue_free()
	# 第二次启动（fresh process）：构造新的 App 实例模拟退出后重启
	var app2 := _make_app()
	check_eq(app2._state, app2.State.TITLE, "重启后进 Title")
	# 槽 2 应被识别为占用（continue_game 能加载通关状态）
	var ok := CampaignService.continue_game(2)
	check(ok, "重启 continue_game(2) 成功")
	check(CampaignService.is_unlocked(&"level_c02"), "重启后 c02 仍解锁")
	# 再展示 Campaign 看 c02 可点
	app2._show_campaign()
	var c02_btn := app2._screen.find_child("Level_level_c02", true, false) as Button
	check(c02_btn != null and not c02_btn.disabled, "c02 可点")
	var c01_btn := app2._screen.find_child("Level_level_c01", true, false) as Button
	check(c01_btn != null and not c01_btn.disabled, "c01 仍可点")
	app2.free()


# ---------------------------------------------------------------------------
# 路径 2b：空壳档 → Title 继续按钮禁用（审查修复：has_save 有意义载荷判断）
# ---------------------------------------------------------------------------

func test_title_continue_disabled_for_shell_save() -> void:
	# 槽 1 写一个有意义档 → 继续可用
	CampaignService.new_game(1, "p1")
	var app := _make_app()
	var continue_btn := app._screen.find_child("ContinueBtn", true, false) as Button
	check(continue_btn != null and not continue_btn.disabled, "有档时继续可用")
	app.free()
	# 删除（写出空壳 {}）→ 继续禁用
	CampaignService.delete_slot(1)
	CampaignService.reset_internal()
	var app2 := _make_app()
	var continue_btn2 := app2._screen.find_child("ContinueBtn", true, false) as Button
	check(continue_btn2 != null and continue_btn2.disabled, "空壳档继续禁用")
	app2.free()


# ---------------------------------------------------------------------------
# 路径 3：3 槽隔离（PRD §15.1）—— 新档/继续/切换槽位不互相污染
# ---------------------------------------------------------------------------

func test_three_slot_isolation_after_full_flow() -> void:
	# 槽 2：通 c01 → 解锁 c02
	CampaignService.new_game(2)
	CampaignService.record_battle_result(&"level_c01", {"won": true, "integrity": 20, "kills": 90, "mark_count": 3})
	check(CampaignService.is_unlocked(&"level_c02"), "槽 2 解锁 c02")
	# 切到槽 3：新档只解 c01
	CampaignService.set_current_slot(3)
	CampaignService.new_game(3)
	check(CampaignService.is_unlocked(&"level_c01"), "槽 3 首关解锁")
	check(not CampaignService.is_unlocked(&"level_c02"), "槽 3 c02 仍锁定")
	# 再切回槽 2：状态保持
	CampaignService.set_current_slot(2)
	check(CampaignService.is_unlocked(&"level_c02"), "切回槽 2 c02 仍解锁")
	# 槽 1：完全未触碰（_clear_test_state 已清空）
	CampaignService.set_current_slot(1)
	check_eq(bool(CampaignService.slot_meta(1).get("exists", true)), false, "槽 1 空")


# ---------------------------------------------------------------------------
# 路径 4：Suspend save 三选项（PRD §15.2）—— 检测/继续/放弃 不会破坏状态
# ---------------------------------------------------------------------------

func test_suspend_save_detected_after_loss() -> void:
	# 模拟一局打到中段后失败：写一份 suspend
	CampaignService.new_game(1)
	var payload := {
		"level_id": "level_c01",
		"completed_waves": 2,
		"current_phase_id": "mingchao",
		"rng_state": 12345,
		"fleet_integrity": 14,
		"ember": 250,
		"becon": 35,
		"towers": [],
		"hero": {"position": [320.0, 240.0], "current_hp": 250.0, "cooldowns": {}},
	}
	SaveService.write_suspend(payload)
	check(SaveService.has_suspend(), "suspend 已写入")
	# 新启动后应能检测 suspend 存在
	var app := _make_app()
	# （main.tscn 在 _ready 内会发出 flash_not；本测试不强制 UI 文案）
	check(SaveService.has_suspend(), "App 启动后 suspend 仍存在")
	app.free()
	# 清除 suspend 再跑一次
	SaveService.clear_suspend()
	check(not SaveService.has_suspend(), "放弃后清除")


# ---------------------------------------------------------------------------
# 路径 5：两英雄选择（C05，允许 lanzhou_wei + zhushou_muen）
# ---------------------------------------------------------------------------

func test_two_hero_choice_visible_for_c05() -> void:
	# 推进到 c05 解锁
	CampaignService.new_game(3)
	var level_ids := ContentCatalog.all_level_ids()
	for i: int in level_ids.size():
		var lid := StringName(level_ids[i])
		var next := ContentCatalog.next_level_id(lid)
		CampaignService.record_battle_result(lid, {"won": true, "integrity": 18, "mark_count": 2})
		if next == &"":
			break
	# 验证 c05 解锁
	var c05 := ContentCatalog.level(&"level_c05")
	check(c05 != null and c05.allowed_heroes.size() >= 2, "c05 允许多英雄")
	check(CampaignService.is_unlocked(&"level_c05"), "c05 解锁")
	# Briefing 应显示两英雄按钮
	var app := _make_app()
	app._show_campaign()
	app._select_level(&"level_c05")
	check_eq(app._state, app.State.BRIEFING, "c05 进 Briefing")
	var hero_lz_btn := app._screen.find_child("Hero_hero_lanzhou_wei", true, false) as Button
	var hero_zm_btn := app._screen.find_child("Hero_hero_zhushou_muen", true, false) as Button
	check(hero_lz_btn != null, "岚舟·苇 按钮存在")
	check(hero_zm_btn != null, "穆恩 按钮存在")
	# 点穆恩
	hero_zm_btn.pressed.emit()
	check_eq(CampaignService.selected_hero, &"hero_zhushou_muen", "切换到穆恩")
	app.free()
