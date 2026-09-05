extends Node2D
## M3：C01–C08 第一章生产战斗场景（固定 BuildNode + PathNetwork，非自由堵路）。
## 数据驱动：关卡 / 波次 / 塔（含 II–IV 级与校准模块）/ 敌人（护盾/光环/标签）/ 英雄 / 技能 /
## 相位事件 / 环境装置全部来自 data/ 下的 .tres。
## 模拟：固定 tick（60Hz）+ 0.5×/1×/2×/3× 速度 + 可暂停（PRD §18.5、§3.1）。
## 路径模型：固定 BuildNode + 预制 PathNetwork，敌人沿路线插值移动，无实时寻路。
## 命令行：
##   -- --level=level_c02           选择关卡（默认 level_c01）
##   -- --m0-screenshot=<路径.png>  启动数帧后截图退出
##   -- --m1-smoke                  自动布防跑完全部波次的战斗冒烟（固定种子、固定 tick）
##   -- --speed=3                   冒烟初始速度档（0.5/1/2/3，默认 3）
##   -- --stop-after-wave=N         冒烟在第 N 波完成后写 suspend save 并退出（退出码 42）
##   -- --resume-suspend            从 suspend save 恢复后继续冒烟
##   -- --m1-soak=<真实秒数>        循环重开战斗的稳定性浸泡测试
##   -- --m2-perf / --m3-perf        性能采样：3× 速度跑完整关，输出帧时间统计 JSON
##   -- --m3-smoke                   M3 第一章 smoke 别名
##   -- --hero=<hero_id>              选择本关允许的英雄
##   -- --shot-at-wave=N             窗口模式第 N 波开始后截图到 out/polish_<level>_waveN.png

const TICK: float = 1.0 / 60.0
const SPEEDS: Array = [0.5, 1.0, 2.0, 3.0]
const LEVEL_DIR: String = "res://data/levels/"
const TOWER_DIR: String = "res://data/towers/"
const ENEMY_DIR: String = "res://data/enemies/"
const HERO_DIR: String = "res://data/heroes/"

const BECON_PER_KILL: int = 3 ## 击杀产航标充能（PRD §10.1：战斗行为产生）
const BUILD_CLICK_RADIUS: float = 18.0
const SMOKE_SEED: int = 20260905
const SMOKE_TIMEOUT_SIM_SECONDS: float = 400.0

const STATE_DISPLAY_NAMES: Dictionary = {
	WaveDirector.State.BUILD: &"STATE_BUILD",
	WaveDirector.State.PRE_DELAY: &"STATE_PRE_DELAY",
	WaveDirector.State.SPAWNING: &"STATE_SPAWNING",
	WaveDirector.State.CLEARING: &"STATE_CLEARING",
	WaveDirector.State.WIN: &"STATE_WIN",
	WaveDirector.State.LOSE: &"STATE_LOSE",
}

## 冒烟自动布防：[[BuildNode 索引, 塔 id], ...]，["upgrade", 节点索引, 模块序号] 表示升级并选模块
const SMOKE_PLANS: Dictionary = {
	&"level_c01": [
		[0, &"tower_needle_rail"], [3, &"tower_needle_rail"], [4, &"tower_needle_rail"],
		[5, &"tower_needle_rail"], [&"upgrade", 0, 0], [6, &"tower_needle_rail"],
		[1, &"tower_needle_rail"], [&"upgrade", 3, 2], [7, &"tower_needle_rail"],
		[&"upgrade", 4, 0],
	],
	&"level_c02": [
		[9, &"tower_needle_rail"], [5, &"tower_needle_rail"], [8, &"tower_needle_rail"],
		[&"upgrade", 9, 2], [4, &"tower_needle_rail"], [&"upgrade", 5, 2],
		[2, &"tower_needle_rail"], [3, &"tower_needle_rail"], [&"upgrade", 8, 0],
		[6, &"tower_needle_rail"], [&"upgrade", 4, 1], [&"upgrade", 2, 2],
		[0, &"tower_needle_rail"], [1, &"tower_ember_well"], [&"upgrade", 1, 2],
		[7, &"tower_needle_rail"], [&"upgrade", 6, 0], [&"upgrade", 3, 1],
	],
	&"level_c03": [
		[3, &"tower_needle_rail"], [7, &"tower_needle_rail"], [4, &"tower_ember_well"],
		[6, &"tower_ember_well"], [0, &"tower_echo_pile"], [2, &"tower_echo_pile"],
		[&"upgrade", 3, 1], [&"upgrade", 0, 0], [8, &"tower_needle_rail"],
		[10, &"tower_ember_well"], [&"upgrade", 4, 2], [5, &"tower_needle_rail"],
		[&"upgrade", 7, 0], [1, &"tower_ember_well"],
		[9, &"tower_needle_rail"], [11, &"tower_ember_well"], [&"upgrade", 8, 2],
		[&"upgrade", 10, 0], [&"upgrade", 6, 1], [&"upgrade", 5, 0],
		[&"upgrade", 9, 1], [&"upgrade", 1, 2],
	],
}

# ---- 数据 ----
var _level: LevelData
var _level_id: StringName = &"level_c01"
var _towers_available: Array[TowerData] = []
var _selected_tower_idx: int = 0
var _enemy_cache: Dictionary = {} # StringName -> EnemyData
var _hero_data: HeroData = null
var _hero_override: StringName = &""

# ---- 场景节点 ----
var _greybox: GreyboxMap
var _path_network: PathNetwork
var _node_manager: Node2D
var _build_nodes: Array[BuildNodeVisual] = []
var _node_by_id: Dictionary = {}
var _battle_root: Node2D
var _director: WaveDirector
var _phase_controller: PhaseController
var _becon: BeconLedger
var _hero: GreyboxHero = null

# ---- 战斗状态 ----
var _towers: Array[GreyboxTower] = []
var _enemies: Array[GreyboxEnemy] = []
var _active_projectiles: Array[GreyboxProjectile] = []
var _projectile_pool: ObjectPool
var _echo_system: EchoLinkSystem
var _devices: Array[GreyboxDevice] = []
var _rng := RandomNumberGenerator.new()
var _ember: int = 0
var _fleet_integrity: int = 0
var _paused: bool = false
var _battle_over: bool = false
var _invincible: bool = false
var _speed: float = 1.0
var _selected_tower_ref: GreyboxTower = null ## 左键点选的已建塔（面板/升级/出售）
var _module_choice_tower: GreyboxTower = null ## 非空 = 模块三选一模态（模拟暂停）
var _perf_mode: bool = false

# ---- 固定 tick ----
var _acc: float = 0.0
var _tick_count: int = 0
var _sim_seconds: float = 0.0

# ---- HUD ----
var _res_label: Label
var _state_label: Label
var _hero_label: Label
var _tower_label: Label
var _subtitle_label: Label
var _message_label: Label
var _hint_label: Label
var _notice: String = ""
var _notice_ttl: float = 0.0

# ---- UI 面板（M2，Phase C）----
var _pause_menu: PauseMenuPanel
var _settings_panel: SettingsPanel
var _result_panel: BattleResultPanel
var _tutorial_overlay: TutorialOverlay
var _menu_open: bool = false ## 暂停/设置/结算 任一面板打开

# ---- Polish：FX / HUD 增强 / 震屏 ----
var _fx: FXLayer
var _hud_extras: HudExtras
var _shake_left: float = 0.0 ## 漏怪震屏剩余秒（尊重 accessibility/screen_shake，仅视觉）
var _shake_intensity: float = 3.0

# ---- 统计 / 战报 / 结算 ----
var _kills: int = 0
var _leaks: int = 0
var _total_damage: float = 0.0
var _leak_by_enemy: Dictionary = {} ## enemy_id -> 漏怪数（战报，PRD §11.3）
var _damage_by_type: Dictionary = {} ## damage_type -> 塔/英雄伤害
var _first_breach_wave: int = 0 ## 第一次漏怪的波次（0 = 未破防）
var _strategy_done: bool = false ## 策略目标（印记 3）
var _last_result: Dictionary = {} ## 结算数据（Phase C 结算界面消费）
var _modules_selected: int = 0 ## 模块选择次数（smoke 报告）
var _boss_phase_seen: Array = [] ## M3 Boss 运行时证据
var _perf_frames: Array = [] ## --m2-perf 帧时间采样（毫秒）
var _dbg_fires: int = 0 ## ET_DEBUG_SYNC 探针：塔开火次数
var _dbg_wave_start_tick: int = 0 ## ET_DEBUG_SYNC 探针：当前波起始 tick

# ---- 命令行模式 ----
var _smoke: bool = false
var _soak_seconds: float = 0.0
var _soak_start_msec: int = 0
var _soak_battles: int = 0
var _screenshot_path: String = ""
var _shot_at_wave: int = 0 ## --shot-at-wave=N：第 N 波开始时窗口模式截图（polish 证据）
var _resume_suspend: bool = false
var _stop_after_wave: int = 0
var _smoke_plan: Array = []
var _smoke_plan_cursor: int = 0
var _smoke_hero_ab_used: bool = false
var _smoke_hero_moved: bool = false
var _smoke_ult_used: bool = false
var _smoke_tide_used: bool = false
var _smoke_restored: bool = false
var _smoke_repair_demo: bool = false ## C03 装置修复演示（一次性）
var _resume_start_pending: bool = false ## suspend 恢复后延迟 1 tick 开波（确定性对齐）
var _record_seconds: float = 0.0 ## --m2-record=<秒>：Movie Maker 录屏模式
var _m3_mode: bool = false


