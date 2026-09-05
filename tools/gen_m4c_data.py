#!/usr/bin/env python3
"""M4-C：C09–C12（第二章首批）数据生成器。
确定性、幂等：全量覆盖同名 .tres；i18n 行按键去重追加。
生成：3 新敌人 + 6 装置 + 5 相位事件 + 48 波次 + 4 关卡。
几何自检：路线端点贴边界、BuildNode 距任意路线 >= 24px（对齐 tools/validate_data.gd）。
"""
import csv, os, sys, math

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAP_W, MAP_H = 640.0, 360.0
MIN_NODE_ROUTE_DIST = 24.0


def write(rel, text):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("wrote", rel)


def fmt_val(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, str):
        return v  # 已带 &"x" / Vector2(...) 字面
    raise TypeError(type(v))


def header(script_class, load_steps, ext_resources):
    lines = ['[gd_resource type="Resource" script_class="%s" load_steps=%d format=3]' % (script_class, load_steps), ""]
    for rtype, path, rid in ext_resources:
        lines.append('[ext_resource type="%s" path="%s" id="%s"]' % (rtype, path, rid))
    lines.append("")
    return lines


def emit(lines, props):
    for k, v in props:
        lines.append("%s = %s" % (k, fmt_val(v)))
    return lines


def v2(p):
    return "Vector2(%s, %s)" % (p[0], p[1])


def color(c):
    return "Color(%.2f, %.2f, %.2f, 1.00)" % c


def sname(s):
    return '&"%s"' % s


def sarr(items):
    return "[" + ", ".join(sname(i) for i in items) + "]"


def v2arr(points):
    return "[" + ", ".join(v2(p) for p in points) + "]"


def packed_v2(points):
    flat = []
    for p in points:
        flat += [str(p[0]), str(p[1])]
    return "PackedVector2Array(%s)" % ", ".join(flat)


# ---------------------------------------------------------------------------
# 几何自检
# ---------------------------------------------------------------------------

def seg_dist(p, a, b):
    ax, ay = a; bx, by = b; px, py = p
    dx, dy = bx - ax, by - ay
    if dx == 0 and dy == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def check_level_geo(level_id, routes, nodes):
    for rid, pts in routes:
        sx, sy = pts[0]; ex, ey = pts[-1]
        for (x, y, tag) in [(sx, sy, "入口"), (ex, ey, "出口")]:
            assert x in (0.0, MAP_W) or y in (0.0, MAP_H) or x == 0 or x == MAP_W or y == 0 or y == MAP_H, \
                "%s %s %s 未贴边界: %s" % (level_id, rid, tag, (x, y))
    for n in nodes:
        for rid, pts in routes:
            for i in range(len(pts) - 1):
                d = seg_dist(n, pts[i], pts[i + 1])
                assert d >= MIN_NODE_ROUTE_DIST, \
                    "%s node %s 距路线 %s 仅 %.1fpx" % (level_id, n, rid, d)
    assert 8 <= len(nodes) <= 22, "%s BuildNode 数量越界: %d" % (level_id, len(nodes))


# ---------------------------------------------------------------------------
# .tres 模板
# ---------------------------------------------------------------------------

def enemy_tres(eid, name_key, note, intro, hp, speed, armor, glow, leak, reward,
               radius, tags, body, stealth=False, heal_r=0.0, heal_ps=0.0, swap=False):
    lines = header("EnemyData", 2, [("Script", "res://scripts/data/enemy_data.gd", "1")])
    lines.append("[resource]")
    emit(lines, [
        ("script", 'ExtResource("1")'), ("id", sname(eid)), ("schema_version", 1),
        ("enabled", True), ("designer_note", '"%s"' % note),
        ("introduced_in_level", sname(intro)), ("display_name_key", sname(name_key)),
        ("max_hp", "float('%s')" % hp if False else repr(float(hp))),
        ("speed_px_per_sec", repr(float(speed))), ("armor", repr(float(armor))),
        ("glow_resist", repr(float(glow))), ("leak_damage", leak),
        ("kill_reward_ember", reward), ("radius_px", repr(float(radius))),
        ("tags", sarr(tags)), ("elite", False), ("boss", False),
        ("shield_hp", "0.0"), ("aura_radius", "0.0"), ("aura_speed_mult", "1.0"),
        ("stealthed", stealth),
        ("heal_radius", repr(float(heal_r))), ("heal_per_sec", repr(float(heal_ps))),
        ("phase_resist_swap", swap),
        ("body_color", color(body)),
    ])
    write("data/enemies/%s.tres" % eid, "\n".join(lines) + "\n")


