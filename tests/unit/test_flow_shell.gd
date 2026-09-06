extends TestBase
## M2 Flow Shell 流程测试（真实玩家路径，非纯数据）：
## A) ContentCatalog 稳定 id/顺序/解析；B) CampaignService 3 槽隔离与推进；
## D) AppFlow Title → Slot → Campaign → Briefing → Battle → Result → 下一关 / 返回战役。
## 统一 TestBase._backup_files/_restore_files（含不存在哨兵）：before_each 备份槽 2/3 与 suspend，
## after_each 可靠恢复；用户真实槽 1 存档只读不触碰。

const APP_SCENE := "res://scenes/app/app.tscn"
const SLOT2_FILES := ["user://saves/slot_02.save.json", "user://saves/slot_02.save.json.bak1", "user://saves/slot_02.save.json.bak2"]
const SLOT3_FILES := ["user://saves/slot_03.save.json", "user://saves/slot_03.save.json.bak1", "user://saves/slot_03.save.json.bak2"]

var _backups: Dictionary = {}


func before_each() -> void:
	_backups = _backup_files(SLOT2_FILES + SLOT3_FILES + [SaveService.SUSPEND_PATH])


func after_each() -> void:
	_restore_files(_backups)
	_backups = {}
	CampaignService.reset_internal()


func _make_app() -> Control: # 不标注返回类型：测试需动态访问 _state/_battle 等脚本成员
	var tree := Engine.get_main_loop() as SceneTree
	var inst := (load(APP_SCENE) as PackedScene).instantiate() as Control
	tree.root.add_child(inst)
	_force_autoloads_ready()
	_force_ready_once(inst)
	_force_descendants_ready(inst)
	return inst


func test_content_catalog_contract() -> void:
	var ids := ContentCatalog.all_level_ids()
	check_eq(ids.size(), 14, "关卡目录 14 关（C01-C14）")
	check_eq(ids[0], "level_c01", "首关 c01")
	check_eq(ids[ids.size() - 1], "level_c14", "末关 c14")
	check_eq(ContentCatalog.first_level_id(), &"level_c01", "战役起点")
	check_eq(ContentCatalog.next_level_id(&"level_c01"), &"level_c02", "c01 的下一关")
	check_eq(ContentCatalog.next_level_id(&"level_c14"), &"", "末关无下一关")
	check_eq(ContentCatalog.next_level_id(&"level_c99"), &"", "未知 id 无下一关")
	check(ContentCatalog.is_valid_level(&"level_c07"), "c07 存在")
	check(not ContentCatalog.is_valid_level(&"level_c15"), "c15 不存在（本批禁止 C15+）")
	check(ContentCatalog.level(&"level_c03") != null, "关卡资源解析")
	check(ContentCatalog.hero(&"hero_lanzhou_wei") != null, "英雄资源解析")
	check(ContentCatalog.tower(&"tower_needle_rail") != null, "塔资源解析")
	check(ContentCatalog.enemy(&"anchor_crab_king") != null, "敌人资源解析")


func test_campaign_three_slot_isolation() -> void:
	# 槽 2：新档 → 通关 c01 → 解锁 c02
	CampaignService.new_game(2)
	check(CampaignService.is_unlocked(&"level_c01"), "新档解锁首关")
	check(not CampaignService.is_unlocked(&"level_c02"), "新档 c02 仍锁定")
	var next := CampaignService.record_battle_result(&"level_c01", {"won": true, "integrity": 20, "kills": 90, "mark_count": 3})
	check_eq(next, &"level_c02", "通关 c01 推进到 c02")
	check(CampaignService.is_unlocked(&"level_c02"), "槽 2 解锁 c02")
	# 印记取历史最高：低分复打不覆盖
	CampaignService.record_battle_result(&"level_c01", {"won": true, "integrity": 12, "kills": 80, "mark_count": 1})
	check_eq(int(CampaignService.level_result(&"level_c01").get("marks", 0)), 3, "印记保留历史最高")
	# 槽 3 隔离：全新档不受槽 2 进度影响
	CampaignService.new_game(3)
	check(not CampaignService.is_unlocked(&"level_c02"), "槽 3 不受槽 2 进度影响（3 槽隔离）")
	check(CampaignService.is_unlocked(&"level_c01"), "槽 3 独立解锁首关")
	# 槽 2 落盘内容独立
	var s2 := SaveService.read_campaign_slot(2)
	check((s2.get("unlocked_levels", []) as Array).has("level_c02"), "槽 2 存档文件含 c02 解锁")
	var s3 := SaveService.read_campaign_slot(3)
	check(not (s3.get("unlocked_levels", []) as Array).has("level_c02"), "槽 3 存档文件不含 c02")
	# 槽位元信息（主菜单展示：时间/完成度/印记，PRD §15.1）
	var meta2 := CampaignService.slot_meta(2)
	check(bool(meta2.get("exists", false)), "槽 2 meta 存在")
	check_eq(int(meta2.get("completed_count", 0)), 1, "槽 2 通关数 = 1")
	check_eq(int(meta2.get("marks_total", 0)), 3, "槽 2 印记总数 = 3")
	check(CampaignService.slot_meta(1).has("exists"), "槽 1 meta 调用不崩（用户真实档，结构只读不校验）")
	# 选择规则：未解锁不可选
	check(not CampaignService.select_level(&"level_c05"), "槽 3 未解锁 c05 不可选")
	check(CampaignService.select_level(&"level_c01"), "槽 3 可选 c01")


