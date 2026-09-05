class_name GreyboxMap
extends Node2D
## 程序化灰盒地形（M3 视觉主题化）：海底 32×32 双色格 + 确定性浪饰，陆地 land_a/land_b
## 双色斑块 + 岸线描边 + hash 撒石砾，再按关卡叠 1–2 个主题小元素（灯塔光晕 / 断桥板条 /
## 盐壳白斑 / 暗红裂缝等）。装饰在 setup/_ready 预计算进数组，_draw 只遍历绘制、不现算 hash；
## 颜色全部来自 VisualTheme.palette_for(level_id)，主体色块过 UiPalette.apply 无障碍重映射。
## 正式地形使用 TileMapLayer 分层（RESEARCH_REPORT.md §6.2），本节点仅作可视化。

const CELL := 32
const VIEWPORT_SIZE := Vector2(640, 360)
const GRID_COLS := 20
const GRID_ROWS := 12
const GRID_ALPHA := 0.03 # 淡网格线（只压海面）
const FOAM_DENSITY := 0.12 # 浪尖装饰密度（约 12%）
const PEBBLE_DENSITY := 0.10 # 陆上石砾 / 盐壳点密度
const DASH_LEN := 5.0 # 浪尖短划线长度（px）
const PATCH_MIN := 0.30 # 陆地双色斑块：hash 落在此区间才补一块 land_b
const PATCH_MAX := 0.80

## 陆地块占位（左上角像素坐标 + 尺寸，均为 32 的整数倍）。
## 灰盒期 8 关共用同一海岸骨架，关卡差异靠调色板与 match 小元素表达。
const ROCK_RECTS: Array[Rect2] = [
	Rect2(Vector2(0, 0), Vector2(640, 64)),
	Rect2(Vector2(0, 352), Vector2(640, 8)),
	Rect2(Vector2(0, 64), Vector2(64, 96)),
	Rect2(Vector2(576, 128), Vector2(64, 64)),
]

## 当前主题关卡（main 会在 setup 前赋值；未 setup 时兜底 C01）。
var level_id: StringName = &"level_c01"
## NEXT_PHASE C：资产替换试验开关（AT-TER-001 Buch Outdoor 32×32, CC0）。
## 仅 --asset-trial 命令行开启；仅作用 C01 顶部岸带与右岸礁岛，试验后决定去留。
var asset_trial := false
const TRIAL_SHEET := "res://assets/art/tilesets/buch/sheet_12.png"
## 候选 tile 源区域（sheet 内 32×32 岩石块）。
const TRIAL_TILES: Array[Rect2] = [
	Rect2(0, 0, 32, 32), Rect2(32, 0, 32, 32), Rect2(0, 32, 32, 32),
]
var _trial_tex: Texture2D = null
## 相位氛围叠加（main 驱动：明潮 VisualTheme.TINT_MINGCHAO / 暮潮 TINT_MUCHAO）。
## alpha > 0 时 _draw 末尾整屏叠加，只罩本层地形与后续节点之下。
var phase_tint := Color(0, 0, 0, 0)

# —— 预计算装饰缓存（setup/_ready 填充，_draw 只遍历）——
var _sea_dashes := PackedVector2Array() # 浪尖短划线起点
var _sea_dots := PackedVector2Array() # 泡沫点圆心
var _land_patches: Array[Rect2] = [] # land_b 双色斑块
var _land_pebbles := PackedVector2Array() # 石砾 / 盐壳点圆心
var _land_pebble_radii := PackedFloat32Array() # 与上面对齐的半径


func _ready() -> void:
	_precompute_decor()


## 切换关卡主题并重算装饰（main 调用；散布确定性依赖 level_id 种子）。
func setup(p_level_id: StringName = &"level_c01") -> void:
	level_id = p_level_id
	_precompute_decor()
	queue_redraw()


func _precompute_decor() -> void:
	var seed := _decor_seed(level_id)
	_sea_dashes.clear()
	_sea_dots.clear()
	_land_patches.clear()
	_land_pebbles.clear()
	_land_pebble_radii.clear()
	for row: int in GRID_ROWS:
		for col: int in GRID_COLS:
			var cell := Rect2(Vector2(col * CELL, row * CELL), Vector2(CELL, CELL))
			var center := cell.get_center()
			if _is_on_land(center):
				_prepare_land_cell(cell, col, row, seed)
			elif row < GRID_ROWS - 1:
				_prepare_sea_cell(cell, col, row, seed)


