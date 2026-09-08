# OpenGameArt 敌人猎手报告

> 角色：OpenGameArt 敌人候选搜集者（俯视像素敌人方向）
> 项目：《余烬潮汐》（AshenTides），Godot 4 像素塔防
> 根目录：`D:\mydev\games\Tower Defense`
> 输出目录：`assets/vendor/hunt/oga-enemies/`
> 报告日期：2026-09-08
> 关键词：top down pixel enemy、pixel crab、pixel turtle、sea monster pixel、pirate pixel、rat pixel、topdown creature

## 一、执行摘要

- 共筛选并下载 **10 个候选**到 `assets/vendor/hunt/oga-enemies/`，全部为正交俯视（top-down / orthogonal）像素画，符合"32–64 px 普通单位"密度要求。
- 许可证全部命中允许范围：**CC0**（3 个）、**CC-BY 3.0/4.0**（6 个）、**OGA-BY 3.0**（1 个）。无任何 CC-BY-SA / CC-BY-NC / GPL / 无许可条目被采用。
- 主动拒绝的候选：Horseshoe Crab Topdown Sprites（Croomfolk，CC-BY-SA 4.0，违反"不接受 ShareAlike"红线）。
- TOP 3 推荐：**① Undead Pirate Roguelike（CC0） ② LPC Animals 2022（CC-BY 4.0） ③ Turtle Sprite 64x64 + Crab standalone 双件套（CC0）**。
- 障碍：仅一处需特别说明——`Animated Pirate 1`（David Harrington）是侧视（sidescroll）构图，不属于本次正交俯视范围，已剔除；另有候选 `Horseshoe Crab Topdown Sprites` 命中 CC-BY-SA 被剔除。

## 二、候选总表