func test_flow_player_path_title_to_result() -> void:
	SaveService.clear_suspend()
	var app := _make_app()
	check_eq(app._state, app.State.TITLE, "启动进 Title")
	var title_art := app._screen.find_child("C01HarborArt", true, false) as Control
	check(title_art != null, "Title 使用港口电影海报构图")
	check(title_art != null and title_art.anchor_right == 1.0 and title_art.anchor_bottom == 1.0 and title_art.offset_right == 0.0 and title_art.offset_bottom == 0.0, "Title 港口栅格背景使用零偏移全画布锚点")
	check(app._screen.find_child("FlowPanel", true, false) == null, "Title 不再使用中央工具面板")
	check(app._screen.find_child("TitlePrimaryAction", true, false) != null, "Title 只有一个高饱和主操作")
	var title_text := ""
	for node: Node in app._screen.find_children("*", "Label", true, false):
		title_text += (node as Label).text
	check(not title_text.contains("M2") and not title_text.contains("Gate") and not title_text.contains("BLOCKED"), "Title 不暴露开发阶段语言")
	# Title → Slot（新游戏）→ 槽 2 → Campaign
	app._show_slots(true)
	check_eq(app._state, app.State.SLOT, "进入选槽")
	app._new_game_slot(2)
	check_eq(app._state, app.State.CAMPAIGN, "新档后进战役选关")
	check_eq(CampaignService.current_slot, 2, "当前槽 = 2")
	check(app._screen.find_child("CampaignHarborMap", true, false) != null, "Campaign 使用可探索港口画卷")
	# 锁定列表呈现：c01 可选、c02 锁定且按钮 disabled（PRD §12.3 不可操作显示原因）
	var c01_btn := app._screen.find_child("Level_level_c01", true, false) as Button
	var c02_btn := app._screen.find_child("Level_level_c02", true, false) as Button
	check(c01_btn != null and not c01_btn.disabled, "c01 可选")
	check(c02_btn != null and c02_btn.disabled, "c02 锁定不可点")
	# 历史成绩不得覆盖锁定原因（例如旧档/回退后的 marks >= 0 但当前仍锁定）。
	var locked_chart := C01CampaignChart.new()
	locked_chart.c02_unlocked = false
	locked_chart.c02_marks = 2
	locked_chart.build_ports()
	var locked_c02 := locked_chart.find_child("Level_level_c02", true, false) as Button
	check(locked_c02 != null and locked_c02.text.contains(LocalizationService.tr_key(&"FLOW_LOCKED")), "有历史印记时锁定原因仍可见")
	locked_chart.free()
	# Campaign → Briefing → Battle
	app._select_level(&"level_c01")
	check_eq(app._state, app.State.BRIEFING, "进入战前简报")
	check(app._screen.find_child("BriefingHarborView", true, false) != null, "Briefing 使用不对称港口望景")
	check(app._screen.find_child("Enemy_salt_shell_walker", true, false) != null, "Briefing 展示盐壳行者轮廓")
	check(app._screen.find_child("Enemy_mast_rat_swarm", true, false) != null, "Briefing 展示桅鼠群轮廓")
	app._enter_battle(false)
	check_eq(app._state, app.State.BATTLE, "进入战斗")
	check(app._battle != null and app._battle.flow_managed, "战斗由 Flow 托管")
	check_eq(String(app._battle._level_id), "level_c01", "战斗载入 c01")
	_force_ready_once(app._battle)
	_force_descendants_ready(app._battle)
	# 审查断言：写档信号 / battle_finished 各恰好一次（唯一写档入口）
	var write_count := [0]
	var finish_count := [0]
	CampaignService.campaign_changed.connect(func() -> void: write_count[0] += 1)
	app._battle.battle_finished.connect(func(_r: Dictionary) -> void: finish_count[0] += 1)
	# Battle → Result（玩家路径：all_waves_completed → _enter_win）
	app._battle._enter_win()
	check_eq(finish_count[0], 1, "battle_finished 恰好发出一次")
	check_eq(write_count[0], 1, "flow 结算写档恰好一次（main 不重复写）")
	check_eq(app._state, app.State.RESULT, "胜利后进 Result 状态")
	check(app._screen.find_child("ResultBeacon", true, false) != null, "Result 以重新亮起的航标为主体")
	check(app._screen.find_child("ResultBigStats", true, false) != null, "Result 使用三个大数字而非统计弹窗")
	check(bool(app._last_result.get("won", false)), "结果为胜")
	check_eq(String(app._last_result.get("next_level_id", "")), "level_c02", "结果携带下一关（AppFlow 写档回填）")
	check(CampaignService.is_unlocked(&"level_c02"), "槽 2 解锁 c02（Flow 路径写档）")
	# Result「下一关」→ c02 简报
	var next_btn := app._screen.find_child("NextLevel", true, false) as Button
	check(next_btn != null, "Result 有下一关按钮")
	next_btn.pressed.emit()
	check_eq(app._state, app.State.BRIEFING, "下一关进简报")
	check_eq(CampaignService.selected_level, &"level_c02", "选中 c02")
	# 战斗中「返回战役」（暂停菜单出口）
	app._enter_battle(false)
	check_eq(app._state, app.State.BATTLE, "再次进入战斗（c02）")
	_force_ready_once(app._battle)
	_force_descendants_ready(app._battle)
	app._battle._on_pause_exit_to_campaign()
	check_eq(app._state, app.State.CAMPAIGN, "返回战役")
	var c02_btn_after := app._screen.find_child("Level_level_c02", true, false) as Button
	check(c02_btn_after != null and not c02_btn_after.disabled, "c02 在战役列表已解锁")
	# 英雄选择：c05 允许两英雄，解锁后可在简报切换
	CampaignService.record_battle_result(&"level_c02", {"won": true, "integrity": 18, "kills": 100, "mark_count": 2})
	CampaignService.record_battle_result(&"level_c03", {"won": true, "integrity": 18, "kills": 100, "mark_count": 2})
	CampaignService.record_battle_result(&"level_c04", {"won": true, "integrity": 18, "kills": 100, "mark_count": 2})
	app._show_campaign()
	app._select_level(&"level_c05")
	check_eq(app._state, app.State.BRIEFING, "c05 简报")
	check_eq(CampaignService.selected_hero, &"hero_lanzhou_wei", "默认英雄为允许名单第一名")
	check(CampaignService.select_hero(&"hero_zhushou_muen"), "可切换穆恩")
	check(not CampaignService.select_hero(&"hero_lanzhou_wei_x"), "非法英雄拒绝")
	app.free()

