class_name C01HarborArt
extends Control
## C01 “最后一盏港灯”电影海报表现层。只绘制视觉，不接触流程或模拟。

enum Mode { TITLE, SLOT, CAMPAIGN, BRIEFING, RESULT_WIN, RESULT_LOSE }

const INK := Color("171b1d")
const ROCK := Color("252a29")
const ROCK_LIT := Color("3c403a")
const SEA_DARK := Color("203638")
const SEA := Color("355756")
const SEA_LIGHT := Color("53736d")
const MOON := Color("7eb0aa")
const BONE := Color("e8ddc8")
const CANVAS := Color("c9bda5")
const CORAL := Color("ef684b")
const EMBER := Color("ff9b55")
const GOLD := Color("e1b35e")
const DANGER := Color("2b8f94")

var mode: Mode = Mode.TITLE
var _time := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func set_mode(value: Mode) -> void:
	mode = value
	queue_redraw()

func _draw() -> void:
	C01SpriteLibrary.draw_harbor_background(self, int(mode), size)
	# Raster art carries the world; only atmosphere remains procedural.
	var fog_y := size.y * 0.55 + sin(_time * 0.22) * 2.0
	for i: int in 4:
		draw_rect(Rect2(0, fog_y + i * 7.0, size.x, 3.0), Color(MOON, 0.025 + i * 0.01))
	_draw_grain()
	_draw_vignette()

func _draw_sky_and_sea() -> void:
	for i: int in 24:
		var k := float(i) / 23.0
		var c := Color("202b2d").lerp(Color("52625d"), k)
		draw_rect(Rect2(0, i * 8.0, size.x, 9.0), c)
	var horizon := size.y * 0.53
	draw_rect(Rect2(0, horizon, size.x, size.y - horizon), SEA_DARK)
	for i: int in 16:
		var y := horizon + float(i) * 11.0
		var c := SEA.lerp(SEA_DARK, float(i) / 18.0)
		draw_rect(Rect2(0, y, size.x, 12), c)
	# 冷青暮潮压在远海，暖色只留给港灯。
	var tide_y := horizon + 8.0 + sin(_time * 0.32) * 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(310, tide_y), Vector2(size.x, tide_y - 22), Vector2(size.x, tide_y + 48),
		Vector2(440, tide_y + 29)
	]), Color(DANGER, 0.25))
	for i: int in 7:
		var y2 := horizon + 12.0 + i * 20.0 + sin(_time * 0.7 + i) * 1.5
		draw_line(Vector2(8 + (i % 2) * 35, y2), Vector2(size.x - 20, y2), Color(SEA_LIGHT, 0.16), 1.0)
	# 地平线雾带。
	for i: int in 5:
		draw_rect(Rect2(0, horizon - 14 + i * 6, size.x, 8), Color(MOON, 0.035 + i * 0.014))

func _draw_title_harbor() -> void:
	_draw_rock_mass(PackedVector2Array([Vector2(0,360),Vector2(0,258),Vector2(64,241),Vector2(126,272),Vector2(208,250),Vector2(270,360)]))
	_draw_lighthouse(Vector2(148, 294), 1.35, true, -0.045)
	_draw_fleet(Vector2(378, 210), 0.75, 5)
	_draw_tide_front(Vector2(455, 223), 1.0)
	# 前景浪与礁石强化纵深。
	draw_colored_polygon(PackedVector2Array([Vector2(0,337),Vector2(126,315),Vector2(240,333),Vector2(330,360),Vector2(0,360)]), Color(INK,0.78))
	_draw_foam_arc(Vector2(246, 329), 96, 0.32)

func _draw_slot_harbor() -> void:
	_draw_rock_mass(PackedVector2Array([Vector2(0,360),Vector2(0,300),Vector2(96,276),Vector2(205,304),Vector2(310,360)]))
	_draw_lighthouse(Vector2(98, 302), 0.78, true)
	_draw_fleet(Vector2(478, 210), 0.58, 4)