def device_tres(did, name_key, note, pos, radius, op, value, interval,
                phase="both", repairable=True, repair_s=3.0, max_hp=0.0, blocks=False):
    lines = header("DeviceData", 2, [("Script", "res://scripts/data/device_data.gd", "1")])
    lines.append("[resource]")
    emit(lines, [
        ("script", 'ExtResource("1")'), ("id", sname(did)), ("schema_version", 1),
        ("enabled", True), ("designer_note", '"%s"' % note),
        ("display_name_key", sname(name_key)), ("position", v2(pos)),
        ("radius_px", repr(float(radius))), ("effect_op", sname(op)),
        ("effect_value", repr(float(value))), ("interval_seconds", repr(float(interval))),
        ("active_phase", sname(phase)), ("repairable", repairable),
        ("repair_seconds", repr(float(repair_s))),
        ("max_hp", repr(float(max_hp))), ("blocks_projectiles", blocks),
    ])
    write("data/devices/%s.tres" % did, "\n".join(lines) + "\n")


def phase_tres(pid, note, level_id, wave, from_p, to_p, activates):
    lines = header("PhaseEventData", 2, [("Script", "res://scripts/data/phase_event_data.gd", "1")])
    lines.append("[resource]")
    emit(lines, [
        ("script", 'ExtResource("1")'), ("id", sname(pid)), ("schema_version", 1),
        ("enabled", True), ("designer_note", '"%s"' % note), ("level_id", sname(level_id)),
        ("starts_at_wave", wave), ("from_phase", sname(from_p)), ("to_phase", sname(to_p)),
        ("activates_routes", sarr(activates)), ("deactivates_routes", "[]"),
        ("environment_changes", "[]"), ("warning_seconds", "20.0"),
        ("player_interruptible", True), ("becon_cost", 40),
    ])
    write("data/phase_events/%s.tres" % pid, "\n".join(lines) + "\n")


def wave_tres(wid, level_id, index, note, groups, reward_e, reward_b, intent):
    ext = [("Script", "res://scripts/data/wave_data.gd", "1"),
           ("Script", "res://scripts/data/wave_group.gd", "2")]
    lines = header("WaveData", 2 + len(groups), ext)
    for i, (eid, count, interval, delay, route) in enumerate(groups):
        lines.append('[sub_resource type="Resource" id="WaveGroup_%d"]' % i)
        emit(lines, [
            ("script", 'ExtResource("2")'), ("enemy_id", sname(eid)),
            ("count", count), ("interval_seconds", repr(float(interval))),
            ("entrance_index", 0), ("delay_after_prev_seconds", repr(float(delay))),
            ("route_id", sname(route)),
        ])
        lines.append("")
    lines.append("[resource]")
    emit(lines, [
        ("script", 'ExtResource("1")'), ("id", sname(wid)), ("schema_version", 1),
        ("enabled", True), ("designer_note", '"%s"' % note),
        ("introduced_in_level", sname(level_id)), ("wave_index", index),
        ("pre_delay_seconds", repr(5.0 if index <= 2 else 8.0)),
        ("groups", "[" + ", ".join('SubResource("WaveGroup_%d")' % i for i in range(len(groups))) + "]"),
        ("completion_reward_ember", reward_e), ("completion_reward_becon", reward_b),
        ("intent", sname(intent)),
    ])
    write("data/waves/%s.tres" % wid, "\n".join(lines) + "\n")


