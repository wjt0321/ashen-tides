# CREDITS（仅真实接入项）

> 更新：2026-09-08（C01/C02 v2 自绘像素表现层取代 Foozle 栅格基线；新增 C01/C02 sourced CC0/CC-BY 派生表现层）
> 规则：PRD §18.6——发布构建必须包含 Godot（MIT）与全部第三方资产归因；本文件只列**已接入运行时**的资产。

## 引擎

- **Godot Engine 4.7.2** — MIT License。Copyright (c) 2014-present Godot Engine contributors.
  <https://godotengine.org/license>

## 字体

- **Ark Pixel Font 12px monospaced (zh_cn)** — TakWolf（<https://takwolf.com>），SIL Open Font License 1.1。
  来源：<https://github.com/TakWolf/ark-pixel-font> v2026.09.01；许可证原文：`licenses/ARK_PIXEL_FONT_OFL.txt`。

## 美术（项目自有原创）

- 早期 C01 切片精灵 16 张（地形 ×4 / 塔 ×3 / 敌人 ×2 / 英雄 ×1 / FX ×2 / UI 图标 ×4）— Ember Tide dev，
  由 `tools/gen_c01_sprites.py` 程序生成，项目自有。当前 C01 的主战场、盐壳行者、桅鼠群、针轨弩台和流程背景已由 v2 自绘像素表现层（见下条）取代；旧图仅保留未替换的 FX/UI/fallback 用途。
- 第一章 C01–C08 精灵 41 张（C02–C08 主题地形 ×28 / 塔 ×3 / 敌人 ×9 含 Boss / 英雄 ×1）+ 全部单位精灵的
  protan/deutan/tritan 色弱变体 — Ember Tide dev，由 `tools/gen_chapter1_sprites.py` 确定性生成（固定 seed），
  项目自有。变体矩阵与 `scripts/ui/ui_palette.gd` 的 apply() 逐像素一致；缺失变体自动回退基础图。
- 第二章首批 C09–C12 精灵 19 张（主题地形 ×16 / 敌人 ×3：芦丛潜行者/孢光医者/倒映影魅）+ 色弱变体 —
  Ember Tide dev，由 `tools/gen_chapter2_sprites.py` 确定性生成，项目自有。
- 第二章收口 C13–C14 精灵 11 张（主题地形 ×8 / 敌人 ×3：雾母载体/雾中医正/沼冠孢王 64×64）+ 色弱变体 —
  Ember Tide dev，由 `tools/gen_chapter2b_sprites.py` 确定性生成，项目自有。

- C01 v2 自绘像素表现层 11 张（Battle 背景 / Title·Campaign·Briefing·Result 背景 ×5 / 简报海图 /
  港口道具图集 / 盐壳行者与桅鼠群 8×3 行走表（侧·正·背三视）/ 针轨弩台 6 帧开火表）— Ember Tide dev，
  由 `tools/build_v2_assets.py` 依 `tools/pixel_v2.py` 作者网格（作者 1px = 运行时 2px、Bayer 有序抖动、
  闭合炭黑轮廓）确定性生成，项目自有；2026-09-08 经业主工作单取代 Foozle 栅格基线。
- C02「潮门初启」专属像素资产 48 张（潮门开/闭、针轨弩台与余烬喷井 I–IV 级、裂鳍疾行者/桅鼠群/锈甲载体、余烬弹体 FX 及 protan/deutan/tritan 变体）— Ember Tide dev，由 `tools/build_v2_assets.py` 依 `tools/pixel_v2.py` 作者网格确定性生成，项目自有；导出清单见 `assets/art/c02/runtime/DERIVED_MANIFEST.json`，运行时由 `scripts/core/art_library.gd` 统一加载。

## 美术（CC0 / CC-BY 第三方素材派生表现层，2026-09-08 接入）

下列派生资产由 `tools/build_sourced_assets.py` 从 `assets/vendor/hunt/` 已入库的 CC0 / CC-BY 素材
经裁帧、调色、合成与 `tools/pixel_v2.py` 项目自有基底拼接而成；每张运行时 PNG 的 SHA-256 与来源
清单见 `assets/art/c01/runtime/DERIVED_MANIFEST.json`、`assets/art/c02/runtime/DERIVED_MANIFEST.json`
与 `out/sourced_assets_lineage.json`；逐源许可证原文与 SHA-256 见 `licenses/sources/AT-CHA-008/`、
`AT-CHA-009/`、`AT-CHA-010/`、`AT-TWR-007/`、`AT-VFX-001/`、`AT-VFX-002/`、`AT-VFX-005/`。

### 需署名（CC-BY）— 派生使用时请保留以下归因文本

