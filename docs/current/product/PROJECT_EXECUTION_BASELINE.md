# 《余烬潮汐》项目执行基线

> 版本：v1.0
> 建立日期：2026-09-06
> 状态：**Active / 唯一执行顺序来源**
> 上位依据：[PRD.md](PRD.md)
> 首次纠偏审计基线：`1495fdd`；本文件自身及后续治理提交不自动改变 M2 `BLOCKED` 结论

## 1. 本文件解决什么问题

`PRD.md` 继续是产品范围和发布验收的唯一权威；本文件只负责把 PRD 转换成**不可跳过的执行顺序、依赖门禁、状态定义和证据规则**。

此前出现偏航的原因不是 PRD 缺少产品路线，而是实现任务绕过了里程碑退出条件：自动化、数据和 CLI 内容被当成产品完成，导致战斗内容推进到 C14，而玩家主流程和发布质量纵向切片仍未通过。

自本基线生效后：

- 不再由临时 `NEXT_PHASE*`、聊天决定或局部任务清单改变阶段顺序；
- 不再用文件数、关卡数、自动构筑或测试总数替代玩家验收；
- 前置 Gate 未通过，不得继续下游批量内容；
- 任何偏离必须形成书面变更，说明原因、影响、回滚和批准人。

## 2. 权威关系

| 主题 | 唯一权威 | 其他文档的角色 |
|---|---|---|
| 产品范围、玩法、里程碑和发布标准 | `PRD.md` | 不得被执行笔记改写 |
| 当前执行顺序、Gate、状态定义 | `PROJECT_EXECUTION_BASELINE.md` | `CHECKLIST.md` 只记录证据 |
| 技术架构和生产方法 | `RESEARCH_REPORT.md` | 代码和测试是实现证据 |
| 美术风格、资产生命周期和许可证 | `ASSET_CATALOG.md` | `ART_PRODUCTION_PLAN.md` 负责生产拆解 |
| 美术生产批次、清单和验收 | `ART_PRODUCTION_PLAN.md` | `M4_ASSET_*` 仅作历史实施记录 |
| 进度证据索引 | `CHECKLIST.md` | 不决定阶段是否可以跳转 |

冲突处理：先按所属主题的唯一权威裁决；无法裁决时暂停实现，由项目主理人明确决定并同步修改权威文件。

## 3. 状态词典：禁止再用一个“完成”覆盖不同成熟度

每个系统、内容或资产只能使用以下状态：

1. **Specified**：PRD/规格已定义，尚未实现。
2. **Data-only**：数据或资源文件存在，但玩家不可达。
3. **Integrated**：运行时已接入，开发者可触发。
4. **Player-accessible**：普通玩家可从正式 UI 路径进入和使用。
5. **Player-verified**：按端到端脚本实跑通过，含失败、重开、退出和恢复路径。
6. **Release-ready**：满足当前里程碑的视觉、音频、性能、本地化、输入、存档和缺陷门禁。
7. **Shipping**：发布构建验收、许可证、Credits 和最终批准全部通过。

硬规则：

- 自动测试通过最多证明 `Integrated`；没有正式 UI 路径不得写 `Player-accessible`。
- smoke/CLI 通关不等于玩家通关。
- 程序生成占位图不得写“最终美术”“正式商业资产”或 `Shipping`。
- “条件通过”不能解锁下游阶段；只有全部硬门禁通过才算 Gate Passed。
- 缺少当前状态任一必需证据时，该状态声明无效，统一标记为 `Unverified/Blocked`；只有完整满足较低状态全部条件时，才能明确回落到该状态。
- 每个状态声明必须绑定 `scope_id`、git revision/build hash、证据 ID、审查人、审查时间与已知 blocker；相关代码、资源、配置或 Gate 条款变化后，证据自动变为 `STALE`，只能追溯、不能支持当前 Gate。

## 4. 当前真实基线

### 4.1 官方阶段判定

**当前仍处于 M2：发布质量纵向切片 C01–C03，Gate 未通过。**

C04–C14 已存在的关卡、敌人、Boss 和程序生成视觉属于**提前集成的 provisional 内容**：保留、不删除、可用于回归，但不代表 M3/M4 产品阶段已经通过，也不得继续据此扩展 C15+。

### 4.2 已确认状态

- 战斗内核：C01–C14 可由运行时加载，6 塔、2 英雄、2 Boss 和多种机制已集成。
- 玩家流程：C01 通关解锁/进入 C02、重开释放建造节点已修复，并有集成测试。
- 存档：单槽成绩、解锁和波次边界 suspend 已集成。
- 设置：键鼠、部分无障碍、中英和音量设置已集成。
- 视觉：C01 Foozle CC0 派生栅格表现层已接入，并于 2026-09-06 获主理人批准为全项目最终视觉方向；C02–C14 仍是 provisional/placeholder，C01 单项仍待外部玩家识别测试后才能达到 `Player-verified`。
- 音频：运行时合成占位；不是正式音频。

### 4.3 阻止 M2 Gate 的硬缺口

以 PRD §22 的 M2 退出标准为准，至少包括：

- 玩家主流程剩余项：首次无障碍设置、suspend 正式三选项、删档与难度等产品化细节；Title/Slot/Campaign/Briefing/Battle/Result 主链已落地；
- C02–C03 按 C01 黄金样板完成发布质量美术、动画与 UI；C01–C03 补齐正式音频、完整 Visual-QA 与 `Player-verified`；
- 键鼠与手柄完整流程；
- 目标机器性能与显示矩阵，而非单一本机报告；
- 5 名盲测者中至少 70% 完成 C03；首小时 S0/S1=0；
- 商店级截图和 30 秒战斗录屏；
- C01–C03 使用资产全部达到规定的 Approved/Implemented/Verified 状态；
- M2 正式退出评审。

