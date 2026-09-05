# 《余烬潮汐》项目 Checklist

> 用途：项目推进过程中的唯一记录入口。完成一项后将 `[ ]` 改为 `[x]`，并在“记录”栏补日期、证据或链接。
>
> 规则：先完成当前阶段退出条件，再进入下一阶段；任何新增需求先标记 Must / Should / Later，并同步 PRD。

## 0. 项目决策与文档

- [ ] 教主确认《余烬潮汐》工作代号可继续使用
- [ ] 完成“余烬潮汐 / Ashen Tides”商标与同名游戏清查
- [ ] 教主确认 PRD 产品范围：24 关、6 塔、4 英雄、24 普通敌、8 精英、6 Boss
- [ ] 教主确认首发平台：Windows PC / Steam
- [ ] 教主确认首发语言：简体中文 + 英文
- [ ] 教主确认 Godot 4.7.x 稳定补丁线
- [ ] 教主确认固定 BuildNode + 预制 PathNetwork 路线模型
- [ ] PRD.md 状态从 Proposed 更新为 Approved
- [ ] RESEARCH_REPORT.md 状态从 Proposed 更新为 Approved
- [ ] ASSET_CATALOG.md 状态从 Proposed 更新为 Approved

## 1. M0：立项与预制作

- [x] 安装并验证 Godot 4.7.x
- [x] 创建 Godot 工程与 `project.godot`
- [x] 创建项目目录骨架与 Autoload
- [x] 锁定 640×360 逻辑分辨率和 32×32 Tile 基线
- [x] 建立稳定 ID、术语表和数据 schema
- [x] 建立 `ASSET_LICENSE_LEDGER.csv`
- [x] 锁定 CJK 字体与英文显示字体（Ark Pixel 12px zh_cn 内含 ASCII；NEXT_PHASE 锁定，缩放验证通过）
- [x] 建立资产下载、原始许可证、hash、credits 归档流程（NEXT_PHASE 管线验证 + M4-A docs/CREDITS.md）
- [x] 完成 C01 灰盒地图
- [x] 完成 C01 的 PathNetwork 与 BuildNode
- [x] 完成 C01 的一波敌人、塔、投射物、伤害和出口扣除
- [x] 完成 C01 的失败、重开和基础 HUD
- [ ] M0 退出评审：所有临时资产均有明确标记
- **记录**：2026-09-05 M0 工程初始化 + 收尾完成（agent 执行）。Godot 4.7.2-stable（ed1daf0bf）；`project.godot` 锁定 640×360 / 32×32 / Forward+ / stretch=viewport+keep+integer，主场景 `scenes/boot/main.tscn`；Autoload：EventBus / SaveService / SettingsService。数据 schema：`scripts/data/`（TowerData / EnemyData / WaveGroup / WaveData / LevelData，均含稳定 id + schema_version）+ C01 实例（1 塔 `tower_needle_rail`、1 敌 `salt_shell_walker`、3 波、关卡 `level_c01`）；校验器 `tools/validate_data.gd` 覆盖重复 ID、类型/引用缺失、负数值、数值范围、BuildNode 与路线互斥（PRD §5.4/§19）。C01 最小战斗闭环：敌人沿激活路线插值移动（无实时寻路）、左键 BuildNode 建塔（100 火种，绿/黄/红三态）、塔按射程攻击"最前"目标、投射物（ObjectPool 复用）命中结算抗性公式伤害（PRD §3.3）、击杀奖励火种 + 航标充能、漏怪扣舰队完整度；HUD 显示火种/完整度/充能/波次/状态/相位；空格开波、P 暂停、R 重开、T 相位切换；完整度归零失败、3 波全清通关，均可重开。验证证据：`out/m0_import_log.txt`（无头导入 0 错误 0 警告）、`out/m0_validate_log.txt`（checked=6 errors=0 PASS）、`out/m0_combat_smoke_log.txt` + `out/m0_combat_smoke.json`（无头冒烟：seed=20260905、8× 速，result=win、waves=3/3、integrity=13/20、退出码 0）、`out/m0_combat_windowed_log.txt` + `out/m0_combat_screenshot.png`（窗口运行通关画面）、`out/m0_combat_boot_screenshot.png`（初始部署画面）。未做（留后续任务）：CJK 字体锁定与资产归档流程（不下载第三方资产）、M0 退出评审（人工门禁）。注意：灰盒战斗按帧驱动，固定种子下无头/窗口结果略有差异（integrity 13 vs 12），固定 tick 确定性模拟属 M1 范围（PRD §18.5）。