- **Sevarihk (LPC animals 2022 - giant rat / mice / shark)** — CC-BY 4.0。源自 [LPC] bears,
  deer, lions and more（OGA pack 作者 tapatilorenzo，CC-BY 4.0）。
  派生条目作者为 Sevarihk；本项目在 C01 桅鼠群（enemy_mast_rat）、C02 桅鼠群（enemy_mast_rat_swarm
  小鼠海）与 C02 裂鳍疾行者（enemy_splitfin_dasher 鲨鱼）的 protan/deutan/tritan 色弱变体中使用。
  来源 URL：<https://opengameart.org/content/lpc-bears-deer-lions-and-more>；
  shark PNG 文件名直接以 Sevarihk 署名（`shark_underwater_160x160_sevarihk.png`）。
  **署名必须**（项目将 "Sevarihk (LPC animals 2022, derived from tapatilorenzo)" 写入致谢）。

- **bluecarrot16 ([LPC] Ship)** — OGA-BY 3.0 / CC-BY 3.0。模块化 top-down 像素帆船；
  本项目仅取船配件（lpc-ship-accessories）与船炮（ship-cannon）两张 PNG 合成 C01 港岸道具图集
  `harbor_props.png`。
  来源 URL：<https://opengameart.org/content/lpc-ship>。
  **署名必须**（项目将 "[LPC] Ship by bluecarrot16, CC-BY 3.0" 写入致谢）。

- **Clint Bellanger (Sparks: Fire / Ice / Blood)** — CC-BY 3.0。三套粒子火花
  (256×384 PNG)；本项目派生使用：C01 `fx_hit_spark_strip4` 命中火花 4 帧条
  （`scripts/ui/fx_layer.gd` 通过 `ArtLibrary.vfx_tex("fx_hit_spark_strip4")` 调用）与
  C02 余烬弹体 `projectile_ember_burst.png`（`scripts/combat/greybox_projectile.gd` 通过
  `ArtLibrary.c02_vfx_tex("projectile_ember_burst")` 调用）。
  来源 URL：<https://opengameart.org/content/sparks-fire-ice-blood>。
  **署名必须**（项目将 "Sparks by Clint Bellanger, CC-BY 3.0" 写入致谢）。

- **Jetrel (Explosion Animations, from Frogatto)** — CC-BY 3.0。480×362 PNG，5 种
  爆炸形态（球/十字/环/烟等）各 6 帧，原始数据来自 Frogatto 游戏项目；
  本项目派生：C01 `fx_muzzle_flash_strip3` 开火闪光 3 帧条
  （`scripts/combat/greybox_tower.gd` 通过 `ArtLibrary.vfx_tex("fx_muzzle_flash_strip3")` 调用）
  + 全部色弱变体。
  OGA 页面 metadata 标 CC0 但页面正文有作者本人亲自发布的更正声明："License is
  **incorrect!** Engine itself is under CC0 but data are under CC-BY-3.0"
  （<https://github.com/frogatto/frogatto/blob/master/LICENSE>），故本项目按作者
  最终意图登记为 **CC-BY 3.0，attribution REQUIRED**；先前的台账/管线归属
  （猎手报告 dvh / b3l7 / artificialintelligence CC0；管线脚本误标 Clint Bellanger
  CC-BY 3.0）已在本轮复核中按作者本人在 OGA 页面的更正声明统一为 Jetrel / CC-BY 3.0。
  来源 URL：<https://opengameart.org/content/explosion-animations>。
  **署名必须**（项目将 "Explosion Animations from Frogatto by Jetrel, CC-BY 3.0" 写入致谢）。

### Courtesy credit（CC0，署名非强制；项目自愿保留以维持来源可追溯）

- **alizard (Crab, top-down walk)** — CC0 1.0。俯视螃蟹 4 方向 × 2 帧行走表
  （256×128 PNG，源 64×32 单帧）；本项目派生：C01 盐壳行者
  `enemy_salt_shell_walker`（`assets/art/c01/runtime/enemy_salt_shell.png`，512×192，含
  protan/deutan/tritan 色弱变体由 `tools/gen_chapter1_sprites.py` 同矩阵派生，未在
  sourced runtime 中）+ C02 锈甲载体 `enemy_rust_armor_carrier`（64×62 PNG + 三色弱变体）。
  实际运行时 C01 盐壳行者使用 `enemy_salt_shell.png`（走 alizard 派生）。
  来源 URL：<https://opengameart.org/content/crab>。

- **zerohero (Pixel Turret Animation)** — CC0 1.0。俯视像素炮塔 5 张 PNG
  （base / deployment 8 帧 / head-shot 6 帧 / head-shot-idle 5 帧 / highlights）；
  本项目派生：C01 针轨弩台 `tower_needle_rail` 炮头 6 帧条（576×96）+ C02 针轨弩台
  tier1..tier4（各 64×64）+ 全部色弱变体。
  来源 URL：<https://opengameart.org/content/pixel-turret-animation>。

