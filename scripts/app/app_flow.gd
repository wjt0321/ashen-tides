extends Control
## AppFlow：应用流程外壳（M2 Flow Shell 第一批；PRD §12.1 / OPEN_SOURCE_TD_RESEARCH §3.3）。
## 状态机：Boot → Title ↔ Slot ↔ Campaign ↔ Briefing → Battle → Result。
## 边界：Flow 决定"玩家在哪里"，Battle 只决定一局发生什么；解锁由 CampaignService 决定，
## 资源解析由 ContentCatalog 决定。程序化 Control UI（本批不做美术）。
## CLI（--m1-smoke / --level / --m2-perf 等）直入 Battle，但关卡校验/写档仍走同一服务入口。

enum State { BOOT, TITLE, SLOT, CAMPAIGN, BRIEFING, BATTLE, RESULT }

const BATTLE_SCENE: String = "res://scenes/boot/main.tscn"
## 这些 CLI 参数表示"直入战斗"（CLI harness 与玩家 UI 共用 ContentCatalog/CampaignService）
const CLI_BATTLE_PREFIXES: Array[String] = [
	"--level=", "--hero=", "--speed=", "--stop-after-wave=", "--resume-suspend",
	"--m1-smoke", "--m3-smoke", "--m2-perf", "--m3-perf", "--m1-soak=",
	"--m2-record=", "--m0-screenshot=", "--shot-at-wave=", "--build=",
	"--font-test=", "--asset-trial",
]

var _state: State = State.BOOT
var _screen: Control = null ## 当前 UI 屏（BATTLE 时为 null）
var _battle: Node2D = null ## 战斗场景实例（scenes/boot/main.tscn）
var _settings_panel: SettingsPanel = null
var _slot_mode_new: bool = false ## SLOT 屏模式：true=新游戏选槽 / false=继续选槽
var _pending_overwrite_slot: int = 0 ## 覆盖二次确认中的槽位（PRD §12.3）
var _last_result: Dictionary = {}
var _flow_shot_path: String = "" ## --flow-screenshot=<path>：Title 截图证据后退出


func _ready() -> void:
	print("[M2-FLOW] AppFlow boot")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--flow-screenshot="):
			_flow_shot_path = arg.trim_prefix("--flow-screenshot=")
	if _cli_wants_battle():
		_enter_battle_cli()
		return
	_show_title()
	if not _flow_shot_path.is_empty():
		_capture_flow_screenshot()


# ---------------------------------------------------------------------------
# CLI 直进战斗（E：与玩家 UI 同一 ContentCatalog/CampaignService 入口）
# ---------------------------------------------------------------------------

func _cli_wants_battle() -> bool:
	for arg: String in OS.get_cmdline_user_args():
		for prefix: String in CLI_BATTLE_PREFIXES:
			if arg.begins_with(prefix):
				return true
	return false


func _enter_battle_cli() -> void:
	# 关卡 id 经 ContentCatalog 校验（CLI 不再绕过目录）；非法 id 直接失败退出，便于 CI 发现
	var level_id := ContentCatalog.first_level_id()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			var requested := StringName(arg.trim_prefix("--level="))
			if ContentCatalog.is_valid_level(requested):
				level_id = requested
			else:
				push_error("[M2-FLOW] unknown --level=%s（ContentCatalog 无此 id）" % requested)
				get_tree().quit(2)
				return
	_state = State.BATTLE
	_battle = (load(BATTLE_SCENE) as PackedScene).instantiate()
	_battle._level_id = level_id
	# flow_managed 保持 false：CLI/冒烟/截图/浸泡走战斗内置面板与报告逻辑（历史行为不变）
	add_child(_battle)
	move_child(_battle, 0)
	print("[M2-FLOW] CLI direct battle: level=%s" % level_id)


# ---------------------------------------------------------------------------
# 屏切换基础
# ---------------------------------------------------------------------------

func _clear_screen() -> void:
	if _screen != null:
		_screen.queue_free()
		_screen = null


