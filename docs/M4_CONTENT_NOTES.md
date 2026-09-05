# M4-C：第二章首批 C09–C12 可玩内容切片（2026-09-06）

> 基线：本地提交 `db46839`（M4-B 后）。范围严格限 C09–C12，不提前补 C13–C24。
> 依据：docs/PRD.md §5.3 蓝图（C09 交叉路/隐匿侦测、C10 双路/孢子治疗、C11 镜像双路/双相抗性/铸潮砧、C12 汇流路/可破坏掩体）与 §5.4 硬约束（每关 12–20 波、BuildNode 8–22、节点距路线 ≥24px、每关首引 ≤1 系统 + 2 敌）。

## 1. 新增机制（运行时，全部数据驱动）

| 机制 | 数据入口 | 运行时 | 关卡 |
|---|---|---|---|
| 隐匿/侦测 | `EnemyData.stealthed` | `GreyboxEnemy.reveal()/is_targetable()`；塔/英雄/回声链/投射物全部走 `is_targetable()`；隐匿时半透明绘制；揭示=侦测装置脉冲或英雄标记 | C09 |
| 治疗光环 | `EnemyData.heal_radius/heal_per_sec` | `main._apply_support_auras(dt)` 同环治疗友军（沉默抑制，封顶 max_hp） | C10 |
| 双相抗性 | `EnemyData.phase_resist_swap` | `take_damage` 内暮潮时 armor↔glow_resist 互换；`current_phase` 由战斗场景每 tick 注入 | C11 |
| 掩体阻挡 | `DeviceData.max_hp/blocks_projectiles` + `effect_op=cover` | `GreyboxProjectile._check_blockers()` 三种弹道统一；掩体承伤可摧毁、残骸不阻挡；存档往返含 hp/destroyed | C12 |
| 侦测装置 | `effect_op=reveal_pulse` | `GreyboxDevice._pulse` 新分支：揭示半径内隐匿敌 effect_value 秒 | C09 |
| 孢子扩散区 | `effect_op=spore_heal` | 敌方治疗场，每跳治疗半径内敌军 | C10 |

约束遵守：第一章既有敌人零行为变化（salt_mender 仍无治疗字段，C01–C08 基线不动）；新字段全部默认值关闭。

## 2. 关卡/波次/敌人数据

- 4 关 LevelData：`data/levels/level_c09..c12.tres`（chapter_index=2，12 波/关，节点 15/16/16/17）。
- 48 个 WaveData：`data/waves/wave_c09..c12_*.tres`（生成器 `tools/gen_m4c_data.py`，几何自检内置）。
- 3 个新敌人：`reed_stalker`（隐匿）、`spore_mender`（治疗）、`mirror_shade`（双相），稳定 id + i18n key。
- 6 个装置：C09 玻璃棱镜（reveal_pulse）、C10 孢子区 ×2（spore_heal）、C12 船壳掩体 ×3（cover，220/220/180 耐久）。
- 5 个相位事件：C09/C10/C12 单次明→暮（C09/C12 激活第二路线），C11 两次（明→暮→明，配合双相反转）。
- i18n：ui.csv +14 keys（LEVEL/OBJ/ENEMY/DEVICE），zh_CN+en 双语。

## 3. 标准构筑（StandardBuilds）

每关 steady / economy / synergy 三套，标准模式（无 simulation_assist）。
结果与 ticks 见 §5 验证记录（本文件回填）。

## 4. 视觉（沿用 M4 锁定规范）

- `visual_theme.gd` THEMES +4（玻璃沼泽章节：青碧/孢绿/银蓝/锈绿）。
- `tools/gen_chapter2_sprites.py`：16 张主题地形 + 3 张敌人精灵 + 9 张色弱变体（项目自有原创，确定性）。
- `greybox_map.gd._draw_level_flavor` +4 关装饰（玻璃苇丛/孢囊/镜面纹/断桅）。
- 台账 `ASSET_LICENSE_LEDGER.csv` +19 行；CREDITS 已更新。

## 5. 验证记录

- 数据校验：validate checked=207 errors=0（M4-C 新增自动覆盖，零工具改动）。
- 单元测试：179/179 PASS（新增 `tests/unit/test_m4c_content.gd` 62 项：数据契约 + 隐匿索敌/双相反换/装置三 op/掩体存档往返 + 第一章敌人不变式）。
- i18n：referenced=193 missing=0。
- smoke/平衡/perf：见下表；性能为窗口模式 3× 全场统计。

| 关卡 | autoplay | steady | economy | synergy | perf avg / 1% low |
|---|---|---|---|---|---|
| C09 | win 145杀 漏0 (ticks=14208) | win 漏0 (13447) | win 漏3 (13767) | win 漏0 (13692) | 74.9 / 59.2 FPS |
| C10 | lose（既定难度定位，同 C04/C07） | win 漏8 (16639) | win 漏6 (15966) | win 漏7 (16572) | 74.9 / 62.5 FPS |
| C11 | lose（既定） | win 漏6 (15523) | win 漏4 (15187) | win 漏0 (15409) | 74.7 / 50.5 FPS |
| C12 | lose（既定） | win 漏1 (18952) | win 漏0 (17814) | win 漏1 (19113) | 74.9 / 64.3 FPS |

- 12/12 标准构筑（4 关 × steady/economy/synergy）全部 win，无 simulation_assist。
- 迭代记录：C10 三构筑各补强一轮（steady/economy/synergy v2→v3，仅加塔与升级，未改任何关卡/敌人数值）；
  C09 synergy v1 误用本关未开放的 prism_grove 导致 0 塔停摆，v2 改用风巢+喷井+回声后通过（此错误已修正并验证）。

## 6. Blockers / 未做（如实保留）

- C13–C14（召唤敌/Boss 2「沼冠孢王」）未做，第二章未闭合；Boss 2 精灵未生成。
- C09–C12 autoplay（生成式计划）按既定定位为 lose（与 C04/C07 一致）；通关凭证以三套标准构筑为准。
- 掩体仅阻挡投射物，不作为敌人掩蔽所（PRD「掩体供敌」语义留待后续章节）。
- 精英敌人本章未新增（PRD 精英考核在 C13）。
- 正式音频/手柄实机/盲测：维持既有门禁状态，不在本轮范围。
- 固定 Tick 确定性已补齐：C04–C12 steady 1×/3×聚合 `failures=0 PASS`；性能报告也已补齐，C04–C12 聚合 `failures=0 PASS`。证据：`out/m4c_gate_regression.log`、`out/m4c_gate_perf_aggregator.log`。