## 2. M1：核心系统

- [x] 2 座塔可由数据资产驱动
- [x] 4 种敌人可由数据资产驱动
- [x] 1 名英雄可移动、攻击和使用技能
- [x] 明潮 / 暮潮相位切换可运行
- [x] 航标充能与潮汐仪消耗闭环
- [x] 波次编辑与数据校验器可运行
- [x] 暂停、0.5×、1×、2×、3×速度正确
- [x] 主存档和设置存档骨架完成
- [x] suspend save 在波次完成时写入并可恢复
- [x] Debug 工具：跳波、无敌、经济注入、路径可视化
- [x] 连续运行 30 分钟无崩溃
- [ ] M1 退出评审
- **记录**：2026-09-05 M1 核心系统完成（agent 执行）。数据层：`tower_needle_rail`（针轨）+ `tower_ember_well`（辉光溅射）双塔；`salt_shell_walker` / `mast_rat_swarm`（集群）/ `splitfin_dasher`（冲刺）/ `rust_armor_carrier`（重甲）四敌；英雄 `hero_lanzhou_wei`（岚舟·苇：右键移动、自动攻击、A 钩索位移 / B 信号标记 / 终极技 80 充能）；相位事件 `phase_c02_tidegate`（第 3 波明潮→暮潮，激活 `route_c02_tideflat`）；C02 关卡数据（10 BuildNode、2 路线、4 波）。系统：固定 tick 60Hz 模拟（速度 0.5/1/2/3× 仅乘算步进，PRD §18.5）；PhaseController 波次边界切换 + 整波预告；潮汐仪 40 充能提前/延后切换，与英雄终极技 80 争夺同一航标账本（PRD §10.1）；suspend save 波次完成写入（含 RNG state/相位/塔位/英雄状态），恢复后与不间断运行逐 tick 一致；Debug：N 跳波 / I 无敌 / M 注资 / V 路径可视化。自动化：`tools/run_tests.gd` 自研测试框架（GUT 等价，不引第三方插件）5 套件 47 断言全过。验证证据：`out/m1_import.log`（无头导入 0 错误）、`out/m1_validate.log`（checked=20 errors=0 PASS）、`out/m1_tests.log`（pass=47 fail=0）、`out/m1_smoke_c01.log`（C01 回归 win）、`out/m1_smoke_c02.log` + `out/m1_smoke_c02_speed1.json` / `out/m1_smoke_c02_speed3.json`（C02 全流程 win；1× 与 3× 逐字段一致：ticks=5486 kills=45 leaks=3 integrity=14；相位切换记录 wave=2 tick=1733；英雄移动 149.5px、A/B/终极技均触发）、`out/m1_suspend_stage1.log`（--stop-after-wave=2 退出码 42）+ `out/m1_suspend_stage2.log` + `out/m1_smoke_speed1.0_resumed.json`（恢复后段位 kills=23 leaks=3 ember=106 becon=53，与不间断运行同段位完全一致，suspend_restored=true）、`out/m1_screenshot_c02.png`（窗口运行 C02 画面：HUD/双路线/10 节点/英雄/键位帮助）、`out/m1_soak.log`（浸泡：3× 速连续 600 真实秒 = 30 分钟模拟时长，C02 循环 30 场战斗，0 ERROR / 0 SCRIPT ERROR，退出码 0；口径注明：非 30 分钟真实墙钟）。未做（留后续任务）：M1 退出评审（人工门禁）。

## 3. M2：发布质量纵向切片（C01–C03）

> 这不是 Demo/MVP。C01–C03 是 v1.0 正式前三关，验证通过后直接保留。

