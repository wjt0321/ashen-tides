# 《余烬潮汐》文档中心

本目录区分**当前权威文档**、**历史归档**和**可复核证据**。实现、评审与后续关卡制作应从本页进入，不再依赖仓库根目录的临时 TODO 文件。

## 当前权威文档

### 产品 `current/product/`

- [PRD.md](current/product/PRD.md) — 产品范围、玩法、里程碑与发布验收的唯一产品权威。
- [PROJECT_EXECUTION_BASELINE.md](current/product/PROJECT_EXECUTION_BASELINE.md) — 当前执行顺序、依赖 Gate 与完成状态定义。
- [CHECKLIST.md](current/product/CHECKLIST.md) — 状态与证据索引，不独立决定 Gate 是否通过。

### 美术 `current/art/`

- [ART_STYLE_BASELINE.md](current/art/ART_STYLE_BASELINE.md) — 2026-09-06 主理人批准的最终视觉方向；C01 是后续所有关卡的黄金样板。
- [C01_STYLE_BIBLE.md](current/art/C01_STYLE_BIBLE.md) — C01 栅格化呈现的具体实现与复用规范。
- [C01_RESOURCE_DECISIONS.md](current/art/C01_RESOURCE_DECISIONS.md) — C01 资源选型、替换与保留决策。
- [ASSET_CATALOG.md](current/art/ASSET_CATALOG.md) — 资产来源、候选与许可证生命周期。
- [ART_PRODUCTION_PLAN.md](current/art/ART_PRODUCTION_PLAN.md) — 后续美术生产批次、规格与验收门禁。
- [CREDITS.md](current/art/CREDITS.md) — 第三方资源许可证和归因。

### 工程 `current/engineering/`

- [RESEARCH_REPORT.md](current/engineering/RESEARCH_REPORT.md) — Godot 技术与生产执行报告。
- [OPEN_SOURCE_TD_RESEARCH.md](current/engineering/OPEN_SOURCE_TD_RESEARCH.md) — 开源塔防结构与许可研究。
- [M4_ASSET_SPEC.md](current/engineering/M4_ASSET_SPEC.md) — 美术资产技术规格。
- [M4_ASSET_PIPELINE.md](current/engineering/M4_ASSET_PIPELINE.md) — 资产生产、导入与回退管线。
- `validate_docs.py` — 文档目录、权威文件与本地链接校验脚本。
- [`tools/validate_c01_assets.py`](../tools/validate_c01_assets.py) — C01 源包、派生资产、台账和视觉证据完整性校验。

### 质量 `current/quality/`

- [PLAYER_EXPERIENCE_AUDIT.md](current/quality/PLAYER_EXPERIENCE_AUDIT.md) — 当前真实可用范围与缺口审计。
- [M2-GATE.yaml](current/quality/gates/M2-GATE.yaml) — 当前 M2 Gate 结构化决议。

## 历史归档 `archive/`

- `milestones/` — 已完成阶段的实施笔记与收口记录。
- `plans/` — 已执行 TODO、实施计划与设计决策；仅供追溯。
- `reviews/` — 历史产品、技术、许可与 Gate 审查。
- `drafts/` — 已被当前权威文档取代的早期草稿。

归档文档不得覆盖 `current/` 的结论。若需要恢复其中的事项，应先在当前权威文档中重新立项。

## 验收证据 `evidence/`

- [C01 视觉证据](evidence/c01/) — 已采用风格的标题、战役、简报、战斗和结算截图，以及验证摘要。

`out/` 只用于本地临时生成，不纳入版本控制；需要长期保留的验收证据必须筛选后复制到 `docs/evidence/`。

## 权威关系

1. `PRD.md` 决定产品目标与范围。
2. `PROJECT_EXECUTION_BASELINE.md` 从 PRD 派生当前执行顺序与 Gate。
3. `ART_STYLE_BASELINE.md` 决定视觉语言；后续 C02+ 必须以 C01 为基准。
4. 工程规范定义实现约束，不得改写产品或视觉方向。
5. Checklist、日志和自动化结果只提供证据；Gate 仍由人类主理人批准。
6. 跨文档冲突由项目主理人裁决，并同步修改所有受影响的当前文档。
