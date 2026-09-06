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
var _flow_shot_path: String = "" ## --flow-screenshot=<path>：玩家外壳截图证据后退出
var _flow_shot_screen: StringName = &"title" ## --flow-screen=title|slot|campaign|briefing|result


func _ready() -> void:
	print("[M2-FLOW] AppFlow boot user_args=%s" % [OS.get_cmdline_user_args()])
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--flow-screenshot="):
			_flow_shot_path = arg.trim_prefix("--flow-screenshot=")
		elif arg.begins_with("--flow-screen="):
			_flow_shot_screen = StringName(arg.trim_prefix("--flow-screen=").to_lower())
	if _cli_wants_battle():
		_enter_battle_cli()
		return
	_show_flow_shot_screen() if not _flow_shot_path.is_empty() else _show_title()
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


## C01 Style Bible 屏根：背景 + 居中内容容器。
## 背景固定在 z=0，screen 在 z=1 居中。
func _make_screen(mode: int = C01HarborArt.Mode.TITLE) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var art := C01HarborArt.new()
	art.name = "C01HarborArt"
	art.mode = mode
	root.add_child(art)
	# 页面内容直接叠在港口构图上；不再创建中央 FlowPanel。
	var content := VBoxContainer.new()
	content.name = "FlowContent"
	content.position = Vector2(40, 20)
	content.size = Vector2(560, 320)
	content.custom_minimum_size = Vector2(560, 320)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(content)
	return root


func _screen_content() -> VBoxContainer:
	if _screen == null:
		return null
	return _screen.get_node_or_null("FlowContent") as VBoxContainer