func _ready() -> void:
	print("[M2] ============================================================")
	print("[M2] 余烬潮汐 Ashen Tides — M2 release-quality vertical slice (C01-C03)")
	_parse_cmdline()
	_rng.randomize()
	UiPalette.configure_from_settings()
	SettingsPanel.capture_defaults()
	SettingsPanel.apply_saved_bindings()
	_build_static_scene()
	if not _load_level(_level_id):
		return
	_build_hud()
	_build_ui_panels()
	_reset_battle_state()
	if _resume_suspend:
		_try_resume_suspend()
	elif SaveService.has_suspend():
		_flash_notice(LocalizationService.tr_key(&"HUD_SUSPEND_FOUND"))
		print("[M2] suspend save detected (C=resume, X=discard)")
	EventBus.ultimate_failed_no_becon.connect(func() -> void: _flash_notice(LocalizationService.tr_key(&"HUD_BEACON_INSUF_ULT")))
	EventBus.tide_clock_failed.connect(func(_reason: StringName) -> void: _flash_notice(LocalizationService.tr_key(&"HUD_BEACON_INSUF_TIDE")))
	EventBus.tide_clock_shifted.connect(func(_dir: StringName) -> void: _strategy_check(&"use_tide_clock"))
	EventBus.device_repaired.connect(func(_id: StringName) -> void: _strategy_check(&"repair_device"))
	# 教程进度信号转发（PRD §12.2）：建造/开波/升级/相位事件
	EventBus.tower_placed.connect(func(_id: StringName, _node: StringName) -> void:
		_tutorial_overlay.notify(&"tower_placed"))
	EventBus.wave_started.connect(func(_i: int) -> void: _tutorial_overlay.notify(&"wave_started"))
	EventBus.tower_upgraded.connect(func(_id: StringName, _node: StringName, _t: int) -> void:
		_tutorial_overlay.notify(&"tower_upgraded"))
	EventBus.tide_clock_shifted.connect(func(_d: StringName) -> void:
		_tutorial_overlay.notify(&"tide_clock_shifted"))
	EventBus.device_offline.connect(func(_id: StringName) -> void:
		_tutorial_overlay.notify(&"device_offline"))
	# 语言切换 / 设置变更后刷新 HUD 文案
	# Polish：相位氛围（地形 tint + 切换闪光 + 事件横幅）
	EventBus.phase_changed.connect(_on_phase_visual)
	EventBus.settings_applied.connect(_refresh_localized_texts)
	_refresh_localized_texts()
	# 关卡教程启动
	if not String(_level.tutorial_id).is_empty():
		_tutorial_overlay.start_for(_level.tutorial_id)
	print("[M2] level=%s routes=%d build_nodes=%d waves=%d towers=%d hero=%s" % [
		_level_id, _level.route_ids.size(), _build_nodes.size(), _director.total_waves(),
		_towers_available.size(), _hero_data.id if _hero_data else "none"
	])
	if _smoke or _soak_seconds > 0.0:
		_start_autoplay()
	elif not _screenshot_path.is_empty():
		_capture_screenshot_and_quit()


# ---------------------------------------------------------------------------
# 场景构建
# ---------------------------------------------------------------------------


func _build_static_scene() -> void:
	var greybox := GreyboxMap.new()
	greybox.name = "GreyboxMap"
	add_child(greybox)
	_greybox = greybox
	_fx = FXLayer.new()
	_fx.name = "FXLayer"
	add_child(_fx)
	_becon = BeconLedger.new()
	_becon.name = "BeconLedger"
	add_child(_becon)
	_projectile_pool = ObjectPool.new(_create_projectile)
	_echo_system = EchoLinkSystem.new()
	_echo_system.name = "EchoLinkSystem"
	_echo_system.enemies = _enemies
	_echo_system.setup(_rng)
	add_child(_echo_system)
	EventBus.becon_kill_refund.connect(func(amount: int, _tower_id: StringName) -> void:
		_becon.add(amount, &"kill_refund"))


func _load_level(level_id: StringName) -> bool:
	if has_node("PathNetwork"):
		_teardown_level_nodes()
	_level_id = level_id
	_level = load(LEVEL_DIR + String(level_id) + ".tres") as LevelData
	if _level == null:
		push_error("[M1] failed to load level: %s" % level_id)
		return false
	_towers_available.clear()
	for tower_id: Variant in _level.allowed_towers:
		var tower := load(TOWER_DIR + String(tower_id) + ".tres") as TowerData
		if tower != null:
			_towers_available.append(tower)
	if _towers_available.is_empty():
		push_error("[M1] level has no loadable towers")
		return false
	_selected_tower_idx = 0
	_enemy_cache.clear()
	_hero_data = null
	if not _level.allowed_heroes.is_empty():
		var selected_hero_id: StringName = _hero_override if _level.allowed_heroes.has(_hero_override) else _level.allowed_heroes[0]
		_hero_data = load(HERO_DIR + String(selected_hero_id) + ".tres") as HeroData

	_path_network = PathNetwork.new()
	_path_network.name = "PathNetwork"
	_path_network.level_id = level_id # Polish：路线按关卡主题取色
	add_child(_path_network)
	var initial_active: Array = _level.initial_active_routes
	if initial_active.is_empty():
		initial_active = [_level.default_active_route]
	for i: int in _level.route_ids.size():
		_path_network.add_route(
			_level.route_ids[i], _level.route_points[i], initial_active.has(_level.route_ids[i])
		)

	_node_manager = Node2D.new()
	_node_manager.name = "BuildNodeManager"
	add_child(_node_manager)
	_build_nodes.clear()
	_node_by_id.clear()
	var level_accent: Color = VisualTheme.palette_for(level_id)["accent"] # Polish：节点主题强调色
	for i: int in _level.build_node_positions.size():
		var node := BuildNodeVisual.new()
		node.name = "BuildNode_%02d" % i
		node.level_accent = level_accent
		_node_manager.add_child(node)
		var node_id := StringName("buildnode_%s_%02d" % [String(level_id).trim_prefix("level_"), i])
		node.setup(node_id, _level.build_node_positions[i], BuildNodeVisual.State.FREE)
		_build_nodes.append(node)
		_node_by_id[node_id] = node

	_battle_root = Node2D.new()
	_battle_root.name = "BattleRuntime"
	add_child(_battle_root)

	_director = WaveDirector.new()
	_director.name = "WaveDirector"
	add_child(_director)
	_director.setup(_level.waves)
	_director.spawn_requested.connect(_on_spawn_requested)
	_director.wave_started.connect(_on_wave_started)
	_director.wave_completed.connect(_on_wave_completed)
	_director.all_waves_completed.connect(_on_all_waves_completed)

	_phase_controller = PhaseController.new()
	_phase_controller.name = "PhaseController"
	add_child(_phase_controller)
	_phase_controller.setup(_level.phase_events, _path_network, _becon)
	_phase_controller.environment_change_requested.connect(_on_environment_change)

	if _subtitle_label != null:
		_subtitle_label.text = LocalizationService.tr_key(&"HUD_LEVEL_SUBTITLE") % _level.id
	_greybox.setup(level_id) # Polish：地形主题（含装饰确定性重算）
	_apply_phase_visual()
	EventBus.level_loaded.emit(level_id)
	return true


func _teardown_level_nodes() -> void:
	for node_name: String in ["PathNetwork", "BuildNodeManager", "BattleRuntime", "WaveDirector", "PhaseController"]:
		var node := get_node_or_null(node_name)
		if node != null:
			remove_child(node)
			node.free()
	_hero = null


func _build_ui_panels() -> void:
	# 暂停 / 设置 / 战报 / 教程 四个独立 CanvasLayer（Phase C）
	_pause_menu = PauseMenuPanel.new()
	_pause_menu.name = "PauseMenu"
	add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.settings_requested.connect(_on_pause_settings)
	_pause_menu.restart_requested.connect(_on_pause_restart)
	_settings_panel = SettingsPanel.new()
	_settings_panel.name = "Settings"
	add_child(_settings_panel)
	_settings_panel.closed.connect(func() -> void:
		if not _result_panel.visible and not _battle_over:
			_pause_menu.open())
	_result_panel = BattleResultPanel.new()
	_result_panel.name = "BattleResult"
	add_child(_result_panel)
	_result_panel.restart_requested.connect(_on_pause_restart)
	_result_panel.closed.connect(func() -> void:
		_menu_open = _pause_menu.is_open() or _settings_panel.is_open())
	_tutorial_overlay = TutorialOverlay.new()
	_tutorial_overlay.name = "TutorialOverlay"
	add_child(_tutorial_overlay)


## Phase C：语言切换或设置变更后，刷新硬编码/字符串常量的文案。
## 注意：smoke 模式（_smoke=true）跳过提示，避免污染日志。
func _refresh_localized_texts() -> void:
	if _subtitle_label != null:
		_subtitle_label.text = LocalizationService.tr_key(&"HUD_LEVEL_SUBTITLE") % _level.id
	if _hint_label != null:
		_hint_label.text = LocalizationService.tr_key(&"HUD_HINT")
	if _tutorial_overlay.is_active():
		_tutorial_overlay.notify(&"refresh")


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = LocalizationService.tr_key(&"GAME_TITLE")
	title.position = Vector2(8, 4)
	title.add_theme_font_size_override("font_size", 16)
	hud.add_child(title)

	_subtitle_label = Label.new()
	_subtitle_label.name = "SubtitleLabel"
	_subtitle_label.position = Vector2(8, 24)
	_subtitle_label.add_theme_font_size_override("font_size", 12)
	_subtitle_label.text = LocalizationService.tr_key(&"HUD_LEVEL_SUBTITLE") % _level.id
	hud.add_child(_subtitle_label)

	_res_label = Label.new()
	_res_label.name = "ResourceLabel"
	_res_label.position = Vector2(8, 42)
	_res_label.add_theme_font_size_override("font_size", 12)
	hud.add_child(_res_label)

	_state_label = Label.new()
	_state_label.name = "StateLabel"
	_state_label.position = Vector2(8, 58)
	_state_label.add_theme_font_size_override("font_size", 12)
	hud.add_child(_state_label)

	_hero_label = Label.new()
	_hero_label.name = "HeroLabel"
	_hero_label.position = Vector2(8, 74)
	_hero_label.add_theme_font_size_override("font_size", 12)
	hud.add_child(_hero_label)

	_tower_label = Label.new()
	_tower_label.name = "TowerLabel"
	_tower_label.position = Vector2(8, 90)
	_tower_label.add_theme_font_size_override("font_size", 12)
	hud.add_child(_tower_label)

	_message_label = Label.new()
	_message_label.name = "MessageLabel"
	_message_label.size = Vector2(640, 40)
	_message_label.position = Vector2(0, 150)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 24)
	_message_label.visible = false
	hud.add_child(_message_label)

	var hint := Label.new()
	hint.name = "HintLabel"
	hint.text = LocalizationService.tr_key(&"HUD_HINT")
	hint.position = Vector2(4, 340)
	hint.add_theme_font_size_override("font_size", 11)
	hud.add_child(hint)
	_hint_label = hint

	# Polish：相位条 / 波次横幅 / Boss 血条 / 英雄技能坞（独立 CanvasLayer，layer=2）
	_hud_extras = HudExtras.new()
	_hud_extras.name = "HudExtras"
	add_child(_hud_extras)