def level_tres(level_id, name_key, note, ember, towers, routes, default_route,
               initial_active, nodes, wave_ids, phase_ids, heroes, hero_spawn,
               obj_key, obj_op, threshold, chapter, tags, device_ids=()):
    check_level_geo(level_id, routes, nodes)
    ext = [("Script", "res://scripts/data/level_data.gd", "1")]
    for i, w in enumerate(wave_ids):
        ext.append(("Resource", "res://data/waves/%s.tres" % w, "w%d" % i))
    for i, p in enumerate(phase_ids):
        ext.append(("Resource", "res://data/phase_events/%s.tres" % p, "pe%d" % i))
    for i, d in enumerate(device_ids):
        ext.append(("Resource", "res://data/devices/%s.tres" % d, "dv%d" % i))
    lines = header("LevelData", 1 + len(ext), ext)
    lines.append("[resource]")
    route_ids = [r[0] for r in routes]
    emit(lines, [
        ("script", 'ExtResource("1")'), ("id", sname(level_id)), ("schema_version", 1),
        ("enabled", True), ("designer_note", '"%s"' % note),
        ("display_name_key", sname(name_key)), ("map_size_cells", "Vector2i(20, 11)"),
        ("initial_ember", ember), ("initial_fleet_integrity", 20),
        ("allowed_towers", sarr(towers)),
        ("route_ids", sarr(route_ids)),
        ("route_points", "[" + ", ".join(packed_v2(pts) for _, pts in routes) + "]"),
        ("default_active_route", sname(default_route)),
        ("initial_active_routes", sarr(initial_active)),
        ("build_node_positions", v2arr(nodes)),
        ("waves", "[" + ", ".join('ExtResource("w%d")' % i for i in range(len(wave_ids))) + "]"),
        ("phase_events", "[" + ", ".join('ExtResource("pe%d")' % i for i in range(len(phase_ids))) + "]"),
        ("allowed_heroes", sarr(heroes)), ("hero_spawn", v2(hero_spawn)),
        ("primary_objective_key", sname("OBJ_PRIMARY_SURVIVE")),
        ("strategy_objective_key", sname(obj_key)), ("strategy_objective_op", sname(obj_op)),
        ("integrity_mark_threshold", threshold), ("tutorial_id", sname("")),
        ("chapter_index", chapter), ("target_tags", sarr(tags)),
    ])
    if device_ids:
        emit(lines, [("devices", "[" + ", ".join('ExtResource("dv%d")' % i for i in range(len(device_ids))) + "]")])
    write("data/levels/%s.tres" % level_id, "\n".join(lines) + "\n")


# ---------------------------------------------------------------------------
# i18n
# ---------------------------------------------------------------------------

I18N_ROWS = [
    ("LEVEL_C09", "C09 玻璃芦径", "C09 Glassreed Passage"),
    ("LEVEL_C10", "C10 孢光洼地", "C10 Sporeglow Hollow"),
    ("LEVEL_C11", "C11 倒映之路", "C11 Mirrorwake Path"),
    ("LEVEL_C12", "C12 沉船温室", "C12 Sunken Greenhouse"),
    ("OBJ_C09_STRATEGY", "在 C09 内完成一次塔升级", "Complete a tower upgrade in C09"),
    ("OBJ_C10_STRATEGY", "在 C10 内使用一次潮汐仪", "Use the tide clock once in C10"),
    ("OBJ_C11_STRATEGY", "在 C11 相位切换前后使用潮汐仪", "Use the tide clock around the phase shifts in C11"),
    ("OBJ_C12_STRATEGY", "在 C12 内完成一次塔升级", "Complete a tower upgrade in C12"),
    ("ENEMY_REED_STALKER", "芦丛潜行者", "Reed Stalker"),
    ("ENEMY_SPORE_MENDER", "孢光医者", "Spore Mender"),
    ("ENEMY_MIRROR_SHADE", "倒映影魅", "Mirror Shade"),
    ("DEVICE_C09_GLASS_LENS", "玻璃棱镜", "Glass Lens"),
    ("DEVICE_C10_SPORE_ZONE", "孢子扩散区", "Spore Bloom"),
    ("DEVICE_C12_HULL_COVER", "船壳掩体", "Hull Cover"),
]