func _draw_campaign_harbor() -> void:
	# 海域画卷：C01 港口在左下，C02 潮门藏在右上远雾。
	_draw_rock_mass(PackedVector2Array([Vector2(0,360),Vector2(0,262),Vector2(82,239),Vector2(176,266),Vector2(252,321),Vector2(315,360)]))
	_draw_lighthouse(Vector2(118, 286), 0.72, true)
	_draw_fleet(Vector2(206, 250), 0.36, 3)
	# 潮门双礁柱。
	_draw_rock_mass(PackedVector2Array([Vector2(510,218),Vector2(528,132),Vector2(550,118),Vector2(565,221)]))
	_draw_rock_mass(PackedVector2Array([Vector2(590,214),Vector2(604,142),Vector2(628,122),Vector2(640,222)]))
	draw_line(Vector2(548,146), Vector2(612,145), Color(MOON,0.32), 2.0)
	for i: int in 6:
		draw_circle(Vector2(518 + i * 22, 172 + sin(i * 1.7) * 13), 20 + i * 3, Color(MOON,0.025))
	# 舰队航迹不是节点流程线。
	var wake := PackedVector2Array([Vector2(218,258),Vector2(285,238),Vector2(350,216),Vector2(420,190),Vector2(520,178)])
	draw_polyline(wake, Color(BONE,0.22), 3.0)
	draw_polyline(wake, Color(MOON,0.32), 1.0)
	_draw_tide_front(Vector2(468, 208), 0.78)

func _draw_briefing_harbor() -> void:
	_draw_rock_mass(PackedVector2Array([Vector2(0,360),Vector2(0,286),Vector2(108,254),Vector2(246,294),Vector2(334,360)]))
	_draw_lighthouse(Vector2(116, 296), 0.9, true)
	_draw_fleet(Vector2(472, 220), 0.6, 5)
	_draw_tide_front(Vector2(402, 224), 0.85)

func _draw_result_harbor(won: bool) -> void:
	_draw_rock_mass(PackedVector2Array([Vector2(0,360),Vector2(0,302),Vector2(124,279),Vector2(238,302),Vector2(320,360)]))
	_draw_fleet(Vector2(420, 214), 0.7, 6)
	_draw_lighthouse(Vector2(505, 300), 1.12, won)
	if won:
		_draw_foam_arc(Vector2(428,304), 130, 0.32)
	else:
		draw_rect(Rect2(0, 216, size.x, 144), Color("17383c",0.38))
		_draw_tide_front(Vector2(460, 238), 1.25)

func _draw_lighthouse(base: Vector2, scale: float, lit: bool, lean: float = 0.0) -> void:
	var h := 112.0 * scale
	var w := 31.0 * scale
	var top := base + Vector2(lean * h, -h)
	# 灯束在塔后。
	if lit:
		var pulse := 0.82 + sin(_time * 1.4) * 0.08
		var lantern := top + Vector2(0, 12 * scale)
		draw_colored_polygon(PackedVector2Array([lantern, lantern + Vector2(250*scale,-54*scale), lantern + Vector2(255*scale,20*scale)]), Color(CORAL,0.075*pulse))
		draw_colored_polygon(PackedVector2Array([lantern, lantern + Vector2(-150*scale,-28*scale), lantern + Vector2(-146*scale,17*scale)]), Color(EMBER,0.055*pulse))
	# 塔身剪影和受光面。
	var body := PackedVector2Array([base+Vector2(-w*.72,0),base+Vector2(w*.72,0),top+Vector2(w*.40,20*scale),top+Vector2(-w*.40,20*scale)])
	draw_colored_polygon(body, INK)
	var face := PackedVector2Array([base+Vector2(-w*.35,-3),base+Vector2(w*.1,-3),top+Vector2(w*.12,22*scale),top+Vector2(-w*.28,22*scale)])
	draw_colored_polygon(face, ROCK_LIT)
	# 台栏、屋顶、灯室。
	draw_rect(Rect2(top+Vector2(-w*.62,15*scale),Vector2(w*1.24,5*scale)),INK)
	draw_rect(Rect2(top+Vector2(-w*.40,2*scale),Vector2(w*.80,15*scale)),Color("352e29"))
	draw_colored_polygon(PackedVector2Array([top+Vector2(-w*.52,3*scale),top+Vector2(w*.52,3*scale),top+Vector2(0,-8*scale)]),INK)
	if lit:
		draw_rect(Rect2(top+Vector2(-w*.28,5*scale),Vector2(w*.56,9*scale)),CORAL)
		draw_circle(top+Vector2(0,9*scale),4.2*scale,Color("ffd18b"))
		draw_circle(top+Vector2(0,9*scale),10*scale,Color(EMBER,0.14))
	else:
		draw_rect(Rect2(top+Vector2(-w*.28,5*scale),Vector2(w*.56,9*scale)),Color("26383a"))
	# 石阶与门。
	draw_rect(Rect2(base+Vector2(-w*.17,-21*scale),Vector2(w*.34,21*scale)),Color("111719"))
	draw_line(base+Vector2(-w*.65,-34*scale),base+Vector2(w*.55,-38*scale),Color(CANVAS,0.24),1.0)