# ---------------------------------------------------------------------------
# 战斗状态
# ---------------------------------------------------------------------------


func _reset_battle_state() -> void:
	for child: Node in _battle_root.get_children():
		child.queue_free()
	_towers.clear()
	_enemies.clear()
	_active_projectiles.clear()
	_devices.clear()
	_projectile_pool = ObjectPool.new(_create_projectile)
	_echo_system.reset()
	_director.reset()
	_becon.set_value_silent(0)
	_ember = _level.initial_ember
	_fleet_integrity = _level.initial_fleet_integrity
	_paused = false
	_battle_over = false
	_invincible = false
	_acc = 0.0
	_tick_count = 0
	_sim_seconds = 0.0
	_kills = 0
	_leaks = 0
	_total_damage = 0.0
	_leak_by_enemy.clear()
	_damage_by_type.clear()
	_first_breach_wave = 0
	_strategy_done = false
	_modules_selected = 0
	_boss_phase_seen.clear()
	_perf_frames.clear()
	_dbg_fires = 0
	_set_selected_tower(null)
	_module_choice_tower = null
	_phase_controller.setup(_level.phase_events, _path_network, _becon)
	_path_network.visible = true
	_apply_phase_visual() # Polish：重开后相位 tint 复位
	position = Vector2.ZERO
	_shake_left = 0.0
	_message_label.visible = false
	_notice = ""
	if _hero_data != null:
		_hero = GreyboxHero.new()
		_hero.name = "Hero"
		_hero.position = _level.hero_spawn
		_hero.enemies = _enemies
		_battle_root.add_child(_hero)
		_hero.setup(_hero_data, _becon)
	else:
		_hero = null
	# 环境装置（相位模板 2，PRD §5.3）
	for device_data: Variant in _level.devices:
		var device := GreyboxDevice.new()
		device.name = "Device_%s" % device_data.id
		device.setup(device_data)
		device.enemies = _enemies
		device.hero = _hero
		device.current_phase = _phase_controller.current_phase
		_battle_root.add_child(device)
		_devices.append(device)
	if _hero != null:
		_hero.devices = _devices
	_smoke_plan_cursor = 0
	_smoke_hero_ab_used = false
	_smoke_hero_moved = false
	_smoke_ult_used = false
	_smoke_tide_used = false
	_smoke_repair_demo = false
	_refresh_build_node_states()
	EventBus.ember_changed.emit(_ember)
	EventBus.fleet_integrity_changed.emit(_fleet_integrity)
	EventBus.becon_changed.emit(0, &"reset")


## 固定 tick 主循环（PRD §18.5）：表现帧累积 -> 60Hz 固定步进，速度档乘算。
func _process(delta: float) -> void:
	if _notice_ttl > 0.0:
		_notice_ttl -= delta
		if _notice_ttl <= 0.0:
			_notice = ""
	if _shake_left > 0.0:
		_shake_left = maxf(0.0, _shake_left - delta)
		if _shake_left > 0.0:
			var mag := _shake_intensity * (_shake_left / 0.25)
			position = Vector2(randf_range(-mag, mag), randf_range(-mag, mag)) # 仅视觉，不动战斗 RNG
		else:
			position = Vector2.ZERO
	if _battle_over:
		_fx.sim_tick(delta) # 胜负已定后 sim 停摆，闪光用真实帧衰减
	if not _paused and not _battle_over and _module_choice_tower == null:
		_acc += delta * _speed
		var steps := 0
		while _acc >= TICK and steps < 12:
			_sim_tick(TICK)
			_acc -= TICK
			steps += 1
			_tick_count += 1
	if _perf_mode and not _battle_over:
		_perf_frames.append(delta * 1000.0)
	_update_hud()
	if _soak_seconds > 0.0 and float(Time.get_ticks_msec() - _soak_start_msec) / 1000.0 >= _soak_seconds:
		_finish_soak()
	if _record_seconds > 0.0 and float(Time.get_ticks_msec() - _soak_start_msec) / 1000.0 >= _record_seconds:
		print("[M2-RECORD] done: %.0f real seconds recorded" % _record_seconds)
		get_tree().quit(0)


func _sim_tick(dt: float) -> void:
	_sim_seconds += dt
	_phase_controller.tick_now = _tick_count
	_director.tick(dt)
	_phase_controller.sim_tick(dt)
	if _hero != null:
		_hero.sim_tick(dt)
	_apply_support_auras()
	for enemy: GreyboxEnemy in _enemies.duplicate():
		enemy.sim_tick(dt)
	for tower: GreyboxTower in _towers:
		tower.sim_tick(dt)
	_echo_system.sim_tick(dt)
	for device: GreyboxDevice in _devices:
		device.current_phase = _phase_controller.current_phase
		device.sim_tick(dt)
	for projectile: GreyboxProjectile in _active_projectiles.duplicate():
		projectile.sim_tick(dt)
	_fx.sim_tick(dt) # Polish：特效随固定 tick 衰减（暂停定格）
	if _smoke or _soak_seconds > 0.0:
		_autoplay_tick()
	if _resume_start_pending:
		_resume_start_pending = false
		_try_start_wave()
	if OS.has_environment("ET_DEBUG_SYNC") and (_tick_count - _dbg_wave_start_tick) % 100 == 0 and _director.state == WaveDirector.State.SPAWNING:
		print("[BSYNC] dt=%d kills=%d alive=%d fires=%d pulses=%d rng=%d" % [_tick_count - _dbg_wave_start_tick, _kills, _enemies.size(), _dbg_fires, _echo_system.pulses_total, _rng.state])


## 支援光环（潮背导航员）：每 tick 重置后由存活且未沉默的光环源注入（沉默抑制，断响模块反制）。
func _apply_support_auras() -> void:
	for enemy: GreyboxEnemy in _enemies:
		enemy.aura_boost = 1.0
	for source: GreyboxEnemy in _enemies:
		if not source.is_alive() or source.data.aura_radius <= 0.0 or source.is_silenced():
			continue
		for ally: GreyboxEnemy in _enemies:
			if ally == source or not ally.is_alive():
				continue
			if ally.position.distance_to(source.position) <= source.data.aura_radius:
				ally.aura_boost = maxf(ally.aura_boost, source.data.aura_speed_mult)


# ---------------------------------------------------------------------------
# 输入
# ---------------------------------------------------------------------------


func _unhandled_input(event: InputEvent) -> void:
	# 任一面板打开：仅消费面板内输入 + Esc/Pause（关闭面板）
	if _menu_open and not (event is InputEventMouseMotion):
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("battle_pause"):
			if _settings_panel.is_open():
				_settings_panel.close()
				get_viewport().set_input_as_handled()
				return
			if _pause_menu.is_open():
				_on_pause_resume()
				get_viewport().set_input_as_handled()
				return
			if _result_panel.visible:
				_result_panel.hide_panel()
				get_viewport().set_input_as_handled()
				return
		return
	# 模块三选一模态（II 级升级，PRD §6.1）：模拟暂停，7/8/9 选择，Esc 取消
	if _module_choice_tower != null:
		if event.is_action_pressed("battle_module_1"):
			_commit_module_choice(0)
		elif event.is_action_pressed("battle_module_2"):
			_commit_module_choice(1)
		elif event.is_action_pressed("battle_module_3"):
			_commit_module_choice(2)
		elif event.is_action_pressed("ui_cancel"):
			_cancel_module_choice()
		return
	if event.is_action_pressed("debug_reset"):
		_restart_battle()
	elif event.is_action_pressed("battle_pause"):
		_toggle_pause()
	elif event.is_action_pressed("battle_start_wave"):
		_try_start_wave()
	elif event.is_action_pressed("speed_up"):
		_change_speed(1)
	elif event.is_action_pressed("speed_down"):
		_change_speed(-1)
	elif event.is_action_pressed("battle_cycle_tower"):
		_cycle_tower()
	elif event.is_action_pressed("battle_upgrade_tower"):
		_try_upgrade_selected()
	elif event.is_action_pressed("battle_sell_tower"):
		_try_sell_selected()
	elif event.is_action_pressed("hero_skill_a"):
		if _hero != null and not _battle_over:
			if not _hero.use_skill_a(get_global_mouse_position()):
				_flash_notice(LocalizationService.tr_key(&"HUD_HERO_SKILL_A_FAIL"))
	elif event.is_action_pressed("hero_skill_b"):
		if _hero != null and not _battle_over:
			if not _hero.use_skill_b():
				_flash_notice(LocalizationService.tr_key(&"HUD_HERO_SKILL_B_FAIL"))
	elif event.is_action_pressed("hero_ultimate"):
		if _hero != null and not _battle_over:
			_hero.use_ultimate() # 失败原因经 EventBus -> notice
	elif event.is_action_pressed("tide_clock_earlier"):
		_try_tide_clock(true)
	elif event.is_action_pressed("tide_clock_later"):
		_try_tide_clock(false)
	elif event.is_action_pressed("debug_skip_wave"):
		_debug_skip_wave()
	elif event.is_action_pressed("debug_invincible"):
		_invincible = not _invincible
		_flash_notice(LocalizationService.tr_key(&"HUD_INVINCIBLE_ON") if _invincible else LocalizationService.tr_key(&"HUD_INVINCIBLE_OFF"))
		print("[M2] debug invincible=%s" % _invincible)
	elif event.is_action_pressed("debug_inject_ember"):
		_ember += 500
		EventBus.ember_changed.emit(_ember)
		_refresh_build_node_states()
		_flash_notice(LocalizationService.tr_key(&"HUD_INJECT_EMBER"))
		print("[M2] debug inject ember -> %d" % _ember)
	elif event.is_action_pressed("debug_toggle_paths"):
		_path_network.visible = not _path_network.visible
	elif event.is_action_pressed("battle_resume_suspend"):
		_try_resume_suspend()
	elif event.is_action_pressed("battle_discard_suspend"):
		SaveService.clear_suspend()
		_flash_notice(LocalizationService.tr_key(&"HUD_SUSPEND_CLEARED"))
	elif event is InputEventMouseButton and event.pressed:
		if _battle_over:
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT and _hero != null:
			_hero.selected = true
			_hero.queue_redraw()
			if not _hero.command_move(get_global_mouse_position()):
				_flash_notice(LocalizationService.tr_key(&"HUD_HERO_CANT_REACH")) # PRD §7.3 路径失败反馈


