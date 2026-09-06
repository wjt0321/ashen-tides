# 开源塔防项目与资源参照研究

> 日期：2026-09-06
> 目的：在继续实现前，用真实开源项目校准《余烬潮汐》的产品闭环、架构分层和资产路线。
> 规则：本轮仅研究，不复制代码、不下载资产、不把第三方内容并入项目。

## 1. 结论先行

开源项目给出的共同答案不是“找一个仓库整体搬过来”，而是：

1. **完整游戏首先是玩家外壳与战斗内核的闭环**。有发布历史的项目会把欢迎页、选关、设置、持久化、游戏、结算、再进入下一局分成明确边界；只含塔、敌人、波次的模板仍只是模板。
2. **对本项目当前规模和既有 typed Resource 基线，优先采用 scene composition + signals + typed domain data**。塔、敌人、投射物、波次、地图和 HUD 各自拥有场景/脚本，通过信号通信；全局状态只保留设置、存档和稳定目录，不把所有逻辑塞进一个主脚本。
3. **为关闭当前 M2 玩家流程和 session 生命周期缺口，本项目应明确分离内容目录、运行时实体和玩家流程**。具体拆分由实际缺陷和当前 Gate 驱动，不将有限样本结论包装成所有 Godot 小项目的通用定理。
4. **资产许可必须与代码许可分开**。MIT/GPL 代码仓库可能使用 CC BY/CC0 资产；仓库可查看也不等于可复用。当前不直接引入 GPL 项目代码，也不把无许可证仓库当开源素材源。
5. **现成资源可明显提高占位和原型质量，但很少能直接成为本项目最终美术**。Ashen Tides 的 32×32 正交俯视、冷蓝深紫海潮主题和统一逐帧动画要求，决定了最终路线仍应是自制/委托；CC0/CC BY 包更适合功能底稿、UI/SFX 和风格参考。

## 2. 项目样本

研究快照（用于避免未来仓库变化覆盖本轮事实）：Quiver 旧仓 `1cbd622`、ape1121 模板 `cfdbf5e`、Defending Todot `275bf29`、Mindustry `c81d0eb`、Server Survival `0179636`、CPU Defense `ba62104`。本轮搜索过的 `prineside/Infinitode_2-Unfinished` 返回 404，未发现可信官方开源仓库，因此没有把第三方复刻、模组或疑似反编译仓当作参考源码。

### 2.1 Outpost Assault / Quiver（Godot 4）

- 仓库：<https://github.com/quiver-dev/tower-defense-tutorial>
- 旧模板：<https://github.com/quiver-dev/tower-defense-godot4>
- 代码：MIT；资产：CC BY 4.0（仓库单独 `LICENSE_ASSETS.txt`）。
- 定位：教学模板，不是完整战役产品。
- 结构：`entities/`、`maps/`、`ui/`；敌人使用 FSM，场景组合、typed signals、独立 spawner/objective/HUD。
- 玩家入口：`ui/main_menu.gd` 只做 Start/How-to/Quit；地图负责连接 objective、spawner、HUD 和经济事件。
- 可借鉴：
  - 实体场景组合，而非主控制器绘制所有单位；
  - 敌人状态机；
  - 地图只编排，不吞并实体行为；
  - 代码和资产许可证分离；
  - sprite 命名采用 `entity/action/frame`。
- 不照搬：NavigationServer 动态寻路、随机刷怪和单图 Demo 流程不适合本项目固定 PathNetwork、固定 tick 和 24 关战役。

### 2.2 Godot 4 Tower Defense Template / ape1121

- 当前仓库：<https://github.com/ape1121/Godot-4-Tower-Defense-Template>（原 `alpapaydin` URL 目前重定向至此）。
- 代码仓库：MIT。
- 定位：4 塔、2 地图、拖放建塔、升级/出售、简单菜单/HUD 的可扩展模板。
- 可借鉴：数据目录驱动塔/敌/地图；复用统一塔基类；菜单与战斗分场景。
- 不照搬：集中 `Data` autoload 字典适合 Demo，不适合本项目的稳定 ID、schema version、存档迁移和大量内容；背景图 + PathFollow2D 也不覆盖本项目分叉路线/相位机制。

### 2.3 Defending Todot（Godot 3）

