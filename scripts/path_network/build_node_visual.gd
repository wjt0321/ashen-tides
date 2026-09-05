class_name BuildNodeVisual
extends Node2D
## BuildNode 可视化（M0 占位升级模块C）：六边形石台。
## 数据契约：BuildNodeData（PRD §18.4）；状态颜色规则见 PRD §3.6：
## 绿 = 可建、黄 = 已占用、红 = 不可建（等级 / 火种不足）——语义保留，
## 由矩形改为六边形发光描边；空闲台面用主题 accent 描边 + 低 alpha 内填，
## 占用时台面暗化（塔叠其上）。BuildNode 永远不在 PathNetwork 的 curve 上（数据层互斥，PRD §5.4）。

enum State { FREE, OCCUPIED, BLOCKED }

const STATE_COLORS: Dictionary = {
	State.FREE: Color(0.30, 0.90, 0.40, 0.90),
	State.OCCUPIED: Color(0.95, 0.85, 0.20, 0.90),
	State.BLOCKED: Color(0.95, 0.30, 0.30, 0.90),
}
const HEX_RADIUS := 11.0 # 32×32 cell 内的六边形外接圆半径
const STONE_BASE := Color(0.13, 0.12, 0.15) ## 石台基座
const STONE_FACE := Color(0.20, 0.19, 0.22) ## 石台上层面

var node_id: StringName
var state: State = State.FREE
## 主题强调色（main 按当前关卡主题赋值，默认金）
var level_accent: Color = Color(0.95, 0.78, 0.32)


func setup(p_id: StringName, p_position: Vector2, p_state: State) -> void:
	node_id = p_id
	position = p_position
	state = p_state
	queue_redraw()


func set_state(p_state: State) -> void:
	state = p_state
	queue_redraw()


func cycle_state() -> void:
	set_state((state + 1) % State.size() as State)


## 六边形顶点（外接圆半径 radius；flat-top，适合 32px 方格子）。
func _hex_points(radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in range(6):
		var a := TAU * float(i) / 6.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


func _stroke_hex(radius: float, color: Color, width: float) -> void:
	var pts := _hex_points(radius)
	pts.append(pts[0])
	draw_polyline(pts, color, width)


func _draw() -> void:
	# 状态语义（PRD §3.6 绿/黄/红）+ 台面 tint
	var edge: Color = STATE_COLORS[state]
	var face_tint := Color(0.0, 0.0, 0.0, 0.0)
	var glow := false
	match state:
		State.FREE:
			face_tint = Color(level_accent, 0.10) # 空闲：低 alpha 主题色内填
			glow = true
		State.OCCUPIED:
			edge = Color(edge, 0.55) # 占用：黄描边压暗，台面暗化
			face_tint = Color(0.03, 0.03, 0.05, 0.42)
		State.BLOCKED:
			face_tint = Color(0.95, 0.30, 0.30, 0.07) # 不可建：台面微泛红
			glow = true
	# 发光 halo（画在台面背后，形成六边形发光描边）
	if glow:
		draw_polyline(_hex_points(HEX_RADIUS + 2.6), Color(edge, 0.22), 5.0)
	# 石台：基座 + 上层面
	var outer := _hex_points(HEX_RADIUS)
	var face := _hex_points(HEX_RADIUS * 0.78)
	draw_colored_polygon(outer, STONE_BASE)
	draw_colored_polygon(face, STONE_FACE)
	# 状态 tint 覆面
	if face_tint.a > 0.0:
		draw_colored_polygon(face, face_tint)
	# 主题 accent 内缘细线（石台刻面）
	_stroke_hex(HEX_RADIUS * 0.78, Color(level_accent, 0.45), 1.0)
	# 状态描边（绿/黄/红）
	_stroke_hex(HEX_RADIUS, edge, 1.8)