func _restart_battle() -> void:
	_reset_battle_state()
	EventBus.test_state_reset.emit()
	if _result_panel != null:
		_result_panel.hide_panel()
	if _pause_menu != null:
		_pause_menu.close()
	_menu_open = false
	print("[M2] battle restarted")


func _toggle_pause() -> void:
	if _battle_over:
		return
	if _pause_menu.is_open():
		_on_pause_resume()
		return
	_pause_menu.open()
	_paused = true
	_menu_open = true
	_flash_notice(LocalizationService.tr_key(&"HUD_PAUSE"))
	print("[M2] pause menu opened (sim paused=%s)" % _paused)


func _on_pause_resume() -> void:
	_pause_menu.close()
	_settings_panel.close()
	_paused = false
	_menu_open = false
	print("[M2] resume from pause menu")


func _on_pause_settings() -> void:
	_pause_menu.close()
	_settings_panel.open()
	_menu_open = true
	print("[M2] settings opened from pause menu")


func _on_pause_restart() -> void:
	if _result_panel != null:
		_result_panel.hide_panel()
	_settings_panel.close()
	_pause_menu.close()
	_menu_open = false
	_restart_battle()


func _change_speed(direction: int) -> void:
	var index: int = SPEEDS.find(_speed)
	index = clampi(index + direction, 0, SPEEDS.size() - 1)
	_speed = SPEEDS[index]
	EventBus.game_speed_changed.emit(_speed)
	print("[M2] game speed -> %.1fx" % _speed)


func _cycle_tower() -> void:
	_selected_tower_idx = (_selected_tower_idx + 1) % _towers_available.size()
	var tower := _selected_tower()
	_flash_notice(LocalizationService.tr_key(&"HUD_CYCLE_TOWER") % [
		LocalizationService.tr_key(tower.display_name_key), tower.base_cost
	])
	_refresh_build_node_states()


func _selected_tower() -> TowerData:
	return _towers_available[_selected_tower_idx]


func _try_tide_clock(earlier: bool) -> void:
	if _battle_over:
		return
	if not _phase_controller.has_pending():
		_flash_notice(LocalizationService.tr_key(&"HUD_TIDE_NO_PENDING"))
		return
	if not _phase_controller.request_shift(earlier):
		if _becon.current < 40:
			_flash_notice(LocalizationService.tr_key(&"HUD_BEACON_INSUF_TIDE"))


# ---------------------------------------------------------------------------
# 建塔 / 升级 / 模块 / 出售
# ---------------------------------------------------------------------------


## 左键：点选已建塔（面板 + E 升级 / G 出售）；点选英雄；空格点建塔。
func _on_left_click(click_pos: Vector2) -> void:
	if _hero != null and _hero.position.distance_to(click_pos) <= 16.0:
		_hero.selected = true
		_hero.queue_redraw()
		_set_selected_tower(null)
		return
	if _hero != null and _hero.selected:
		_hero.selected = false
		_hero.queue_redraw()
	for node: BuildNodeVisual in _build_nodes:
		if node.position.distance_to(click_pos) > BUILD_CLICK_RADIUS:
			continue
		if node.state == BuildNodeVisual.State.OCCUPIED:
			_set_selected_tower(_tower_at_node(node.node_id))
			return
		_set_selected_tower(null)
		_try_place_tower(click_pos)
		return
	_set_selected_tower(null)


func _tower_at_node(node_id: StringName) -> GreyboxTower:
	for tower: GreyboxTower in _towers:
		if tower.node_id == node_id:
			return tower
	return null


## E 升级（PRD §6.1）：I→II 进入模块三选一模态（选定时才扣费并锁定）；
## II→III / III→IV 直接扣费升级。
func _try_upgrade_selected() -> void:
	if _battle_over or _selected_tower_ref == null:
		return
	var tower := _selected_tower_ref
	if not tower.can_upgrade():
		_flash_notice(LocalizationService.tr_key(&"HUD_TOWER_UPGRADE_FULL"))
		return
	var cost := tower.upgrade_cost()
	if _ember < cost:
		_flash_notice(LocalizationService.tr_key(&"HUD_TOWER_UPGRADE_COST") % cost)
		return
	if tower.tier == 1 and not tower.pending_module_choices().is_empty():
		_module_choice_tower = tower # 模态：选定模块后才扣费升级（PRD §6.1 本局锁定）
		return
	_ember -= cost
	EventBus.ember_changed.emit(_ember)
	tower.upgrade()
	_finish_upgrade(tower)


## 模块三选一提交：扣 II 级成本、升级、挂载模块。
func _commit_module_choice(choice_index: int) -> void:
	var tower := _module_choice_tower
	if tower == null:
		return
	var choices := tower.pending_module_choices()
	if choice_index < 0 or choice_index >= choices.size():
		return
	var module := choices[choice_index] as ModuleData
	var cost := tower.upgrade_cost()
	if _ember < cost:
		_flash_notice(LocalizationService.tr_key(&"HUD_MODULE_UPGRADE_FAIL") % cost)
		_module_choice_tower = null
		return
	_module_choice_tower = null
	_ember -= cost
	EventBus.ember_changed.emit(_ember)
	tower.upgrade()
	if not tower.apply_module(module):
		push_error("[M2] module apply failed: %s -> %s" % [tower.data.id, module.id])
	_modules_selected += 1
	EventBus.module_selected.emit(tower.data.id, module.id)
	print("[M2] module selected: %s on %s@%s" % [module.id, tower.data.id, tower.node_id])
	_finish_upgrade(tower)


func _cancel_module_choice() -> void:
	_module_choice_tower = null
	_flash_notice(LocalizationService.tr_key(&"HUD_MODULE_CANCEL"))


func _finish_upgrade(tower: GreyboxTower) -> void:
	_strategy_check(&"upgrade_any_tower")
	_fx.upgrade_halo(tower.position, VisualTheme.palette_for(_level_id)["accent"]) # Polish：升级光环
	EventBus.tower_upgraded.emit(tower.data.id, tower.node_id, tower.tier)
	_refresh_build_node_states()
	print("[M2] tower upgraded: %s@%s -> tier %d" % [tower.data.id, tower.node_id, tower.tier])


## G 出售：退款累计投入 70%（PRD §3.7）。
func _try_sell_selected() -> void:
	if _battle_over or _selected_tower_ref == null:
		return
	var tower := _selected_tower_ref
	_set_selected_tower(null)
	var refund := int(tower.invested_ember * 0.7)
	_ember += refund
	EventBus.ember_changed.emit(_ember)
	var node: BuildNodeVisual = _node_by_id.get(tower.node_id)
	if node != null:
		node.set_state(BuildNodeVisual.State.FREE)
	if tower.data.pair_link:
		_echo_system.remove_pile(tower)
	_towers.erase(tower)
	tower.queue_free()
	EventBus.tower_sold.emit(tower.data.id, tower.node_id, refund)
	_refresh_build_node_states()
	print("[M2] tower sold: %s@%s refund=%d" % [tower.data.id, tower.node_id, refund])


## 策略目标判定（结算印记 3，PRD §9.2）：按 LevelData.strategy_objective_op。
func _strategy_check(op: StringName) -> void:
	if _strategy_done or _level.strategy_objective_op != op:
		return
	_strategy_done = true
	_flash_notice(LocalizationService.tr_key(&"HUD_STRATEGY_DONE"))
	print("[M2] strategy objective done: %s" % op)


func _try_place_tower(click_pos: Vector2) -> void:
	for node: BuildNodeVisual in _build_nodes:
		if node.position.distance_to(click_pos) > BUILD_CLICK_RADIUS:
			continue
		var tower := _selected_tower()
		if node.state == BuildNodeVisual.State.OCCUPIED:
			_flash_notice(LocalizationService.tr_key(&"HUD_PLACE_OCCUPIED"))
			return
		if _ember < tower.base_cost:
			_flash_notice(LocalizationService.tr_key(&"HUD_PLACE_NO_FUNDS") % [
				LocalizationService.tr_key(tower.display_name_key), tower.base_cost
			])
			return
		_place_tower_at(node, tower)
		return


func _place_tower_at(node: BuildNodeVisual, tower_data: TowerData, free_of_charge: bool = false) -> bool:
	if node.state == BuildNodeVisual.State.OCCUPIED:
		return false
	if not free_of_charge:
		if _ember < tower_data.base_cost:
			return false
		_ember -= tower_data.base_cost
		EventBus.ember_changed.emit(_ember)
	var tower := GreyboxTower.new()
	tower.setup(tower_data, node.node_id)
	tower.position = node.position
	tower.enemies = _enemies
	tower.invested_ember = 0 if free_of_charge else tower_data.base_cost
	tower.fire_requested.connect(_on_tower_fire)
	_battle_root.add_child(tower)
	_towers.append(tower)
	if tower_data.pair_link:
		_echo_system.add_pile(tower)
	node.set_state(BuildNodeVisual.State.OCCUPIED)
	_refresh_build_node_states()
	_fx.build_puff(node.position, VisualTheme.palette_for(_level_id)["accent"]) # Polish：建造尘环
	EventBus.tower_placed.emit(tower_data.id, node.node_id)
	print("[M2] tower placed: %s at %s (ember left=%d)" % [tower_data.id, node.node_id, _ember])
	return true


func _refresh_build_node_states() -> void:
	var cost := _selected_tower().base_cost
	for node: BuildNodeVisual in _build_nodes:
		if node.state == BuildNodeVisual.State.OCCUPIED:
			continue
		if _ember >= cost:
			node.set_state(BuildNodeVisual.State.FREE)
		else:
			node.set_state(BuildNodeVisual.State.BLOCKED)