func _make_label(text: String, font_size: int = 14) -> Label:
	var l := StyleManager.make_label(text, font_size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _make_button(text: String) -> Button:
	var btn := StyleManager.make_brass_button(text, 220)
	return btn


## 接入 Kenney UI Audio：select/confirm/cancel/error/transition。
## 由 AudioService 在 _ready 时加载 .ogg（资源缺失时回退占位合成，不破坏离线模式）。

func _poster_stage(name: String) -> Control:
	var stage := Control.new()
	stage.name = name
	stage.custom_minimum_size = Vector2(560, 320)
	stage.size = Vector2(560, 320)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return stage

func _poster_label(text: String, pos: Vector2, extent: Vector2, font_size: int, color: Color = StyleManager.COLOR_PARCHMENT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = extent
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.03, 0.04, 0.04, 0.88))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _poster_button(text: String, pos: Vector2, extent: Vector2, primary: bool = false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = extent
	btn.custom_minimum_size = extent
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_size_override("font_size", 16 if primary else 12)
	var states: Array[String] = ["normal", "hover", "pressed", "disabled", "focus"]
	for state: String in states:
		var sb := StyleBoxFlat.new()
		if primary:
			sb.bg_color = Color("ef684b") if state != "pressed" else Color("c84c39")
			sb.border_color = Color("ffd09a") if state == "hover" or state == "focus" else Color("74352e")
			sb.set_border_width_all(2 if state == "hover" or state == "focus" else 1)
			sb.corner_radius_top_left = 2
			sb.corner_radius_top_right = 9
			sb.corner_radius_bottom_left = 9
			sb.corner_radius_bottom_right = 2
		else:
			sb.bg_color = Color(0.06, 0.08, 0.08, 0.58 if state == "hover" or state == "focus" else 0.18)
			sb.border_color = Color("b8c5b8", 0.42 if state == "hover" or state == "focus" else 0.0)
			sb.set_border_width_all(1 if state == "hover" or state == "focus" else 0)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		btn.add_theme_stylebox_override(state, sb)
	btn.add_theme_color_override("font_color", Color("1d2020") if primary else StyleManager.COLOR_PARCHMENT)
	btn.add_theme_color_override("font_hover_color", Color("101414") if primary else Color("ffd4b2"))
	btn.add_theme_color_override("font_pressed_color", Color("101414") if primary else StyleManager.COLOR_CORAL)
	btn.add_theme_color_override("font_disabled_color", Color("78817b"))
	return btn

func _ui_play(action: StringName) -> void:
	if AudioService != null and AudioService.has_method("play_ui_event"):
		AudioService.play_ui_event(action)


func _wire_ui_audio(btn: Button, kind: StringName = &"ui_select") -> void:
	# press 触发 confirm；focus_entered 触发 select
	btn.focus_entered.connect(func() -> void: _ui_play(kind))
	btn.pressed.connect(func() -> void: _ui_play(&"ui_confirm"))


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# Esc 逐级返回；BATTLE 内 Esc 由战斗暂停菜单消费
	match _state:
		State.SLOT, State.CAMPAIGN:
			_ui_play(&"ui_cancel")
			_show_title()
		State.BRIEFING:
			_ui_play(&"ui_cancel")
			_show_campaign()
		State.RESULT:
			_ui_play(&"ui_cancel")
			_show_campaign()
		_:
			return
	get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Title
# ---------------------------------------------------------------------------

func _show_title() -> void:
	var screen := _make_screen(C01HarborArt.Mode.TITLE)
	_set_screen(screen, State.TITLE)
	var stage := _poster_stage("TitlePoster")
	_screen_content().add_child(stage)
	stage.add_child(_poster_label("余烬潮汐", Vector2(238, 44), Vector2(310, 48), 34, StyleManager.COLOR_PARCHMENT))
	stage.add_child(_poster_label("ASHEN TIDES", Vector2(242, 91), Vector2(260, 24), 14, StyleManager.COLOR_CORAL))
	stage.add_child(_poster_label("守住最后一盏港灯，让迁徙舰队穿过暮潮。", Vector2(242, 119), Vector2(294, 50), 13, Color("c9d0c3")))
	var has_any_save := false
	for slot: int in CampaignService.SLOTS:
		if CampaignService.has_save(slot):
			has_any_save = true
	var marker := Control.new()
	marker.name = "TitlePrimaryAction"
	stage.add_child(marker)
	var new_btn := _poster_button("启航", Vector2(242, 204 if not has_any_save else 252), Vector2(196, 42 if not has_any_save else 28), not has_any_save)
	new_btn.name = "NewGameBtn"
	_wire_ui_audio(new_btn)
	new_btn.pressed.connect(func() -> void:
		_ui_play(&"ui_confirm")
		_show_slots(true))
	stage.add_child(new_btn)
	var continue_btn := _poster_button(LocalizationService.tr_key(&"MENU_CONTINUE") if has_any_save else LocalizationService.tr_key(&"FLOW_NO_SAVE"), Vector2(242, 204 if has_any_save else 252), Vector2(196, 42 if has_any_save else 28), has_any_save)
	continue_btn.name = "ContinueBtn"
	continue_btn.disabled = not has_any_save
	_wire_ui_audio(continue_btn)
	continue_btn.pressed.connect(func() -> void:
		_ui_play(&"ui_confirm")
		_show_slots(false))
	stage.add_child(continue_btn)
	var settings_btn := _poster_button(LocalizationService.tr_key(&"MENU_SETTINGS"), Vector2(446, 274), Vector2(54, 24))
	settings_btn.name = "SettingsBtn"
	_wire_ui_audio(settings_btn)
	settings_btn.pressed.connect(_open_settings)
	stage.add_child(settings_btn)
	var quit_btn := _poster_button(LocalizationService.tr_key(&"FLOW_EXIT_GAME"), Vector2(502, 274), Vector2(54, 24))
	quit_btn.name = "QuitBtn"
	_wire_ui_audio(quit_btn)
	quit_btn.pressed.connect(func() -> void:
		_ui_play(&"ui_cancel")
		get_tree().quit())
	stage.add_child(quit_btn)


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
	var screen := _make_screen(C01HarborArt.Mode.SLOT)
	_set_screen(screen, State.SLOT)
	var content := _screen_content()
	# 标题 + 返回行
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	var back_arrow := StyleManager.make_arrow_w(16)
	title_row.add_child(back_arrow)
	var title := StyleManager.make_subtitle(LocalizationService.tr_key(&"FLOW_SLOT_TITLE"))
	title_row.add_child(title)
	content.add_child(title_row)
	# 3 卡片水平布局
	var cards := HBoxContainer.new()
	cards.name = "SlotCards"
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 8)
	content.add_child(cards)
	for slot: int in CampaignService.SLOTS:
		var card := _make_slot_card(slot, new_mode)
		cards.add_child(card)
	# 覆盖确认行（默认隐藏）
	var confirm_label := StyleManager.make_small("")
	confirm_label.name = "ConfirmLabel"
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.visible = false
	content.add_child(confirm_label)
	var confirm_row := HBoxContainer.new()
	confirm_row.name = "ConfirmRow"
	confirm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_row.visible = false
	var yes_btn := StyleManager.make_brass_button(LocalizationService.tr_key(&"FLOW_CONFIRM_YES"), 120)
	yes_btn.pressed.connect(func() -> void: _new_game_slot(_pending_overwrite_slot))
	var no_btn := StyleManager.make_round_button(LocalizationService.tr_key(&"FLOW_CANCEL"), 120)
	no_btn.pressed.connect(func() -> void: _show_slots(_slot_mode_new))
	confirm_row.add_child(yes_btn)
	confirm_row.add_child(no_btn)
	content.add_child(confirm_row)
	var back_btn := StyleManager.make_round_button(LocalizationService.tr_key(&"FLOW_BACK"), 120)
	_wire_ui_audio(back_btn, &"ui_cancel")
	back_btn.pressed.connect(_show_title)
	content.add_child(back_btn)