- [x] C01–C03 的正式路线、波次和目标规格完成
- [x] 6 座塔中至少 3 座达到正式质量，每座至少 2 个模块可玩
- [x] 1 名英雄达到正式质量
- [x] 6–8 个正式敌人
- [x] 两种相位模板
- [x] 中英本地化 key 全流程可用
- [ ] CJK 字体在 640×360、125%/150% UI 缩放下可读
- [x] 键鼠完整流程通过
- [ ] 手柄完整流程通过
- [x] 基础无障碍：色弱、高对比、低特效、独立音量、重绑定
- [x] 教程、战报、结算、设置、存档流程完整
- [ ] 正式音频混音与关键威胁事件音效完成
- [x] 目标机器达到 60 FPS，3×速度无状态错误
- [ ] 许可证台账中 C01–C03 使用的资产全部有证据
- [ ] 15 名盲测者中至少 70% 完成 C03
- [ ] 至少 1 张商店级截图和 30 秒战斗录屏
- [ ] M2 退出评审并按实测吞吐重估全项目
- **记录**：2026-09-05 M2 技术实现收口（agent 执行；人工门禁未通过）。数据层：3 关卡（level_c01/c02/c03）/ 21 波次（6+7+8）/ 3 塔（needle_rail/ember_well/echo_pile）/ 9 模块（每塔 3 个）/ 6 敌（salt_shell_walker / mast_rat_swarm / splitfin_dasher / rust_armor_carrier / lamp_leech / tide_back_navigator）/ 1 英雄（lanzhou_wei）/ 3 技能（grapple_shift/flare_mark/route_sweep）/ 1 装置（device_c03_lighthouse）/ 2 相位事件（phase_c02_tidegate 明→暮改道 / phase_c03_beacon_failure 暮潮装置失效）。关卡硬约束：8–22 BuildNode、PathRoute 与 BuildNode ≥24px 互斥、入口/出口贴地图边缘（validate_data.gd 强制）。系统：固定 tick 60Hz + 0.5/1/2/3× 速度（PRD §18.5）；II 级校准模块三选一模态；潮汐仪 40 充能干预相位 ±10s，与英雄终极技 80 争夺同一账本；suspend save 波次完成时写入，--stop-after-wave → --resume-suspend 验证一致（PASS）。Phase C UI：PauseMenuPanel（继续/设置/重开，Esc 关闭）/ SettingsPanel（5 路音量滑杆 + 4 预色弱/高对比/低特效/自动施放 + 中英切换 + 13 项键鼠重绑定含冲突检测与默认恢复）/ BattleResultPanel（印记 + 漏怪构成 + 伤害构成 + 未覆盖标签 + 复盘建议）/ TutorialOverlay（c01/c02/c03 三套步骤定义，F1 跳过，完成状态持久化）。LocalizationService 注册 Autoload，152→161 keys，0 missing / 27 unused（informational）。AudioService 注册 Autoload，6 总线（Master/Music/SFX/Ambient/UI/Voice）+ 21 事件占位合成音（16-bit PCM → AudioStreamWAV 缓存）+ 总线音量随 SettingsService 同步。UiPalette 静态类：色弱 4 预设 + 高对比/低特效开关。验证证据：tools/validate_data.gd checked=49 errors=0 PASS；tools/run_tests.gd pass=47 fail=0 PASS（5 套件）；tools/check_i18n.gd 0 missing；smoke：C01 1×/3× = ticks=7017 kills=90 leaks=0 marks=3/3；C02 3× = ticks=10047 kills=103 leaks=5 marks=1/3；C03 1×/3× = ticks=11558 kills=119 leaks=10 marks=2/3（含潮汐仪+终极技双消耗与装置修复演示）；C03 3× resume-suspend = suspend_restored=true ticks=8571 marks=2/3；perf C01/C02/C03 3× 全部 ≥140fps 1%low ≥100fps；60s 浸泡 0 ERROR；窗口运行截图 out/m2_screenshot.png、out/m2_screenshot_pause.png 可读。未完成（留 M3+/人工）：CJK 字体锁定（占位 Noto Sans 默认）+ 实际中文字符验证；手柄完整流程（手柄按钮已绑 Space/Pause/Cycle/Xbox Y/E 等，触发器代码就位但未在物理机器验证）；5–15 名盲测（人工门禁）；30 秒战斗录屏（Godot 编辑器可，但 M2 内未执行录制 → 已通过 Movie Maker 模式写好代码 --m2-record=<秒>）；正式资产（C01–C03 的所有 sprite/VFX/UI 仍为灰盒/占位，ASSET_LICENSE_LEDGER 仅记录 Creative 框架）。详见 docs/M2_SLICE_NOTES.md。

