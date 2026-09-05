class_name WaveData
extends Resource
## 波次数据（M0 最小 schema；完整字段见 PRD §19.3 / RESEARCH_REPORT.md §13.1）。
## groups 元素为 WaveData 同目录定义的 WaveGroup 资源。
## 注意：数组未声明元素类型，以便 .tres 文本序列化稳定；元素约束由 tools/validate_data.gd 校验。

@export var id: StringName
@export var schema_version: int = 1
@export var enabled: bool = true
@export var designer_note: String = ""
@export var introduced_in_level: StringName = &"level_c01"
@export var wave_index: int = 1
@export var pre_delay_seconds: float = 5.0 ## 必须 >= 5 秒（RESEARCH_REPORT.md §13.1）
@export var groups: Array = [] ## Array[WaveGroup]
@export var completion_reward_ember: int = 20
@export var completion_reward_becon: int = 5
@export var intent: StringName = &"economy" ## 波次意图（PRD §8.4）
