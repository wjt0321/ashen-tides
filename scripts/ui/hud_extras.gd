class_name HudExtras
extends CanvasLayer
## HUD 增强层（Polish 阶段，PRD §12.2 战斗信息层级）。
## 顶中相位条（当前相位 + 待切换预告）、波次/事件横幅（淡入淡出）、Boss 血条（阶段刻度）、
## 左下英雄技能坞（1/2/3 槽位 + 冷却扫弧 + 终极技充能条）。
## 全部 _draw 矢量 + 主题字体，无第三方资产；文案经 LocalizationService。

const PHASE_COLORS: Dictionary = {
	&"mingchao": Color(1.0, 0.85, 0.55),
	&"muchao": Color(0.55, 0.70, 1.0),
}
const PHASE_NAMES: Dictionary = {
	&"mingchao": "PHASE_MINGCHAO",
	&"muchao": "PHASE_MUCHAO",
}
const BANNER_TTL: float = 2.5

var _phase_widget: PhaseWidget
var _banner: Label
var _banner_ttl: float = 0.0
var _boss_bar: BossBar
var _skill_dock: SkillDock


func _ready() -> void:
	layer = 2 # HUD(1) 之上，教程(10)/面板(20+) 之下
	_phase_widget = PhaseWidget.new()
	_phase_widget.position = Vector2(232, 2)
	_phase_widget.size = Vector2(176, 20)
	add_child(_phase_widget)
	_boss_bar = BossBar.new()
	_boss_bar.position = Vector2(424, 2) # 顶右：避开左上 HUD 文案与顶中相位条
	_boss_bar.size = Vector2(212, 20)
	add_child(_boss_bar)
	_banner = Label.new()
	_banner.size = Vector2(640, 30)
	_banner.position = Vector2(0, 110)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 20)
	_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_banner.add_theme_constant_override("shadow_offset_x", 1)
	_banner.add_theme_constant_override("shadow_offset_y", 1)
	_banner.visible = false
	add_child(_banner)
	_skill_dock = SkillDock.new()
	_skill_dock.position = Vector2(8, 316)
	_skill_dock.size = Vector2(150, 40)
	add_child(_skill_dock)


func _process(delta: float) -> void:
	if _banner_ttl > 0.0:
		_banner_ttl -= delta
		_banner.modulate.a = clampf(_banner_ttl, 0.0, 1.0)
		if _banner_ttl <= 0.0:
			_banner.visible = false


## 相位条：当前相位 + 待切换预告（PhaseController）。
func update_phase(pc: PhaseController) -> void:
	_phase_widget.set_state(pc.current_phase, pc.pending_to_phase(), pc.pending_wave())


## 英雄技能坞：每帧刷新冷却/充能。
func update_hero(hero: GreyboxHero, becon: int) -> void:
	_skill_dock.set_hero(hero, becon)


## Boss 血条：传 null 隐藏。
func update_boss(boss: GreyboxEnemy) -> void:
	_boss_bar.set_boss(boss)


## 波次开始横幅（"第 N/M 波 · 组成"）。
func show_wave_banner(text: String) -> void:
	_show_banner(text, Color(1.0, 0.95, 0.85))


## 事件横幅（Boss 阶段 / 相位切换），醒目色。
func show_event_banner(text: String) -> void:
	_show_banner(text, Color(1.0, 0.65, 0.45))


