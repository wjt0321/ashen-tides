class_name SettingsPanel
extends CanvasLayer
## 设置面板（M2，PRD §10.2 音量 / §13.1 无障碍 / §13.2 按键重绑定）。
## 持久化走 SettingsService（user://settings.cfg）；应用经 EventBus.settings_applied 广播。
## 按键重绑定：点击动作行的按钮后按新键；冲突（同一键已占）拒绝并提示；可恢复默认。

signal closed

## 允许重绑定的战斗动作（debug_* 不开放）。
const REBINDABLE_ACTIONS: Array[StringName] = [
	&"battle_start_wave", &"battle_pause", &"battle_cycle_tower",
	&"battle_upgrade_tower", &"battle_sell_tower",
	&"hero_skill_a", &"hero_skill_b", &"hero_ultimate",
	&"tide_clock_earlier", &"tide_clock_later",
	&"speed_up", &"speed_down", &"debug_reset",
]

const ACTION_LABEL_KEYS: Dictionary = {
	&"battle_start_wave": "开始波次", &"battle_pause": "暂停", &"battle_cycle_tower": "切换塔种",
	&"battle_upgrade_tower": "升级塔", &"battle_sell_tower": "出售塔",
	&"hero_skill_a": "英雄技能A", &"hero_skill_b": "英雄技能B", &"hero_ultimate": "终极技",
	&"tide_clock_earlier": "潮汐提前", &"tide_clock_later": "潮汐推迟",
	&"speed_up": "加速", &"speed_down": "减速", &"debug_reset": "重开",
}

static var _default_bindings: Dictionary = {} ## action -> Array[InputEventKey]（启动快照）

var _vbox: VBoxContainer
var _capturing_action: StringName = &""
var _capture_button: Button = null
var _conflict_label: Label


## 启动时（main._ready 最前）快照 InputMap 默认键位，供恢复默认。
static func capture_defaults() -> void:
	if not _default_bindings.is_empty():
		return
	for action: StringName in REBINDABLE_ACTIONS:
		var events: Array = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				events.append(event.physical_keycode)
		_default_bindings[action] = events


## 启动时应用已保存的键位覆盖。
static func apply_saved_bindings() -> void:
	var saved: Dictionary = SettingsService.get_value("input", "bindings", {})
	for action: Variant in saved:
		var action_name := StringName(action)
		if not REBINDABLE_ACTIONS.has(action_name):
			continue
		_set_action_keys(action_name, saved[action])


static func _set_action_keys(action: StringName, keycodes: Array) -> void:
	# 只替换键盘事件，保留手柄按钮映射（手柄不参与重绑定，PRD §13.2）
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	for keycode: Variant in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = int(keycode)
		InputMap.action_add_event(action, event)


func _ready() -> void:
	layer = 40
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.85)
	dim.size = Vector2(640, 360)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(90, 16)
	panel.size = Vector2(460, 328)
	add_child(panel)
	var scroll := ScrollContainer.new()
	panel.add_child(scroll)
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 3)
	scroll.add_child(_vbox)


func open() -> void:
	_rebuild()
	visible = true


func close() -> void:
	visible = false
	_capturing_action = &""
	closed.emit()


func is_open() -> bool:
	return visible


func _rebuild() -> void:
	for child: Node in _vbox.get_children():
		child.queue_free()
	_capturing_action = &""
	_add_header(LocalizationService.tr_key(&"SETTINGS_TITLE"))
	# —— 音量（PRD §10.2：Master/Music/SFX/Ambient/UI 独立通道）——
	for spec: Array in [
		[&"SETTINGS_MASTER", "master_volume"], [&"SETTINGS_MUSIC", "music_volume"],
		[&"SETTINGS_SFX", "sfx_volume"], [&"SETTINGS_AMBIENT", "ambient_volume"],
		[&"SETTINGS_UI_VOL", "ui_volume"],
	]:
		_add_slider(LocalizationService.tr_key(spec[0]),
			float(SettingsService.get_value("audio", spec[1], 1.0)),
			func(value: float) -> void: _set_and_apply("audio", spec[1], value))
	# —— 显示 / 无障碍（PRD §13.1）——
	_add_slider(LocalizationService.tr_key(&"SETTINGS_UI_SCALE"),
		float(SettingsService.get_value("display", "ui_scale", 1.0)),
		func(value: float) -> void:
			_set_and_apply("display", "ui_scale", value)
			get_window().content_scale_factor = value,
		0.8, 1.6)
	var presets := [&"default", &"protan", &"deutan", &"tritan"]
	var preset_keys := [&"CP_DEFAULT", &"CP_PROTAN", &"CP_DEUTAN", &"CP_TRITAN"]
	_add_option(LocalizationService.tr_key(&"SETTINGS_COLOR_PRESET"), presets, preset_keys,
		StringName(SettingsService.get_value("accessibility", "color_preset", "default")),
		func(value: StringName) -> void:
			_set_and_apply("accessibility", "color_preset", String(value))
			UiPalette.configure_from_settings())
	for spec: Array in [
		[&"SETTINGS_HIGH_CONTRAST", "high_contrast"], [&"SETTINGS_LOW_FX", "low_fx"],
	]:
		_add_toggle(LocalizationService.tr_key(spec[0]),
			bool(SettingsService.get_value("accessibility", spec[1], false)),
			func(value: bool) -> void: _set_and_apply("accessibility", spec[1], value))
	_add_toggle(LocalizationService.tr_key(&"SETTINGS_AUTOCAST"),
		bool(SettingsService.get_value("gameplay", "auto_cast_basic", false)),
		func(value: bool) -> void: _set_and_apply("gameplay", "auto_cast_basic", value))
	# —— 语言 ——
	_add_option(LocalizationService.tr_key(&"SETTINGS_LANGUAGE"),
		[&"zh_CN", &"en"], [&"LANG_ZH", &"LANG_EN"],
		StringName(LocalizationService.current_locale),
		func(value: StringName) -> void: LocalizationService.switch_locale(String(value)))
	# —— 按键重绑定（PRD §13.2）——
	_add_header(LocalizationService.tr_key(&"SETTINGS_KEYS"))
	_conflict_label = Label.new()
	_conflict_label.add_theme_font_size_override("font_size", 11)
	_conflict_label.add_theme_color_override("font_color", Color(0.95, 0.5, 0.45))
	_vbox.add_child(_conflict_label)
	for action: StringName in REBINDABLE_ACTIONS:
		_add_rebind_row(action)
	var reset_btn := Button.new()
	reset_btn.text = LocalizationService.tr_key(&"SETTINGS_RESET_KEYS")
	reset_btn.pressed.connect(_reset_bindings)
	_vbox.add_child(reset_btn)
	var close_btn := Button.new()
	close_btn.text = LocalizationService.tr_key(&"MENU_CLOSE")
	close_btn.pressed.connect(close)
	_vbox.add_child(close_btn)