def append_i18n():
    path = os.path.join(ROOT, "data/i18n/ui.csv")
    with open(path, encoding="utf-8") as f:
        existing = {row.split(",", 1)[0] for row in f if row.strip() and not row.startswith("#")}
    with open(path, "a", encoding="utf-8", newline="\n") as f:
        f.write("# M4-C：C09–C12 关卡/敌人/装置\n")
        for key, zh, en in I18N_ROWS:
            if key in existing:
                continue
            f.write("%s,%s,%s\n" % (key, zh, en))
            print("i18n +", key)


# ---------------------------------------------------------------------------
# 新敌人（第二章首批）
# ---------------------------------------------------------------------------

def gen_enemies():
    # 隐匿（C09）：不可索敌，需侦测揭示；速攻型
    enemy_tres("reed_stalker", "ENEMY_REED_STALKER",
               "M4-C 第二章：C09 隐匿敌——侦测考核（PRD §5.3 玻璃芦径）", "level_c09",
               130.0, 58.0, 0.0, 10.0, 1, 18, 9.0, ["stealth", "swift"],
               (0.35, 0.55, 0.40), stealth=True)
    # 治疗（C10）：孢光医者，治疗光环；沉默可抑制
    enemy_tres("spore_mender", "ENEMY_SPORE_MENDER",
               "M4-C 第二章：C10 治疗敌——集火考核（PRD §5.3 孢光洼地）", "level_c10",
               170.0, 40.0, 5.0, 20.0, 1, 24, 10.0, ["healer"],
               (0.55, 0.85, 0.55), heal_r=84.0, heal_ps=10.0)
    # 双相（C11）：暮潮时物理/辉光抗性互换；明潮 armor=90 glow=10
    enemy_tres("mirror_shade", "ENEMY_MIRROR_SHADE",
               "M4-C 第二章：C11 双相敌——伤害配比考核（PRD §5.3 倒映之路）", "level_c11",
               240.0, 46.0, 90.0, 10.0, 2, 28, 11.0, ["phasebound", "heavy"],
               (0.60, 0.55, 0.85), swap=True)


# ---------------------------------------------------------------------------
# 装置与相位事件
# ---------------------------------------------------------------------------