- 仓库：<https://github.com/crystal-bit/defending-todot>
- 可玩构建：README 提供 HTML5、Windows/Linux/macOS。
- 代码：GPLv3；原创资产 CC BY；Kenney 子资产 CC0。
- 结构：`autoload/`、`resources/`、`scenes/`、`publishing/`、`docs/`，并把 Credits 纳入游戏。
- 可借鉴：
  - 把可发布构建、游戏内 Credits、贡献约定视为产品的一部分；
  - autoload 只保存跨场景服务；
  - 资源和场景分离；
  - 完整游戏至少要有可玩的外壳，而不只是战斗沙盒。
- 不直接复用：Godot 3 代码与当前 Godot 4.7 架构代际不同；GPLv3 代码会改变本项目许可选择，因此只学结构，不复制代码。

### 2.4 CPU Defense（仓库 `ochadenas/cpudefense`，完整 Android 塔防）

- 仓库：<https://github.com/ochadenas/cpudefense>
- 分发：F-Droid + GitHub Releases；代码 MIT。
- 完整度：32 个预制关卡、无尽模式、25+英雄、选关、设置、关卡编辑、持久化、多语言、发布元数据与截图。
- 架构证据：
  - `WelcomeActivity`、`LevelSelectActivity`、`GameActivity`、`SettingsActivity` 明确分离玩家流程；
  - `StageCatalog` 负责关卡目录，`Persistency` 负责进度，`GameMechanics` 负责规则；
  - `Stage`、`Wave`、`Hero`、`Marketplace` 作为领域对象；
  - `fastlane/metadata` 把发布文案、截图、变更记录纳入仓库。
- 最重要借鉴：**产品 shell 与 battle session 必须分离**。欢迎页/选关/设置/存档不是战斗脚本上的几个弹窗，而是稳定的产品层。
- 不照搬：Android Activity/View 架构不能机械移植到 Godot；应转换成 Godot scene/state/service 边界。

### 2.5 Mindustry（成熟开源塔防/RTS）

- 仓库：<https://github.com/Anuken/Mindustry>
- 代码：GPLv3；活跃发布、多平台构建、自动化测试、生成内容管线。
- 可借鉴：
  - 内容定义、实体系统、UI、平台启动器、工具链分模块；
  - 生成代码/图集由构建产生，不手改生成物；
  - 每次提交可生成 bleeding-edge build；
  - campaign/content/save/UI 都是独立系统而不是 `main` 的条件分支。
- 不照搬：其 ECS、网络、模组、多平台和规模远超单人小游戏，完整复制会产生过度工程；GPLv3 代码也不直接引入。

### 2.6 Server Survival

- 仓库：<https://github.com/pshenok/server-survival>
- 代码：MIT。
- 产品结构：Survival、25 关/5 章 Campaign、Sandbox 三种模式；每关都有目标、教学概念和 debrief。
- 可借鉴：章节/关卡不是文件序号，而是“简报 → 目标 → 规则变化 → 结算/复盘”的产品包；这正是当前项目需要重新补齐的玩家层。
- 不照搬：Web/Three.js 技术栈与云架构题材不同，只参考产品信息架构。

## 3. 对 Ashen Tides 的架构校准

### 3.1 保留的正确选择

- Godot 4.7、typed GDScript、稳定 ID 和 `.tres` 数据驱动；
- 固定 tick 60 Hz 与确定性报告；
- 固定 BuildNode + 预制 PathNetwork；
- Save/Settings/Audio/Localization 等跨场景服务；
- 数据校验、单元测试、smoke、suspend/perf 证据。

### 3.2 当前核心偏差

当前 `scripts/boot/main.gd` 同时承担启动、命令行测试、战斗编排、关卡加载、重开、结算、下一关、调试和部分存档恢复。它能支撑技术原型，但不适合完整产品继续扩展。此前两个 S1 都涉及 session 重建或产品流程状态交接，提示这一边界存在结构性风险；但不能仅据此断言所有问题都由主脚本职责集中直接造成。

### 3.3 目标边界（思想校准，不在本轮重构）

```text
App / Flow
  Boot → FirstRun → Title → Profile/Slot → Campaign → Briefing → Battle → Result

Services (autoload, no presentation)
  SaveService / SettingsService / AudioService / LocalizationService / ContentCatalog

Campaign domain
  progression / unlock rules / chapter & level catalog / selected hero / difficulty

Battle session
  BattleController / WaveDirector / PhaseController / BuildSystem / HeroSystem
  owns every mutable battle node; restart destroys/recreates or resets from one manifest

Data
  LevelData / WaveData / EnemyData / TowerData / HeroData / DeviceData

Presentation
  screens / HUD / dialogs / accessibility presentation / art library

Tools & tests
  validators / deterministic simulator / integration harness / asset checks
```

核心规则：