func test_c01_raster_sprite_contract() -> void:
	check(FileAccess.file_exists("res://scripts/ui/c01_sprite_library.gd"), "C01 有集中式栅格精灵库")
	var enemy_src := FileAccess.get_file_as_string("res://scripts/combat/greybox_enemy.gd")
	var tower_src := FileAccess.get_file_as_string("res://scripts/combat/greybox_tower.gd")
	var map_src := FileAccess.get_file_as_string("res://scripts/boot/greybox_map.gd")
	var harbor_src := FileAccess.get_file_as_string("res://scripts/ui/c01_harbor_art.gd")
	var campaign_src := FileAccess.get_file_as_string("res://scripts/ui/c01_campaign_chart.gd")
	check(enemy_src.contains("C01SpriteLibrary"), "C01 敌人主体由栅格精灵绘制")
	check(tower_src.contains("C01SpriteLibrary"), "C01 防御塔主体由栅格精灵绘制")
	check(map_src.contains("C01SpriteLibrary"), "C01 战场地形与舰队接入栅格精灵")
	check(harbor_src.contains("C01SpriteLibrary"), "完整 C01 产品流程复用同一精灵语言")
	check(not campaign_src.contains("draw_colored_polygon") and not campaign_src.contains("draw_circle("), "Campaign 不再以程序化几何图形主导港图")
	check(FileAccess.file_exists("res://assets/art/c01/runtime/enemy_salt_shell.png"), "盐壳行者派生精灵表存在")
	check(FileAccess.file_exists("res://assets/art/c01/runtime/enemy_mast_rat.png"), "桅鼠群派生精灵表存在")
	check(FileAccess.file_exists("res://assets/art/c01/runtime/tower_needle_rail.png"), "针轨塔派生精灵表存在")
	check(FileAccess.file_exists("res://assets/art/c01/runtime/harbor_props.png"), "港口环境派生精灵图集存在")