def gen_devices_phases():
    device_tres("device_c09_glass_lens", "DEVICE_C09_GLASS_LENS",
                "M4-C C09：玻璃棱镜——侦测脉冲，每 3 秒揭示半径内隐匿敌 5 秒",
                (320, 240), 150.0, "reveal_pulse", 5.0, 3.0)
    device_tres("device_c10_spore_zone_a", "DEVICE_C10_SPORE_ZONE",
                "M4-C C10：孢子扩散区 A——敌方治疗场，每 2 秒治疗半径内敌军 7 点",
                (240, 176), 88.0, "spore_heal", 7.0, 2.0, repairable=False)
    device_tres("device_c10_spore_zone_b", "DEVICE_C10_SPORE_ZONE",
                "M4-C C10：孢子扩散区 B——覆盖双路尾段",
                (496, 248), 88.0, "spore_heal", 7.0, 2.0, repairable=False)
    device_tres("device_c12_hull_cover_a", "DEVICE_C12_HULL_COVER",
                "M4-C C12：船壳掩体 A——阻挡投射物，可被火力击破",
                (352, 272), 26.0, "cover", 0.0, 99.0, repairable=False, max_hp=220.0, blocks=True)
    device_tres("device_c12_hull_cover_b", "DEVICE_C12_HULL_COVER",
                "M4-C C12：船壳掩体 B——封锁北侧射界",
                (480, 176), 26.0, "cover", 0.0, 99.0, repairable=False, max_hp=220.0, blocks=True)
    device_tres("device_c12_hull_cover_c", "DEVICE_C12_HULL_COVER",
                "M4-C C12：船壳掩体 C——封锁 A 路前段射界",
                (144, 112), 24.0, "cover", 0.0, 99.0, repairable=False, max_hp=180.0, blocks=True)
    phase_tres("phase_c09_tide_shift", "M4-C C09：暮潮激活交叉支路", "level_c09", 4,
               "mingchao", "muchao", ["route_c09_b"])
    phase_tres("phase_c10_tide_shift", "M4-C C10：预告式昼暮切换", "level_c10", 5,
               "mingchao", "muchao", [])
    phase_tres("phase_c11_tide_shift_a", "M4-C C11：第一次双相切换", "level_c11", 4,
               "mingchao", "muchao", [])
    phase_tres("phase_c11_tide_shift_b", "M4-C C11：第二次双相切换（回明潮）", "level_c11", 9,
               "muchao", "mingchao", [])
    phase_tres("phase_c12_tide_shift", "M4-C C12：暮潮激活汇流支路", "level_c12", 5,
               "mingchao", "muchao", ["route_c12_b"])


# ---------------------------------------------------------------------------
# 波次（每关 12 波；组 = (enemy_id, count, interval, delay_after_prev, route_id)）
# ---------------------------------------------------------------------------

W = "salt_shell_walker"; R = "mast_rat_swarm"; D = "splitfin_dasher"
C = "rust_armor_carrier"; S = "brine_spitter"; N = "tide_back_navigator"
L = "lamp_leech"; G = "tideglass_runner"; P = "reef_sapper"
ST = "reed_stalker"; SM = "spore_mender"; MS = "mirror_shade"

REWARD_E = [28, 30, 32, 35, 37, 40, 42, 45, 47, 50, 52, 55]
REWARD_B = [6, 6, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10]


