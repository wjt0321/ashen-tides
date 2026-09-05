class_name LevelData
extends Resource
## 关卡数据（M0 最小 schema；完整字段见 PRD §19.4 / RESEARCH_REPORT.md §12）。
## 路径模型：固定 BuildNode + 预制 PathNetwork；BuildNode 永远不在路线 curve 上
## （数据层互斥，PRD §5.4），由 tools/validate_data.gd 强制校验。
## 注意：数组未声明元素类型，以便 .tres 文本序列化稳定；元素约束由校验器保证。

@export var id: StringName
@export var schema_version: int = 1
@export var enabled: bool = true
@export var designer_note: String = ""
@export var display_name_key: StringName
@export var map_size_cells: Vector2i = Vector2i(20, 11) ## 640×360 ÷ 32
@export var initial_ember: int = 200 ## 初始火种（关卡固定）
@export var initial_fleet_integrity: int = 20 ## 初始舰队完整度
@export var allowed_towers: Array = [] ## Array[StringName]，必须存在于 data/towers/
@export var route_ids: Array = [] ## Array[StringName]，与 route_points 一一对应
@export var route_points: Array = [] ## Array[PackedVector2Array]，预制路线折线
@export var default_active_route: StringName ## 默认激活路线
@export var initial_active_routes: Array = [] ## Array[StringName]，开局即激活；空 = 仅 default_active_route
@export var build_node_positions: Array = [] ## Array[Vector2]，8–22 个固定建造点
@export var waves: Array = [] ## Array[WaveData]
@export var phase_events: Array = [] ## Array[PhaseEventData]
@export var allowed_heroes: Array = [] ## Array[StringName]，必须存在于 data/heroes/
@export var hero_spawn: Vector2 = Vector2(480, 256)
@export var primary_objective_key: StringName ## 主目标本地化 key（结算印记 1：通关）
@export var strategy_objective_key: StringName ## 策略目标本地化 key（印记 3，PRD §9.2）
@export var strategy_objective_op: StringName ## 策略目标判定：upgrade_any_tower / use_tide_clock / repair_device
@export var integrity_mark_threshold: int = 15 ## 印记 2：结算时舰队完整度阈值
@export var tutorial_id: StringName ## 教学节拍 id（PRD §11.2；空 = 无教程）
@export var devices: Array = [] ## Array[DeviceData]，相位模板 2（C03 装置失效/修复）
@export var chapter_index: int = 1
@export var target_tags: Array = [] ## 本章目标标签，供生产校验与战报使用
@export var boss_enemy_id: StringName = &"" ## Boss 关可选，必须在某一波出现