# ---------------------------------------------------------------------------
# 波次 / 生成 / 战斗结算
# ---------------------------------------------------------------------------


func _try_start_wave() -> void:
	if _battle_over:
		return
	if _director.start_wave():
		print("[M2] wave %d started (tick=%d)" % [_director.waves_started(), _tick_count])
	else:
		_flash_notice(LocalizationService.tr_key(&"HUD_NOT_START"))


func _on_wave_started(wave_index: int) -> void:
	_phase_controller.on_wave_started(wave_index + 1, _tick_count)
	EventBus.wave_started.emit(wave_index)
	# Polish：波次横幅（含组成预告）+ 窗口模式定波截图
	if _hud_extras != null and _banners_enabled():
		_hud_extras.show_wave_banner(_wave_banner_text(wave_index))
	if _shot_at_wave > 0 and wave_index + 1 == _shot_at_wave and DisplayServer.get_name() != "headless":
		_capture_wave_shot(wave_index + 1)
	if OS.has_environment("ET_DEBUG_SYNC"):
		print("[WSYNC] wave=%d t=%d rng=%d ember=%d fires=%d pulses=%d links=%s" % [wave_index + 1, _tick_count, _rng.state, _ember, _dbg_fires, _echo_system.pulses_total, JSON.stringify(_echo_system.get_link_timers())])
		_dbg_wave_start_tick = _tick_count


## 波次横幅文案（Polish）："第 N/M 波 · 敌×数 敌×数"。
func _wave_banner_text(wave_index: int) -> String:
	var comp: Array[String] = []
	var wave := _director.wave_at(wave_index)
	if wave != null:
		for group: WaveGroup in wave.groups:
			var data := _get_enemy_data(group.enemy_id)
			var enemy_name := LocalizationService.tr_key(data.display_name_key) if data != null else String(group.enemy_id)
			comp.append("%s×%d" % [enemy_name, group.count])
	return LocalizationService.tr_key(&"HUD_WAVE_BANNER") % [
		wave_index + 1, _director.total_waves(), "  ".join(comp)
	]


## --shot-at-wave=N（Polish 证据）：窗口模式第 N 波开始后数帧截图到 out/polish_*。
func _capture_wave_shot(wave_number: int) -> void:
	for i: int in 90: # 等 1.5 秒（真实帧），让敌群进入画面
		await get_tree().process_frame
	var out_dir := ProjectSettings.globalize_path("res://out")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var shot_path := out_dir.path_join("polish_%s_wave%d.png" % [_level_id, wave_number])
	var err := get_viewport().get_texture().get_image().save_png(shot_path)
	print("[POLISH] wave screenshot saved: %s (err=%d)" % [shot_path, err])


func _on_spawn_requested(enemy_id: StringName, route_id: StringName) -> void:
	var data := _get_enemy_data(enemy_id)
	if data == null:
		push_error("[M2] unknown enemy id: %s" % enemy_id)
		return
	var actual_route := route_id
	if actual_route == &"" or not _path_network.is_route_active(actual_route):
		actual_route = _level.default_active_route
	var enemy := GreyboxEnemy.new()
	enemy.setup(data, _path_network.routes[actual_route], _rng)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_goal.connect(_on_enemy_reached_goal)
	enemy.boss_phase_changed.connect(_on_boss_phase_changed)
	_battle_root.add_child(enemy)
	_enemies.append(enemy)


func _on_boss_phase_changed(enemy: GreyboxEnemy, phase_index: int, label: String) -> void:
	_boss_phase_seen.append({"enemy": String(enemy.data.id), "phase": phase_index, "label": label, "tick": _tick_count})
	print("[M3-BOSS] runtime phase level=%s enemy=%s phase=%d label=%s" % [_level_id, enemy.data.id, phase_index, label])
	_fx.boss_burst(enemy.position) # Polish：Boss 阶段爆发 + 横幅
	if _hud_extras != null and _banners_enabled():
		_hud_extras.show_event_banner("%s · %s" % [LocalizationService.tr_key(enemy.data.display_name_key), label])
	_flash_notice("Boss %s：%s" % [enemy.data.id, label])


func _get_enemy_data(enemy_id: StringName) -> EnemyData:
	if not _enemy_cache.has(enemy_id):
		_enemy_cache[enemy_id] = load(ENEMY_DIR + String(enemy_id) + ".tres") as EnemyData
	return _enemy_cache[enemy_id]


func _on_enemy_died(enemy: GreyboxEnemy) -> void:
	_kills += 1
	_ember += enemy.data.kill_reward_ember
	_becon.add(BECON_PER_KILL, &"kill")
	_fx.kill_burst(enemy.position, enemy.data.body_color) # Polish：击杀爆点
	EventBus.enemy_killed.emit(enemy.data.id, enemy.data.kill_reward_ember)
	EventBus.ember_changed.emit(_ember)
	_refresh_build_node_states()
	_remove_enemy(enemy)


func _on_enemy_reached_goal(enemy: GreyboxEnemy) -> void:
	_leaks += 1
	_leak_by_enemy[enemy.data.id] = int(_leak_by_enemy.get(enemy.data.id, 0)) + 1
	if _first_breach_wave == 0:
		_first_breach_wave = _director.waves_started()
	if _invincible:
		print("[M2] debug invincible: leak ignored (%s)" % enemy.data.id)
	else:
		_fleet_integrity -= enemy.data.leak_damage
		_fx.flash_screen(VisualTheme.FLASH_LEAK) # Polish：漏怪红闪 + 震屏
		_shake()
		EventBus.fleet_leaked.emit(enemy.data.id, enemy.data.leak_damage)
		EventBus.fleet_integrity_changed.emit(_fleet_integrity)
	_remove_enemy(enemy)
	if _fleet_integrity <= 0 and not _battle_over:
		_enter_lose()


func _remove_enemy(enemy: GreyboxEnemy) -> void:
	_enemies.erase(enemy)
	_director.notify_enemy_removed()
	enemy.queue_free()


func _on_tower_fire(tower: GreyboxTower, target: GreyboxEnemy) -> void:
	var damage: float = _rng.randf_range(tower.eff_damage_min(), tower.eff_damage_max())
	_dbg_fires += 1
	var projectile := _projectile_pool.acquire() as GreyboxProjectile
	if projectile.get_parent() == null:
		_battle_root.add_child(projectile)
		projectile.enemies = _enemies
		projectile.resolved.connect(_on_projectile_resolved)
	_active_projectiles.append(projectile)
	projectile.setup(tower.position, target, damage, tower.data.damage_type, tower.data.projectile_speed,
		tower.eff_splash_radius(), tower.eff_pierce(), tower.eff_armor_shred(), tower, tower.eff_range())


func _create_projectile() -> GreyboxProjectile:
	return GreyboxProjectile.new()


func _on_projectile_resolved(projectile: GreyboxProjectile) -> void:
	_total_damage += projectile.resolved_damage()
	_damage_by_type[projectile.damage_type] = float(_damage_by_type.get(projectile.damage_type, 0.0)) + projectile.resolved_damage()
	_fx.hit_spark(projectile.position, projectile.damage_type) # Polish：命中火花
	_active_projectiles.erase(projectile)
	projectile.visible = false
	_projectile_pool.release(projectile)


func _on_wave_completed(wave_index: int, reward_ember: int, reward_becon: int) -> void:
	_ember += reward_ember
	_becon.add(reward_becon, &"wave_completed")
	EventBus.ember_changed.emit(_ember)
	EventBus.wave_completed.emit(wave_index)
	_refresh_build_node_states()
	print("[M2] wave %d cleared: +%d ember +%d becon (kills=%d leaks=%d integrity=%d)" % [
		wave_index + 1, reward_ember, reward_becon, _kills, _leaks, _fleet_integrity
	])
	_write_suspend_save(wave_index + 1)
	if OS.has_environment("ET_DEBUG_SYNC"):
		print("[SYNC] wave=%d becon=%d rng=%d hero=%s" % [
			wave_index + 1, _becon.current, _rng.state,
			"none" if _hero == null else "%.1f,%.1f hp=%.0f down=%s cds=%s" % [_hero.position.x, _hero.position.y, _hero.current_hp, _hero.is_down, JSON.stringify(_hero.get_save_state().get("cooldowns", {}))]
		])
	if _smoke or _soak_seconds > 0.0:
		if _stop_after_wave > 0 and wave_index + 1 >= _stop_after_wave:
			print("[M2-SMOKE] stop-after-wave=%d reached, suspend written, quit(42)" % _stop_after_wave)
			get_tree().quit(42)
			return
		_autoplay_build()
		if _director.state == WaveDirector.State.BUILD:
			_try_start_wave()


func _on_all_waves_completed() -> void:
	_enter_win()


## 相位氛围（Polish）：地形全屏 tint 常驻（仅地形层，保证战斗可读性）+ 切换瞬间闪光/横幅。
func _apply_phase_visual() -> void:
	if _greybox == null or _phase_controller == null:
		return
	_greybox.phase_tint = VisualTheme.TINT_MUCHAO if _phase_controller.current_phase == PhaseController.MUCHAO else VisualTheme.TINT_MINGCHAO
	_greybox.queue_redraw()


func _on_phase_visual(new_phase: StringName) -> void:
	_apply_phase_visual()
	var tint := VisualTheme.TINT_MUCHAO if new_phase == PhaseController.MUCHAO else VisualTheme.TINT_MINGCHAO
	_fx.flash_screen(Color(tint.r, tint.g, tint.b, 0.22))
	if _hud_extras != null and _banners_enabled():
		_hud_extras.show_event_banner(LocalizationService.tr_key(
			&"PHASE_MUCHAO" if new_phase == PhaseController.MUCHAO else &"PHASE_MINGCHAO"))


## 横幅开关：正常游玩始终开；smoke 仅窗口模式开（无头跑批不需要，窗口 smoke 用于 polish 截图证据）。
func _banners_enabled() -> bool:
	return not _smoke or DisplayServer.get_name() != "headless"