func _set_screen(screen: Control, state: State) -> void:
	_clear_screen()
	_screen = screen
	_state = state
	add_child(_screen)


func _make_screen() -> VBoxContainer:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT) # 注意：直接赋值 anchors_preset 伪属性不生效
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 8)
	return root


func _make_label(text: String, font_size: int = 14) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 24)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return btn


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# Esc 逐级返回；BATTLE 内 Esc 由战斗暂停菜单消费
	match _state:
		State.SLOT, State.CAMPAIGN:
			_show_title()
		State.BRIEFING:
			_show_campaign()
		State.RESULT:
			_show_campaign()
		_:
			return
	get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Title
# ---------------------------------------------------------------------------

func _show_title() -> void:
	var screen := _make_screen()
	screen.add_child(_make_label(LocalizationService.tr_key(&"GAME_TITLE"), 28))
	var has_any_save := false
	for slot: int in CampaignService.SLOTS:
		if CampaignService.has_save(slot):
			has_any_save = true
	var new_btn := _make_button(LocalizationService.tr_key(&"FLOW_NEW_GAME"))
	new_btn.pressed.connect(func() -> void: _show_slots(true))
	screen.add_child(new_btn)
	var continue_btn := _make_button(LocalizationService.tr_key(&"MENU_CONTINUE"))
	continue_btn.name = "ContinueBtn"
	continue_btn.disabled = not has_any_save
	if not has_any_save:
		continue_btn.text += " (%s)" % LocalizationService.tr_key(&"FLOW_NO_SAVE")
	continue_btn.pressed.connect(func() -> void: _show_slots(false))
	screen.add_child(continue_btn)
	var settings_btn := _make_button(LocalizationService.tr_key(&"MENU_SETTINGS"))
	settings_btn.pressed.connect(_open_settings)
	screen.add_child(settings_btn)
	var quit_btn := _make_button(LocalizationService.tr_key(&"FLOW_EXIT_GAME"))
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
	screen.add_child(quit_btn)
	_set_screen(screen, State.TITLE)


func _open_settings() -> void:
	if _settings_panel == null:
		_settings_panel = SettingsPanel.new()
		_settings_panel.name = "Settings"
		add_child(_settings_panel)
		_settings_panel.closed.connect(func() -> void: pass) # 屏保留在下层，无需切状态
	_settings_panel.open()


# ---------------------------------------------------------------------------
# Slot（3 手动战役槽，PRD §15.1；覆盖需二次确认，PRD §12.3）
# ---------------------------------------------------------------------------

func _show_slots(new_mode: bool) -> void:
	_slot_mode_new = new_mode
	_pending_overwrite_slot = 0
	var screen := _make_screen()
	screen.add_child(_make_label(LocalizationService.tr_key(&"FLOW_SLOT_TITLE"), 20))
	for slot: int in CampaignService.SLOTS:
		var meta := CampaignService.slot_meta(slot)
		var btn: Button
		if bool(meta.get("exists", false)):
			btn = _make_button(LocalizationService.tr_key(&"FLOW_SLOT_META") % [
				slot, int(meta.get("completed_count", 0)), int(meta.get("marks_total", 0)),
				String(meta.get("updated_at_utc", "")).left(16),
			])
			if new_mode:
				btn.pressed.connect(func() -> void: _ask_overwrite(slot))
			else:
				btn.pressed.connect(func() -> void: _continue_slot(slot))
		else:
			btn = _make_button(LocalizationService.tr_key(&"FLOW_SLOT_EMPTY") % slot)
			if new_mode:
				btn.pressed.connect(func() -> void: _new_game_slot(slot))
			else:
				btn.disabled = true
		screen.add_child(btn)
	# 覆盖确认行（默认隐藏）
	var confirm_label := _make_label("", 12)
	confirm_label.name = "ConfirmLabel"
	confirm_label.visible = false
	screen.add_child(confirm_label)
	var confirm_row := HBoxContainer.new()
	confirm_row.name = "ConfirmRow"
	confirm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_row.visible = false
	var yes_btn := _make_button(LocalizationService.tr_key(&"FLOW_CONFIRM_YES"))
	yes_btn.custom_minimum_size = Vector2(120, 24)
	yes_btn.pressed.connect(func() -> void: _new_game_slot(_pending_overwrite_slot))
	var no_btn := _make_button(LocalizationService.tr_key(&"FLOW_CANCEL"))
	no_btn.custom_minimum_size = Vector2(120, 24)
	no_btn.pressed.connect(func() -> void: _show_slots(_slot_mode_new))
	confirm_row.add_child(yes_btn)
	confirm_row.add_child(no_btn)
	screen.add_child(confirm_row)
	var back_btn := _make_button(LocalizationService.tr_key(&"FLOW_BACK"))
	back_btn.pressed.connect(_show_title)
	screen.add_child(back_btn)
	_set_screen(screen, State.SLOT)