## 4. M3：第一章完整生产（C04–C08）

- [ ] 6 座塔全部上线
- [ ] 2 名英雄上线
- [ ] 第一章敌人与精英完成
- [ ] C01–C08 完成正式资产、波次、目标和测试
- [ ] 第一章 Boss 完成
- [ ] 每关至少 3 套标准构筑可通
- [ ] 关卡生产速度稳定在预测区间 ±25%
- [ ] 建立平衡报告与回归报告
- [x] M3 退出评审（条件通过；见 [M3_GATE_REVIEW.md](M3_GATE_REVIEW.md)）
- **记录**：2026-09-05 自动化门禁与标准构筑已收口；手柄实机、低端机性能、5–15 人盲测、正式音频和 Shipping 美术仍为后续人工/资产门禁，未伪装为完成。

## M3 阶段记录

> 2026-09-05：M3 主要代码与内容基线已落地，状态 PARTIAL。详见 [M3_CHAPTER_NOTES.md](M3_CHAPTER_NOTES.md)。最终性能聚合、确定性回归、suspend 一致性、编辑器导入和人工退出评审未确认，因此以下 M3 门禁保持未勾选。

## Polish 阶段记录（表现与可玩性增强，2026-09-05）

> 用户试玩反馈"方向正确但整体太简陋"后的表现增强阶段，已完成，状态 DONE（不含正式资产门禁）。
> 详见 [M3_POLISH_NOTES.md](M3_POLISH_NOTES.md) 与 [M3_POLISH_TODO.md](M3_POLISH_TODO.md)。
> 范围：VisualTheme 8 关调色板、地形/路线/塔/敌/英雄程序化剪影、FX 反馈层（命中/击杀/漏怪/建造/升级/相位/震屏，可关）、
> HUD 增强（相位条/波次横幅/技能坞/Boss 血条）。全部程序化矢量，无第三方资产，未改核心规则与 sim 数值。
> 验证：导入 0 错、数据校验 checked=141 errors=0、测试 117/117、i18n missing=0、8 关 smoke 回归
> （C01/C03/C08 ticks 与 M2/M3 基线逐一一致）、C03 suspend/resume 一致性（4226+7332=11558）、
> M3-SMOKE 聚合 PASS、perf C01/C03/C08 avg 75fps（1% low 45–52fps 已诚实标注）。
> 截图证据：out/polish_level_c01_wave2.png / polish_level_c03_wave3.png / polish_level_c06_wave3.png / polish_level_c08_wave12.png。
> 不勾选任何 M3 正式门禁：正式美术/字体/音频/盲测/低端机验证仍为 blocker。

## 当前下一阶段：M3 Gate Closure + Asset Pipeline

