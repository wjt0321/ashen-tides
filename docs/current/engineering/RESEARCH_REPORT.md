# 《余烬潮汐》技术研究报告(RESEARCH_REPORT)

> **文档状态**:Proposed v1.0（正式候选，待项目主理人拍板）
> **撰写日期**:2026-09-04
> **Owner**:技术主理人
> **Approver**:项目主理人(0 基础、唯一开发者)
> **Supersedes**:`TECH_RESEARCH_DRAFT.md`(v0.1)的所有非冲突结论;冲突以本文件为准
> **读者**:0 基础且为唯一开发者的项目主理人,以及协助落地的 agent
> **本文不修改其他草稿/审查稿**

---

## 目录

- [0. 文档目的与读者](#0-文档目的与读者)
- [1. 工程决策摘要](#1-工程决策摘要)
- [2. 引擎与版本](#2-引擎与版本)
- [3. 项目目录架构](#3-项目目录架构)
- [4. 像素艺术渲染配置](#4-像素艺术渲染配置)
- [5. 固定 BuildNode + 预制 PathNetwork](#5-固定-buildnode--预制-pathnetwork)
- [6. TileMap / TileMapLayer](#6-tilemap--tilemaplayer)
- [7. 数据驱动架构](#7-数据驱动架构)
- [8. 战斗实体:塔 / 投射物 / 状态效果 / 敌人](#8-战斗实体)
- [9. 相位系统(明潮 / 暮潮)技术实现](#9-相位系统)
- [10. 航标充能系统](#10-航标充能系统)
- [11. 英雄系统](#11-英雄系统)
- [12. 关卡数据(LevelData)](#12-关卡数据)
- [13. 波次系统](#13-波次系统)
- [14. 存档系统(含 suspend save)](#14-存档系统)
- [15. UI / 输入 / 无障碍](#15-ui--输入--无障碍)
- [16. 音频系统](#16-音频系统)
- [17. 性能与对象池](#17-性能与对象池)
- [18. 测试](#18-测试)
- [19. 工具链与发布](#19-工具链与发布)
- [20. 学习路径(0 基础如何上手)](#20-学习路径)
- [21. 工期与风险区间](#21-工期与风险区间)
- [22. 事实等级体系](#22-事实等级体系)
- [23. 已废弃术语扫描器](#23-已废弃术语扫描器)
- [附录 A 术语表(中英对照)](#附录-a-术语表)
- [附录 B 决策记录](#附录-b-决策记录)
- [附录 C 来源 URL 清单](#附录-c-来源-url-清单)

---

## 0. 文档目的与读者

**目的**:把"研究 + 草稿 + 审查"整合成一份 **可直接执行** 的技术报告,零基础用户按图施工即可启动 Godot 工程并产出 v1.0 完整战役《余烬潮汐》。

**不是**:
- 不是 PRD(产品定义见 `PRD.md`)。
- 不是美术资产清单(见 `ASSET_CATALOG.md`)。
- 不是教学教程;学习路径见 §20。

**读者**:
1. **项目主理人**(0 基础、唯一开发者):按 §20 学习,按 §21 排期,按 §19 发布。
2. **协助 agent**:按 §3 目录、§7 数据契约、§22 事实等级工作,不得自创术语或自扩范围。

**文档权威边界**:
1. `PRD.md` 是产品目标、范围与验收标准的唯一权威。
2. `RESEARCH_REPORT.md`（本文件）是技术实现与生产方法的唯一权威，但不得改写产品范围。
3. `ASSET_CATALOG.md` 是资产候选、风格与许可状态的唯一权威。
4. 历史草稿 `*_DRAFT.md` 与 `REVIEW_*.md` 仅用于追溯，不再作为执行依据。
5. 跨域冲突由项目主理人拍板，并同步修订所有受影响的正式文档。

---

## 1. 工程决策摘要

> 本节是 **项目真相(PROJECT_CANON)**。除本文件明确列出的可推翻项外,所有下游文档必须与本表一致。

| # | 决策项 | 锁定值 | 备注 |
|---|---|---|---|
| 1 | 引擎 | Godot 4.7.x 稳定补丁 | 不锁定为"长期支持"(LTS)概念;Godot 官方未对 4.7 声明 LTS,见 §2 |
| 2 | GDScript 版本 | GDScript 2.0(静态类型 + typed signal) | 全面静态类型,见 §2.4 |
| 3 | 渲染后端 | Forward+(默认) | 仅 Windows 桌面首发,见 §19 |
| 4 | 物理 | Godot Physics 2D(默认) | 本项目只做 2D |
| 5 | 逻辑分辨率 | 640×360 | 16:9,1080p 整数 3×,见 §4 |
| 6 | 像素 tile 尺寸 | 32×32 | 与 640×360 配套,见 §4.2 |
| 7 | 工作代号 | 《余烬潮汐》(Ashen Tides) | 待商标清查,见 PRD §24 |
| 8 | 首发平台 | Windows PC(Steam) | Linux/Steam Deck 在 Beta 后决策;移动/Web/macOS 不在 v1.0,见 PRD §0 |
| 9 | 首发语言 | 简体中文 + 英文(P0) | P1=繁中+日语(视 ROI),见 PRD §14 |
| 10 | 战役规模 | 24 主线关 + 6 塔 + 4 英雄 + 24 普通敌 + 8 精英 + 6 Boss | 见 PRD §0 |
| 11 | 路径模型 | **固定 BuildNode + 预制 PathNetwork** | 玩家不可自由建路/堵路;关卡设计预先绘制路线,见 §5 |
| 12 | 敌人寻路 | **预存 route/segment ID + progress**,无动态 A* | 普通敌人不走实时寻路;英雄地面移动可走 A*,见 §5.4 |
| 13 | 原创核心机制 | 相位(明潮/暮潮) + 航标充能 + 校准模块 + 潮汐仪 | 见 PRD §4、§9 与 §10 |
| 14 | 数据驱动 | 100% 数据驱动;数值与 ID 全部走 .tres / .json | 见 §7 |
| 15 | 视觉风格 | 像素 + 潮汐航海仪器语言 | 拒绝木质卷轴中世纪 UI,见 ASSET_CATALOG §1 |
| 16 | 存档 | 三槽轮转 + suspend save | 见 §14 |
| 17 | 工期 | 零基础兼职 30–48 个月风险区间 | 见 §21 |
| 18 | 收口 | 发布质量纵向切片 C01–C03 是 v1.0 的前三关,**不是 Demo/MVP** | 见 §21.3 |

> 【Policy】本表任何修改必须升级 PRD、Tech、Asset 三份正式文档并写入附录 B 决策记录。

---

## 2. 引擎与版本

### 2.1 版本锁定

**【Verified】** 截至 2026-09,Godot 当前稳定版本:

| 版本 | 发布时间 | 当前支持等级 |
|---|---|---|
| Godot 4.6 | 2026-01-27 | 维护中(常规修复) |
| **Godot 4.7 "Lights, Camera, Action!"** | **2026-06-18** | 当前稳定 |
| Godot 4.7.1 RC | 2026-07-09 | 发布候选 |
| Godot 4.8 (master/dev) | 2026 Q4 预计 | 开发中 |

**【Policy / 重要】** Godot 官方未将 4.7 标为"LTS"(Long-Term Support)。本项目沿用"稳定补丁线"措辞,**不宣称 4.7 是 LTS**。每周同步 4.7.x patch 修复;4.8 升级需独立 PRD 决议。

**来源**:
- [Godot 4.7 Release Notes](https://godotengine.org/article/godot-4-7-release-notes/)
- [Godot Release Policy](https://docs.godotengine.org/en/latest/about/release_policy.html)

### 2.2 Godot 4.7 关键特性(对本项目的影响)

| 特性 | 对本项目影响 | 采纳 |
|---|---|---|
| Wasm64 Web 导出 | 暂不导出 Web;了解即可 | 否 |
| HDR 输出 | 桌面/移动可用;Web/iOS 不可 | 否(v1.0 无 HDR) |
| AreaLight3D | 3D;本项目不用 | 否 |
| Transform Offset for Control | UI 动画质量提升 | **是** |
| VirtualJoystick 节点 | 触屏手柄原生节点 | **是**(为未来移动版预留) |
| 引擎级 iOS/Android 导出改进 | 不在 v1.0 | 否 |
| 内置 Asset Store 替代 Asset Library | 资产搜索流程变化 | **是** |
| 修复 ~1,265 项 | 性能/稳定性提升 | **是** |

**来源**:[Godot 4.7 — Cinevva 2026-06](https://app.cinevva.com/zh-CN/news/2026-06-19-godot-4-7-released),[Godot 4.7 Features — Ziva](https://ziva.sh/blogs/godot-4-7)

### 2.3 4.6 特性(回溯相关)

**【Verified】** Godot 4.6(2026-01-27)的两项默认变化,只对**新建项目**生效,本项目 M0 立项即覆盖:
- Windows 渲染驱动默认改为 **Direct3D 12**(原 Vulkan,4.6 起因 D3D12 在部分消费级 GPU 上更稳定)。
- 3D 物理默认改为 **Jolt Physics**;2D 物理仍是 **Godot Physics 2D**(本项目用此)。

**来源**:[Godot 4.6 Release](https://godotengine.org/releases/4.6/),[GDQuest — Godot 4.6: What changes for you](https://gdquest.com/library/godot_4_6_workflow_changes)

### 2.4 GDScript 2.0 静态类型

**【Verified】** Godot 4 全面使用 GDScript 2.0,本项目规则:
- 所有 `var` 必须声明类型(`var hp: float = 100.0`)。
- 所有 signal 必须 typed(`signal gold_changed(new_amount: int)`)。
- 所有 `@export` 必须声明类型。
- 函数参数和返回值必须声明类型。

**【Policy】** 静态类型缺失会导致 Godot 4 内部走慢路径(动态 Variant),对本项目 3× 速度 + 200+ 节点同屏是性能硬伤。

### 2.5 Godot Web 导出(本项目 v1.0 不上线,记录备查)

**【Verified】** Godot 4 Web 导出**仅支持 Compatibility renderer**,Forward+ 与 Mobile 不可用;C# 项目不能 Web 导出。

**【Verified】** Godot 4.7 起支持 **Wasm64**(突破 32-bit WebAssembly 的 4 GB 内存上限);默认开启 WebAssembly SIMD。

**【Verified】** Web 导出音频格式:.ogg/.wav/.mp3 三种技术上都被支持;官方**推荐 .ogg Vorbis**(MP3 有专利、WAV 体积过大)。本项目若将来导 Web,统一 Vorbis。

**来源**:[Godot Docs — Exporting for the Web](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html),[Godot 4.7 — Wasm64 confirmed (Cinevva)](https://app.cinevva.com/zh-CN/news/2026-06-19-godot-4-7-released)

---

## 3. 项目目录架构

### 3.1 目录结构

```
res://
├── project.godot                 # 项目配置,见 §4.2
├── .gutconfig.json               # GUT 测试配置,见 §18
├── default_bus_layout.tres       # 音频总线,见 §16
├── icon.svg                      # 应用图标
├── autoload/                     # AutoLoad 脚本(见 §3.2)
│   ├── event_bus.gd
│   ├── save_service.gd
│   ├── settings_service.gd
│   ├── audio_service.gd
│   ├── localization_service.gd
│   ├── input_service.gd
│   └── phase_clock.gd
├── core/                         # 不依赖游戏内容的底层
│   ├── entity/                   # EntityBase
│   ├── pool/                     # ObjectPool<T>
│   ├── data/                     # JSON/CSV 加载器
│   ├── math/                     # 工具函数(确定性 RNG 等)
│   └── signals/                  # 信号名常量
├── data/                         # 数据资源(策划表)
│   ├── towers/                   # TowerData.tres
│   ├── enemies/                  # EnemyData.tres
│   ├── waves/                    # WaveData.tres
│   ├── levels/                   # LevelData.tres(24 关)
│   ├── heroes/                   # HeroData.tres
│   ├── skills/                   # SkillData.tres
│   ├── status_effects/           # StatusEffectData.tres
│   ├── projectiles/              # ProjectileData.tres
│   ├── phase_events/             # PhaseEventData.tres
│   └── balance/                  # BalanceSnapshot.tres
├── scenes/
│   ├── boot/
│   ├── ui/                       # 主菜单 / HUD / 设置 / 结算
│   │   ├── components/           # 复用控件(像素风格 9-slice)
│   │   ├── hud/
│   │   ├── menu/
│   │   └── popups/
│   ├── levels/                   # level_01.tscn … level_24.tscn
│   ├── towers/                   # 6 塔场景模板
│   ├── enemies/                  # 24+8 敌人场景模板
│   ├── heroes/                   # 4 英雄场景模板
│   ├── projectiles/              # 投射物场景模板
│   ├── path_network/             # PathNetwork 预制组件,见 §5
│   └── common/
├── scripts/
│   ├── towers/                   # TowerBase + 6 塔子类
│   ├── enemies/                  # EnemyBase + 32 敌人子类
│   ├── heroes/                   # HeroBase + 4 英雄子类
│   ├── projectiles/              # ProjectileBase
│   ├── status_effects/           # StatusEffectRunner
│   ├── waves/                    # WaveDirector
│   ├── path_network/             # 见 §5
│   ├── phase/                    # PhaseController
│   ├── becon_power/              # 航标充能(见 §10)
│   └── ui/
├── assets/
│   ├── art/
│   │   ├── tilesets/             # 32×32 像素地形
│   │   ├── characters/
│   │   ├── towers/
│   │   ├── vfx/
│   │   ├── ui/
│   │   └── icons/
│   ├── audio/
│   │   ├── music/
│   │   ├── sfx/
│   │   └── amb/
│   ├── fonts/                    # 含 CJK 字体 + 拉丁像素字体
│   └── shaders/
├── tests/
│   ├── unit/                     # GUT 单元测试
│   ├── integration/              # 关卡 / suspend save / 迁移
│   └── fixtures/                 # golden level / save / screenshot
└── tools/                        # 编辑器脚本、批处理
```

### 3.2 AutoLoad 与命名规范

**【Policy】** AutoLoad 命名统一 `*Service` 后缀(与 PRD §18.1 一致):

| AutoLoad 名 | 职责 |
|---|---|
| `EventBus` | 全局 typed signal,只传事件不存状态 |
| `SaveService` | 存档读写、迁移、suspend save |
| `SettingsService` | ConfigFile → user://settings.cfg |
| `AudioService` | 总线、音量、Bus 池 |
| `LocalizationService` | Godot 内置 Translation 包装 |
| `InputService` | 键鼠 / 手柄 / 触屏抽象 |
| `PhaseClock` | 全局相位时间轴(明潮 / 暮潮 / 潮汐仪) |

**【Policy】** 关卡内全局对象(随关卡场景进入/退出):
`WaveDirector` / `PathNetwork` / `BuildNodeManager` / `TowerManager` / `EnemyManager` / `HeroController` / `PhaseController` / `BeconLedger` / `CombatEventBus` / `BattleHUD`。

**【Policy】** AutoLoad **不依赖**其他 AutoLoad 的 `_init`;跨依赖通过显式初始化或方法注入,禁止假设顺序。

### 3.3 节点命名

**【Policy】** PascalCase 节点类,小写下划线场景文件:
- 类:`TowerBase` / `Tower_NeedleRail` / `EnemyBase` / `Enemy_SaltShellWalker`
- 场景:`tower_needle_rail.tscn` / `enemy_salt_shell_walker.tscn`
- 资源:`TowerData_NeedleRail.tres`(snake_case + PascalCase 混合)

---

## 4. 像素艺术渲染配置

### 4.1 关键事实

**【Verified】** Godot 4 像素艺术由以下设置共同决定:

| 设置 | 值 | 备注 |
|---|---|---|
| `textures/canvas_textures/default_texture_filter` | `0`(Nearest) | 像素必需 |
| `window/stretch/mode` | `viewport`(严格像素) | 严格模式 |
| `window/stretch/aspect` | `keep`(加黑边) | 像素艺术避免拉伸 |
| `window/stretch/scale_mode` | `integer`(整数倍缩放) | Godot 4.2 起引入 |
| `2d/snap/snap_2d_transforms_to_pixel` | `true` | 防止亚像素抖动 |
| `2d/snap/snap_2d_vertices_to_pixel` | `true` | 同上 |

**来源**:[GDQuest — Pixel Art in Godot 4](https://www.gdquest.com/library/pixel_art_setup_godot4/),[Godot Docs — Multiple resolutions](https://docs.godotengine.org/en/latest/tutorials/viewports/multiple_resolutions.html)

### 4.2 推荐的 `project.godot` 段

```ini
[application]
config/name="AshenTides"
config/features=PackedStringArray("4.7", "Forward Plus")

[display]
window/size/viewport_width=640
window/size/viewport_height=360
window/stretch/mode="viewport"
window/stretch/aspect="keep"
window/stretch/scale_mode="integer"
window/stretch/mipmap=false

[rendering]
renderer/rendering_method="forward_plus"
renderer/rendering_method.mobile="mobile"
renderer/rendering_device/driver.windows="d3d12"
textures/canvas_textures/default_texture_filter=0
textures/canvas_textures/default_texture_repeat=0
textures/default_filters/anisotropic_filtering_level=0
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true

[gui]
theme/default_font_pixel_snap=true
```

**【Verified】** 640×360 的依据:
- 1080p(1920×1080)是整数 3× 缩放,无黑边。
- 720p(1280×720)是整数 2× 缩放,无黑边。
- 1440p(2560×1440)非整数,自动 floor 到 4× 即 2560×1440(满屏),无问题。
- 4K(3840×2160)是整数 6× 缩放,无黑边。

**【Policy】** 选定 640×360 后,所有 tile 尺寸统一 **32×32**;视野 = 20 × 11.25 tiles,适合长条路线关卡。角色占地 32×32,精英 64×64,Boss 96×96 或 128×128。

### 4.3 相机

**【Policy】** Camera2D 配置:
- `zoom` 仅整数档(1×, 2×),不要 1.5×。
- 默认 `position_smoothing_enabled=false`(像素艺术不需要平滑)。
- `limit_left/right/top/bottom` 锁在地图内。

### 4.4 修改默认过滤的注意事项

**【Warning】** 修改 `default_texture_filter` 之前已经导入的纹理仍是 Linear 过滤。**必须**:
1. 关闭 Godot 编辑器
2. 删除 `res://.godot/imported/` 缓存目录
3. 重启编辑器
4. 对每张纹理在 FileSystem dock 选中 → Import 面板 → 取消 `Filter` → Reimport

---

## 5. 固定 BuildNode + 预制 PathNetwork

> 这是本项目的 **路径模型**:玩家不可自由建路/堵路,关卡设计师预制所有路线与节点。本节是本项目对"传统塔防自由堵路"模式的明确替换。

### 5.1 路径模型定义

**【Policy】** 路径模型由三个预制组件构成:

| 组件 | 角色 | 数据 |
|---|---|---|
| `BuildNode`(固定建造点) | 关卡设计师放置的有限节点(8–22 个),玩家只能在此处建塔 | `id: StringName`, `world_position: Vector2`, `allowed_tower_types: Array[StringName]`, `tags: BitField`(潮滩/锚地/高地) |
| `PathRoute`(预制路径) | 一条完整的出生点→终点路线,由 `Segment` 串联 | `id: StringName`, `segments: Array[Segment]`, `visible_in_phase: Array[PhaseId]`(该路径在哪几个相位可见) |
| `Segment`(路径段) | 路径的两个连续节点 | `from: Node2D`, `to: Node2D`, `curve: Curve2D`, `width_px: float` |

**【Policy】** 玩家放置塔在 `BuildNode` 上;敌人沿 `PathRoute` 的 segment 移动。**BuildNode 永远不在 Segment 上**,所以**放塔不可能堵路**。

### 5.2 运行时数据流

```gdscript
class_name PathNetwork extends Node2D

@export var routes: Array[PathRoute]
@export var spawn_points: Array[Marker2D]
@export var goal_points: Array[Marker2D]

var active_routes: Dictionary[StringName, PathRoute] = {}

func activate_route(route_id: StringName) -> void:
    var route: PathRoute = routes[route_id]
    active_routes[route_id] = route

func deactivate_route(route_id: StringName) -> void:
    active_routes.erase(route_id)

func get_progress_for_enemy(route_id: StringName, segment_index: int, t: float) -> float:
    # 返回 0..1 的路线进度,敌人用此推进
    ...
```

### 5.3 敌人与路径

**【Policy】** 敌人记录:
```
state.route_id: StringName
state.segment_index: int
state.segment_t: float       # 0..1 当前段内进度
state.phase_id: StringName   # 出生时所在的相位(明潮/暮潮)
```

敌人 `_physics_process(delta)`:
1. 取当前 route_id 对应 PathRoute。
2. 取 segments[segment_index],按 `segment.curve` 取点。
3. `move_and_slide` 沿曲线插值。
4. 到达段末,segment_index++。若超出,进入下一 route;若无下一 route,抵达终点。

**【Policy】** 同一波在相同操作下必须复现相同路线与结果(确定性)。这要求路线切换在波次开始时确定,不在帧间变化。

### 5.4 哪些场景用 AStarGrid2D

**【Policy】** AStarGrid2D 在本项目**仅用于**:
- **英雄地面移动**:英雄可走任意可走 cell,使用 NavigationAgent2D + NavigationRegion2D(更自然)。
- **关卡编辑器**:关卡设计师离线检查路线连通性、覆盖盲区。
- **潮汐仪效果预览**:Boss 阶段技能需要快速查询最近 spawn→goal 路径。

**【Policy】** 普通敌人**不**使用 AStar;只走预制 PathRoute。

### 5.5 相位改道如何工作

**【Verified】** PRD §4.1 相位系统允许"一段潮滩道路开启/关闭"。实现方式:

```gdscript
# PhaseController 在相位切换时
func _on_phase_changed(new_phase: PhaseId) -> void:
    for route in path_network.routes:
        if route.visible_in_phase.has(new_phase):
            path_network.activate_route(route.id)
        else:
            path_network.deactivate_route(route.id)
    # 已出生的敌人:旧 route 还在但不再激活,允许它们走完当前段
    # 在新一波开始前,所有敌人在出生时被分配新 phase_id
```

**【Policy】** 路线切换在波次边界完成;**不在帧间动态改变路线**,以保证确定性。

---

## 6. TileMap / TileMapLayer

### 6.1 TileMapLayer 介绍

**【Verified】** Godot 4.3 引入 `TileMapLayer` 节点,作为 `TileMap` 单节点的替代。多个 `TileMapLayer` 共享一个 `TileSet` 资源,各自维护 cell 数据、Z-index、Y-sort、modulate。

**来源**:[CSDN EP11:初识瓦片地图](https://blog.csdn.net/luckyrui123/article/details/155442298),[Godot Docs — Using TileMaps](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html)

### 6.2 关卡分层结构

**【Policy】** 本项目每个关卡使用以下 `TileMapLayer`(同节点下,从下到上):

| 层 | 名字 | 内容 | 物理 | 导航 |
|---|---|---|---|---|
| 0 | `ground` | 海水/海床/底层地面 | 无 | 无 |
| 1 | `terrain_decor` | 装饰(礁石、珊瑚、船骸) | 无 | 无 |
| 2 | `path_overlay` | 路径瓦片(可视,与 PathRoute 重叠) | 无 | 无 |
| 3 | `build_zone` | 高亮标记可建区域(辅助 BuildNode) | 无 | 无 |
| 4 | `phase_indicator` | 相位切换临时高亮 | 无 | 无 |

**【Policy】** `path_overlay` 仅作可视化;碰撞和实际行走由 `PathNetwork` 的曲线决定。两者坐标严格对齐。

### 6.3 TileSet 与 Terrain

**【Verified】** Godot 4 TileSet 支持 Terrain(peering bits)和自定义 data layers。

**【Policy】** 每关 `tile_size` 必须为 `32×32`,与 PathNetwork 和 Camera 一致。Terrain 至少 3 个:
- `sea`(海水)
- `rock`(礁石/陆地)
- `path`(路径)

---

## 7. 数据驱动架构

### 7.1 总原则

**【Policy】** 所有游戏内容通过 Resource / JSON 描述,场景仅做引用。**禁止**硬编码数值、ID、字符串到场景或脚本。

### 7.2 Resource 类继承

```gdscript
# data/towers/tower_data.gd
class_name TowerData extends Resource

@export var id: StringName              # 唯一 ID,稳定,进入存档后不变
@export var display_name_key: StringName # 本地化 key,不是中文原文
@export var base_cost: int
@export var tiers: Array[TowerTier]     # 长度 = 4 (I, II, III, IV)
@export var projectile_scene: PackedScene
@export var target_priority: TargetPriority
@export var icon: Texture2D

class TowerTier extends Resource:
    @export var tier: int                 # 1..4
    @export var damage: float
    @export var range_px: float
    @export var fire_interval: float
    @export var cost_to_upgrade: int
    @export var sprite_frames: SpriteFrames
    @export var modules: Array[ModuleData] # II 级: 3 选 1;III/IV 级: 0
    @export var iv_skill: SkillData       # IV 级独有
```

**【Policy】** `id` 一旦进入公开存档不可改名;改名必须走迁移流程(见 §14.4)。

### 7.3 JSON / Resource 选择

| 数据 | 推荐 | 理由 |
|---|---|---|
| TowerData / EnemyData / SkillData 等单实体 | **Resource(.tres)** | 强类型、编辑器友好 |
| WaveData / LevelData(组合多实体) | **JSON** + 自定义加载器 | 易于 diff、版本控制友好 |
| BalanceSnapshot(每次发布的快照) | **Resource** | 需 EditorInspector 检查 |
| Settings(玩家设置) | **ConfigFile** | 标准 INI 格式 |

### 7.4 数据加载器

**【Policy】** 所有 .json 在加载时校验:
- 必填字段存在
- ID 唯一
- 数值在合法范围
- 跨文件引用(如 `level.heroes[0]` 引用 `hero.id`)存在

校验失败:`push_error` + 阻止关卡进入,绝不静默通过。

### 7.5 加载时序

**【Policy】** 启动顺序:
1. `LocalizationService._ready()` 加载 .po/.csv
2. `SettingsService._ready()` 读 `user://settings.cfg`
3. 主菜单显示
4. 进入关卡:`LevelLoader.load(level_id)` → 加载 .tres + .json,做校验
5. `WaveDirector._ready()`、`PathNetwork._ready()` 等
6. 第一波开始前生成 suspend save 检查点

---

## 8. 战斗实体

### 8.1 EntityBase

```gdscript
class_name EntityBase extends Node2D

@export var id: StringName
@export var max_hp: float
var current_hp: float
@onready var hp_bar: ProgressBar = $HPBar
@onready var sprite: AnimatedSprite2D = $Sprite

signal died(killer: Node, position: Vector2)
signal damaged(amount: float, type: DamageType, source: Node)

func take_damage(amount: float, type: DamageType, source: Node) -> void:
    var actual := compute_final_damage(amount, type)
    current_hp -= actual
    damaged.emit(actual, type, source)
    if current_hp <= 0:
        die(source)

func compute_final_damage(base: float, type: DamageType) -> float:
    # 抗性公式(PRD §3.2)
    var resist := get_resist(type)
    var coef := 100.0 / (100.0 + maxf(-50.0, resist))
    return base * coef
```

### 8.2 塔(Tower)

**【Policy】** 六塔命名(本项目原创,**非**传统四塔):

| id | 名称 | 空间规则 |
|---|---|---|
| `tower_needle_rail` | 针轨弩台 | 直线穿透,方向重要 |
| `tower_ember_well` | 余烬喷井 | 扇形短射程,留下热区 |
| `tower_echo_pile` | 回声桩阵 | 两桩之间生成伤害线 |
| `tower_wind_nest` | 风帆机巢 | 派出可重定向无人帆 |
| `tower_tide_anvil` | 铸潮砧塔 | 攻击产生可拾取碎片 |
| `tower_prism_grove` | 棱镜苗圃 | 链接附近塔传递增益 |

**【Policy】** 升级结构:4 级(I, II, III, IV)。II 级时 3 选 1 校准模块,本局锁定。IV 级解锁 1 自动被动 + 1 付费主动技能。

**【Policy】** 玩家**不能**通过 SDK 文档/KR Wiki 等"参考作品"实现机制;实现参考仅限 PRD §6。

### 8.3 投射物(Projectile)

**【Policy】** 投射物用 `Area2D + Sprite2D`,生命周期:
1. `acquire()` 从对象池取出
2. `setup(caster, target, damage, speed, status_to_apply)`
3. `_physics_process`: 朝 target 飞行(可用纯追踪或预存弹道)
4. `body_entered`: 命中 → 调 target.take_damage + 应用 status;release 回池
5. 5s TTL 仍未命中 → release 回池

### 8.4 状态效果(Composition over Inheritance)

**【Policy】** 状态效果用组合模式;每个效果是 `StatusEffectData.Instance`(RefCounted),挂在实体 `active_effects: Array` 上,统一 tick:

```gdscript
class_name StatusEffectRunner extends Node

@export var target: EntityBase
var active_effects: Array[StatusEffectData.Instance] = []

func apply(effect: StatusEffectData, source: Node) -> void:
    if effect.can_stack:
        # 检查同 kind 已存在的 instance,叠加
        ...
    else:
        active_effects.append(StatusEffectData.Instance.new(effect, source))

func _process(delta: float) -> void:
    for inst in active_effects:
        inst.tick(delta, target)
    active_effects = active_effects.filter(func(i): return i.remaining > 0)
```

### 8.5 敌人(Enemy)

**【Policy】** 敌人记录:`route_id` + `segment_index` + `segment_t` + `phase_id`。不做 A*。

```gdscript
class_name EnemyBase extends EntityBase

@export var data: EnemyData
var route_id: StringName
var segment_index: int
var segment_t: float
var phase_id: StringName

func _physics_process(delta: float) -> void:
    var route := path_network.active_routes[route_id]
    if not route: return
    if segment_index >= route.segments.size():
        _reach_goal()
        return
    var segment: Segment = route.segments[segment_index]
    var target_pos := segment.curve.sample(segment_t + delta * speed / segment.length)
    var dir := (target_pos - global_position).normalized()
    velocity = dir * data.speed_px_per_sec
    move_and_slide()
    segment_t += delta * data.speed_px_per_sec / segment.length
    if segment_t >= 1.0:
        segment_t = 0.0
        segment_index += 1
```

**【Policy】** 敌人动画帧从 `data.sprite_frames` 读取;不接受硬编码。

---

## 9. 相位系统

### 9.1 相位数据

```gdscript
class_name PhaseEventData extends Resource

@export var id: StringName
@export var level_id: StringName
@export var starts_at_wave: int           # 第几波开始时切换
@export var from_phase: PhaseId           # 明潮或暮潮
@export var to_phase: PhaseId
@export var activates_routes: Array[StringName]
@export var deactivates_routes: Array[StringName]
@export var environment_changes: Array[EnvironmentChange]
@export var warning_seconds: float = 20.0 # 必须 ≥ 20 秒
@export var player_interruptible: bool = true
@export var becon_cost: int = 40          # 潮汐仪延后/提前成本
```

### 9.2 PhaseController

```gdscript
class_name PhaseController extends Node

@export var level_id: StringName
var current_phase: PhaseId = PHASE_MINGCHAO
var pending_phase: PhaseId = PHASE_MINGCHAO
var switch_at_seconds: float = 0.0
var warning_signal_emitted: bool = false

@onready var path_network: PathNetwork
@onready var becon_ledger: BeconLedger

func _process(delta: float) -> void:
    if not warning_signal_emitted and warning_seconds_remaining() < 20.0:
        EventBus.phase_warning.emit(pending_phase, 20.0)
        warning_signal_emitted = true
    if switch_at_seconds > 0 and Time.get_ticks_msec() / 1000.0 >= switch_at_seconds:
        _switch_to(pending_phase)

func _switch_to(new_phase: PhaseId) -> void:
    for r in activate_routes_for(new_phase):
        path_network.activate_route(r)
    for r in deactivate_routes_for(new_phase):
        path_network.deactivate_route(r)
    current_phase = new_phase
    EventBus.phase_changed.emit(new_phase)

func request_shift(delta_seconds: float) -> bool:
    if not becon_ledger.try_spend(40): return false
    switch_at_seconds += delta_seconds
    return true
```

### 9.3 潮汐仪

**【Policy】** 潮汐仪是 **航标充能消费** 的唯一来源(见 §10)。一次潮汐仪干预消耗 40 充能,改变相位切换时间 ±10 秒。**Boss 阶段相位锁死,不可干预**。

---

## 10. 航标充能系统

### 10.1 定义

**【Policy】** 航标充能(`becon`)是 0–100 的主动资源,由战斗行为(击杀、治疗、显形、相位互动)产生,被以下消费:
- 英雄终极技
- 潮汐仪延后/提前
- 部分地图装置

**【Policy】** 英雄终极技与潮汐仪**争夺**同一资源,这是本项目原创的核心张力。

### 10.2 BeconLedger

```gdscript
class_name BeconLedger extends Node

signal value_changed(new_value: int)

var current: int = 0

func add(amount: int, source: StringName) -> void:
    var before := current
    current = clamp(current + amount, 0, 100)
    value_changed.emit(current)
    EventBus.becon_changed.emit(current, source)

func try_spend(amount: int) -> bool:
    if current < amount: return false
    current -= amount
    value_changed.emit(current)
    EventBus.becon_spent.emit(amount)
    return true
```

---

## 11. 英雄系统

### 11.1 HeroBase

```gdscript
class_name HeroBase extends CharacterBody2D

@export var data: HeroData
var becon_ledger: BeconLedger
var downed_at: float = 0.0
const REVIVE_SECONDS: float = 25.0

func _ready() -> void:
    becon_ledger = get_tree().get_first_node_in_group("becon_ledger")
    EventBus.becon_spent.connect(_on_becon_spent)

func use_skill_a() -> void:
    if not data.skill_a.is_ready(): return
    data.skill_a.execute(self)

func use_ultimate() -> bool:
    if not becon_ledger.try_spend(data.ultimate.cost):
        EventBus.ultimate_failed_no_becon.emit()
        return false
    data.ultimate.execute(self)
    return true

func die() -> void:
    downed_at = Time.get_ticks_msec() / 1000.0
    set_physics_process(false)
    visible = false
    # 25 秒后 _revive

func _revive() -> void:
    set_physics_process(true)
    visible = true
    current_hp = data.max_hp * 0.3  # 30% 复活
```

### 11.2 四英雄(本项目原创)

| id | 名称 | 定位 |
|---|---|---|
| `hero_lanzhou_wei` | 岚舟·苇 | 机动侦察 |
| `hero_zhushou_muen` | 铸手·穆恩 | 前排与机关 |
| `hero_baoyuzhe_mi_luo` | 孢语者·弥洛 | 持续支援 |
| `hero_shizhongren_se_ruei` | 失钟人·瑟芮 | 风险爆发 |

技能明细见 PRD §7.4。

---

## 12. 关卡数据(LevelData)

```gdscript
class_name LevelData extends Resource

@export var id: StringName                  # level_c01
@export var display_name_key: StringName
@export var scene: PackedScene
@export var map_size_cells: Vector2i        # 20×11 (640×360 ÷ 32)
@export var spawn_points: Array[Marker2D]
@export var goal_points: Array[Marker2D]
@export var build_nodes: Array[BuildNodeData]
@export var path_routes: Array[PathRoute]
@export var initial_ember: int               # 起始火种
@export var initial_fleet_integrity: int     # 起始舰队完整度
@export var waves: Array[WaveData]
@export var phase_events: Array[PhaseEventData]
@export var allowed_towers: Array[StringName]
@export var allowed_heroes: Array[StringName]
@export var primary_objective: StringName
@export var optional_objectives: Array[StringName]
@export var bgm_track: StringName
@export var estimated_duration_min: Vector2i  # [min, max]

class BuildNodeData extends Resource:
    @export var id: StringName
    @export var world_position: Vector2
    @export var allowed_tower_types: Array[StringName]
    @export var tags: BitField                  # 潮滩/锚地/高地
```

**【Policy】** 关卡数据在加载时必须校验:`build_nodes` 不在 `path_routes` 任意 `segment.curve` 上;出生点必须在地图边缘;至少一条从每个 spawn 到每个 goal 的 active route。

---

## 13. 波次系统

### 13.1 WaveData

```gdscript
class_name WaveData extends Resource

@export var wave_index: int
@export var pre_delay_seconds: float         # ≥ 5 秒
@export var groups: Array[WaveGroup]
@export var completion_reward_ember: int
@export var completion_reward_becon: int
@export var intent: WaveIntent                # 经济/速度/护甲/分路/救场/Boss 准备

class WaveGroup extends Resource:
    @export var enemy_id: StringName
    @export var count: int
    @export var interval_seconds: float
    @export var entrance_index: int            # spawn_points[entrance_index]
    @export var delay_after_prev_seconds: float
    @export var formation: Formation
```

### 13.2 WaveDirector 状态机

```
IDLE → BUILD (等待玩家按"开始波次")
     → WAVE_PRE_DELAY (倒计时 ≥ 5 秒,显示敌人预告)
     → WAVE_SPAWN (按 groups 生成)
     → WAVE_CLEAR (本波所有敌人消失)
     → (有下一波? 是 → BUILD;否 → WIN)
任意阶段接 LOSE 转换:舰队完整度 ≤ 0 → LOSE → END
```

**【Policy】** 同屏敌人数:180 普通 + 120 投射物 + 80 特效 = 380 总动态节点上限(3× 速度)。

---

## 14. 存档系统

### 14.1 存档目录

**【Policy】** 存档路径: `user://saves/`
- 战役槽:`slot_01.save.json` / `.bak1` / `.bak2`(轮转备份)
- 设置:`user://settings.cfg`(ConfigFile)
- suspend save(单局):`user://suspend/suspend_<level_id>_<wave_index>.json`
- 日志:`user://logs/`(崩溃报告,可关闭)

### 14.2 存档格式(JSON + 原子写)

**【Policy】** 写入流程:
1. 写 `slot_01.save.json.tmp`
2. 校验 JSON 合法
3. 若 `slot_01.save.json` 存在,备份为 `.bak1`(覆盖旧 bak1)
4. `DirAccess.rename_absolute(.tmp, .save.json)`

读取流程:优先 `.save.json` → 失败读 `.bak1` → 再失败读 `.bak2` → 失败显示"存档损坏"提示。

### 14.3 Suspend Save(单局中断恢复)

**【Policy】** 在以下时刻自动写 suspend save:
- 每个波次完成时
- Boss 阶段开始 / 完成
- 玩家手动暂停时(可选)
- 应用退出前(`NOTIFICATION_WM_CLOSE_REQUEST`)

**【Policy】** Suspend save 内容:
- `level_id`、`current_wave_index`、`current_phase_id`
- RNG 种子(`RandomNumberGenerator.state`)
- 舰队完整度、火种、航标充能
- 塔列表(ID + tier + module_id + position + hp + cooldown)
- 英雄状态、敌人列表(同上)
- PhaseController 状态、暂停标记

**【Policy】** 加载 suspend save 时:
- 验证 schema_version
- 显示"上次在 C## 第 N 波退出,继续?"
- 三选项:继续 / 放弃本局(回 BUILD 阶段) / 退出到关卡选择

### 14.4 版本迁移

**【Policy】** 每次 schema 变化必须:
- bump `SCHEMA_VERSION`
- 提供 `vN_to_vN+1_migrate(payload) -> payload`
- 迁移前保留旧档为 `slot_XX.vN.bak.json`
- 单元测试覆盖最近 5 个已发布 schema

---

## 15. UI / 输入 / 无障碍

### 15.1 视觉语言

**【Policy】** UI 视觉基于 **潮汐航海仪器**:海图刻度盘、棱镜透镜、黄铜指针、深度刻度、航线。**禁止**:
- 木质卷轴中世纪风格(避免与某经典塔防过近)
- 默认 Godot 主题(过通用)

### 15.2 Control 节点基础

**【Verified】** Godot 4 Control 节点 4 种 layout mode:POSITION / ANCHORS / CONTAINER / UNCONTROLLED。容器内子节点由容器接管,不要在容器里手设 anchors。

**来源**:[DeepWiki — Layout and Container System](https://deepwiki.com/kdada/godot/4.2-layout-and-container-system)

**【Policy】** 所有 UI 用 Container(VBoxContainer / HBoxContainer / GridContainer / MarginContainer / AspectRatioContainer)布局。锚点仅用于全屏背景。

### 15.3 主题

**【Policy】** 创建 `theme_ashen_tides.tres` 全局主题,挂在主菜单根 Control 上;所有 UI 节点继承。

StyleBox 集中在 `assets/ui/styleboxes/`:`panel_main` / `panel_popup` / `button_default` / `button_hover` / `progress_bar_bg` / `progress_bar_fill`。

### 15.4 输入

**【Policy】** `InputService` AutoLoad 封装:
- 键鼠:`InputEventMouseButton` / `InputEventMouseMotion`
- 手柄:`InputEventJoypadButton` / `InputEventJoypadMotion`
- 触屏:`InputEventScreenTouch` / `InputEventScreenDrag`

**InputMap** action 必须包括:`pause` / `speed_up` / `speed_down` / `select_next_tower` / `select_prev_tower` / `place_tower` / `sell_tower` / `use_hero_skill_a/b/c` / `use_hero_ultimate` / `camera_pan_up/down/left/right` / `toggle_phase_indicator`。

**【Verified】** Godot 4.7+ 提供 `VirtualJoystick` 节点(原生),为未来触屏版预留,不强制启用。

**来源**:[Godot 4.7 release notes](https://godotengine.org/article/godot-4-7-release-notes/)

### 15.5 无障碍基础(分确定/实验/不承诺三类)

**【Policy】** v1.0 落地:
- ✅ 确定:UI 缩放 80–160%、色弱 1 套预设 + 自定义、键鼠+手柄完整、独立音量、字幕、可暂停、可跳过过场、震屏/闪白可关
- ⚠️ 实验:简化瞄准、自动英雄基础技能、单手键位预设
- ❌ 不承诺:屏幕阅读器语义标签、低视觉噪声模式(留 P2)

---

## 16. 音频系统

### 16.1 总线

**【Policy】** `default_bus_layout.tres`:
```
Master
├── Music (BGM,EQ 提升低音,长尾 reverb)
├── SFX
│   ├── Combat (塔攻击、敌人死亡、技能)
│   ├── UI (按钮、提示音)
│   └── Ambient (环境音、风声)
└── Voice (DLC/Mod 预留)
```

### 16.2 音频格式

**【Policy】** 桌面平台:
- 音乐 `.ogg` Vorbis(MP3 有专利,WAV 体积大)
- SFX `.ogg` Vorbis 或 `.wav`(短音)

**【Verified】** Godot 4 Web 导出音频:.ogg / .wav / .mp3 三种都支持;官方推荐 .ogg Vorbis。

### 16.3 AudioService

```gdscript
class_name AudioService extends Node

const SFX_POOL_SIZE: int = 16
var _sfx_pool: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer

func _ready() -> void:
    for i in SFX_POOL_SIZE:
        var p := AudioStreamPlayer.new()
        p.bus = "SFX"
        add_child(p)
        _sfx_pool.append(p)

func play_sfx(stream: AudioStream, bus: StringName = "Combat", pitch: float = 1.0) -> void:
    for p in _sfx_pool:
        if not p.playing:
            p.stream = stream
            p.pitch_scale = pitch
            p.bus = bus
            p.play()
            return

func play_bgm(stream: AudioStream, fade_sec: float = 1.0) -> void:
    # 交叉淡化
    ...
```

### 16.4 音频事件矩阵(见 ASSET_CATALOG §11)

**【Policy】** 每个威胁/事件必须有可辨识声音:飞行进入、隐匿显形、治疗施放、出口告急、相位将变。

---

## 17. 性能与对象池

### 17.1 目标机

**【Policy】** 锁定最低目标机:
- CPU: Intel Core i5-1135G7(或等效 Zen 2)
- GPU: Intel UHD 730 集成显卡
- RAM: 8 GB DDR4
- 存储: 256 GB SSD
- OS: Windows 10 64-bit

**【Policy】** 性能预算:
- 1080p 60 FPS,1× 速度
- 1080p 60 FPS,3× 速度
- 1% low ≥ 45 FPS(3× 速度,同屏 380 节点)

### 17.2 对象池

**【Policy】** 必须在 M0 实现的池:
- `ProjectilePool`
- `XPGemPool`(经验宝石)
- `DamageNumberPool`(伤害飘字)
- `ParticleEffectPool`
- `AudioStreamPlayer` SFX 池(见 §16.3)

**【Policy】** 同屏上限:380 总动态节点(180 普通敌 + 120 投射物 + 80 特效)。

### 17.3 性能监控

**【Verified】** Godot 4 Debugger 面板的 Profiler / Visual Profiler / Monitors 是日常工具。

**【Policy】** 自定义 monitor:
```gdscript
func _ready() -> void:
    Performance.add_custom_monitor("alive_enemies", Callable(self, "_count_alive_enemies"))
    Performance.add_custom_monitor("active_projectiles", Callable(self, "_count_active_projectiles"))
```

**【Warning】** profile 必须用 **release build**,不用编辑器。

---

## 18. 测试

### 18.1 框架

**【Policy】** 使用 [GUT 9.x](https://github.com/bitwes/Gut.git)。Godot 4.7 对应 GUT 9.6.0+。

### 18.2 测试目录

```
tests/
├── unit/
│   ├── test_balance.gd
│   ├── test_damage_formula.gd
│   ├── test_status_effects.gd
│   ├── test_save_migration.gd
│   └── test_path_route.gd
├── integration/
│   ├── test_wave_completion.gd
│   ├── test_suspend_save.gd
│   ├── test_phase_change.gd
│   └── test_hero_skill.gd
└── fixtures/
    ├── golden_save_v3.json
    ├── golden_level_c01.tres
    └── golden_screenshot.png
```

### 18.3 CI

**【Policy】** 在 Windows runner 上跑:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gexit
```

### 18.4 性能回归脚本

**【Policy】** 固定布局 + 固定种子下跑 60 秒 3× 战斗,记录平均 FPS 和 1% low,数据写入历史 CSV,跨版本比较。

---

## 19. 工具链与发布

### 19.1 工具清单

**【Verified】** Godot 4 编辑器自带的工具:
- FileSystem dock
- TileMap 编辑
- Debugger 面板
- Performance monitor
- Export Manager

**【Policy】** 第三方工具(若需):
- [Aseprite](https://www.aseprite.org/) — 像素美术(一次性购买)
- [LDtk](https://ldtk.io/) — 关卡编辑器(免费,后期可选)
- [GUT](https://github.com/bitwes/Gut) — 测试(本项目必装)
- [Git](https://git-scm.com/) — 版本控制
- 文本编辑器:VS Code / Godot Script Editor

### 19.2 发布平台

**【Policy】** v1.0 仅 Windows PC,通过 [Steam](https://store.steampowered.com/sub/163632/) 发行。

**【Verified】** Steam 抽成(2024 年起三档,每游戏独立):
- 30%(营收 < $10M)
- 25%($10M–$50M)
- 20%(> $50M)

**来源**:[Steam Partner docs](https://partner.steamgames.com/doc/gettingstarted/royalty)

### 19.3 Export Preset

**【Policy】** Windows 桌面 preset:
- `Forward+` renderer
- `x86_64` 架构
- 嵌入 PCK
- `vr.embedded_framebuffer = false`
- 自定义图标

### 19.4 发布流程

1. M6 发布候选(见 PRD §22)
2. 在 Windows + Steam Deck 同等硬件 + 低端机三档测试矩阵上跑 72 小时 soak
3. 性能 + 输入 + 存档 + 多分辨率 + 双语言 + 无障碍基础全部通过
4. 提交 Steam 商店审查(预留 2–4 周缓冲)
5. 商店页 + 截图 + 描述 + 系统需求 完成
6. 上线后首月保留热修复分支

---

## 20. 学习路径(0 基础如何上手)

### 20.1 推荐学习顺序(总 60–90 小时)

| 阶段 | 时长 | 资源 | 验收 |
|---|---|---|---|
| 1. GDScript 基础 | 15–20h | [GDQuest GDScript 教程](https://www.gdquest.com/tutorial/godot/gdscript) | 能写带类型的类和 signal |
| 2. Godot 4 编辑器 | 10h | [Godot 官方 Getting Started](https://docs.godotengine.org/en/stable/tutorials/getting_started/index.html) | 能建场景、写脚本、运行 |
| 3. 2D 节点系统 | 8h | [Godot 官方 2D 教程](https://docs.godotengine.org/en/stable/tutorials/2d/index.html) | 能用 Sprite2D / Area2D / CollisionShape2D |
| 4. TileMap / TileMapLayer | 6h | [官方 TileMaps 教程](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html) | 能画 32×32 地形 |
| 5. 信号 / AutoLoad | 6h | [AutoLoad 教程](https://docs.godotengine.org/en/4.0/tutorials/scripting/singletons_autoload.html) | 能建 EventBus |
| 6. Resource 数据驱动 | 5h | Godot 官方 Resource 教程 | 能定义 TowerData |
| 7. 项目实战(M0 灰盒) | 10–25h | 本文件 §3–§6 | 跑通 1 敌 1 塔 1 波 |

### 20.2 不推荐的学习路径

- ❌ 先学 Unity 再转 Godot:概念差异大,浪费时间
- ❌ 先学 C# / GDExtension:GDScript 足够本项目;C# 上手慢 + Web 不可用
- ❌ 一开始就啃 3D:本项目纯 2D

### 20.3 学习期的里程碑

**【Policy】** 0 基础用户必须先完成 M0(立项)再做 M1(灰盒)。M0 不写游戏代码,只搭项目骨架。

---

## 21. 工期与风险区间

### 21.1 估算基线

**【Recommendation】** **不缩成 Demo**,但用工作量而非日历愿望估算:

| 工时假设 | 数值 |
|---|---|
| 单人工作量 | 1 人 |
| 投入时间 | 15–20 小时/周(兼职) |
| 0 基础学习成本 | 已计入 60–90h(见 §20) |
| 系统设计 + 实现 + 调优 + 集成 + 返工缓冲 | 每系统 +30–50% |
| 美术产能 | 32×32 像素,每角色 4 方向 × 4 状态 × 6 帧 = 96 帧 ≈ 1–2 周/人 |

### 21.2 工期风险区间

**【Recommendation】** **零基础、兼职 15–20 小时/周、主要用合规资产 + 少量委托**:

| 工时/月 | 区间 | 备注 |
|---|---|---|
| **风险下限** | 30 个月 | 严格按计划、纵向切片顺利、无重大返工 |
| **风险上限** | 48 个月 | 经历 1–2 次架构调整、纵向切片反馈迭代、节庆/家庭中断 |
| 假设 | 18–24 个月 | 需要接近 1.5–2 个全职当量或明确的美术/音频/QA/本地化外包 |

**【Policy】** 项目主理人必须按 **30–48 个月风险区间** 自我管理;**纵向切片(C01–C03)通过后**,按实测吞吐重估,并把"按真实工时计算 24 关完工日"写入决策记录。

### 21.3 发布质量纵向切片 ≠ Demo

**【Policy / 重要】** C01–C03 是 v1.0 的前三个关卡,不是 demo/MVP。Gate B 通过后,**这些关卡直接进入 v1.0,内容不丢弃**。纵向切片的目标是:
- 验证生产链(美术 → 程序 → 测试 → 调优)
- 验证固定 BuildNode + PathNetwork 系统
- 验证相位系统
- 验证 CJK 字体 + 无障碍基础

### 21.4 关键风险(摘录,完整见 PRD §28)

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| 零基础导致架构反复 | 高 | 高 | M0 锁数据边界 + 事件契约 |
| 38 种敌人动画产能不足 | 高 | 高 | 复用 + 模块化精灵部件 + 委托 |
| CJK 字体选错导致后期重做 | 中 | 高 | M0 锁定字体并实测可读性 |
| Steamworks 集成延期 | 中 | 中 | 离线优先,Steam 后置 |
| 兼职中断(疾病/家庭) | 中 | 中 | 文档化,小里程碑,休息预算 |

---

## 22. 事实等级体系

**【Policy】** 所有事实性陈述必须标注等级;agent 不得擅自将低等级结论当约束使用。

| 等级 | 含义 | 处理 |
|---|---|---|
| **Verified** | 锁定版本官方文档/源码/本地可复现实验 | 可作为强制约束 |
| **Observed** | 本项目 spike 或测试机实际结果 | 仅作为参考 |
| **Assumption** | 尚未验证的计划假设 | 必须后续验证或标注待决 |
| **Recommendation** | 设计/工程选择,可讨论 | 不可作为强制约束 |
| **Policy** | 项目为了风险控制主动采用的规则 | 一旦锁定不可绕过 |

### 22.1 当前 Verified 清单

- Godot 4.7 = 当前稳定,2026-06-18 发布
- TileMapLayer 引入 Godot 4.3
- `stretch/scale_mode="integer"` 引入 Godot 4.2
- `AStarGrid2D.set_point_solid` 引入 Godot 4.3
- Web 导出仅支持 Compatibility renderer
- C# 项目不能 Web 导出
- Godot 4.6+ 新建项目 Windows 默认 D3D12、3D 默认 Jolt Physics
- 640×360 在 1080p 整数 3× 满屏

### 22.2 当前 Assumption 清单(必须后续验证)

- 6 塔 / 24+8+6 敌人 / 4 英雄在零基础兼职 30–48 月窗口内可完成
- CJK 字体 §23 Ark Pixel Font 实际可读性与许可证(待 ASSET_CATALOG §10 验证)
- 30 FPS 最低目标机 = Intel UHD 730 + i5-1135G7 是否够用(需 spike)

### 22.3 当前 Policy 清单(项目强制)

- 640×360 + 32×32 tile
- 固定 BuildNode + 预制 PathNetwork(不自由堵路)
- GDScript 2.0 全静态类型
- Suspend save 在波次完成时
- 视觉走潮汐航海仪器语言(非木质卷轴)
- Windows PC / Steam 首发
- 简中 + 英 P0
- 对象池与 P1 同时实现(不后置)

---

## 23. 已废弃术语扫描器

**【Policy】** 下列旧词**禁止**出现在正式文档、代码注释、commit message、UI 文本:

| 旧词 | 替换为 | 替换理由 |
|---|---|---|
| `gold` / `coins` | `ember`(火种) | PRD 命名 |
| `lives` / `hp_global` | `fleet_integrity`(舰队完整度) | PRD 命名 |
| `Stars` | `becon_mark`(航标印记) | PRD 命名 |
| `meteor` / `meteor_shower` | 删除;改为原创装置 | 避免与某经典塔防重合 |
| `reinforcements` | 删除;改为原创 | 同上 |
| `goblin` | 原创敌人(`salt_shell_walker`) | 避免通用原型 |
| `archer` / `mage` / `barracks` / `artillery` | 原创 6 塔(`needle_rail` / `ember_well` / `echo_pile` / `wind_nest` / `tide_anvil` / `prism_grove`) | 避免传统四塔 |
| `MVP` / `demo` / `vertical slice demo` | `release-quality vertical slice`(发布质量纵向切片) | 不偷换完整游戏承诺 |
| `LTS`(指代 Godot 4.7) | `stable`(稳定补丁线) | Godot 未声明 4.7 为 LTS |

**【Policy】** CI 中加 `scripts/check_forbidden_terms.py`,扫描 `res://**` 与 `docs/**`,发现旧词立即报错。

---

## 附录 A 术语表

| 中文 | 英文 | 说明 |
|---|---|---|
| 火种 | ember | 关卡内货币 |
| 舰队完整度 | fleet_integrity | 关卡内"命数" |
| 航标印记 | becon_mark | 战役货币 |
| 航标充能 | becon | 战斗内 0–100 主动资源 |
| 潮汐仪 | tide_clock | 消耗 40 充能的相位干预 |
| 校准模块 | calibration_module | II 级 3 选 1 |
| 针轨弩台 | needle_rail | 6 塔之一 |
| 余烬喷井 | ember_well | 6 塔之一 |
| 回声桩阵 | echo_pile | 6 塔之一 |
| 风帆机巢 | wind_nest | 6 塔之一 |
| 铸潮砧塔 | tide_anvil | 6 塔之一 |
| 棱镜苗圃 | prism_grove | 6 塔之一 |
| 岚舟·苇 | lanzhou_wei | 4 英雄之一 |
| 铸手·穆恩 | zhushou_muen | 4 英雄之一 |
| 孢语者·弥洛 | baoyuzhe_mi_luo | 4 英雄之一 |
| 失钟人·瑟芮 | shizhongren_se_ruei | 4 英雄之一 |

---

## 附录 B 决策记录

| 日期 | 决策 | 旧值 → 新值 | 来源 | 影响 |
|---|---|---|---|---|
| 2026-09-04 | viewport | 426×240 → **640×360** | REVIEW_TECH_LICENSE Blocker #2 | 1080p 整数 3× 满屏 |
| 2026-09-04 | tile 尺寸 | 16×16 / 32×32 → **统一 32×32** | REVIEW_PRODUCT §5 | AStarGrid2D / CellSize 锁定 |
| 2026-09-04 | 路径模型 | AStar 校验 + 自由堵路 → **固定 BuildNode + 预制 PathNetwork** | REVIEW_PRODUCT B-02 + 用户消息 | 普通敌人不再动态寻路 |
| 2026-09-04 | 内容规模 | 4 塔 / 16 敌 → **6 塔 / 24+8+6** | PRD §0 + 用户消息 | 锁定 v1.0 |
| 2026-09-04 | 首发模式 | 含无尽 → **无尽 P2** | 用户消息 | 缩短 v1.0 范围 |
| 2026-09-04 | 首发语言 | 9 种 → **简中 + 英 P0,繁中+日语 P1** | 用户消息 | 翻译成本降至 2 种 |
| 2026-09-04 | 工期 | 15–24 月 → **30–48 月风险区间,纵向切片后重估** | REVIEW_PRODUCT B-07 | 防止承诺过乐观 |
| 2026-09-04 | 工程代号 | "Tower Defense" → **《余烬潮汐》** | 用户消息 | 待商标清查 |
| 2026-09-04 | Godot 版本 | "4.7 LTS" → **"4.7.x 稳定补丁线"** | REVIEW_PRODUCT B-08 | 不冒充 LTS 承诺 |
| 2026-09-04 | 引擎版本锁 | 4.7 stable | Godot 官方 | M0 立项 |

---

## 附录 C 来源 URL 清单(可点击)

### 引擎与版本
- [Godot 4.7 Release Notes](https://godotengine.org/article/godot-4-7-release-notes/)
- [Godot 4.6 Release](https://godotengine.org/releases/4.6/)
- [Godot Release Policy](https://docs.godotengine.org/en/latest/about/release_policy.html)
- [Godot Docs — Multiple resolutions](https://docs.godotengine.org/en/latest/tutorials/viewports/multiple_resolutions.html)
- [Godot Docs — Exporting for the Web](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html)
- [Godot Docs — AutoLoad](https://docs.godotengine.org/en/4.0/tutorials/scripting/singletons_autoload.html)
- [Godot Docs — Using TileMaps](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html)
- [Godot Docs — AStarGrid2D](https://docs.godotengine.org/en/4.4/classes/class_astargrid2d.html)
- [Godot Docs — Debugger panel](https://docs.godotengine.org/en/4.0/tutorials/debug/debugger_panel.html)

### 像素与 2D
- [GDQuest — Pixel Art in Godot 4](https://www.gdquest.com/library/pixel_art_setup_godot4/)

### UI / Control
- [DeepWiki — Layout and Container System](https://deepwiki.com/kdada/godot/4.2-layout-and-container-system)

### 测试
- [GUT — GitHub](https://github.com/bitwes/Gut)

### 发布
- [Steam Partner — Royalty](https://partner.steamgames.com/doc/gettingstarted/royalty)

### 工具
- [Aseprite](https://www.aseprite.org/)
- [LDtk](https://ldtk.io/)

---

> 文档版本:Proposed v1.0(2026-09-04)
> 状态:正式候选技术报告，待项目主理人拍板后进入 M0
> 建议下一步:拍板后执行 M0 立项(ProjectSetup + Autoload 骨架 + 一个空场景)
