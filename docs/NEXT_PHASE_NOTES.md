# NEXT_PHASE 执行记录（M3 Gate Closure + Asset Pipeline）

> 建立/更新：2026-09-05
> 范围：docs/NEXT_PHASE.md 定义的 P0 平衡闭环 + P0 资产管线 + P1 验证门禁
> 约束执行：不改 PRD/RESEARCH_REPORT/ASSET_CATALOG/历史草稿；资产逐项核验许可证，不批量下载；无外发（GitHub push 已在会话外由用户确认执行）。

## 1. 标准模式构筑机制（完成）

- 新增 `scripts/boot/standard_builds.gd`（`class_name StandardBuilds`）：C01–C08 每关 3 套构筑
  （steady 稳健 / economy 经济 / synergy 相位·英雄协同），格式同 SMOKE_PLANS，含升级/模块选择。
- main.gd 新增命令行：
  - `--build=<steady|economy|synergy>`：标准构筑模式，**不使用 simulation_assist**；与 `--m3-smoke/--m3-perf` 同用会 push_error。
  - 标准构筑报告写到 `out/balance_<level>_<build>_speed<X>.json`，与辅助模式报告物理分离。
- 报告字段增强：`fail_reason`（integrity_depleted_wave_N / timeout_wave_N）、`leak_by_wave`、`leak_by_enemy`、
  `tower_stats`（每塔 id/节点/tier/模块/kills/投入火种）——失败原因可定位到具体波次与敌人。

## 2. 平衡分析与修正（完成，未改数值）

关键发现：**回声桩（tower_echo_pile）主 DPS 极弱**——链接伤害击杀不归属塔（kills=0），
将其当主 C 的构筑（C07 synergy v1–v3、C03 synergy v1）全部失败。修正方式是把回声桩降为减速/支援位，
DPS 由针轨弩台（削甲模块）+ 余烬喷井（集火模块）承担。**未修改任何关卡/波次数值**，
C04/C07 失败根因均为构筑不合理而非数值失衡。

## 3. 平衡验证结果总表（speed 3×，无辅助，24/24 通过）

| 关卡 | steady | economy | synergy | 迭代 |
|---|---|---|---|---|
| C01 | win 漏0 余20 | win 漏0 余20 | win 漏0 余20 | 一次通过 |
| C02 | win 漏7 余6 | win 漏10 余3 | win 漏8 余4 | economy 迭代到 v4（撤无效 0 号位、补 3/5 号位双路线覆盖） |
| C03 | win 漏10 余3 | win 漏3 余14 | win 漏10 余2 | synergy v1（回声主 C）lose → v2 win |
| C04 | win 漏5 余15 | win 漏7 余12 | win 漏5 余13 | synergy 迭代到 v3（弃回声主 C，风巢长程+喷井集火+削甲） |
| C05 | win 漏13 余4 | win 漏7 余12 | win 漏6 余12 | synergy 迭代到 v3（有效核心提前满级，消除后期闲置火种） |
| C06 | win 漏4 余15 | win 漏14 余2 | win 漏9 余5 | synergy v1（四回声）lose → v2 风巢主 C win |
| C07 | win 漏4 余12 | win 漏2 余16 | win 漏8 余8 | synergy 迭代到 v4（下路开闸前预置+削甲，砍 0 杀散塔） |
| C08 | win 漏4 余12 | win 漏2 余16 | win 漏5 余10 | synergy v1（四回声）lose → v2 Boss 集火 win |

证据：`out/balance_<level>_<build>_speed3.0.json` × 24（含 fail_reason / leak_by_wave / leak_by_enemy /
tower_stats 字段）。**未修改任何关卡/波次/塔数值**——所有失败均为构筑问题，经构筑迭代解决。

## 4. 标准模式固定 Tick 回归（通过）

steady 构筑 1× vs 3× 逐 tick 一致（标准模式、无辅助）：

