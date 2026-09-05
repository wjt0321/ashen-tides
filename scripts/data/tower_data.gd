class_name TowerData
extends Resource
## 塔数据（M0 最小 schema；完整字段见 PRD §19.1）。
## id 稳定：进入公开存档后不可改名，改名必须走迁移流程（RESEARCH_REPORT.md §14.4）。

@export var id: StringName
@export var schema_version: int = 1
@export var enabled: bool = true
@export var designer_note: String = ""
@export var introduced_in_level: StringName = &"level_c01"
@export var display_name_key: StringName ## 本地化 key，不是中文原文
@export var base_cost: int = 100 ## 火种
@export var range_px: float = 112.0 ## 合法范围 32–320（PRD §19.1）
@export var attack_period: float = 0.8 ## 秒/次，0.08–10
@export var damage_min: float = 18.0
@export var damage_max: float = 20.0 ## min <= max
@export var damage_type: StringName = &"physical" ## physical / glow / true（PRD §3.2，仅三类）
@export var projectile_speed: float = 320.0
@export var splash_radius: float = 0.0 ## 溅射半径（0 = 单体）
@export var pierce: int = 1 ## 投射物穿透数量（1 = 单体；针轨弩台直线穿透 > 1）
@export var tiers: Array = [] ## Array[TowerTier]，II–IV 级（PRD §6.1）；II 级必须 3 个模块候选
@export var pair_link: bool = false ## 回声桩阵：两座桩之间生成伤害线（RESEARCH_REPORT.md §7.2）
@export var link_max_range: float = 0.0 ## pair_link 桩间最大连线距离
