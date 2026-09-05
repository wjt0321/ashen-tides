class_name PathNetwork
extends Node2D
## 预制 PathNetwork 可视化（M3 主题化）：路线画成“路”——road_bed 深底 + road_inner 内芯 +
## 沿线 48px 一个地面方向箭头（PRD §4.3，指向终点）；入口三层同心圆环 portal、出口方块
## 闸门。未激活路线整体 alpha×0.35。颜色全部取自 VisualTheme.palette_for(level_id)，
## 主色经 UiPalette.apply 无障碍重映射。
## 契约：RESEARCH_REPORT.md §5 / PRD §18.3 —— 普通敌人只走预制 PathRoute，不使用实时 A*
## 寻路；相位切换通过 activate_route / deactivate_route 完成（本类纯可视化，无 sim 逻辑）。

# —— 路幅 / 标记常量（px）——
const ROAD_BED_WIDTH := 14.0 # 路底宽
const ROAD_INNER_WIDTH := 8.0 # 路内芯宽
const ARROW_SPACING := 48.0 # 地面箭头间距
const ARROW_LENGTH := 6.0 # 箭头长
const ARROW_HALF_W := 3.0 # 箭头半翼宽
const INACTIVE_ALPHA := 0.35 # 未激活路线整体透明度
const PORTAL_RING_R := [9.0, 6.0, 3.0] # 入口同心圆环半径（外 → 内）
const GATE_HALF := Vector2(10.0, 9.0) # 出口门框半尺寸：半宽沿路线方向、半高垂直

## route_id -> PackedVector2Array（路线折线点，正式版由 Segment.curve 提供）
var routes: Dictionary = {}
## route_id -> true
var active_routes: Dictionary = {}
## 当前主题关卡（main 赋值；调色板取色依据，兜底 C01）。
var level_id: StringName = &"level_c01"
## route_id -> Array[PackedVector2Array]：预计算方向箭头三角形（纯几何，与主题无关）
var _arrow_tris: Dictionary = {}


func add_route(route_id: StringName, points: PackedVector2Array, active: bool) -> void:
	routes[route_id] = points
	if active:
		active_routes[route_id] = true
	_arrow_tris[route_id] = _build_arrow_tris(points)
	queue_redraw()


func activate_route(route_id: StringName) -> void:
	if routes.has(route_id):
		active_routes[route_id] = true
		queue_redraw()


func deactivate_route(route_id: StringName) -> void:
	if active_routes.erase(route_id):
		queue_redraw()


func is_route_active(route_id: StringName) -> bool:
	return active_routes.has(route_id)


## 沿折线每 ARROW_SPACING 生成一个朝终点的小三角（终点前 24px 留白，避免压住闸门）。
func _build_arrow_tris(points: PackedVector2Array) -> Array[PackedVector2Array]:
	var tris: Array[PackedVector2Array] = []
	var total_len := 0.0
	for i: int in range(1, points.size()):
		total_len += points[i].distance_to(points[i - 1])
	var limit := total_len - 30.0 # 终点前留白，避免箭头压住出口闸门
	var next_dist := ARROW_SPACING
	var acc := 0.0
	for i: int in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var seg := b - a
		var seg_len := seg.length()
		if seg_len < 0.001:
			continue
		var dir := seg / seg_len
		var perp := Vector2(-dir.y, dir.x)
		while next_dist <= limit and next_dist <= acc + seg_len:
			var t := (next_dist - acc) / seg_len
			var pos := a.lerp(b, t)
			var tip := pos + dir * ARROW_LENGTH
			var base := pos - dir * (ARROW_LENGTH * 0.5)
			tris.append(PackedVector2Array([tip, base + perp * ARROW_HALF_W, base - perp * ARROW_HALF_W]))
			next_dist += ARROW_SPACING
		acc += seg_len
	return tris


func _draw() -> void:
	var pal := VisualTheme.palette_for(level_id)
	var bed := UiPalette.apply(pal["road_bed"])
	var inner := UiPalette.apply(pal["road_inner"])
	var accent := UiPalette.apply(pal["accent"])
	var glow := UiPalette.apply(pal["glow"])
	# 先画未激活路线：激活路线后画并压在共享段上，保持连续且不受半透明叠加影响
	for route_id: StringName in routes:
		if not active_routes.has(route_id):
			_draw_route(route_id, INACTIVE_ALPHA, bed, inner, accent, glow)
	for route_id: StringName in routes:
		if active_routes.has(route_id):
			_draw_route(route_id, 1.0, bed, inner, accent, glow)


func _draw_route(route_id: StringName, alpha: float, bed: Color, inner: Color, accent: Color, glow: Color) -> void:
	var points: PackedVector2Array = routes[route_id]
	if points.size() < 2:
		return
	# 路：深色路底 + 内芯
	var bed_c := bed
	bed_c.a *= alpha
	draw_polyline(points, bed_c, ROAD_BED_WIDTH)
	var inner_c := inner
	inner_c.a *= alpha
	draw_polyline(points, inner_c, ROAD_INNER_WIDTH)
	# 地面方向箭头（accent，指向终点）
	var arrow_col := Color(accent.r, accent.g, accent.b, accent.a * alpha)
	for tri in _arrow_tris.get(route_id, []):
		draw_colored_polygon(tri, arrow_col)
	# 入口 portal / 出口闸门
	_draw_portal(points[0], alpha, accent, glow)
	_draw_gate(points[points.size() - 2], points[points.size() - 1], alpha, bed, accent)


## 入口：三层同心圆环 portal（accent / glow 交替；激活时最亮，另加一圈外泛光）。
func _draw_portal(center: Vector2, alpha: float, accent: Color, glow: Color) -> void:
	if alpha >= 1.0:
		draw_circle(center, PORTAL_RING_R[0] + 4.0, Color(glow.r, glow.g, glow.b, 0.08))
	var ring_glow := Color(glow.r, glow.g, glow.b, glow.a * alpha)
	var ring_accent := Color(accent.r, accent.g, accent.b, accent.a * alpha)
	draw_arc(center, PORTAL_RING_R[0], 0.0, TAU, 28, ring_glow, 2.0)
	draw_arc(center, PORTAL_RING_R[1], 0.0, TAU, 24, ring_accent, 1.5)
	draw_arc(center, PORTAL_RING_R[2], 0.0, TAU, 16, ring_glow, 1.0)


## 出口：方块门形 + accent 描边（舰队闸门意象），门框落在终点内侧，中缝沿行进方向。
func _draw_gate(prev: Vector2, exit_pt: Vector2, alpha: float, bed: Color, accent: Color) -> void:
	var dir := exit_pt - prev
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	dir = dir.normalized()
	var center := exit_pt - dir * (GATE_HALF.x + 4.0)
	var gate_rect := Rect2(center - GATE_HALF, GATE_HALF * 2.0)
	draw_rect(gate_rect, Color(bed.r, bed.g, bed.b, 0.85 * alpha), true)
	draw_rect(gate_rect, Color(accent.r, accent.g, accent.b, accent.a * alpha), false, 2.0)
	var seam := dir * (GATE_HALF.x - 2.0)
	draw_line(center - seam, center + seam, Color(accent.r, accent.g, accent.b, accent.a * alpha * 0.6), 1.0)
