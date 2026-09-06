# 历史阶段计划：M3 Gate Closure + Asset Pipeline

> 建立日期：2026-09-05
> 当前状态：Historical / 已被 `PROJECT_EXECUTION_BASELINE.md` 取代，不再决定执行顺序
> 原状态：Planned
> 目标：把现有 C01–C08 从“系统与表现已成型、仍有门禁缺口”推进到“标准难度可评估、正式资产可安全接入、M3 可以退出评审”。

## 为什么是这一阶段

当前工程的核心方向已经被试玩确认，继续新增英雄、敌人或地图会放大返工成本。当前最影响真实品质的不是系统数量，而是：

1. C04 / C07 在标准难度下的构筑与波次平衡不足；
2. 当前视觉仍是程序化占位，正式像素资产尚未进入安全可追溯的接入流程；
3. CJK 字体、正式音频、手柄实机、低端机性能和盲测仍没有证据；
4. M3 的最终退出门禁尚未满足。

## 阶段范围

### P0：平衡与可玩性闭环

- 为 C01–C08 建立“标准模式”固定构筑脚本，不使用 `simulation_assist`。
- C04、C07 先做波次/初始资源/BuildNode 可达性分析，再做最小数值修正。
- 每关验证至少 3 套不同思路的标准构筑：稳健、经济、相位/英雄协同。
- 保持固定 BuildNode + PathNetwork，不引入自由堵路或动态寻路。
- 建立每关平衡报告：漏怪波次、塔贡献、英雄贡献、剩余火种、航标争夺、失败原因。
- 将标准难度与测试辅助模式的报告彻底分开。

### P0：正式资产接入管线

- 从 `docs/ASSET_CATALOG.md` 中筛选少量候选，不批量下载。
- 先锁定 CJK 字体、UI 字体和基础像素尺寸，再接入角色/塔/地形。
- 每项资产进入 `ASSET_LICENSE_LEDGER.csv` 前必须保存来源 URL、作者、许可证原文、下载日期、文件 hash、署名文本和修改记录。
- 第一批只做 C01 的替换试验，验证风格、像素密度、轮廓可读性和 UI 缩放。
- 不满意时回退到程序化占位，不污染运行时数据契约。

### P1：验证门禁

- C01–C08 标准难度 smoke 与固定 Tick 回归。
- C04/C07 3 套标准构筑记录。
- CJK 字体在 640×360、125%/150% UI 缩放下截图验证。
- 音频事件接口接入至少一套可合法使用的临时音频；正式音乐/SFX 仍不宣称完成。
- 手柄实机验证、低端机性能验证、5–15 人盲测列为人工门禁。
- 修复 S0/S1 问题并生成 M3 Gate 报告。

## 不在本阶段

- 不扩展到 C09–C24。
- 不新增第三、第四名英雄。
- 不新增完整成长树、图鉴、成就和无尽模式。
- 不做 Steam 发布或商店页面外发。
- 不把候选资产写成 Shipping，不把自动 smoke 写成盲测结论。

## 退出条件

全部满足后才可将本阶段标记为 Done：

- [x] C04/C07 标准难度不使用辅助模式可完成（3 套构筑全 win，未改数值；NEXT_PHASE_NOTES §2/§3）
- [x] C01–C08 每关至少 3 套标准构筑有记录（`scripts/boot/standard_builds.gd` + `out/balance_*.json` × 24）
- [x] 平衡报告与失败原因报告已生成（NEXT_PHASE_NOTES §3 总表 + 每关 fail_reason/leak/tower_stats JSON）
- [x] CJK 字体候选完成实际缩放验证并做出锁定决定（Ark Pixel 12px zh_cn；NEXT_PHASE_NOTES §5）
- [x] C01 第一批正式资产替换试验完成，许可证证据齐全（AT-TER-001，trial-only；NEXT_PHASE_NOTES §6）
- [x] 资产台账中所有已接入资产均非 `Indirect` / `Not verified`（台账 16 行均 Verified/项目自有）
- [x] 标准模式固定 Tick / 1× / 3× 回归通过（C01/C04/C07 steady 1×=3× 逐 tick 一致）
- [x] M3 Gate 退出评审完成（条件通过；手柄实机/低端机/盲测保留为后续人工门禁，详见 M3_GATE_REVIEW.md）

## 当前证据与关联文件

- 表现增强记录：[M3_POLISH_NOTES.md](M3_POLISH_NOTES.md)
- 第一章内容记录：[M3_CHAPTER_NOTES.md](M3_CHAPTER_NOTES.md)
- 产品范围：[PRD.md](PRD.md)
- 技术路线：[RESEARCH_REPORT.md](RESEARCH_REPORT.md)
- 资产与许可：[ASSET_CATALOG.md](ASSET_CATALOG.md)
- 总进度：[CHECKLIST.md](CHECKLIST.md)

## 执行顺序

1. 标准模式构筑与 C04/C07 平衡分析
2. 平衡修正与全 C01–C08 回归
3. 字体锁定和 C01 资产接入试验
4. 音频/手柄/低端机/盲测人工门禁
5. M3 Gate 退出评审
6. 退出后才进入 M4 C09–C24 内容生产