func _ask_overwrite(slot: int) -> void:
	_pending_overwrite_slot = slot
	var confirm_label := _screen.get_node_or_null("ConfirmLabel") as Label
	var confirm_row := _screen.get_node_or_null("ConfirmRow") as Control
	if confirm_label != null:
		confirm_label.text = LocalizationService.tr_key(&"FLOW_CONFIRM_OVERWRITE")
		confirm_label.visible = true
	if confirm_row != null:
		confirm_row.visible = true


func _new_game_slot(slot: int) -> void:
	# 原子语义（红队 S2）：写档失败停留选槽页并显示本地化错误，不进战役
	if CampaignService.new_game(slot):
		_show_campaign()
	else:
		_show_slot_save_error()


func _continue_slot(slot: int) -> void:
	if CampaignService.continue_game(slot):
		_show_campaign()
	else:
		_show_slot_save_error()


## 选槽页保存/读取失败提示：停留当前安全页面（PRD §12.3 不可静默失败）。
func _show_slot_save_error() -> void:
	_show_slots(_slot_mode_new)
	var confirm_label := _screen.get_node_or_null("ConfirmLabel") as Label
	if confirm_label != null:
		confirm_label.text = LocalizationService.tr_key(&"FLOW_SAVE_FAILED")
		confirm_label.visible = true


# ---------------------------------------------------------------------------
# Campaign（选关：锁定列表 + 印记展示）
# ---------------------------------------------------------------------------

func _show_campaign() -> void:
	var screen := _make_screen()
	screen.add_child(_make_label(LocalizationService.tr_key(&"FLOW_CAMPAIGN_HEADER") % [
		CampaignService.current_slot, CampaignService.total_marks()
	], 18))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 220)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 2)
	scroll.add_child(list)
	for id: Variant in ContentCatalog.all_level_ids():
		var level_id := StringName(String(id))
		var level := ContentCatalog.level(level_id)
		if level == null:
			continue
		var unlocked := CampaignService.is_unlocked(level_id)
		var text := LocalizationService.tr_key(level.display_name_key)
		var result := CampaignService.level_result(level_id)
		if not result.is_empty():
			text += "  ·  " + LocalizationService.tr_key(&"FLOW_MARKS_FMT") % int(result.get("marks", 0))
		var btn := _make_button(text)
		btn.name = "Level_%s" % level_id # 稳定节点名：测试与手柄焦点定位用
		btn.custom_minimum_size = Vector2(400, 22)
		if not unlocked:
			btn.disabled = true
			btn.text += "  (%s)" % LocalizationService.tr_key(&"FLOW_LOCKED") # 不可操作要显示原因（PRD §12.3）
		else:
			btn.pressed.connect(func() -> void: _select_level(level_id))
		list.add_child(btn)
	screen.add_child(scroll)
	var back_btn := _make_button(LocalizationService.tr_key(&"FLOW_BACK"))
	back_btn.pressed.connect(_show_title)
	screen.add_child(back_btn)
	_set_screen(screen, State.CAMPAIGN)


