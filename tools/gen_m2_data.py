#!/usr/bin/env python3
"""M2 Phase A：批量生成数据 .tres（模块/塔 tiers/新敌人/装置/相位事件/波次/关卡）。
直接写文本 .tres，格式与 M0/M1 既有文件一致。幂等：全量覆盖同名文件。"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SCRIPT_PATHS = {
    "ModuleData": "res://scripts/data/module_data.gd",
    "TowerData": "res://scripts/data/tower_data.gd",
    "TowerTier": "res://scripts/data/tower_tier.gd",
    "EnemyData": "res://scripts/data/enemy_data.gd",
    "WaveData": "res://scripts/data/wave_data.gd",
    "WaveGroup": "res://scripts/data/wave_group.gd",
    "LevelData": "res://scripts/data/level_data.gd",
    "PhaseEventData": "res://scripts/data/phase_event_data.gd",
    "DeviceData": "res://scripts/data/device_data.gd",
}


def write(rel, text):
    path = os.path.join(ROOT, rel.replace("/", os.sep))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("wrote", rel)


def fmt_val(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float):
        return repr(v)
    if isinstance(v, int):
        return str(v)
    if isinstance(v, str):  # 已格式化字面量（&"x"、Vector2(...) 等）
        # tres 文本格式要求 Color 四分量（r,g,b,a），三分量会解析失败
        if v.startswith("Color(") and v.count(",") == 2:
            return v[:-1] + ", 1.00)"
        return v
    raise TypeError(v)


def resource_header(script_class, load_steps, ext_resources, sub_resources):
    """ext_resources: [(script|Resource, path, id)]; sub_resources: 占位计数"""
    lines = ['[gd_resource type="Resource" script_class="%s" load_steps=%d format=3]' % (script_class, load_steps), ""]
    for _i, (typ, path, rid) in enumerate(ext_resources):
        lines.append('[ext_resource type="%s" path="%s" id="%s"]' % (typ, path, rid))
    if ext_resources:
        lines.append("")
    return lines


def emit_block(lines, props):
    for k, v in props:
        lines.append("%s = %s" % (k, fmt_val(v)))


# ---------------------------------------------------------------- 模块 ×9
MODULES = [
    # (id, tower_id, name_key, desc_key, op, value, tint, note)
    ("mod_needle_long_needle", "tower_needle_rail", "MOD_NEEDLE_LONG_NEEDLE", "MOD_NEEDLE_LONG_NEEDLE_DESC", "pierce_bonus", 2.0, "Color(0.55, 0.80, 1.00)", "长针：穿透 +2（PRD §6.2）"),
    ("mod_needle_barb", "tower_needle_rail", "MOD_NEEDLE_BARB", "MOD_NEEDLE_BARB_DESC", "armor_shred", 15.0, "Color(0.95, 0.60, 0.40)", "倒钩：命中削甲 15，持续 4 秒"),
    ("mod_needle_speed_wheel", "tower_needle_rail", "MOD_NEEDLE_SPEED_WHEEL", "MOD_NEEDLE_SPEED_WHEEL_DESC", "fire_rate_mult", 0.75, "Color(0.70, 1.00, 0.70)", "速轮：攻击周期 ×0.75"),
    ("mod_ember_wide_nozzle", "tower_ember_well", "MOD_EMBER_WIDE_NOZZLE", "MOD_EMBER_WIDE_NOZZLE_DESC", "splash_radius_mult", 1.5, "Color(1.00, 0.80, 0.45)", "扩口：溅射半径 ×1.5"),
    ("mod_ember_condensed", "tower_ember_well", "MOD_EMBER_CONDENSED", "MOD_EMBER_CONDENSED_DESC", "focus_damage_mult", 1.6, "Color(1.00, 0.55, 0.30)", "凝焰：溅射归零，伤害 ×1.6"),
    ("mod_ember_tempering", "tower_ember_well", "MOD_EMBER_TEMPERING", "MOD_EMBER_TEMPERING_DESC", "kill_becon", 2.0, "Color(0.85, 0.95, 0.55)", "回火：本塔击杀返还 2 航标充能"),
    ("mod_echo_sluggish", "tower_echo_pile", "MOD_echo_sluggish".upper(), "MOD_echo_sluggish_DESC".upper(), "link_slow", 0.3, "Color(0.65, 0.75, 1.00)", "迟滞弦：链路上敌人减速 30%"),
    ("mod_echo_broken", "tower_echo_pile", "MOD_ECHO_BROKEN", "MOD_ECHO_BROKEN_DESC", "link_silence", 1.0, "Color(0.80, 0.60, 1.00)", "断响：链路上敌人被沉默（能力失效）"),
    ("mod_echo_resonance", "tower_echo_pile", "MOD_ECHO_RESONANCE", "MOD_ECHO_RESONANCE_DESC", "link_chain", 1.0, "Color(1.00, 0.90, 0.50)", "共振：链路伤害跳跃 +1 目标"),
]
for mid, tower, nk, dk, op, val, tint, note in MODULES:
    lines = resource_header("ModuleData", 2, [("Script", SCRIPT_PATHS["ModuleData"], "1")], 0)
    lines.append("[resource]")
    emit_block(lines, [
        ("script", 'ExtResource("1")'), ("id", '&"%s"' % mid), ("schema_version", 1),
        ("enabled", True), ("designer_note", '"M2：%s"' % note),
        ("tower_id", '&"%s"' % tower), ("display_name_key", '&"%s"' % nk),
        ("description_key", '&"%s"' % dk), ("effect_op", '&"%s"' % op),
        ("effect_value", val), ("tint", tint),
    ])
    write("data/modules/%s.tres" % mid, "\n".join(lines) + "\n")


# ---------------------------------------------------------------- 塔（含 tiers 子资源）
def tower_tres(tower_id, note, name_key, base, tiers, extra=None):
    """base: dict of flat props (tier I); tiers: list of (tier, cost, dmg_min, dmg_max, range, period, [module ids])"""
    ext = [("Script", SCRIPT_PATHS["TowerData"], "1"), ("Script", SCRIPT_PATHS["TowerTier"], "2")]
    mod_ids = []
    for t in tiers:
        for m in t[6]:
            if m not in mod_ids:
                mod_ids.append(m)
    for i, m in enumerate(mod_ids):
        ext.append(("Resource", "res://data/modules/%s.tres" % m, "m%d" % i))
    load_steps = 1 + len(ext) + len(tiers)
    lines = resource_header("TowerData", load_steps, ext, 0)
    for t in tiers:
        tier, cost, dmin, dmax, rng, period, mods = t
        lines.append('[sub_resource type="Resource" id="TowerTier_%d"]' % tier)
        lines.append('script = ExtResource("2")')
        props = [("tier", tier), ("cost_to_upgrade", cost), ("damage_min", float(dmin)),
                 ("damage_max", float(dmax)), ("range_px", float(rng)), ("attack_period", float(period))]
        if mods:
            refs = ", ".join('ExtResource("m%d")' % mod_ids.index(m) for m in mods)
            props.append(("module_choices", "[%s]" % refs))
        emit_block(lines, props)
        lines.append("")
    lines.append("[resource]")
    props = [('script', 'ExtResource("1")'), ("id", '&"%s"' % tower_id), ("schema_version", 1),
             ("enabled", True), ("designer_note", '"%s"' % note),
             ("introduced_in_level", '&"%s"' % base.get("introduced", "level_c01")),
             ("display_name_key", '&"%s"' % name_key)]
    for k, v in base["props"]:
        props.append((k, v))
    refs = ", ".join('SubResource("TowerTier_%d")' % t[0] for t in tiers)
    props.append(("tiers", "[%s]" % refs))
    if extra:
        props.extend(extra)
    emit_block(lines, props)
    write("data/towers/%s.tres" % tower_id, "\n".join(lines) + "\n")


tower_tres("tower_needle_rail",
    "M2：针轨弩台（直线穿透，方向重要，PRD §6.2）；II 级 3 选 1 校准模块，本局锁定",
    "TOWER_NEEDLE_RAIL",
    {"introduced": "level_c01", "props": [
        ("base_cost", 100), ("range_px", 112.0), ("attack_period", 0.8),
        ("damage_min", 18.0), ("damage_max", 20.0), ("damage_type", '&"physical"'),
        ("projectile_speed", 320.0), ("splash_radius", 0.0), ("pierce", 2),
    ]},
    [(2, 80, 24, 27, 120, 0.8, ["mod_needle_long_needle", "mod_needle_barb", "mod_needle_speed_wheel"]),
     (3, 140, 34, 38, 120, 0.7, []),
     (4, 220, 48, 54, 128, 0.65, [])])

tower_tres("tower_ember_well",
    "M2：余烬喷井（扇形短射程 + 溅射热区，PRD §6.2）；II 级 3 选 1 校准模块",
    "TOWER_EMBER_WELL",
    {"introduced": "level_c02", "props": [
        ("base_cost", 120), ("range_px", 88.0), ("attack_period", 1.1),
        ("damage_min", 26.0), ("damage_max", 30.0), ("damage_type", '&"glow"'),
        ("projectile_speed", 280.0), ("splash_radius", 40.0), ("pierce", 1),
    ]},
    [(2, 90, 34, 38, 88, 1.1, ["mod_ember_wide_nozzle", "mod_ember_condensed", "mod_ember_tempering"]),
     (3, 150, 46, 52, 92, 1.1, []),
     (4, 240, 62, 70, 92, 1.0, [])])

tower_tres("tower_echo_pile",
    "M2：回声桩阵（两座桩之间生成辉光伤害线，PRD §6.2）；II 级 3 选 1 校准模块",
    "TOWER_ECHO_PILE",
    {"introduced": "level_c03", "props": [
        ("base_cost", 80), ("range_px", 96.0), ("attack_period", 0.5),
        ("damage_min", 7.0), ("damage_max", 9.0), ("damage_type", '&"glow"'),
        ("projectile_speed", 0.0), ("splash_radius", 0.0), ("pierce", 1),
    ]},
    [(2, 70, 10, 12, 96, 0.5, ["mod_echo_sluggish", "mod_echo_broken", "mod_echo_resonance"]),
     (3, 120, 14, 17, 96, 0.45, []),
     (4, 200, 19, 23, 96, 0.4, [])],
    extra=[("pair_link", True), ("link_max_range", 220.0)])


# ---------------------------------------------------------------- 敌人 ×2 新增 + 4 既有补 body_color
ENEMIES = [
    # (id, note, name_key, hp, speed, armor, gres, leak, reward, radius, tags, elite, shield, aura_r, aura_mult, color, introduced)
    ("lamp_leech", "M2：灯寄生体，护盾标签（PRD §8.6）；护盾先于生命承伤，控制后集火反制",
     "ENEMY_LAMP_LEECH", 140.0, 45.0, 0.0, 20.0, 1, 14, 11.0, '[&"shield"]', False, 80.0, 0.0, 1.0,
     "Color(0.65, 0.85, 0.95)", "level_c03"),
    ("tide_back_navigator", "M2：潮背导航员，支援标签（PRD §8.6）；光环加速周围友军，优先击杀反制",
     "ENEMY_TIDE_BACK_NAVIGATOR", 120.0, 50.0, 10.0, 10.0, 1, 16, 10.0, '[&"support"]', False, 0.0, 80.0, 1.3,
     "Color(0.75, 0.55, 0.95)", "level_c03"),
]
for eid, note, nk, hp, spd, armor, gres, leak, reward, radius, tags, elite, shield, aura_r, aura_mult, color, intro in ENEMIES:
    lines = resource_header("EnemyData", 2, [("Script", SCRIPT_PATHS["EnemyData"], "1")], 0)
    lines.append("[resource]")
    emit_block(lines, [
        ("script", 'ExtResource("1")'), ("id", '&"%s"' % eid), ("schema_version", 1),
        ("enabled", True), ("designer_note", '"%s"' % note), ("introduced_in_level", '&"%s"' % intro),
        ("display_name_key", '&"%s"' % nk), ("max_hp", hp), ("speed_px_per_sec", spd),
        ("armor", armor), ("glow_resist", gres), ("leak_damage", leak),
        ("kill_reward_ember", reward), ("radius_px", radius), ("tags", tags),
        ("elite", elite), ("shield_hp", shield), ("aura_radius", aura_r),
        ("aura_speed_mult", aura_mult), ("body_color", color),
    ])
    write("data/enemies/%s.tres" % eid, "\n".join(lines) + "\n")

# 既有 4 敌补 body_color（可读性：色+形+文字三重编码）
PATCH_COLORS = {
    "salt_shell_walker": "Color(0.85, 0.72, 0.50)",
    "mast_rat_swarm": "Color(0.65, 0.50, 0.35)",
    "splitfin_dasher": "Color(0.45, 0.85, 0.90)",
    "rust_armor_carrier": "Color(0.80, 0.45, 0.30)",
}
for eid, color in PATCH_COLORS.items():
    path = os.path.join(ROOT, "data", "enemies", "%s.tres" % eid)
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    color4 = color[:-1] + ", 1.00)"  # tres 要求四分量
    if "body_color" in text:
        import re as _re
        text = _re.sub(r"\nbody_color = [^\n]+", "\nbody_color = %s" % color4, text)
    else:
        text = text.rstrip("\n") + "\nbody_color = %s\n" % color4
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("patched", eid)


# ---------------------------------------------------------------- 装置 + 相位事件（C03 模板 2）
lines = resource_header("DeviceData", 2, [("Script", SCRIPT_PATHS["DeviceData"], "1")], 0)
lines.append("[resource]")
emit_block(lines, [
    ("script", 'ExtResource("1")'), ("id", '&"device_c03_lighthouse"'), ("schema_version", 1),
    ("enabled", True),
    ("designer_note", '"M2：C03 失火灯塔装置——在线时每 3 秒辉光脉冲；暮潮事件令其离线，英雄驻守 3 秒修复（PRD §5.3）"'),
    ("display_name_key", '&"DEVICE_C03_LIGHTHOUSE"'), ("position", "Vector2(320, 48)"),
    ("radius_px", 110.0), ("effect_op", '&"glow_pulse"'), ("effect_value", 22.0),
    ("interval_seconds", 3.0), ("active_phase", '&"both"'), ("repairable", True), ("repair_seconds", 3.0),
])
write("data/devices/device_c03_lighthouse.tres", "\n".join(lines) + "\n")

lines = resource_header("PhaseEventData", 2, [("Script", SCRIPT_PATHS["PhaseEventData"], "1")], 0)
lines.append("[resource]")
emit_block(lines, [
    ("script", 'ExtResource("1")'), ("id", '&"phase_c03_beacon_failure"'), ("schema_version", 1),
    ("enabled", True),
    ("designer_note", '"C03 失火灯塔：第 3 波明潮→暮潮，灯塔装置离线（相位模板 2：环境装置失效，PRD §4.1/§5.3）"'),
    ("level_id", '&"level_c03"'), ("starts_at_wave", 3),
    ("from_phase", '&"mingchao"'), ("to_phase", '&"muchao"'),
    ("activates_routes", "[]"), ("deactivates_routes", "[]"),
    ("environment_changes", '[{"op": &"device_offline", "device_id": &"device_c03_lighthouse"}]'),
    ("warning_seconds", 20.0), ("player_interruptible", True), ("becon_cost", 40),
])
write("data/phase_events/phase_c03_beacon_failure.tres", "\n".join(lines) + "\n")


# ---------------------------------------------------------------- 波次
def wave_tres(wave_id, level_id, index, note, groups, reward_e, reward_b, intent):
    """groups: [(enemy_id, count, interval, delay, route_id)]"""
    lines = resource_header("WaveData", 2 + len(groups), [
        ("Script", SCRIPT_PATHS["WaveData"], "1"), ("Script", SCRIPT_PATHS["WaveGroup"], "2")], 0)
    sub_ids = []
    for gi, (enemy, count, interval, delay, route) in enumerate(groups):
        sid = "WaveGroup_%d" % (gi + 1)
        sub_ids.append(sid)
        lines.append('[sub_resource type="Resource" id="%s"]' % sid)
        lines.append('script = ExtResource("2")')
        props = [("enemy_id", '&"%s"' % enemy), ("count", count),
                 ("interval_seconds", float(interval)), ("entrance_index", 0),
                 ("delay_after_prev_seconds", float(delay))]
        if route:
            props.append(("route_id", '&"%s"' % route))
        emit_block(lines, props)
        lines.append("")
    lines.append("[resource]")
    emit_block(lines, [
        ("script", 'ExtResource("1")'), ("id", '&"%s"' % wave_id), ("schema_version", 1),
        ("enabled", True), ("designer_note", '"%s"' % note),
        ("introduced_in_level", '&"%s"' % level_id), ("wave_index", index),
        ("pre_delay_seconds", 5.0),
        ("groups", "[%s]" % ", ".join('SubResource("%s")' % s for s in sub_ids)),
        ("completion_reward_ember", reward_e), ("completion_reward_becon", reward_b),
        ("intent", '&"%s"' % intent),
    ])
    write("data/waves/%s.tres" % wave_id, "\n".join(lines) + "\n")


W = "salt_shell_walker"; S = "mast_rat_swarm"; D = "splitfin_dasher"; A = "rust_armor_carrier"
L = "lamp_leech"; N = "tide_back_navigator"
# C01 追加 3 波（现有 3 波保留）
wave_tres("wave_c01_04", "level_c01", 4, "M2：群聚引入（桅鼠群）", [(S, 12, 0.7, 0.0, ""), (W, 4, 1.2, 2.0, "")], 35, 8, "swarm_check")
wave_tres("wave_c01_05", "level_c01", 5, "M2：混合压力", [(W, 10, 1.0, 0.0, ""), (S, 10, 0.6, 3.0, "")], 45, 12, "coverage_check")
wave_tres("wave_c01_06", "level_c01", 6, "M2：C01 收尾高压", [(W, 16, 0.8, 0.0, ""), (S, 8, 0.5, 4.0, "")], 60, 15, "coverage_check")
# C02 追加 3 波（现有 4 波保留）
wave_tres("wave_c02_05", "level_c02", 5, "M2：迅捷双路检验", [(D, 8, 0.8, 0.0, "route_c02_tideflat"), (W, 8, 1.1, 1.0, "route_c02_main")], 40, 10, "speed_check")
wave_tres("wave_c02_06", "level_c02", 6, "M2：重甲 + 群聚复合", [(A, 3, 1.6, 0.0, "route_c02_main"), (S, 10, 0.6, 2.0, "route_c02_tideflat"), (D, 6, 0.8, 4.0, "route_c02_tideflat")], 50, 12, "armor_check")
wave_tres("wave_c02_07", "level_c02", 7, "M2：C02 收尾", [(A, 5, 1.4, 0.0, "route_c02_main"), (S, 12, 0.5, 1.5, "route_c02_tideflat"), (D, 8, 0.7, 3.0, "route_c02_main")], 70, 16, "armor_check")
# C03 全部 8 波
wave_tres("wave_c03_01", "level_c03", 1, "M2：双路开局低压", [(W, 8, 1.1, 0.0, "route_c03_main")], 30, 8, "economy")
wave_tres("wave_c03_02", "level_c03", 2, "M2：北路群聚", [(S, 10, 0.7, 0.0, "route_c03_north"), (W, 6, 1.1, 2.0, "route_c03_main")], 30, 8, "swarm_check")
wave_tres("wave_c03_03", "level_c03", 3, "M2：暮潮开始，灯塔装置离线（phase_c03_beacon_failure）", [(D, 8, 0.8, 0.0, "route_c03_north"), (W, 6, 1.1, 1.0, "route_c03_main")], 40, 10, "speed_check")
wave_tres("wave_c03_04", "level_c03", 4, "M2：重甲登场", [(A, 3, 1.6, 0.0, "route_c03_main"), (S, 10, 0.6, 2.0, "route_c03_north")], 45, 12, "armor_check")
wave_tres("wave_c03_05", "level_c03", 5, "M2：护盾引入（灯寄生体）", [(L, 2, 2.0, 0.0, "route_c03_main"), (D, 8, 0.7, 1.0, "route_c03_north"), (S, 6, 0.6, 3.0, "route_c03_main")], 45, 12, "shield_check")
wave_tres("wave_c03_06", "level_c03", 6, "M2：支援引入（潮背导航员）", [(N, 1, 1.0, 0.0, "route_c03_main"), (S, 10, 0.6, 1.0, "route_c03_main"), (D, 8, 0.7, 2.0, "route_c03_north")], 50, 12, "support_check")
wave_tres("wave_c03_07", "level_c03", 7, "M2：复合压力", [(A, 4, 1.4, 0.0, "route_c03_main"), (L, 2, 1.8, 1.0, "route_c03_north"), (S, 10, 0.5, 2.0, "route_c03_north")], 55, 14, "armor_check")
wave_tres("wave_c03_08", "level_c03", 8, "M2：C03 收尾高压", [(N, 2, 2.5, 0.0, "route_c03_main"), (A, 5, 1.3, 1.0, "route_c03_main"), (S, 12, 0.5, 2.0, "route_c03_north"), (D, 8, 0.6, 4.0, "route_c03_main")], 80, 20, "finale")


# ---------------------------------------------------------------- 关卡 ×3
def level_tres(level_id, note, name_key, ember, integrity, towers, routes, default_route,
               initial_active, nodes, waves, phase_events, heroes, hero_spawn,
               primary_key, strategy_key, strategy_op, mark_threshold, tutorial_id, devices):
    ext = [("Script", SCRIPT_PATHS["LevelData"], "1")]
    for i, w in enumerate(waves):
        ext.append(("Resource", "res://data/waves/%s.tres" % w, "w%d" % i))
    for i, p in enumerate(phase_events):
        ext.append(("Resource", "res://data/phase_events/%s.tres" % p, "pe%d" % i))
    for i, d in enumerate(devices):
        ext.append(("Resource", "res://data/devices/%s.tres" % d, "dv%d" % i))
    lines = resource_header("LevelData", 1 + len(ext), ext, 0)
    lines.append("[resource]")
    route_ids = "[%s]" % ", ".join('&"%s"' % r for r, _ in routes)
    route_pts = "[%s]" % ", ".join("PackedVector2Array(%s)" % ", ".join(str(c) for pt in pts for c in pt) for _, pts in routes)
    node_list = "[%s]" % ", ".join("Vector2(%d, %d)" % n for n in nodes)
    props = [
        ("script", 'ExtResource("1")'), ("id", '&"%s"' % level_id), ("schema_version", 1),
        ("enabled", True), ("designer_note", '"%s"' % note),
        ("display_name_key", '&"%s"' % name_key), ("map_size_cells", "Vector2i(20, 11)"),
        ("initial_ember", ember), ("initial_fleet_integrity", integrity),
        ("allowed_towers", "[%s]" % ", ".join('&"%s"' % t for t in towers)),
        ("route_ids", route_ids), ("route_points", route_pts),
        ("default_active_route", '&"%s"' % default_route),
    ]
    if initial_active:
        props.append(("initial_active_routes", "[%s]" % ", ".join('&"%s"' % r for r in initial_active)))
    props += [
        ("build_node_positions", node_list),
        ("waves", "[%s]" % ", ".join('ExtResource("w%d")' % i for i in range(len(waves)))),
    ]
    if phase_events:
        props.append(("phase_events", "[%s]" % ", ".join('ExtResource("pe%d")' % i for i in range(len(phase_events)))))
    props.append(("allowed_heroes", "[%s]" % ", ".join('&"%s"' % h for h in heroes)))
    if heroes:
        props.append(("hero_spawn", "Vector2(%d, %d)" % hero_spawn))
    props += [
        ("primary_objective_key", '&"%s"' % primary_key),
        ("strategy_objective_key", '&"%s"' % strategy_key),
        ("strategy_objective_op", '&"%s"' % strategy_op),
        ("integrity_mark_threshold", mark_threshold),
        ("tutorial_id", '&"%s"' % tutorial_id),
    ]
    if devices:
        props.append(("devices", "[%s]" % ", ".join('ExtResource("dv%d")' % i for i in range(len(devices)))))
    emit_block(lines, props)
    write("data/levels/%s.tres" % level_id, "\n".join(lines) + "\n")


C01_ROUTE_MAIN = [(0, 192), (320, 192), (320, 320), (640, 320)]
C01_ROUTE_TIDE = [(0, 192), (480, 192), (480, 80), (640, 80)]
level_tres("level_c01",
    "M2 纵向切片：C01「离港火线」——单路 / 8 BuildNode / 固定明潮 / 教学：建造、范围、开波、升级、暂停（PRD §5.3/§11.2）",
    "LEVEL_C01", 400, 20, ["tower_needle_rail"],
    [("route_c01_main", C01_ROUTE_MAIN), ("route_c01_tideflat", C01_ROUTE_TIDE)],
    "route_c01_main", [],
    [(160, 112), (352, 112), (512, 144), (96, 256), (256, 256), (416, 256), (544, 224), (64, 320)],
    ["wave_c01_01", "wave_c01_02", "wave_c01_03", "wave_c01_04", "wave_c01_05", "wave_c01_06"],
    [], [], (0, 0), "OBJ_PRIMARY_SURVIVE", "OBJ_C01_STRATEGY", "upgrade_any_tower", 15, "tutorial_c01", [])

level_tres("level_c02",
    "M2 纵向切片：C02「潮门初启」——单路变双路 / 预告式改道相位模板 / 迅捷敌（PRD §5.3）；英雄按蓝图自 C03 起登场",
    "LEVEL_C02", 450, 20, ["tower_needle_rail", "tower_ember_well"],
    [("route_c02_main", C01_ROUTE_MAIN), ("route_c02_tideflat", C01_ROUTE_TIDE)],
    "route_c02_main", [],
    [(160, 112), (352, 112), (512, 144), (96, 256), (256, 256), (416, 256), (544, 224), (64, 320), (224, 144), (384, 240)],
    ["wave_c02_01", "wave_c02_02", "wave_c02_03", "wave_c02_04", "wave_c02_05", "wave_c02_06", "wave_c02_07"],
    ["phase_c02_tidegate"], [], (0, 0), "OBJ_PRIMARY_SURVIVE", "OBJ_C02_STRATEGY", "use_tide_clock", 14, "tutorial_c02", [])

C03_ROUTE_MAIN = [(0, 256), (352, 256), (352, 160), (640, 160)]
C03_ROUTE_NORTH = [(0, 96), (448, 96), (448, 288), (640, 288)]
level_tres("level_c03",
    "M2 纵向切片：C03「失火灯塔」——双路 / 12 BuildNode / 首英雄岚舟·苇 / 相位模板 2：暮潮装置失效、英雄修复（PRD §5.3）",
    "LEVEL_C03", 550, 20, ["tower_needle_rail", "tower_ember_well", "tower_echo_pile"],
    [("route_c03_main", C03_ROUTE_MAIN), ("route_c03_north", C03_ROUTE_NORTH)],
    "route_c03_main", ["route_c03_main", "route_c03_north"],
    [(64, 192), (128, 320), (160, 128), (224, 224), (256, 64), (320, 320), (384, 64), (416, 192), (480, 224), (496, 64), (544, 192), (544, 320)],
    ["wave_c03_01", "wave_c03_02", "wave_c03_03", "wave_c03_04", "wave_c03_05", "wave_c03_06", "wave_c03_07", "wave_c03_08"],
    ["phase_c03_beacon_failure"], ["hero_lanzhou_wei"], (320, 304),
    "OBJ_PRIMARY_SURVIVE", "OBJ_C03_STRATEGY", "repair_device", 12, "tutorial_c03", ["device_c03_lighthouse"])

print("M2 Phase A data generation done.")