## 单张槽位卡（C01 Style Bible §3.2）：Kenney 9-slice 蓝底 + 章标 / profile / 通关数 / 印记
func _make_slot_card(slot: int, new_mode: bool) -> PanelContainer:
	var meta := CampaignService.slot_meta(slot)
	var occupied := bool(meta.get("exists", false))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 220)
	# 底图（Kenney 9-slice）
	var t: Texture2D = StyleManager.tex(StyleManager.PATH_BTN_BORDER)
	var sb: StyleBox = null
	if t != null:
		sb = StyleBoxTexture.new()
	else:
		sb = StyleBoxFlat.new()
	if t != null:
		sb.texture = t
		sb.region_rect = Rect2(0, 0, t.get_width(), t.get_height())
		sb.modulate_color = StyleManager.BTN_MOD_NORMAL if occupied else StyleManager.BTN_MOD_LOCKED
	else:
		sb.bg_color = StyleManager.CARD_NORMAL if occupied else StyleManager.CARD_LOCKED
		sb.border_color = StyleManager.COLOR_BRASS
		sb.set_border_width_all(1)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", sb)
	# 内容
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	# 顶部行：章标 C## + 状态图标
	var top_row := HBoxContainer.new()
	var chapter := StyleManager.make_label("C%02d" % slot, StyleManager.FONT_SIZE_HEADING, StyleManager.COLOR_BRASS)
	top_row.add_child(chapter)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	var status_icon := StyleManager.make_node_marker(2 if occupied else 0, 18)
	top_row.add_child(status_icon)
	vbox.add_child(top_row)
	# profile id
	var profile_text := String(meta.get("profile_id", "—")) if occupied else LocalizationService.tr_key(&"FLOW_SLOT_EMPTY") % slot
	var profile_label := StyleManager.make_label(profile_text, StyleManager.FONT_SIZE_BODY, StyleManager.COLOR_PARCHMENT if occupied else StyleManager.COLOR_LOCKED)
	profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(profile_label)
	# 通关数 / 印记
	if occupied:
		var stats_hbox := HBoxContainer.new()
		stats_hbox.add_theme_constant_override("separation", 4)
		var completed_label := StyleManager.make_label("%d 通关" % int(meta.get("completed_count", 0)), StyleManager.FONT_SIZE_SMALL, StyleManager.COLOR_PARCHMENT)
		stats_hbox.add_child(completed_label)
		stats_hbox.add_child(Control.new())  # spacer
		var marks_label := StyleManager.make_label("%d 印" % int(meta.get("marks_total", 0)), StyleManager.FONT_SIZE_SMALL, StyleManager.COLOR_BRASS)
		stats_hbox.add_child(marks_label)
		vbox.add_child(stats_hbox)
	else:
		vbox.add_child(StyleManager.make_small("—", StyleManager.COLOR_LOCKED))
	# 主操作按钮
	var action_btn: Button
	if occupied:
		if new_mode:
			action_btn = StyleManager.make_round_button(LocalizationService.tr_key(&"FLOW_OVERWRITE_SHORT"), 140)
			action_btn.pressed.connect(func() -> void: _ask_overwrite(slot))
		else:
			action_btn = StyleManager.make_round_button(LocalizationService.tr_key(&"MENU_CONTINUE"), 140)
			action_btn.pressed.connect(func() -> void: _continue_slot(slot))
	else:
		if new_mode:
			action_btn = StyleManager.make_round_button(LocalizationService.tr_key(&"FLOW_NEW_GAME"), 140)
			action_btn.pressed.connect(func() -> void: _new_game_slot(slot))
		else:
			action_btn = StyleManager.make_round_button(LocalizationService.tr_key(&"MENU_CONTINUE"), 140)
			action_btn.disabled = true
	action_btn.custom_minimum_size = Vector2(140, 28)
	_wire_ui_audio(action_btn, &"ui_confirm")
	vbox.add_child(action_btn)
	return card


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
	var screen := _make_screen(C01HarborArt.Mode.CAMPAIGN)
	_set_screen(screen, State.CAMPAIGN)
	var stage := _poster_stage("CampaignPoster")
	_screen_content().add_child(stage)
	stage.add_child(_poster_label("离港海域", Vector2(0, 0), Vector2(220, 38), 23, StyleManager.COLOR_PARCHMENT))
	stage.add_child(_poster_label("沿舰队航迹选择下一处岸防。远海仍被暮潮遮蔽。", Vector2(0, 31), Vector2(390, 28), 12, Color("c0c9bd")))
	var chart := C01CampaignChart.new()
	chart.name = "CampaignHarborMap"
	chart.position = Vector2(0, 47)
	chart.size = Vector2(560, 230)
	chart.c01_unlocked = CampaignService.is_unlocked(&"level_c01")
	chart.c02_unlocked = CampaignService.is_unlocked(&"level_c02")
	var c01_result := CampaignService.level_result(&"level_c01")
	var c02_result := CampaignService.level_result(&"level_c02")
	chart.c01_marks = int(c01_result.get("marks", -1)) if not c01_result.is_empty() else -1
	chart.c02_marks = int(c02_result.get("marks", -1)) if not c02_result.is_empty() else -1
	chart.build_ports() # 测试与运行都立即建立稳定节点契约
	chart.level_chosen.connect(_select_level)
	stage.add_child(chart)
	var back_btn := _poster_button("← %s" % LocalizationService.tr_key(&"FLOW_BACK"), Vector2(0, 286), Vector2(106, 26))
	back_btn.name = "CampaignBack"
	_wire_ui_audio(back_btn, &"ui_cancel")
	back_btn.pressed.connect(_show_title)
	stage.add_child(back_btn)


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
	var screen := _make_screen(C01HarborArt.Mode.BRIEFING)
	_set_screen(screen, State.BRIEFING)
	var stage := _poster_stage("BriefingPoster")
	_screen_content().add_child(stage)
	var view_marker := Control.new()
	view_marker.name = "BriefingHarborView"
	stage.add_child(view_marker)
	stage.add_child(_poster_label(LocalizationService.tr_key(level.display_name_key), Vector2(0, 0), Vector2(360, 38), 24, StyleManager.COLOR_PARCHMENT))
	stage.add_child(_poster_label("出航前，最后一次望向港口。", Vector2(2, 32), Vector2(330, 24), 12, Color("c3cbc0")))
	var map := C01BriefingVisual.new()
	map.name = "C01BattlefieldSketch"
	map.kind = C01BriefingVisual.Kind.MAP
	map.position = Vector2(0, 52)
	map.size = Vector2(350, 236)
	stage.add_child(map)
	# 右侧信息只保留可行动的关键信息。
	stage.add_child(_poster_label("护航命令", Vector2(372, 0), Vector2(180, 28), 15, StyleManager.COLOR_CORAL))
	stage.add_child(_poster_label("守住舰队完整度\n%d 波敌潮\n至少完成一次升级" % level.waves.size(), Vector2(372, 28), Vector2(184, 72), 13, StyleManager.COLOR_PARCHMENT))
	var enemy_ids: Array[StringName] = []
	for w: Variant in level.waves:
		var wave := w as WaveData
		for g: Variant in wave.groups:
			var group := g as WaveGroup
			if not enemy_ids.has(group.enemy_id):
				enemy_ids.append(group.enemy_id)
	var enemy_x := 370.0
	for enemy_id: StringName in enemy_ids.slice(0, 2):
		var portrait := C01BriefingVisual.new()
		portrait.name = "Enemy_%s" % enemy_id
		portrait.kind = C01BriefingVisual.Kind.WALKER if enemy_id == &"salt_shell_walker" else C01BriefingVisual.Kind.RATS
		portrait.position = Vector2(enemy_x, 105)
		portrait.size = Vector2(82, 72)
		stage.add_child(portrait)
		var enemy_data := ContentCatalog.enemy(enemy_id)
		if enemy_data != null:
			stage.add_child(_poster_label(LocalizationService.tr_key(enemy_data.display_name_key), Vector2(enemy_x - 4, 174), Vector2(90, 24), 11, Color("d7ddcf"), HORIZONTAL_ALIGNMENT_CENTER))
		enemy_x += 94.0
	var tower_visual := C01BriefingVisual.new()
	tower_visual.name = "AvailableTowerVisual"
	tower_visual.kind = C01BriefingVisual.Kind.TOWER
	tower_visual.position = Vector2(372, 195)
	tower_visual.size = Vector2(72, 55)
	stage.add_child(tower_visual)
	var tower_name := "岸防"
	if not level.allowed_towers.is_empty():
		var tower := ContentCatalog.tower(level.allowed_towers[0])
		if tower != null:
			tower_name = LocalizationService.tr_key(tower.display_name_key)
	stage.add_child(_poster_label("%s\n本关可用" % tower_name, Vector2(446, 199), Vector2(110, 48), 12, StyleManager.COLOR_PARCHMENT))
	if level.allowed_heroes.is_empty():
		stage.add_child(_poster_label("本次护航由岸防独立完成", Vector2(372, 243), Vector2(184, 22), 11, Color("aebcb2")))
	else:
		var hero_x := 372.0
		for hero_id: Variant in level.allowed_heroes:
			var hero := ContentCatalog.hero(hero_id)
			if hero == null:
				continue
			var hero_btn := _poster_button(LocalizationService.tr_key(hero.display_name_key), Vector2(hero_x, 240), Vector2(88, 24))
			hero_btn.name = "Hero_%s" % hero_id
			hero_btn.pressed.connect(func() -> void:
				CampaignService.select_hero(hero_id)
				_refresh_hero_buttons(screen, level))
			stage.add_child(hero_btn)
			hero_x += 92.0
	if SaveService.has_suspend():
		var resume_btn := _poster_button(LocalizationService.tr_key(&"FLOW_RESUME_SUSPEND"), Vector2(370, 268), Vector2(88, 36), true)
		resume_btn.name = "ResumeBattle"
		_wire_ui_audio(resume_btn, &"ui_confirm")
		resume_btn.pressed.connect(func() -> void: _enter_battle(true))
		stage.add_child(resume_btn)
	var start_btn := _poster_button(LocalizationService.tr_key(&"FLOW_START_BATTLE"), Vector2(464, 268), Vector2(92, 36), true)
	start_btn.name = "StartBattle"
	_wire_ui_audio(start_btn, &"ui_confirm")
	start_btn.pressed.connect(func() -> void: _enter_battle(false))
	stage.add_child(start_btn)
	var back_btn := _poster_button("← %s" % LocalizationService.tr_key(&"FLOW_BACK"), Vector2(0, 290), Vector2(108, 24))
	back_btn.name = "BriefingBack"
	_wire_ui_audio(back_btn, &"ui_cancel")
	back_btn.pressed.connect(_show_campaign)
	stage.add_child(back_btn)
	_refresh_hero_buttons(screen, level)


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
	var mode := C01HarborArt.Mode.RESULT_WIN if won else C01HarborArt.Mode.RESULT_LOSE
	var screen := _make_screen(mode)
	_set_screen(screen, State.RESULT)
	var stage := _poster_stage("ResultPoster")
	_screen_content().add_child(stage)
	var beacon_marker := Control.new()
	beacon_marker.name = "ResultBeacon"
	stage.add_child(beacon_marker)
	stage.add_child(_poster_label("航标重燃" if won else "暮潮越港", Vector2(0, 5), Vector2(310, 46), 28, StyleManager.COLOR_PARCHMENT if won else Color("a8c7c3")))
	stage.add_child(_poster_label("舰队已穿过最后一道港火。" if won else "航标熄灭，舰队完整度耗尽。", Vector2(2, 48), Vector2(330, 30), 13, Color("c6cec0")))
	var marks_visual := C01BriefingVisual.new()
	marks_visual.name = "ResultMarks"
	marks_visual.kind = C01BriefingVisual.Kind.MARKS
	marks_visual.mark_count = int(_last_result.get("mark_count", 0))
	marks_visual.position = Vector2(0, 88)
	marks_visual.size = Vector2(142, 48)
	stage.add_child(marks_visual)
	stage.add_child(_poster_label("航海印记 %d/3" % int(_last_result.get("mark_count", 0)), Vector2(145, 88), Vector2(150, 42), 14, StyleManager.COLOR_CORAL))
	var stats := HBoxContainer.new()
	stats.name = "ResultBigStats"
	stats.position = Vector2(0, 166)
	stats.size = Vector2(355, 82)
	stats.add_theme_constant_override("separation", 18)
	stage.add_child(stats)
	var values: Array = [
		[int(_last_result.get("integrity", 0)), LocalizationService.tr_key(&"RESULT_INTEGRITY")],
		[int(_last_result.get("kills", 0)), LocalizationService.tr_key(&"RESULT_KILLS")],
		[int(round(float(_last_result.get("sim_seconds", 0.0)))), "秒"],
	]
	for pair: Array in values:
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(96, 76)
		var num := StyleManager.make_label(str(pair[0]), 30, StyleManager.COLOR_PARCHMENT)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(num)
		var cap := StyleManager.make_label(String(pair[1]), 11, Color("aebbb0"))
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(cap)
		stats.add_child(col)
	if bool(_last_result.get("save_failed", false)):
		stage.add_child(_poster_label(LocalizationService.tr_key(&"FLOW_SAVE_FAILED"), Vector2(0, 250), Vector2(350, 22), 11, StyleManager.COLOR_DANGER))
	var next_id := StringName(String(_last_result.get("next_level_id", "")))
	if won and next_id != &"":
		var next_btn := _poster_button("前往潮门", Vector2(382, 217), Vector2(174, 42), true)
		next_btn.name = "NextLevel"
		_wire_ui_audio(next_btn, &"ui_confirm")
		next_btn.pressed.connect(func() -> void:
			if CampaignService.select_level(next_id):
				_show_briefing())
		stage.add_child(next_btn)
	var retry_btn := _poster_button(LocalizationService.tr_key(&"MENU_RESTART"), Vector2(382, 264), Vector2(82, 30), not won)
	retry_btn.name = "Retry"
	_wire_ui_audio(retry_btn, &"ui_select")
	retry_btn.pressed.connect(func() -> void: _enter_battle(false))
	stage.add_child(retry_btn)
	var campaign_btn := _poster_button(LocalizationService.tr_key(&"MENU_EXIT_TO_CAMPAIGN"), Vector2(468, 264), Vector2(88, 30))
	campaign_btn.name = "ResultCampaignBtn"
	_wire_ui_audio(campaign_btn, &"ui_cancel")
	campaign_btn.pressed.connect(_show_campaign)
	stage.add_child(campaign_btn)


func _show_flow_shot_screen() -> void:
	match _flow_shot_screen:
		&"slot":
			_show_slots(true)
		&"campaign":
			_show_campaign()
		&"briefing":
			CampaignService.selected_level = &"level_c01"
			_show_briefing()
		&"result":
			_last_result = {"won": true, "mark_count": 3, "integrity": 20, "kills": 90, "leaks": 0, "sim_seconds": 117.0,
				"marks": {"completed": true, "integrity": true, "strategy": true}, "next_level_id": "level_c02"}
			_show_result()
		&"result_lose":
			_last_result = {"won": false, "mark_count": 0, "integrity": 0, "kills": 37, "leaks": 20, "sim_seconds": 64.0, "marks": {}}
			_show_result()
		_:
			_show_title()


func _capture_flow_screenshot() -> void:
	for i: int in 5:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(_flow_shot_path)
	print("[M2-FLOW] flow screenshot saved: %s (err=%d)" % [_flow_shot_path, err])
	get_tree().quit()