func _select_level(level_id: StringName) -> void:
	if CampaignService.select_level(level_id):
		_show_briefing()


# ---------------------------------------------------------------------------
# Briefing（战前简报 + 英雄选择 + suspend 恢复入口）
# ---------------------------------------------------------------------------

func _show_briefing() -> void:
	var level := ContentCatalog.level(CampaignService.selected_level)
	if level == null:
		_show_campaign()
		return
	var screen := _make_screen()
	screen.add_child(_make_label("%s — %s" % [
		LocalizationService.tr_key(&"FLOW_BRIEFING_TITLE"), LocalizationService.tr_key(level.display_name_key)
	], 18))
	screen.add_child(_make_label(LocalizationService.tr_key(&"FLOW_BRIEFING_INFO") % [
		level.waves.size(), level.initial_ember, level.initial_fleet_integrity
	], 12))
	if level.strategy_objective_key != &"":
		screen.add_child(_make_label(LocalizationService.tr_key(level.strategy_objective_key), 11))
	# 英雄选择（该关 allowed_heroes；两英雄时玩家可选）
	if not level.allowed_heroes.is_empty():
		screen.add_child(_make_label(LocalizationService.tr_key(&"FLOW_HERO_SELECT"), 13))
		var hero_row := HBoxContainer.new()
		hero_row.alignment = BoxContainer.ALIGNMENT_CENTER
		for hero_id: Variant in level.allowed_heroes:
			var hero := ContentCatalog.hero(hero_id)
			if hero == null:
				continue
			var hero_btn := _make_button("")
			hero_btn.custom_minimum_size = Vector2(140, 24)
			hero_btn.name = "Hero_%s" % hero_id
			hero_btn.pressed.connect(func() -> void:
				CampaignService.select_hero(hero_id)
				_show_briefing())
			hero_row.add_child(hero_btn)
		screen.add_child(hero_row)
		_refresh_hero_buttons(screen, level)
	# suspend 恢复入口（PRD §15.2：继续 / 放弃本局——放弃 = 直接开始新战斗）
	var suspend := SaveService.read_suspend()
	if not suspend.is_empty() and String(suspend.get("level_id", "")) == String(level.id):
		var resume_btn := _make_button(LocalizationService.tr_key(&"FLOW_RESUME_BATTLE") % int(suspend.get("completed_waves", 0)))
		resume_btn.name = "ResumeBattle"
		resume_btn.pressed.connect(func() -> void: _enter_battle(true))
		screen.add_child(resume_btn)
	var start_btn := _make_button(LocalizationService.tr_key(&"FLOW_START_BATTLE"))
	start_btn.name = "StartBattle"
	start_btn.pressed.connect(func() -> void: _enter_battle(false))
	screen.add_child(start_btn)
	var back_btn := _make_button(LocalizationService.tr_key(&"FLOW_BACK"))
	back_btn.pressed.connect(_show_campaign)
	screen.add_child(back_btn)
	_set_screen(screen, State.BRIEFING)


func _refresh_hero_buttons(screen: Control, level: LevelData) -> void:
	for hero_id: Variant in level.allowed_heroes:
		var hero := ContentCatalog.hero(hero_id)
		var hero_btn := screen.find_child("Hero_%s" % hero_id, true, false) as Button
		if hero == null or hero_btn == null:
			continue
		var selected: bool = hero_id == CampaignService.selected_hero
		hero_btn.text = ("✓ " if selected else "") + LocalizationService.tr_key(hero.display_name_key)


# ---------------------------------------------------------------------------
# Battle / Result
# ---------------------------------------------------------------------------

