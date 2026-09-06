# C01 资源决议（收敛版）

> **视觉权威**：`docs/current/art/ART_STYLE_BASELINE.md`
> **C01 实现样板**：`docs/current/art/C01_STYLE_BIBLE.md`
> **资产成熟度**：`ART_ASSET_REGISTRY.csv`
> **逐文件许可证**：`ASSET_LICENSE_LEDGER.csv`
> **决议日期**：2026-09-06

本文只保留当前有效资源决议。旧的 Kenney 主视觉试装、程序化海报方案和未采用候选不再重复展开；Git 历史可用于追溯。

## 1. 最终采用：Foozle CC0 栅格主体

| 包 | 创作者 / 分发 | C01 用途 | 处理方式 |
|---|---|---|---|
| Spire — Enemy Pack 2 (Ground) | Baldur / Foozle | Magma Crab → 盐壳行者；Scorpion → 桅鼠群 | 裁为 8 帧 × 3 方向，冷青灰调色 |
| Spire — Tower Pack 1 | Baldur / Foozle | Tower 01 塔基与动画武器 → 针轨弩台 | 组合为 6 帧 96×96 图条，暖珊瑚/炭灰调色 |
| Scallywag — Ships | Pixel Carvel / Foozle | 迁徙舰队、港船与流程装饰 | 最近邻缩放、暖色识别调色 |
| Scallywag — Water and Islands | Pixel Carvel / Foozle | 礁岸与港区材质来源 | 冷青灰调色并进入背景合成 |
| Scallywag — Fort | Pixel Carvel / Foozle | 码头与岸防道具来源 | 潮湿石材/木材调色并进入图集 |

上述原包的 Readme 均声明 Creative Commons Zero（CC0），允许商业使用和修改，且不要求署名。项目自愿保留 Pixel Carvel、Baldur 与 Foozle 署名。

## 2. 保留：Kenney 辅助资源

- **Kenney UI Pack 2.0**：少量按钮、箭头、标记与兼容 UI 资源；不再主导世界画面。
- **Kenney UI Audio**：`ui_select`、`ui_confirm`、`ui_cancel`、`ui_transition`、`ui_error`。
- **Kenney Pirate FX**：保留已接入的小型战斗 FX/兼容候选；旧菜单船饰不再作为 C01 主体。

许可证和实际路径继续由 `ASSET_LICENSE_LEDGER.csv` 管理。

## 3. 已取代方案

- 程序化圆形、线段、多边形拼成的灯塔、船、塔和敌人主体；
- 以 Kenney 单张船饰作为 C01 主视觉；
- Campaign 的抽象岸线、圆形节点和流程图航线；
- 早期项目生成的 C01 塔/敌/地形占位主体。

旧文件仅在仍有运行时 fallback、FX 或历史价值时保留，不代表当前风格。

## 4. 可复现资产链

- 原始压缩包：`assets/vendor/c01/foozle/source_archives/`
- 来源、SHA-256、实际使用成员：`assets/vendor/c01/foozle/SOURCE_MANIFEST.json`
- CC0 全文：`assets/vendor/c01/foozle/LICENSE-CC0-1.0.txt`
- 构建脚本：`tools/build_c01_foozle_assets.py`
- 派生输出：`assets/art/c01/runtime/`
- 派生 SHA-256：`assets/art/c01/runtime/DERIVED_MANIFEST.json`
- Credits：`docs/current/art/CREDITS.md`

构建脚本直接读取保留的 5 个 ZIP，不依赖临时解压目录。

## 5. 运行时边界

- 统一入口：`scripts/ui/c01_sprite_library.gd`。
- 覆盖 Title、Campaign、Briefing、Battle、Result，以及盐壳行者、桅鼠群、针轨弩台、灯塔、舰队和港区背景。
- 美术替换不得修改塔伤害、射速、敌人生命、路线、波次、奖励、BuildNode 或模拟生命周期。
- C01 硬基线保持：7017 ticks、90 kills、0 gameplay leaks、integrity 20。

## 6. 主理批准

2026-09-06，项目主理人确认当前 C01 美术风格正式采用，并要求后续全部关卡沿用。批准原文记录在 `docs/current/art/ART_STYLE_BASELINE.md` 和 `ART_ASSET_REGISTRY.csv`。

该批准锁定视觉方向；单项资产是否达到 Visual-QA、Player-verified 或 Shipping，仍按 `docs/current/art/ART_PRODUCTION_PLAN.md` 执行。
