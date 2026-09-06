extends Node
## StyleManager：最终美术风格基线的运行时主题服务（autoload，纯服务，无 presentation）。
## 职责（PROJECT_EXECUTION_BASELINE §3 + ART_STYLE_BASELINE.md）：
##   - 锁定主题色（深海蓝 / 黄铜 / 羊皮 / 锁定灰 / 警示红 / 潮汐绿 / 暮紫）；
##   - 暴露 9-slice TextureRect / 按钮 / 关卡卡 / 战报行等样式构造工厂；
##   - 不依赖 Editor 导入（场景里手动 connect theme 不可靠）；
##   - 资源缺失一律回退 ColorRect / Color + procedural 绘制（PRD §13 抗降级）。
##
## 使用：StyleManager.make_brass_button("继续") 等。Flow UI 屏只调用 API，不直接 hardcode 颜色。

const PATH_BTN_BORDER: String = "res://assets/vendor/c01/kenney/ui/blue/Default/button_rectangle_border.png"
const PATH_BTN_DEPTH: String = "res://assets/vendor/c01/kenney/ui/blue/Default/button_rectangle_depth_border.png"
const PATH_BTN_FLAT: String = "res://assets/vendor/c01/kenney/ui/blue/Default/button_rectangle_flat.png"
const PATH_BTN_ROUND: String = "res://assets/vendor/c01/kenney/ui/blue/Default/button_round_border.png"
const PATH_BTN_SQUARE: String = "res://assets/vendor/c01/kenney/ui/blue/Default/button_square_border.png"
const PATH_ICON_CIRCLE: String = "res://assets/vendor/c01/kenney/ui/blue/Default/icon_circle.png"
const PATH_ICON_CHECK: String = "res://assets/vendor/c01/kenney/ui/blue/Default/icon_checkmark.png"
const PATH_ICON_CROSS: String = "res://assets/vendor/c01/kenney/ui/blue/Default/icon_cross.png"
const PATH_ICON_SQUARE: String = "res://assets/vendor/c01/kenney/ui/blue/Default/icon_square.png"
const PATH_STAR: String = "res://assets/vendor/c01/kenney/ui/blue/Default/star.png"
const PATH_ARROW_E: String = "res://assets/vendor/c01/kenney/ui/blue/Default/arrow_basic_e.png"
const PATH_ARROW_W: String = "res://assets/vendor/c01/kenney/ui/blue/Default/arrow_basic_w.png"

# ART_STYLE_BASELINE §4 + C01_STYLE_BIBLE §1：主题色
const COLOR_DEEP_SEA: Color = Color("#1d2f30")
const COLOR_BRASS: Color = Color("#d4a85c") # 仅印记/胜利高光
const COLOR_PARCHMENT: Color = Color("#e8ddc8")
const COLOR_LOCKED: Color = Color("#71817d")
const COLOR_DANGER: Color = Color("#b34c42")
const COLOR_SAFE: Color = Color("#668b7f")
const COLOR_DUSK: Color = Color("#384b49")
const COLOR_CORAL: Color = Color("#ef684b")

# 按钮主态 modulate：原 Kenney 蓝偏亮，调到本项目深海蓝
const BTN_MOD_NORMAL: Color = Color(0.18, 0.32, 0.55, 1.0)
const BTN_MOD_LOCKED: Color = Color(0.12, 0.18, 0.30, 0.7)
const BTN_MOD_PRESSED: Color = Color(0.10, 0.22, 0.45, 1.0)
const BTN_MOD_HOVER: Color = Color(0.22, 0.36, 0.60, 1.0)
const BTN_MOD_SELECTED: Color = Color(0.25, 0.40, 0.55, 0.95)

# 关卡卡高亮色
const CARD_HIGHLIGHT: Color = Color(0.20, 0.35, 0.55, 0.9)
const CARD_NORMAL: Color = Color(0.10, 0.18, 0.30, 0.85)
const CARD_LOCKED: Color = Color(0.05, 0.08, 0.14, 0.6)