## 单元格中心落在任一块陆地上即视为陆格。
func _is_on_land(point: Vector2) -> bool:
	for rect: Rect2 in ROCK_RECTS:
		if rect.has_point(point):
			return true
	return false


## 海格装饰：浪尖短划线 / 泡沫点二选一（颜色统一 sea_foam 低 alpha，密度 FOAM_DENSITY）。
func _prepare_sea_cell(cell: Rect2, col: int, row: int, seed: int) -> void:
	if VisualTheme.cell_hash(col, row, seed) <= 1.0 - FOAM_DENSITY:
		return
	if VisualTheme.cell_hash(col, row, seed + 7) > 0.5:
		var dx := 4.0 + VisualTheme.cell_hash(row, col, seed + 3) * float(CELL - 8.0 - DASH_LEN)
		var dy := 4.0 + VisualTheme.cell_hash(col, row, seed + 5) * float(CELL - 8.0)
		_sea_dashes.append(cell.position + Vector2(dx, dy))
	else:
		var px := 6.0 + VisualTheme.cell_hash(row, col, seed + 11) * float(CELL - 12.0)
		var py := 6.0 + VisualTheme.cell_hash(col, row, seed + 13) * float(CELL - 12.0)
		_sea_dots.append(cell.position + Vector2(px, py))


## 陆格装饰：可选 land_b 斑块 + 石砾 / 盐壳小点（accent 低 alpha）。
func _prepare_land_cell(cell: Rect2, col: int, row: int, seed: int) -> void:
	var h := VisualTheme.cell_hash(col, row, seed)
	if h > PATCH_MIN and h < PATCH_MAX:
		var ox := 4.0 + VisualTheme.cell_hash(row, col, seed + 1) * 10.0
		var oy := 4.0 + VisualTheme.cell_hash(col, row, seed + 2) * 10.0
		var size := 12.0 + VisualTheme.cell_hash(row, col, seed + 3) * 6.0
		_land_patches.append(Rect2(cell.position + Vector2(ox, oy), Vector2(size, size)))
	if VisualTheme.cell_hash(col, row, seed + 5) < PEBBLE_DENSITY:
		var qx := VisualTheme.cell_hash(row, col, seed + 6)
		var qy := VisualTheme.cell_hash(col, row, seed + 7)
		_land_pebbles.append(cell.position + Vector2(6.0 + qx * 20.0, 6.0 + qy * 20.0))
		_land_pebble_radii.append(1.0 if qx > 0.5 else 1.5)


## 关卡确定性种子：level_id 逐字符哈希，保证同一关装饰图案稳定、关间不同。
func _decor_seed(p_level_id: StringName) -> int:
	var s := 0
	var key := String(p_level_id)
	for i: int in key.length():
		s = (s * 31 + key.unicode_at(i)) & 0x7FFFFFFF
	return s


