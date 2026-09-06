class_name C01SpriteLibrary
extends RefCounted
## C01 raster presentation gateway. Primary subjects come from CC0 Foozle-derived PNGs;
## procedural drawing remains limited to lighting/status overlays.

const ROOT := "res://assets/art/c01/runtime/"
const ENEMY_SALT: Texture2D = preload(ROOT + "enemy_salt_shell.png")
const ENEMY_RAT: Texture2D = preload(ROOT + "enemy_mast_rat.png")
const TOWER_NEEDLE: Texture2D = preload(ROOT + "tower_needle_rail.png")
const PROPS: Texture2D = preload(ROOT + "harbor_props.png")
const BATTLE_BG: Texture2D = preload(ROOT + "battle_background.png")
const BRIEFING_MAP: Texture2D = preload(ROOT + "briefing_map.png")
const TITLE_BG: Texture2D = preload(ROOT + "title_background.png")
const CAMPAIGN_BG: Texture2D = preload(ROOT + "campaign_background.png")
const BRIEFING_BG: Texture2D = preload(ROOT + "briefing_background.png")
const RESULT_WIN_BG: Texture2D = preload(ROOT + "result_win_background.png")
const RESULT_LOSE_BG: Texture2D = preload(ROOT + "result_lose_background.png")

const ENEMY_FRAME := Vector2(64, 64)
const TOWER_FRAME := Vector2(96, 96)
const PROP_FRAME := Vector2(128, 128)

static func background_for_mode(mode: int) -> Texture2D:
	match mode:
		0, 1: return TITLE_BG
		2: return CAMPAIGN_BG
		3: return BRIEFING_BG
		4: return RESULT_WIN_BG
		5: return RESULT_LOSE_BG
	return TITLE_BG

static func draw_harbor_background(canvas: CanvasItem, mode: int, target_size: Vector2, tint := Color.WHITE) -> void:
	canvas.draw_texture_rect(background_for_mode(mode), Rect2(Vector2.ZERO, target_size), false, tint)

static func draw_battle_background(canvas: CanvasItem, phase_tint := Color(0, 0, 0, 0)) -> void:
	canvas.draw_texture_rect(BATTLE_BG, Rect2(Vector2.ZERO, Vector2(640, 360)), false)
	if phase_tint.a > 0.0:
		canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), phase_tint, true)

static func _enemy_row(facing: float) -> int:
	var direction := Vector2.RIGHT.rotated(facing)
	if absf(direction.x) >= absf(direction.y):
		return 0
	return 1 if direction.y >= 0.0 else 2

static func draw_enemy(canvas: CanvasItem, enemy_id: StringName, facing: float, walk_phase: float, modulate := Color.WHITE) -> bool:
	var tex: Texture2D
	var swarm := false
	match enemy_id:
		&"salt_shell_walker": tex = ENEMY_SALT
		&"mast_rat_swarm":
			tex = ENEMY_RAT
			swarm = true
		_: return false
	var row := _enemy_row(facing)
	var frame: int = int(floor(walk_phase * 3.25)) % 8
	var src := Rect2(Vector2(frame * 64, row * 64), ENEMY_FRAME)
	var direction := Vector2.RIGHT.rotated(facing)
	var flip_x := row == 0 and direction.x > 0.0 # source side frames face left
	if swarm:
		var offsets := [Vector2(4, -7), Vector2(-9, 5), Vector2(11, 8)]
		for i: int in 3:
			var scale := 0.48 if i > 0 else 0.56
			var dst_size := ENEMY_FRAME * scale
			canvas.draw_set_transform(offsets[i], 0.0, Vector2(-1.0 if flip_x else 1.0, 1.0))
			canvas.draw_texture_rect_region(tex, Rect2(-dst_size * 0.5, dst_size), src, modulate)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var dst_size := Vector2(52, 52)
		canvas.draw_set_transform(Vector2(0, -4), 0.0, Vector2(-1.0 if flip_x else 1.0, 1.0))
		canvas.draw_texture_rect_region(tex, Rect2(-dst_size * 0.5, dst_size), src, modulate)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

static func draw_tower(canvas: CanvasItem, attack_amount: float, modulate := Color.WHITE) -> void:
	var frame := 0
	if attack_amount > 0.0:
		frame = clampi(1 + int((1.0 - attack_amount) * 4.0), 1, 5)
	var src := Rect2(Vector2(frame * 96, 0), TOWER_FRAME)
	var dst_size := Vector2(68, 68)
	canvas.draw_texture_rect_region(TOWER_NEEDLE, Rect2(Vector2(-34, -47), dst_size), src, modulate)

static func draw_prop(canvas: CanvasItem, index: int, rect: Rect2, modulate := Color.WHITE) -> void:
	canvas.draw_texture_rect_region(PROPS, rect, Rect2(Vector2(clampi(index, 0, 7) * 128, 0), PROP_FRAME), modulate)

static func draw_briefing_map(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_texture_rect(BRIEFING_MAP, rect, false)

static func draw_briefing_subject(canvas: CanvasItem, kind: int, rect: Rect2) -> void:
	match kind:
		1:
			var src := Rect2(Vector2(3 * 64, 1 * 64), ENEMY_FRAME)
			canvas.draw_texture_rect_region(ENEMY_SALT, rect, src)
		2:
			var src := Rect2(Vector2(2 * 64, 0), ENEMY_FRAME)
			for off: Vector2 in [Vector2(0, 2), Vector2(22, 12), Vector2(42, 0)]:
				canvas.draw_texture_rect_region(ENEMY_RAT, Rect2(rect.position + off, rect.size * 0.58), src)
		3:
			canvas.draw_texture_rect_region(TOWER_NEEDLE, rect, Rect2(Vector2.ZERO, TOWER_FRAME))