- **benhickling (Animated Fire)** — CC0 1.0。8 套火苗动画（每套 10×6 = 60 帧 × 64×64），
  本项目派生：C02 余烬喷井 tier1..tier4（各 64×64）+ 全部色弱变体。
  来源 URL：<https://opengameart.org/content/animated-fire>。

### 派生资产覆盖范围（与 ART_ASSET_REGISTRY.csv `C0X_SOURCED_PRESENTATION` 行一一对应）

- **C01 sourced 表现层**：`enemy_mast_rat`（Sevarihk CC-BY 4.0）/ `enemy_salt_shell`（alizard CC0）/
  `tower_needle_rail` 炮头（zerohero CC0）/ `harbor_props`（bluecarrot16 CC-BY 3.0）；
  战斗背景 / 流程背景 / briefing map 仍为 v2 自绘项目自有（见上一节）。
- **C02 sourced 表现层**：`enemy_mast_rat_swarm` 小鼠海（Sevarihk CC-BY 4.0）/
  `enemy_rust_armor_carrier`（alizard CC0）/ `enemy_splitfin_dasher` 鲨鱼（Sevarihk CC-BY 4.0）/
  `tower_needle_rail` tier1..tier4（zerohero CC0）/ `tower_ember_well` tier1..tier4（benhickling CC0）/
  `projectile_ember_burst` 弹体（Clint Bellanger CC-BY 3.0）；
  潮门开/闭（`tide_gate_open.png`、`tide_gate_closed.png`）与潮门 FX（`fx_tide_gate_strip3.png`）
  仍为 v2 自绘项目自有，未替换。
- 全部 C01/C02 单位精灵均含 protan/deutan/tritan 色弱变体（与 `scripts/ui/ui_palette.gd` 同矩阵
  生成），变体清单见 `assets/art/c01/runtime/DERIVED_MANIFEST.json` 与
  `assets/art/c02/runtime/DERIVED_MANIFEST.json`。

## 试验性资产（不随构建默认启用）

## 试验性资产（不随构建默认启用）

- **Buch – Outdoor 32×32 Tileset** — Michele "Buch" Bucelli，CC0 1.0（`licenses/CC0-1.0.txt`）。
  仅 `--asset-trial` 试验开关使用，replacement_status=trial-only，不作为正式资产发布。

## 第三方 CC0 美术与 UI

- **Foozle Scallywag — Water and Islands / Ships / Fort** — 由 Pixel Carvel 创作、Foozle 分发，CC0 1.0。**历史来源**：2026-09-06 至 2026-09-08 间曾组成 C01 背景与 `harbor_props.png`；2026-09-08 起 C01 表现层改由 v2 自绘像素取代，Foozle 栅格不再接入运行时。
- **Foozle Spire — Tower Pack 1 / Enemy Pack 2 (Ground)** — 由 Baldur 创作、Foozle 分发，CC0 1.0。**历史来源**：曾用于针轨弩台与盐壳行者/桅鼠群动画；2026-09-08 起由 v2 自绘取代，不再接入运行时。
- Foozle 原始压缩包、下载页、SHA-256 与实际使用成员见 `assets/vendor/c01/foozle/SOURCE_MANIFEST.json`；许可证全文见 `assets/vendor/c01/foozle/LICENSE-CC0-1.0.txt`。派生文件 hash 现指向 v2 自绘产物，见 `assets/art/c01/runtime/DERIVED_MANIFEST.json` 与 `ASSET_LICENSE_LEDGER.csv`（c01_v2_* 行）。署名并非 CC0 强制要求，本项目自愿保留此历史归因。

- **Kenney UI Pack 2.0** — Kenney（<https://kenney.nl/assets/ui-pack>），CC0 1.0。C01 玩家外壳使用少量 9-slice 按钮、节点、箭头与星标；许可证：`assets/vendor/c01/kenney/LICENSE.txt`。
- **Kenney Pirate Pack** — Kenney（<https://kenney.nl/assets/pirate-pack>），CC0 1.0。C01 菜单使用 1 个船只装饰，并保留 1 个战斗爆炸 FX 候选；许可证：`assets/vendor/c01/kenney/LICENSE-PIRATE-PACK.txt`。

## 音频

- **Kenney UI Audio** — Kenney（<https://kenney.nl/assets/ui-audio>），CC0 1.0。C01 玩家外壳接入 select / confirm / cancel / transition / error 五类事件（共 6 个 OGG，含 rollover 候选）；许可证：`assets/vendor/c01/kenney/LICENSE-UI-AUDIO.txt`。
- 战斗类音效当前仍为运行时合成占位（AudioStreamGenerator，项目自有），不把 UI 音频接入误报为全量正式音频完成。
