class_name C01ChartBackdrop
extends Control
## C01 player-shell backdrop: a restrained deep-sea chart behind all flow screens.
## Decorative only; input passes through and all coordinates target the 640x360 logical viewport.

const DEEP := Color("071622")
const SEA := Color("0c2a3b")
const GRID := Color("31546566")
const BRASS := Color("c59a4a")
const BRASS_DIM := Color("80652f")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), DEEP)
	# Broad bands and chart grid remain quiet enough for 12 px body text.
	draw_rect(Rect2(0, size.y * 0.18, size.x, size.y * 0.64), SEA)
	for x: int in range(0, int(size.x) + 1, 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), GRID, 1.0)
	for y: int in range(0, int(size.y) + 1, 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID, 1.0)
	# Route line and port nodes give every menu the same nautical-map silhouette.
	var route := PackedVector2Array([
		Vector2(18, 292), Vector2(116, 252), Vector2(216, 280),
		Vector2(330, 226), Vector2(438, 248), Vector2(622, 184),
	])
	draw_polyline(route, BRASS_DIM, 2.0, false)
	for point: Vector2 in route:
		draw_circle(point, 4.0, BRASS_DIM)
		draw_circle(point, 2.0, DEEP)
	# Corner rules read as a brass chart frame without competing with controls.
	var m := 10.0
	var arm := 28.0
	for corner: Vector2 in [Vector2(m, m), Vector2(size.x - m, m), Vector2(m, size.y - m), Vector2(size.x - m, size.y - m)]:
		var sx := 1.0 if corner.x < size.x * 0.5 else -1.0
		var sy := 1.0 if corner.y < size.y * 0.5 else -1.0
		draw_line(corner, corner + Vector2(arm * sx, 0), BRASS, 2.0)
		draw_line(corner, corner + Vector2(0, arm * sy), BRASS, 2.0)