def gen_waves():
    # C09：walker/rat/dasher + 隐匿 stalker（w3 起）；w4 相位后双路
    c09 = [
        [(W, 6, 0.9, 0.0, "")],
        [(W, 4, 0.9, 0.0, ""), (R, 6, 0.5, 2.0, "")],
        [(W, 5, 0.8, 0.0, ""), (ST, 2, 1.2, 2.0, "")],
        [(R, 8, 0.5, 0.0, ""), (ST, 3, 1.0, 1.5, "route_c09_b")],
        [(D, 5, 0.6, 0.0, ""), (W, 5, 0.8, 2.0, "route_c09_b")],
        [(ST, 4, 0.9, 0.0, ""), (W, 6, 0.8, 2.0, "route_c09_b")],
        [(R, 10, 0.45, 0.0, ""), (D, 4, 0.6, 2.0, "route_c09_b")],
        [(ST, 5, 0.8, 0.0, ""), (W, 6, 0.7, 2.0, "route_c09_b")],
        [(D, 8, 0.5, 0.0, ""), (ST, 3, 0.9, 2.0, "route_c09_b")],
        [(W, 8, 0.7, 0.0, ""), (ST, 5, 0.8, 2.0, "route_c09_b")],
        [(R, 12, 0.4, 0.0, ""), (ST, 4, 0.8, 1.5, "route_c09_b"), (D, 4, 0.5, 3.0, "")],
        [(W, 10, 0.6, 0.0, ""), (ST, 6, 0.7, 2.0, "route_c09_b"), (D, 6, 0.5, 4.0, "")],
    ]
    # C10：walker/spitter/carrier + 医者 mender（w3 起）+ navigator 支援；双路常驻
    c10 = [
        [(W, 6, 0.9, 0.0, "")],
        [(W, 4, 0.8, 0.0, ""), (S, 3, 1.0, 2.0, "route_c10_south")],
        [(W, 5, 0.8, 0.0, ""), (SM, 1, 0.5, 2.0, "route_c10_south")],
        [(C, 3, 1.2, 0.0, ""), (W, 6, 0.7, 2.0, "route_c10_south")],
        [(S, 5, 0.8, 0.0, ""), (SM, 2, 1.0, 2.0, "route_c10_south")],
        [(W, 8, 0.6, 0.0, ""), (C, 3, 1.1, 2.0, "route_c10_south"), (SM, 1, 0.5, 3.5, "")],
        [(N, 1, 0.5, 0.0, ""), (W, 8, 0.6, 1.0, ""), (S, 4, 0.8, 2.5, "route_c10_south")],
        [(SM, 2, 0.8, 0.0, ""), (C, 4, 1.0, 1.5, ""), (W, 6, 0.6, 3.0, "route_c10_south")],
        [(S, 6, 0.7, 0.0, "route_c10_south"), (SM, 2, 0.8, 2.0, ""), (W, 6, 0.6, 3.0, "")],
        [(C, 5, 0.9, 0.0, ""), (N, 1, 0.5, 1.0, "route_c10_south"), (S, 5, 0.7, 2.5, "route_c10_south")],
        [(W, 10, 0.5, 0.0, ""), (SM, 3, 0.8, 2.0, "route_c10_south"), (C, 4, 0.9, 4.0, "")],
        [(C, 6, 0.8, 0.0, ""), (SM, 2, 0.7, 1.5, ""), (S, 6, 0.6, 3.0, "route_c10_south"), (W, 6, 0.5, 4.5, "")],
    ]
    # C11：runner/leech/carrier + 双相 shade（w3 起）；镜像双路常驻
    c11 = [
        [(G, 5, 0.8, 0.0, "")],
        [(G, 4, 0.7, 0.0, ""), (W, 4, 0.8, 2.0, "route_c11_bot")],
        [(G, 5, 0.7, 0.0, ""), (MS, 1, 0.5, 2.0, "route_c11_bot")],
        [(L, 4, 0.9, 0.0, ""), (G, 6, 0.6, 2.0, "route_c11_bot")],
        [(MS, 2, 1.0, 0.0, ""), (W, 6, 0.7, 2.0, "route_c11_bot")],
        [(C, 3, 1.1, 0.0, "route_c11_bot"), (G, 7, 0.6, 2.0, "")],
        [(L, 5, 0.8, 0.0, "route_c11_bot"), (MS, 2, 0.9, 2.0, "")],
        [(G, 8, 0.5, 0.0, ""), (C, 3, 1.0, 2.0, "route_c11_bot"), (MS, 1, 0.5, 3.5, "")],
        [(MS, 3, 0.8, 0.0, "route_c11_bot"), (L, 4, 0.8, 2.0, ""), (G, 6, 0.5, 3.0, "")],
        [(C, 5, 0.9, 0.0, ""), (MS, 2, 0.8, 2.0, "route_c11_bot"), (G, 6, 0.5, 3.5, "route_c11_bot")],
        [(L, 6, 0.7, 0.0, ""), (MS, 3, 0.7, 2.0, ""), (C, 3, 0.9, 3.5, "route_c11_bot")],
        [(MS, 4, 0.7, 0.0, ""), (C, 4, 0.8, 1.5, "route_c11_bot"), (L, 5, 0.7, 3.0, ""), (G, 6, 0.5, 4.5, "route_c11_bot")],
    ]
    # C12：sapper/carrier/navigator/walker/spitter；无新敌，掩体射界考核；w5 相位后汇流
    c12 = [
        [(W, 6, 0.9, 0.0, "")],
        [(P, 3, 1.0, 0.0, ""), (W, 4, 0.8, 2.0, "")],
        [(S, 4, 0.9, 0.0, ""), (W, 5, 0.7, 2.0, "")],
        [(C, 3, 1.1, 0.0, ""), (P, 3, 0.9, 2.0, "")],
        [(W, 6, 0.7, 0.0, ""), (S, 4, 0.8, 1.5, "route_c12_b")],
        [(N, 1, 0.5, 0.0, ""), (C, 4, 1.0, 1.0, ""), (W, 5, 0.7, 3.0, "route_c12_b")],
        [(P, 5, 0.8, 0.0, "route_c12_b"), (S, 4, 0.8, 2.0, "")],
        [(C, 5, 0.9, 0.0, ""), (W, 6, 0.6, 2.0, "route_c12_b"), (N, 1, 0.5, 3.5, "route_c12_b")],
        [(S, 6, 0.7, 0.0, ""), (P, 4, 0.8, 2.0, "route_c12_b"), (C, 3, 0.9, 3.5, "")],
        [(W, 9, 0.6, 0.0, "route_c12_b"), (C, 4, 0.9, 2.0, ""), (S, 4, 0.7, 3.5, "")],
        [(N, 1, 0.5, 0.0, ""), (P, 6, 0.7, 1.0, "route_c12_b"), (C, 5, 0.8, 3.0, "")],
        [(C, 6, 0.8, 0.0, ""), (S, 6, 0.6, 2.0, "route_c12_b"), (P, 5, 0.7, 4.0, ""), (W, 6, 0.5, 5.5, "route_c12_b")],
    ]
    for lvl, table in [("c09", c09), ("c10", c10), ("c11", c11), ("c12", c12)]:
        for i, groups in enumerate(table):
            wave_tres("wave_%s_%02d" % (lvl, i + 1), "level_%s" % lvl, i + 1,
                      "M4-C %s 波次 %02d" % (lvl.upper(), i + 1), groups,
                      REWARD_E[i], REWARD_B[i],
                      "economy" if i < 2 else ("finale" if i == 11 else "coverage"))