## 塔选中态（Polish）：选中塔高亮射程环，取消/切换时恢复。
func _set_selected_tower(tower: GreyboxTower) -> void:
	if _selected_tower_ref != null and is_instance_valid(_selected_tower_ref):
		_selected_tower_ref.highlight_range = false
		_selected_tower_ref.queue_redraw()
	_selected_tower_ref = tower
	if tower != null:
		tower.highlight_range = true
		tower.queue_redraw()


## 漏怪震屏（Polish，仅视觉，不消耗战斗 RNG；尊重 accessibility/screen_shake）。
func _shake(intensity: float = 3.0, seconds: float = 0.25) -> void:
	if UiPalette.low_fx() or not bool(SettingsService.get_value("accessibility", "screen_shake", true)):
		return
	_shake_left = maxf(_shake_left, seconds)
	_shake_intensity = intensity


## 相位模板 2：PhaseController 的环境变化应用到装置运行时（PRD §4.1/§5.3）。
func _on_environment_change(change: Dictionary) -> void:
	if String(change.get("op", "")) == &"device_offline":
		for device: GreyboxDevice in _devices:
			if device.data.id == change.get("device_id", &""):
				device.set_online(false)
				_flash_notice(LocalizationService.tr_key(&"HUD_DEVICE_OFFLINE") % LocalizationService.tr_key(device.data.display_name_key))
				print("[M2] device offline by phase event: %s" % device.data.id)


func _enter_win() -> void:
	_battle_over = true
	_fx.flash_screen(VisualTheme.FLASH_WIN) # Polish：胜利绿闪
	# 航标印记（PRD §9.2）：1 通关 / 2 完整度阈值 / 3 策略目标
	var marks := {
		"completed": true,
		"integrity": _fleet_integrity >= _level.integrity_mark_threshold,
		"strategy": _strategy_done,
	}
	var mark_count: int = int(marks["completed"]) + int(marks["integrity"]) + int(marks["strategy"])
	_last_result = _build_battle_result(true, marks, mark_count)
	_message_label.text = LocalizationService.tr_key(&"HUD_WIN") % [
		_level.id, mark_count, _fleet_integrity, _level.initial_fleet_integrity
	]
	_message_label.visible = true
	print("[M2] WIN: level=%s waves=%d kills=%d leaks=%d integrity=%d marks=%d/3 ticks=%d sim=%.1fs" % [
		_level_id, _director.total_waves(), _kills, _leaks, _fleet_integrity, mark_count, _tick_count, _sim_seconds
	])
	# 主存档：记录关卡结果与印记（PRD §15.3 level_results / §9.2）
	var campaign := SaveService.read_campaign_slot(1)
	var results: Dictionary = campaign.get("level_results", {})
	var prev: Dictionary = results.get(String(_level_id), {})
	results[String(_level_id)] = {
		"completed": true,
		"integrity": _fleet_integrity,
		"kills": _kills,
		"marks": maxi(mark_count, int(prev.get("marks", 0))),
		"best_integrity": maxi(_fleet_integrity, int(prev.get("best_integrity", 0))),
	}
	campaign["level_results"] = results
	campaign["profile_id"] = "default"
	SaveService.write_campaign_slot(1, campaign)
	SaveService.clear_suspend()
	# Phase C：显示结算/战报面板
	if _result_panel != null and not _smoke and not _perf_mode:
		_result_panel.show_result(_last_result)
		_menu_open = true
	if _smoke or _perf_mode:
		_finish_smoke("win", 0)
	elif _soak_seconds > 0.0:
		_soak_next_battle()


## 战报/结算数据组装（PRD §11.3：漏怪构成、伤害构成、首次破防波次、未覆盖标签）。
func _build_battle_result(won: bool, marks: Dictionary, mark_count: int) -> Dictionary:
	# 玩家已部署的伤害类型覆盖（用于"未覆盖标签"提示）
	var covered_types: Array = []
	for tower: GreyboxTower in _towers:
		if not covered_types.has(tower.data.damage_type):
			covered_types.append(tower.data.damage_type)
	var uncovered_tags: Array = []
	for enemy_id: Variant in _leak_by_enemy:
		var enemy_data := _get_enemy_data(enemy_id)
		if enemy_data == null:
			continue
		for tag: Variant in enemy_data.tags:
			if uncovered_tags.has(tag):
				continue
			# 重甲漏怪且无辉光/削甲手段 → 提示
			if tag == &"heavy" and not covered_types.has(&"glow"):
				uncovered_tags.append(tag)
			elif tag == &"swarm" and not _has_splash_or_pierce():
				uncovered_tags.append(tag)
	return {
		"won": won,
		"level_id": String(_level_id),
		"waves_started": _director.waves_started(),
		"waves_total": _director.total_waves(),
		"kills": _kills,
		"leaks": _leaks,
		"leak_by_enemy": _leak_by_enemy.duplicate(),
		"damage_by_type": _damage_by_type.duplicate(),
		"first_breach_wave": _first_breach_wave,
		"uncovered_tags": uncovered_tags,
		"integrity": _fleet_integrity,
		"marks": marks,
		"mark_count": mark_count,
		"strategy_op": String(_level.strategy_objective_op),
		"sim_seconds": snappedf(_sim_seconds, 0.1),
	}


func _has_splash_or_pierce() -> bool:
	for tower: GreyboxTower in _towers:
		if tower.eff_splash_radius() > 0.0 or tower.eff_pierce() > 1 or tower.data.pair_link:
			return true
	return false


func _enter_lose() -> void:
	_battle_over = true
	_fx.flash_screen(VisualTheme.FLASH_LOSE) # Polish：失败红闪
	_director.enter_lose()
	_last_result = _build_battle_result(false, {"completed": false, "integrity": false, "strategy": _strategy_done}, 0)
	_message_label.text = LocalizationService.tr_key(&"HUD_LOSE")
	_message_label.visible = true
	print("[M2] LOSE: level=%s wave=%d kills=%d leaks=%d" % [_level_id, _director.waves_started(), _kills, _leaks])
	SaveService.clear_suspend()
	if _result_panel != null and not _smoke and not _perf_mode:
		_result_panel.show_result(_last_result)
		_menu_open = true
	if _smoke or _perf_mode:
		_finish_smoke("lose", 1)
	elif _soak_seconds > 0.0:
		_soak_next_battle()


func _debug_skip_wave() -> void:
	if _battle_over:
		return
	for enemy: GreyboxEnemy in _enemies.duplicate():
		_remove_enemy(enemy)
	if _director.debug_finish_wave():
		print("[M2] debug skip wave")
	else:
		_flash_notice(LocalizationService.tr_key(&"HUD_SKIP_FAIL"))


# ---------------------------------------------------------------------------
# Suspend save（PRD §15.2：波次完成时写入）
# ---------------------------------------------------------------------------


func _write_suspend_save(completed_waves: int) -> void:
	var towers_payload: Array = []
	for tower: GreyboxTower in _towers:
		towers_payload.append({
			"tower_id": String(tower.data.id),
			"node_id": String(tower.node_id),
			"tier": tower.tier,
			"module_id": String(tower.module.id) if tower.module != null else "",
			"invested_ember": tower.invested_ember,
			"cooldown": tower.get_cooldown(),
		})
	var devices_payload: Array = []
	for device: GreyboxDevice in _devices:
		var device_state := device.get_save_state()
		device_state["device_id"] = String(device.data.id)
		devices_payload.append(device_state)
	var payload := {
		"level_id": String(_level_id),
		"completed_waves": completed_waves,
		"current_phase_id": String(_phase_controller.current_phase),
		"rng_state": str(_rng.state), # int64 经 JSON double 会丢精度，必须字符串化（PRD §15.2 确定性）
		"fleet_integrity": _fleet_integrity,
		"ember": _ember,
		"becon": _becon.current,
		"towers": towers_payload,
		"devices": devices_payload,
		"link_timers": _echo_system.get_link_timers(),
		"strategy_done": _strategy_done,
		"hero": _hero.get_save_state() if _hero != null else {},
		"speed": _speed,
		# 冒烟一次性演示状态也是模拟状态的一部分（驱动英雄指令/经济），
		# 必须随存档恢复，否则中断+恢复与不间断运行产生分歧（PRD §15.2 确定性）。
		"smoke": {
			"plan_cursor": _smoke_plan_cursor,
			"hero_moved": _smoke_hero_moved,
			"hero_ab_used": _smoke_hero_ab_used,
			"tide_used": _smoke_tide_used,
			"ult_used": _smoke_ult_used,
			"repair_demo": _smoke_repair_demo,
		},
	}
	var err := SaveService.write_suspend(payload)
	print("[M2] suspend save written: wave=%d err=%d" % [completed_waves, err])


