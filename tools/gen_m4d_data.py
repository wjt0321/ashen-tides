#!/usr/bin/env python3
"""M4-D：C13–C14（第二章收口）数据生成器。
确定性、幂等：全量覆盖同名 .tres；i18n 行按键去重追加。
生成：3 新敌人（召唤敌/精英/Boss2）+ 5 装置 + 2 相位事件 + 24 波次 + 2 关卡。
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
            assert x in (0.0, MAP_W) or y in (0.0, MAP_H), \
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
               radius, tags, body, stealth=False, heal_r=0.0, heal_ps=0.0, swap=False,
               elite=False, affixes=(), summon_id="", summon_interval=0.0,
               boss=False, boss_phases=(), shield=0.0):
    lines = header("EnemyData", 2, [("Script", "res://scripts/data/enemy_data.gd", "1")])
    lines.append("[resource]")
    props = [
        ("script", 'ExtResource("1")'), ("id", sname(eid)), ("schema_version", 1),
        ("enabled", True), ("designer_note", '"%s"' % note),
        ("introduced_in_level", sname(intro)), ("display_name_key", sname(name_key)),
        ("max_hp", repr(float(hp))), ("speed_px_per_sec", repr(float(speed))),
        ("armor", repr(float(armor))), ("glow_resist", repr(float(glow))),
        ("leak_damage", leak), ("kill_reward_ember", reward),
        ("radius_px", repr(float(radius))), ("tags", sarr(tags)),
        ("elite", elite), ("boss", boss),
        ("shield_hp", repr(float(shield))), ("aura_radius", "0.0"), ("aura_speed_mult", "1.0"),
        ("stealthed", stealth),
        ("heal_radius", repr(float(heal_r))), ("heal_per_sec", repr(float(heal_ps))),
        ("phase_resist_swap", swap),
        ("body_color", color(body)),
    ]
    if affixes:
        props.append(("elite_affixes", sarr(affixes)))
    if summon_id:
        props.append(("summon_enemy_id", sname(summon_id)))
        props.append(("summon_interval_seconds", repr(float(summon_interval))))
    if boss:
        props.append(("boss_phase_count", len(boss_phases)))
        dicts = []
        for ph in boss_phases:
            dicts.append('{"threshold": %s, "label": "%s", "armor_bonus": %s, "speed_mult": %s, "shield_restore": %s}' % (
                repr(float(ph[0])), ph[1], repr(float(ph[2])), repr(float(ph[3])), repr(float(ph[4]))))
        props.append(("boss_phases", "[" + ", ".join(dicts) + "]"))
    emit(lines, props)
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
               obj_key, obj_op, threshold, chapter, tags, device_ids=(), boss_id=""):
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
    if boss_id:
        emit(lines, [("boss_enemy_id", sname(boss_id))])
    write("data/levels/%s.tres" % level_id, "\n".join(lines) + "\n")


# ---------------------------------------------------------------------------
# i18n
# ---------------------------------------------------------------------------

I18N_ROWS = [
    ("LEVEL_C13", "C13 雾母腹地", "C13 Mistmother Deep"),
    ("LEVEL_C14", "C14 沼冠孢王", "C14 Marsh Crown Spore King"),
    ("OBJ_C13_STRATEGY", "在 C13 内完成一次塔升级", "Complete a tower upgrade in C13"),
    ("OBJ_C14_STRATEGY", "在 C14 内使用一次潮汐仪", "Use the tide clock once in C14"),
    ("ENEMY_SPORE_MOTHER_CARRIER", "雾母载体", "Spore Mother Carrier"),
    ("ENEMY_MARSH_MIST_PHYSICIAN", "雾中医正", "Marsh Mist Physician"),
    ("ENEMY_BOSS_MARSH_CROWN_SPORE_KING", "沼冠孢王", "Marsh Crown Spore King"),
    ("DEVICE_C13_MIST_LENS", "雾透镜", "Mist Lens"),
    ("DEVICE_C14_SPORE_NEST", "孢巢", "Spore Nest"),
]


def append_i18n():
    path = os.path.join(ROOT, "data/i18n/ui.csv")
    with open(path, encoding="utf-8") as f:
        existing = {row.split(",", 1)[0] for row in f if row.strip() and not row.startswith("#")}
    with open(path, "a", encoding="utf-8", newline="\n") as f:
        f.write("# M4-D：C13–C14 关卡/敌人/装置\n")
        for key, zh, en in I18N_ROWS:
            if key in existing:
                continue
            f.write("%s,%s,%s\n" % (key, zh, en))
            print("i18n +", key)


# ---------------------------------------------------------------------------
# 新敌人（第二章收口：召唤敌 / 精英 / Boss 2）
# ---------------------------------------------------------------------------

def gen_enemies():
    # 召唤（C13）：雾母载体——固定 6 秒召唤桅鼠群，击杀本体停止召唤（PRD §8.6）；沉默抑制
    enemy_tres("spore_mother_carrier", "ENEMY_SPORE_MOTHER_CARRIER",
               "M4-D 第二章：C13 召唤敌——本体识别考核（PRD §5.3 雾母腹地 / §8.6）", "level_c13",
               500.0, 30.0, 20.0, 20.0, 2, 40, 14.0, ["summon", "support"],
               (0.55, 0.45, 0.68), summon_id="mast_rat_swarm", summon_interval=6.0)
    # 精英（C14）：雾中医正——再生词缀 + 强化治疗光环（PRD §8.7 #3 最小实现：无留孢区）
    enemy_tres("marsh_mist_physician", "ENEMY_MARSH_MIST_PHYSICIAN",
               "M4-D 第二章：精英「雾中医正」——再生词缀 + 治疗光环（PRD §8.7 #3）", "level_c14",
               600.0, 36.0, 10.0, 30.0, 2, 60, 12.0, ["healer", "support"],
               (0.45, 0.80, 0.65), heal_r=96.0, heal_ps=14.0,
               elite=True, affixes=["regenerating"])
    # Boss 2（C14）：沼冠孢王——孢巢供疗（装置）+ 根系改道（相位开第二路线）+ 短暂暴露核心
    # （phase 1/3 armor_bonus 负值窗口）；禁止长时间无敌回血（PRD §8.8）
    enemy_tres("boss_marsh_crown_spore_king", "ENEMY_BOSS_MARSH_CROWN_SPORE_KING",
               "M4-D 第二章：Boss 2 沼冠孢王——暴露核心爆发窗口考核（PRD §8.8）", "level_c14",
               1200.0, 16.0, 50.0, 30.0, 5, 0, 22.0, ["boss", "heavy"],
               (0.60, 0.35, 0.55), boss=True, shield=100.0,
               boss_phases=[
                   (0.67, "孢冠绽开·核心暴露", -25.0, 1.15, 0.0),
                   (0.34, "根系回拢", 15.0, 0.90, 120.0),
                   (0.0, "孢王暴走·核心暴露", -15.0, 1.40, 0.0),
               ])


# ---------------------------------------------------------------------------
# 装置与相位事件
# ---------------------------------------------------------------------------

def gen_devices_phases():
    # C13 视野脉冲：两座雾透镜（侦测脉冲，同 C09 棱镜机制，最小新机制）
    device_tres("device_c13_mist_lens_a", "DEVICE_C13_MIST_LENS",
                "M4-D C13：雾透镜 A——视野脉冲，每 3 秒揭示半径内隐匿敌 5 秒",
                (208, 160), 150.0, "reveal_pulse", 5.0, 3.0)
    device_tres("device_c13_mist_lens_b", "DEVICE_C13_MIST_LENS",
                "M4-D C13：雾透镜 B——覆盖第三入口路线上段",
                (480, 64), 140.0, "reveal_pulse", 5.0, 3.0)
    # C14 孢巢：供疗 + 阻挡投射物（分火管理考核：打巢=分火，PRD §8.8 孢巢供疗）
    device_tres("device_c14_spore_nest_a", "DEVICE_C14_SPORE_NEST",
                "M4-D C14：孢巢 A——供疗 Boss/敌军并阻挡投射物，可被火力击破",
                (352, 148), 40.0, "spore_heal", 8.0, 2.0, repairable=False, max_hp=260.0, blocks=True)
    device_tres("device_c14_spore_nest_b", "DEVICE_C14_SPORE_NEST",
                "M4-D C14：孢巢 B——扼守汇流口",
                (488, 216), 40.0, "spore_heal", 8.0, 2.0, repairable=False, max_hp=260.0, blocks=True)
    device_tres("device_c14_spore_nest_c", "DEVICE_C14_SPORE_NEST",
                "M4-D C14：孢巢 C——覆盖第二路线前段（根系改道后启用）",
                (96, 296), 40.0, "spore_heal", 8.0, 2.0, repairable=False, max_hp=260.0, blocks=True)
    # C13：暮潮激活第三入口（三入口考核）
    phase_tres("phase_c13_third_gate", "M4-D C13：暮潮激活第三入口", "level_c13", 4,
               "mingchao", "muchao", ["route_c13_c"])
    # C14：根系改道——暮潮激活第二路线（PRD §8.8 Boss 2 机制最小实现）
    phase_tres("phase_c14_root_reroute", "M4-D C14：根系改道激活第二路线", "level_c14", 6,
               "mingchao", "muchao", ["route_c14_b"])


# ---------------------------------------------------------------------------
# 波次（每关 12 波；组 = (enemy_id, count, interval, delay_after_prev, route_id)）
# ---------------------------------------------------------------------------

W = "salt_shell_walker"; R = "mast_rat_swarm"; S = "brine_spitter"
C = "rust_armor_carrier"; N = "tide_back_navigator"; P = "reef_sapper"
ST = "reed_stalker"; SM = "spore_mender"
SMC = "spore_mother_carrier"; MMP = "marsh_mist_physician"
BOSS = "boss_marsh_crown_spore_king"

REWARD_E = [28, 30, 32, 35, 37, 40, 42, 45, 47, 50, 52, 55]
REWARD_B = [6, 6, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10]


def gen_waves():
    # C13 雾母腹地：walker/stalker + 召唤敌 carrier（w3 起）；w4 相位开第三入口
    c13 = [
        [(W, 6, 0.9, 0.0, "")],
        [(W, 4, 0.9, 0.0, ""), (ST, 2, 1.2, 2.0, "route_c13_b")],
        [(SMC, 1, 0.5, 0.0, ""), (W, 4, 0.8, 2.0, "route_c13_b")],
        [(ST, 3, 1.0, 0.0, "route_c13_c"), (W, 6, 0.8, 2.0, "")],
        [(SMC, 1, 0.5, 0.0, "route_c13_b"), (R, 8, 0.5, 2.0, "")],
        [(ST, 4, 0.9, 0.0, "route_c13_c"), (W, 6, 0.7, 2.0, "route_c13_b")],
        [(SMC, 2, 1.5, 0.0, ""), (ST, 3, 0.9, 3.0, "route_c13_c")],
        [(W, 8, 0.6, 0.0, "route_c13_b"), (ST, 4, 0.8, 2.0, "route_c13_c")],
        [(SMC, 1, 0.5, 0.0, "route_c13_c"), (R, 10, 0.45, 2.0, ""), (ST, 3, 0.8, 4.0, "route_c13_b")],
        [(ST, 5, 0.7, 0.0, "route_c13_c"), (W, 8, 0.6, 2.0, ""), (SMC, 1, 0.5, 4.0, "route_c13_b")],
        [(SMC, 2, 1.2, 0.0, ""), (ST, 5, 0.7, 2.0, "route_c13_c"), (W, 8, 0.5, 4.0, "route_c13_b")],
        [(SMC, 2, 1.0, 0.0, "route_c13_b"), (ST, 6, 0.6, 2.0, "route_c13_c"), (W, 10, 0.5, 4.0, "")],
    ]
    # C14 沼冠孢王（Boss 场）：spitter/sapper 开场，carrier w3 起少量递进 + 精英医正；w6 根系改道开第二路线；w12 Boss
    # （v2 调波：w1 即 380hp/70 甲 carrier 开场，任何构筑 w1–4 固定漏 10——开场压力超限，减 carrier 总量与前置波次）
    c14 = [
        [(S, 3, 1.0, 0.0, ""), (P, 3, 1.0, 2.0, "")],
        [(P, 4, 0.9, 0.0, ""), (S, 3, 1.0, 2.0, "")],
        [(C, 2, 1.4, 0.0, ""), (MMP, 1, 0.5, 2.0, "")],
        [(S, 5, 0.8, 0.0, ""), (C, 2, 1.3, 2.0, ""), (N, 1, 0.5, 4.0, "")],
        [(MMP, 1, 0.5, 0.0, ""), (P, 5, 0.8, 2.0, ""), (S, 4, 0.8, 4.0, "")],
        [(C, 3, 1.1, 0.0, "route_c14_b"), (P, 4, 0.8, 2.0, "")],
        [(MMP, 1, 0.5, 0.0, "route_c14_b"), (S, 5, 0.7, 2.0, ""), (C, 3, 1.1, 4.0, "")],
        [(P, 6, 0.7, 0.0, ""), (N, 1, 0.5, 2.0, "route_c14_b"), (C, 3, 1.0, 3.0, "route_c14_b")],
        [(MMP, 2, 1.5, 0.0, ""), (S, 6, 0.6, 2.0, "route_c14_b"), (C, 4, 0.9, 4.0, "")],
        [(C, 4, 0.9, 0.0, "route_c14_b"), (P, 5, 0.7, 2.0, ""), (MMP, 1, 0.5, 4.0, "")],
        [(S, 6, 0.6, 0.0, ""), (MMP, 2, 1.2, 2.0, "route_c14_b"), (C, 4, 0.9, 4.0, "")],
        [(BOSS, 1, 0.5, 0.0, ""), (MMP, 1, 0.5, 6.0, "route_c14_b"), (C, 3, 1.1, 8.0, "")],
    ]
    for lvl, table in [("c13", c13), ("c14", c14)]:
        for i, groups in enumerate(table):
            wave_tres("wave_%s_%02d" % (lvl, i + 1), "level_%s" % lvl, i + 1,
                      "M4-D %s 波次 %02d" % (lvl.upper(), i + 1), groups,
                      REWARD_E[i], REWARD_B[i],
                      "economy" if i < 2 else ("finale" if i == 11 else "coverage"))


# ---------------------------------------------------------------------------
# 关卡
# ---------------------------------------------------------------------------

HEROES = ["hero_lanzhou_wei", "hero_zhushou_muen"]


def gen_levels():
    # C13 雾母腹地：三入口 / 18 节点 / 视野脉冲（雾透镜）+ 召唤敌 + 隐匿敌
    level_tres("level_c13", "LEVEL_C13",
               "M4-D 第二章：C13「雾母腹地」——三入口 + 视野脉冲 + 召唤敌（本体识别考核，PRD §5.3）",
               1000, ["tower_needle_rail", "tower_ember_well", "tower_echo_pile", "tower_wind_nest", "tower_prism_grove"],
               [("route_c13_a", [(0, 120), (288, 120), (288, 208), (640, 208)]),
                ("route_c13_b", [(0, 312), (416, 312), (416, 240), (640, 240)]),
                ("route_c13_c", [(0, 32), (512, 32), (512, 96), (640, 96)])],
               "route_c13_a", ["route_c13_a", "route_c13_b"],
               [(64, 72), (160, 72), (256, 72), (352, 72), (448, 72),
                (64, 168), (160, 168), (240, 168), (336, 168), (432, 168),
                (608, 168), (64, 264), (160, 264), (256, 264), (360, 264),
                (544, 264), (96, 344), (520, 344)],
               ["wave_c13_%02d" % i for i in range(1, 13)],
               ["phase_c13_third_gate"], HEROES, (320, 160),
               "OBJ_C13_STRATEGY", "upgrade_any_tower", 12, 2,
               ["summon", "stealth", "support"],
               device_ids=["device_c13_mist_lens_a", "device_c13_mist_lens_b"])
    # C14 沼冠孢王（Boss 场）：双路线 / 16 节点 / 孢巢供疗+阻挡（分火管理）+ Boss 2
    level_tres("level_c14", "LEVEL_C14",
               "M4-D 第二章：C14「沼冠孢王」——Boss 场 + 孢巢分火 + 根系改道（分火管理考核，PRD §5.3/§8.8）",
               1100, ["tower_needle_rail", "tower_ember_well", "tower_echo_pile", "tower_wind_nest", "tower_tide_anvil", "tower_prism_grove"],
               [("route_c14_a", [(0, 88), (352, 88), (352, 184), (640, 184)]),
                ("route_c14_b", [(0, 320), (288, 320), (288, 248), (640, 248)])],
               "route_c14_a", ["route_c14_a"],
               [(64, 40), (192, 40), (320, 40), (448, 40), (576, 40),
                (64, 136), (160, 136), (256, 136), (448, 136), (544, 136),
                (64, 280), (160, 280), (416, 280), (544, 280),
                (96, 346), (224, 346)],
               ["wave_c14_%02d" % i for i in range(1, 13)],
               ["phase_c14_root_reroute"], HEROES, (240, 200),
               "OBJ_C14_STRATEGY", "use_tide_clock", 12, 2,
               ["boss", "healer", "heavy", "armor"],
               device_ids=["device_c14_spore_nest_a", "device_c14_spore_nest_b", "device_c14_spore_nest_c"],
               boss_id=BOSS)


def main():
    gen_enemies()
    gen_devices_phases()
    gen_waves()
    gen_levels()
    append_i18n()
    print("M4-D data generation complete")


if __name__ == "__main__":
    main()