## 5. 唯一主线：严格回到 PRD 里程碑

### M0/M1：历史工程基础

保留实现和证据，但不再以旧“完成”文字推导产品成熟度。发现影响 M2 的基础缺陷立即回修。

### M2：发布质量纵向切片 C01–C03

必须首先通过。工作只能服务于 M2 出口，不得扩 C15+。

M2 Gate 的产品级验收脚本必须覆盖：

```text
首次启动 → 无障碍快速设置 → 标题页 → 新游戏/存档槽
→ 战役/选关 → 战前简报与英雄选择 → C01
→ 失败/重开 → 通关/结算 → 解锁 C02 → 返回战役
→ 退出游戏 → 再次启动 → 继续 → C02/C03 → C03 结算
```

中途还必须抽查设置、语言、存档损坏恢复、suspend 三选项和输入焦点。任一主线路径 S1 阻断，Gate 不通过。

### M3：生产工具与第一章 C01–C08

只有 M2 Gate Passed 后才能恢复。已有 C04–C08 provisional 内容必须按冻结后的玩家外壳、美术、音频和数据规范重新验收，不能直接沿用旧勾选。

### M4：全战役 Alpha C09–C24

只有 M3 Gate Passed 后才能恢复批量内容。已有 C09–C14 provisional 内容需重新纳入正式战役入口和章节回归。M4 退出仍以 PRD 为准：24 关、4 英雄、敌人/精英/Boss、成长、图鉴、结局占位、从新档通关。

### M5–M7

严格按 PRD §22 执行 Beta 内容锁定、发布候选和发布；不得提前使用“最终”“正式发布质量”描述未过门禁的内容。

## 6. 每个任务开始前的强制检查

任何实现任务必须写明：

- 所属里程碑与对应 PRD 条款；
- 它关闭哪个 Gate 缺口；
- 前置依赖是否通过；
- 玩家从哪个正式 UI 路径访问；
- 完成状态目标（Integrated / Player-verified / Release-ready）；
- 自动验证与人工验证分别是什么；
- 不在范围内的内容；
- 失败后的回滚方式。

若任务不能关闭当前 Gate 缺口，默认不执行。安全修复和真正阻塞当前 Gate 的技术债可以例外，但必须写出与当前 blocker 的直接因果链、范围上限、截止日期和回滚方案，并经人类主理人批准。例外不得新增未来阶段的关卡、敌人、Boss、英雄、章节资产或内容数据；“维护便利性”本身不构成例外。

## 7. Gate 评审模板

每次阶段退出必须同时回答：

1. **范围**：PRD 规定的交付是否逐项存在？
2. **可达**：普通玩家是否能通过正式 UI 使用？
3. **闭环**：开始、失败、重开、完成、退出、继续是否都可走？
4. **品质**：美术、动画、音频、文案是否达到该 Gate 等级？
5. **兼容**：存档、输入、语言、分辨率和性能是否覆盖规定矩阵？
6. **缺陷**：S0/S1 是否满足门槛？
7. **证据**：自动化、截图/录像和人工名单是否真实存在？
8. **诚实性**：是否存在 Data-only 被写成完成、占位被写成最终？

八项全部通过才可提交评审；**只有项目人类主理人可以批准 Gate Passed**。Agent 只能写 `SUBMITTED_FOR_REVIEW` 或 `BLOCKED`。

唯一有效的 Gate 决议必须存为 `docs/gates/<gate_id>.yaml`，至少包含：

```yaml
gate_id: M2-GATE
status: BLOCKED | SUBMITTED_FOR_REVIEW | PASSED | STALE
evaluated_revision: <git commit>
build_hash: <artifact sha256>
criteria_revision: <PRD commit>
submitted_by: <agent/person>
approved_by: <human project owner only>
approved_at: <timestamp>
approval_record: <durable pointer>
evidence_manifest: <path + sha256>
blockers: []
supersedes: <previous decision id>
```

缺少 `approved_by`、不是人类主理人批准、证据未绑定当前 revision，或 Gate 相关实现/标准已变化时，不得为 `PASSED`。聊天总结、Checklist 勾选、测试日志和下游口头结果均不能替代 Gate 决议。

## 8. 变更控制

当前 `PRD.md`、`RESEARCH_REPORT.md`、`ASSET_CATALOG.md` 仍标记为 `Proposed`。它们可以约束“不得超前”和定义待批准目标，但在项目人类主理人明确批准并记录 revision 前，任何 Gate 均不得写 `PASSED`。

- PRD 范围变化：修改 PRD，记录批准人和影响。
- 执行顺序变化：修改本文件，说明依赖变化。
- 美术路线变化：修改 ASSET_CATALOG 和 ART_PRODUCTION_PLAN。
- 临时实验：必须带开关、回退和截止日期，不得改变正式状态。
- 下游 Agent 不得自行宣告阶段完成；只能提交实现与证据，由主理审查决定状态。

## 9. 旧记录处理

以下文档保留作历史证据，不再决定当前执行顺序：

- `NEXT_PHASE.md` / `NEXT_PHASE_NOTES.md`
- `M3_*_NOTES.md` / `M3_GATE_REVIEW.md`
- `M4_ASSET_PIPELINE.md` / `M4_CONTENT_NOTES.md`

它们的测试数据、提交和故障记录仍有效；其中“正式资产”“阶段完成”“条件通过后进入下一阶段”等旧表述，统一受本基线的当前状态覆盖。