func _try_resume_suspend() -> void:
	var payload := SaveService.read_suspend()
	if payload.is_empty():
		_flash_notice(LocalizationService.tr_key(&"HUD_NO_SUSPEND"))
		return
	var saved_level := StringName(payload.get("level_id", ""))
	if saved_level != _level_id:
		if not _load_level(saved_level):
			return
		_reset_battle_state()
	_director.restore_progress(int(payload.get("completed_waves", 0)))
	_fleet_integrity = int(payload.get("fleet_integrity", _level.initial_fleet_integrity))
	_ember = int(payload.get("ember", _level.initial_ember))
	_becon.set_value_silent(int(payload.get("becon", 0)))
	_rng.state = String(str(payload.get("rng_state", "0"))).to_int() # 字符串化 int64（兼容旧数值型存档）
	_speed = float(payload.get("speed", 1.0))
	_phase_controller.restore_phase(StringName(payload.get("current_phase_id", "mingchao")))
	for tower_entry: Variant in payload.get("towers", []):
		var node: BuildNodeVisual = _node_by_id.get(StringName(tower_entry.get("node_id", "")))
		var tower_data := _tower_by_id(StringName(tower_entry.get("tower_id", "")))
		if node != null and tower_data != null:
			if _place_tower_at(node, tower_data, true):
				var tower := _tower_at_node(node.node_id)
				if tower != null:
					# 恢复等级/模块/投入（PRD §15.2 塔列表：ID + tier + module_id）
					var saved_tier := clampi(int(tower_entry.get("tier", 1)), 1, 4)
					while tower.tier < saved_tier:
						tower.upgrade()
					var saved_module := StringName(tower_entry.get("module_id", ""))
					if saved_module != &"" and not tower_data.tiers.is_empty():
						for choice: Variant in (tower_data.tiers[0] as TowerTier).module_choices:
							if (choice as ModuleData).id == saved_module:
								tower.apply_module(choice)
					tower.invested_ember = int(tower_entry.get("invested_ember", tower_data.base_cost))
					tower.set_cooldown(float(tower_entry.get("cooldown", 0.0)))
	_echo_system.restore_link_timers(payload.get("link_timers", {}))
	_strategy_done = bool(payload.get("strategy_done", false))
	for device_entry: Variant in payload.get("devices", []):
		for device: GreyboxDevice in _devices:
			if device.data.id == StringName(device_entry.get("device_id", "")):
				device.restore_save_state(device_entry)
	if _hero != null and payload.has("hero"):
		_hero.restore_save_state(payload["hero"])
	_smoke_restored = true
	# 冒烟一次性演示动作（移动/AB 技能/潮汐仪/终极技/修复演示）的已用状态随存档恢复，
	# 保证中断+恢复与不间断运行产出逐 tick 一致（确定性证据）。旧存档缺省视为已用。
	var smoke_state: Dictionary = payload.get("smoke", {})
	_smoke_plan_cursor = int(smoke_state.get("plan_cursor", 0))
	_smoke_hero_moved = bool(smoke_state.get("hero_moved", true))
	_smoke_hero_ab_used = bool(smoke_state.get("hero_ab_used", true))
	_smoke_tide_used = bool(smoke_state.get("tide_used", true))
	_smoke_ult_used = bool(smoke_state.get("ult_used", true))
	_smoke_repair_demo = bool(smoke_state.get("repair_demo", true))
	_refresh_build_node_states()
	EventBus.ember_changed.emit(_ember)
	EventBus.fleet_integrity_changed.emit(_fleet_integrity)
	EventBus.becon_changed.emit(_becon.current, &"resume")
	_flash_notice(LocalizationService.tr_key(&"HUD_SUSPEND_RESUMED") % [saved_level, int(payload.get("completed_waves", 0))])
	if OS.has_environment("ET_DEBUG_SYNC"):
		print("[SYNC] resume-end rng=%d (saved=%d)" % [_rng.state, int(payload.get("rng_state", 0))])
	print("[M2] suspend restored: level=%s completed_waves=%d phase=%s ember=%d integrity=%d towers=%d" % [
		saved_level, int(payload.get("completed_waves", 0)), payload.get("current_phase_id", "?"),
		_ember, _fleet_integrity, payload.get("towers", []).size()
	])
	if _smoke:
		# _start_autoplay 在 _ready 中晚于本函数执行，这里需先加载布防计划，
		# 否则恢复后的第一次 _autoplay_build 面对空计划、漏放波间塔位。
		_smoke_plan = SMOKE_PLANS.get(_level_id, _build_generated_smoke_plan())
		_autoplay_build()
		# 不间断运行中下一波在 director.tick 的 wave_completed 信号内启动（当 tick 中段），
		# 首次 spawn 落在下一 tick；恢复时若在 _ready 直接开波会提前 1 tick，
		# 破坏中断+恢复与不间断运行的逐 tick 一致性。延迟到首个 sim tick 末尾对齐。
		_resume_start_pending = true


func _tower_by_id(tower_id: StringName) -> TowerData:
	for tower: TowerData in _towers_available:
		if tower.id == tower_id:
			return tower
	return null


# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------


func _flash_notice(text: String) -> void:
	_notice = text
	_notice_ttl = 2.5


func _update_hud() -> void:
	_res_label.text = "火种 %d | 舰队完整度 %d/%d | 航标充能 %d/100" % [
		_ember, _fleet_integrity, _level.initial_fleet_integrity, _becon.current
	]
	var state_text: String = LocalizationService.tr_key(STATE_DISPLAY_NAMES[_director.state])
	if _director.state == WaveDirector.State.PRE_DELAY:
		state_text += " %.0fs" % _director.pre_delay_remaining()
	var phase_localized: String = LocalizationService.tr_key(StringName(_phase_controller.current_phase.to_upper().replace("MINGCHAO", "PHASE_MINGCHAO").replace("MUCHAO", "PHASE_MUCHAO")))
	_state_label.text = "波次 %d/%d | %s | 相位 %s | %.1fx%s%s%s" % [
		_director.waves_started(), _director.total_waves(), state_text,
		phase_localized, _speed,
		" | 已暂停" if _paused else "",
		" | " + _phase_controller.pending_description() if _phase_controller.has_pending() else "",
		" | " + _notice if not _notice.is_empty() else "",
	]
	if _hero != null:
		var hero_state := ""
		if _hero.is_down:
			hero_state = "倒地 %.0fs | " % (_hero.data.revive_seconds * (1.0 - _hero.revive_progress()))
		_hero_label.text = "英雄 %s | %sA钩索 %s | B标记 %s | 大扫掠 %s（80 充能）" % [
			LocalizationService.tr_key(_hero_data.display_name_key), hero_state,
			_cd_text(_hero.cooldown_remaining(_hero_data.skill_a.id)),
			_cd_text(_hero.cooldown_remaining(_hero_data.skill_b.id)),
			_cd_text(_hero.cooldown_remaining(_hero_data.ultimate.id)),
		]
	else:
		_hero_label.text = ""
	# 塔面板 / 模块三选一提示（PRD §6.1）
	if _module_choice_tower != null:
		var choices := _module_choice_tower.pending_module_choices()
		var parts: Array = []
		for i: int in choices.size():
			var module := choices[i] as ModuleData
			parts.append("[%d] %s" % [i + 7, LocalizationService.tr_key(module.display_name_key)])
		_tower_label.text = LocalizationService.tr_key(&"HUD_MODULE_CHOICE") % "  ".join(parts)
	elif _selected_tower_ref != null:
		var tower := _selected_tower_ref
		var module_text: String = LocalizationService.tr_key(tower.module.display_name_key) if tower.module != null else "—"
		var upgrade_text: String
		if tower.can_upgrade():
			upgrade_text = "E 升级(%d)" % tower.upgrade_cost()
		else:
			upgrade_text = LocalizationService.tr_key(&"HUD_TOWER_UPGRADE_FULL")
		_tower_label.text = LocalizationService.tr_key(&"HUD_TOWER_INFO") % [
			LocalizationService.tr_key(tower.data.display_name_key), "I II III IV".split(" ")[tower.tier - 1], module_text,
			tower.total_kills, upgrade_text, int(tower.invested_ember * 0.7),
		]
	else:
		var device_text := ""
		for device: GreyboxDevice in _devices:
			device_text += " | 装置%s%s" % [
				"在线" if device.online else "离线",
				"" if device.online else "（修复 %.0f%%）" % (device.repair_ratio() * 100.0),
			]
		_tower_label.text = device_text.strip_edges()
	_update_hud_extras()


func _cd_text(remaining: float) -> String:
	return "就绪" if remaining <= 0.0 else "%.0fs" % remaining


## Polish HUD 增强：相位条 / 技能坞 / Boss 血条每帧刷新（开销极小，控件仅在状态变化时重绘）。
func _update_hud_extras() -> void:
	if _hud_extras == null:
		return
	_hud_extras.update_phase(_phase_controller)
	_hud_extras.update_hero(_hero, _becon.current)
	var boss: GreyboxEnemy = null
	for enemy: GreyboxEnemy in _enemies:
		if enemy.data.boss and enemy.is_alive():
			boss = enemy
			break
	_hud_extras.update_boss(boss)


# ---------------------------------------------------------------------------
# 命令行模式：截图 / 冒烟 / 浸泡
# ---------------------------------------------------------------------------


func _parse_cmdline() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			_level_id = StringName(arg.trim_prefix("--level="))
		elif arg.begins_with("--m0-screenshot="):
			_screenshot_path = arg.trim_prefix("--m0-screenshot=")
		elif arg == "--m1-smoke" or arg == "--m3-smoke":
			_smoke = true
			_m3_mode = arg == "--m3-smoke"
		elif arg == "--m2-perf" or arg == "--m3-perf":
			_perf_mode = true
			_m3_mode = arg == "--m3-perf"
			_smoke = true # 复用 smoke 自动布防跑完全场
			_speed = 3.0
		elif arg.begins_with("--m2-record="):
			_record_seconds = float(arg.trim_prefix("--m2-record="))
			_smoke = true # 录屏模式复用 smoke 自动战斗，到时退出
		elif arg.begins_with("--speed="):
			_speed = float(arg.trim_prefix("--speed="))
		elif arg.begins_with("--stop-after-wave="):
			_stop_after_wave = int(arg.trim_prefix("--stop-after-wave="))
		elif arg == "--resume-suspend":
			_resume_suspend = true
		elif arg.begins_with("--hero="):
			_hero_override = StringName(arg.trim_prefix("--hero="))
		elif arg.begins_with("--m1-soak="):
			_soak_seconds = float(arg.trim_prefix("--m1-soak="))
		elif arg.begins_with("--shot-at-wave="):
			_shot_at_wave = int(arg.trim_prefix("--shot-at-wave="))


func _build_generated_smoke_plan() -> Array:
	## M3 生产工具：新关卡不再要求手写一份 smoke 布防脚本；按关卡允许塔/固定节点生成确定性计划。
	var plan: Array = []
	var preferred: Array[StringName] = [&"tower_needle_rail", &"tower_ember_well", &"tower_wind_nest", &"tower_tide_anvil", &"tower_prism_grove", &"tower_echo_pile"]
	for i: int in _build_nodes.size():
		var tower_id: StringName = preferred[i % preferred.size()]
		if not _level.allowed_towers.has(tower_id):
			tower_id = _level.allowed_towers[i % _level.allowed_towers.size()]
		plan.append([i, tower_id])
		if i % 3 == 2:
			plan.append([&"upgrade", i, i % 3])
	return plan


