# CREDITS（仅真实接入项）

> 更新：2026-09-08（C01/C02 v2 自绘像素表现层取代 Foozle 栅格基线）
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