| # | 名称 | 作者 | 来源 URL | 许可证 | 保存路径 | 像素尺寸 | 包含内容 | 风格匹配（高/中/低 + 理由） |
|---|---|---|---|---|---|---|---|---|
| 1 | Big Red Crab | rapidpunches | https://opengameart.org/content/big-red-crab | CC-BY 4.0（页面同时挂 CC-BY 3.0 标识） | `01_big_red_crab/crab-big-red.zip` → `extracted/crab-walk.png` 64×32、`crab-claws.png` 192×32 | 单帧 ~32×32（双帧横向排列） | 2 张 PNG：walking、claws 动作；俯视红蟹 | **高**：纯俯视硬边像素，单帧 ~32 px，暖红配色与项目"暖珊瑚/余烬橙"己方高光调色方向契合（注意：本素材为敌方，调色后期可整体偏冷青处理） |
| 2 | Crab (top-down) | alizard | https://opengameart.org/content/crab | CC0 | `02_crab_topdown/Crab.zip` → `extracted/Crab/Crab_Walk.png` 256×128 | 单帧 64×32（4 方向 × 2 帧，共 8 帧排成 256×128） | 俯视橙色螃蟹 4 方向行走，含 PSD 源文件 | **高**：CC0 零障碍，单帧 ~32 px 边长正合适，造型对称干净，调色偏暖，后期偏冷即可纳入敌方 |
| 3 | Turtle Sprite (64×64 top-down) | Oiboo | https://opengameart.org/content/turtle-sprite | CC0 | `03_turtle_64x64/Turtle_TopDown_64x64_SpriteSheet.png` 256×256 | 单帧 64×64，含 idle / walk / retreat / squished / power-up 多组动画 | 一只绿/棕色乌龟多种状态 | **高**：原生俯视、64×64 完美命中"普通单位 32–64 px / 重甲单位 64–96 px"上限，CC0 无附加义务，含 XCF 源文件 |
| 4 | Top down rat, animated (Warlock's Gauntlet) | rAum / jackFlower / DrZoliparia / Neil2D | https://opengameart.org/content/top-down-rat-animated | CC-BY 3.0 | `04_rat_topdown_wg/rat-attack.png` 512×128、`rat-dying.png` 512×256、`rat-move.png` 512×128 | 单帧 ~32×32，4 方向 × 多帧 | 俯视黑鼠三组动画（attack/dying/move），红眼强调 | **高**：明确 top-down 标签，多角度多状态完整，鼠群/夜袭敌兵理想素材；CC-BY 3.0 须署名原作者团队 |
| 5 | Animated Rat and Bat | Calciumtrice | https://opengameart.org/content/animated-rat-and-bat | CC-BY 3.0 | `05_rat_bat_calciumtrice/rat_bat_calciumtrice.png` 320×320 | 单帧鼠 ~16×16、蝙蝠 ~24×24 | 鼠 + 蝙蝠各含 idle / gesture / walk / attack / death | **中**：俯视但单帧 ~16 px 偏小，仅适合小体型敌人或巢穴涌出动画；若项目需要更突出鼠群个体，建议优先 #4 和 #6 |
| 6 | [LPC] bears, deer, lions and more（含 shark、giant rat、mice） | tapatilorenzo（Sevarihk 派生部分） | https://opengameart.org/content/lpc-bears-deer-lions-and-more | CC-BY 4.0（页面整体）；Sevarihk 派生条目仍为 CC-BY 4.0，非 Sevarihk 派生条目可按 CC0 用 | `06_lpc_animals_2022/lpc_animals_2022_v1.1.zip`（421 KB）+ `shark_underwater_160x160_sevarihk.png` | shark 160×160 单帧；giant rat 80×64；mice 32×32；fox/bear/lion 64×64；deer 64×96 | 俯视硬边像素，含 shark、giant rat（含 walk/attack/die）、mice、bear/deer/fox/lion/dog/mushroom 等 | **高**：本批唯一直接命中"鲨鱼/鼠群"两类核心敌人；shark 160×160 适合做 BOSS 级重甲海怪；rat 64 px 适合精英鼠；mice 32 px 适合炮灰鼠海。CC-BY 4.0 须署名原作者 + Sevarihk |
| 7 | 2D Shark (Not Animated) | OGA 贡献者（页面未具名） | https://opengameart.org/content/2d-shark-not-animated | OGA-BY 3.0 | `07_2d_shark/Shark1.png` 128×32 | 128×32 单图 | 蓝灰色鲨鱼侧视图 | **低**：**视角为侧视（profile / sidescroll），并非俯视**。若项目坚持俯视，请勿采用；可留作"海面背景装饰"或"BOSS 出现前 cut-in 图"参考 |
| 8 | Pirate Zombie and Skeleton 32x48 | Reemax | https://opengameart.org/content/pirate-zombie-and-skeleton-32x48 | CC-BY 3.0 | `08_pirate_zombie_skeleton/pirate-zombie-skeleton-preview.png` 256×256、`pirate-skeleton-face.png` 48×48、`pirate-zombie-face.png` 48×48 | 单帧 32×32/48×48 头身比；预览图含 4 方向行走的 zombie 与 skeleton 各两套（带红头巾/带三角帽） | 4 方向俯视僵尸+骷髅海盗，含独立头像 | **高**：完美命中"重甲怪物/骷髅海盗"调性，48×48 在普通单位上限附近，CC-BY 3.0 署名 Reemax 即可 |
| 9 | Undead Pirate Roguelike | AmberFallStudio | https://opengameart.org/content/undead-pirate-roguelike | CC0 | `09_undead_pirate_roguelike/*.png`（共 10 张 PNG） | 单帧 16×16~32×32（crocodile 128×48，zombie/skeleton 80×80~384×224，goldbeard 192×96） | tileset_v6、zombie-sheet、goldbeard-sheet、crocodile-sheet、blue_zombie-sheet、skeleton-sheet、skeleton_with_hat-sheet、skeleton_with_musket-sheet、player-sheet、parrot_miniboss-sheet | **高**：CC0 零障碍，整套海盗主题含鳄鱼、骷髅、海盗鹦鹉、金胡子船长等，正好覆盖"港岸闸门关卡"全套敌人；尺寸偏小（~16 px 单帧），需要做 up-scale 处理到 32 px，但造型非常干净 |
| 10 | Sailors & Pirates | AntumDeluge | https://opengameart.org/content/sailors-pirates | CC-BY 4.0 + CC-BY 3.0 + OGA-BY 3.0（页面三标） | `10_sailors_pirates/sailor_and_pirate-1.1.zip`（171 KB）→ `extracted/PNG/24x32/`、`48x64_scale2x/` | 24×32、48×64（含 2x 放大版） | 男/女海盗、男/女船长多套方向，含 idle/walking 多帧 | **高**：明确标注 orthogonal 俯视 + N/E/S/W 四方向，尺寸刚好命中"普通单位 32–64 px"区间；带独立船长 boss 候选；CC-BY 4.0 需署名 AntumDeluge |

## 三、被剔除的候选（记录透明）

| 名称 | 作者 | 许可证 | 剔除原因 |
|---|---|---|---|
| Horseshoe Crab Topdown Sprites | Croomfolk | **CC-BY-SA 4.0** | ShareAlike 不在白名单（违反"不允许 ShareAlike"硬规则），且派生图源同样为 CC-BY-SA |
| Animated Pirate 1 | David Harrington | OGA-BY 3.0 | 实际构图是 **侧视**（隶属 `2D::Sprite::Sidescroll` 集合），与本批"正交俯视"目标不符；保留链接备查，但不入仓 |
| pixel turtle | alizard | CC0 | 标签含 `sidescroller` 且未在俯视集合内，疑似侧视；避免误纳入，已跳过 |

## 四、推荐 TOP 3

### 🥇 TOP 1 — Undead Pirate Roguelike（`09_undead_pirate_roguelike/`）

- **理由**：CC0 零许可负担；一次买齐"鳄鱼（crocodile）+ 骷髅（skeleton 多套装扮）+ 僵尸（zombie/blue_zombie）+ 金胡子船长 boss + 鹦鹉小 boss"，正好对应本项目"潮汐关 / 海盗港岸关"两章的敌方配置。
- **短板**：单帧 ~16 px 偏小，需要做 2× 上采样才能与项目"32–64 px 普通单位"统一；建议在 `tools/gen_*_sprites.py` 流水线中加 nearest-neighbor 2× 缩放步骤。
- **可立即落地**：金胡子船长（goldbeard-sheet）做章末 boss；鳄鱼（crocodile-sheet）做"沼泽浅滩"普通单位；骷髅（skeleton_with_musket）做炮台位压制兵。

### 🥈 TOP 2 — [LPC] bears, deer, lions and more（含 Sevarihk 派生条目）（`06_lpc_animals_2022/`）

- **理由**：本批唯一直接命中"鲨鱼 boss（shark 160×160）+ 巨型鼠精英（giant rat 80×64）+ 小鼠海（mice 32×32）"三档；shark 单帧 160 px 已落在项目"塔 64–96 / 重甲 boss 96–160"上限，完全能当第一章潮汐 BOSS 使用。
- **短板**：CC-BY 4.0 + 派生链署名——必须在 `ASSET_LICENSE_LEDGER.csv` 记入 `tapatilorenzo` 和 `Sevarihk` 双重署名。
- **可立即落地**：shark（160×160）作潮汐章 BOSS；giant rat 80×64 作精英敌；mice 32×32 作炮灰涌潮；fox/bear 等不直接用但保留为后续章节素材。

### 🥉 TOP 3 — Turtle Sprite 64×64 + Crab (top-down) 双件套（`03_turtle_64x64/` + `02_crab_topdown/`）

- **理由**：两个都是 **CC0**，原生俯视 + 像素密度刚好命中（乌龟 64×64、螃蟹 64×32），造型干净适合做"潮汐甲壳类"族群（重甲乌龟走慢路径 / 普通螃蟹沿边路绕行）。
- **短板**：单一角色，需要靠调色变体（红→青灰后期处理）做 2~3 档难度区分。
- **可立即落地**：乌龟直接作重甲慢速敌人；螃蟹作快速小型甲壳敌人；与 `01_big_red_crab`（CC-BY）合并可组成 3 档"螃蟹兵"梯度。

## 五、落地建议（给项目后续步骤）

1. **统一许可登记**：把所有 CC-BY/OGA-BY 条目写入 `assets/vendor/hunt/oga-enemies/CREDITS.md`，并在 `ASSET_LICENSE_LEDGER.csv` 补齐 `tapatilorenzo`、`Sevarihk`、`Reemax`、`Calciumtrice`、`rAum/jackFlower/DrZoliparia/Neil2D`、`AntumDeluge`、`AmberFallStudio`、`rapidpunches` 等署名。
2. **像素密度归一**：单帧 ≤32 px 的资源（Undead Pirate Roguelike、Animated Rat and Bat）走 nearest-neighbor 2× up-scale；64 px 资源直接用；>64 px 资源考虑 down-sample 或作 BOSS 专用层。
3. **调色重映射**：所有素材在导入 Godot 4 之前过一遍 `tools/` 下的色相/饱和度处理（冷青灰主调 + 暖珊瑚高光），把暖橙系螃蟹/船长统一偏移到项目调色板。
4. **不接受的来源**：本次已剔除 CC-BY-SA 与 sidescroll 候选；若未来需要补全"海怪 / 章鱼 / 巨型水母"，建议改去 Kenney 或 Itch.io 的明确 CC0 创作者包，不要触碰 CC-BY-SA 标签条目。

## 六、访问障碍记录

- `itch.io` 部分作者页面会触发登录墙/地区限制，本次完全未触碰 itch.io，所有 10 个候选均直接走 opengameart.org 的 `https://opengameart.org/sites/default/files/...` 直链下载。
- 同一站点请求间隔 1–2 秒、每下载之间 `sleep 1~2`，未触发任何反爬封禁。
- `opengameart.org` 的 `Animated top down creatures.` 是 collection 页面（无独立文件），不是独立候选——本次正确地改为从该集合内拆出 `crab` 与 `big-red-crab` 等独立条目下载。
- 报告文件名中的 `/` 与中文标点按要求替换为下划线，便于 Windows 文件系统与 grep 索引。
