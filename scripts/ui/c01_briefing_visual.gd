class_name C01BriefingVisual
extends Control
## C01 简报缩略战场与敌人轮廓。纯视觉节点。

enum Kind { MAP, WALKER, RATS, TOWER, MARKS }
const INK := Color("171b1d")
const ROCK := Color("303633")
const SEA := Color("345553")
const FOAM := Color("91b4aa")
const BONE := Color("e8ddc8")
const CORAL := Color("ef684b")
const EMBER := Color("ff9b55")
var kind: Kind = Kind.MAP
var mark_count := 3
var level_id: StringName = &"level_c01"
var subject_id: StringName = &""

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	match kind:
		Kind.MAP: _draw_map()
		Kind.WALKER: _draw_walker()
		Kind.RATS: _draw_rats()
		Kind.TOWER: _draw_tower()
		Kind.MARKS: _draw_marks()

func _draw_map() -> void:
	if level_id == &"level_c02":
		_draw_c02_map()
		return
	C01SpriteLibrary.draw_briefing_map(self, Rect2(Vector2.ZERO, size))

func _draw_walker() -> void:
	if level_id == &"level_c02" and subject_id != &"":
		_draw_c02_subject(subject_id, size)
		return
	C01SpriteLibrary.draw_briefing_subject(self, 1, Rect2(Vector2(5, 0), size - Vector2(10, 2)))

func _draw_rats() -> void:
	if level_id == &"level_c02" and subject_id != &"":
		_draw_c02_subject(subject_id, size)
		return
	C01SpriteLibrary.draw_briefing_subject(self, 2, Rect2(Vector2(0, 2), Vector2(48, 48)))

func _draw_tower() -> void:
	if level_id == &"level_c02" and subject_id != &"":
		var tex := ArtLibrary.c02_tower_tex(subject_id, 1)
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2(4, -1), Vector2(58, 58)), false)
			return
	C01SpriteLibrary.draw_briefing_subject(self, 3, Rect2(Vector2(-8, -10), size + Vector2(16, 16)))

func _draw_marks() -> void:
	for i: int in 3:
		var c := Vector2(20+i*42,22)
		if i >= mark_count:
			draw_circle(c,15,Color("303735"))
			draw_circle(c,12,Color("53605b"))
			continue
		draw_circle(c,15,Color("7b3f30"))
		draw_circle(c,12,Color(CORAL,0.82))
		draw_line(c+Vector2(-5,1),c+Vector2(-1,6),BONE,2.0)
		draw_line(c+Vector2(-1,6),c+Vector2(7,-6),BONE,2.0)


func _draw_c02_subject(enemy_id: StringName, extent: Vector2) -> void:
	var tex := ArtLibrary.c02_enemy_tex(enemy_id)
	if tex == null:
		C01SpriteLibrary.draw_briefing_subject(self, 2, Rect2(Vector2(0, 2), Vector2(48, 48)))
		return
	var side := minf(extent.x, extent.y) * 0.78
	draw_texture_rect(tex, Rect2(Vector2((extent.x - side) * 0.5, (extent.y - side) * 0.5), Vector2(side, side)), false)


func _draw_c02_map() -> void:
	var panel := Rect2(Vector2.ZERO, size)
	draw_rect(panel, Color("102a31", 0.88), true)
	draw_rect(panel, Color("8acfc0", 0.48), false, 2.0)
	for x in range(16, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color("8acfc0", 0.07), 1.0)
	for y in range(16, int(size.y), 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("8acfc0", 0.07), 1.0)
	var a := Vector2(12, size.y * 0.54)
	var b := Vector2(size.x * 0.54, size.y * 0.54)
	var c := Vector2(size.x - 16, size.y - 22)
	var d := Vector2(size.x * 0.74, 28)
	draw_polyline(PackedVector2Array([a, b, c]), Color("e8ddc8", 0.88), 5.0)
	draw_polyline(PackedVector2Array([a, Vector2(size.x * 0.68, size.y * 0.54), d, Vector2(size.x - 16, 28)]), Color("6ee0cb", 0.92), 5.0)
	draw_circle(a, 6.0, Color("ef684b"))
	draw_circle(c, 6.0, Color("ef684b"))
	draw_circle(d, 6.0, Color("6ee0cb"))
	var gate := ArtLibrary.c02_landmark_tex("tide_gate_closed")
	if gate != null:
		draw_texture_rect(gate, Rect2(Vector2(size.x * 0.57, size.y * 0.24), Vector2(96, 67)), false)