# 字号
const FONT_SIZE_TITLE: int = 24
const FONT_SIZE_SUBTITLE: int = 18
const FONT_SIZE_HEADING: int = 16
const FONT_SIZE_BODY: int = 14
const FONT_SIZE_SMALL: int = 12
const FONT_SIZE_TINY: int = 11

const NINE_SLICE_MARGIN: int = 4
const BTN_MIN_WIDTH: int = 120
const BTN_HEIGHT: int = 28
const CARD_WIDTH: int = 180
const CARD_HEIGHT: int = 96
const HERO_CARD_WIDTH: int = 140
const HERO_CARD_HEIGHT: int = 160

# 资源缓存：path -> Texture2D
var _tex_cache: Dictionary = {}


func _ready() -> void:
	print("[C01-VISUAL] harbor poster palette ready")


# ---------------------------------------------------------------------------
# 颜色 / 字号
# ---------------------------------------------------------------------------

func color_deep_sea() -> Color: return COLOR_DEEP_SEA
func color_brass() -> Color: return COLOR_BRASS
func color_parchment() -> Color: return COLOR_PARCHMENT
func color_locked() -> Color: return COLOR_LOCKED
func color_danger() -> Color: return COLOR_DANGER
func color_safe() -> Color: return COLOR_SAFE
func color_dusk() -> Color: return COLOR_DUSK


# ---------------------------------------------------------------------------
# 资源加载（带 fallback）
# ---------------------------------------------------------------------------

func tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	if not ResourceLoader.exists(path):
		_tex_cache[path] = null
		return null
	var t := load(path) as Texture2D
	_tex_cache[path] = t
	return t


# ---------------------------------------------------------------------------
# 9-slice 按钮工厂
# ---------------------------------------------------------------------------

## 黄铜主按钮：9-slice Kenney button_rectangle_border；modulate 调到深海蓝；
## 文本用 Ark Pixel 12 px 黄铜色。text 可空（按钮容器）。
func make_brass_button(text: String = "", min_width: int = -1) -> Button:
	var btn := Button.new()
	btn.text = text
	_apply_button_style(btn, PATH_BTN_BORDER, BTN_MOD_NORMAL, BTN_MOD_PRESSED, BTN_MOD_DISABLED if false else BTN_MOD_LOCKED, min_width)
	return btn


## 圆角小按钮（设置/取消之类小尺寸 CTA）
func make_round_button(text: String = "", min_width: int = -1) -> Button:
	var btn := Button.new()
	btn.text = text
	_apply_button_style(btn, PATH_BTN_ROUND, BTN_MOD_NORMAL, BTN_MOD_PRESSED, BTN_MOD_LOCKED, min_width)
	return btn


## 方按钮（英雄/关卡卡头像槽）
func make_square_button(text: String = "", min_width: int = -1) -> Button:
	var btn := Button.new()
	btn.text = text
	_apply_button_style(btn, PATH_BTN_SQUARE, BTN_MOD_NORMAL, BTN_MOD_PRESSED, BTN_MOD_LOCKED, min_width)
	return btn


# 兼容：BTN_MOD_DISABLED 占位，避免 IDE 标 unused 警告。
const BTN_MOD_DISABLED := BTN_MOD_LOCKED

func _apply_button_style(btn: Button, _path: String, _mod_normal: Color, _mod_pressed: Color, _mod_disabled: Color, min_width: int) -> void:
	# 新方向不再使用 Kenney 蓝色 9-slice。主流程按钮是盐渍帆布上的深墨操作片。
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.09, 0.09, 0.72 if state != "hover" else 0.90)
		sb.border_color = Color(COLOR_CORAL, 0.58 if state == "hover" or state == "focus" else 0.0)
		sb.set_border_width_all(1 if state == "hover" or state == "focus" else 0)
		sb.corner_radius_top_right = 7
		sb.corner_radius_bottom_left = 7
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		btn.add_theme_stylebox_override(state, sb)
	btn.add_theme_color_override("font_color", COLOR_PARCHMENT)
	btn.add_theme_color_override("font_hover_color", Color("ffd3b0"))
	btn.add_theme_color_override("font_pressed_color", COLOR_CORAL)
	btn.add_theme_color_override("font_disabled_color", COLOR_LOCKED)
	btn.add_theme_font_size_override("font_size", FONT_SIZE_BODY)
	btn.custom_minimum_size = Vector2(min_width if min_width > 0 else BTN_MIN_WIDTH, BTN_HEIGHT)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


