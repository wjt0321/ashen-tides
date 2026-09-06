class_name PauseMenuPanel
extends CanvasLayer
## 暂停菜单（M2）：继续 / 设置 / 重开（/ 返回战役，Flow 嵌入时）。Esc 开关；打开时不强制 _paused（main 控制模拟暂停）。

signal resume_requested
signal settings_requested
signal restart_requested
signal exit_to_campaign_requested ## Flow Shell：仅 flow_managed 时按钮可见

## AppFlow 嵌入战斗时置 true，显示「返回战役」按钮（须在 add_child 前设置）
var show_exit_to_campaign: bool = false

var _panel: PanelContainer
var _title_label: Label
var _menu_buttons: Dictionary = {} ## action_id(StringName) -> Button


func _ready() -> void:
	layer = 30
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.7)
	dim.size = Vector2(640, 360)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.position = Vector2(230, 110)
	_panel.size = Vector2(180, 170 if show_exit_to_campaign else 140)
	add_child(_panel)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)
	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_title_label)
	var ids: Array[StringName] = [&"MENU_CONTINUE", &"MENU_SETTINGS", &"MENU_RESTART"]
	if show_exit_to_campaign:
		ids.append(&"MENU_EXIT_TO_CAMPAIGN")
	for id: StringName in ids:
		var btn := Button.new()
		btn.name = String(id)
		vbox.add_child(btn)
		match id:
			&"MENU_CONTINUE":
				btn.pressed.connect(func() -> void: resume_requested.emit())
			&"MENU_SETTINGS":
				btn.pressed.connect(func() -> void: settings_requested.emit())
			&"MENU_RESTART":
				btn.pressed.connect(func() -> void: restart_requested.emit())
			&"MENU_EXIT_TO_CAMPAIGN":
				btn.pressed.connect(func() -> void: exit_to_campaign_requested.emit())
		_menu_buttons[id] = btn
	refresh_texts()


func open() -> void:
	refresh_texts()
	visible = true


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


func refresh_texts() -> void:
	if _title_label != null:
		_title_label.text = LocalizationService.tr_key(&"PAUSE_TITLE")
	for id: StringName in _menu_buttons:
		var btn := _menu_buttons[id] as Button
		if btn != null:
			btn.text = LocalizationService.tr_key(id)
