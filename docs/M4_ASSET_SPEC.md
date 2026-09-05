# M4-A 美术技术规范（v1.0 正式资产基线）

> 建立日期：2026-09-05
> 状态：Locked（M4-A）
> 依据：PRD §12.4 像素视觉规范、§18.6 许可证；ASSET_CATALOG.md §11–12 落地流程（本规范不修改 catalog，仅作执行细则）
> 适用范围：C01 正式资产纵向切片及后续全部正式资产生产。任何与本规范冲突的资产不得标记为 Shipping。

## 1. 分辨率与网格

- 逻辑分辨率 **640×360**，整数倍缩放（1280×720 / 1920×1080 / 2560×1440）。
- 基础像素网格 **32×32**；角色/塔/敌人基础占地 32×32，精英 64×64，Boss 96×96 或 128×128。
- 投射物/小图标 8×8 或 16×16；UI 图标 16×16 或 24×24。
- 所有尺寸必须是 8 的倍数；禁止非整数缩放与亚像素摆放（工程已开 `snap_2d_transforms_to_pixel`）。
- 纹理过滤：Nearest（`default_texture_filter=0`），禁用 mipmap。

## 2. 调色板

- 关卡主题色以 `scripts/ui/visual_theme.gd` 的 `THEMES` 为唯一来源；资产绘制时取对应关卡调色板，
  正式精灵允许 ±10% 明度抖动，不得引入调色板之外的高饱和色。
- C01「离港火线」基准：黄昏港岸（sea 夜蓝 #1A2B42 系、land 暖棕 #524536 系、accent 橙 #F28C40 系）。
- 阵营/危险/可交互用**轮廓形状**区分，不只依赖颜色（PRD §12.4）；所有精灵必须过 UiPalette 色弱重映射后的可读性检查。

## 3. 轮廓与可读性

- 每个 32×32 单位必须有 1px 深色外轮廓（建议 #14141C 系），主体与背景对比度在最繁忙战斗（同屏 40+ 单位）下仍可辨。
- 敌人剪影按种类可区分：壳行者=圆顶甲壳、鼠群=三点散布、旗鱼=长梭形、锈甲=方块重甲。
- 塔按家族形状区分：针轨=立轨、喷井=圆釜、回声=桩阵、风巢=风车、潮汐砧=砧形、棱光=晶簇。
- 剪影优先于细节：先看 32×32 缩小图能认出是什么，再加内部像素细节。

## 4. 动画帧

- 行走/攻击循环 4 帧为基线（横向帧条，单文件），idle 允许 2 帧。
- FX：命中火花 4 帧条（8×8/帧），开火闪光 3 帧条（16×16/帧），相位切换闪光由代码驱动。
- 帧率与固定 tick（60Hz）对齐：动画步进走 sim_tick，不依赖真实帧率。
- 闪光频率遵守无障碍预算：大面积高对比闪烁 < 3 次/秒（PRD §13.1）。

## 5. 命名与目录

- 目录：`assets/art/{tilesets,towers,characters,enemies,vfx,ui,icons}/`。
- 命名：`<类别>_<id>[_<变体>].png`，id 与数据层 `TowerData/EnemyData/HeroData.id` 完全一致
  （如 `tower_needle_rail.png`、`enemy_salt_shell_walker.png`、`hero_lanzhou_wei.png`）。
- 帧条加 `_strip<帧数>` 后缀（如 `fx_hit_spark_strip4.png`）。
- 地形 tile 按关卡分目录：`assets/art/tilesets/c01/terrain_sea_a.png` 等。

## 6. 导入规则

- Godot 默认导入即可（2D Pixel 预设）；不勾选 mipmaps，filter=Nearest，无压缩伪影需求时不启用 VRAM 压缩。
- 每个新增 PNG 必须经 `--editor --headless --quit` 导入验证 0 error 后才允许引用。
- 运行时加载必须带**程序化回退**：文件缺失时回退到矢量绘制，不得报错崩溃。

## 7. 许可证规则（硬门槛）

- 每个资产进入工程前必须完成 `ASSET_LICENSE_LEDGER.csv` 登记：来源 URL、作者、许可证名称、
  许可证原文（存 `licenses/`）、下载日期、sha256、署名文本、是否修改、可否再分发。
- `Indirect` / `Not verified` 来源的资产**不得接入运行时**，只能留在 catalog 候选。
- 项目自有（原创/程序生成）资产标记 license=`Project-owned (original)`，作者=`Ember Tide dev`，
  仍须登记 hash 与生成工具（如 `tools/gen_c01_sprites.py`）。
- 禁止批量下载；每项单独核验。禁止伪造 Shipping 状态。
- 发布构建的 credits 必须包含 Godot（MIT）与全部第三方资产归因（PRD §18.6），见 `docs/CREDITS.md`。

## 8. C01 切片资产清单（M4-A 范围）

| 类别 | 资产 | 规格 | 来源路线 |
|---|---|---|---|
| 地形 | terrain_sea_a/b、terrain_land_a/b（C01） | 32×32 ×4 | 项目自有生成（首选） |
| 塔 | tower_needle_rail / tower_ember_well / tower_echo_pile | 32×32 ×3 | 项目自有生成 |
| 敌人 | enemy_salt_shell_walker / enemy_mast_rat_swarm | 32×32 ×2 | 项目自有生成 |
| 英雄 | hero_lanzhou_wei | 32×32 | 项目自有生成 |
| FX | fx_muzzle_flash_strip3 / fx_hit_spark_strip4 | 帧条 ×2 | 项目自有生成 |
| UI | icon_ember / icon_integrity / icon_becon / icon_wave | 16×16 ×4 | 项目自有生成 |
| 字体 | Ark Pixel 12px zh_cn（已接入，NEXT_PHASE 锁定） | TTF | TakWolf, OFL 1.1 |

未列入上表的类别（音乐、正式 SFX、其余五塔、其余敌人、Boss、C02+ 地形）不在 M4-A 范围；
无安全合适来源时保持程序化占位并记 blocker，不得伪造。
