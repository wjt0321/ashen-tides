class_name BattleResultPanel
extends CanvasLayer
## 结算/战报面板（M2，PRD §9.2 印记 + §11.3 战报）。
## 数据源为 main.gd 组装的 _last_result Dictionary；纯展示，不触碰战斗状态。
## 键盘：R 重开（由 main 处理）/ Esc 关闭；鼠标：按钮。

signal restart_requested
signal next_level_requested
signal closed

const PANEL_SIZE := Vector2(460, 320)

var _result: Dictionary = {}
var _vbox: VBoxContainer


func _ready() -> void:
	layer = 20
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.82)
	dim.size = Vector2(640, 360)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = (Vector2(640, 360) - PANEL_SIZE) * 0.5
	panel.size = PANEL_SIZE
	add_child(panel)
	var scroll := ScrollContainer.new()
	panel.add_child(scroll)
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(_vbox)


func show_result(result: Dictionary) -> void:
	_result = result
	_rebuild()
	visible = true


func hide_panel() -> void:
	visible = false
	closed.emit()


func _rebuild() -> void:
	for child: Node in _vbox.get_children():
		child.queue_free()
	var won := bool(_result.get("won", false))
	_add_title(LocalizationService.tr_key(&"RESULT_WIN") if won else LocalizationService.tr_key(&"RESULT_LOSE"),
		Color(0.55, 0.95, 0.65) if won else Color(0.95, 0.45, 0.40))
	# 印记（PRD §9.2：通关 / 完整度 / 策略目标）
	var marks: Dictionary = _result.get("marks", {})
	var mark_text := "%s %d/3  [%s %s %s]" % [
		LocalizationService.tr_key(&"RESULT_MARKS"), int(_result.get("mark_count", 0)),
		"✓" if marks.get("completed", false) else "✗",
		"✓" if marks.get("integrity", false) else "✗",
		"✓" if marks.get("strategy", false) else "✗",
	]
	_add_line(mark_text)
	_add_line("%s %d | %s %d | %s %d | %s %.0fs" % [
		LocalizationService.tr_key(&"RESULT_INTEGRITY"), int(_result.get("integrity", 0)),
		LocalizationService.tr_key(&"RESULT_KILLS"), int(_result.get("kills", 0)),
		LocalizationService.tr_key(&"RESULT_LEAKS"), int(_result.get("leaks", 0)),
		LocalizationService.tr_key(&"RESULT_TIME"), float(_result.get("sim_seconds", 0.0)),
	])
	# 战报（PRD §11.3）
	_add_header(LocalizationService.tr_key(&"RESULT_REPORT"))
	var breach := int(_result.get("first_breach_wave", 0))
	_add_line("%s: %s" % [LocalizationService.tr_key(&"RESULT_FIRST_BREACH"),
		str(breach) if breach > 0 else "—"])
	var leak_by: Dictionary = _result.get("leak_by_enemy", {})
	if not leak_by.is_empty():
		_add_line(LocalizationService.tr_key(&"RESULT_LEAK_TOP") + ":")
		var pairs: Array = leak_by.keys()
		pairs.sort_custom(func(a: Variant, b: Variant) -> bool: return int(leak_by[a]) > int(leak_by[b]))
		for i: int in mini(3, pairs.size()):
			_add_line("  %s ×%d" % [String(pairs[i]), int(leak_by[pairs[i]])])
	var dmg_by: Dictionary = _result.get("damage_by_type", {})
	if not dmg_by.is_empty():
		_add_line(LocalizationService.tr_key(&"RESULT_DAMAGE") + ":")
		for dtype: Variant in dmg_by:
			_add_line("  %s: %.0f" % [String(dtype), float(dmg_by[dtype])])
	var uncovered: Array = _result.get("uncovered_tags", [])
	if not uncovered.is_empty():
		_add_line("%s: %s" % [LocalizationService.tr_key(&"RESULT_UNCOVERED"),
			", ".join(uncovered.map(func(t: Variant) -> String: return String(t)))])
	_add_header(LocalizationService.tr_key(&"RESULT_HINTS"))
	if uncovered.has(&"swarm"):
		_add_line(LocalizationService.tr_key(&"HINT_SPLASH"))
	elif uncovered.has(&"heavy"):
		_add_line(LocalizationService.tr_key(&"HINT_GLOW"))
	else:
		_add_line(LocalizationService.tr_key(&"HINT_NONE"))
	_add_line(LocalizationService.tr_key(&"RESULT_RESTART_HINT"), Color(0.7, 0.7, 0.75))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_child(row)
	# S1 修复：通关且有下一关时提供「下一关」推进入口（战役推进，PRD §7/§638）
	var next_id := String(_result.get("next_level_id", ""))
	if won and not next_id.is_empty():
		var next_btn := Button.new()
		next_btn.text = "%s (%s)" % [LocalizationService.tr_key(&"MENU_NEXT_LEVEL"), next_id]
		next_btn.pressed.connect(func() -> void: next_level_requested.emit())
		row.add_child(next_btn)
	var restart_btn := Button.new()
	restart_btn.text = LocalizationService.tr_key(&"MENU_RESTART")
	restart_btn.pressed.connect(func() -> void: restart_requested.emit())
	row.add_child(restart_btn)
	var close_btn := Button.new()
	close_btn.text = LocalizationService.tr_key(&"MENU_CLOSE")
	close_btn.pressed.connect(hide_panel)
	row.add_child(close_btn)


func _add_title(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	_vbox.add_child(label)


func _add_header(text: String) -> void:
	var label := Label.new()
	label.text = "— %s —" % text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.45))
	_vbox.add_child(label)


func _add_line(text: String, color: Color = Color(0.88, 0.88, 0.90)) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	_vbox.add_child(label)
