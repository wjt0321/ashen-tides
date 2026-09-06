# 余烬潮汐 / Ashen Tides

一款使用 **Godot 4.7** 开发的 Windows PC 单人 2D 塔防游戏。核心设计围绕固定建造节点、预制分叉路线、明潮/暮潮相位、航标充能、英雄和塔模块展开。

> **当前不是完成品，也不是可发布 Alpha。** 官方阶段仍为 **M2：C01–C03 发布质量纵向切片，Gate = BLOCKED**。C01 产品表现层与栅格美术已完成并于 2026-09-06 被主理人采用为全项目视觉基准；C02–C14 仍包含提前集成的 provisional/placeholder 内容。

## 当前真实状态

- 已集成：C01–C14 战斗数据、6 座塔、2 名英雄、2 个 Boss、固定 tick、相位/装置/模块、设置、存档与自动化工具；C01 已具备完整标题→选关→简报→战斗→结算表现层。
- 已修复：C01 通关解锁并进入 C02；重开后建造节点可再次放塔。
- 尚未达到 M2：C02–C03 尚未按 C01 黄金样板完成发布质量表现；正式音频、完整手柄流程、目标机矩阵和 5 人盲测仍待完成。
- 暂停扩展：前置 M2/M3 Gate 未通过前，不继续 C15+。

详细审计见 [`docs/current/quality/PLAYER_EXPERIENCE_AUDIT.md`](docs/current/quality/PLAYER_EXPERIENCE_AUDIT.md)。

## 运行

要求：Godot **4.7.x stable**。

1. 用 Godot Project Manager 导入本目录的 `project.godot`。
2. 打开项目并运行主场景 `scenes/boot/main.tscn`。

当前默认启动进入产品流程：标题页 → 新游戏/继续 → 三存档槽 → 战役选关 → 战前简报/英雄选择 → 战斗 → 结算。C01 已采用最终视觉方向；首次无障碍设置、删档 UI、难度选择、完整手柄菜单导航，以及 C02–C03 同等级表现仍未完成，因此整体仍属于开发中纵向切片。

### 开发验证

以下示例假设 Godot 控制台程序可通过环境或完整路径调用：

```text
godot --headless --path . --editor --quit
godot --headless --path . --script tools/validate_data.gd
godot --headless --path . --script tools/run_tests.gd
godot --headless --path . --script tools/check_i18n.gd
python docs/current/engineering/validate_docs.py
python tools/validate_c01_assets.py
```

测试通过最多证明相应功能已 `Integrated`，不代表 Player-verified、Gate Passed 或 Shipping。

## 项目基线

本项目采用不可跳过的 Gate 和七级成熟度：

```text
Specified → Data-only → Integrated → Player-accessible
→ Player-verified → Release-ready → Shipping
```

只有项目人类主理人可以批准 Gate Passed；Agent、测试日志和 Checklist 勾选不能代替批准。

### 权威文档

| 主题 | 文档 |
|---|---|
| 产品范围、玩法、里程碑、发布标准 | [`docs/current/product/PRD.md`](docs/current/product/PRD.md) |
| 当前唯一执行顺序、依赖与 Gate | [`docs/current/product/PROJECT_EXECUTION_BASELINE.md`](docs/current/product/PROJECT_EXECUTION_BASELINE.md) |
| 技术架构与生产方法 | [`docs/current/engineering/RESEARCH_REPORT.md`](docs/current/engineering/RESEARCH_REPORT.md) |
| 美术风格、候选与许可证政策 | [`docs/current/art/ASSET_CATALOG.md`](docs/current/art/ASSET_CATALOG.md) |
| 美术/精灵生产批次与验收 | [`docs/current/art/ART_PRODUCTION_PLAN.md`](docs/current/art/ART_PRODUCTION_PLAN.md) |
| 逐项美术状态 | [`ART_ASSET_REGISTRY.csv`](ART_ASSET_REGISTRY.csv) |
| 当前 M2 Gate 决议 | [`docs/current/quality/gates/M2-GATE.yaml`](docs/current/quality/gates/M2-GATE.yaml) |
| 状态和证据索引 | [`docs/current/product/CHECKLIST.md`](docs/current/product/CHECKLIST.md) |