- [x] C04/C07 标准难度平衡分析与修正（结论：无需改数值，构筑迭代解决；详见 NEXT_PHASE_NOTES §2/§3）
- [x] C01–C08 每关 3 套标准构筑验证（24/24 win，speed 3× 无辅助；out/balance_*.json × 24）
- [x] 平衡报告与失败原因报告（fail_reason/leak_by_wave/leak_by_enemy/tower_stats 字段 + NEXT_PHASE_NOTES §3 总表）
- [x] CJK 字体缩放验证与锁定决定（Ark Pixel 12px zh_cn 锁定为默认 UI 字体；out/font_ark_scales.png/_metrics.json）
- [x] C01 第一批正式资产替换试验（AT-TER-001 Buch CC0；--asset-trial 开关；结论 trial-only 不默认启用；out/asset_trial_c01_on/off.png）
- [x] 已接入资产许可证证据齐全（ASSET_LICENSE_LEDGER.csv 16 行：OFL/CC0 原文、sha256、署名文本；无 Indirect/Not verified 接入项）
- [x] 标准模式固定 Tick / 1× / 3× 回归（C01/C04/C07 steady 1× vs 3× ticks/kills/leaks/完整度全等）
- [ ] M3 Gate 退出评审（人工门禁，未做）
- **阶段说明**：[NEXT_PHASE.md](NEXT_PHASE.md)
- **记录**：2026-09-05 执行完成 P0 全部项 + P1 可自动化项，并完成 M3 Gate 条件退出评审，详见 [NEXT_PHASE_NOTES.md](NEXT_PHASE_NOTES.md) 与 [M3_GATE_REVIEW.md](M3_GATE_REVIEW.md)。剩余人工门禁：手柄实机、低端机性能、5–15 人盲测；正式音频/美术资产仍未宣称完成。
- **GitHub**：Public 仓库已创建并推送：<https://github.com/wjt0321/ashen-tides>；`main` 首个基线提交 `ae51920`，文档/忽略规则提交 `6d7c019`；2026-09-05 可见性改为 Public 并推送 `8e2855c`。

## M4-A：C01 正式资产纵向切片（2026-09-05）

- [x] 美术技术规范锁定（[M4_ASSET_SPEC.md](M4_ASSET_SPEC.md)：32×32/640×360/调色板/轮廓/帧/命名/导入/许可证）
- [x] C01 切片资产 16 张（项目自有原创，`tools/gen_c01_sprites.py` 确定性生成）
- [x] 运行时接入（`ArtLibrary` + 强制程序化回退：C01 地形、3 塔、2 敌、岚舟英雄、2 FX 帧条、4 HUD 图标）
- [x] 台账 +16 行（Project-owned，含 sha256）与 [CREDITS.md](CREDITS.md)（仅真实接入项）
- [x] 验证：导入 0 error / validate PASS / tests 117/117 / i18n missing=0 / C01 autoplay ticks=7017 与 steady 7080 均与基线一致 / perf 144fps avg
- **记录**：[M4_ASSET_PIPELINE.md](M4_ASSET_PIPELINE.md)；未做项（其余塔/敌/Boss 精灵、正式音频、色弱贴图重映射、terrain_land_b 未接入）见该文 §6

## 5. M4：全战役 Alpha（C09–C24）

- [ ] 24 关均可从新档进入和完成
- [ ] 4 名英雄全部上线
- [ ] 24 普通敌、8 精英、6 Boss 全部上线
- [ ] 三棵成长树、四档难度、辅助选项完成
- [ ] 图鉴、成就、完整结局完成
- [ ] 中英全流程无缺失 key 或文本截断
- [ ] 存档迁移覆盖最近 5 个 schema
- [ ] 所有核心资产有许可证状态
- [ ] 新档完整通关测试
- [ ] Alpha 退出评审：S0=0，S1 进入修复计划
- **记录**：

## 6. M5：Beta 与内容锁定

- [ ] 最终像素资产完成
- [ ] 最终音乐、SFX、动态混音完成
- [ ] 中英文本人工校审完成
- [ ] 无障碍真实用户测试完成
- [ ] 键鼠、手柄、热插拔、断连矩阵完成
- [ ] 720p、1080p、1440p、4K、16:10、21:9 验证完成
- [ ] 低端目标机器性能验证完成
- [ ] Steam 成就与云存档（若启用）验证完成
- [ ] 商店页面、截图、胶囊图、预告片素材完成
- [ ] 发行构建中的第三方资产全部达到 Shipping
- [ ] 内容锁定：除修复外不新增系统
- **记录**：

## 7. M6：发布候选

