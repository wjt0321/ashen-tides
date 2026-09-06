class_name FXLayer
extends Node2D
## 战斗反馈特效层（Polish 阶段，PRD §12.4 可读性反馈）。
## 命中火花 / 击杀爆点 / 建造尘环 / 升级光环 / Boss 阶段爆发 / 漏怪·相位·胜负全屏闪。
## 纯 _draw 矢量图元（无第三方资产）；特效记录在定长数组池里（上限 MAX_FX），
## 不逐条建节点；由战斗场景在固定 tick 里调 sim_tick 驱动衰减——暂停即定格（全项目视觉规则）。
## accessibility/low_fx 开启时跳过粒子碎点，只保留环/闪光等基本反馈。

const MAX_FX: int = 80
const FLASH_DURATION: float = 0.45

const KIND_HIT := 0 ## 命中火花：四向短线
const KIND_KILL := 1 ## 击杀爆点：扩散环 + 碎点
const KIND_BUILD := 2 ## 建造尘环
const KIND_UPGRADE := 3 ## 升级上升光环
const KIND_BOSS := 4 ## Boss 阶段爆发：大红环 + 十字线

const DAMAGE_TYPE_COLORS: Dictionary = {
	&"physical": Color(1.0, 0.88, 0.45),
	&"glow": Color(0.55, 0.85, 1.0),
}

## {kind:int, pos:Vector2, t:float, dur:float, color:Color}
var _fx: Array[Dictionary] = []
var _flash_color := Color(0, 0, 0, 0)
var _flash_left: float = 0.0


func _ready() -> void:
	z_index = 60 # 压在地形/路线/塔/敌/投射物之上，HUD 之下（HUD 在 CanvasLayer）


func sim_tick(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(0.0, _flash_left - delta)
	for i: int in range(_fx.size() - 1, -1, -1):
		_fx[i]["t"] = float(_fx[i]["t"]) + delta
		if float(_fx[i]["t"]) >= float(_fx[i]["dur"]):
			_fx.remove_at(i)
	if not _fx.is_empty() or _flash_left > 0.0:
		queue_redraw()


func hit_spark(pos: Vector2, damage_type: StringName) -> void:
	_add(KIND_HIT, pos, 0.15, DAMAGE_TYPE_COLORS.get(damage_type, Color(1.0, 1.0, 1.0)))


func kill_burst(pos: Vector2, color: Color) -> void:
	_add(KIND_KILL, pos, 0.35, color)


func build_puff(pos: Vector2, accent: Color) -> void:
	_add(KIND_BUILD, pos, 0.40, accent)


func upgrade_halo(pos: Vector2, accent: Color) -> void:
	_add(KIND_UPGRADE, pos, 0.50, accent)


func boss_burst(pos: Vector2) -> void:
	_add(KIND_BOSS, pos, 0.60, Color(1.0, 0.35, 0.25))


## 全屏闪光（漏怪红闪 / 相位切换 / 胜负）。low_fx 时减半 alpha。
func flash_screen(color: Color) -> void:
	_flash_color = color
	if UiPalette.low_fx():
		_flash_color.a *= 0.5
	_flash_left = FLASH_DURATION
	queue_redraw()


func _add(kind: int, pos: Vector2, dur: float, color: Color) -> void:
	if _fx.size() >= MAX_FX:
		_fx.pop_front()
	_fx.append({"kind": kind, "pos": pos, "t": 0.0, "dur": dur, "color": color})
	queue_redraw()


func _draw() -> void:
	var low_fx := UiPalette.low_fx()
	for fx: Dictionary in _fx:
		var k: float = clampf(float(fx["t"]) / float(fx["dur"]), 0.0, 1.0) # 0 → 1
		var fade := 1.0 - k
		var pos: Vector2 = fx["pos"]
		var color: Color = fx["color"]
		match int(fx["kind"]):
			KIND_HIT:
				# M4-A：命中火花优先 4 帧条（8×8/帧），缺失回退程序化十字线
				var spark := ArtLibrary.vfx_tex("fx_hit_spark_strip4")
				if spark != null:
					var frame := clampi(int(k * 4.0), 0, 3)
					draw_texture_rect_region(spark, Rect2(pos - Vector2(4, 4), Vector2(8, 8)),
						Rect2(frame * 8, 0, 8, 8), Color(color.r, color.g, color.b, fade))
				else:
					var len := 3.0 + 5.0 * k
					var c := Color(color.r, color.g, color.b, 0.9 * fade)
					for d: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
						draw_line(pos + d * 2.0, pos + d * len, c, 1.0)
			KIND_KILL:
				# C01 v2：实际接入 Kenney Pirate CC0 explosion 候选；缩至 28px、深海调色，非 64px tile。
				var kenney_explosion := load("res://assets/vendor/c01/kenney/fx/explosion_01.png") as Texture2D
				if kenney_explosion != null:
					var sz := 14.0 + 14.0 * k
					draw_texture_rect(kenney_explosion, Rect2(pos - Vector2.ONE * sz * 0.5, Vector2.ONE * sz), false,
						Color(color.r * 0.8 + 0.2, color.g * 0.65 + 0.15, color.b * 0.45 + 0.1, 0.55 * fade))
				draw_arc(pos, 4.0 + 10.0 * k, 0.0, TAU, 20,
						Color(color.r, color.g, color.b, 0.8 * fade), 1.5)
				if not low_fx:
					for i: int in 4:
						var ang := TAU * float(i) / 4.0 + 0.6
						var d := Vector2(cos(ang), sin(ang))
						draw_circle(pos + d * (3.0 + 9.0 * k), 1.2,
								Color(color.r, color.g, color.b, 0.7 * fade))
			KIND_BUILD:
				draw_arc(pos, 2.0 + 11.0 * k, 0.0, TAU, 20,
						Color(color.r, color.g, color.b, 0.7 * fade), 1.5)
				if not low_fx:
					for i: int in 3:
						var off := Vector2(float(i - 1) * 4.0, -6.0 * k - 2.0)
						draw_circle(pos + off, 1.0, Color(color.r, color.g, color.b, 0.5 * fade))
			KIND_UPGRADE:
				var rise := Vector2(0, -8.0 * k)
				draw_arc(pos + rise, 6.0 + 10.0 * k, 0.0, TAU, 24,
						Color(color.r, color.g, color.b, 0.85 * fade), 2.0)
				draw_arc(pos + rise, 3.0 + 5.0 * k, 0.0, TAU, 16,
						Color(1.0, 1.0, 1.0, 0.5 * fade), 1.0)
			KIND_BOSS:
				draw_arc(pos, 8.0 + 22.0 * k, 0.0, TAU, 28,
						Color(color.r, color.g, color.b, 0.9 * fade), 2.5)
				var cl := 8.0 + 14.0 * k
				var cc := Color(color.r, color.g, color.b, 0.6 * fade)
				draw_line(pos - Vector2(cl, 0), pos + Vector2(cl, 0), cc, 1.5)
				draw_line(pos - Vector2(0, cl), pos + Vector2(0, cl), cc, 1.5)
	if _flash_left > 0.0:
		var fk: float = _flash_left / FLASH_DURATION
		var fc := Color(_flash_color.r, _flash_color.g, _flash_color.b, _flash_color.a * fk)
		# 略大于视口，抵消震屏偏移露边
		draw_rect(Rect2(Vector2(-8, -8), Vector2(656, 376)), fc, true)
