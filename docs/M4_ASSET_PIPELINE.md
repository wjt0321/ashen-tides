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

---

# M4-B：第一章 C01–C08 正式资产扩展（2026-09-06）

## 1. 盘点结果（C01–C08 实际使用 id）

- 塔 6：needle_rail / ember_well / echo_pile / wind_nest / tide_anvil / prism_grove
- 英雄 2：lanzhou_wei / zhushou_muen
- 敌人 11（waves 实际引用）：salt_shell_walker、mast_rat_swarm、splitfin_dasher、rust_armor_carrier、
  lamp_leech、tide_back_navigator、brine_spitter、reef_sapper、salt_mender、tideglass_runner、
  anchor_crab_king（Boss，64×64）
- `anchor_crab_guardian`：EnemyData 存在但 C01–C08 无 wave 引用（仅剪影分支），**未生成精灵**，记为"数据存在未出场"。

## 2. 生成器与产出

- 新增 `tools/gen_chapter1_sprites.py`（PIL，固定 seed 确定性生成，可复现）。
- 产出：C02–C08 主题地形 28 张（sea_a/sea_b/land_a/land_b × 7，调色板逐关对齐 `visual_theme.gd` THEMES）；
  单位 13 张（3 塔 + hero_zhushou_muen + 9 敌含 Boss）；色弱变体 57 张（19 单位 × protan/deutan/tritan，
  变体矩阵与 `ui_palette.gd` apply() 逐像素一致）。
- 预览目检：`out/m4b_units_preview.png`（19 单位拼图）、`out/m4b_terrain_preview.png`（8 关 sea_a+land_a）。

## 3. 接入点

- `scripts/core/art_library.gd`：新增 `_unit_cached()`——非 default 色弱预设时先试 `<stem>_<preset>.png`，
  缺失回退基础图，再缺失回退程序化剪影（三级回退链）。
- `greybox_enemy.gd`：sprite 分支按纹理尺寸居中（适配 64×64 Boss）；高对比模式 modulate ×1.18 + 白色外圈。
- `greybox_tower.gd` / `greybox_hero.gd`：sprite 分支同高对比处理。
- 地形：`greybox_map.gd` 按 level_id 自动取 `tilesets/<chapter>/`，C02–C08 无需改代码。
- 纯视觉层，不触碰战斗数据与 sim 逻辑。

## 4. 台账

- `ASSET_LICENSE_LEDGER.csv` +41 行（13 单位 base + 28 地形），色弱变体在 notes 注明"同包生成"；
  land_b 系列与 M4-A 一致标 staged（陆地斑块仍程序化渲染）。
- 顺手修复 df6b434 基线中 terrain_buch 行 17 列不一致问题（并入 notes），现全表 16 列齐整。

## 5. 验证结果（2026-09-06）

- 编辑器导入 0 error；`validate_data.gd` checked=141 errors=0 PASS；`run_tests.gd` 117/117 PASS；`check_i18n.gd` missing=0。
- C01–C08 3× autoplay smoke 全跑通无 ERROR：C01=7017 / C03=11558 / C08=16661 与 M2/M3 基线逐 tick 一致——精灵层纯视觉，sim 零变化。
- C04/C07 autoplay lose 为既定难度定位（非回归）；steady 标准构筑 win 且 ticks=13523/13467、kills/leaks/integrity 与 NEXT_PHASE 基线逐字段一致。
- perf（3×）：C01 avg 6.97ms(144fps) 1%low 66fps；C04 6.95ms(144fps)/77fps；C08 6.95ms(144fps)/76fps。
- 截图证据：`out/polish_level_c08_wave3.png`（C08 主题地形 + 塔/敌精灵渲染目检通过）。

## 6. Blockers / 未做（如实保留）

- anchor_crab_guardian：无出场，未生成精灵。
- 精英/Boss 阶段变体、FX/UI 图标色弱变体：未做（低优先，接入层就绪）。
- 正式音频：仍运行时合成占位，未宣称完成。
- terrain_land_b（全章）：staged 未接入。
- 手柄实机/低端机/盲测：留发行前人工门禁。

---

# M4-C：第二章首批 C09–C12 资产扩展（2026-09-06）

- 新增 `tools/gen_chapter2_sprites.py`（复用 gen_chapter1_sprites 的 save/remap/terrain_for 工具函数）：
  C09–C12 主题地形 16 张（调色板对齐 visual_theme.gd 第二章「玻璃沼泽」新增 4 主题）+
  3 张新敌人精灵（reed_stalker 隐匿 / spore_mender 治疗 / mirror_shade 双相）+ 9 张色弱变体。
- `greybox_map.gd._draw_level_flavor` +4 关装饰（玻璃苇丛/荧光孢囊/镜像银纹/断桅藤壶）。
- 台账 +19 行（16 地形 + 3 单位 base；变体同包注明）；CREDITS 已同步。
- 预览证据：`out/m4c_sprites_preview.png`、`out/m4c_terrain_preview.png`。
- 机制层（隐匿/治疗光环/双相抗性/掩体阻挡/侦测与孢子装置）详见 docs/M4_CONTENT_NOTES.md。
- Blockers 维持：C13–C14 与 Boss 2 未做；正式音频/手柄/盲测门禁不变。