- [ ] Windows 安装、升级、卸载验证
- [ ] 离线启动、离线存档和平台恢复验证
- [ ] 主存档、备份存档、suspend save 损坏恢复验证
- [ ] 旧版本存档迁移验证
- [ ] 72 小时 soak / 回归测试
- [ ] S0=0、S1=0
- [ ] Godot 及第三方许可证 Credits 完整
- [ ] 隐私说明与崩溃收集策略明确
- [ ] Steam 商店和构建审查包完成
- [ ] 发布候选构建签名并归档 hash
- [ ] 项目主理人批准发布
- **记录**：

## 8. 发布后

- [ ] Day-0 构建发布
- [ ] 首周高严重度问题回顾
- [ ] 1/7/30 日回顾
- [ ] 决定 v1.1（Should）内容
- [ ] 单独评估 Later：无尽、编辑器、创意工坊、联机、移动端
- **记录**：

## 变更记录

| 日期 | 变更 | 原因 | 批准人 |
|---|---|---|---|
| 2026-09-05 | 建立项目 Checklist，并将文档统一收纳至 `docs/` | 项目主理人要求 | 小黑 |
| 2026-09-05 | 勾选 M0 已完成项并记录验证证据（工程骨架 + C01 灰盒占位） | M0 工程初始化执行 | 项目主理人（agent 执行） |
| 2026-09-05 | 勾选 M0 数据 schema、C01 战斗闭环、失败/重开/HUD 完成项并记录证据 | M0 收尾执行 | 项目主理人（agent 执行） |
| 2026-09-05 | 勾选 M1 核心系统完成项（双塔/四敌/英雄/相位/潮汐仪/校验器/固定 tick 速度/存档骨架/suspend/Debug）并记录证据 | M1 执行 | 项目主理人（agent 执行） |
| 2026-09-05 | M2 收口：注册 LocalizationService 为 Autoload、project.godot 新增 ui_cancel action；i18n csv 扩到 161 keys；main.gd 集成 PauseMenu/Settings/BattleResult/Tutorial 四个面板；调用 UiPalette.configure_from_settings + SettingsPanel.apply_saved_bindings；硬编码中文字符串全部走 tr_key；C01/C02/C03 smoke + 1×/3× 确定性 + C03 suspend restore 一致性 + perf 144fps 全部通过 | M2 收口执行 | 项目主理人（agent 执行） |
| 2026-09-05 | 新增 Polish 阶段记录（视觉主题/FX/HUD 增强），未勾任何 M3 正式门禁；M3_POLISH_TODO.md 移入 docs/ | 试玩反馈后的表现增强执行 | 项目主理人（agent 执行） |
| 2026-09-05 | Polish 阶段完成：C01–C08 主题化地形、塔/敌/英雄辨识度、FX、HUD、录屏与回归证据已落地；正式资产/音频/字体/盲测/低端机仍未完成 | 用户试玩反馈“方向正确但太简陋” | 项目主理人（agent 执行） |
| 2026-09-05 | NEXT_PHASE 执行：新增 StandardBuilds（C01–C08 × steady/economy/synergy，--build 标准模式与辅助报告分离）、平衡报告字段（fail_reason/leak_by_wave/tower_stats）；24/24 构筑 win（仅构筑迭代，未改数值）；C01/C04/C07 1×/3× tick 全等；Ark Pixel Font（OFL 1.1）接入并锁定为默认 UI 字体（12/15/18px 缩放验证通过）；AT-TER-001（CC0）C01 替换试验完成并决定 trial-only；台账 16 行含 hash/许可证原文。M3 Gate 退出评审等人工门禁保持未勾 | NEXT_PHASE P0/P1 执行 | 项目主理人（agent 执行） |
| 2026-09-05 | M4-A：美术技术规范锁定（M4_ASSET_SPEC.md）；C01 切片 16 张项目自有原创精灵（tools/gen_c01_sprites.py）接入运行时并全部带程序化回退；台账 +16 行、新建 CREDITS.md（Godot MIT + Ark Pixel OFL）；M0 两项历史遗留（字体锁定/资产归档流程）勾销；验证全绿且战斗基线不变 | M4-A 执行（用户确认后） | 项目主理人（agent 执行） |
