class_name SkillData
extends Resource
## 技能数据（M1 最小 schema；完整效果序列见 PRD §19.5，M2+ 扩展）。
## effect 为统一技能效果派发标识：dash / mark / route_sweep / barrier / repair / forge_wall。

@export var id: StringName
@export var schema_version: int = 1
@export var enabled: bool = true
@export var designer_note: String = ""
@export var display_name_key: StringName
@export var effect: StringName
@export var cooldown_seconds: float = 10.0
@export var becon_cost: int = 0 ## 终极技消耗航标充能（与潮汐仪争夺同一资源，PRD §10.1）
@export var damage: float = 0.0
@export var damage_type: StringName = &"glow"
@export var radius_px: float = 0.0
@export var duration_seconds: float = 0.0
@export var mark_multiplier: float = 1.25 ## 照明标记：目标承伤倍率
