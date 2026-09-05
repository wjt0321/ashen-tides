class_name DeviceData
extends Resource
## 环境装置数据（PRD §4.1 相位可组合项"某类环境节点激活"；C03 失火灯塔模板）。
## 装置在 active_phase 相位在线；相位事件的 environment_changes 可令其离线（device_offline）。
## 离线装置可由英雄驻守 repair_seconds 秒修复（PRD §5.3 C03：英雄修复装置）。

@export var id: StringName
@export var schema_version: int = 1
@export var enabled: bool = true
@export var designer_note: String = ""
@export var display_name_key: StringName
@export var position: Vector2 = Vector2.ZERO
@export var radius_px: float = 96.0
@export var effect_op: StringName = &"glow_pulse" ## glow_pulse：每 interval 秒对范围内敌人造成辉光伤害；reveal_pulse：揭示隐匿（effect_value=揭示秒数）；spore_heal：敌方孢子区治疗（effect_value=每跳治疗量）；cover：可破坏掩体（无脉冲，阻挡投射物）
@export var effect_value: float = 20.0
@export var interval_seconds: float = 3.0
@export var active_phase: StringName = &"both" ## mingchao / muchao / both
@export var repairable: bool = true
@export var repair_seconds: float = 3.0 ## 英雄驻守修复时长
@export var max_hp: float = 0.0 ## >0 = 可破坏（C12 掩体）；归零后失效且不可修复
@export var blocks_projectiles: bool = false ## 掩体：阻挡经过半径内的投射物（C12 沉船温室）