# ---------------------------------------------------------------------------
# 关卡卡# ---------------------------------------------------------------------------
# 关卡卡 / 英雄卡 / 节点
# ---------------------------------------------------------------------------

## 关卡卡：背景 Kenney 按钮 9-slice + 章节编号 / 状态 / 印记三行。
## status: 0=locked, 1=unlocked, 2=completed, 3=selected（黄铜加粗）
func make_chapter_card(level_id: StringName, status: int, chapter_label: String, title_text: String, marks: int = -1) -> PanelContainer:
	var card := PanelContainer.new()
	var t: Texture2D = tex(PATH_BTN_BORDER)
	if t == null:
		# 回退：纯色卡
		var sb := StyleBoxFlat.new()
		sb.bg_color = CARD_NORMAL
		sb.border_color = COLOR_BRASS
		sb.set_border_width_all(1)
		card.add_theme_stylebox_override("panel", sb)
	else:
		var sb := StyleBoxTexture.new()
		sb.texture = t
		sb.region_rect = Rect2(0, 0, t.get_width(), t.get_height())
		if status == 0:
			sb.modulate_color = CARD_LOCKED
		elif status == 1:
			sb.modulate_color = CARD_NORMAL
		elif status == 2:
			sb.modulate_color = COLOR_SAFE
		elif status == 3:
			sb.modulate_color = CARD_HIGHLIGHT
		else:
			sb.modulate_color = CARD_NORMAL
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		if status == 3:
			# 选中态：2 px 黄铜描边
			var sb2 := sb.duplicate() as StyleBoxTexture
			# 改用 StyleBoxFlat 叠加以实现"额外"边框？— 简化：替换 border 颜色
			# 这里用 modulate 加深 1 个色调近似
			sb2.modulate_color = COLOR_HIGHLIGHT_DARKER
			card.add_theme_stylebox_override("panel", sb2)
		else:
			card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	# 内容 vbox
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)
	# 章节行
	var hbox_top := HBoxContainer.new()
	hbox_top.add_theme_constant_override("separation", 4)
	var chapter := Label.new()
	chapter.text = chapter_label
	chapter.add_theme_font_size_override("font_size", FONT_SIZE_HEADING)
	chapter.add_theme_color_override("font_color", COLOR_BRASS)
	hbox_top.add_child(chapter)
	var icon := TextureRect.new()
	icon.texture = _icon_for_status(status)
	icon.custom_minimum_size = Vector2(20, 20)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox_top.add_child(icon)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_top.add_child(spacer)
	var marks_label := Label.new()
	marks_label.text = _marks_text(marks)
	marks_label.add_theme_font_size_override("font_size", FONT_SIZE_TINY)
	marks_label.add_theme_color_override("font_color", COLOR_PARCHMENT)
	hbox_top.add_child(marks_label)
	vbox.add_child(hbox_top)
	# 标题
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", FONT_SIZE_BODY)
	title.add_theme_color_override("font_color", COLOR_PARCHMENT)
	vbox.add_child(title)
	# id 行（小灰）
	var id_label := Label.new()
	id_label.text = String(level_id)
	id_label.add_theme_font_size_override("font_size", FONT_SIZE_TINY)
	id_label.add_theme_color_override("font_color", COLOR_LOCKED)
	vbox.add_child(id_label)
	return card


const COLOR_HIGHLIGHT_DARKER := Color(0.10, 0.18, 0.32, 1.0)


