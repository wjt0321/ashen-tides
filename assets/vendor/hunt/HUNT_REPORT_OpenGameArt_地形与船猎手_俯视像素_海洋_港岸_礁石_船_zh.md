# OGA 地形与船猎手报告

**任务**：在 opengameart.org 搜索海洋 / 港岸 / 礁石 / 船的俯视像素 tileset 与像素船，筛 5-8 个候选下载到 `assets/vendor/hunt/oga-terrain/`。

**采集日期**：2026-09-08
**采集范围**：所有候选均直连 OGA `/sites/default/files/` 公开资源，未镜像站点；同站请求间隔 1-2 秒。
**保存根目录**：`D:\mydev\games\Tower Defense\assets\vendor\hunt\oga-terrain\`

---

## 候选总览表

| # | 名称 | 作者 | 来源页 URL | 许可证 | 文件直连 URL | 像素尺寸 / 像素密度 | 包含内容 | 风格匹配初评 |
|---|---|---|---|---|---|---|---|---|
| 1 | Outdoor 32x32 Tileset | Buch | https://opengameart.org/content/outdoor-32x32-tileset | CC0 | https://opengameart.org/sites/default/files/sheet_12.png | sheet.png 640x288，32x32 正交像素块 | 水域 / 草地 / 草径 / 石地 / 圆石 / 残垣石塔 / 树桩 / 木牌 | **高**——正交俯视、清晰硬边像素、调色偏冷青蓝（含水）+ 暗色泥土，单张 sheet 即可拼出基础海岸地形 |
| 2 | 32x32 Static Water Tileset | TearOfTheStar | https://opengameart.org/content/32x32px-static-water-tileset | CC-BY 3.0 | https://opengameart.org/sites/default/files/water_tileset_0.png + water_tileset_p1_0.png | water_tileset.png 96x96（3x3 个 32x32 tile），p1 100x100（多色变体） | 静态水波 tile 的两种主色调（深青 / 浅青） | **高**——纯俯视水 tile、32x32 像素、无动画但 tile 边界清晰，能直接当海水主层 |
| 3 | [LPC] Ship | bluecarrot16 | https://opengameart.org/content/lpc-ship | OGA-BY 3.0+ / CC-BY 3.0+ / GPL 2.0+（任选其一） | https://opengameart.org/sites/default/files/lpc-ship.zip | 模块化 32x32 tile，组合后船只 200-600 px 宽 | 完整方帆船：船体、甲板、桅杆、帆（收/展）、索具、桅顶瞭望台、舵轮、锚、舱口、动画炮 | **高**——真正的 top-down 像素帆船、模块化程度极高、LPC 风格契合严肃像素画 |
| 4 | Pirate Pack (190+) | Kenney (kenney.nl) | https://opengameart.org/content/pirate-pack-190 | CC0（Credit 非必须） | https://opengameart.org/sites/default/files/kenney_piratepack.zip | 船 20-113 px、tile 64x64、配件小尺寸（船帆、桅杆、炮、船员、锚、信号旗） | 多艘船（small/large/dinghy）+ 大小船帆 + 桅杆 + 瞭望台 + 炮 + 子弹 + 船员 + 海图 + Effects（火焰、爆炸、水花） | **中**——内容极丰富，但船只实际是侧视（front-side）、tile 调色为亮米黄卡通扁平风，需要重调色 + 视角处理；Effects 是顶级附加资源 |
| 5 | Animated Ocean Water Tile | POKOMOKO | https://opengameart.org/content/animated-ocean-water-tile | CC0 | https://opengameart.org/sites/default/files/WaterTileOcean.gif + Ocean_SpriteSheet.png | WaterTileOcean.gif 128x128（动画），Ocean_SpriteSheet.png 256x64（4 帧 sprite sheet） | 单 tile 32x32 循环波纹动画（4 帧） | **高**——32x32 像素、CC0、循环动画无缝；色彩略深青蓝，可直接做主水层 |
| 6 | The Battle for Wesnoth Water Animation | Zabin (zookeeper 协作) | https://opengameart.org/content/the-battle-for-wesnoth-water-animation | CC0 | https://opengameart.org/sites/default/files/oceanNew.gif + BFWwater+Zremix.gif + Zwater(160x64).png | oceanNew.gif 342x180（动画预览）、Zwater 160x64（10 帧 sprite sheet） | ZRPG 重制的深海/浅海无缝循环 tile 动画 | **高**——CC0、32x32 像素、波纹细腻，更接近"潮汐"意境；可与 POKOMOKO 二选一做主水层 |
| 7 | Top-Down Grass, Beach & Water Tileset | Matiaan | https://opengameart.org/content/top-down-grass-beach-and-water-tileset | CC0 | https://opengameart.org/sites/default/files/terrain_1.png + terrain_tiles24.png | terrain.png 576x576（24x24 tile grid）、terrain_tiles24.png 256x256 | 海岸过渡 tile：海 -> 浅滩 -> 沙滩 -> 草甸 -> 裸土，含斜角过渡 tile | **高**——俯视像素、明确含"海/岸/草"三相过渡，正是港口地形需要的形态 |
| 8 | 2D Outdoor 32x32 Tileset | aeren108 | https://opengameart.org/content/2d-outdoor-32x32-tileset | CC0 | https://opengameart.org/sites/default/files/tileset32x32.png | tileset32x32.png 288x256，9 个 32x32 tile（8 个主 tile + 1 个 32x256 装饰带） | 草、水、土、混合过渡 4x2 网格，含完整海/岸/草过渡 | **高**——CC0、32x32、清晰正交过渡，可作"Buch tileset"的备选/补充风格 |

> 备注：Buch tileset（#1）的 `sheet.png` 实际尺寸 640x288，按 32x32 切分约 9 行 x 20 列 = 180 个 tile，密度与本项目"32x32 tile"硬性要求严格对齐。

---

## 推荐 TOP 3

### 1. [LPC] Ship (bluecarrot16) —— `lpc-ship.zip`
**理由**：这是市面上极少数真正 top-down 像素风帆船中质量最高的一档。模块化分解（船体 / 甲板 / 桅杆 / 帆 / 索具 / 炮 / 桅顶台）允许自由组合大帆船、双桅小船、改装战舰等不同尺度的"船单位"，单 tile 32x32 切合硬性要求。许可证为 OGA-BY 3.0+ / CC-BY 3.0+ / GPL 2.0+ 三选一，便于在不同发布渠道保留署名或转 GPL。**对世界观的契合**：木质暖色船体 + 余烬橙帆面，与"己方高光暖珊瑚/余烬橙"配色一致，不需要大改色即可直接做关卡里出现的友方旗舰或敌方巨型 Boss 船。

### 2. Outdoor 32x32 Tileset (Buch) + Top-Down Grass/Beach/Water Tileset (Matiaan) + 32x32 Static Water Tileset (TearOfTheStar) —— 组合方案
**理由**：三者拼起来刚好覆盖"海 + 浅滩 + 滩涂 + 草甸 + 石地 + 残垣塔"的港口地形需求：
- Buch 提供石质塔基 + 水 + 石地的硬派基础地形，密度完全匹配；
- Matiaan 提供"海水 -> 沙滩 -> 草地"过渡，是港口关卡里浅水航行时需要的形态；
- TearOfTheStar 提供静态海浪 tile，可作为深水主层。

三者均为 CC0 / CC-BY-3.0，许可证干净。**对世界观契合**：冷青蓝水色调与"冷青灰暮潮海洋"完全一致；陆地绿色调可走 Godot Color Correction 改成暮色冷青 + 礁石暖橙的双色相。所有 tile 都是 32x32，可直接进 Godot TileMap。

### 3. The Battle for Wesnoth Water Animation (Zabin) —— `oceanNew.gif` + `Zwater.png`
**理由**：在所有"水"候选中，BFW/ZRPG 改色版是最贴合"潮汐"语义的：动画帧更密（10 帧），波纹细节（深浅海分层）更适合做主循环水层。CC0 许可证 + 32x32 像素 + 与 Buch tileset 视觉风格相近（都是 ZRPG/DB32 系调色），可直接覆盖到 Matiaan 或 Buch tile 之上的水层，做成"潮汐涌动"动画。备选是 POKOMOKO 的 4 帧版，更轻量但帧数较少。

---

## 候选访问与下载详情

- **候选数量**：8 个候选全部下载成功（任务要求 5-8），总下载量约 11 MB（其中 Kenney Pirate Pack 占 2.5 MB、LPC Ship 占 0.93 MB、BFW Water Animation 占 1.7 MB）。
- **保存位置**：`D:\mydev\games\Tower Defense\assets\vendor\hunt\oga-terrain\`，每个候选一个独立子目录，子目录内保留原始 ZIP / PNG 文件并附 `extracted/` 解压产物（用于人工视觉抽检）。
- **下载顺序**（间隔 1-2 秒）：Buch sheet -> TearOfTheStar water -> LPC Ship zip -> Kenney Pirate Pack zip -> POKOMOKO water -> BFW Water -> aeren108 Outdoor -> Matiaan grass/beach/water。
- **验证方式**：
  - 用 `file` 命令确认每个 PNG/GIF 的真实类型与像素尺寸；
  - 用 `unzip -l` / `unzip -d extracted/` 验证 zip 包未损坏并查看内含；
  - 用 PIL 读取关键图（`lpc-ship-preview.png` 2358x1799、`sheet.png` 640x288、`tileset32x32.png` 288x256 等）的尺寸与 mode，确认是 8-bit RGBA 像素图。

## 遇到的访问障碍 / 跳过记录

| 候选 | 问题 | 处理 |
|---|---|---|
| Whispers of Avalon: Animated Ocean Tileset | CC-BY-SA，违反"拒绝 CC-BY-SA"硬性规则 | 跳过，未下载 |
| [LPC] Wooden Ship Tiles (Reemax) | 混合 CC-BY-SA + GPL，水 tile 属 Sharm，违反规则 | 跳过 |
| RPG Pirate Ship Tile Set | 标注"Free to use"措辞模糊，未挂 CC0/CC-BY 正式元数据；且 8x8 tile 太小 | 跳过 |
| Isometric road tiles (water expansion) | CC0，但等距 (isometric) 视角，违反"禁止等距视角"硬性规则 | 跳过 |
| Pixel Art Top Down Rocks Pack | CC-BY-SA 4.0，违反规则 | 跳过 |
| Exterior 32x32 Town tileset (Arthur Carvalho) | CC-BY-SA 4.0，违反规则 | 跳过 |
| Free CC0 Top Down Tileset Template (16x16) | 密度 16x16 低于项目硬性要求 32x32 | 不下载，列为备选低密度原型 |
| Pirate Pack (Kenney) "top-down perspective" 页面文字 | 实际 PNG 是侧视（front-side），tile 偏亮米黄卡通扁平风；保留为"Effects/海盗素材复用"参考 | **已下载并入候选 #4**，但风格匹配评为"中"，建议仅复用 Effects（火焰/爆炸/水花） |

## 后续建议

1. **统一调色板**：将 Buch、Matiaan、aeren108 三套 tileset 统一映射到项目自定义的"冷青灰暮潮 + 暖珊瑚余烬"调色板，可写一个 Godot `EditorScript` 批量将源 PNG 颜色替换为项目调色（按 tile 不破坏 32x32 网格）。
2. **船的二次加工**：Kenney 船需要改回真正的 top-down（用 GIMP/Aseprite 把桅杆/帆翻转成俯视），或仅取其 Effects 资源（爆炸/火焰/水花）作为 VFX 来源。
3. **加水动画**：用 BFW/Zabin 的 10 帧水动画做"潮汐层"，叠在 Matiaan/Buch 的静态水 tile 之上，做成可调速度的水流。
4. **礁石缺口**：本次未找到单一"礁石 top-down 像素"包（Buch tileset 里的石地可部分替代），后续可单独从 Kenney isometric rocks / Quaternius rocks 中寻找补齐。
5. **下个猎手**：本报告专注地形 + 船，下一阶段应搜"敌人 / 塔 / VFX / 闸门"——可在 OGA 搜 `top down` + `creature` / `tower defense` / `cannon` / `gate` 等关键词。
