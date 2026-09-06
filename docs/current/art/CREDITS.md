# CREDITS（仅真实接入项）

> 更新：2026-09-06（C01 Foozle CC0 栅格表现层迭代）
> 规则：PRD §18.6——发布构建必须包含 Godot（MIT）与全部第三方资产归因；本文件只列**已接入运行时**的资产。

## 引擎

- **Godot Engine 4.7.2** — MIT License。Copyright (c) 2014-present Godot Engine contributors.
  <https://godotengine.org/license>

## 字体

- **Ark Pixel Font 12px monospaced (zh_cn)** — TakWolf（<https://takwolf.com>），SIL Open Font License 1.1。
  来源：<https://github.com/TakWolf/ark-pixel-font> v2026.09.01；许可证原文：`licenses/ARK_PIXEL_FONT_OFL.txt`。

## 美术（项目自有原创）

- 早期 C01 切片精灵 16 张（地形 ×4 / 塔 ×3 / 敌人 ×2 / 英雄 ×1 / FX ×2 / UI 图标 ×4）— Ember Tide dev，
  由 `tools/gen_c01_sprites.py` 程序生成，项目自有。当前 C01 的主战场、盐壳行者、桅鼠群、针轨弩台和流程背景已由下述 Foozle CC0 栅格表现层取代；旧图仅保留未替换的 FX/UI/fallback 用途。
- 第一章 C01–C08 精灵 41 张（C02–C08 主题地形 ×28 / 塔 ×3 / 敌人 ×9 含 Boss / 英雄 ×1）+ 全部单位精灵的
  protan/deutan/tritan 色弱变体 — Ember Tide dev，由 `tools/gen_chapter1_sprites.py` 确定性生成（固定 seed），
  项目自有。变体矩阵与 `scripts/ui/ui_palette.gd` 的 apply() 逐像素一致；缺失变体自动回退基础图。
- 第二章首批 C09–C12 精灵 19 张（主题地形 ×16 / 敌人 ×3：芦丛潜行者/孢光医者/倒映影魅）+ 色弱变体 —
  Ember Tide dev，由 `tools/gen_chapter2_sprites.py` 确定性生成，项目自有。
- 第二章收口 C13–C14 精灵 11 张（主题地形 ×8 / 敌人 ×3：雾母载体/雾中医正/沼冠孢王 64×64）+ 色弱变体 —
  Ember Tide dev，由 `tools/gen_chapter2b_sprites.py` 确定性生成，项目自有。

## 试验性资产（不随构建默认启用）

- **Buch – Outdoor 32×32 Tileset** — Michele "Buch" Bucelli，CC0 1.0（`licenses/CC0-1.0.txt`）。
  仅 `--asset-trial` 试验开关使用，replacement_status=trial-only，不作为正式资产发布。

## 第三方 CC0 美术与 UI

- **Foozle Scallywag — Water and Islands / Ships / Fort** — 由 Pixel Carvel 创作、Foozle 分发，CC0 1.0。C01 使用其水岸、舰船、码头与港口道具，经冷青暮潮/暖珊瑚调色后组成 Title、Campaign、Briefing、Battle、Result 背景与 `harbor_props.png`。
- **Foozle Spire — Tower Pack 1 / Enemy Pack 2 (Ground)** — 由 Baldur 创作、Foozle 分发，CC0 1.0。C01 使用 Tower 01 的塔基与动画武器制作针轨弩台，使用 Magma Crab / Scorpion 动画制作盐壳行者与桅鼠群。
- Foozle 原始压缩包、下载页、SHA-256 与实际使用成员见 `assets/vendor/c01/foozle/SOURCE_MANIFEST.json`；许可证全文见 `assets/vendor/c01/foozle/LICENSE-CC0-1.0.txt`；派生文件逐项 hash 见 `assets/art/c01/runtime/DERIVED_MANIFEST.json` 与 `ASSET_LICENSE_LEDGER.csv`。署名并非 CC0 强制要求，本项目自愿保留。

- **Kenney UI Pack 2.0** — Kenney（<https://kenney.nl/assets/ui-pack>），CC0 1.0。C01 玩家外壳使用少量 9-slice 按钮、节点、箭头与星标；许可证：`assets/vendor/c01/kenney/LICENSE.txt`。
- **Kenney Pirate Pack** — Kenney（<https://kenney.nl/assets/pirate-pack>），CC0 1.0。C01 菜单使用 1 个船只装饰，并保留 1 个战斗爆炸 FX 候选；许可证：`assets/vendor/c01/kenney/LICENSE-PIRATE-PACK.txt`。

## 音频

- **Kenney UI Audio** — Kenney（<https://kenney.nl/assets/ui-audio>），CC0 1.0。C01 玩家外壳接入 select / confirm / cancel / transition / error 五类事件（共 6 个 OGG，含 rollover 候选）；许可证：`assets/vendor/c01/kenney/LICENSE-UI-AUDIO.txt`。
- 战斗类音效当前仍为运行时合成占位（AudioStreamGenerator，项目自有），不把 UI 音频接入误报为全量正式音频完成。
