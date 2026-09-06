class_name C01Emblem
extends Control
## C01 v2 title sigil: tide + beacon + ember, drawn procedurally (no blue star).

func _ready() -> void:
	custom_minimum_size = Vector2(96, 58)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var brass := Color("c9a96e")
	var ember := Color("ef7d32")
	var sea := Color("4f93a8")
	var c := Vector2(48, 29)
	# Tide arcs.
	for i in 3:
		draw_arc(c + Vector2(0, 13 + i * 3), 19.0 + i * 7.0, PI * 1.08, PI * 1.92, 24, Color(sea, 0.85 - i * 0.18), 2.0)
	# Beacon mast and lantern.
	draw_line(c + Vector2(0, 10), c + Vector2(0, -13), brass, 3.0)
	draw_line(c + Vector2(-8, 10), c + Vector2(8, 10), brass, 2.0)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0,-20), c + Vector2(6,-11), c + Vector2(0,-7), c + Vector2(-6,-11)]), ember)
	draw_circle(c + Vector2(0,-13), 2.2, Color("fff0b2"))
	# Two restrained beacon rays.
	draw_line(c + Vector2(-8,-13), c + Vector2(-25,-18), Color(brass, .55), 1.0)
	draw_line(c + Vector2(8,-13), c + Vector2(25,-18), Color(brass, .55), 1.0)
