class_name HeroData
extends Resource
## 英雄数据（M1 最小 schema；PRD §7）。英雄是战术工具，无法独自清场。

@export var id: StringName
@export var schema_version: int = 1
@export var enabled: bool = true
@export var designer_note: String = ""
@export var display_name_key: StringName
@export var max_hp: float = 300.0
@export var move_speed: float = 130.0
@export var attack_range: float = 110.0
@export var attack_period: float = 0.7
@export var damage: float = 12.0
@export var skill_a: SkillData
@export var skill_b: SkillData
@export var ultimate: SkillData
@export var revive_seconds: float = 25.0 ## 倒下后复归时间（M2 启用倒地机制）
