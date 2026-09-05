class_name ModuleData
extends Resource
## 校准模块数据（PRD §6.1：塔 II 级时 3 选 1，本局锁定，可按出售规则重建）。
## 效果为单操作数模型：effect_op 指明语义，effect_value 为数值；
## 叠加规则固化为"每塔至多 1 个模块"，不存在多模块叠加（RESEARCH_REPORT.md §7.2）。

@export var id: StringName
@export var schema_version: int = 1
@export var enabled: bool = true
@export var designer_note: String = ""
@export var tower_id: StringName ## 所属塔（校验器核对与 TowerTier 挂载一致）
@export var display_name_key: StringName ## 本地化 key，不是中文原文
@export var description_key: StringName
@export var effect_op: StringName ## 见下表
@export var effect_value: float = 0.0
## effect_op 合法值（M2）：
## pierce_bonus        投射物额外穿透数量（针轨·长针）
## armor_shred         命中削减目标护甲值，持续 4 秒（针轨·倒钩）
## fire_rate_mult      攻击周期乘算（针轨·速轮，0.75 = 高频）
## splash_radius_mult  溅射半径乘算（余烬·扩口）
## focus_damage_mult   伤害乘算且溅射归零（余烬·凝焰）
## kill_becon          本塔击杀返还航标充能（余烬·回火）
## link_slow           链路上敌人减速比例（回声·迟滞弦，0.3 = -30%）
## link_silence        链路上敌人被沉默（回声·断响，value 无意义填 1）
## link_chain          链路伤害额外跳跃目标数（回声·共振）
## tint: Color         模块挂载后的视觉反馈色（描边），数据驱动
@export var tint: Color = Color(1.0, 1.0, 1.0)
