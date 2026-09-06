# 《余烬潮汐》美术与精灵生产计划

> 版本：v1.0
> 建立日期：2026-09-06
> 状态：Active
> 风格与许可证上位依据：[ASSET_CATALOG.md](ASSET_CATALOG.md)
> 项目顺序依据：[PROJECT_EXECUTION_BASELINE.md](PROJECT_EXECUTION_BASELINE.md)

## 1. 是否需要比 PRD 更细

需要，但不是重写 PRD。

PRD 已经明确了产品视觉目标、像素尺寸、可读性和里程碑；ASSET_CATALOG 已明确风格路线、禁止混搭、候选/Shipping 生命周期和许可证规则。这些足以决定“做成什么”，但不足以稳定管理数百张精灵的**逐项规格、依赖、批次、版本、动画覆盖、评审和替换**。

本文件补的是美术生产控制层，防止：同一角色由不同批次画出不同比例；单帧占位被误认为最终；关卡先生产、动画和 UI 后补导致大规模返工；不同 Agent 使用不同调色板、光向和命名。

## 2. 权威边界

- `ASSET_CATALOG.md`：风格、候选、许可与生命周期政策。
- `ART_PRODUCTION_PLAN.md`：资产清单结构、生产批次、依赖和验收。
- `M4_ASSET_SPEC.md`：早期接入技术细则，仅作输入；其 `Locked/正式资产` 状态由本计划覆盖。
- `ASSET_LICENSE_LEDGER.csv`：真实文件和许可证证据，不代表视觉质量通过。

## 3. 资产成熟度

每个资产包使用独立的 **Art Status**：

1. `Briefed`：用途、尺寸、动作、色板、参考已明确。
2. `Concept-approved`：轮廓、比例、视角和材质语言通过评审。
3. `Production`：正在绘制，不进入发布构建。
4. `Integrated`：导入游戏并绑定稳定 ID，有缺失回退。
5. `Visual-QA`：在目标关卡、最繁忙场景、色觉预设和 UI 缩放下通过。
6. `Player-verified`：外部玩家无需说明可辨认关键对象和状态。
7. `Shipping`：Visual-QA + Player-verified + 动画/音频依赖完整 + 许可证/Credits + 主理批准。

当前 `assets/art/` 程序生成 PNG 统一为：`Integrated placeholder`。许可证为 Project-owned 不等于 Art Status 为 Shipping。

三套状态不得互相替代：资产来源 `Approved/Implemented` 最多支持项目 `Specified/Integrated`；`Visual-QA` 不自动等于玩家验证；单项资产 `Asset-Shipping` 不等于美术包 `Art-Shipping`，更不等于项目 `Project-Shipping`。任何 Shipping 声明必须满足 `ASSET_CATALOG.md` 与本计划条件的并集。

## 4. 风格圣经必须锁定的内容

在任何最终精灵批量生产前，建立可视化 Style Bible（不能只有文字）：

- 32×32、64×64、96/128×128 的比例尺和像素密度对照；
- 正交俯视角度、可见顶部/侧面比例；
- 西北 315° 单一光向和四档明暗阶；
- 全局母色板、四章节子色板、阵营/危险/交互保留色；
- 1px 描边、内部线、接触阴影、透明边缘规则；
- 塔、英雄、普通敌、精英、Boss 的轮廓板；
- 金属、木、布、玻璃、孢体、余烬六类材质样张；
- UI 黄铜海图语言：面板、按钮、焦点、禁用、危险、弹窗；
- 色觉预设和高对比的允许变化；
- 禁止混搭样例和错误示例。

Style Bible 未经一次整屏 mockup 评审通过，不得批量生产。

## 5. 每项资产的规格字段

资产清单中的每个 `asset_id` 至少记录：

- 对应数据 ID、章节、首次出现关卡和使用场景；
- 类型、画布尺寸、占地、锚点、碰撞/命中特效挂点；
- 方向数；
- 动作列表、每动作帧数、FPS、循环/单次、关键帧事件；
- 轮廓关键词、材质、章节色板、光向；
- 受击、控制、护盾、沉默、隐匿、精英、Boss 阶段等状态表现；
- VFX/SFX/UI 依赖；
- 文件路径、版本、负责人、Art Status；
- 许可证状态和 ledger ID；
- 评审截图、目标关卡、评审人、问题与回滚版本。

没有这些字段的“画一张精灵”任务不得进入生产。

## 6. 动画最低规格矩阵

最终数值以 Style Bible 和角色 brief 为准，但不得低于：

| 类型 | 必需动作 |
|---|---|
| 普通敌 | idle、move、attack/ability（如有）、hit、death；特殊状态按能力增加 |
| 精英 | 普通敌全部动作 + 精英能力 telegraph/execute + 可辨精英状态 |
| Boss | idle、move、attack、hit、death、每阶段 transition、每个核心机制 telegraph/execute/recover |
| 塔 | idle、attack、upgrade transition；模块/过热/沉默等状态必须可辨 |
| 英雄 | idle、move、basic attack、技能 A/B、ultimate、hit、down、recover |
| 装置 | idle/online/offline、damage、repair、destroy（按设计） |
| UI | normal、hover/focus、pressed、disabled、locked、selected |
| VFX | anticipation、impact、linger/decay；危险效果满足闪光预算 |

