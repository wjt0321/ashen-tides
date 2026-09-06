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
	C01SpriteLibrary.draw_briefing_map(self, Rect2(Vector2.ZERO, size))

func _draw_walker() -> void:
	C01SpriteLibrary.draw_briefing_subject(self, 1, Rect2(Vector2(5, 0), size - Vector2(10, 2)))

func _draw_rats() -> void:
	C01SpriteLibrary.draw_briefing_subject(self, 2, Rect2(Vector2(0, 2), Vector2(48, 48)))

func _draw_tower() -> void:
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