func _set_and_apply(section: String, key: String, value: Variant) -> void:
	SettingsService.set_value(section, key, value)
	EventBus.settings_applied.emit()


func _add_header(text: String) -> void:
	var label := Label.new()
	label.text = "— %s —" % text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.45))
	_vbox.add_child(label)


func _add_slider(label_text: String, value: float, on_change: Callable, min_v: float = 0.0, max_v: float = 1.0) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 130
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size.x = 200
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	_vbox.add_child(row)


func _add_toggle(label_text: String, value: bool, on_change: Callable) -> void:
	var check := CheckBox.new()
	check.text = label_text
	check.button_pressed = value
	check.add_theme_font_size_override("font_size", 12)
	check.toggled.connect(on_change)
	_vbox.add_child(check)


func _add_option(label_text: String, values: Array, label_keys: Array, current: StringName, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 130
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)
	var option := OptionButton.new()
	for i: int in values.size():
		option.add_item(LocalizationService.tr_key(label_keys[i]), i)
		if values[i] == current:
			option.select(i)
	option.item_selected.connect(func(index: int) -> void: on_change.call(values[index]))
	row.add_child(option)
	_vbox.add_child(row)


func _add_rebind_row(action: StringName) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = String(ACTION_LABEL_KEYS.get(action, action))
	label.custom_minimum_size.x = 130
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)
	var btn := Button.new()
	btn.text = _binding_text(action)
	btn.pressed.connect(func() -> void:
		_capturing_action = action
		_capture_button = btn
		btn.text = LocalizationService.tr_key(&"SETTINGS_PRESS_KEY"))
	row.add_child(btn)
	_vbox.add_child(row)


func _binding_text(action: StringName) -> String:
	var keys: Array[String] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append(OS.get_keycode_string(event.physical_keycode))
	return ", ".join(keys) if not keys.is_empty() else "—"


## 捕获重绑定按键；冲突检测：同一物理键已被其他可绑定动作占用则拒绝。
func _input(event: InputEvent) -> void:
	if _capturing_action == &"" or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var keycode: int = event.physical_keycode
		if keycode == KEY_ESCAPE:
			_finish_capture(false)
			get_viewport().set_input_as_handled()
			return
		for other: StringName in REBINDABLE_ACTIONS:
			if other == _capturing_action:
				continue
			for bound: InputEvent in InputMap.action_get_events(other):
				if bound is InputEventKey and bound.physical_keycode == keycode:
					_conflict_label.text = "%s: %s → %s" % [
						LocalizationService.tr_key(&"SETTINGS_CONFLICT"),
						OS.get_keycode_string(keycode), String(ACTION_LABEL_KEYS.get(other, other))]
					_finish_capture(false)
					get_viewport().set_input_as_handled()
					return
		_persist_binding(_capturing_action, keycode)
		_finish_capture(true)
		get_viewport().set_input_as_handled()


func _finish_capture(applied: bool) -> void:
	if _capture_button != null:
		_capture_button.text = _binding_text(_capturing_action) if applied else _binding_text(_capturing_action)
	_capturing_action = &""
	_capture_button = null


func _persist_binding(action: StringName, keycode: int) -> void:
	_set_action_keys(action, [keycode])
	var saved: Dictionary = SettingsService.get_value("input", "bindings", {})
	saved = saved.duplicate()
	saved[String(action)] = [keycode]
	SettingsService.set_value("input", "bindings", saved)
	_conflict_label.text = ""
	EventBus.settings_applied.emit()


func _reset_bindings() -> void:
	for action: StringName in REBINDABLE_ACTIONS:
		if _default_bindings.has(action):
			_set_action_keys(action, _default_bindings[action])
	SettingsService.set_value("input", "bindings", {})
	_rebuild()
	EventBus.settings_applied.emit()
