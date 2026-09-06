# Tower Defense (像素俯视角塔防) — 技术与生产研究

> **调研状态**:初稿 (DRAFT)
> **撰写日期**:2026-09-04
> **目标读者**:0 基础、唯一开发者的项目主理人(同时也是用户)
> **目标产出**:不包含 demo / MVP 的完整可发布塔防(目标参考 Kingdom Rush,但不复制)
> **引擎**:Godot 4.x(下文锁定具体版本,见 §0.3)
> **本文档作用**:技术选型 + 系统架构 + 制作顺序 + 风险清单。其他 PRD / 美术 / 音频调研交由另外的文档承担。

---

## 目录

- [0. 术语、版本与方法学](#0-术语版本与方法学)
- [1. 项目架构与目录约定](#1-项目架构与目录约定)
- [2. 像素艺术渲染配置(2D 渲染、Texture Filter、Viewport Stretch)](#2-像素艺术渲染配置2d-渲染texture-filterviewport-stretch)
- [3. TileMap 与 TileMapLayer(地图 / 地形 / 路径)](#3-tilemap-与-tilemaplayer地图--地形--路径)
- [4. 导航与寻路](#4-导航与寻路)
- [5. 波次系统(Wave Manager)](#5-波次系统wave-manager)
- [6. 敌人 AI(FSM + NavigationAgent2D)](#6-敌人-aifsm--navigationagent2d)
- [7. 塔、投射物与状态效果](#7-塔投射物与状态效果)
- [8. 资源数据化(Resource / JSON)](#8-资源数据化resource--json)
- [9. 存档系统](#9-存档系统)
- [10. UI 系统](#10-ui-系统)
- [11. 音频系统](#11-音频系统)
- [12. 性能优化与对象池](#12-性能优化与对象池)
- [13. 测试](#13-测试)
- [14. 发布与导出](#14-发布与导出)
- [15. 范围控制与制作顺序(规划)](#15-范围控制与制作顺序规划)
- [16. 来源汇总、许可证与版本注意事项](#16-来源汇总许可证与版本注意事项)
- [17. 风险、不确定性与未决议题](#17-风险不确定性与未决议题)
- [18. 后续步骤(交付给下一阶段的钩子)](#18-后续步骤交付给下一阶段的钩子)

---

## 0. 术语、版本与方法学

### 0.1 文档约定

- **【事实】**:截至 2026-09 可在官方文档/源码/权威媒体直接验证的条目,会附 URL。
- **【建议】**:基于事实或行业惯例给出的方案选择;非强制,可以讨论。
- **【警告】**:容易踩坑的地方,务必注意。
- **【待决】**:仍未敲定,需要后续 PRD/美术调研输入的开放议题。

### 0.2 范围与边界

- **包含**:引擎选型、目录架构、像素艺术渲染配置、TileMap/TileMapLayer、Navigation2D、波次/AI/塔/投射物/状态效果、资源数据化、存档、UI、音频、性能、测试、发布流程、制作顺序、范围控制。
- **不包含**:具体美术资产清单(由 `ART_ASSETS_RESEARCH_DRAFT.md` 接管)、具体音频资产清单(由 `AUDIO_ASSETS_RESEARCH_DRAFT.md` 接管)、完整 PRD(由 `PRD_DRAFT.md` 接管,但本文档会给出 §15 范围控制表以便后续 PRD 直接复用)。
- **Kingdom Rush 借鉴但不复制**:仅借鉴机制分类与教学曲线,不复制其手绘卡通美术、原版角色、关卡、文本。

### 0.3 引擎版本锁定

【事实】截至 2026-09,Godot 官方稳定版本与发布时间线(来源:[Godot 4.5 release notes](https://godotengine.org/releases/4.5/)、[Godot release policy](https://docs.godotengine.org/en/latest/about/release_policy.html)):

| 版本 | 发布时间 | 支持等级 |
|---|---|---|
| Godot 4.5 | 2025-09 | 仅安全/平台补丁 |
| Godot 4.6 | 2026-01-26 | 常规修复(包含 Jolt Physics 默认、Modern 主题、Direct3D 12 默认) |
| Godot 4.7 "Director's Cut" | 2026-06-18 | **当前最新稳定**(HDR 输出、AreaLight3D、Wasm64、内置 Asset Store、Transform Offset、VirtualJoystick) |
| Godot 4.8 (master) | 2026 Q4 预计 | 开发中,可能引入破坏性改动 |

【建议】采用 **Godot 4.7 LTS 风格稳定线**作为目标版本,理由:
- 4.7 是当前最新稳定,带 HDR 输出、Asset Store、VirtualJoystick 等利好单人/小团队项目的新功能。
- 4.8 仍在 master 分支,可能引入 API 破坏性改动;**不建议**在 0 基础个人项目上做开发版。
- 在项目开始时,在 `project.godot` 头部写明 `config/features=PackedStringArray("4.7")`,锁定 minor 版本向上兼容。
- 日常开发每周同步到 4.7.x patch 即可,不在 4.7 升 4.8 之前预先采用 4.8 API。

【警告】若选用 4.6 或更早,**不要**使用 `4.7+` 才有的 `TileMapLayer` 新行为或 Wasm64 导出(详见 §3、§14)。如决定退到 4.6,需在 §15 制作顺序里专门标注 API 差异。

### 0.4 调查方法

- 优先官方文档、Godot 官方博客、`docs.godotengine.org` 镜像、本地已 clone 的子模块 `submodules/minimax-skills`/`submodules/superpowers`(如有相关 skill)。
- 其次是 GDQuest / KidsCanCode / GameDeveloper 等知名 Godot 教程站。
- 社区博客、Medium、CSDN、Reddit 仅作为补充,具体 API 用法必须在官方文档中复核。
- 对于 Kingdom Rush 机制与术语,使用 101games / seeles / omnigames / wiki 类来源交叉核对(避免单一来源偏差)。
- **重要**:本文档不引用未经核实的 AI 生成片段;凡是带有"AI 给出……"的字段,本调研一律不用。

---

## 1. 项目架构与目录约定

### 1.1 单例(AutoLoad)与信号总线

【事实】Godot 4.x 的 AutoLoad 是在场景树加载之前注入 `/root` 的节点,常用于跨场景保持存活的对象(来源:[Godot 4.0 Docs — Singletons (Autoload)](https://docs.godotengine.org/en/4.0/tutorials/scripting/singletons_autoload.html))。官方与社区建议:
- AutoLoad **不是** OOP 意义上的 Singleton,而是"全局可达的根节点"。
- AutoLoad 的初始化顺序遵循 **Project Settings → Autoload** 中的顺序。
- Godot 4 推荐使用 **typed signal**(直接 `signal foo(arg: int)`)而不是字符串拼装事件名。

【建议】本项目的 AutoLoad 划分(候选,可在 §17 待决项讨论):

| AutoLoad 名 | 职责 | 信号示例 |
|---|---|---|
| `EventBus` | 全局信号总线,只传事件,不存状态 | `wave_started(wave_index)`, `enemy_killed(enemy_type)`, `tower_sold(tower_type)`, `gold_changed(value)`, `lives_changed(value)` |
| `GameManager` | 当前关卡、玩家生命、暂停/退出 | `level_completed`, `level_failed` |
| `SaveManager` | 存档读写、版本迁移、加密(可选) | `save_loaded`, `save_failed` |
| `SettingsManager` | 音视频设置、键位(用 ConfigFile 落到 user://) | `setting_changed(key)` |
| `AudioManager` | BGM/SFX/UI 音效播放与音量 | `bgm_track_changed(track_id)` |
| `SceneManager` | 场景淡入淡出切换、加载界面 | `scene_change_started`, `scene_change_finished` |
| `SceneFlow` | 关卡内阶段:Build → WaveInProgress → …(详见 §5) | `phase_changed(new_phase)` |

【警告】常见的反模式:
- **不要**在 `_init()` 里访问其他 AutoLoad(初始化顺序未保证)。
- **不要**把场景级临时状态塞进 AutoLoad(例如当前关卡的塔列表)。
- **不要**对所有跨节点通信都走 EventBus——父子/兄弟关系应优先用直接 `connect`,否则会形成"signal spaghetti"。
- **不要**依赖 AutoLoad 顺序,通过显式初始化或构造函数参数注入。

### 1.2 目录结构

【建议】基于 [Godot 4.3 Developer Cheatsheet](https://themetalvortex.com/godot-4-3-developer-cheatsheet-game-architecture-workflows)、[godot-development skill](https://www.skillmd.ai/skills/godot-development-1)、[deepwiki Godot-GameTemplate](https://deepwiki.com/nezvers/Godot-GameTemplate/2.1-project-configuration-and-autoloads) 的共识,本项目目录骨架:

```
res://
├── project.godot
├── .gutconfig.json           # 测试配置(§13)
├── default_bus_layout.tres   # 音频总线预设(§11)
├── default_env.tres          # 渲染环境(可选,2D 可省)
├── icon.svg
├── autoload/                 # 全局单例脚本(只放脚本,场景由 Project Settings 注册)
│   ├── event_bus.gd
│   ├── game_manager.gd
│   ├── save_manager.gd
│   ├── settings_manager.gd
│   ├── audio_manager.gd
│   ├── scene_manager.gd
│   └── scene_flow.gd
├── core/                     # 通用底层能力,不依赖游戏内容
│   ├── entity/               # 实体基类(角色、塔、子弹、敌人的共同父)
│   ├── pool/                 # 对象池(§12)
│   ├── data/                 # 数据加载器(CSV/JSON 解析)
│   ├── math/                 # 工具函数
│   └── signals/              # 信号名常量(便于重构)
├── data/                     # 数据资源(策划表)
│   ├── towers/               # TowerData.tres 资源(每塔一个 .tres)
│   ├── enemies/              # EnemyData.tres
│   ├── waves/                # 关卡波次 JSON
│   ├── levels/               # 关卡 JSON(地图、波次、金币初始值、生命上限)
│   ├── status_effects/       # StatusEffectData.tres
│   ├── projectiles/          # ProjectileData.tres
│   └── localization/         # i18n(若做多语言,使用 Godot 内置 Translation)
├── scenes/
│   ├── boot/                 # 启动场景
│   ├── ui/                   # UI(主菜单、暂停、HUD、商店、升级面板、设置、结算)
│   │   ├── components/       # 复用控件(自定义 Button、ProgressBar、IconLabel)
│   │   ├── hud/
│   │   ├── menu/
│   │   └── popups/
│   ├── levels/               # 关卡场景(level_01.tscn、level_02.tscn …)
│   ├── towers/               # 塔的场景模板(每个塔 .tscn)
│   ├── enemies/              # 敌人场景模板
│   ├── projectiles/          # 投射物场景模板
│   ├── effects/              # 粒子、屏幕震动、弹道轨迹
│   └── common/               # 通用场景(光标、放置预览、调试 overlay)
├── scripts/                  # 与场景分离的逻辑脚本(非 autoload)
│   ├── towers/
│   ├── enemies/
│   ├── projectiles/
│   ├── waves/
│   ├── ai/
│   └── ui/
├── assets/
│   ├── art/
│   ├── audio/
│   ├── fonts/
│   └── shaders/
├── tests/                    # GUT/单元测试(§13)
│   ├── unit/
│   └── integration/
└── tools/                    # 编辑器脚本、批处理、ImporterPlugin
```

【警告】
- **不要**把图片/音频直接放在 `res://` 根目录,会让 FileSystem dock 难以浏览。
- **不要**在场景里写大段 GDScript 逻辑,优先抽到 `scripts/` 或 `data/` 的 Resource 类;场景只保留 `@export` 引用。
- 关卡场景里只放关卡专用节点(地图、出生点、终点、初始金币/生命 override),塔与敌人的"模板"应放在 `scenes/towers/`、`scenes/enemies/`。

### 1.3 节点命名、@export、@onready 规范

【建议】在项目根目录放一个 `STYLE_GUIDE.md`(本文档不写,留给后续 PRD)。核心规则:

1. **节点命名**:`PascalCase`,塔类 `TowerBase`/`ArcherTower`、敌人 `EnemyBase`/`GoblinGrunt`、投射物 `ProjectileBase`/`Arrow`。场景文件同名小写 + 下划线(`archer_tower.tscn`)。
2. **`@export` 而非硬编码**:数值常量(伤害、攻速、范围、价格、子弹速度)、引用(场景、动画、贴图)都用 `@export`。这是数据驱动的前提。
3. **`@onready var sprite: Sprite2D = $Sprite2D`**:仅缓存 `_process`/`_physics_process` 中高频访问的节点(见 [godot-development skill](https://www.skillmd.ai/skills/godot-development-1))。**不要**在 `_process` 里反复 `get_node`。
4. **信号命名**:`snake_case`,过去时(动作完成)用 `_ed`、当前时(状态变化)用 `_ing`。例如 `enemy_killed`、`gold_changed`。
5. **类型**:GDScript 2.0 全面用静态类型(`var hp: float = 100.0`)。未类型化变量会让 Godot 4 内部走慢路径。

### 1.4 通信:直接信号 vs EventBus

【建议】判定标准(综合 [openillumi autoload guide](https://openillumi.com?p=71244/) 与 [skills.cat godot-autoload-architecture](https://skills.cat/skills/thedivergentai/gd-agentic-skills/godot-autoload-architecture)):
- 父子/兄弟:用直接 `connect`。
- 跨场景/跨关卡/跨系统:用 EventBus。

事件总线在 Godot 4 推荐写法(typed signal):

```gdscript
# autoload/event_bus.gd
extends Node

signal wave_started(wave_index: int)
signal wave_completed(wave_index: int, reward: int)
signal enemy_killed(enemy_type: StringName, position: Vector2, gold: int)
signal enemy_reached_end(enemy_type: StringName)
signal tower_placed(tower_id: StringName, cell: Vector2i)
signal tower_sold(tower_id: StringName, refund: int)
signal tower_upgraded(tower_id: StringName, new_tier: int)
signal gold_changed(new_amount: int)
signal lives_changed(new_amount: int)
signal phase_changed(new_phase: StringName)  # build / wave / win / lose
signal level_completed
signal level_failed
signal pause_toggled(is_paused: bool)
```

【警告】EventBus **不要存状态**(它是总线,不是数据仓)。需要持久数据就放到 `GameManager` 或 `SaveManager`。

---

## 2. 像素艺术渲染配置(2D 渲染、Texture Filter、Viewport Stretch)

> 国王之泪/Bloons 等现代像素风塔防都基于"低基础分辨率 + 整数缩放 + Nearest 过滤"。本节是工程的"地基配置",务必一次做对。

### 2.1 关键事实

【事实】Godot 4.x 的像素艺术配置由三类设置共同决定(来源:[GDQuest — Setting up pixel art graphics in Godot 4](https://www.gdquest.com/library/pixel_art_setup_godot4/)、[sprite-ai — godot-sprites pixel-perfect guide](https://www.sprite-ai.art/guides/godot-sprites)、[bugnet — Fix Blurry Pixel Art in Godot](https://bugnet.io/blog/how-to-fix-godot-pixel-art-blurry)):

1. **Texture Filter**:纹理采样过滤方式。
   - `0 = Nearest`(硬边缘,像素艺术必需)。
   - `1 = Linear`(默认,会让像素糊)。
2. **Viewport Stretch Mode**:渲染时整体如何被缩放到窗口。
   - `disabled`:不做缩放,窗口 = 视口。
   - `canvas_items`:以基础尺寸为参考,在窗口内渲染并保持比例。适合"像素精灵 + 平滑 UI"。
   - `viewport`:严格把整个视口缩放到窗口。**最严格的像素完美**,但 UI/粒子/补间动画也一起像素化。
3. **Stretch Aspect**:窗口长宽比不匹配时的处理。
   - `ignore`:拉变形。
   - `keep`:加黑边(像素艺术推荐)。
   - `keep_width` / `keep_height`:以一边为准。
4. **Stretch Scale Mode**(Godot 4.3+):`fractional`(允许任意小数缩放) / `integer`(仅整数倍缩放,像素艺术推荐)。
5. **Snap 2D Transforms to Pixel**:防止精灵亚像素抖动。

### 2.2 推荐的 `project.godot` 配置(像素俯视角塔防)

【建议】直接复制到 `project.godot`(只列相关段):

```ini
[application]
config/name="Tower Defense"
config/features=PackedStringArray("4.7", "Forward Plus")  # 或 "Mobile" / "Compatibility";见 §17 待决

[display]
window/size/viewport_width=426
window/size/viewport_height=240
window/stretch/mode="viewport"
window/stretch/aspect="keep"
window/stretch/scale_mode="integer"  # Godot 4.3+ 才有
window/stretch/mipmap=false

[rendering]
renderer/rendering_method="forward_plus"
renderer/rendering_method.mobile="mobile"
textures/canvas_textures/default_texture_filter=0  # Nearest
textures/canvas_textures/default_texture_repeat=0   # Disable repeat (1) for cleaner pixels
textures/default_filters/anisotropic_filtering_level=0
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true

[gui]
theme/default_font_pixel_snap=true
```

【事实】为什么是 `426×240`?
- 这是 16:9,业界常用"复古"基础分辨率(SNES 256×224、PSP 480×272、3DS 400×240)。塔防一般需要看到更多横向地图,**426×240 是实用下限**。
- 整数缩放下,1080p 显示器只能放下约 4× = 1704×960,会有黑边;如果必须 1080p 满屏,可改 480×270(整数缩放 4×=1920×1080) 或放弃 integer 缩放。

【警告】
- 修改 `default_texture_filter` 之前已经导入的纹理仍是 Linear 过滤;必须 **删除 `.godot/imported/` 缓存并重新 Reimport**,或逐张图在 Import 面板取消 `Filter`。
- `viewport` 模式会像素化 UI 文本。如果用高质量 UI,**改用 `canvas_items`**;若坚持 viewport,字体大小必须为基础分辨率的整除数。
- `forward_plus` 不支持 HTML5/Web 导出(Web 仅 `compatibility`);见 §14 发布。
- 如果未来要导出 Web,**`renderer/rendering_method.mobile="mobile"` 也不可用,Web 必须用 `compatibility`**。

### 2.3 相机

【事实】`Camera2D` 的关键属性(`zoom`、`limit`、`position_smoothing_enabled`、`rotation_smoothing_enabled`)。
- `zoom` 在像素艺术中应保持 **整数倍**(`Vector2(1,1)`、`Vector2(2,2)`)。亚整数会让相机在窗口上做亚像素采样,出现抖动。
- `limit_left/right/top/bottom` 用来把相机锁在地图内。
- 关闭 smoothing 或仅开 position_smoothing(塔防通常不需要相机旋转)。

【建议】塔防相机行为:
- 默认跟玩家视野中心(如关卡中心),玩家按方向键或右键拖动平移。
- 缩放档位:1×、1.5×、2×(像素艺术里 1.5× 容易抖动,可考虑只给整数档)。

【警告】像素艺术里不要把 `zoom` 设为 `Vector2(0.5, 0.5)`(放大) + smoothing——会出现"波纹"。必须整数或关闭 smoothing。

---

## 3. TileMap 与 TileMapLayer(地图 / 地形 / 路径)

### 3.1 TileMapLayer 与 TileMap 的区别

【事实】Godot 4.3 起,`TileMapLayer` 作为 **节点**被引入,取代旧的 `TileMap` 单一节点(来源:[CSDN EP11: 初识瓦片地图](https://blog.csdn.net/luckyrui123/article/details/155442298)、[Coco Code — Godot 4.3 TileMap Tutorial](https://forgame.su/ru/videos/43sJIWaj2Yw/godot-4-3-tilemap-tutorial-layers-collisions-and-more)、[Godot Docs Using TileMaps](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html))。
- `TileMapLayer` 把"绘制、碰撞、自定义数据、物理"分到独立的子节点,每个 TileMapLayer 是一个 layer。
- 一个 `TileMap` 节点下可有多个 `TileMapLayer`,共享 `TileSet` 资源。
- TileSet 资源管理 atlas、terrain、physics layer、navigation layer、自定义 data layers。

### 3.2 推荐的地图图层结构

【建议】本项目每个关卡采用如下分层(从下到上):

| 层 | TileMapLayer 名 | 用途 | 物理 | 导航 |
|---|---|---|---|---|
| 0 | `Background` | 草地 / 沙漠 / 雪地等底色 | 无 | 无 |
| 1 | `TerrainDecor` | 装饰(石头、树、花) | 无 | 无 |
| 2 | `Path` | 路径瓦片(敌人走的路) | 障碍物 | 不可走(挖空) |
| 3 | `Buildable` | 可建造地形(高亮) | 无 | 无 |
| 4 | `Placeholders` | 出生点、终点、特殊格子标记 | 否 | 仅起点/终点用作路径点 |
| 5 | `Overlay` | 射程范围、放置预览(运行时绘制) | 否 | 否 |

【事实】多个 `TileMapLayer` 共享同一 `TileSet` 资源,但各自维护 cell 数据;Z-index/Y-sort 可独立配置。

### 3.3 TileSet 与 Autotile / Terrain

【事实】Godot 4.x 的 TileSet 支持(来源:[uhiyama-lab — Setting Up Autotiling with the Terrains Feature](https://uhiyama-lab.com/en/notes/godot/terrains-autotile-setup/)、[dodatech — Fix TileMap Terrain Sets](https://tutorials.dodatech.com/quick-fix/godot-tilemap-terrain)):
- **Terrain**:为瓦片打"位标记"(peering bits),`set_cells_terrain_connect()` 自动连接相邻同 terrain 的瓦片,生成无缝地形。
- **Autotile bitmask**:位掩码自动拼接(2×2 wall、2×2 corner、3×3 square 等)。
- **自定义数据层**:在 TileSet 上为每个瓦片设置自定义 metadata(例如 `buildable: true`, `path_id: 3`),可在脚本里通过 `TileData.get_custom_data("buildable")` 读取。

【建议】本项目用 **Terrain Set**(不是 Autotile bitmask):
- 至少 2 个 Terrain:`Path`(路径)、`Buildable`(可建)。
- 制作 3×3 minimal terrain 套装(8 张 + 中心),实现"路 → 自然过渡到草地"。
- 配合 `set_cells_terrain_connect()` 让关卡设计师像画路一样连线。

### 3.4 塔位放置校验(塔防关键路径)

【事实/建议】本项目的塔位校验应分层处理(综合 [vav-labs — Godot Tower Defense Path Validation](https://vav-labs.com/blog/tower-defense-path-validation-in-godot/)、[tutorials.dodatech](https://tutorials.dodatech.com/quick-fix/godot-tilemap-terrain)、[godottd skill](https://lobehub.com/skills/erikhazzard-vasir-tower-defense)):

```gdscript
# 伪代码:放置一个塔前的检查
func can_place_tower(cell: Vector2i) -> bool:
    # 1. 边界
    if not tile_map_layer.is_in_bounds(cell):
        return false
    # 2. 必须是 Buildable 地形(从自定义数据读)
    var tile_data: TileData = tile_map_layer.get_cell_tile_data(cell)
    if tile_data == null or not tile_data.get_custom_data("buildable"):
        return false
    # 3. 不能已经被占用
    if occupancy.has(cell):
        return false
    # 4. 不能完全堵死路径
    if not validate_path_exists_after_blocking(cell):
        return false
    # 5. 玩家金币够不够
    return gold >= tower_cost

func validate_path_exists_after_blocking(cell: Vector2i) -> bool:
    # 关键模式:把该 cell 临时设为不可走,跑一遍 A*,再恢复
    var was_solid: bool = astar_grid.is_point_solid(cell)
    astar_grid.set_point_solid(cell, true)
    var path: PackedVector2Array = astar_grid.get_id_path(start_cell, goal_cell)
    astar_grid.set_point_solid(cell, was_solid)
    return not path.is_empty()
```

【关键事实】vav-labs 文章的发现(来源:[vav-labs](https://vav-labs.com/blog/tower-defense-path-validation-in-godot/)):
- **不要**只检查"当前 cell 是 buildable",还要 **校验放塔后所有出生点到终点的路径仍然存在**。这是 Kingdom Rush 的核心规则:玩家永远不能把路堵死。
- 这个校验在每张地图初始时跑一次缓存"出生点列表 + 终点列表 + 出生-终点组合数";放置时只对受影响组合重算。

### 3.5 关卡数据格式(初稿)

【建议】关卡 JSON 雏形(后续 PRD 会扩展):

```jsonc
// data/levels/level_01.json
{
  "id": "level_01",
  "name_key": "LEVEL_FOREST_OUTPOST",
  "map": {
    "tileset": "res://assets/art/tilesets/forest.tres",
    "size_cells": [40, 24],
    "background_layer": 0,
    "terrain_layer": 1,
    "path_layer": 2,
    "buildable_layer": 3
  },
  "spawn_points": [[0, 12]],
  "goal_point": [39, 12],
  "starting_gold": 200,
  "starting_lives": 20,
  "waves": [
    "res://data/waves/level_01_waves.json"
  ]
}
```

---

## 4. 导航与寻路

### 4.1 NavigationServer2D 与 NavigationRegion2D

【事实】Godot 4.x 的导航(来源:[WebSearch synthesis on NavigationServer2D](https://www.google.com/search?q=Godot+4+NavigationServer2D+NavigationRegion2D+dynamic+obstacles)):

- `NavigationServer2D` 是 singleton,**不要**自己 new,直接 `NavigationServer2D.xxx` 访问。
- `NavigationRegion2D` 是一个 2D 区域,持有一个 `NavigationPolygon`,通过 `bake_navigation_polygon()` 烘焙。
- 烘焙源几何由 `NavigationPolygon.source_geometry_mode` 决定:
  - `GROUP_WITH_CHILDREN`:节点和所有子节点的 CollisionShape;
  - `GROUP_EXPLICIT`:显式列出的节点;
  - `ROOT_NODE_CHILDREN`:仅根节点的直接子节点。
- **动态障碍**用 `NavigationObstacle2D`(圆形 radius 或多边形 vertices)。
- **寻路代理**用 `NavigationAgent2D`(子节点),自动绕过 `NavigationObstacle2D`。
- 不要在每帧重烘焙 `NavigationRegion2D`,那是 **静态** 通道。

### 4.2 塔防的最佳实践:静态导航 + 动态阻塞

【建议】结合 vav-labs 的塔防路径校验经验与 Godot 4 Navigation API,本项目采用 **AStarGrid2D + 临时 set_point_solid** 的简化方案,理由:
1. 塔防关卡的"可走图"在关卡内是固定(地图布局不变),变的只是塔本身。完全用 NavigationServer2D 太重。
2. AStarGrid2D 用 cell 索引,正好对应 TileMapLayer 的 cell。
3. 校验放塔时是否堵死路径,只需 `set_point_solid` + `get_id_path` + 恢复,**单次 O(N)**。

【事实】备选方案(若 AStarGrid2D 不够用):
- 用 `NavigationServer2D.map_get_path()` 跑 NavigationRegion2D,支持避障和斜线,但更复杂。
- 用 `AStar2D`(点图),自己定义连接;灵活但要手写。

【建议】 **MVP-2 阶段(放塔与路径校验)采用 AStarGrid2D**。后续如果要做"可破坏地形"或"会移动的塔"再升级到 NavigationServer2D。

### 4.3 AStarGrid2D 的初始化

【伪代码】

```gdscript
func _ready():
    var grid := AStarGrid2D.new()
    grid.region = Rect2i(0, 0, map_size_x, map_size_y)
    grid.cell_size = Vector2(16, 16)  # 与 TileMap tile_size 一致
    grid.update()
    # 标记 path 瓦片为不可走
    for cell in path_cells:
        grid.set_point_solid(cell, true)
    astar_grid = grid
```

---

## 5. 波次系统(Wave Manager)

### 5.1 波次数据的两种模式

【事实/建议】业内两种主流做法(综合 [GameMaker forum — Wave System in Tower Defense](http://forum.gamemaker.io/index.php?threads/wave-system-in-tower-defense.110877/)、[DeepWiki — Wave and Team Management (YouTD2)](https://deepwiki.com/handongdong-patsnap/youtd2/3.4-wave-and-team-management)、[towertido GDD v1.2](https://www.github.com/StArias-Projects/Towertido/wiki/GDD-v1.2-eng)、[godottd skill](https://lobehub.com/skills/erikhazzard-vasir-tower-defense)):

| 模式 | 优点 | 缺点 | 适用 |
|---|---|---|---|
| **手动编排** (`waves = [{enemy: "Goblin", count: 10, delay: 1.0}, ...]`) | 设计可读、可控、可重现 | 难做"动态难度" | 关卡 BOSS 波、固定叙事节奏 |
| **威胁预算 + 加权**(`budget = base × (1 + n × rate); weighted random pick`) | 易扩展、易调参、动态难度 | 难精确控制 | 无限模式 / 程序生成 |

【建议】 **本项目主用"手动编排 JSON",关卡元数据可标注难度倍率**;无限模式再用威胁预算。

### 5.2 推荐的波次数据格式

```jsonc
// data/waves/level_01_waves.json
{
  "level_id": "level_01",
  "waves": [
    {
      "index": 1,
      "pre_delay": 5.0,
      "groups": [
        { "enemy": "goblin_grunt", "count": 8, "interval": 1.0, "spawn_at": [0, 12] }
      ],
      "reward_gold": 30,
      "reward_xp": 0
    },
    {
      "index": 2,
      "pre_delay": 8.0,
      "groups": [
        { "enemy": "goblin_grunt", "count": 10, "interval": 0.8 },
        { "enemy": "goblin_runner", "count": 4, "interval": 0.6, "delay_after_prev": 6.0 }
      ],
      "reward_gold": 35
    }
  ]
}
```

字段说明:
- `pre_delay`:波次开始前倒计时(给玩家准备时间)。
- `groups`:本波的所有敌人群组;组之间可以并行或串行(`delay_after_prev` 控制相对偏移)。
- `interval`:同组内连续两次生成的间隔(秒)。
- `reward_gold`:全部敌人被击杀后奖励金币(可选)。

### 5.3 WaveManager 的状态机

【建议】关卡内阶段拆为(基于 [lobehub godot-genre-tower-defense](https://lobehub.com/skills/thedivergentai-gd-agentic-skills-godot-genre-tower-defense)):

```
IDLE → BUILD (等待玩家点击"开始波次") → WAVE_PRE_DELAY (倒计时) → WAVE_SPAWN (生成中)
   → WAVE_CLEAR (本波所有敌人消失) → (有下一波? 是 → BUILD;否 → WIN)
任意阶段接 LOSE 转换:敌人到达终点且 lives ≤ 0 → LOSE → END
```

伪代码:

```gdscript
class_name WaveManager extends Node

signal phase_changed(new_phase: StringName)
signal wave_started(wave_index: int)
signal wave_completed(wave_index: int)
signal level_completed
signal level_failed

enum Phase { IDLE, BUILD, WAVE_PRE_DELAY, WAVE_SPAWN, WAVE_CLEAR, WIN, LOSE }

var phase: Phase = Phase.IDLE
var wave_index: int = 0
var waves_data: Array = []
var alive_enemies: int = 0

func _ready():
    EventBus.enemy_killed.connect(_on_enemy_killed)
    EventBus.enemy_reached_end.connect(_on_enemy_reached_end)

func start_wave_button_pressed() -> void:
    if phase != Phase.BUILD: return
    _enter_phase(Phase.WAVE_PRE_DELAY)

func _process(delta: float) -> void:
    match phase:
        Phase.WAVE_PRE_DELAY:
            ...
        Phase.WAVE_SPAWN:
            # 维护 spawn timers
            ...
```

### 5.4 早期加速、动态难度、平衡常数

【事实】业内常见平衡公式(综合 [godottd skill](https://lobehub.com/skills/erikhazzard-vasir-tower-defense)、[FPS TD Toolkit — Weighted Wave Spawn Controller](https://unrealpossibilities.blogspot.in/2018/03/fps-tower-defense-toolkit-basics_2.html)):

- **威胁预算**:`budget = baseBudget × (1 + waveNumber × growthRate)`, `growthRate ≈ 0.08 ~ 0.15`。
- **敌人 HP 倍数**:`hpMultiplier = 1 + waveNumber × scalingFactor`, `scalingFactor` 决定 Casual/Normal/Veteran。
- **金币收入**:击杀奖励随波次缓慢上升;玩家建造/升级支出是控制曲线的手柄。

【建议】这些公式做成 `BalanceConfig.tres` 资源,放 `data/balance.tres`,策划可以直接在 Godot 编辑器调而不改代码。

### 5.5 波次预览(避免信息黑箱)

【建议】HUD 的"下一波预览"显示:
- 敌人类型 + 数量(用占位图标,**不要**实例化真敌人,否则可能误触)
- 预计总金币奖励
- 是否有 BOSS
- 总威胁等级(数字 1–5 星)

【事实】Godot 4 中"假敌人"用 `Sprite2D + 占位贴图`,不要挂物理体或脚本;见 [yyz-productions Making TD Part 3](https://yyz-productions.com/2015/12/01/making-a-tower-defense-game-part-3/) 的 "DummyEnemy" 模式。

---

## 6. 敌人 AI(FSM + NavigationAgent2D)

### 6.1 是否需要 FSM?

【事实】塔防中敌人 AI 通常极简:**沿路径走到终点**,遇到"前堵后塞"时减速,只有 BOSS 才有"冲刺 / 召唤 / 狂暴"等复杂行为。
- 普通敌人:只需要"朝下一个路径点移动 + 受击处理 + 死亡",**不需要完整 FSM**。
- BOSS / 精英:有限状态机(IDLE → CHASE → ENRAGED → DEAD)是必需的。

【建议】实施分层:
- **`EnemyBase`(基类,所有敌人)**:HP、移动、受伤、死亡、击退、生成经验宝石。
- **`BasicEnemy`(继承)**:线性沿路径走。
- **`BossEnemy`(继承)**:持有一个 `StateMachine` 子节点,挂多个 `State`(如 IdleState、ChaseState、EnragedState、DeathState)。

### 6.2 移动方式的选择

【事实】两种实现:

| 方式 | 说明 | 适用 |
|---|---|---|
| 沿预存路径点列表 | 关卡设计时固定 `Path2D.curve` 或 `Vector2[]` 列表,敌人逐点 `move_toward` | 关卡固定(99% 塔防) |
| NavigationAgent2D | 烘焙导航多边形,运行时算路 | 关卡动态 / 多路径 / 可破坏地形 |

【建议】本项目采用 **预存路径点**(每个关卡 `PathPoints: Vector2[]` 资源)。理由:
- 关卡是手绘的固定地图,不需要运行时避障。
- 性能更好(无须 NavigationServer)。
- 教学曲线、关卡编辑器、设计师沟通都更简单。

### 6.3 敌人基类骨架

```gdscript
# scripts/enemies/enemy_base.gd
class_name EnemyBase
extends CharacterBody2D

@export var data: EnemyData
@export var move_speed: float = 60.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar

var path_points: PackedVector2Array
var path_index: int = 1
var current_hp: float

func _ready() -> void:
    current_hp = data.max_hp
    hp_bar.max_value = data.max_hp
    hp_bar.value = current_hp

func _physics_process(delta: float) -> void:
    if path_index >= path_points.size():
        _reached_goal()
        return
    var target := path_points[path_index]
    var dir := (target - global_position).normalized()
    velocity = dir * move_speed
    move_and_slide()

func take_damage(amount: float, source: Node) -> void:
    current_hp -= amount
    hp_bar.value = current_hp
    if current_hp <= 0.0:
        die(source)

func die(killer: Node) -> void:
    EventBus.enemy_killed.emit(data.id, global_position, data.gold_reward)
    GameManager.add_gold(data.gold_reward)
    # 生成 XP gem / loot
    queue_free()

func _reached_goal() -> void:
    EventBus.enemy_reached_end.emit(data.id)
    GameManager.lose_life(data.life_cost)
    queue_free()
```

### 6.4 BOSS 的状态机骨架

【建议】用 §1.4 的 EventBus 思路,把 State 写成 `Resource` 或 `Node` 子节点。这里给一个 **Node 子节点版**(最简单):

```gdscript
# scripts/ai/state.gd
class_name State
extends Node

var state_machine: StateMachine

func enter() -> void: pass
func exit() -> void: pass
func physics_update(_delta: float) -> void: pass

# scripts/ai/state_machine.gd
class_name StateMachine extends Node

@export var initial_state: State
var current_state: State
var states: Dictionary = {}

func _ready() -> void:
    for child in get_children():
        if child is State:
            states[child.name] = child
            child.state_machine = self
    if initial_state:
        _enter(initial_state)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func transition_to(state_name: StringName) -> void:
    if not states.has(state_name): return
    var next := states[state_name]
    if current_state: current_state.exit()
    current_state = next
    _enter(next)

func _enter(state: State) -> void:
    current_state = state
    current_state.enter()
```

【警告】`transition_to` 中不要让旧 State 在 `exit()` 里再调用 `transition_to`,否则会重入;用 `_pending_transition` 标记延迟到下一帧处理。

---

## 7. 塔、投射物与状态效果

### 7.1 塔的统一基类

【事实】所有塔共享的行为:
- 周期扫描射程内的敌人(优先选最近 / 最血量多 / 最先到达终点,本项目建议"最先到达终点"以体现 Tower Defense 的"保命"核心)。
- 触发时实例化 / 取出投射物。
- 应用攻击特效(伤害、状态)。
- 升级 / 卖出。

【建议】本项目 `TowerBase` 设计:

```gdscript
# scripts/towers/tower_base.gd
class_name TowerBase
extends Node2D

@export var data: TowerData
@export var level: int = 1  # 1..3

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var fire_point: Marker2D = $FirePoint
@onready var range_indicator: Node2D = $RangeIndicator

var fire_cooldown: float = 0.0
var current_target: EnemyBase = null

func _physics_process(delta: float) -> void:
    fire_cooldown = max(0.0, fire_cooldown - delta)
    if fire_cooldown <= 0.0:
        current_target = _pick_target()
        if current_target:
            _fire_at(current_target)
            fire_cooldown = data.fire_interval_at(level)

func _pick_target() -> EnemyBase:
    # 在射程内选 path_index 最大的(最接近终点)
    var best: EnemyBase = null
    var best_progress := -1
    for enemy in _enemies_in_range():
        if enemy.path_index > best_progress:
            best = enemy
            best_progress = enemy.path_index
    return best

func _fire_at(enemy: EnemyBase) -> void:
    var proj := ProjectilePool.acquire(data.projectile_scene)
    proj.global_position = fire_point.global_position
    proj.setup(self, enemy, data.damage_at(level), data.projectile_speed, data.status_to_apply)
    proj.tree_entered.connect(_on_proj_tree_entered)

func _on_proj_tree_entered() -> void:
    pass
```

### 7.2 塔位目标选择策略

【事实】业内塔防常见三种策略(综合 [godottd skill](https://lobehub.com/skills/erikhazzard-vasir-tower-defense)、多篇分析):
1. **First(最先到达终点)**:最符合"保命"逻辑,大多数塔防默认。
2. **Closest(最近)**:玩家直觉友好。
3. **Strongest(最血多)**:适合 BOSS 速射。
4. **Last(最后到达终点,反方向)**:用于尾刀、收菜。

【建议】每种塔可在 `TowerData` 里标注 `target_priority: TargetPriority`。

### 7.3 投射物:Area2D vs Hitscan

【事实】塔防投射物三种实现:
| 类型 | 描述 | 性能 | 视觉 |
|---|---|---|---|
| **Area2D + Sprite2D** | 节点,信号碰撞 | 几百个 OK | 飞行轨迹明显 |
| **Hitscan** | `PhysicsDirectSpaceState2D.intersect_ray` | 几乎无开销 | 没有飞行,瞬时 |
| **MultiMeshInstance2D** | 共享 mesh 的批量渲染 | 上千个 | 适合子弹海 |

【建议】本项目采用 **Area2D + 节点对象池**(命中范围 + 飞行轨迹明显)。子弹海场景再考虑 MultiMesh。

### 7.4 状态效果(Buff / Debuff)系统

【事实】业内主流是 **组合优于继承**(来源:[DynamicStatusEffects (github)](https://github.com/TheCodingLand/DynamicStatusEffects)、[Stack Overflow — Status Effect System Design](https://stackoverflow.com/questions/how-to-design-a-status-effect-system)、[Game Programming Patterns](https://gameprogrammingpatterns.com/)):
- 每个效果是独立 `Resource`(或 `Node`),挂到实体上。
- 实体保留 `active_effects: Array[StatusEffectData]`,tick 逻辑统一处理。

【建议】本项目 `StatusEffectData` 设计:

```gdscript
# data/status_effects/status_effect_data.gd
class_name StatusEffectData extends Resource

enum Kind { SLOW, BURN, POISON, STUN, ARMOR_BREAK, BLEED, REGEN }

@export var id: StringName
@export var kind: Kind
@export var duration: float
@export var magnitude: float          # 慢速 %、伤害 tick、护甲减益 等
@export var tick_interval: float = 0.0  # 0 = 一次性 / 持续型;>0 = DOT
@export var can_stack: bool = false
@export var max_stacks: int = 1
@export var icon: Texture2D
@export var color: Color = Color.WHITE

# 运行时挂在目标上的实例
class Instance extends RefCounted:
    var data: StatusEffectData
    var remaining: float
    var stacks: int = 1
    var tick_accum: float = 0.0
    func tick(delta: float, target: Node) -> float:
        remaining -= delta
        if data.tick_interval > 0.0:
            tick_accum += delta
            if tick_accum >= data.tick_interval:
                tick_accum = 0.0
                target.take_damage(data.magnitude * stacks, null)  # 来源 = effect
        return remaining
```

【警告】状态效果应在 `enemy_base.gd` 里集中持有 `active_effects: Array[Status.Instance]`,**不要**让投射物直接操作敌人,否则会形成"投射物逻辑 + 敌人逻辑"双重真相。投射物只负责"创建 effect instance 并 push 给目标"。

### 7.5 塔升级 / 出售

【建议】TowerData 持有一个 `tiers: Array[TowerTier]`,每 tier 含 `damage`、`range`、`fire_interval`、`cost_to_upgrade`、`sprite_override`(可选)、`unlocks_branch_a/b`(可选,对应 Kingdom Rush 的 Tier 4 分叉)。

【警告】 **不要**用散落的 if-else 分支写升级路径;用数据驱动 + 显式 tier 索引。否则平衡性调参会变成代码考古。

---

## 8. 资源数据化(Resource / JSON)

### 8.1 Godot Resource(.tres)vs JSON

【事实】两种数据化方式对比(综合 [uhiyama-lab Save/Load](https://uhiyama-lab.com/en/notes/godot/save-load-system)、[dev.to — Godot 4 Save Systems](https://dev.to/ziva/godot-4-save-systems-5-patterns-from-real-shipped-games-3g23)、[GDQuest — Saving and Loading Games in Godot 4](https://gdquest.com/tutorial/godot/gdscript/save_game_godot4)):

| 维度 | `.tres` Resource | JSON |
|---|---|---|
| 类型安全 | 强(自定义类) | 弱(全 Dictionary) |
| 编辑器集成 | 完整(inspector) | 无 |
| 运行时加载 | `preload` / `ResourceLoader.load` | `FileAccess.get_file_as_string + JSON.parse_string` |
| 适合 | 实体静态配置(Tower、Enemy、Status、Projectile) | 关卡布局、波次、剧情文本 |
| 版本迁移 | 改 schema 会破坏旧存档 | 容易做迁移代码 |
| 跨工程共享 | 拖放即可 | 拖 JSON 文件 |

【建议】本项目:
- **静态配置**:`TowerData.tres`、`EnemyData.tres`、`StatusEffectData.tres`、`ProjectileData.tres`(每类一个 .tres,策划在 Godot Inspector 调)。
- **关卡数据**:`level_XX.json`(关卡布局、波次、奖励)。
- **全局数值**:`balance.tres`(一个 BalanceConfig Resource)。
- **多语言**:Godot 内置 `Translation` + `.po/.csv`(若做)。

### 8.2 推荐的 Resource 类继承

```gdscript
# data/towers/tower_data.gd
class_name TowerData extends Resource

@export var id: StringName
@export var display_name_key: StringName
@export var tier_count: int = 3
@export var base_cost: int = 50
@export var tiers: Array[TowerTier] = []
@export var projectile_scene: PackedScene
@export var fire_sfx: AudioStream
@export var sell_refund_ratio: float = 0.6
@export var target_priority: TargetPriority = TargetPriority.FIRST
@export var icon: Texture2D

class TowerTier extends Resource:
    @export var tier: int = 1
    @export var damage: float = 5.0
    @export var range: float = 120.0
    @export var fire_interval: float = 1.0
    @export var cost_to_upgrade: int = 75
    @export var sprite_frames: SpriteFrames   # 替代 sprite
    @export var unlocks_branch_a: bool = false
    @export var branch_a_data: TowerData
    @export var branch_b_data: TowerData
```

### 8.3 加载与缓存

【建议】
- 关卡所有 `TowerData` / `EnemyData` 在 `Boot` 场景里 `preload` 到全局字典 `ContentDb.towers["archer_basic"]`。
- 关卡 JSON 在 `Level._ready` 里 `JSON.parse_string` → `LevelData` Resource(自定义)。
- 不要在 `_process` 里反复 `ResourceLoader.load`。

### 8.4 关卡数据校验

【建议】关卡加载后做一次 schema 校验:
- 出生点必须在地图边缘
- 终点必须在地图边缘
- 所有出生点到终点必须有 A* 路径(初始地图无塔时也必须能走通)
- 波次 JSON 的 `enemy` id 必须存在于 ContentDb

校验失败直接 `push_error` + 提示,防止策划写出死局关卡。

---

## 9. 存档系统

### 9.1 持久化路径

【事实】Godot 4 中:
- `res://` 是只读(导出后)。
- `user://` 映射到平台可写目录(Windows:`%APPDATA%\Godot\app_userdata\<project>\`)。
- 必须用 `DirAccess` + `FileAccess` 操作。

【建议】SaveManager 单一职责,所有路径都从它走:

```gdscript
const SAVE_DIR = "user://saves"
const SAVE_EXT = ".json"

func _ready():
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func get_save_path(slot: int) -> String:
    return "%s/save_%02d%s" % [SAVE_DIR, slot, SAVE_EXT]
```

### 9.2 格式:JSON + 原子写

【事实】最佳实践(综合 [dev.to — Godot 4 Save Systems](https://dev.to/ziva/godot-4-save-systems-5-patterns-from-real-shipped-games-3g23)、[bugnet — Game Save Best Practices](https://bugnet.io/blog/game-save-best-practices-godot)、[uhiyama-lab](https://uhiyama-lab.com/en/notes/godot/save-load-system)):
- 用 JSON(可读、可 diff、可手动测试)。
- **先写临时文件,再原子 rename**,防止崩溃导致存档损坏。
- 保留 `.bak` 上一份。
- 存档带 `version` 字段,支持迁移。

【伪代码】

```gdscript
func save_game(slot: int, data: Dictionary) -> Error:
    var path := get_save_path(slot)
    var tmp := path + ".tmp"
    var bak := path + ".bak"
    var file := FileAccess.open(tmp, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    var payload := {
        "version": SAVE_VERSION,
        "timestamp": Time.get_unix_time_from_system(),
        "data": data
    }
    file.store_string(JSON.stringify(payload, "  "))
    file.close()  # 也可 file = null
    # 原子 rename:先 .bak 备份旧档
    if FileAccess.file_exists(path):
        DirAccess.rename_absolute(path, bak)
    DirAccess.rename_absolute(tmp, path)
    return OK

func load_game(slot: int) -> Dictionary:
    var path := get_save_path(slot)
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    var text := file.get_as_text()
    file.close()
    var parsed = JSON.parse_string(text)
    if parsed == null:
        # 尝试 bak
        ...
    return _migrate(parsed)
```

### 9.3 存档内容设计

【建议】本项目的存档粒度:

| 内容 | 是否存档 | 备注 |
|---|---|---|
| 玩家设置(音量、分辨率、键位) | ✅ | ConfigFile,独立文件 `user://settings.cfg` |
| 战役进度(打到第几关) | ✅ | SaveManager JSON |
| 永久货币(Stars/Gems) | ✅ | |
| 关卡内临时状态 | ❌ | 玩家战败直接重打,不要中途存档 |
| 解锁的塔 / 敌人百科 | ✅ | |

### 9.4 加密(可选)

【事实】Godot 4 提供 `FileAccess.open_encrypted_with_pass()`,但**仅防君子**。真正防作弊需要服务端校验。
【建议】单人单机项目,默认明文 JSON;若后期要加 PC 防萌新改存档的最小保护,用 `open_encrypted_with_pass`,密码常量写在脚本里(会被反编译)。

### 9.5 版本迁移

【建议】每次改 schema:
```gdscript
func _migrate(payload) -> Dictionary:
    var v: int = payload.get("version", 0)
    while v < SAVE_VERSION:
        v += 1
        payload = _migration_table[v].call(payload)
    return payload
```
迁移函数放在独立脚本,按版本号索引,便于审计。

---

## 10. UI 系统

### 10.1 Control 节点基础

【事实】Godot 4 UI 由 Control 节点构成(来源:[DeepWiki — Layout and Container System](https://deepwiki.com/kdada/godot/4.2-layout-and-container-system)、[claudemarket.ai — godot-ui-control](https://www.claudemarket.ai/skills/gamedev-skills/awesome-gamedev-agent-skills/godot-ui-control)、[pkg.go.dev classdb Control](https://pkg.go.dev/graphics.gd/classdb/Control)):
- 4 种 layout mode:`POSITION` / `ANCHORS` / `CONTAINER` / `UNCONTROLLED`。
- 锚点(anchor_left/right/top/bottom)是 **0..1** 的比例;`offset_*` 是像素偏移。
- 容器(VBoxContainer、HBoxContainer、GridContainer、MarginContainer、PanelContainer、ScrollContainer、TabContainer、CenterContainer、AspectRatioContainer、FlowContainer)接管子节点位置,**不要**在容器里再手设 anchors。

### 10.2 推荐 UI 架构

【建议】
- 一个 `Theme.tres` 全局主题(覆盖 default font、colors、styleboxes)。
- UI 场景树结构:每屏一个独立 `.tscn`(`MainMenu.tscn`、`HUD.tscn`、`PauseMenu.tscn`、`LevelSelect.tscn`、`SettingsMenu.tscn`、`LevelResult.tscn`)。
- HUD 用 `CanvasLayer`(层 10),永远在地图之上。
- 弹窗(Pause / Confirm / Result)用独立的 CanvasLayer(层 20),HUD 之上。
- 公共控件(自定义 Button、IconLabel、ProgressBarWithText)放在 `scenes/ui/components/`。
- 焦点管理:菜单首项 `grab_focus()`,支持键盘 + 手柄(塔防 PC 端手柄可选)。

### 10.3 主题与样式

【事实】Godot 4 主题由 4 类资源构成:
- `Color`
- `Texture`(icon)
- `Font`(font + font_size)
- `StyleBox`(background,9-slice)
- `Constant`(数值,如 BoxContainer.separation)

主题查找顺序:`add_theme_*_override()` 本节点 → 祖先 Control → 项目默认主题 → 内置 fallback。

【建议】为塔防风格:
- 一个粗描边字体(Bitmap 字体或 SDF),保持像素风。
- 按钮 `StyleBoxFlat` + `border_color` 高对比度,让玩家在战斗中能看清。
- 进度条样式统一一个 `StyleBoxFlat`。

### 10.4 响应式 / 多分辨率

【事实】基于 §2 的 viewport 配置,UI 在 viewport 模式下会整体像素缩放。
- 菜单用 `canvas_items` 模式渲染的子 viewport(可选,让 UI 更平滑),或直接接受像素化。
- `AspectRatioContainer` 用来维持按钮组的纵横比。
- `size_flags_horizontal = Control.SIZE_EXPAND_FILL + Control.SIZE_SHRINK_CENTER` 让按钮在窗口拉宽时居中。

### 10.5 输入

【事实】Godot 4 输入(来源:[Godot 4.0 Input docs](https://docs.godotengine.org/en/4.0/classes/class_input.html)、[Using InputEvent](https://docs.godotengine.org/en/4.0/tutorials/inputs/inputevent.html)、[studyraid mouse+touch](https://app.studyraid.com/en/read/32761/1441896/handling-mouse-and-touchscreen-input-events)):

| 输入 | 推荐 |
|---|---|
| 鼠标 / 触屏点击放置 | `_unhandled_input` 中 `InputEventMouseButton` / `InputEventScreenTouch` 通用 |
| 鼠标右键拖动相机 | `InputEventMouseMotion` 按住右键时累计 delta |
| 滚轮缩放 | `InputEventMouseButton.button_index == MOUSE_BUTTON_WHEEL_UP/DOWN` |
| 触屏双指缩放 | 解析 `InputEventScreenTouch` + `InputEventScreenDrag`,或用第三方 [GodotTouchInputManager](http://github.org/sh-dave/GodotTouchInputManager) |
| 键盘 | `InputMap` actions(`pause`、`select_next_tower`、`speed_up`) |

【建议】项目设置里启用 `input_devices/pointing/emulate_mouse_from_touch=true`,让 PC 测试时点击更直观。但发布时若以 PC 为主,关闭 `emulate_touch_from_mouse` 避免指针漂移。

【警告】Windows 上同时启用两个 emulate 会出现指针漂移([studyraid 文章](https://app.studyraid.com/en/read/32761/1441896/handling-mouse-and-touchscreen-input-events));分平台配置。

---

## 11. 音频系统

### 11.1 Bus 布局

【建议】项目启动时配置 `default_bus_layout.tres`:

```
Master
├── Music     (BGM,加 EQ 提升低音,长尾 reverb)
├── SFX       (塔攻击、敌人死亡、技能)
│   ├── UI    (菜单按钮 hover/click)
│   └── Combat (战斗内 SFX)
└── Ambient   (环境音、风声)
```

**理由**:分离后可以独立调音量、保存到 settings.cfg、运行时静音(关 BGM 但保留 UI 音)。

### 11.2 AudioManager 设计

【建议】`AudioManager` AutoLoad 职责:
- 缓存 `AudioStream` 资源(避免重复 load)。
- BGM 用 `AudioStreamPlayer` 循环 + 淡入淡出(`Tween`)。
- SFX 用池化 `AudioStreamPlayer`(短音不会卡顿)。
- 暴露 API:
  - `play_sfx(stream: AudioStream, bus: StringName = "SFX", pitch: float = 1.0)`
  - `play_bgm(stream: AudioStream, fade_duration: float = 1.0)`
  - `set_bus_volume(bus: StringName, linear_db: float)`

【警告】每个 `play_sfx` 都 `AudioStreamPlayer.new()` 会卡;**必须**预创建 8–16 个 SFX player,轮询使用。

### 11.3 音频格式

【事实】
- 音乐:`.ogg`(Vorbis)或 `.mp3`。
- 短音效:`.wav` 或 `.ogg`。
- `.ogg` 文件最小、CPU 友好、HTML5 兼容(Web 导出唯一支持 Vorbis,不支持 .wav)。

【警告】导出 Web 时 **不能用 `.wav` 或 `.mp3`**,只 Vorbis 工作。

### 11.4 音量与设置

【建议】音量用 `linear`(0..1)存储,在 AudioManager 内转 `db`:

```gdscript
func linear_to_db(linear: float) -> float:
    return 20.0 * log(linear) / log(10.0) if linear > 0.0 else -80.0

func set_bus_volume(bus: StringName, linear: float) -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(linear))
```

SettingsManager 用 ConfigFile 持久化:
```ini
[audio]
master_volume=0.8
music_volume=0.6
sfx_volume=1.0
```

---

## 12. 性能优化与对象池

### 12.1 性能预算(目标)

【建议】本项目目标:
- 帧时间 ≤ 16.67ms(60 FPS),中端 PC / Steam Deck / 主流安卓机。
- 同屏敌人:50–150。
- 同屏投射物:100–300。
- 同屏塔:30–60。

### 12.2 已知优化点

【事实】Godot 4 2D 性能优化建议(综合 [reddit bullet pooling discussion](https://www.reddit.com/r/godot/comments/...)、[Object Pool — Godot 4 Recipes](https://kidscancode.org/godot_recipes/4.x/recipes/bullet_pool/)、[Many entities forum](https://forum.godotengine.org/t/.../...)):

| 问题 | 优化 |
|---|---|
| `queue_free` 延迟到帧末、可能帧尖刺 | 对象池 |
| 投射物很多节点 | `MultiMeshInstance2D` 批量渲染 |
| 高频 `get_node` | `@onready` 缓存 |
| 每帧重烘焙导航 | 不要每帧重烘焙 |
| 大量 `_process` 节点 | 关闭不在视野的 `process_mode`,或用 `set_process(false)` |
| 文本标签每帧改 | 改值才更新,不要每帧重设 |
| `String` 拼接 | 用 `%s/%d` 格式化而非 `+` |
| 静态类型 | 全面 `@export` + 静态类型,避免 Variant 装箱 |
| 多线程 | GDScript 是单线程;真正 CPU 重活走 C# / GDExtension;线程池用 `WorkerThreadPool.add_task`,主线程 API 必须 `call_deferred` |

### 12.3 对象池

【建议】本项目至少为下列实体建立池:
- `Projectile`(投射物)
- `XP_Gem`(经验宝石)
- `FloatingDamageLabel`(伤害飘字)
- `ParticleEffect`(一次性特效)
- `AudioStreamPlayer`(SFX)

通用池骨架:

```gdscript
# core/pool/object_pool.gd
class_name ObjectPool extends Node

@export var scene: PackedScene
@export var initial_size: int = 16

var _free: Array[Node] = []

func _ready() -> void:
    for i in initial_size:
        var inst := scene.instantiate()
        add_child(inst)
        inst.set_process(false)
        inst.set_physics_process(false)
        inst.visible = false
        _free.append(inst)

func acquire() -> Node:
    var obj: Node
    if _free.is_empty():
        obj = scene.instantiate()
        add_child(obj)
    else:
        obj = _free.pop_back()
    obj.set_process(true)
    obj.set_physics_process(true)
    obj.visible = true
    return obj

func release(obj: Node) -> void:
    obj.set_process(false)
    obj.set_physics_process(false)
    obj.visible = false
    _free.append(obj)
```

【警告】对象池的对象**必须**自己提供 `reset()` 方法,被 acquire 时清掉旧状态(目标、伤害、剩余时间等)。

### 12.4 监控与 Profile

【事实】Godot 4 Debugger 面板的 **Profiler / Visual Profiler / Monitors** 是日常工具(来源:[Godot Debugger Panel 4.0 docs](https://docs.godotengine.org/en/4.0/tutorials/debug/debugger_panel.html)、[bugnet — Godot Performance Profiling Guide](https://bugnet.io/blog/godot-performance-profiling-guide-for-beginners))。

【建议】自定义 monitor:
```gdscript
func _ready():
    Performance.add_custom_monitor("alive_enemies", Callable(self, "_count_alive_enemies"))
    Performance.add_custom_monitor("active_projectiles", Callable(self, "_count_active_projectiles"))
```
这样 Debugger → Monitors 就能直接看到,不必自己写 FPS 计数器。

【警告】Profile 时**必须**导出 release build 测,编辑器内 profiling 数据会被编辑器开销污染。

---

## 13. 测试

### 13.1 框架选择

【事实】Godot 测试两大主流(来源:[GUT Quick Start](https://gut.readthedocs.io/en/godot_3x/Quick-Start.html)、[helpmetest — GUT Framework Guide](https://helpmetest.com/blog/godot-unit-testing-guide)):

| 框架 | 语言 | 备注 |
|---|---|---|
| **GUT 9.x** | GDScript 优先 | 社区最活跃,Godot 4.5+ 用 v9.5.0,Godot 4.7+ 推荐 v9.6.0+ |
| **gdUnit4** | GDScript + C# | C# 项目首选 |

【建议】本项目纯 GDScript,选 **GUT**。

### 13.2 哪些代码值得测试

【事实/建议】好的单元测试对象(可独立运行,无场景树依赖):
- 数值计算(伤害公式、经验曲线、升级成本、金币奖励)
- 状态机(纯逻辑的 State 切换)
- 波次数据校验(关卡 JSON → 校验器)
- 资源加载和迁移(存档读写、版本迁移)
- 平衡常数(公式)
- 字符串/i18n key 完整性

【警告】不要试图给场景树代码(`_ready` 里 add_child 的)写单元测试,转用集成测试或手动 QA。

### 13.3 `.gutconfig.json` 雏形

```json
{
  "dirs": ["res://tests/unit"],
  "prefix": "test_",
  "suffix": ".gd",
  "log_level": 1,
  "include_subdirs": true,
  "gut_on_ready": true,
  "should_exit": true
}
```

### 13.4 一个测试示例

```gdscript
# tests/unit/test_balance.gd
extends GutTest

func test_damage_formula_at_tier_1() -> void:
    var tower := TowerData.new()
    tower.tiers = [TowerData.TowerTier.new()]
    tower.tiers[0].damage = 5.0
    assert_eq(tower.damage_at(1), 5.0)

func test_status_effect_tick_damage() -> void:
    var burn := StatusEffectData.new()
    burn.kind = StatusEffectData.Kind.BURN
    burn.tick_interval = 1.0
    burn.magnitude = 3.0
    burn.duration = 5.0
    var instance := StatusEffectData.Instance.new()
    instance.data = burn
    var target := MockEnemy.new()
    instance.tick(1.0, target)
    assert_eq(target.damage_taken, 3.0)
```

【建议】CI 上跑测试:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gexit
```

---

## 14. 发布与导出

### 14.1 平台矩阵

【事实】Godot 4.x 导出能力(综合 [godotengine.org release notes 4.5–4.7](https://godotengine.org/releases/4.5/)、[Export for Web 教程](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)、[godotweb.io guides 2026](https://cur.at/R7sykKH)):

| 平台 | 渲染后端 | 状态 | 备注 |
|---|---|---|---|
| Windows .exe | Forward+ / Mobile / Compatibility | ✅ | 推荐 Forward+ |
| Linux .x86_64 | Forward+ / Mobile / Compatibility | ✅ | |
| macOS .app / .dmg | Forward+ / Mobile / Compatibility | ✅ | 需签名 + 公证 |
| Android .apk / .aab | Mobile / Compatibility | ✅ | Godot 4.7 起 Android GABE 稳定 |
| iOS | Mobile / Compatibility | ✅ | 需 Apple 开发者账号 + Xcode |
| Web (HTML5/Wasm) | **仅 Compatibility** | ✅ | Godot 4.3+ 默认单线程,免 SharedArrayBuffer;Godot 4.7+ 支持 Wasm64 |
| Steam Deck (Linux) | Forward+ / Mobile / Compatibility | ✅ | 默认 Forward+,Mobile 续航更长 |

【警告】
- Web 导出**必须**用 `compatibility` 渲染后端,不能用 Forward+。
- C# 项目**不能**导出 Web(GDScript 才行)。
- Godot 4.7 Wasm64 解决 4GB 堆限制;若用大型 `.pck`,优先选 4.7。

### 14.2 导出配置

【建议】每个平台一份 Export Preset:
- **Windows**:`Forward+` 渲染、`x86_64`、嵌入 PCK、应用图标、`vr.embedded_framebuffer` 关。
- **macOS**:`arm64` + `x86_64` universal(若要 Rosetta)、`codesign` 证书、`notarytool` 公证。
- **Linux**:`x86_64`、AppImage 或 .zip。
- **Web**:启用 `html/canvas_resize_policy=2`、`progressive_web_app=1`(可选)、单线程(`threads_support=false`)。
- **Android**:Gradle build、`min_sdk=24`、`target_sdk=34+`、`architecture=arm64-v8a + armeabi-v7a`。
- **iOS**:需在 Xcode 重新签名。

### 14.3 优化项

【事实/建议】
- 启用 VRAM 压缩(Desktop: S3TC/BPTC;Mobile: ETC2/ASTC)。
- 移除编辑器中未引用的资源:Project → Tools → `Remove Unused Resources`(慎用,先在版本控制备份)。
- 音频转 `.ogg` Vorbis,`-q0.5` 即可。
- 不在 release 中包含 source map / debug symbols。
- 启用 `script encryption`(在 Export Preset 中给 C# / GDScript 加 XOR 密钥)。

### 14.4 上架

【事实】主要渠道对比:

| 渠道 | 抽成 | 备注 |
|---|---|---|
| Steam | 30%(营收 < $10M)→ 25%(> $10M) | 需 Steamworks 账号($100 一次性) |
| itch.io | 0–10% 自定 | 上手最快,Web/PC 都行 |
| Epic Games Store | 12% | 申请制 |
| GOG | 30% | |
| 自有站 | 0% | 但需自己处理支付 / 退款 |

【建议】先 **itch.io**(测试版),再 Steam(正式版)。考虑先做 Demo / EA 收集反馈。

### 14.5 macOS 公证

【警告】未公证的 macOS .app 在现代 macOS 上会弹"无法打开"。必须:
1. Apple Developer 账号($99/年)。
2. `codesign --deep --options runtime --sign "Developer ID Application: ..." Game.app`。
3. `xcrun notarytool submit Game.zip --keychain-profile <profile> --wait`。
4. `xcrun stapler staple Game.app`。

---

## 15. 范围控制与制作顺序(规划)

> **本节是本调研最关键的产出之一**。用户 0 基础,又拒绝 demo / MVP,所以必须按"全部交付"的方向规划,但**仍然要有顺序**,否则一开始就在错误方向上越走越远。

### 15.1 范围控制方法

【事实/建议】核心原则(综合 [indie game timelines](https://playgama.com/blog/2025/03/05/what-is-a-realistic-timeline-for-developing-an-indie-game-from-concept-to-release)、[data-driven indie timelines](https://gamewiki.blog/indie-game-development-timelines)、[Realistic Timeline: Idea to Steam Release](https://fyrosgamesstudio.com/resources/idea-to-steam-timeline)):

1. **锁定最小可玩内核**(Minimal Playable Core,MPC):玩家能"开一局→放塔→打一波→胜/负"的最小闭环。
2. **内容纵向切割**:不是"先做满 30 关",而是"先做满 1 关有 5 波 + 1 个塔 + 3 个敌人",再横向扩展。
3. **每个里程碑必须有可玩版本**,而不是"做完所有功能再玩"。
4. **反范围蔓延**:新需求入 backlog 时,标注 P0/P1/P2;P2 进入"未来 DLC"。
5. **数据驱动**:策划可调的参数必须脱离代码,见 §8。
6. **孤狼开发周期**估算:参考 1 人完整游戏的 1.5–3 年(含学习成本)。

### 15.2 整体里程碑(参考节奏)

> 时间估算按 1 人 0 基础、业余 15–20 小时/周。**所有时间均为参考量级**,不要按"必须 X 月完成"理解。

| 阶段 | 内容 | 估时 | 可玩里程碑 |
|---|---|---|---|
| **P0 学习/预研** | Godot 基础、GDQuest GDScript 课程、Hector @ devbranch 教程;搭建项目骨架 | 4–6 周 | 跑通 Hello World + 玩家可在地图上移动 |
| **P1 最小可玩内核** | 1 张地图 + 1 条固定路径 + 1 个敌人 + 1 个塔 + 1 个投射物 + 1 个波次 + 金币 + 生命 | 6–10 周 | 通关 1 个 5 波关卡 |
| **P2 塔与敌人扩展** | 4 种塔 + 6 种敌人 + 3 种状态效果 + 2 个升级档 | 8–12 周 | 通关 1 个 10 波关卡,有 4 塔可选 |
| **P3 完整战役(8–12 关)** | 完整关卡美术、完整敌人塔生态、永久货币、关卡选择、解锁 | 12–16 周 | 战役模式通关一遍 |
| **P4 打磨** | UI 美术、音效 BGM、教程、设置、画质选项、本地化(中英文)、截图、Steam 主页素材 | 6–10 周 | 可发布 |
| **P5 发布 + 维护** | itch.io EA / Steam EA、收集反馈、修 bug、小更新 | 持续 | 上线 |

【警告】以上是参考;**单人 + 0 基础** 应取上限,实际 12–24 个月浮动都正常。**避免因单次延期而推翻范围**。

### 15.3 P1 最小可玩内核(最关键的"地基")

【建议】P1 完成度的最小集合:
- 1 个 TileMapLayer 路径 + 1 个出生点 + 1 个终点(用 AStarGrid2D)。
- 1 个 `EnemyBase` 场景,HP=100,移动速度 60,沿路径走。
- 1 个 `TowerBase` 场景,单发投射物,伤害 10,射程 120,射速 1s。
- 1 个 `ProjectileBase`(Area2D),命中扣血。
- `WaveManager` + 1 个手写波(5 个敌人,每 1.5s 一个)。
- `GameManager`:金币 100,生命 20,胜/负判定。
- HUD:金币数、生命数、波次倒计时、"开始波次"按钮。
- 主菜单 → 关卡 → 结果 三屏切换。
- 玩家点击格子 → 放塔 → 金币扣除 → 占用校验。

**完成后**:这就是塔防的"骨架",所有后续内容往里填即可。

### 15.4 范围控制清单(对照 Kingdom Rush 决定砍哪些)

| Kingdom Rush 元素 | 是否纳入 | 备注 |
|---|---|---|
| 4 种塔 | ✅ 全部纳入 | 弓箭、法师、兵营、炮台 |
| 每塔 4 档 + 2 分叉 | ❌ 简化为 3 档 + 1 个最终升级 | Kingdom Rush 的 Tier 4 分叉对 0 基础过大 |
| 48 种敌人 | ❌ 简化为 12–16 种 | 4 基础 + 4 精英 + 4 飞行 + 4 BOSS |
| 12 个英雄 | ❌ 简化为 4 个英雄 | 每个英雄 1 主动 + 1 被动技能 |
| 2 个地图法术 | ✅ 全部纳入 | 流星雨 + 援军 |
| Heroic/Iron/Endless 模式 | ❌ 战役 + 无限模式即可 | Heroic 后置 |
| Stars 永久升级 | ✅ 简化为 1 个分支 | |
| 全语音 / 配音 | ❌ 简化为关键台词 + SFX | 全语音成本极高 |
| 百科全书 | ❌ 简化为"敌人详情"面板 | |
| Steam 成就 | ✅ 全部纳入 | Godot Steamworks addon |

### 15.5 反范围蔓延策略

【建议】写一个 `BACKLOG.md`,所有"想做"放进 P2/P3 池。每月回看一次,只移动"是否本季度做"。

【警告】 **不要**在 P1–P3 阶段做"剧情过场动画""多语言配音""手绘风格全角色立绘"——它们是高成本/低频使用的内容。

---

## 16. 来源汇总、许可证与版本注意事项

### 16.1 核心官方/可验证来源

| 来源 | URL | 版本/许可证 | 用途 |
|---|---|---|---|
| Godot 官方文档(英文) | https://docs.godotengine.org/en/stable/ | Godot 4.x,CC BY 3.0 | API 与教程 |
| Godot 官���文档(中文) | https://docs.godotengine.org/zh_CN/stable/ | 同上 | 中文版 |
| Godot 4.5 release | https://godotengine.org/releases/4.5/ | Godot 4.5 | 版本说明 |
| Godot release policy | https://docs.godotengine.org/en/latest/about/release_policy.html | CC BY 3.0 | 版本支持等级 |
| Godot Debugger panel | https://docs.godotengine.org/en/4.0/tutorials/debug/debugger_panel.html | CC BY 3.0 | Profiling |
| Godot Using TileMaps | https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html | CC BY 3.0 | TileMapLayer |
| Godot Using TileSets | https://docs.godotengine.org/en/4.0/tutorials/2d/using_tilesets.html | CC BY 3.0 | TileSet |
| Godot Singletons (AutoLoad) | https://docs.godotengine.org/en/4.0/tutorials/scripting/singletons_autoload.html | CC BY 3.0 | AutoLoad |
| Godot Using InputEvent | https://docs.godotengine.org/en/4.0/tutorials/inputs/inputevent.html | CC BY 3.0 | 输入 |
| Godot Export for Web | https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html | CC BY 3.0 | Web 导出 |
| Godot 4.0 Input class | https://docs.godotengine.org/en/4.0/classes/class_input.html | CC BY 3.0 | 输入 API |
| Godot Mouse & Input Coordinates (zh_TW) | https://docs.godotengine.org/zh_TW/latest/tutorials/inputs/mouse_and_input_coordinates.html | CC BY 3.0 | 视口坐标 |

### 16.2 教程与社区资源(二次验证)

| 来源 | URL | 用途 |
|---|---|---|
| GDQuest — Pixel Art in Godot 4 | https://www.gdquest.com/library/pixel_art_setup_godot4/ | 像素艺术配置 |
| GDQuest — Save Game in Godot 4 | https://gdquest.com/tutorial/godot/gdscript/save_game_godot4 | 存档 |
| KidsCanCode — Object Pool Recipe | https://kidscancode.org/godot_recipes/4.x/recipes/bullet_pool/ | 对象池 |
| Uhiyama Lab — Autotiling Terrains | https://uhiyama-lab.com/en/notes/godot/terrains-autotile-setup/ | TileSet Terrain |
| Uhiyama Lab — Save/Load | https://uhiyama-lab.com/en/notes/godot/save-load-system | 存档格式 |
| Vav Labs — TD Path Validation | https://vav-labs.com/blog/tower-defense-path-validation-in-godot/ | 塔位校验 |
| Vav Labs — Path Blocking | https://vav-labs.com/blog/tower-defense-path-blocking | 同上 |
| Vav Labs — Godot TD 系列 | https://vav-labs.com/blog/ | 同系列 |
| sharpcoderblog — Tower Defense in Godot | http://sharpcoderblog.com/blog/creating-a-tower-defense-game-in-godot | 整体框架(API 较旧) |
| Towertido GDD v1.2 | https://www.github.com/StArias-Projects/Towertido/wiki/GDD-v1.2-eng | GDD 范例 |
| YouTD2 Wave System | https://deepwiki.com/handongdong-patsnap/youtd2/3.4-wave-and-team-management | 波次架构 |
| godottd skill | https://lobehub.com/skills/erikhazzard-vasir-tower-defense | 塔防公式 |
| godot-genre-tower-defense | https://lobehub.com/de/skills/neversight-skills_feed-godot-genre-tower-defense | 塔防分类 |
| The Metalvortex — Godot 4.3 Cheatsheet | https://themetalvortex.com/godot-4-3-developer-cheatsheet-game-architecture-workflows | 项目架构 |
| skills.cat — godot-autoload-architecture | https://skills.cat/skills/thedivergentai/gd-agentic-skills/godot-autoload-architecture | AutoLoad 架构 |
| skillmd — godot-development | https://www.skillmd.ai/skills/godot-development-1 | 开发技巧 |
| openillumi — Autoload Signal Bus | https://openillumi.com?p=71244/ | 事件总线 |
| Bugnet — Blurry Pixel Art | https://bugnet.io/blog/how-to-fix-godot-pixel-art-blurry | 像素艺术 |
| Bugnet — Performance Profiling | https://bugnet.io/blog/godot-performance-profiling-guide-for-beginners | Profiling |
| Bugnet — Save Best Practices | https://bugnet.io/blog/game-save-best-practices-godot | 存档 |
| dev.to — Godot Save Systems | https://dev.to/ziva/godot-4-save-systems-5-patterns-from-real-shipped-games-3g23 | 存档模式 |
| GUT Quick Start | https://gut.readthedocs.io/en/godot_3x/Quick-Start.html | 测试(注意:这是 Godot 3.x 文档,GUT 已支持 4.x) |
| helpmetest — GUT Framework | https://helpmetest.com/blog/godot-unit-testing-guide | GUT |
| helpmetest — GUT Advanced | https://helpmetest.com/blog/godot-gut-advanced-testing | GUT 高级 |
| dodatech — Fix TileMap Terrain | https://tutorials.dodatech.com/quick-fix/godot-tilemap-terrain | TileMap 修复 |
| sprite-ai — godot-sprites | https://www.sprite-ai.art/guides/godot-sprites | 精灵配置 |
| Dre Dyson — pixel-perfect Godot 4.6 | https://dredyson.com/how-i-mastered-jagged-edges-of-2d-art-while-moving-in-godot-4-6-... | 像素防抖动 |
| CSDN — 初识瓦片地图 | https://blog.csdn.net/luckyrui123/article/details/155442298 | TileMapLayer 中文 |
| gamineai — Export Lesson 14 | https://www.gamineai.com/courses/build-complete-game-godot-4/lessons/lesson-14-export-platform-preparation | 发布 |
| studyraid — Mouse & Touch | https://app.studyraid.com/en/read/32761/1441896/handling-mouse-and-touchscreen-input-events | 输入 |
| GodotTouchInputManager | http://github.org/sh-dave/GodotTouchInputManager | 触屏增强 |
| DeepWiki — Layout/Container | https://deepwiki.com/kdada/godot/4.2-layout-and-container-system | UI |
| DeepWiki — Control & UI 4.4 | https://www.deepwiki.com/godotengine/godot/4.4-control-and-ui-system | UI |
| claudemarket — godot-ui-control | https://www.claudemarket.ai/skills/gamedev-skills/awesome-gamedev-agent-skills/godot-ui-control | UI |
| pkg.go.dev — Control | https://pkg.go.dev/graphics.gd/classdb/Control | Control API |
| DynamicStatusEffects (GitHub) | https://github.com/TheCodingLand/DynamicStatusEffects | 状态效果 |
| Game Programming Patterns | https://gameprogrammingpatterns.com/ | 模式(开源书) |

### 16.3 Kingdom Rush 参考(机制层面,非素材)

| 来源 | URL | 用途 |
|---|---|---|
| 101games — Kingdom Rush | https://101games.io/kingdom-rush | 玩法综述 |
| seeles — Kingdom Rush | https://www.seeles.ai/games/strategy/kingdom-rush-tower-defense-strategy-game | 玩法 |
| omnigames — Kingdom Rush | https://omnigames.blog/kingdom-rush-tower-defense | 玩法 |
| Wikipedia — Kingdom Rush | https://en.wikipedia.org/wiki/Kingdom_Rush | 基本信息 |
| GameRankr — Kingdom Rush | https://www.gamerankr.com/games/238802-Kingdom-Rush | 平台/特性 |
| Wikiwand — Legends of Kingdom Rush | http://wikiwand.dev/en/Legends_of_Kingdom_Rush | 系列演变 |
| IPFS/Wikipedia — Kingdom Rush: Frontiers | https://ipfs.io/ipns/en.wikipedia-on-ipfs.org/wiki/Kingdom_Rush%3A_Frontiers | 续作 |
| Humble Store — Kingdom Rush | https://www.humblebundle.com/store/kingdom-rush?partner=patshead | 平台/规格 |
| A.V. Club — Kingdom Rush Review | https://www.avclub.com/kingdom-rush-review-pc | 评论 |

### 16.4 已知许可证注意事项

- **Godot 引擎本身**:MIT。
- **GDScript 代码**:项目自有,默认 MIT 或更严。
- **GUT 框架**:MIT。
- **Kenney 资产**(CC0):用于原型或全项目使用均可,无须署名(但建议标注)。
- **OpenGameArt 资产**:多数 CC0 / CC-BY,务必逐个看 license 文件。
- **itch.io 资源包**:每个包单独看 license,常见 CC0 / CC-BY。
- **Kingdom Rush 美术 / 文本 / 音频**:全部版权属 Ironhide Game Studio,**严禁使用**。本文档不引入任何 KR 资源。

### 16.5 版本注意事项

- **TileMapLayer**:Godot 4.3+ 才有新 API;4.0–4.2 用 `TileMap` 单节点(仍可用)。
- **Web Wasm64**:Godot 4.7+ 才有;之前 `.pck > 4GB` 会爆。
- **Stretch scale_mode = "integer"**:Godot 4.3+。
- **Direct3D 12 default**:Godot 4.6+(Windows)。
- **VirtualJoystick**:Godot 4.7+(官方节点)。
- **HDR 输出**:Godot 4.7+。

---

## 17. 风险、不确定性与未决议题

### 17.1 本调研不能解决的开放议题(需要其他文档输入)

| ID | 议题 | 解决路径 |
|---|---|---|
| O-1 | **关卡数量 / 主题** | 由 PRD 决定(预计 8–12 关,3 个主题) |
| O-2 | **永久货币 / Stars 树形** | 由 PRD / 经济设计决定 |
| O-3 | **塔/敌人/状态效果具体数值** | 由 BalanceConfig + §15 P2 阶段迭代 |
| O-4 | **美术风格细化**(调色板、分辨率、单 sprite 尺寸) | 由 ART_ASSETS_RESEARCH 决定 |
| O-5 | **音频清单**(BGM 风格、SFX 数量) | 由 AUDIO_ASSETS_RESEARCH 决定 |
| O-6 | **本地化范围**(仅简中 vs 中英双语) | 由 PRD 决定 |
| O-7 | **是否做英雄单位**(KR 有,本项目决定简化为 4 个) | 由 PRD 决定 |
| O-8 | **是否做 Heroic / Iron / Endless** | 由 PRD 决定(本调研建议 P3 之后做) |
| O-9 | **是否做 Mod 支持 / Steam Workshop** | 不在 v1.0 范围 |
| O-10 | **是否做 Switch / 移动版** | PC 优先,移动版 v1.x 之后 |

### 17.2 已知技术风险

| ID | 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|---|
| R-1 | 0 基础单人周期 > 24 个月,容易半途放弃 | 高 | 高 | §15 范围控制,设里程碑可玩版本 |
| R-2 | 塔防平衡性调参慢 | 高 | 中 | 数值全部 `.tres`,§8 数据驱动 |
| R-3 | 像素 + 整数缩放在 1080p / 4K 显示器黑边大 | 中 | 低 | 提供 UI 设置开关"全屏拉伸" |
| R-4 | macOS 公证流程耗时长 | 中 | 中 | 提前申请 Developer ID |
| R-5 | Web 导出兼容性 renderer 性能弱 | 中 | 中 | v1 不上 Web,后续做 P2 |
| R-6 | C# 不能 Web,GDScript 必须 | 已锁定 GDScript,风险消除 | — | — |
| R-7 | Godot 4.8 升级破坏 API | 中 | 中 | §0.3 锁定 4.7 |
| R-8 | 第三方 GUT 版本与 Godot 4.7 不兼容 | 低 | 中 | GUT 9.6+ 支持 Godot 4.7 |
| R-9 | 自学曲线:TileMapLayer + Navigation2D 同时上手 | 高 | 中 | P1 先做 TileMap + 路径点,暂时跳过 Navigation2D |
| R-10 | 美术产能瓶颈 | 高 | 高 | 必须先 ART_ASSETS_RESEARCH 找到可商用资产;否则延期 |

### 17.3 已澄清的不确定性

| 项 | 结论 |
|---|---|
| 是否用 ECS? | **不用**。Godot 节点系统已足够,ECS 在本项目是过度设计。 |
| 是否上 Forward+ 还是 Mobile 还是 Compatibility? | **PC 主力:Forward+**;Web/Mobile 后续:Compatibility;**统一项目里配置 3 个 Export Preset** 即可。 |
| 是否使用 GDScript 静态类型? | **是**,全程静态类型。 |
| 是否写中文注释? | **是**(配合简中本地化),但 identifier / 类名 / signal 名用英文。 |
| 模式(单关卡 / 战役)? | **战役为主 + 无限模式**。Heroic/Iron 留 P3+。 |

---

## 18. 后续步骤(交付给下一阶段的钩子)

### 18.1 下一阶段应该立即开始的事

1. **PRD 撰写**:基于 §15.2 里程碑、§15.4 范围控制清单、§17.1 开放议题,产出 `PRD_DRAFT.md`(另一文档)。
2. **美术调研**:`ART_ASSETS_RESEARCH_DRAFT.md` 锁定像素艺术基础分辨率、单 sprite 尺寸、调色板、风格参考(Kenney / OpenGameArt 等开源资源)。
3. **音频调研**:`AUDIO_ASSETS_RESEARCH_DRAFT.md` 锁定 BGM / SFX 来源与数量。
4. **技术验证(spike)**:
   - 跑通 Godot 4.7 项目骨架,确认 §2 配置生效。
   - 跑通 §3.4 塔位校验(AStarGrid2D + TileMapLayer)。
   - 跑通 §7.3 投射物 + §7.4 状态效果。
   - 跑通 §9 存档读写。
   - 每个 spike 单独 commit,失败立即回滚。

### 18.2 不要在调研阶段做的事

- 写完整代码。
- 选具体美术资源(等美术调研)。
- 选具体音频(等音频调研)。
- 锁定关卡剧情 / 文本(等 PRD)。

### 18.3 完成 §1–§15 后的检查清单

- [ ] `project.godot` 写入 §2.2 配置。
- [ ] `default_bus_layout.tres` 按 §11.1 创建。
- [ ] §1.1 的 AutoLoad 脚本框架创建(空实现)。
- [ ] §3.2 的 TileMapLayer 分层在一个 demo 关卡中跑通。
- [ ] §4 的 AStarGrid2D 在 demo 关卡中跑通。
- [ ] §6 的 EnemyBase 跑通(1 个敌人走完整路径)。
- [ ] §7 的 TowerBase + ProjectileBase 跑通(1 个塔打死 1 个敌人)。
- [ ] §5 的 WaveManager 跑通(1 关 1 波 5 敌人)。
- [ ] §8 的 Resource 数据类定义完毕。
- [ ] §9 的 SaveManager 跑通读写。
- [ ] §10 的 HUD 跑通(显示金币/生命/波次)。
- [ ] §12 的对象池跑通(投射物 / XP gem)。
- [ ] §13 的 GUT 跑通 1 个测试样例。
- [ ] §14 的 Windows 导出跑通(可双击 .exe 运行)。

完成后,即为 P1 最小可玩内核(§15.3)。

---

> 文档版本:DRAFT v0.1(2026-09-04)
> 撰写:技术与生产研究 agent
> 复核人:待指派
> 状态:待 PRD / 美术调研 / 音频调研输入 → 进入 v0.2
