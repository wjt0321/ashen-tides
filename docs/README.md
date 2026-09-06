# 《余烬潮汐》项目文档

## 先看哪份

- [PRD.md](PRD.md) —— 产品范围、玩法、里程碑和发布验收的唯一权威。
- [PROJECT_EXECUTION_BASELINE.md](PROJECT_EXECUTION_BASELINE.md) —— 当前唯一执行顺序、依赖 Gate 和完成状态定义。
- [ART_PRODUCTION_PLAN.md](ART_PRODUCTION_PLAN.md) —— 美术/精灵的生产批次、规格字段、一致性门禁和验收流程。
- [RESEARCH_REPORT.md](RESEARCH_REPORT.md) —— Godot 技术与生产执行报告。
- [ASSET_CATALOG.md](ASSET_CATALOG.md) —— 美术风格、资产候选和许可证生命周期。
- [CHECKLIST.md](CHECKLIST.md) —— 进度证据索引；不单独决定阶段是否通过。
- [PLAYER_EXPERIENCE_AUDIT.md](PLAYER_EXPERIENCE_AUDIT.md) —— 2026-09-06 当前真实可用范围与缺口审计。
- `NEXT_PHASE*` / `M3_*` / `M4_*_NOTES` —— 历史阶段计划与实施证据，不再决定当前执行顺序。
- `*_DRAFT.md` / `REVIEW_*.md` —— 历史草稿与审查记录，仅用于追溯。

## 文档权威关系

1. `PRD.md`：产品目标、范围、里程碑和发布验收。
2. `PROJECT_EXECUTION_BASELINE.md`：从 PRD 派生的唯一执行顺序与 Gate；不得改写产品范围。
3. `RESEARCH_REPORT.md`：技术实现和生产方法。
4. `ASSET_CATALOG.md`：美术风格、候选和许可证政策。
5. `ART_PRODUCTION_PLAN.md`：从资产政策派生的生产清单、批次和美术验收。
6. `CHECKLIST.md`：只记录状态和证据，不允许凭自身勾选跳过 Gate。
7. 历史计划、草稿与审查文件：只用于追溯，不作为当前执行依据。

跨文档冲突由项目主理人拍板，并同步修改受影响的权威文档；冲突未解决前暂停实现。