func _icon_for_status(status: int) -> Texture2D:
	if status == 0:
		return tex(PATH_ICON_CROSS) # 锁定
	if status == 1:
		return tex(PATH_ICON_SQUARE) # 未通
	if status == 2:
		return tex(PATH_ICON_CIRCLE) # 已通
	return tex(PATH_ICON_CIRCLE)


func _marks_text(marks: int) -> String:
	if marks < 0:
		return "—"
	return "%d/3" % marks


## 节点圆点：战役海图上的关卡位置
func make_node_marker(status: int, size: int = 20) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = _icon_for_status(status)
	icon.custom_minimum_size = Vector2(size, size)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


## 印记徽章（一颗）
func make_mark_star(size: int = 16) -> TextureRect:
	var star := TextureRect.new()
	star.texture = tex(PATH_STAR)
	star.custom_minimum_size = Vector2(size, size)
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return star


# ---------------------------------------------------------------------------
# 屏背景 / 主面板
# ---------------------------------------------------------------------------

## 全屏深海蓝背景（ColorRect）
func make_background() -> ColorRect:
	var bg := ColorRect.new()
	bg.color = COLOR_DEEP_SEA
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bg


## 居中大面板：Kenney button_depth_border + 深蓝调制 + 黄铜 1 px 描边
func make_center_panel(min_w: int = 480, min_h: int = 280) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(min_w, min_h)
	var t: Texture2D = tex(PATH_BTN_DEPTH)
	if t == null:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.05, 0.10, 0.20, 0.9)
		sb.border_color = COLOR_BRASS
		sb.set_border_width_all(1)
		p.add_theme_stylebox_override("panel", sb)
	else:
		var sb := StyleBoxTexture.new()
		sb.texture = t
		sb.region_rect = Rect2(0, 0, t.get_width(), t.get_height())
		sb.modulate_color = Color(0.05, 0.10, 0.20, 0.9)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 16
		sb.content_margin_bottom = 16
		p.add_theme_stylebox_override("panel", sb)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## 章节带分割线（黄铜 1 px）
func make_brass_divider(width: int = 600) -> ColorRect:
	var d := ColorRect.new()
	d.color = COLOR_BRASS
	d.custom_minimum_size = Vector2(width, 1)
	d.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return d


# ---------------------------------------------------------------------------
# 文本 / 标签
# ---------------------------------------------------------------------------

func make_label(text: String, size: int = -1, color: Color = COLOR_PARCHMENT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size if size > 0 else FONT_SIZE_BODY)
	l.add_theme_color_override("font_color", color)
	return l


func make_title(text: String) -> Label:
	return make_label(text, FONT_SIZE_TITLE, COLOR_BRASS)


func make_subtitle(text: String) -> Label:
	return make_label(text, FONT_SIZE_SUBTITLE, COLOR_PARCHMENT)


func make_body(text: String) -> Label:
	return make_label(text, FONT_SIZE_BODY, COLOR_PARCHMENT)


func make_small(text: String, color: Color = COLOR_LOCKED) -> Label:
	return make_label(text, FONT_SIZE_SMALL, color)


# ---------------------------------------------------------------------------
# 方向箭头
# ---------------------------------------------------------------------------

func make_arrow_e(size: int = 16) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(PATH_ARROW_E)
	t.custom_minimum_size = Vector2(size, size)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t


func make_arrow_w(size: int = 16) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(PATH_ARROW_W)
	t.custom_minimum_size = Vector2(size, size)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t


# ---------------------------------------------------------------------------
# 测试 / 调试
# ---------------------------------------------------------------------------

func clear_texture_cache() -> void:
	_tex_cache.clear()


func has_all_assets() -> bool:
	for path: String in [PATH_BTN_BORDER, PATH_BTN_DEPTH, PATH_BTN_FLAT, PATH_BTN_ROUND, PATH_BTN_SQUARE,
		PATH_ICON_CIRCLE, PATH_ICON_CHECK, PATH_ICON_CROSS, PATH_ICON_SQUARE,
		PATH_STAR, PATH_ARROW_E, PATH_ARROW_W]:
		if not ResourceLoader.exists(path):
			return false
	return true
