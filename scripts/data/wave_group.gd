class_name WaveGroup
extends Resource
## 波次内的一组敌人（M0 最小 schema；RESEARCH_REPORT.md §13.1 WaveGroup）。

@export var enemy_id: StringName ## 必须存在于 data/enemies/
@export var count: int = 1
@export var interval_seconds: float = 1.0
@export var entrance_index: int = 0 ## 入口索引（M0 单入口，恒 0）
@export var delay_after_prev_seconds: float = 0.0
@export var route_id: StringName = &"" ## 生成路线；空 = 关卡默认激活路线