历史 `NEXT_PHASE*`、`M3_*` 和 `M4_*_NOTES` 仅用于追溯，不决定当前路线。

## 开源塔防参照

继续实现前，项目对多个真实开源塔防进行了结构与许可证研究：

- Quiver Outpost Assault：Godot scene composition、signals、敌人 FSM、地图编排；MIT 代码与 CC BY 4.0 资产分离。
- Godot 4 Tower Defense Template：塔/敌/地图数据目录和基础菜单；适合模板，不承担完整战役架构。
- Defending Todot：可发布构建、Credits、autoload/resources/scenes 分层；GPLv3 代码只学习结构，不复制。
- CPU Defense（`ochadenas/cpudefense`）：欢迎页、选关、设置、持久化、领域规则和发布元数据明确分层，是完整小游戏产品 shell 的重要参照。
- Mindustry：内容、实体、UI、平台和工具链模块化；规模过大，仅吸收边界和构建思想。
- Server Survival：章节、目标、简报、规则变化和 debrief 组成完整关卡产品包。

校准后的目标边界是：

```text
App Flow → Campaign Domain → Battle Session
          ↘ Services / Content Catalog
Data Resources → Runtime Entities → Presentation
Tools & Tests 与玩家 UI 调用同一应用服务
```

不整体搬运外部仓库，不引入 Mindustry 级 ECS/网络/模组复杂度，不复制 GPL 代码，不改变固定 BuildNode + PathNetwork 与固定 tick 基线。

完整研究、精确 URL 和取舍见 [`docs/current/engineering/OPEN_SOURCE_TD_RESEARCH.md`](docs/current/engineering/OPEN_SOURCE_TD_RESEARCH.md)。

## 现成开源资源结论

本轮开源研究中的候选素材尚未并入正式构建。仓库当前已有一款已接入的 OFL-1.1 字体，以及一个仅由试验开关启用的 CC0 tileset；详见许可证台账与 Credits。以下项目仅完成页面级来源和许可证初筛，尚未下载逐文件核验：

- [Kenney Tower Defense Top-Down](https://kenney.nl/assets/tower-defense-top-down) — CC0，适合作为塔防功能底稿；视觉过亮，不是最终海潮风格。
- [Kenney Pirate Pack](https://kenney.nl/assets/pirate-pack) — CC0，适合船、码头、岛礁和海事道具候选。
- [Kenney UI Audio](https://kenney.nl/assets/ui-audio) — CC0，适合作为 UI 音效候选。
- [LPC Ship](https://opengameart.org/content/lpc-ship) — 可选择 CC BY 4.0，模块化船与动画火炮有价值，但需完整署名和修改记录。
- LPC/Ocean 32×32 水面动画 — 只作动画节奏参考；BY-SA 管理成本较高，最终倾向自制。

任何资产必须经过 `Research → Proposed → Approved → Implemented → Verified → Shipping`，并记录来源、选择的许可证路径、原始/导出 hash、修改说明和 Credits。公开仓库、预览图或 MIT 代码许可都不自动赋予资产复用权。

## 目录概览

```text
autoload/       跨场景服务
assets/art/      自有/派生运行时美术（C01 基准位于 assets/art/c01/runtime）
assets/vendor/   按关卡和来源归档的第三方源资产与许可
data/            typed Resource 内容数据
docs/            PRD、执行基线、研究与 Gate
scenes/          Godot 场景
scripts/         运行时与工具脚本
tests/           自动化测试
tools/           校验、报告和资产生成工具
```

## 许可证

**本仓库目前没有项目级 `LICENSE` 文件，因此公开可见不等于授予复用许可。** 在人类项目主理人选定代码许可证前，请勿复制、修改或再分发本项目代码与原创资源。

第三方字体和未来候选资产按各自许可证管理，详见：

- [`ASSET_LICENSE_LEDGER.csv`](ASSET_LICENSE_LEDGER.csv)
- [`docs/current/art/CREDITS.md`](docs/current/art/CREDITS.md)
- `licenses/`

代码许可证与资产许可证始终分开判断。

## 项目主页

<https://github.com/wjt0321/ashen-tides>
