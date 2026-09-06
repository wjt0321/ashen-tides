class_name BattleSession
extends RefCounted
## 战斗会话（M2 Flow Shell 第一批；OPEN_SOURCE_TD_RESEARCH §3.3）。
## 边界：restart/重开作用于一个 battle session —— 一局战斗拥有的可变节点与计数
## 从这里集中复位，不依赖散落节点自己恢复。
## 第一批只把 main._reset_battle_state 的实体收拢到这里；towers/enemies 等数组的
## 所有权仍留在战斗场景，后续批次沿 M2 Gate 玩家路径渐进迁移（不为重构而重构，§3.4）。

var battle ## scripts/boot/main.gd 实例（非类型化：动态访问其会话字段）


func _init(battle_root) -> void:
	battle = battle_root


## 复位一整局：清空运行时实体、计数器、建造节点占用、英雄与装置，回到 BUILD 阶段。
## 等价于原 main._reset_battle_state 的完整语义（含 S1 修复的节点占用复位）。
func reset() -> void:
	var b = battle
	for child: Node in b._battle_root.get_children():
		child.queue_free()
	b._towers.clear()
	b._enemies.clear()
	b._active_projectiles.clear()
	b._devices.clear()
	b._projectile_pool = ObjectPool.new(b._create_projectile)
	b._echo_system.reset()
	b._director.reset()
	b._becon.set_value_silent(0)
	b._ember = b._level.initial_ember
	b._fleet_integrity = b._level.initial_fleet_integrity
	b._paused = false
	b._battle_over = false
	b._invincible = false
	b._acc = 0.0
	b._tick_count = 0
	b._sim_seconds = 0.0
	b._kills = 0
	b._leaks = 0
	b._total_damage = 0.0
	b._leak_by_enemy.clear()
	b._leak_by_wave.clear()
	b._fail_reason = ""
	b._damage_by_type.clear()
	b._first_breach_wave = 0
	b._strategy_done = false
	b._modules_selected = 0
	b._boss_phase_seen.clear()
	b._perf_frames.clear()
	b._dbg_fires = 0
	b._set_selected_tower(null)
	b._module_choice_tower = null
	b._phase_controller.setup(b._level.phase_events, b._path_network, b._becon)
	b._path_network.visible = true
	b._apply_phase_visual() # Polish：重开后相位 tint 复位
	b.position = Vector2.ZERO
	b._shake_left = 0.0
	b._message_label.visible = false
	b._notice = ""
	if b._hero_data != null:
		b._hero = GreyboxHero.new()
		b._hero.name = "Hero"
		b._hero.position = b._level.hero_spawn
		b._hero.enemies = b._enemies
		b._battle_root.add_child(b._hero)
		b._hero.setup(b._hero_data, b._becon)
	else:
		b._hero = null
	# 环境装置（相位模板 2，PRD §5.3）
	for device_data: Variant in b._level.devices:
		var device := GreyboxDevice.new()
		device.name = "Device_%s" % device_data.id
		device.setup(device_data)
		device.enemies = b._enemies
		device.hero = b._hero
		device.current_phase = b._phase_controller.current_phase
		b._battle_root.add_child(device)
		b._devices.append(device)
	if b._hero != null:
		b._hero.devices = b._devices
	b._smoke_plan_cursor = 0
	b._smoke_hero_ab_used = false
	b._smoke_hero_moved = false
	b._smoke_ult_used = false
	b._smoke_tide_used = false
	b._smoke_repair_demo = false
	# S1 修复：上局塔随 _battle_root 清空，节点占用状态必须同步复位——
	# 否则重开后已建节点永久保持 OCCUPIED（_refresh_build_node_states 跳过占用节点）
	for node: BuildNodeVisual in b._build_nodes:
		if node.state != BuildNodeVisual.State.FREE:
			node.set_state(BuildNodeVisual.State.FREE)
	b._refresh_build_node_states()
	EventBus.ember_changed.emit(b._ember)
	EventBus.fleet_integrity_changed.emit(b._fleet_integrity)
	EventBus.becon_changed.emit(0, &"reset")


## session-owned 状态字段清单（与 main.gd 私有变量一一对应）。
##  对 Flow / 集成测试 / suspend 反序列化校验统一暴露（PRD §15.2 + PROJECT_EXECUTION_BASELINE §3）。
const STATE_FIELDS: Array[StringName] = [
	&"level_id", &"level_data", &"hero_data_id",
	&"rng_state", &"rng_seed",
	&"ember", &"fleet_integrity", &"becon",
	&"towers", &"enemies", &"devices", &"hero",
	&"kills", &"leaks", &"total_damage",
	&"leak_by_enemy", &"damage_by_type", &"first_breach_wave",
	&"strategy_done", &"modules_selected", &"boss_phase_seen",
	&"tick_count", &"sim_seconds", &"speed",
	&"paused", &"battle_over", &"invincible",
]


## suspend save 缺字段时补 null（兼容旧 schema，PRD §15.4）。
static func with_defaults(payload: Dictionary) -> Dictionary:
	for field: StringName in STATE_FIELDS:
		if not payload.has(field):
			payload[field] = null
	return payload


## 断言 payload 是否覆盖所有 session-owned 字段（集成测试用）。
static func payload_has_all_keys(payload: Dictionary) -> bool:
	for field: StringName in STATE_FIELDS:
		if not payload.has(field):
			return false
	return true
