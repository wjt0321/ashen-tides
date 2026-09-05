# CREDITS（仅真实接入项）

> 更新：2026-09-06（M4-C）
> 规则：PRD §18.6——发布构建必须包含 Godot（MIT）与全部第三方资产归因；本文件只列**已接入运行时**的资产。

## 引擎

- **Godot Engine 4.7.2** — MIT License。Copyright (c) 2014-present Godot Engine contributors.
  <https://godotengine.org/license>

## 字体

- **Ark Pixel Font 12px monospaced (zh_cn)** — TakWolf（<https://takwolf.com>），SIL Open Font License 1.1。
  来源：<https://github.com/TakWolf/ark-pixel-font> v2026.09.01；许可证原文：`licenses/ARK_PIXEL_FONT_OFL.txt`。

## 美术（项目自有原创）

- C01 切片精灵 16 张（地形 ×4 / 塔 ×3 / 敌人 ×2 / 英雄 ×1 / FX ×2 / UI 图标 ×4）— Ember Tide dev，
  由 `tools/gen_c01_sprites.py` 程序生成，项目自有。明细与 hash 见 `ASSET_LICENSE_LEDGER.csv`。
- 第一章 C01–C08 精灵 41 张（C02–C08 主题地形 ×28 / 塔 ×3 / 敌人 ×9 含 Boss / 英雄 ×1）+ 全部单位精灵的
  protan/deutan/tritan 色弱变体 — Ember Tide dev，由 `tools/gen_chapter1_sprites.py` 确定性生成（固定 seed），
  项目自有。变体矩阵与 `scripts/ui/ui_palette.gd` 的 apply() 逐像素一致；缺失变体自动回退基础图。
- 第二章首批 C09–C12 精灵 19 张（主题地形 ×16 / 敌人 ×3：芦丛潜行者/孢光医者/倒映影魅）+ 色弱变体 —
  Ember Tide dev，由 `tools/gen_chapter2_sprites.py` 确定性生成，项目自有。

## 试验性资产（不随构建默认启用）

- **Buch – Outdoor 32×32 Tileset** — Michele "Buch" Bucelli，CC0 1.0（`licenses/CC0-1.0.txt`）。
  仅 `--asset-trial` 试验开关使用，replacement_status=trial-only，不作为正式资产发布。

## 音频

- 当前全部为运行时合成占位（AudioStreamGenerator，项目自有），正式音频资产未接入。