func _draw_ship(pos: Vector2, scale: float, sail_tint: Color = CANVAS) -> void:
	var bob := sin(_time * 0.8 + pos.x * 0.02) * 1.3 * scale
	var p := pos + Vector2(0,bob)
	draw_colored_polygon(PackedVector2Array([p+Vector2(-25,7)*scale,p+Vector2(24,7)*scale,p+Vector2(15,15)*scale,p+Vector2(-15,15)*scale]),INK)
	draw_line(p+Vector2(0,8)*scale,p+Vector2(0,-29)*scale,INK,2.2*scale)
	draw_colored_polygon(PackedVector2Array([p+Vector2(1,-27)*scale,p+Vector2(1,1)*scale,p+Vector2(20,-2)*scale]),Color(sail_tint,0.68))
	draw_colored_polygon(PackedVector2Array([p+Vector2(-2,-23)*scale,p+Vector2(-2,0)*scale,p+Vector2(-16,-5)*scale]),Color(MOON,0.35))
	draw_line(p+Vector2(-18,17)*scale,p+Vector2(22,17)*scale,Color(BONE,0.20),1.0)

func _draw_fleet(origin: Vector2, scale: float, count: int) -> void:
	for i: int in count:
		var row := i % 3
		var col := i / 3
		_draw_ship(origin + Vector2(col * 80 + row * 21, row * 31), scale * (1.0 - row*0.09), CANVAS.lerp(MOON,float(row)*0.18))

func _draw_tide_front(pos: Vector2, scale: float) -> void:
	for i: int in 5:
		var p := pos + Vector2(i*34*scale, sin(i*1.9+_time*.5)*6)
		draw_arc(p, (18+i*3)*scale, PI*1.02, PI*1.92, 18, Color(MOON,0.20-i*.018), 3.0*scale)
		draw_circle(p+Vector2(2,-2),2.2*scale,Color(DANGER,0.55))

func _draw_rock_mass(points: PackedVector2Array) -> void:
	draw_colored_polygon(points, ROCK)
	if points.size() > 2:
		draw_polyline(points, Color(ROCK_LIT,0.72), 2.0)

func _draw_foam_arc(center: Vector2, radius: float, alpha: float) -> void:
	for i: int in 3:
		draw_arc(center+Vector2(i*12,0),radius-i*18,PI*1.08,PI*1.82,28,Color(BONE,alpha-i*.07),1.2)

func _draw_grain() -> void:
	# 固定颗粒，避免每帧随机抖动。
	for i: int in 150:
		var x := fmod(float(i * 83 + 17), maxf(size.x,1.0))
		var y := fmod(float(i * 47 + 29), maxf(size.y,1.0))
		var a := 0.025 + float(i % 5) * 0.006
		draw_circle(Vector2(x,y),0.55,Color(BONE,a))

func _draw_vignette() -> void:
	draw_rect(Rect2(0,0,size.x,18),Color(INK,0.22))
	draw_rect(Rect2(0,size.y-24,size.x,24),Color(INK,0.34))
	draw_rect(Rect2(0,0,18,size.y),Color(INK,0.22))
	draw_rect(Rect2(size.x-18,0,18,size.y),Color(INK,0.28))