- Flow 决定“玩家在哪里”，Battle 只决定“这一局发生什么”；
- Campaign 决定解锁，不由结算面板推测；
- ContentCatalog 统一解析稳定 ID → 资源；
- restart 作用于一个 battle session，不能依赖散落节点自己恢复；
- CLI harness 和玩家 UI 调用同一应用服务，不在 `main.gd` 各走一套逻辑；
- 自动化证明 Integrated，端到端玩家脚本才能证明 Player-verified。

### 3.4 明确不采用

- 不引入 Mindustry 级 ECS/网络/模组架构；
- 不改为动态 A* 或允许堵路；
- 不用一个巨型全局 `Data` 字典替代 typed Resource；
- 不复制 GPL 项目源码到当前仓库；
- 不因为“开源”直接混入资产；
- 不为重构而重构：后续只沿当前 M2 Gate 的玩家纵向路径渐进拆分。

## 4. 开源资源候选

### 可直接进入候选池（仍须逐文件登记和视觉评审）

1. Kenney Tower Defense Top-Down — CC0：<https://kenney.nl/assets/tower-defense-top-down>。覆盖塔、道路、敌人、弹丸、粒子、HUD；适合功能原型，风格过亮，不是最终海潮视觉。
2. Kenney Pirate Pack — CC0：<https://kenney.nl/assets/pirate-pack>。适合船、码头、岛礁和海事小道具；仍需调色/重绘。
3. Kenney UI Audio — CC0：<https://kenney.nl/assets/ui-audio>。适合 UI 点击、切换和确认音；可直接列为高优先级正式候选。
4. LPC Ship — 优先选择 CC BY 4.0 路径：<https://opengameart.org/content/lpc-ship>。模块化帆船和动画火炮高度契合，但必须署名、记录修改且按多层拼装管理。
5. Godot Audio Effects Demo 中明确列出的 CC0 SFX：<https://github.com/godotengine/godot-demo-projects/tree/master/audio/audio_effects>。只复用 README 明确列名的 CC0 文件；代码为 MIT，音乐另为 CC BY 3.0。

### 仅参考，不直接进入最终资产

- LPC Base Assets：<https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles>。32×32 正交、四向和动作体系适合研究，但 CC BY-SA/GPL 与逐作者 attribution 成本较高，风格也偏明亮 RPG。
- LPC Animated Water：<https://opengameart.org/content/lpc-animated-water-and-waterfalls>。参考水边动画；存在 BY-SA 与历史对齐问题。
- Animated Ocean Tileset：<https://opengameart.org/content/animated-ocean-tileset>。32×32、10 帧岸浪适合作为节奏参考，最终建议自制。
- Kenney UI Pack：<https://kenney.nl/assets/ui-pack>。CC0，可做交互线框；通用卡通视觉不应成为最终潮汐仪器 UI。
- Godot RPG/Isometric demos：参考 TileSet、网格移动、排序和锚点；64×64 RPG 或 128×64 等距美术不适配本项目。

### 不采用

- 无许可证 GitHub 仓库：公开可看不等于允许使用。
- War on Water SFX：页面虽标 CC0，但逐文件来源链不足，不进入正式发行池。
- OpenGameArt 预览图中未随附件授权的第三方素材。
- 任何与 32×32 正交硬边像素路线冲突的等距、16×16混搭或 Spine 平滑素材。

## 5. 对现有规划的影响

- 不整体迁移任何外部项目；当前数据驱动与固定 tick 技术底座保留。
- `main.gd` 的巨型职责已被确认是结构性风险；应以 Flow/Campaign/BattleSession 边界渐进拆分，但拆分仍受当前 M2 Gate 驱动。
- 开源资源只进入 `Research/Proposed`；没有项目主理批准、逐文件许可证、hash、Credits 和上下文视觉评审，不进入 `Approved/Shipping`。
- 当前程序生成图片继续保持 `Integrated placeholder`；不会因为发现现成素材而自动替换。
- 完整性优先级从开源成熟项目得到再次验证：产品 shell、选关/存档、结算/复盘、发布构建和 Credits 都是游戏本体，不是最后再补的外围。

## 6. 事实限制

- 本轮没有下载或导入任何外部素材。
- GitHub 星数和活跃时间只用于选择样本，不作为架构质量证明。
- 部分资源页面未公开 ZIP 内像素尺寸/帧表；未下载核验前保持 Proposed，不能凭预览推断。
- 代码许可证和资产许可证始终分开处理；多许可证资产必须在台账中锁定实际采用路径。
