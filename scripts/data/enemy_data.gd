class_name EnemyData
extends Resource
## 敌人数据（M0 最小 schema；完整字段见 PRD §19.2）。
## 基准模型见 PRD §8.3：标准步兵 S = 生命 100、速度 55 px/s、击杀奖励 10。

@export var id: StringName
@export var schema_version: int = 1
@export var enabled: bool = true
@export var designer_note: String = ""
@export var introduced_in_level: StringName = &"level_c01"
@export var display_name_key: StringName
@export var max_hp: float = 100.0
@export var speed_px_per_sec: float = 55.0
@export var armor: float = 0.0 ## 物理抗性，常规范围 -25 至 150（PRD §3.3）
@export var glow_resist: float = 0.0 ## 辉光抗性
@export var leak_damage: int = 1 ## 漏过扣除的舰队完整度
@export var kill_reward_ember: int = 10 ## 击杀奖励（火种）
@export var radius_px: float = 10.0 ## 灰盒占位绘制半径
@export var tags: Array = [] ## Array[StringName]，普通敌人最多 2 个核心标签（PRD §8.1）
@export var elite: bool = false ## 精英最多 3 个核心标签
@export var elite_affixes: Array = [] ## 精英词缀：armored / enraged / tidebound / regenerating
@export var boss: bool = false ## Boss 数据入口（当前章节 C08）
@export var boss_phase_count: int = 0
@export var boss_phases: Array = [] ## [{threshold, label, armor_bonus, speed_mult, shield_restore}]
@export var shield_hp: float = 0.0 ## 护盾值（护盾标签：先于生命承伤，PRD §8.6 lamp_leech）
@export var aura_radius: float = 0.0 ## 支援光环半径（0 = 无光环）
@export var aura_speed_mult: float = 1.0 ## 光环内友军速度乘算（tide_back_navigator）
@export var stealthed: bool = false ## 隐匿（C09）：不可被塔/英雄索敌，需侦测揭示（PRD §5.3 玻璃芦径）
@export var heal_radius: float = 0.0 ## 治疗光环半径（C10 孢光洼地；0 = 无治疗）
@export var heal_per_sec: float = 0.0 ## 治疗光环每秒恢复量（沉默抑制）
@export var phase_resist_swap: bool = false ## 双相形态（C11 倒映之路）：暮潮时 armor 与 glow_resist 互换
@export var body_color: Color = Color(0.85, 0.72, 0.50) ## 灰盒占位主体色（可读性：色+形+文字三重编码，PRD §3.4）
