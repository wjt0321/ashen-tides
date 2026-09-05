class_name PhaseEventData
extends Resource
## 相位事件数据（PRD §4.4）。路线切换在波次边界应用（RESEARCH_REPORT.md §5.5）；
## 潮汐仪可把下一次切换提前（立即生效）或延后（下一波开始后 +10 秒），消耗 40 航标充能。

@export var id: StringName
@export var schema_version: int = 1
@export var enabled: bool = true
@export var designer_note: String = ""
@export var level_id: StringName
@export var starts_at_wave: int = 2 ## 第几波开始时切换（1 起）
@export var from_phase: StringName = &"mingchao"
@export var to_phase: StringName = &"muchao"
@export var activates_routes: Array = [] ## Array[StringName]
@export var deactivates_routes: Array = [] ## Array[StringName]
@export var environment_changes: Array = [] ## M2+ 使用
@export var warning_seconds: float = 20.0 ## 必须 >= 20（PRD §4.1）
@export var player_interruptible: bool = true ## Boss 剧情切换为 false
@export var becon_cost: int = 40
