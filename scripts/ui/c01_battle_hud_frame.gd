class_name C01BattleHudFrame
extends Control
## 场景化战斗 HUD 框架：左上帆布徽记、右上舰队状态、底部操作条、海平线潮位。
const INK := Color("171b1d")
const CANVAS := Color("d8ccb5")
const CORAL := Color("ef684b")
const SEA := Color("5d8079")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _draw() -> void:
	# 两个小型实体化信息承载，不形成横贯屏幕的调试栏。
	draw_colored_polygon(PackedVector2Array([Vector2(6,6),Vector2(208,6),Vector2(218,54),Vector2(8,58)]),Color(INK,0.78))
	draw_line(Vector2(12,58),Vector2(205,55),Color(CANVAS,0.30),1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(464,8),Vector2(634,8),Vector2(632,49),Vector2(452,54)]),Color(INK,0.72))
	# 舰队三帆徽记。
	for i: int in 3:
		var x := 574.0+i*15.0
		draw_line(Vector2(x,18),Vector2(x,37),Color(CANVAS,0.58),1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x,18),Vector2(x,33),Vector2(x+9,31)]),Color(CANVAS,0.44))
	# 港灯图标。
	draw_rect(Rect2(468,20,6,22),Color(CANVAS,0.48))
	draw_circle(Vector2(471,18),4,CORAL)
	# 底部旧帆布操作条，中央留出战场。
	draw_colored_polygon(PackedVector2Array([Vector2(0,339),Vector2(420,339),Vector2(436,360),Vector2(0,360)]),Color(INK,0.82))
	draw_line(Vector2(0,338),Vector2(418,338),Color(CANVAS,0.26),1.0)
	# 低干扰潮位线横跨海平线。
	draw_line(Vector2(222,14),Vector2(446,14),Color(SEA,0.35),2.0)
	draw_circle(Vector2(333,14),3,CORAL)