func _start_autoplay() -> void:
	if not _resume_suspend:
		_rng.seed = SMOKE_SEED # 恢复存档时保留存档中的 RNG state（PRD §15.2）
	if _m3_mode:
		# M3 smoke/perf 的验证辅助：不改变固定 tick/伤害/路径，只避免内容审计被漏怪提前截断。
		_invincible = true
	_smoke_plan = SMOKE_PLANS.get(_level_id, _build_generated_smoke_plan())
	if _soak_seconds > 0.0:
		_speed = 3.0
		_soak_start_msec = Time.get_ticks_msec()
		print("[M1-SOAK] start: %.0f real seconds, speed=3x" % _soak_seconds)
	elif _record_seconds > 0.0:
		_soak_start_msec = Time.get_ticks_msec() # 复用为录屏起始时刻
		print("[M2-RECORD] start: %.0f real seconds, level=%s" % [_record_seconds, _level_id])
	else:
		print("[M1-SMOKE] start: level=%s seed=%d speed=%.1fx fixed_tick=60Hz" % [_level_id, SMOKE_SEED, _speed])
	if not _resume_suspend:
		_autoplay_build()
		_try_start_wave()


func _autoplay_build() -> void:
	while _smoke_plan_cursor < _smoke_plan.size():
		var entry: Array = _smoke_plan[_smoke_plan_cursor]
		if entry[0] is StringName and entry[0] == &"upgrade":
			# 升级演示：[&"upgrade", 节点索引, 模块序号]（模块序号 -1 = 不选模块直接升）
			var up_tower := _tower_at_node((_build_nodes[entry[1]] as BuildNodeVisual).node_id)
			if up_tower == null or not up_tower.can_upgrade():
				_smoke_plan_cursor += 1
				continue
			if _ember < up_tower.upgrade_cost():
				return
			_ember -= up_tower.upgrade_cost()
			EventBus.ember_changed.emit(_ember)
			up_tower.upgrade()
			var module_idx := int(entry[2])
			if module_idx >= 0 and up_tower.tier == 2:
				var choices: Array = up_tower.data.tiers[0].module_choices
				if module_idx < choices.size():
					up_tower.apply_module(choices[module_idx])
					_modules_selected += 1
					EventBus.module_selected.emit(up_tower.data.id, (choices[module_idx] as ModuleData).id)
			_finish_upgrade(up_tower)
			_smoke_plan_cursor += 1
			continue
		var node := _build_nodes[entry[0]]
		var tower_data := _tower_by_id(entry[1])
		if node.state == BuildNodeVisual.State.OCCUPIED:
			_smoke_plan_cursor += 1
			continue
		if tower_data == null or _ember < tower_data.base_cost:
			return
		_place_tower_at(node, tower_data)
		_smoke_plan_cursor += 1


func _autoplay_tick() -> void:
	if _smoke and _sim_seconds > SMOKE_TIMEOUT_SIM_SECONDS:
		_finish_smoke("timeout", 2)
		return
	if _hero == null:
		return
	# 英雄移动演示：第 1 波开始后就位到路线中段（证明右键移动链路可用）
	if not _smoke_hero_moved and _director.waves_started() >= 1:
		_smoke_hero_moved = true
		_hero.command_move(_level.hero_spawn + Vector2(-140, -56))
	# 英雄技能演示：第 2 波迎击时按英雄数据派发统一技能效果。
	if not _smoke_hero_ab_used and _director.state == WaveDirector.State.SPAWNING and _director.waves_started() >= 2:
		_smoke_hero_ab_used = true
		if _hero.data.id == &"hero_zhushou_muen":
			_hero.use_skill_a()
			_hero.command_move(_level.hero_spawn)
			_hero.use_skill_b()
		else:
			_hero.use_skill_b()
			_hero.use_skill_a(Vector2(320, 240))
	# 潮汐仪：有待切换事件且充能足够时提前一次（证明航标充能竞争）
	if not _smoke_tide_used and _phase_controller.has_pending() and _becon.current >= 40:
		_smoke_tide_used = _phase_controller.request_shift(true)
	# 终极技：充能足够时放一次
	if not _smoke_ult_used and _becon.current >= 80:
		_smoke_ult_used = _hero.use_ultimate()
	# C03 装置修复演示：灯塔离线后英雄驻守修复（一次性）
	if not _smoke_repair_demo and _director.waves_started() >= 3:
		for device: GreyboxDevice in _devices:
			if not device.online:
				_smoke_repair_demo = true
				if _hero != null and not _hero.is_down:
					_hero.command_move(device.position + Vector2(0, 24))
				break


func _finish_smoke(result: String, exit_code: int) -> void:
	if not _battle_over:
		_battle_over = true
	var report := {
		"result": result,
		"level_id": String(_level_id),
		"seed": SMOKE_SEED,
		"speed": _speed,
		"fixed_tick_hz": 60,
		"tick_count": _tick_count,
		"sim_seconds": snappedf(_sim_seconds, 0.01),
		"waves_total": _director.total_waves(),
		"waves_started": _director.waves_started(),
		"kills": _kills,
		"leaks": _leaks,
		"fleet_integrity": _fleet_integrity,
		"ember": _ember,
		"becon": _becon.current,
		"towers_built": _towers.size(),
		"total_damage": snappedf(_total_damage, 0.1),
		"dbg_fires": _dbg_fires,
		"dbg_link_pulses": _echo_system.pulses_total,
		"phase": String(_phase_controller.current_phase),
		"phase_transitions": _phase_controller.transition_log,
		"tide_clock_used": _smoke_tide_used,
		"hero": {
			"present": _hero != null,
			"skills_used": _hero.skills_used if _hero != null else {},
			"distance_moved": snappedf(_hero.distance_moved, 0.1) if _hero != null else 0.0,
			"ultimate_used": _smoke_ult_used,
		},
		"suspend_restored": _smoke_restored,
		"invincible": _invincible,
		"simulation_assist": _m3_mode,
		"marks": _last_result.get("marks", {}),
		"strategy_done": _strategy_done,
		"strategy_op": String(_level.strategy_objective_op),
		"echo_links": _echo_system.link_count(),
		"devices": _devices.map(func(d: GreyboxDevice) -> Dictionary: return {"id": String(d.data.id), "online": d.online, "repair_progress": snappedf(d.repair_ratio(), 0.01)}),
		"modules_selected": _modules_selected,
		"first_breach_wave": _first_breach_wave,
		"uncovered_tags": _last_result.get("uncovered_tags", []),
		"boss_phases_seen": _boss_phase_seen.duplicate(true),
	}
	var out_dir := ProjectSettings.globalize_path("res://out")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var suffix := "_speed%s" % _speed
	if _resume_suspend:
		suffix += "_resumed"
	var report_prefix := "m3" if _m3_mode or String(_level_id) >= "level_c04" else "m2"
	var report_path := out_dir.path_join("%s_smoke_%s%s.json" % [report_prefix, _level_id, suffix])
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	if _perf_mode:
		_write_perf_report(out_dir)
	print("[M1-SMOKE] result=%s level=%s waves=%d/%d kills=%d leaks=%d integrity=%d ember=%d becon=%d towers=%d ticks=%d sim=%.2fs phase=%s tide=%s ult=%s" % [
		result, _level_id, _director.waves_started(), _director.total_waves(), _kills, _leaks,
		_fleet_integrity, _ember, _becon.current, _towers.size(), _tick_count, _sim_seconds,
		_phase_controller.current_phase, _smoke_tide_used, _smoke_ult_used
	])
	print("[M1-SMOKE] report: %s" % report_path)
	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var shot_path := out_dir.path_join("m2_smoke_%s.png" % _level_id)
		image.save_png(shot_path)
		print("[M2-SMOKE] screenshot saved: %s" % shot_path)
	get_tree().quit(exit_code)


## --m2-perf：帧时间统计（avg/p99/1%low，毫秒与 FPS），PRD §18.6 性能验收。
func _write_perf_report(out_dir: String) -> void:
	if _perf_frames.is_empty():
		return
	var frames := _perf_frames.duplicate()
	frames.sort()
	var total := 0.0
	for f: float in frames:
		total += f
	var avg_ms := total / frames.size()
	var p99_ms: float = frames[mini(int(frames.size() * 0.99), frames.size() - 1)]
	var low1_idx := maxi(int(frames.size() * 0.99) - 1, 0) # 1% 最慢帧均值近似：取最慢 1% 区间
	var slow_count := maxi(frames.size() - low1_idx, 1)
	var slow_total := 0.0
	for i: int in range(low1_idx, frames.size()):
		slow_total += frames[i]
	var low1_ms := slow_total / slow_count
	var perf := {
		"level_id": String(_level_id),
		"speed": _speed,
		"frames": frames.size(),
		"avg_ms": snappedf(avg_ms, 0.01),
		"avg_fps": snappedf(1000.0 / maxf(avg_ms, 0.001), 0.1),
		"p99_ms": snappedf(p99_ms, 0.01),
		"low1_ms": snappedf(low1_ms, 0.01),
		"low1_fps": snappedf(1000.0 / maxf(low1_ms, 0.001), 0.1),
		"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"window_size": [ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height")],
		"towers": _towers.size(),
		"ticks": _tick_count,
	}
	var perf_prefix := "m3" if _m3_mode or String(_level_id) >= "level_c04" else "m2"
	var perf_path := out_dir.path_join("%s_perf_%s.json" % [perf_prefix, _level_id])
	var pf := FileAccess.open(perf_path, FileAccess.WRITE)
	if pf != null:
		pf.store_string(JSON.stringify(perf, "  "))
		pf.close()
	print("[M2-PERF] level=%s frames=%d avg=%.2fms(%.0ffps) p99=%.2fms 1%%low=%.2fms(%.0ffps) -> %s" % [
		_level_id, frames.size(), avg_ms, perf["avg_fps"], p99_ms, low1_ms, perf["low1_fps"], perf_path
	])


func _soak_next_battle() -> void:
	_soak_battles += 1
	_restart_battle()
	_autoplay_build()
	_try_start_wave()


func _finish_soak() -> void:
	print("[M1-SOAK] done: battles=%d real_seconds=%.0f last_level=%s" % [
		_soak_battles, float(Time.get_ticks_msec() - _soak_start_msec) / 1000.0, _level_id
	])
	get_tree().quit(0)


func _capture_screenshot_and_quit() -> void:
	for i: int in 5:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(_screenshot_path)
	print("[M1] screenshot saved: %s (err=%d)" % [_screenshot_path, err])
	get_tree().quit()