| 关卡 | 1× ticks/kills/leaks/余完整度 | 3× ticks/kills/leaks/余完整度 | 一致 |
|---|---|---|---|
| C01 | 7080 / 90 / 0 / 20 | 7080 / 90 / 0 / 20 | ✅ |
| C04 | 13523 / 73 / 5 / 15 | 13523 / 73 / 5 / 15 | ✅ |
| C07 | 13467 / 74 / 4 / 12 | 13467 / 74 / 4 / 12 | ✅ |

证据：`out/balance_<level>_steady_speed1.0.json` 与 `speed3.0.json` 对照（sim_seconds 亦一致）。

## 5. CJK 字体锁定（完成）

- 候选：Ark Pixel Font 12px monospaced（catalog FT-CJK-001 / §10.2 已 Verified，OFL 1.1，允许商用）。
- 来源：`gh release download -R TakWolf/ark-pixel-font` v2026.09.01，
  zip sha256=`72c8550d76e3beebdb3a36bf99aaa27a83ba5569912c81822da4f8cdb719ae81`。
- 接入：`assets/fonts/ark-pixel-12px-monospaced-zh_cn.ttf`（sha256 `4f0cc9ae…`）设为
  `gui/theme/default_font`（zh_cn 变体内含 ASCII，无需 fallback 链）；latin 变体备用未启用。
  OFL 原文存 `licenses/ARK_PIXEL_FONT_OFL.txt`，台账 2 行已登记（ASSET_LICENSE_LEDGER.csv）。
- 缩放验证（新增 main.gd `--font-test` 模式）：12/15/18px（≈100%/125%/150%）中英混排渲染截图
  `out/font_ark_scales.png` + 度量 `out/font_ark_metrics.json`。12px 原生最锐利；15/18px 非整数倍
  略粗但完全可读，无豆腐块、无截断。游戏内 HUD 实机确认见 `out/asset_trial_c01_on.png`。
- **锁定决定**：UI 默认字体 = Ark Pixel 12px zh_cn；HUD 字号优先 12/24 整数倍，15/18 可用但避免用于小字正文。

## 6. C01 资产替换试验（完成，结论：管线可行 / 资产不默认启用）

- 候选：AT-TER-001 Buch Outdoor 32×32 Tileset（CC0，Verified，OGA 页 + 第三方印证）。
- 流程验证：逐项下载（非批量）→ sha256（`831785af…`）→ CC0 原文存 `licenses/CC0-1.0.txt` →
  台账登记 → 工程接入（GreyboxMap `--asset-trial` 开关，仅 C01 岸带/礁岛铺 3 块岩石 tile，夜紫 tint 压色）。
- 对比证据：`out/asset_trial_c01_on.png` / `out/asset_trial_c01_off.png`。
- **结论**：接入管线（下载→核验→台账→接入→截图→回退）全链路可行；视觉上纹理优于纯色但 3 tile 重复感明显、
  紫色调与 C01 黄昏暖色强调有轻微冲突（catalog 原注“需重涂为海主题”）。**决定：不默认启用**，
  保留 `--asset-trial` 开关与台账记录（replacement_status=trial-only），正式地形资产等待按主题重涂批次。

## 7. 最终回归（2026-09-05，收口前）

- 编辑器导入：0 error（Godot 4.7.2 `--editor --headless --quit`）。
- `tools/validate_data.gd`：PASS。
- `tools/run_tests.gd`：117/117 PASS。
- `tools/check_i18n.gd`：referenced=179 defined=204 missing=0。

## 8. 未完成的门禁（保持未勾，不伪装）

- M3 Gate 退出评审：人工门禁，未做。
- 手柄实机验证、低端机性能验证、5–15 人盲测：人工门禁，未做。
- 正式音频资产：仍为运行时合成占位（台账 status=not-final），未宣称完成。
- 正式地形/角色/塔像素资产：仅完成管线验证，未批量接入。