func _enter_battle(resume_suspend: bool) -> void:
	var level_id := CampaignService.selected_level
	var hero_id := CampaignService.selected_hero
	_clear_screen()
	_state = State.BATTLE
	_battle = (load(BATTLE_SCENE) as PackedScene).instantiate()
	_battle.flow_managed = true
	_battle._level_id = level_id # 在 add_child 触发 _ready 前注入（_ready 读取）
	_battle._hero_override = hero_id
	_battle._resume_suspend = resume_suspend
	_battle.battle_finished.connect(_on_battle_finished)
	_battle.battle_exit_requested.connect(_on_battle_exit)
	add_child(_battle)
	move_child(_battle, 0)
	print("[M2-FLOW] battle start: level=%s hero=%s resume=%s slot=%d" % [
		level_id, hero_id, resume_suspend, CampaignService.current_slot
	])


func _on_battle_finished(result: Dictionary) -> void:
	_last_result = result
	# Flow 托管：结算写档唯一入口（main._enter_win 在 flow_managed 下不写档）。
	# CampaignService 推进解锁与印记（PRD §15.1），返回的下一关 id 写入结果供 Result 屏「下一关」展示。
	var selected_level := CampaignService.selected_level
	if selected_level != &"" and bool(result.get("won", false)):
		var next_id := CampaignService.record_battle_result(selected_level, result)
		if CampaignService.last_error == OK:
			_last_result["next_level_id"] = String(next_id)
		else:
			# 写档失败：不解锁/不显示下一关，Result 屏显示保存失败（红队 S2）
			_last_result["save_failed"] = true
	if _battle != null:
		_battle.queue_free() # 信号自战斗内部发出，延迟到帧尾销毁
		_battle = null
	_show_result()


func _on_battle_exit() -> void:
	if _battle != null:
		_battle.queue_free()
		_battle = null
	_show_campaign()


func _show_result() -> void:
	var won := bool(_last_result.get("won", false))
	var screen := _make_screen()
	screen.add_child(_make_label(LocalizationService.tr_key(&"RESULT_WIN") if won else LocalizationService.tr_key(&"RESULT_LOSE"), 22))
	screen.add_child(_make_label("%s %d/3 | %s %d | %s %d | %s %d" % [
		LocalizationService.tr_key(&"RESULT_MARKS"), int(_last_result.get("mark_count", 0)),
		LocalizationService.tr_key(&"RESULT_INTEGRITY"), int(_last_result.get("integrity", 0)),
		LocalizationService.tr_key(&"RESULT_KILLS"), int(_last_result.get("kills", 0)),
		LocalizationService.tr_key(&"RESULT_LEAKS"), int(_last_result.get("leaks", 0)),
	], 12))
	if bool(_last_result.get("save_failed", false)):
		var err_label := _make_label(LocalizationService.tr_key(&"FLOW_SAVE_FAILED"), 12)
		err_label.name = "SaveFailedLabel"
		screen.add_child(err_label)
	var next_id := StringName(String(_last_result.get("next_level_id", "")))
	if won and next_id != &"":
		var next_btn := _make_button(LocalizationService.tr_key(&"MENU_NEXT_LEVEL"))
		next_btn.name = "NextLevel"
		next_btn.pressed.connect(func() -> void:
			if CampaignService.select_level(next_id):
				_show_briefing())
		screen.add_child(next_btn)
	var retry_btn := _make_button(LocalizationService.tr_key(&"MENU_RESTART"))
	retry_btn.name = "Retry"
	retry_btn.pressed.connect(func() -> void: _enter_battle(false))
	screen.add_child(retry_btn)
	var campaign_btn := _make_button(LocalizationService.tr_key(&"MENU_EXIT_TO_CAMPAIGN"))
	campaign_btn.pressed.connect(_show_campaign)
	screen.add_child(campaign_btn)
	_set_screen(screen, State.RESULT)


# ---------------------------------------------------------------------------
# 证据：--flow-screenshot=<path>（Title 屏截图后退出）
# ---------------------------------------------------------------------------

func _capture_flow_screenshot() -> void:
	for i: int in 5:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(_flow_shot_path)
	print("[M2-FLOW] flow screenshot saved: %s (err=%d)" % [_flow_shot_path, err])
	get_tree().quit()
