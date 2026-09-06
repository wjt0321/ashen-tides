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

---

# M4-D：第二章收口 C13–C14 + 精英 + Boss 2（2026-09-06）

## 1. 新增机制（运行时，数据驱动，默认关闭零回归）

- 召唤敌：`EnemyData.summon_enemy_id` + `summon_interval_seconds`（默认 0 = 不召唤，前章敌人零行为变化）。
  `GreyboxEnemy` 固定 tick 确定性计时（不经 RNG），到点 `summon_requested` 信号；main 处理器让子怪沿
  召唤者同路线、从其位置稍后 14px 里程出生（`setup()` 新增可选 `spawn_progress_px`，默认 0 不影响既有调用）。
  击杀本体即停止召唤；沉默抑制召唤（与支援光环同规则，断响反制）。击杀/漏怪走正常信号计入战报。
- 精英：marsh_mist_physician「雾中医正」——elite + regenerating 词缀 + 强化治疗光环（PRD §8.7 #3 最小实现，无留孢区）。
- Boss 2 `boss_marsh_crown_spore_king`「沼冠孢王」（PRD §8.8 最小改动三件套）：
  ①孢巢供疗 = 3 个 spore_heal + blocks_projectiles + max_hp=260 装置（打巢 = 分火，复用 M4-C 掩体管线）；
  ②根系改道 = wave 6 相位事件激活第二路线（现成机制）；
  ③短暂暴露核心 = boss_phases 的 armor_bonus 负值窗口（phase 1 −25 / phase 3 −15），无长时间无敌回血。

## 2. 关卡/波次/敌人数据（tools/gen_m4d_data.py，确定性幂等，几何自检内置）

- C13「雾母腹地」：三入口 / 18 节点 / 双雾透镜视野脉冲 / 召唤敌 + 隐匿敌；wave 4 相位开第三入口。考核：本体识别。
- C14「沼冠孢王」（Boss 场）：双路线 / 16 节点 / 三孢巢分火 / wave 6 根系改道 / wave 12 Boss 2。考核：分火管理。
- 3 新敌人 + 5 装置 + 2 相位事件 + 24 波次 + 2 LevelData；i18n +9 keys（zh_CN+en）。
- 调波记录（仅 C14 波次构成，未动任何敌人数值）：v1 w1 即 380hp/70 甲 carrier 开场，三套构筑 w1–4 固定漏 10；
  v2 改为 spitter/sapper 开场、carrier w3 起少量递进（总量 40→28）。

## 3. 标准构筑（StandardBuilds）

- C13：steady（13267 漏5）/ economy（13349 漏7）/ synergy（14697 漏14）全 win。
- C14：steady（21015 漏9）/ economy（21386 漏8）/ synergy（21357 漏9）全 win。
- 构筑迭代记录（均未改敌人数值）：C14 steady v1–v4（v1 物理打 70 甲漏 carrier → v3 喷井辉光主战；
  b 路 14/15 南侧射击线避开孢巢 C 投射物封锁）；C14 economy v5 补 12 号位喷井；C13 economy v2 补顶排反隐覆盖。
- C14 autoplay（生成式计划）lose 为既定难度定位（同 C04）：第二章收官 Boss 场；通关凭证为三套标准构筑。
  m3_smoke 聚合器据此不含 level_c14（注释在 tools/m3_smoke.gd）。

## 4. 视觉（沿用 M4 锁定规范）

- `visual_theme.gd` THEMES +2（雾母腹地灰绿雾 / 沼冠孢王深沼紫冠）。
- `tools/gen_chapter2b_sprites.py`：地形 ×8 + 单位 ×3（含 64×64 Boss 2）+ 色弱变体 ×9，项目自有原创确定性生成。
- 台账 +11 行、CREDITS 同步；预览 `out/m4d_sprites_preview.png`。

## 5. 验证记录

- 导入 0 错误；validate checked=243 errors=0（+36：3 敌 + 5 装置 + 2 相位 + 24 波 + 2 关）。
- 单元测试 234/234 PASS（新增 `tests/unit/test_m4d_content.gd` 55 项：C13/C14 契约、召唤计时确定性、
  沉默抑制召唤、出生里程、Boss 暴露窗口/护盾回复、Boss 末波出场）。
- i18n：referenced=202 defined=227 missing=0。
- 固定 tick 确定性：C13 steady 1×=3×=13267 ticks / 127 杀 / 漏5 / 完整度 15；C14 steady 1×=3×=21015 / 90 / 漏9 / 3——
  召唤机制逐 tick 一致。
- C14 suspend/resume：wave 6 中断 + steady 恢复通关（完整度 3，证据 `out/balance_level_c14_steady_speed3.0_resumed.json`）。本轮修复恢复路径错误使用 generated plan 的问题；标准构筑现在通过 `_resolve_smoke_plan()` 在首次运行与恢复时使用同一计划。
- perf：见下表（--m2-perf 3× 全场）。

| 关卡 | autoplay | steady | economy | synergy | perf avg / 1% low |
|---|---|---|---|---|---|
| C13 | win 119杀 漏14 (14631) | win 漏5 (13267) | win 漏7 (13349) | win 漏14 (14697) | 143.7 / 80.3 FPS |
| C14 | lose（既定，同 C04） | win 漏9 (21015) | win 漏8 (21386) | win 漏9 (21357) | 143.8 / 77.6 FPS |

## 6. Blockers / 未做（如实保留）

- C14 autoplay lose（既定难度定位，见 §3）；C04 autoplay lose 为历史既知，m3_smoke 聚合器该项 FAIL 维持原状。
- 「雾中医正」未实现留孢区（PRD §8.7 #3 完整语义）；孢巢供疗对 Boss 的加成幅度小（半径 40 接触窗口短）。
- C15+、第三/四章内容未做；正式音频/手柄实机/盲测维持既有门禁。
- 台账 M4-C 遗留一行重复记录（sprite_enemy_mirror_shade 双份），待下轮清理，不影响列数校验。
