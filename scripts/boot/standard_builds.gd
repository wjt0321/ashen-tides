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
	# C09「玻璃芦径」：交叉路 + 隐匿敌；侦测棱镜（320,240 r150）是揭示核心，塔群贴着放。
	&"level_c09": {
		STEADY: [
			[7, &"tower_needle_rail"], [8, &"tower_needle_rail"], [11, &"tower_ember_well"],
			[6, &"tower_needle_rail"], [9, &"tower_needle_rail"], [&"upgrade", 7, 1],
			[12, &"tower_needle_rail"], [10, &"tower_ember_well"], [&"upgrade", 8, 2],
			[2, &"tower_needle_rail"], [13, &"tower_needle_rail"], [&"upgrade", 11, 0],
			[3, &"tower_needle_rail"], [&"upgrade", 6, 1], [14, &"tower_ember_well"],
			[&"upgrade", 9, 1],
		],
		ECONOMY: [
			[7, &"tower_needle_rail"], [8, &"tower_needle_rail"], [&"upgrade", 7, 1],
			[11, &"tower_ember_well"], [&"upgrade", 8, 2], [6, &"tower_needle_rail"],
			[&"upgrade", 7, -1], [12, &"tower_needle_rail"], [&"upgrade", 11, 0],
			[9, &"tower_needle_rail"], [&"upgrade", 8, -1], [2, &"tower_needle_rail"],
			[&"upgrade", 6, 1],
		],
		SYNERGY: [ # 风巢长程 + 喷井溅射 + 回声缓速（C09 无棱镜，构筑仅限本关可用塔）
			[8, &"tower_wind_nest"], [7, &"tower_needle_rail"], [11, &"tower_ember_well"],
			[&"upgrade", 8, 1], [6, &"tower_echo_pile"], [10, &"tower_echo_pile"],
			[&"upgrade", 7, 1], [12, &"tower_needle_rail"], [&"upgrade", 11, 1],
			[2, &"tower_wind_nest"], [&"upgrade", 2, 1], [9, &"tower_needle_rail"],
			[&"upgrade", 6, 0], [13, &"tower_needle_rail"], [&"upgrade", 9, 1],
			[3, &"tower_needle_rail"], [&"upgrade", 12, 1], [14, &"tower_ember_well"],
			[&"upgrade", 3, 1], [&"upgrade", 13, 1],
		],
	},
	# C10「孢光洼地」：双路常驻 + 双孢子治疗区；输出贴着两路尾段集火，压制治疗窗口。
	&"level_c10": {
		STEADY: [
			[6, &"tower_needle_rail"], [11, &"tower_needle_rail"], [7, &"tower_needle_rail"],
			[12, &"tower_ember_well"], [1, &"tower_needle_rail"], [&"upgrade", 6, 1],
			[8, &"tower_needle_rail"], [15, &"tower_ember_well"], [&"upgrade", 7, 2],
			[5, &"tower_needle_rail"], [14, &"tower_needle_rail"], [&"upgrade", 11, 1],
			[2, &"tower_needle_rail"], [&"upgrade", 12, 0], [9, &"tower_needle_rail"],
			[&"upgrade", 8, 1], [3, &"tower_needle_rail"], [13, &"tower_needle_rail"],
			[4, &"tower_needle_rail"], [&"upgrade", 15, 1], [&"upgrade", 1, 1],
			[10, &"tower_ember_well"], [&"upgrade", 5, 1], [&"upgrade", 2, 1],
			[&"upgrade", 9, 1], [&"upgrade", 14, 1],
		],
		ECONOMY: [
			[6, &"tower_needle_rail"], [7, &"tower_needle_rail"], [&"upgrade", 6, 1],
			[11, &"tower_needle_rail"], [&"upgrade", 7, 2], [12, &"tower_ember_well"],
			[&"upgrade", 6, -1], [8, &"tower_needle_rail"], [&"upgrade", 11, 1],
			[&"upgrade", 12, 0], [15, &"tower_ember_well"], [&"upgrade", 8, 1],
			[5, &"tower_needle_rail"], [&"upgrade", 5, 1], [1, &"tower_needle_rail"],
			[&"upgrade", 1, 1], [14, &"tower_needle_rail"], [&"upgrade", 14, 1],
			[10, &"tower_ember_well"], [&"upgrade", 10, 1], [9, &"tower_needle_rail"],
			[&"upgrade", 9, 1], [&"upgrade", 7, -1], [3, &"tower_needle_rail"],
			[&"upgrade", 3, 1],
		],
		SYNERGY: [ # v2：去掉回声主 C（v1 回声+棱镜输出不足漏 13）；棱镜+喷井+风巢为主，回声仅 1 对缓速
			[7, &"tower_prism_grove"], [6, &"tower_needle_rail"], [12, &"tower_ember_well"],
			[&"upgrade", 7, 1], [11, &"tower_needle_rail"], [2, &"tower_wind_nest"],
			[8, &"tower_prism_grove"], [&"upgrade", 6, 1], [15, &"tower_ember_well"],
			[&"upgrade", 12, 1], [5, &"tower_needle_rail"], [14, &"tower_needle_rail"],
			[&"upgrade", 11, 1], [1, &"tower_needle_rail"], [&"upgrade", 8, 1],
			[3, &"tower_needle_rail"], [&"upgrade", 5, 1], [9, &"tower_needle_rail"],
			[&"upgrade", 9, 1], [&"upgrade", 14, 1], [&"upgrade", 15, 1],
			[10, &"tower_ember_well"], [&"upgrade", 10, 1],
			[13, &"tower_needle_rail"], [&"upgrade", 13, 1], [&"upgrade", 7, -1],
			[4, &"tower_needle_rail"], [&"upgrade", 4, 1], [&"upgrade", 2, -1],
		],
	},
	# C11「倒映之路」：镜像双路 + 双相敌换抗性；物理/辉光必须混编，潮汐砧主打。
	&"level_c11": {
		STEADY: [
			[4, &"tower_needle_rail"], [9, &"tower_ember_well"], [5, &"tower_needle_rail"],
			[10, &"tower_ember_well"], [6, &"tower_needle_rail"], [&"upgrade", 4, 1],
			[11, &"tower_needle_rail"], [3, &"tower_ember_well"], [&"upgrade", 9, 1],
			[8, &"tower_needle_rail"], [12, &"tower_needle_rail"], [&"upgrade", 5, 2],
			[7, &"tower_needle_rail"], [&"upgrade", 10, 0], [13, &"tower_needle_rail"],
			[&"upgrade", 6, 1],
		],
		ECONOMY: [
			[4, &"tower_needle_rail"], [5, &"tower_needle_rail"], [&"upgrade", 4, 1],
			[9, &"tower_ember_well"], [&"upgrade", 5, 2], [10, &"tower_ember_well"],
			[&"upgrade", 4, -1], [6, &"tower_needle_rail"], [&"upgrade", 9, 1],
			[11, &"tower_needle_rail"], [&"upgrade", 10, 0], [&"upgrade", 6, 1],
			[3, &"tower_ember_well"], [&"upgrade", 3, 1], [8, &"tower_needle_rail"],
			[&"upgrade", 8, 1], [&"upgrade", 5, -1], [12, &"tower_needle_rail"],
			[&"upgrade", 12, 1], [13, &"tower_needle_rail"], [&"upgrade", 13, 1],
		],
		SYNERGY: [ # v2：潮汐砧+棱镜伤害配比（v1 八塔漏 13，补塔+升级填满经济）
			[5, &"tower_tide_anvil"], [4, &"tower_needle_rail"], [10, &"tower_prism_grove"],
			[&"upgrade", 5, 0], [9, &"tower_ember_well"], [6, &"tower_wind_nest"],
			[11, &"tower_prism_grove"], [&"upgrade", 4, 1], [&"upgrade", 10, 1],
			[8, &"tower_needle_rail"], [&"upgrade", 9, 1], [13, &"tower_needle_rail"],
			[&"upgrade", 6, 2], [3, &"tower_ember_well"], [&"upgrade", 3, 1],
			[12, &"tower_needle_rail"], [&"upgrade", 12, 1], [&"upgrade", 11, 1],
			[7, &"tower_needle_rail"], [&"upgrade", 7, 1], [&"upgrade", 8, 1],
			[&"upgrade", 13, 1], [14, &"tower_ember_well"], [&"upgrade", 14, 1],
		],
	},
	# C12「沉船温室」：汇流路 + 船壳掩体挡射界；主力压汇流尾段，边塔先清掩体开射界。
	&"level_c12": {
		STEADY: [
			[4, &"tower_needle_rail"], [13, &"tower_needle_rail"], [5, &"tower_needle_rail"],
			[15, &"tower_ember_well"], [6, &"tower_needle_rail"], [&"upgrade", 4, 1],
			[16, &"tower_needle_rail"], [12, &"tower_needle_rail"], [&"upgrade", 5, 2],
			[11, &"tower_ember_well"], [14, &"tower_needle_rail"], [&"upgrade", 6, 1],
			[7, &"tower_needle_rail"], [&"upgrade", 15, 0], [10, &"tower_needle_rail"],
			[&"upgrade", 13, 1],
		],
		ECONOMY: [
			[4, &"tower_needle_rail"], [5, &"tower_needle_rail"], [&"upgrade", 4, 1],
			[15, &"tower_ember_well"], [&"upgrade", 5, 2], [13, &"tower_needle_rail"],
			[&"upgrade", 4, -1], [6, &"tower_needle_rail"], [&"upgrade", 15, 0],
			[16, &"tower_needle_rail"], [&"upgrade", 6, 1], [12, &"tower_needle_rail"],
			[14, &"tower_needle_rail"], [&"upgrade", 14, 1], [11, &"tower_ember_well"],
			[&"upgrade", 11, 1], [7, &"tower_needle_rail"], [&"upgrade", 7, 1],
			[10, &"tower_needle_rail"], [&"upgrade", 10, 1], [&"upgrade", 5, -1],
		],
		SYNERGY: [ # v2：潮汐砧+棱镜混编破掩体（v1 八塔漏 11，补塔+升级填满经济）
			[5, &"tower_tide_anvil"], [4, &"tower_needle_rail"], [15, &"tower_prism_grove"],
			[&"upgrade", 5, 0], [13, &"tower_ember_well"], [6, &"tower_wind_nest"],
			[16, &"tower_prism_grove"], [&"upgrade", 4, 1], [11, &"tower_ember_well"],
			[&"upgrade", 15, 1], [12, &"tower_needle_rail"], [&"upgrade", 13, 1],
			[&"upgrade", 6, 1], [14, &"tower_needle_rail"], [&"upgrade", 14, 1],
			[7, &"tower_needle_rail"], [&"upgrade", 7, 1], [&"upgrade", 16, 1],
			[10, &"tower_needle_rail"], [&"upgrade", 10, 1], [&"upgrade", 11, 1],
		],
	},
	# C13「雾母腹地」：三入口 + 召唤敌 + 隐匿敌。w1–3 只有 a/b 两路，w4 相位开 c 路（顶排 0–4 覆盖）。
	# 召唤载体走 a/b 路，7/8/13 位集火本体；雾透镜揭示 stalker。
	&"level_c13": {
		STEADY: [
			[7, &"tower_needle_rail"], [13, &"tower_needle_rail"], [2, &"tower_needle_rail"],
			[8, &"tower_needle_rail"], [12, &"tower_ember_well"], [&"upgrade", 7, 1],
			[1, &"tower_needle_rail"], [14, &"tower_needle_rail"], [&"upgrade", 13, 2],
			[11, &"tower_needle_rail"], [3, &"tower_needle_rail"], [&"upgrade", 2, 1],
			[9, &"tower_needle_rail"], [15, &"tower_ember_well"], [&"upgrade", 8, 1],
			[4, &"tower_needle_rail"], [&"upgrade", 12, 0],
		],
		ECONOMY: [ # v2：补顶排 3/4 覆盖 c 路隐匿 stalker（v1 顶排仅 1/2，透镜揭示空窗漏 16）
			[7, &"tower_needle_rail"], [13, &"tower_needle_rail"], [&"upgrade", 7, 1],
			[2, &"tower_needle_rail"], [&"upgrade", 13, 2], [3, &"tower_needle_rail"],
			[&"upgrade", 2, 1], [12, &"tower_ember_well"], [8, &"tower_needle_rail"],
			[&"upgrade", 3, 1], [14, &"tower_needle_rail"], [&"upgrade", 13, -1],
			[9, &"tower_needle_rail"], [&"upgrade", 12, 0], [4, &"tower_needle_rail"],
			[&"upgrade", 8, 1], [1, &"tower_needle_rail"],
		],
		SYNERGY: [ # 相位/英雄协同：风巢跨路长程 + 棱镜贯穿 + 回声缓速沉默压制召唤（回声仅支援）
			[2, &"tower_wind_nest"], [7, &"tower_needle_rail"], [8, &"tower_prism_grove"],
			[13, &"tower_echo_pile"], [&"upgrade", 2, 1], [12, &"tower_ember_well"],
			[&"upgrade", 8, 1], [14, &"tower_needle_rail"], [&"upgrade", 7, 1],
			[9, &"tower_needle_rail"], [&"upgrade", 12, 0], [1, &"tower_needle_rail"],
			[&"upgrade", 13, 0], [4, &"tower_needle_rail"], [&"upgrade", 9, 1],
			[15, &"tower_ember_well"], [&"upgrade", 14, 1],
		],
	},
	# C14「沼冠孢王」（Boss 场）：w1–5 仅 a 路，w6 根系改道开 b 路，w12 Boss。
	# 孢巢 A(352,148)/B(488,216)/C(96,296) 阻挡投射物且供疗——边塔先清巢开射界，8/9/12/13 位集火 Boss 尾段。
	&"level_c14": {
		STEADY: [ # v4：b 路换辉光（15/12/13 喷井打 carrier glow_resist=10；v3 弩台物理漏 7 carrier）；a 路 6/7/9 喷井 + 2 砧 + 8 弩
			[7, &"tower_ember_well"], [6, &"tower_ember_well"], [8, &"tower_needle_rail"],
			[&"upgrade", 7, 1], [9, &"tower_ember_well"], [15, &"tower_ember_well"],
			[&"upgrade", 6, 1], [14, &"tower_needle_rail"], [2, &"tower_tide_anvil"],
			[&"upgrade", 8, 1], [13, &"tower_ember_well"], [12, &"tower_ember_well"],
			[&"upgrade", 9, 0], [11, &"tower_ember_well"], [&"upgrade", 2, 0],
			[5, &"tower_ember_well"], [&"upgrade", 14, 1], [&"upgrade", 13, 1],
			[1, &"tower_ember_well"],
		],
		ECONOMY: [ # v4：同思路少塔多升级
			[7, &"tower_ember_well"], [6, &"tower_ember_well"], [&"upgrade", 7, 1],
			[8, &"tower_needle_rail"], [&"upgrade", 6, 1], [9, &"tower_ember_well"],
			[&"upgrade", 7, -1], [15, &"tower_ember_well"], [2, &"tower_tide_anvil"],
			[&"upgrade", 8, 1], [14, &"tower_needle_rail"], [&"upgrade", 9, 0],
			[&"upgrade", 2, 0], [13, &"tower_ember_well"], [11, &"tower_ember_well"],
			[&"upgrade", 13, 1], [12, &"tower_ember_well"], [&"upgrade", 15, 1],
			[&"upgrade", 6, -1],
		],
		SYNERGY: [ # v3 Boss 集火：喷井辉光主战 + 砧塔削甲 + 回声沉默医正（v2 开局出口侧放空，w1 漏 4）
			[7, &"tower_ember_well"], [6, &"tower_ember_well"], [&"upgrade", 7, 1],
			[2, &"tower_tide_anvil"], [8, &"tower_needle_rail"], [&"upgrade", 2, 0],
			[9, &"tower_ember_well"], [14, &"tower_needle_rail"], [15, &"tower_needle_rail"],
			[&"upgrade", 6, 1], [13, &"tower_ember_well"], [&"upgrade", 9, 0],
			[11, &"tower_echo_pile"], [12, &"tower_needle_rail"], [&"upgrade", 13, 1],
			[&"upgrade", 8, 1], [5, &"tower_ember_well"], [&"upgrade", 12, 1],
		],
	},
}
