class_name TowerTier
extends Resource
## 塔等级数据（PRD §6.1：每塔 4 级 I–IV；TowerData 平铺字段即 I 级，本资源描述 II–IV）。
## II 级必须提供 3 个校准模块候选（3 选 1）；III/IV 级 module_choices 为空。
## IV 级主动技能与自动被动属 M3 范围，M2 不做。

@export var tier: int = 2 ## 2..4
@export var cost_to_upgrade: int = 80 ## 升到本级的火种成本
@export var damage_min: float = 0.0 ## 0 = 继承上一级
@export var damage_max: float = 0.0
@export var range_px: float = 0.0
@export var attack_period: float = 0.0
@export var module_choices: Array = [] ## Array[ModuleData]，仅 tier=2 非空且必须为 3 个