程序闪白、缩放、modulate 可以补反馈，但不能替代必需角色动画。

## 7. 生产顺序和冻结点

### ART-A-STYLE-BIBLE：Style Bible

通过条件：完整可视样张、C01 整屏 mockup、核心塔/敌/英雄比例统一、UI 与战场同屏一致。未通过不得做全章。

### ART-B-C01-SLICE：C01 发布质量切片

只生产 C01 真正需要的完整资产包：地形、UI、针轨塔全等级与动画、两类敌人的完整动画、必要英雄、投射物、状态、VFX、BGM/SFX 接口。目标是证明**最终生产质量和吞吐**，不是先画很多单位。

### ART-C-C02-C03-SLICE：C02–C03 纵向切片完成

复用并补齐 C02/C03 的塔、敌、英雄、装置、相位视觉和音频。完成后冻结：比例、光向、轮廓、主色板、动画时序、UI 组件和导出模板。

### ART-D-CHAPTER1：第一章批量生产

只在 C01–C03 Player-verified 后扩 C04–C08。按“关卡资产包”交付，不按“先画全敌人后再接入”交付。

### ART-E-LATER-CHAPTERS：后续章节

第二、三、四章依次进行：章节概念板 → 章节纵向关 → 章节批量 → Boss 包 → 章节整屏 QA。已有 C09–C14 程序图继续作占位，等待其章节 Gate。

### ART-F-SHIPPING：内容锁定与 Shipping

补齐全部动画、UI、VFX、宣传画面；逐项做 Visual-QA、Player-verified、许可证和 Credits；替换/删除占位引用需单独审计，不因文件存在自动删除。

## 8. 每个资产包的流水线

```text
Brief → silhouette sheet → concept review → palette/material pass
→ animation key poses → full frames → export → Godot import
→ in-context screenshot/video → readability/performance/accessibility QA
→ player recognition test → fixes → approval → Shipping
```

每一阶段的失败都回到最近可恢复版本；禁止在未通过 silhouette/concept 时直接批量补帧。

## 9. 一致性门禁

每批资产必须同时通过：

- **比例**：同类别尺寸和接触点与标准模板一致；
- **视角**：顶部/侧面比例一致，无等距或侧视混入；
- **光向**：高光和阴影统一；
- **色板**：章节色板和保留色不冲突；
- **轮廓**：640×360、100%/125%/150% UI 下仍可辨；
- **动作**：帧率、关键帧事件和固定 tick 不漂移；
- **状态**：不能只靠颜色，危险/可交互有形状和动画差异；
- **同屏**：40+ 敌、6 塔、英雄、VFX 叠加时不糊；
- **性能**：纹理页、draw call、内存和 3×速度满足当前 Gate；
- **来源**：许可证、hash、衍生关系和 Credits 完整。

## 10. 版本、状态注册与替换规则

逐项当前状态只能登记在 `ART_ASSET_REGISTRY.csv`；其他 Markdown 只能引用，不得重复宣告当前状态。Registry 至少包含 `asset_id,runtime_ids,chapter,first_level,asset_lifecycle_status,art_status,placeholder,active_version,source_hash,export_hash,license_ledger_id,required_animations,completed_animations,visual_qa_evidence,player_test_evidence,approved_by,approval_record,target_build`。`placeholder=true` 时 Art Status 最高为 `Integrated`；许可证完整不得提升 Art Status。

- 源文件与导出文件分离；发布仓库只放批准的必要源/导出物。
- 文件名包含稳定数据 ID，不用显示名。
- 替换必须保持锚点、画布和运行时契约；不兼容变化先升级规范。
- 同一资产只允许一个 Active 版本；候选和废弃版本进入可追溯归档。
- 占位回退必须在每个阶段前移检查：M2 检查 C01–C03、M3 检查 C01–C08、每章 Gate 检查对应章节、Shipping 检查全项目；结果必须进入 Gate evidence manifest。存在未批准回退即阻止对应 Gate。
- 生成器继续保留作回退、测试和无资产开发，不计入最终美术完成率。

## 11. 验收证据

资产不得只凭“看起来不错”升级状态。至少需要：

- 单资产 sprite sheet 与版本号；
- 正常、色觉预设、高对比截图；
- 最繁忙战斗 10–30 秒视频；
- 目标尺寸辨识测试；
- 动画状态覆盖表；
- Godot 导入和缺资源扫描；
- 性能报告；
- 外部玩家识别记录；
- ledger、许可证原文、hash 和 Credits。

## 12. 当前纠偏

- `M4_ASSET_SPEC.md` 中“Locked（M4-A）”“后续全部正式资产生产”等字样仅视为**技术接入基线**，不是最终视觉冻结。
- `M4_ASSET_PIPELINE.md` 中 C01–C14 资产记录均为历史接入证据，当前统一状态为 `Integrated placeholder`。
- 在 Art Gate A/B/C 通过前，不再批量生成后续章节最终精灵，也不把自动生成 PNG 数量计入最终美术进度。