func _show_banner(text: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner_ttl = BANNER_TTL
	_banner.modulate.a = 1.0
	_banner.visible = true


## 顶中相位条。
class PhaseWidget extends Control:
	var _phase: StringName = &"mingchao"
	var _pending_phase: StringName = &""
	var _pending_wave: int = -1
	var _last_key: String = ""

	func set_state(phase: StringName, pending_phase: StringName, pending_wave: int) -> void:
		var key := "%s|%s|%d" % [phase, pending_phase, pending_wave]
		if key == _last_key:
			return
		_last_key = key
		_phase = phase
		_pending_phase = pending_phase
		_pending_wave = pending_wave
		queue_redraw()

	func _draw() -> void:
		var font := get_theme_default_font()
		draw_line(Vector2(0, 10), Vector2(size.x, 10), Color(0.55, 0.70, 0.66, 0.28), 2.0)
		var phase_col: Color = HudExtras.PHASE_COLORS.get(_phase, Color.WHITE)
		var phase_name: String = LocalizationService.tr_key(HudExtras.PHASE_NAMES.get(_phase, &"PHASE_MINGCHAO"))
		draw_circle(Vector2(8, 10), 4.0, phase_col)
		draw_string(font, Vector2(18, 14), phase_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, phase_col)
		if _pending_phase != &"":
			var pend_col: Color = HudExtras.PHASE_COLORS.get(_pending_phase, Color.WHITE)
			var pend_name: String = LocalizationService.tr_key(HudExtras.PHASE_NAMES.get(_pending_phase, &"PHASE_MUCHAO"))
			var text := "→ 第%d波 %s" % [_pending_wave, pend_name]
			draw_string(font, Vector2(62, 14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, pend_col)
			# 潮汐仪可干预标记
			draw_circle(Vector2(58, 10), 2.0, Color(1.0, 0.9, 0.4))


## 顶中 Boss 血条（阶段刻度）。
class BossBar extends Control:
	var _boss: GreyboxEnemy = null

	func set_boss(boss: GreyboxEnemy) -> void:
		if boss == _boss:
			if _boss != null:
				queue_redraw()
			return
		_boss = boss
		visible = _boss != null
		queue_redraw()

	func _draw() -> void:
		if _boss == null or not is_instance_valid(_boss) or not _boss.is_alive():
			return
		var font := get_theme_default_font()
		var name_text: String = LocalizationService.tr_key(_boss.data.display_name_key)
		var bar := Rect2(0, 10, size.x, 8)
		draw_string(font, Vector2(0, 8), name_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 11,
				Color(1.0, 0.75, 0.65))
		draw_rect(bar, VisualTheme.HP_BAR_BG, true)
		var ratio: float = clampf(_boss.hp / maxf(_boss.data.max_hp, 1.0), 0.0, 1.0)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)),
				Color(0.85, 0.25, 0.20), true)
		if _boss.shield > 0.0 and _boss.data.shield_hp > 0.0:
			var sr: float = clampf(_boss.shield / _boss.data.shield_hp, 0.0, 1.0)
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * sr, 2.0)), VisualTheme.SHIELD_BAR, true)
		draw_rect(bar, Color(1, 1, 1, 0.35), false, 1.0)
		# 阶段刻度（boss_phases 阈值）
		for phase: Dictionary in _boss.data.boss_phases:
			var th := float(phase.get("threshold", 0.0))
			if th <= 0.0 or th >= 1.0:
				continue
			var x: float = bar.size.x * (1.0 - th) # threshold 为剩余血量比例
			var passed: bool = ratio <= th
			draw_line(Vector2(x, bar.position.y - 1), Vector2(x, bar.end.y + 1),
					Color(1.0, 0.9, 0.4) if passed else Color(1, 1, 1, 0.5), 1.0)


## 左下英雄技能坞：1/2/3 槽位 + 冷却扫弧；终极技槽底部充能条。
class SkillDock extends Control:
	const SLOT := 30.0
	const GAP := 6.0
	var _hero: GreyboxHero = null
	var _becon: int = 0

	func set_hero(hero: GreyboxHero, becon: int) -> void:
		_hero = hero
		_becon = becon
		visible = _hero != null
		if visible:
			queue_redraw()

	func _draw() -> void:
		if _hero == null or not is_instance_valid(_hero):
			return
		var font := get_theme_default_font()
		var skills: Array = [_hero.data.skill_a, _hero.data.skill_b, _hero.data.ultimate]
		var keys: Array[String] = ["1", "2", "3"]
		for i: int in 3:
			var skill: SkillData = skills[i]
			if skill == null:
				continue
			var rect := Rect2(i * (SLOT + GAP), 0, SLOT, SLOT)
			var remaining: float = _hero.cooldown_remaining(skill.id)
			var ready: bool = remaining <= 0.0 and not _hero.is_down
			var affordable: bool = skill.becon_cost <= 0 or _becon >= skill.becon_cost
			var bg := Color(0.06, 0.06, 0.10, 0.80)
			draw_rect(rect, bg, true)
			var border := Color(0.9, 0.85, 0.6, 0.9) if (ready and affordable) else Color(1, 1, 1, 0.25)
			draw_rect(rect, border, false, 1.0)
			# 冷却扫弧（顺时针暗色扇形覆盖）
			if remaining > 0.0 and skill.cooldown_seconds > 0.0:
				var frac: float = clampf(remaining / skill.cooldown_seconds, 0.0, 1.0)
				var center := rect.get_center()
				var pts := PackedVector2Array([center])
				var steps := 12
				for s: int in steps + 1:
					var ang := -PI / 2.0 + TAU * frac * float(s) / float(steps)
					pts.append(center + Vector2(cos(ang), sin(ang)) * SLOT)
				draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
				draw_string(font, rect.position + Vector2(9, 20), "%.0f" % remaining,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.85))
			else:
				var key_col := Color(1.0, 0.95, 0.8) if affordable else Color(0.6, 0.6, 0.65)
				draw_string(font, rect.position + Vector2(10, 20), keys[i],
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, key_col)
			# 终极技：底部航标充能条（与潮汐仪竞争，PRD §10.1）
			if skill.becon_cost > 0:
				var charge: float = clampf(float(_becon) / float(skill.becon_cost), 0.0, 1.0)
				var bar := Rect2(rect.position + Vector2(2, SLOT - 4), Vector2((SLOT - 4) * charge, 2.0))
				draw_rect(Rect2(rect.position + Vector2(2, SLOT - 4), Vector2(SLOT - 4, 2.0)),
						Color(1, 1, 1, 0.15), true)
				draw_rect(bar, Color(1.0, 0.85, 0.35) if affordable else Color(0.7, 0.55, 0.25), true)
		if _hero.is_down:
			draw_string(font, Vector2(0, -4), LocalizationService.tr_key(&"HUD_HERO_DOWN"),
					HORIZONTAL_ALIGNMENT_LEFT, 120, 10, Color(1.0, 0.5, 0.45))
