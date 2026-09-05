# M4-A 记录：C01 正式资产纵向切片 + 美术技术规范锁定

> 建立：2026-09-05
> 前置：M3 Gate 有条件通过（docs/M3_GATE_REVIEW.md）；NEXT_PHASE 收口（docs/NEXT_PHASE_NOTES.md）
> 约束执行：不改 PRD/RESEARCH_REPORT/ASSET_CATALOG；不做手柄/多人/盲测；不扩展 C09–C24；不 push。

## 1. 规范锁定

`docs/M4_ASSET_SPEC.md`：32×32 像素基线 / 640×360 整数倍缩放 / 调色板与轮廓规则 /
动画帧（4 帧行走、FX 帧条、tick 对齐）/ 命名与目录（与数据层 id 一致）/ 导入规则（Nearest、
导入验证、程序化回退强制）/ 许可证硬门槛（Indirect 不得接入、禁止伪造 Shipping）。

## 2. C01 切片资产（全部项目自有原创，16 张）

- 生成工具：`tools/gen_c01_sprites.py`（PIL；确定性 seed，可重生成）。
- 产出：地形 4（c01 sea_a/b、land_a/b）、塔 3（needle_rail/ember_well/echo_pile）、
  敌人 2（salt_shell_walker/mast_rat_swarm，即 C01 实际出场敌）、英雄 1（lanzhou_wei）、
  FX 2（muzzle_flash_strip3 / hit_spark_strip4）、UI 图标 4（ember/integrity/becon/wave）。
- 预览：`out/m4a_sprite_sheet_preview.png`。

## 3. 运行时接入（全部带程序化回退，规范 §6）

- 新增 `scripts/core/art_library.gd`（ArtLibrary 静态加载层，缺失文件 → null → 回退矢量绘制）。
- 接入点：
  - `greybox_map.gd`：C01 海底/陆地 tile 平铺（其余关卡自动回退程序化）；
  - `greybox_tower.gd`：塔精灵 + muzzle flash 3 帧条；
  - `greybox_enemy.gd`：敌人精灵（modulate 表达减速/受击闪白；无精灵敌人如锈甲搬运兽自动回退剪影）；
  - `greybox_hero.gd`：英雄精灵（倒地变暗）；
  - `fx_layer.gd`：命中火花 4 帧条；
  - `main.gd` HUD：火种/完整度/航标/波次图标（缺失则纯文本）。
- 截图证据：`out/m4a_c01_wave3.png`（塔/敌/地形/图标）、`out/m4a_c03_wave4_sprites.png`（英雄/跨关回退）。

## 4. 许可证与台账

- 台账 `ASSET_LICENSE_LEDGER.csv` +16 行（Project-owned original，含 sha256 与生成工具）。
- `docs/CREDITS.md` 建立：Godot MIT + Ark Pixel OFL（真实接入项）+ Buch 试验性说明。

## 5. 验证结果

- 编辑器导入 0 error；`validate_data.gd` PASS；`run_tests.gd` 117/117 PASS；`check_i18n.gd` missing=0。
- C01 smoke（默认 autoplay）：win，ticks=7017，与 M2/M3 基线一致（资产层不影响战斗逻辑）。
- C01 steady 标准构筑（无辅助）：win 漏0 余20，ticks=7080——与 NEXT_PHASE 基线逐字段一致。
- C01 perf（3×）：avg 6.97ms（144fps），1% low 15.38ms（65fps）（`out/m2_perf_level_c01.json`）。
- 战斗行为零变化：smoke ticks 与既有基线逐一相同（7017/7080/11558），证明精灵层纯视觉。

## 6. Blockers / 未做（如实保留）

- 其余三塔（wind_nest/tide_anvil/prism_grove）、其余 10 种敌人、全部 Boss、C02+ 地形：无正式精灵，
  保持程序化剪影回退（接入层已就绪，逐批生产即可）。
- 正式音频（音乐/SFX）：仍运行时合成占位，未宣称完成。
- 色弱重映射对精灵贴图仅部分生效（modulate 通道）：需在 M4 后续批次做调色板变体或 shader 方案。
- 手柄实机/低端机/盲测：按 M3 Gate 决议留发行前人工门禁。
- terrain_land_b 已生成未接入（陆地斑块仍程序化），台账标 staged。
