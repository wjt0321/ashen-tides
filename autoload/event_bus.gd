extends Node
## EventBus：全局 typed signal 总线。只传事件，不存状态（RESEARCH_REPORT.md §3.2）。
## 依赖规则：AutoLoad 不得依赖其他 AutoLoad 的 _init。

# 相位系统（PRD §4）
signal phase_changed(new_phase: StringName)
signal phase_warning(pending_phase: StringName, seconds_remaining: float)

# 航标充能（PRD §10，0–100，英雄终极技与潮汐仪争夺同一资源）
signal becon_changed(new_value: int, source: StringName)
signal becon_spent(amount: int)

# 关卡内资源（PRD §3.1：火种 ember / 舰队完整度 fleet_integrity）
signal ember_changed(new_value: int)
signal fleet_integrity_changed(new_value: int)

# 波次（RESEARCH_REPORT §13）
signal wave_started(wave_index: int)
signal wave_completed(wave_index: int)

# M0 灰盒战斗
signal enemy_killed(enemy_id: StringName, reward_ember: int)
signal fleet_leaked(enemy_id: StringName, integrity_loss: int)
signal tower_placed(tower_id: StringName, node_id: StringName)

# M1：相位 / 潮汐仪 / 英雄 / 速度 / 存档
signal tide_clock_shifted(direction: StringName)
signal tide_clock_failed(reason: StringName)
signal ultimate_failed_no_becon
signal hero_skill_used(skill_id: StringName)
signal game_speed_changed(new_speed: float)
signal suspend_save_written(level_id: StringName, completed_waves: int)
signal level_loaded(level_id: StringName)

# M2：塔升级/模块/出售、击杀返能、装置、英雄倒地、设置
signal tower_upgraded(tower_id: StringName, node_id: StringName, new_tier: int)
signal module_selected(tower_id: StringName, module_id: StringName)
signal tower_sold(tower_id: StringName, node_id: StringName, refund: int)
signal becon_kill_refund(amount: int, tower_id: StringName)
signal device_offline(device_id: StringName)
signal device_online(device_id: StringName)
signal device_repaired(device_id: StringName)
signal hero_down
signal hero_revived
signal settings_applied

# M0 灰盒测试
signal test_state_reset


func _ready() -> void:
	print("[M0] EventBus ready")