# ---------------------------------------------------------------------------
# 关卡
# ---------------------------------------------------------------------------

HEROES = ["hero_lanzhou_wei", "hero_zhushou_muen"]


def gen_levels():
    # C09 玻璃芦径：交叉路 / 15 节点 / 隐匿 + 侦测棱镜
    level_tres("level_c09", "LEVEL_C09",
               "M4-C 第二章：C09「玻璃芦径」——交叉路 + 视野草丛隐匿 + 侦测棱镜（PRD §5.3）",
               900, ["tower_needle_rail", "tower_ember_well", "tower_echo_pile", "tower_wind_nest"],
               [("route_c09_a", [(0, 176), (640, 176)]),
                ("route_c09_b", [(0, 304), (320, 304), (320, 48), (640, 48)])],
               "route_c09_a", ["route_c09_a"],
               [(64, 88), (160, 88), (240, 88), (400, 88), (480, 88), (560, 88),
                (96, 136), (224, 136), (416, 136), (544, 136),
                (64, 224), (416, 224), (544, 224), (64, 336), (200, 336)],
               ["wave_c09_%02d" % i for i in range(1, 13)],
               ["phase_c09_tide_shift"], HEROES, (480, 240),
               "OBJ_C09_STRATEGY", "upgrade_any_tower", 12, 2,
               ["stealth", "swift", "swarm"], device_ids=["device_c09_glass_lens"])
    # C10 孢光洼地：双路 / 16 节点 / 孢子扩散区 + 治疗敌
    level_tres("level_c10", "LEVEL_C10",
               "M4-C 第二章：C10「孢光洼地」——双路 + 孢子扩散区（敌方治疗场）+ 治疗敌（PRD §5.3）",
               950, ["tower_needle_rail", "tower_ember_well", "tower_echo_pile", "tower_wind_nest", "tower_prism_grove"],
               [("route_c10_north", [(0, 96), (448, 96), (448, 176), (640, 176)]),
                ("route_c10_south", [(0, 272), (320, 272), (320, 320), (640, 320)])],
               "route_c10_north", ["route_c10_north", "route_c10_south"],
               [(64, 40), (192, 40), (320, 40), (448, 40), (576, 40),
                (96, 144), (224, 144), (352, 144), (544, 144), (624, 144),
                (64, 224), (160, 224), (256, 224), (400, 224),
                (88, 336), (216, 336)],
               ["wave_c10_%02d" % i for i in range(1, 13)],
               ["phase_c10_tide_shift"], HEROES, (320, 136),
               "OBJ_C10_STRATEGY", "use_tide_clock", 12, 2,
               ["healer", "support", "armor"],
               device_ids=["device_c10_spore_zone_a", "device_c10_spore_zone_b"])
    # C11 倒映之路：镜像双路 / 16 节点 / 双相抗性互换 + 铸潮砧塔
    level_tres("level_c11", "LEVEL_C11",
               "M4-C 第二章：C11「倒映之路」——镜像双路 + 双相敌抗性互换 + 铸潮砧塔（PRD §5.3）",
               1000, ["tower_needle_rail", "tower_ember_well", "tower_echo_pile", "tower_wind_nest", "tower_tide_anvil", "tower_prism_grove"],
               [("route_c11_top", [(0, 72), (256, 72), (256, 200), (640, 200)]),
                ("route_c11_bot", [(0, 288), (384, 288), (384, 160), (640, 160)])],
               "route_c11_top", ["route_c11_top", "route_c11_bot"],
               [(96, 24), (448, 24), (576, 24),
                (96, 120), (192, 120), (320, 120), (448, 120), (576, 120),
                (64, 248), (160, 248), (320, 248), (480, 248), (608, 248),
                (128, 336), (288, 336), (512, 336)],
               ["wave_c11_%02d" % i for i in range(1, 13)],
               ["phase_c11_tide_shift_a", "phase_c11_tide_shift_b"], HEROES, (320, 240),
               "OBJ_C11_STRATEGY", "use_tide_clock", 12, 2,
               ["phasebound", "heavy", "shield"])
    # C12 沉船温室：汇流路 / 17 节点 / 可破坏掩体阻挡投射物
    level_tres("level_c12", "LEVEL_C12",
               "M4-C 第二章：C12「沉船温室」——汇流路 + 可破坏船壳掩体阻挡投射物（PRD §5.3）",
               1050, ["tower_needle_rail", "tower_ember_well", "tower_echo_pile", "tower_wind_nest", "tower_tide_anvil", "tower_prism_grove"],
               [("route_c12_a", [(0, 64), (288, 64), (288, 224), (640, 224)]),
                ("route_c12_b", [(0, 320), (416, 320), (416, 224), (640, 224)])],
               "route_c12_a", ["route_c12_a"],
               [(96, 24), (400, 24), (544, 24),
                (64, 120), (160, 120), (352, 120), (448, 120), (544, 120),
                (64, 176), (160, 176), (352, 176), (544, 176),
                (64, 272), (160, 272), (240, 272), (480, 272), (576, 272)],
               ["wave_c12_%02d" % i for i in range(1, 13)],
               ["phase_c12_tide_shift"], HEROES, (320, 272),
               "OBJ_C12_STRATEGY", "upgrade_any_tower", 12, 2,
               ["heavy", "armor", "support"],
               device_ids=["device_c12_hull_cover_a", "device_c12_hull_cover_b", "device_c12_hull_cover_c"])


def main():
    gen_enemies()
    gen_devices_phases()
    gen_waves()
    gen_levels()
    append_i18n()
    print("M4-C data generation complete")


if __name__ == "__main__":
    main()
