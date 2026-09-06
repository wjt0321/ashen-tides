class_name C01CampaignChart
extends Control
## C01 港口海域画卷：交互入口附着在地点，C02 仅作为远处潮门。

signal level_chosen(level_id: StringName)

const INK := Color("171b1d")
const ROCK := Color("303633")
const SEA := Color("355756")
const FOAM := Color("88aaa2")
const BONE := Color("e8ddc8")
const CANVAS := Color("c9bda5")
const CORAL := Color("ef684b")
const LOCKED := Color("71817d")

var c01_unlocked := true
var c02_unlocked := false
var c01_marks := -1
var c02_marks := -1
var _built := false

func _ready() -> void:
	build_ports()

func build_ports() -> void:
	if _built:
		return
	_built = true
	custom_minimum_size = Vector2(560, 230)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_add_port(&"level_c01", Vector2(42, 108), Vector2(168, 72), "C01  离港火线", c01_unlocked, c01_marks, true)
	_add_port(&"level_c02", Vector2(390, 52), Vector2(145, 62), "C02  潮门出口", c02_unlocked, c02_marks, false)
	queue_redraw()

func _add_port(id: StringName, pos: Vector2, extent: Vector2, text: String, unlocked: bool, marks: int, warm: bool) -> void:
	var btn := Button.new()
	btn.name = "Level_%s" % id
	btn.position = pos
	btn.size = extent
	btn.custom_minimum_size = extent
	var status := "靠港 · 可进入" if unlocked else LocalizationService.tr_key(&"FLOW_LOCKED") + " · 暮潮封航"
	if unlocked and marks >= 0:
		status = "港旗印记 %d/3" % marks
	btn.text = "%s\n%s" % [text, status]
	btn.disabled = not unlocked
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_size_override("font_size", 13 if warm else 12)
	btn.add_theme_color_override("font_color", BONE if unlocked else LOCKED)
	btn.add_theme_color_override("font_hover_color", Color("fff1d8"))
	btn.add_theme_color_override("font_disabled_color", LOCKED)
	for state: String in ["normal", "pressed", "hover", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(INK, 0.56 if state != "hover" else 0.78)
		sb.border_color = Color(CORAL, 0.82) if warm and unlocked else Color(FOAM, 0.38)
		sb.set_border_width_all(0)
		sb.border_width_left = 3 if warm and unlocked else 1
		sb.content_margin_left = 12
		sb.content_margin_right = 8
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		btn.add_theme_stylebox_override(state, sb)
	btn.pressed.connect(func() -> void: level_chosen.emit(id))
	add_child(btn)

func _draw() -> void:
	# 港区、舰队与潮门均由 C01HarborArt 的栅格背景承担；此控件只保留地点交互。
	pass
