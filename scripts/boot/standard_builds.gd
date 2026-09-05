class_name StandardBuilds
extends RefCounted
## 标准模式构筑库（NEXT_PHASE P0）：每关 3 套不同思路，**不使用 simulation_assist**。
## - steady：稳健 —— 双路线均衡覆盖，先广度后升级
## - economy：经济 —— 少塔多升级，攒火种吃波次奖励
## - synergy：相位/英雄协同 —— 围绕相位改道与英雄技能窗口布防（回声链/模块优先）
## 格式同 main.SMOKE_PLANS：[[BuildNode 索引, 塔 id], ...]，[&"upgrade", 节点索引, 模块序号] 升级并选模块
## （模块序号 -1 = 不选模块直接升）。节点索引按 LevelData.build_node_positions 顺序。
## 约束：固定 BuildNode + PathNetwork，不自由堵路（PRD §5.4）。

const STEADY := &"steady"
const ECONOMY := &"economy"
const SYNERGY := &"synergy"
const NAMES: Array[StringName] = [STEADY, ECONOMY, SYNERGY]

const BUILDS: Dictionary = {
	&"level_c01": {
		STEADY: [
			[0, &"tower_needle_rail"], [3, &"tower_needle_rail"], [4, &"tower_needle_rail"],
			[5, &"tower_needle_rail"], [&"upgrade", 0, 0], [6, &"tower_needle_rail"],
			[&"upgrade", 3, 2], [7, &"tower_needle_rail"], [&"upgrade", 4, 0],
		],
		ECONOMY: [
			[0, &"tower_needle_rail"], [4, &"tower_needle_rail"], [&"upgrade", 0, 0],
			[3, &"tower_needle_rail"], [&"upgrade", 4, 0], [&"upgrade", 0, -1],
			[5, &"tower_needle_rail"], [&"upgrade", 3, 2],
		],
		SYNERGY: [
			[0, &"tower_needle_rail"], [3, &"tower_needle_rail"], [4, &"tower_needle_rail"],
			[&"upgrade", 0, 1], [5, &"tower_needle_rail"], [&"upgrade", 3, 0],
			[6, &"tower_needle_rail"], [&"upgrade", 4, 2],
		],
	},
	# C04「白盐岬」：双路线全程激活。要点——短路竖段 x=320 与长路底段 y=288 是覆盖重心。
	&"level_c04": {
		STEADY: [
			[2, &"tower_wind_nest"], [8, &"tower_needle_rail"], [6, &"tower_needle_rail"],
			[9, &"tower_needle_rail"], [1, &"tower_needle_rail"], [&"upgrade", 2, 0],
			[11, &"tower_ember_well"], [5, &"tower_needle_rail"], [&"upgrade", 6, 1],
			[4, &"tower_needle_rail"], [&"upgrade", 8, 1], [10, &"tower_ember_well"],
			[&"upgrade", 9, 2], [0, &"tower_needle_rail"], [&"upgrade", 11, 0],
		],
		ECONOMY: [
			[2, &"tower_wind_nest"], [6, &"tower_needle_rail"], [&"upgrade", 2, 0],
			[9, &"tower_needle_rail"], [&"upgrade", 6, 1], [&"upgrade", 2, -1],
			[8, &"tower_needle_rail"], [&"upgrade", 9, 1], [11, &"tower_ember_well"],
			[&"upgrade", 2, -1], [&"upgrade", 6, -1], [&"upgrade", 11, 0],
		],
		SYNERGY: [ # 相位/英雄协同：风巢长程跨双路 + 喷井集火模块 + 削甲；相位改道后覆盖不断档
			[2, &"tower_wind_nest"], [8, &"tower_needle_rail"], [6, &"tower_needle_rail"],
			[9, &"tower_ember_well"], [&"upgrade", 9, 1], [1, &"tower_needle_rail"],
			[&"upgrade", 2, 2], [5, &"tower_needle_rail"], [11, &"tower_ember_well"],
			[&"upgrade", 6, 1], [4, &"tower_needle_rail"], [&"upgrade", 9, -1],
			[0, &"tower_needle_rail"], [&"upgrade", 11, 1],
		],
	},
	# C07「潮脊断桥」：1–5 波只有上路，第 6 波相位开下路——必须在第 6 波前预置下路覆盖。
	&"level_c07": {
		STEADY: [
			[1, &"tower_needle_rail"], [2, &"tower_needle_rail"], [10, &"tower_ember_well"],
			[3, &"tower_needle_rail"], [&"upgrade", 2, 2], [12, &"tower_needle_rail"],
			[7, &"tower_needle_rail"], [6, &"tower_needle_rail"], [11, &"tower_ember_well"],
			[8, &"tower_needle_rail"], [&"upgrade", 1, 1], [&"upgrade", 7, 2],
			[13, &"tower_needle_rail"], [9, &"tower_needle_rail"], [&"upgrade", 11, 0],
		],
		ECONOMY: [
			[10, &"tower_needle_rail"], [&"upgrade", 10, 1], [2, &"tower_needle_rail"],
			[&"upgrade", 10, -1], [&"upgrade", 2, 2], [1, &"tower_needle_rail"],
			[7, &"tower_needle_rail"], [&"upgrade", 10, -1], [11, &"tower_ember_well"],
			[&"upgrade", 7, 1], [6, &"tower_needle_rail"], [&"upgrade", 2, -1],
			[8, &"tower_needle_rail"], [&"upgrade", 11, 0],
		],
		SYNERGY: [ # v4 相位协同：下路第 6 波前预置 7/11 号位；削甲+集火针对重甲；砍掉 0 杀后期散塔，火种集中升级
			[1, &"tower_needle_rail"], [10, &"tower_ember_well"], [2, &"tower_wind_nest"],
			[&"upgrade", 10, 1], [7, &"tower_needle_rail"], [11, &"tower_ember_well"],
			[&"upgrade", 7, 1], [&"upgrade", 2, 1], [&"upgrade", 11, 1],
			[12, &"tower_needle_rail"], [&"upgrade", 1, 1], [13, &"tower_tide_anvil"],
			[&"upgrade", 12, 1], [&"upgrade", 13, 0],
		],
	},
	# C02「潮门初启」：默认 A 路（y192→x320↓y320），相位开 B 路（x480↑y80）。只有弩台/喷井。
	&"level_c02": {
		STEADY: [
			[0, &"tower_needle_rail"], [4, &"tower_ember_well"], [2, &"tower_needle_rail"],
			[8, &"tower_needle_rail"], [6, &"tower_ember_well"], [&"upgrade", 4, 0],
			[3, &"tower_needle_rail"], [9, &"tower_needle_rail"], [7, &"tower_needle_rail"],
			[&"upgrade", 0, 2], [1, &"tower_needle_rail"], [&"upgrade", 2, 1],
			[5, &"tower_ember_well"], [&"upgrade", 8, 2],
		],
		ECONOMY: [ # v4：四塔输出已足但双路线覆盖不足（v3 锈甲漏 7），补 3 号位 A 路左段 + 5 号位汇合角
			[4, &"tower_ember_well"], [8, &"tower_needle_rail"], [2, &"tower_needle_rail"],
			[&"upgrade", 4, 1], [3, &"tower_needle_rail"], [&"upgrade", 8, 2],
			[&"upgrade", 2, 1], [&"upgrade", 4, -1], [5, &"tower_ember_well"],
			[&"upgrade", 3, 2], [&"upgrade", 8, -1],
		],
		SYNERGY: [ # 相位前预置 B 路覆盖（节点 2/6 贴 x480 竖段），英雄技能留给开闸波
			[0, &"tower_needle_rail"], [4, &"tower_ember_well"], [8, &"tower_needle_rail"],
			[2, &"tower_needle_rail"], [6, &"tower_ember_well"], [&"upgrade", 4, 0],
			[9, &"tower_needle_rail"], [3, &"tower_needle_rail"], [&"upgrade", 2, 1],
			[7, &"tower_needle_rail"], [&"upgrade", 6, 1], [1, &"tower_needle_rail"],
		],
	},
	# C03「失火灯塔」：基于 M2 已验证 plan 变体（steady 与原 plan 同型）。
	&"level_c03": {
		STEADY: [
			[3, &"tower_needle_rail"], [7, &"tower_needle_rail"], [4, &"tower_ember_well"],
			[6, &"tower_ember_well"], [0, &"tower_echo_pile"], [2, &"tower_echo_pile"],
			[&"upgrade", 3, 1], [&"upgrade", 0, 0], [8, &"tower_needle_rail"],
			[10, &"tower_ember_well"], [&"upgrade", 4, 2], [5, &"tower_needle_rail"],
			[&"upgrade", 7, 0], [1, &"tower_ember_well"], [9, &"tower_needle_rail"],
			[11, &"tower_ember_well"], [&"upgrade", 8, 2], [&"upgrade", 10, 0],
			[&"upgrade", 6, 1], [&"upgrade", 5, 0],
		],
		ECONOMY: [
			[3, &"tower_needle_rail"], [7, &"tower_needle_rail"], [&"upgrade", 3, 1],
			[4, &"tower_ember_well"], [&"upgrade", 7, 2], [&"upgrade", 4, 1],
			[8, &"tower_needle_rail"], [&"upgrade", 3, -1], [10, &"tower_ember_well"],
			[&"upgrade", 7, -1], [5, &"tower_needle_rail"], [&"upgrade", 4, -1],
			[6, &"tower_ember_well"], [&"upgrade", 8, 2],
		],
		SYNERGY: [ # v2：回声桩仅作减速/支援，DPS 由弩台+喷井承担（v1 回声当主 C 输出归零致败）
			[3, &"tower_needle_rail"], [7, &"tower_needle_rail"], [4, &"tower_ember_well"],
			[0, &"tower_echo_pile"], [&"upgrade", 3, 1], [6, &"tower_ember_well"],
			[&"upgrade", 7, 2], [2, &"tower_echo_pile"], [&"upgrade", 4, 1],
			[8, &"tower_needle_rail"], [10, &"tower_ember_well"], [&"upgrade", 0, 0],
			[&"upgrade", 6, 1], [5, &"tower_needle_rail"], [&"upgrade", 7, -1],
		],
	},
	# C05「漂木渡口」：三路汇入共享出口段 y180(x320–640)，节点 6/7/8 是枢纽。
	&"level_c05": {
		STEADY: [
			[6, &"tower_needle_rail"], [7, &"tower_needle_rail"], [2, &"tower_needle_rail"],
			[3, &"tower_ember_well"], [4, &"tower_needle_rail"], [8, &"tower_ember_well"],
			[&"upgrade", 6, 1], [5, &"tower_needle_rail"], [10, &"tower_needle_rail"],
			[&"upgrade", 7, 2], [9, &"tower_needle_rail"], [&"upgrade", 2, 2],
			[11, &"tower_ember_well"], [1, &"tower_needle_rail"], [&"upgrade", 3, 0],
		],
		ECONOMY: [
			[7, &"tower_needle_rail"], [6, &"tower_needle_rail"], [&"upgrade", 7, 2],
			[2, &"tower_ember_well"], [&"upgrade", 6, 1], [4, &"tower_needle_rail"],
			[&"upgrade", 7, -1], [8, &"tower_needle_rail"], [&"upgrade", 2, 1],
			[&"upgrade", 6, -1], [3, &"tower_ember_well"], [&"upgrade", 7, -1],
		],
		SYNERGY: [ # v3：实测有效的 7/8/2 核心提前满级，后期补 4/5/11 覆盖（v2 后期 612 火种无动作可花）
			[7, &"tower_needle_rail"], [8, &"tower_ember_well"], [2, &"tower_wind_nest"],
			[&"upgrade", 7, 2], [4, &"tower_needle_rail"], [&"upgrade", 8, 1],
			[&"upgrade", 2, 1], [5, &"tower_needle_rail"], [10, &"tower_tide_anvil"],
			[&"upgrade", 7, -1], [11, &"tower_ember_well"], [&"upgrade", 8, -1],
			[9, &"tower_echo_pile"], [&"upgrade", 4, 1], [&"upgrade", 11, 1],
		],
	},
	# C06「锈帆滩」：双环路。节点 1/2 内环双覆盖（上环 y64+y180），5/6 下环同理。
	&"level_c06": {
		STEADY: [
			[1, &"tower_needle_rail"], [2, &"tower_needle_rail"], [5, &"tower_needle_rail"],
			[6, &"tower_needle_rail"], [8, &"tower_ember_well"], [11, &"tower_ember_well"],
			[&"upgrade", 1, 1], [0, &"tower_wind_nest"], [7, &"tower_wind_nest"],
			[&"upgrade", 5, 1], [9, &"tower_needle_rail"], [10, &"tower_needle_rail"],
			[&"upgrade", 2, 2], [3, &"tower_needle_rail"], [4, &"tower_needle_rail"],
		],
		ECONOMY: [
			[1, &"tower_needle_rail"], [2, &"tower_needle_rail"], [&"upgrade", 1, 1],
			[5, &"tower_needle_rail"], [&"upgrade", 2, 1], [6, &"tower_ember_well"],
			[&"upgrade", 1, -1], [8, &"tower_needle_rail"], [&"upgrade", 5, 1],
			[11, &"tower_needle_rail"], [&"upgrade", 1, -1], [&"upgrade", 6, 1],
		],
		SYNERGY: [ # v2：风巢跨环长程主 C + 内环弩台削甲，回声仅 1 座减速（v1 四回声归零致败）
			[8, &"tower_wind_nest"], [11, &"tower_wind_nest"], [3, &"tower_needle_rail"],
			[10, &"tower_ember_well"], [&"upgrade", 3, 1], [0, &"tower_needle_rail"],
			[&"upgrade", 8, 1], [7, &"tower_needle_rail"], [&"upgrade", 10, 1],
			[1, &"tower_echo_pile"], [&"upgrade", 0, 2], [&"upgrade", 11, 2],
			[&"upgrade", 1, 0],
		],
	},
	# C08「吞锚蟹巢」：双折线路 + 第 12 波 Boss。顶排 1/2/12/3 贴上段，7/13/8 贴下段。
	&"level_c08": {
		STEADY: [
			[2, &"tower_needle_rail"], [12, &"tower_needle_rail"], [10, &"tower_ember_well"],
			[7, &"tower_needle_rail"], [13, &"tower_needle_rail"], [11, &"tower_ember_well"],
			[1, &"tower_needle_rail"], [&"upgrade", 2, 1], [8, &"tower_needle_rail"],
			[6, &"tower_needle_rail"], [&"upgrade", 12, 2], [4, &"tower_wind_nest"],
			[9, &"tower_needle_rail"], [&"upgrade", 7, 1], [3, &"tower_needle_rail"],
			[&"upgrade", 10, 1], [5, &"tower_needle_rail"], [&"upgrade", 11, 0],
		],
		ECONOMY: [
			[2, &"tower_needle_rail"], [10, &"tower_ember_well"], [&"upgrade", 2, 1],
			[12, &"tower_needle_rail"], [7, &"tower_needle_rail"], [&"upgrade", 10, 1],
			[13, &"tower_needle_rail"], [&"upgrade", 2, -1], [11, &"tower_ember_well"],
			[&"upgrade", 12, 2], [8, &"tower_needle_rail"], [&"upgrade", 2, -1],
			[&"upgrade", 7, 1],
		],
		SYNERGY: [ # v2 Boss 集火：喷井集火模块+潮汐砧削甲针对锚蟹王；回声仅 1 座减速支援（v1 四座回声 0 杀致败）
			[10, &"tower_ember_well"], [2, &"tower_wind_nest"], [12, &"tower_needle_rail"],
			[&"upgrade", 10, 1], [4, &"tower_tide_anvil"], [7, &"tower_needle_rail"],
			[&"upgrade", 2, 2], [11, &"tower_ember_well"], [&"upgrade", 4, 0],
			[13, &"tower_needle_rail"], [&"upgrade", 12, 1], [1, &"tower_echo_pile"],
			[&"upgrade", 11, 1], [&"upgrade", 7, 1], [&"upgrade", 1, 0],
		],
	},
}
