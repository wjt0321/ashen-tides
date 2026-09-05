class_name TutorialOverlay
extends CanvasLayer
## 教程覆盖层（M2，PRD §12.2）：非阻断、可跳过（F1）、每步 ≤45 字。
## 步骤由关卡 tutorial_id 驱动；事件触发推进（建造/开波/升级/暂停）。
## 完成状态写入 SettingsService（tutorial/done_<id>），已完成的教程不再显示。

## 步骤定义：[提示 key, 推进触发信号名（EventBus）]。空触发 = 立即推进。
const STEPS: Dictionary = {
	&"tutorial_c01": [
		[&"TUT_STEP_BUILD", &"tower_placed"],
		[&"TUT_STEP_START", &"wave_started"],
		[&"TUT_STEP_RANGE", &""], # 信息步，2.5 秒后自动推进
		[&"TUT_STEP_UPGRADE", &"tower_upgraded"],
		[&"TUT_STEP_PAUSE", &""],
		[&"TUT_DONE", &""],
	],
	&"tutorial_c02": [
		[&"TUT_C02_STEP_ROUTE", &"wave_started"],
		[&"TUT_C02_STEP_TIDE", &"tide_clock_shifted"],
		[&"TUT_C02_DONE", &""],
	],
	&"tutorial_c03": [
		[&"TUT_C03_STEP_DEVICE", &"wave_started"],
		[&"TUT_C03_STEP_DOWN", &"device_offline"],
		[&"TUT_C03_DONE", &""],
	],
}

const INFO_STEP_SECONDS := 4.0

var _label: Label
var _skip_label: Label
var _tutorial_id: StringName = &""
var _step: int = -1
var _info_left: float = 0.0


func _ready() -> void:
	layer = 10
	visible = false
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 300)
	panel.size = Vector2(330, 56)
	add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_label)
	_skip_label = Label.new()
	_skip_label.add_theme_font_size_override("font_size", 10)
	_skip_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(_skip_label)


## 由 main 在关卡加载后调用。已完成或无烟教程定义时不显示。
func start_for(tutorial_id: StringName) -> void:
	_tutorial_id = tutorial_id
	if not STEPS.has(tutorial_id):
		return
	if bool(SettingsService.get_value("tutorial", "done_%s" % tutorial_id, false)):
		return
	visible = true
	_step = -1
	_advance()


func skip() -> void:
	if _step < 0:
		return
	_finish()


func is_active() -> bool:
	return _step >= 0


## main 转发相关 EventBus 信号到此（避免 overlay 直接持有总线依赖以外的耦合）。
func notify(trigger: StringName) -> void:
	if _step < 0 or not STEPS.has(_tutorial_id):
		return
	var steps: Array = STEPS[_tutorial_id]
	if _step < steps.size() and steps[_step][1] == trigger:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tutorial_skip"):
		skip()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _step < 0 or _info_left <= 0.0:
		return
	_info_left -= delta
	if _info_left <= 0.0:
		_advance()


func _advance() -> void:
	var steps: Array = STEPS[_tutorial_id]
	_step += 1
	if _step >= steps.size():
		_finish()
		return
	var step: Array = steps[_step]
	_label.text = "%d/%d  %s" % [_step + 1, steps.size(), LocalizationService.tr_key(step[0])]
	_skip_label.text = LocalizationService.tr_key(&"TUT_SKIP")
	_info_left = INFO_STEP_SECONDS if step[1] == &"" else 0.0


func _finish() -> void:
	SettingsService.set_value("tutorial", "done_%s" % _tutorial_id, true)
	_step = -1
	visible = false