func _draw() -> void:
	var pal := VisualTheme.palette_for(level_id)
	var sea_a := UiPalette.apply(pal["sea_a"])
	var sea_b := UiPalette.apply(pal["sea_b"])
	var foam := UiPalette.apply(pal["sea_foam"])
	var land_a := UiPalette.apply(pal["land_a"])
	var land_b := UiPalette.apply(pal["land_b"])
	var edge := UiPalette.apply(pal["land_edge"])
	var accent := UiPalette.apply(pal["accent"])
	var glow := UiPalette.apply(pal["glow"])
	var viewport := Rect2(Vector2.ZERO, VIEWPORT_SIZE)
	# M4-A：正式地形 tile 优先（仅已生产关卡，如 C01），缺失回退纯色格
	var sea_tex_a := ArtLibrary.terrain_tex(level_id, "sea_a")
	var sea_tex_b := ArtLibrary.terrain_tex(level_id, "sea_b")
	var land_tex_a := ArtLibrary.terrain_tex(level_id, "land_a")
	var land_tex_b := ArtLibrary.terrain_tex(level_id, "land_b")
	# 海底：双色 32px 格
	for row: int in GRID_ROWS:
		for col: int in GRID_COLS:
			var cell := Rect2(Vector2(col * CELL, row * CELL), Vector2(CELL, CELL))
			var clipped := cell.intersection(viewport)
			var use_a := (row + col) % 2 == 0
			var sea_tex := sea_tex_a if use_a else sea_tex_b
			if sea_tex != null:
				draw_texture(sea_tex, clipped.position)
			else:
				draw_rect(clipped, sea_a if use_a else sea_b, true)
	# 淡网格线（alpha 0.03，只压海面；陆地稍后盖掉）
	var grid := Color(1.0, 1.0, 1.0, GRID_ALPHA)
	for col: int in GRID_COLS + 1:
		var x := float(col * CELL)
		draw_line(Vector2(x, 0), Vector2(x, VIEWPORT_SIZE.y), grid, 1.0)
	for row: int in GRID_ROWS + 1:
		var y := float(row * CELL)
		draw_line(Vector2(0, y), Vector2(VIEWPORT_SIZE.x, y), grid, 1.0)
	# 浪饰：短划线 + 泡沫点（sea_foam 低 alpha）
	var dash_col := Color(foam.r, foam.g, foam.b, 0.22)
	for p: Vector2 in _sea_dashes:
		draw_line(p, p + Vector2(DASH_LEN, 0), dash_col, 1.0)
	var dot_col := Color(foam.r, foam.g, foam.b, 0.18)
	for p: Vector2 in _sea_dots:
		draw_circle(p, 1.0, dot_col)
	# 陆地：land_a 底 + land_b 斑块 + 石砾点（M4-A：正式 land tile 优先）
	for rect: Rect2 in ROCK_RECTS:
		if land_tex_a != null:
			var cols := int(rect.size.x) / CELL
			var rows := int(rect.size.y) / CELL
			for row: int in rows:
				for col: int in cols:
					draw_texture(land_tex_a, rect.position + Vector2(col * CELL, row * CELL))
		else:
			draw_rect(rect, land_a, true)
	for patch: Rect2 in _land_patches:
		draw_rect(patch, land_b, true)
	var pebble_col := Color(accent.r, accent.g, accent.b, 0.16)
	for i: int in _land_pebbles.size():
		draw_circle(_land_pebbles[i], _land_pebble_radii[i], pebble_col)
	# 岸线：沿陆块边缘 2px 亮线模拟海岸
	for rect: Rect2 in ROCK_RECTS:
		draw_rect(rect, edge, false, 2.0)
	# 每关主题小元素
	_draw_level_flavor(land_a, land_b, edge, accent, glow, foam)
	# NEXT_PHASE C 资产替换试验：Buch 岩石 tile 覆写 C01 岸带（暗化 tint 贴合夜港调色板）
	if asset_trial and level_id == &"level_c01":
		_draw_asset_trial()
	# 相位氛围（alpha > 0 才画整屏 tint）
	if phase_tint.a > 0.0:
		draw_rect(viewport, phase_tint, true)


