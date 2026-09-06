extends TestBase
## BattleSession：session-owned 状态清单 + reset 入口契约。
## 不实例化战斗节点；只测静态清单 / 默认值。

func test_state_fields_list_is_stable() -> void:
	check(BattleSession.STATE_FIELDS.size() >= 20, "STATE_FIELDS 至少 20 项")
	check_eq(String(BattleSession.STATE_FIELDS[0]), "level_id", "首字段 level_id")
	check(BattleSession.STATE_FIELDS.has(&"ember"), "含 ember")
	check(BattleSession.STATE_FIELDS.has(&"fleet_integrity"), "含 fleet_integrity")
	check(BattleSession.STATE_FIELDS.has(&"becon"), "含 becon")
	check(BattleSession.STATE_FIELDS.has(&"rng_state"), "含 rng_state")


func test_with_defaults_fills_missing_fields() -> void:
	var partial := {"level_id": "level_c01", "ember": 200}
	var filled := BattleSession.with_defaults(partial)
	check_eq(filled.get("ember"), 200, "原有字段保留")
	check(filled.has("fleet_integrity"), "补 fleet_integrity 键")
	check(filled.has("rng_state"), "补 rng_state 键")
	check(filled.has("becon"), "补 becon 键")
	check(BattleSession.payload_has_all_keys(filled), "补全后所有键齐")


func test_payload_has_all_keys_strict() -> void:
	var ok := {"level_id": "x", "level_data": null, "hero_data_id": null,
		"rng_state": 0, "rng_seed": 0, "ember": 0, "fleet_integrity": 0, "becon": 0,
		"towers": [], "enemies": [], "devices": [], "hero": null,
		"kills": 0, "leaks": 0, "total_damage": 0.0,
		"leak_by_enemy": {}, "damage_by_type": {}, "first_breach_wave": 0,
		"strategy_done": false, "modules_selected": 0, "boss_phase_seen": [],
		"tick_count": 0, "sim_seconds": 0.0, "speed": 1.0,
		"paused": false, "battle_over": false, "invincible": false}
	check(BattleSession.payload_has_all_keys(ok), "完整 payload 通过")
	var missing: Dictionary = {"level_id": "x"}
	check(not BattleSession.payload_has_all_keys(missing), "缺键 payload 不通过")