## 每关 1–2 个独特小元素（简单几笔；坐标按 640×360 视口手摆）。
func _draw_level_flavor(land_a: Color, land_b: Color, edge: Color, accent: Color, glow: Color, foam: Color) -> void:
	match level_id:
		&"level_c01":
			# 黄昏港岸：右岸礁岛两根栈桥桩，桩顶锚灯微光
			var pile := VisualTheme.shade(land_b, 0.75)
			draw_rect(Rect2(580, 132, 5, 20), pile, true)
			draw_rect(Rect2(596, 146, 5, 18), pile, true)
			draw_rect(Rect2(579, 128, 7, 4), glow, true)
			draw_rect(Rect2(595, 142, 7, 4), glow, true)
		&"level_c02":
			# 雾中潮门：主水道两侧残留闸柱，夹住 x=480 上行潮道
			var pillar := VisualTheme.shade(land_b, 0.7)
			draw_rect(Rect2(458, 84, 6, 96), pillar, true)
			draw_rect(Rect2(496, 84, 6, 96), pillar, true)
			draw_rect(Rect2(456, 82, 10, 3), VisualTheme.shade(land_a, 0.8), true)
			draw_rect(Rect2(494, 82, 10, 3), VisualTheme.shade(land_a, 0.8), true)
			# 海雾带：上缘一段淡色雾弧
			var fog := Color(foam.r, foam.g, foam.b, 0.10)
			draw_arc(Vector2(300, -60), 220.0, 0.0, PI, 24, fog, 3.0)
		&"level_c03":
			# 失火灯塔：右上礁岛两层光晕圆弧 + 塔灯光源
			var beacon := Vector2(600, 140)
			draw_circle(beacon, 3.0, glow)
			draw_circle(beacon, 1.5, accent)
			draw_arc(beacon, 13.0, deg_to_rad(205.0), deg_to_rad(335.0), 16,
					Color(accent.r, accent.g, accent.b, 0.5), 2.0)
			draw_arc(beacon, 21.0, deg_to_rad(195.0), deg_to_rad(345.0), 20,
					Color(glow.r, glow.g, glow.b, 0.25), 2.0)
		&"level_c04":
			# 白盐岬：岸陆上结一片片盐壳白斑
			var crust := Color(glow.r, glow.g, glow.b, 0.55)
			for spot: Rect2 in [
				Rect2(72, 10, 9, 5), Rect2(96, 20, 6, 4), Rect2(118, 8, 11, 5),
				Rect2(150, 18, 7, 5), Rect2(186, 12, 10, 4), Rect2(228, 24, 6, 4),
				Rect2(266, 10, 12, 5), Rect2(308, 20, 6, 4), Rect2(352, 12, 9, 5),
				Rect2(400, 22, 5, 4), Rect2(448, 8, 11, 6), Rect2(500, 16, 7, 5),
				Rect2(552, 22, 8, 4), Rect2(16, 84, 8, 5), Rect2(34, 116, 10, 5),
				Rect2(20, 140, 7, 4),
			]:
				draw_rect(spot, crust, true)
		&"level_c05":
			# 漂木渡口：水道漂几根朽木，带青苔点
			var wood := VisualTheme.shade(land_a, 1.1)
			var wood_dark := VisualTheme.shade(land_a, 0.9)
			draw_rect(Rect2(398, 236, 20, 4), wood, true)
			draw_rect(Rect2(420, 248, 14, 4), wood_dark, true)
			draw_rect(Rect2(452, 232, 18, 4), wood, true)
			draw_rect(Rect2(468, 250, 12, 4), wood_dark, true)
			var moss := Color(accent.r, accent.g, accent.b, 0.5)
			draw_rect(Rect2(402, 237, 2, 2), moss, true)
			draw_rect(Rect2(456, 233, 2, 2), moss, true)
		&"level_c06":
			# 锈帆滩：沉船肋骨拱出水面，钉几颗锈点
			var hull := VisualTheme.shade(land_b, 0.9)
			var hull_light := VisualTheme.shade(land_b, 1.15)
			draw_arc(Vector2(430, 238), 34.0, deg_to_rad(200.0), deg_to_rad(340.0), 24, hull, 3.0)
			draw_arc(Vector2(508, 240), 22.0, deg_to_rad(200.0), deg_to_rad(340.0), 16, hull_light, 2.0)
			var rust := Color(accent.r, accent.g, accent.b, 0.6)
			draw_circle(Vector2(432, 206), 1.5, rust)
			draw_circle(Vector2(446, 210), 1.0, rust)
			draw_circle(Vector2(508, 220), 1.2, rust)
		&"level_c07":
			# 潮脊断桥：上段主路残留的桥面板条横跨水道（留断口）
			var plank := VisualTheme.shade(land_b, 1.25)
			var grain := VisualTheme.blend(land_b, edge, 0.6)
			for px: float in [340.0, 388.0, 436.0, 484.0, 532.0, 568.0]:
				draw_rect(Rect2(px - 3.0, 148.0, 6.0, 24.0), plank, true)
				draw_rect(Rect2(px - 3.0, 148.0, 6.0, 2.0), grain, true)
		&"level_c08":
			# 吞锚蟹巢：陆上暗红裂缝 + 缝口渗出的红光
			var crack := VisualTheme.shade(accent, 0.45)
			draw_polyline(PackedVector2Array([Vector2(120, 14), Vector2(140, 30), Vector2(128, 48), Vector2(148, 62)]),
					crack, 1.5)
			draw_polyline(PackedVector2Array([Vector2(560, 20), Vector2(572, 36), Vector2(562, 52)]), crack, 1.5)
			draw_polyline(PackedVector2Array([Vector2(12, 84), Vector2(26, 100), Vector2(16, 122), Vector2(34, 148)]),
					crack, 1.5)
			var vent := Color(accent.r, accent.g, accent.b, 0.5)
			draw_circle(Vector2(148, 62), 2.0, vent)
			draw_circle(Vector2(34, 148), 2.0, vent)
		&"level_c09":
			# 玻璃芦径：水面竖几丛玻璃苇（半透明竖茎 + 顶穗）
			var reed := Color(accent.r, accent.g, accent.b, 0.55)
			var tip := Color(glow.r, glow.g, glow.b, 0.7)
			for rp: Vector2 in [Vector2(120, 210), Vector2(500, 130), Vector2(210, 330)]:
				draw_line(rp, rp + Vector2(0, -12), reed, 2.0)
				draw_line(rp + Vector2(4, 0), rp + Vector2(4, -9), reed, 1.5)
				draw_circle(rp + Vector2(0, -13), 1.6, tip)
				draw_circle(rp + Vector2(4, -10), 1.2, tip)
		&"level_c10":
			# 孢光洼地：地表散落荧光孢囊（小圆簇 + 微光晕）
			var spore := Color(glow.r, glow.g, glow.b, 0.6)
			var halo := Color(glow.r, glow.g, glow.b, 0.18)
			for sp: Vector2 in [Vector2(150, 60), Vector2(420, 110), Vector2(540, 300), Vector2(90, 250)]:
				draw_circle(sp, 5.0, halo)
				draw_circle(sp, 2.0, spore)
				draw_circle(sp + Vector2(4, 2), 1.2, spore)
		&"level_c11":
			# 倒映之路：水面画镜像银纹（成对的水平亮线，上下对称）
			var mirror_line := Color(foam.r, foam.g, foam.b, 0.35)
			for mx: float in [80.0, 240.0, 420.0, 560.0]:
				draw_line(Vector2(mx, 148), Vector2(mx + 26, 148), mirror_line, 1.2)
				draw_line(Vector2(mx, 212), Vector2(mx + 26, 212), mirror_line, 1.2)
		&"level_c12":
			# 沉船温室：断裂桅杆斜插水中 + 藤壶点
			var mast := VisualTheme.shade(land_a, 0.85)
			draw_line(Vector2(96, 208), Vector2(112, 240), mast, 3.0)
			draw_line(Vector2(96, 208), Vector2(100, 200), VisualTheme.shade(land_a, 1.1), 2.0)
			draw_line(Vector2(540, 96), Vector2(556, 128), mast, 3.0)
			var barnacle := Color(edge.r, edge.g, edge.b, 0.6)
			draw_circle(Vector2(104, 224), 1.4, barnacle)
			draw_circle(Vector2(548, 112), 1.2, barnacle)


## 资产替换试验（NEXT_PHASE C）：在 C01 顶部岸带与右岸礁岛铺 Buch 岩石 tile。
## modulate 压暗偏夜紫，贴合 C01 黄昏港岸调色板；alpha 0.9 保留底色过渡。
func _draw_asset_trial() -> void:
	if _trial_tex == null:
		_trial_tex = load(TRIAL_SHEET) as Texture2D
	if _trial_tex == null:
		return
	var tint := Color(0.55, 0.50, 0.62, 0.9)
	var rects: Array[Rect2] = [ROCK_RECTS[0], ROCK_RECTS[3]] # 顶部岸带 + 右岸礁岛
	for rect: Rect2 in rects:
		var cols := int(rect.size.x) / CELL
		var rows := int(rect.size.y) / CELL
		for row: int in rows:
			for col: int in cols:
				var dst := Rect2(rect.position + Vector2(col * CELL, row * CELL), Vector2(CELL, CELL))
				var src: Rect2 = TRIAL_TILES[(col + row) % TRIAL_TILES.size()]
				draw_texture_rect_region(_trial_tex, dst, src, tint)
