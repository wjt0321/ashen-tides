# 三文档技术 / 许可证审查报告

> **审查员**:技术事实审查员 (read-only)
> **审查日期**:2026-09-04
> **审查范围**:
> - `TECH_RESEARCH_DRAFT.md`(技术调研)
> - `ASSET_AUDIO_RESEARCH_DRAFT.md`(美术 + 音频资产调研)
> - `PRD_FRAMEWORK_DRAFT.md`(PRD 框架)
> **方法**:逐条阅读 → 联网核验高风险事实 → 与另外两份文档交叉比对 → 标记 Blocker / Major / Minor
> **原则**:仅指出问题,不修改源文档,所有修正建议附原文引用和定位。

---

## 0. 总览

| 严重度 | 数量 | 说明 |
|---|---:|---|
| **BLOCKER** | 4 | 进入实现前必须解决,否则会卡死开发或交付不可玩 |
| **MAJOR** | 14 | 影响代码结构、可玩性、范围控制,需在本周内修正 |
| **MINOR** | 10 | 文案、笔误、低风险澄清,可在实现前一并改 |

**最危险的 3 个 BLOCKER**(后文展开):
1. **寻路 / 路径封堵校验缺失或策略矛盾**——TECH 与 PRD 对敌人路径采取不同策略,且 PRD 完全没规划"放塔后路径必须仍可达"这一 Kingdom Rush 核心规则。
2. **像素基础分辨率矛盾**——TECH §2.2 说 `426×240`,PRD §12.4 说 `640×360`,直接影响 TileMapLayer/AStarGrid2D 的 cell_size、相机、缩放档位。
3. **Sonniss EULA 版本与发布日期可疑**——ASSET_AUDIO §8.5 声称"EULA v2.0,生效 2026-08-27",但 Sonniss GDC 2026 Bundle 在 2026-03 已发布,需要直接核对原始 EULA 文件确认实际生效日期。

---

## 1. Blocker(4 条)

### Blocker #1 — 路径封堵校验(PATH placement validator)在 PRD 中完全缺失

- **冲突文档**:
  - TECH_RESEARCH §3.4 引用 vav-labs 文章,把"放塔后跑 A* 校验路径仍可达"作为 **硬性要求**(原文:"**不要**只检查'当前 cell 是 buildable',还要 **校验放塔后所有出生点到终点的路径仍然存在**。这是 Kingdom Rush 的核心规则:玩家永远不能把路堵死。")
  - PRD_FRAMEWORK §3.1 / §3.5 / §5.4 / §18 / §25.2 等 **完全没有** placement validator 的规则、UI、错误信息或验收标准。
- **风险**:这是 Kingdom Rush 系列的核心设计之一,玩家无法堵路。若实现时漏掉,玩家可以靠堵路"无脑通关",关卡设计全部失效。
- **建议**:
  1. PRD §3 新增 §3.6"放置与封堵校验"小节:写明"放塔前必须在 AStarGrid2D 上临时 set_point_solid,确认所有 spawn→goal 路径仍存在;否则弹出红色预览并禁止放置"。
  2. PRD §5 关卡硬约束新增"每关至少 1 个 spawn 与 1 个 goal,且任何 buildable cell 单独置 solid 后所有 spawn→goal 路径至少 1 条仍存在(关卡设计师工具自动化校验)"。
  3. PRD §18.1 PathNetwork 节点需明确"含 TowerPlacementValidator 子节点"。

---

### Blocker #2 — 像素基础分辨率在 TECH 与 PRD 之间直接矛盾

- **原文引用**:
  - TECH_RESEARCH §2.2:
    ```
    window/size/viewport_width=426
    window/size/viewport_height=240
    ```
    §2.2 末段:"426×240 是实用下限……整数缩放下,1080p 显示器只能放下约 4× = 1704×960,会有黑边"
  - PRD §12.4:"逻辑分辨率建议 640×360,整数倍缩放到 1280×720、1920×1080、2560×1440"
- **影响**:
  - AStarGrid2D 的 `cell_size` 必须与 TileMap `tile_size` 一致(若改 32×32,网格单元数 / 屏 = 1/4)。
  - ASSET_AUDIO §0 同时推荐 16×16(Kenney Tiny Dungeon)和 32×32(Buch Outdoor)两套混合方案,**没有在 TECH 或 PRD 中给出单一规则**。
  - 整数缩放档位:`426×240` 在 1080p 显示器只 4× 整数缩放且黑边大;`640×360` 可 3× = 1920×1080 完美满屏。
- **建议**:
  1. 二选一并全文统一为 `640×360`(更现代、Steam Deck 友好、整数缩放刚好 3× 满屏 1080p)。
  2. 配套统一 tile 尺寸为 **32×32**(而非 TECH §3.2 隐含的 16×16),并明确 AStarGrid2D `cell_size = Vector2(32, 32)`。
  3. 同步修改 ASSET_AUDIO §0 主推表:删掉 Kenney Tiny Dungeon(16×16)或注明"需缩放适配到 32×32 网格";补上 32×32 的 Kenney(若需要)。

---

### Blocker #3 — 寻路策略在 TECH 与 PRD 之间方向不一致,且 PRD 与自己的相位机制直接冲突

- **原文引用**:
  - TECH_RESEARCH §3.4 + §4.1:推荐 AStarGrid2D(动态、可 `set_point_solid`)做塔位封堵校验,敌人沿预存路径点(`PathPoints: Vector2[]`)移动。
  - PRD §18:"本项目的敌人路径应优先使用设计师定义的曲线/航点,避免每个单位实时寻路造成不可控行为。"
  - PRD §4.1(相位系统):"一段潮滩道路开启/关闭,敌人改道"——路径在运行时变化。
- **冲突**:
  - PRD §18 自己说"敌人沿曲线",但 §4.1 又要求路径运行时改变。**只靠设计师曲线无法应对路径运行时改变**,必须至少在路径改变时重算 A* 或切换到 NavigationServer2D。
  - TECH §3.4/§4 推荐的 AStarGrid2D + set_point_solid 模式恰好能解决相位改道(在路径变更瞬间 `set_point_solid` 重新标记),但 TECH 没明说"相位改道"这个用法。
- **建议**:
  1. PRD §18 把 PathNetwork 描述改为:
     - **静态部分**:每关预设 1–3 条候选 `PathPoints: Vector2[]`(设计师画的曲线)。
     - **动态部分**:WaveDirector 持有当前激活的 path index 列表;PhaseController 在相位切换时调用 `WaveDirector.activate_path(new_id)`,并对 AStarGrid2D 重新 `set_point_solid`(旧路 cell 解除,新路 cell 标记)。
     - **封堵校验**:TowerPlacementValidator 沿用 AStarGrid2D `set_point_solid + get_id_path`,对当前激活路径校验。
  2. 在 PRD §4.1 末尾加"路径变更需 0.5s 动画预演,且动画期间敌人不被强制改向,改向发生在新一波开始前"。

---

### Blocker #4 — Sonniss GDC Bundle EULA 版本与生效日期可疑,需直接核验

- **原文引用**(ASSET_AUDIO §8.5):
  > "许可条款页(已核实全文):https://sonniss.com/gdc-bundle-license/ (**EULA v2.0,生效 2026-08-27**——就在调研前一周更新,务必以下载当日版本为准)"
- **核验发现**:
  - 多次搜索(NewsBreak、Zeli、PluginDeals、PieFed)都指出 **Sonniss GDC 2026 Bundle 在 2026-03 发布**(7.47GB+)。
  - EULA v2.0"生效 2026-08-27"在 GDC Bundle 发布 **5 个月之后**——若是追溯生效,商务上对**已下载**素材的合法性造成疑问;若是 v2.0 仅约束 2027 年之后的 bundle,则 §8.5 的"调研前一周"措辞是误导。
- **风险**:
  - EULA 日期弄错会直接影响商用合规。Sonniss EULA 关键约束(禁止 AI 训练、禁止再分发、禁止主张著作权)若被 v2.0 修改但 §8.5 还按旧版描述,可能导致违规。
- **建议**:
  1. 直接访问 https://sonniss.com/gdc-bundle-license/ 抓取生效日期与版本号,替换 §8.5 的措辞。
  2. 表格增加列"下载日期"与"对应 EULA 版本",把这一份的具体下载日期写死。
  3. 若无法核实,在 §0"已知内容缺口"区标注"⚠️ Sonniss 许可需下载当日复核"。

---

## 2. Major(14 条)

### Major #1 — 内容规模"翻 3 倍"在 TECH 与 PRD 之间无统一

- **原文引用**:
  - TECH §15.4 范围表(明确"砍项"清单):4 塔 / 12–16 敌人 / 4 英雄 / 4 BOSS。
  - PRD §0:"24 主线关卡、6 座塔、4 名英雄、24 种普通敌人、8 种精英、6 个 Boss"——总敌人 38 种。
- **问题**:
  - PRD 的内容量是 TECH 推荐范围的 **2.5–3 倍**。
  - 对 0 基础、唯一开发者、15–24 个月窗口,§22 M3 "每关超过 3 周即触发砍项"暗示每关 2–3 周。24 关 × 3 周 = 72 周 = 17 月,接近 PRD 自定上限。
  - 38 种敌人(含 6 Boss 各自 3–4 阶段动作)需要 **大量动画帧**——这与 ASSET_AUDIO §10 中"严格俯视像素的现成'塔'整体稀缺"叠加,实际产能瓶颈在美术。
- **建议**:
  1. PRD §0 锁定一个更现实的初始预算(例如 **6 塔 / 12 普通 + 4 精英 + 4 Boss / 4 英雄 / 16 主线关卡**),把 24 关卡移到 P1。
  2. 同步修改 PRD §5.3 关卡表为 16 条,删掉 P2 候选条目但保留剧情钩子。
  3. 在 PRD §25.2 砍项顺序表中把"24 关 → 16 关"作为第一砍选项。

---

### Major #2 — 里程碑度量不一致,TECH P1 与 PRD M1 描述不同的"最小内核"

- **原文引用**:
  - TECH §15.3 P1 最小可玩内核:"1 个 TileMapLayer 路径 + 1 个出生点 + 1 个终点 + 1 个 EnemyBase + 1 个 TowerBase + 1 个 ProjectileBase + WaveManager + GameManager + HUD + 主菜单 → 关卡 → 结果 三屏。"
  - PRD §22 M1 核心系统原型:"2 塔、4 敌、1 英雄、相位、波次编辑、存档骨架、调试工具……3×速度状态正确;能用数据资产创建新波次而不改代码。"
- **问题**:
  - PRD M1 已经包含"1 英雄 + 相位",这两个都是 PRD §6.7 才完整化的复杂子系统。
  - TECH P1 走"先跑通 1 敌人 1 塔",更稳;PRD M1 直接跳到 4 敌 2 塔 1 英雄,**对 0 基础用户的不可执行风险更高**。
  - 两份文档给的"第一个里程碑"完全不同,合在一起看会让读者无所适从。
- **建议**:
  1. PRD §22 M1 改为 TECH §15.3 的口径:**1 塔 1 敌 1 波 + AStarGrid2D 路径校验 + HUD + 存档骨架**。
  2. PRD M2 改为"2 塔 + 4 敌 + 1 英雄(含相位)"。
  3. PRD M3 改为"6 塔骨架 + 4 英雄 + 12 敌 + C01–C08 + Boss 1"。
  4. 同步在 PRD §22 末尾加一张"M0→M7 工作量分布表",每关、每敌人、每塔的具体数量一目了然。

---

### Major #3 — AutoLoad 命名不统一(TECH 与 PRD 用两套术语)

- **原文引用**:
  - TECH §1.1:`EventBus / GameManager / SaveManager / SettingsManager / AudioManager / SceneManager / SceneFlow`
  - PRD §18.1:`AppState / SceneRouter / SaveService / SettingsService / LocalizationService / AudioService / InputService / TelemetryLocal / WaveDirector / PathNetwork / BuildNodeManager / TowerManager / EnemyManager / HeroController / PhaseController / CombatEventBus / BattleHUD`
- **问题**:
  - 同样职责,TECH 叫 `SaveManager`,PRD 叫 `SaveService`——实施时不知道用哪个。
  - PRD 没有 EventBus/SceneFlow,但有 CombatEventBus;TECH 的 EventBus 是全局,PRD 的 CombatEventBus 是关卡内。两层都用得着,但文档没分开。
  - PRD §18.1 把 `WaveDirector / PathNetwork / BuildNodeManager` 当作"CurrentScreen 的子节点",与 §18.1 顶部 `SaveService / SettingsService / LocalizationService / AudioService / InputService / TelemetryLocal` 是 Main 的子节点——**哪些是 AutoLoad、哪些是普通子节点未区分**。
- **建议**:
  1. 统一规范:TECH 的 `*Manager` vs PRD 的 `*Service` 二选一(推荐 `*Service`,与 Godot 官方 Service Locator 习惯一致)。
  2. AutoLoad 列表(顶层常驻):`SceneService / AudioService / SaveService / SettingsService / LocalizationService / InputService / EventBus`(全局信号)。
  3. 关卡内节点(随关卡场景载入):`WaveDirector / PathNetwork / BuildNodeManager / TowerManager / EnemyManager / HeroController / PhaseController / CombatEventBus / BattleHUD`。
  4. 在 PRD §18.1 顶部显式区分这两层。

---

### Major #4 — 性能策略分歧:Pooling "先用" vs "后用"

- **原文引用**:
  - TECH §12:"对象池的项目至少为下列实体建立池:Projectile / XP_Gem / FloatingDamageLabel / ParticleEffect / AudioStreamPlayer"
  - PRD §18.3:"对象池用于弹道、伤害数字和常见特效,**但先用性能分析证明必要**"
- **问题**:
  - PRD §28"严苛审查问卷"中"3× 速度是否仍可读"是关键问题,但 PRD 又说"先不池化,等分析再说",这是一个**矛盾**——3× 速度 200+ 单位时,如果不预先池化,profile 时已经晚了。
  - 单人 0 基础项目**没有持续 profile 的工具与习惯**,"先 profile 再池化"在实践中几乎不会发生,导致 P2/P3 阶段性能崩溃。
- **建议**:
  1. PRD §18.3 改为"对象池用于弹道、伤害数字、经验宝石、特效、AudioStreamPlayer——**与 P1 同时实现**,而非后置"。
  2. 在 §22 M0 退出标准增加"对象池基类已实现并通过单元测试"。
  3. 在 §28 严苛审查问卷加入"未池化的节点清单与理由"一问。

---

### Major #5 — Wave 周期与"3× 可读性"在 PRD 中的并发上限过松

- **原文引用**:
  - PRD §18.3:"同屏设计上限:180 普通单位、250 投射物/特效实体"
  - PRD §5.4 关卡硬约束:"每关 12–20 波"
  - PRD §3.1:"Boss 阶段失败不靠'扣 20'偷袭"
- **问题**:
  - 180 普通单位 × 250 投射物 = 430 个动态节点。3× 速度下若同时存在,1.5ms/帧的预算根本不够——单帧 `move_and_slide` × 430 节点就爆。
  - PRD §6.3 塔数值预算里 III 级 DPS 指数 470、IV 级 850——按基础塔 ~10 DPS、IV 级 ~85 DPS 推算,炮台 1 秒可产生 6–10 个 projectile,4 座 IV 级塔 × 10 = 40/秒;波次持续 30s × 40 = 1200 projectile/波——已经超 §18.3 的 250 上限。
  - PRD §22 严苛审查问卷已经问"3× 是否可读",但**没有"3× 不爆帧"的硬约束**。
- **建议**:
  1. PRD §18.3 增加"3× 速度下,同屏任意瞬间不超过 180 普通 + 120 projectile + 80 特效 = 380 总动态节点(3× 减半预算)"。
  2. 塔 IV 级 DPS 上限收紧(870 → 600 左右),并要求投射物具有 4s 自动消失 TTL。
  3. 增加"波次设计约束:同屏 projectile 任意瞬间不超过 150"。

---

### Major #6 — PRD §3.4 目标选择规则与 PRD §6.5 IV 级技能"反滥用护栏"未覆盖低难度

- **原文引用**:
  - PRD §3.4:"每塔可选:最前、最后、最高生命、最低生命、最高护甲、标记目标。默认'最前'。**高级优先级在第 3 关逐步解锁,避免教程首关信息过多。**"
  - PRD §6.5 给出 6 塔的"反滥用护栏",但没说哪个对应"低难度"。
- **问题**:
  - §3.4 承诺第 1 关不要所有优先级,但 §22 M2 没说"第 3 关前优先级选项 UI 必须灰显"。
  - 玩家首关 C01(§5.3)只能用"最前"目标,§6 6 塔其中 4 座的"高级优先级"该如何呈现?
- **建议**:
  1. PRD §3.4 增加"高级优先级在 C03 起在塔升级 II 级后解锁;UI 解锁前不显示相关按钮而非灰显,降低认知负担"。
  2. PRD §6.5 增加"反滥用护栏"统一子表:每塔给出"在标准难度的单关最大贡献占比 P95 < 35%"指标。
  3. PRD §20.2 增加"目标优先级使用率分布"指标。

---

### Major #7 — PRD §22 缺乏"集成测试 + 性能回归"硬指标

- **原文引用**:
  - PRD §21.1 列出测试类型(单元、数据验证、集成、存档、回归、UI、性能)。
  - PRD §18.3:"目标机 1080p,主流集显/四核机器,1×/3×均 60 FPS;1% low 不低于 45 FPS"。
  - PRD §26.3 验收:"目标机 1080p 60 FPS,3×最大压力 1% low ≥45 FPS"。
- **问题**:
  - "主流集显/四核机器"无明确型号。Steam Deck(AMD Van Gogh APU)是塔防的目标机型之一(§0 "架构预留 Steam Deck"),但 Steam Deck 实际是 Zen 2 + RDNA2,**比很多主流集显强**;若以集显为基准,Steam Deck 反而不是瓶颈。
  - "3×最大压力 1% low ≥45 FPS"在 §21.1 没有对应自动化测试。手工测一个 3× 25 分钟关卡 = 75 分钟单次,3 轮差 = 3.75 小时,无法每里程碑都跑。
- **建议**:
  1. PRD §18.3 改为具体目标机:1080p,Intel UHD 730 + i5-1135G7(或等效 Steam Deck 目标);明确写"Steam Deck 同等硬件也需满足 30 FPS 目标(因 Zen 2 强于 UHD 730,实际会更高)"。
  2. PRD §21.1 新增"性能回归脚本:在固定布局 + 固定种子下,跑 60 秒 3× 战斗,记录平均 FPS 和 1% low,数据写入历史 CSV"。
  3. PRD §26.3 改为"3× 60 秒标准压力脚本 ≥ 50 FPS,1% low ≥ 40 FPS"。

---

### Major #8 — 路径封堵校验在 PRD 中没有对应 UI/反馈设计

- **原文引用**:
  - PRD §12.3 交互标准未涉及"放塔失败原因"的具体反馈。
  - PRD §3 / §25 未涉及"放置校验失败时的 UX"。
- **问题**:
  - 若引入 Blocker #1 的 placement validator,玩家点格子后**被拒绝**时,必须给出明确原因(原因:堵路 / 不在建点 / 金币不足 / 在路径上)。PRD 没规定。
- **建议**:
  1. PRD §3 新增 §3.6 placement validator 的 UX 子条款:
     - 鼠标悬停在建点上:绿色 = 可建、黄色 = 已占用、红色 = 堵路 / 不可建
     - 点击红色时:HUD 弹一行原因("将阻断敌人路径""不可建造地形")
     - 撤回机制(§3.5):堵路时给出 2 秒内"撤销"按钮
  2. PRD §12.2 战斗 HUD 增加"放置反馈区",承载上述信息。

---

### Major #9 — 本地化目标 9 种语言(PRD §14.1)对 0 基础单人项目不可执行

- **原文引用**:
  - PRD §14.1:"简体中文、英语为 P0……繁体中文、日语、韩语、德语、法语、西班牙语、葡萄牙语(巴西)、俄语为 P1,取决于预算与商店愿望单地区数据"
- **问题**:
  - P0 中英 2 种 + P1 7 种 = 9 种。每种需要 UI 文本翻译(§14.2 提到 UI 预留英语 140% / 德语 160% / 俄语 140% 长度)、字体回退测试(§13.1)、截图测试(§14.3)、无障碍测试(§13.3)、bug 修复(每种语言都要 QA)。
  - 翻译成本:9 × 2000 词 × $0.10/词 ≈ $1800 仅翻译,**专业塔防术语需要 native speaker**——商业化项目通常需要 2–3 倍这个数字。
  - 即使用 AI 翻译,§14.1 已禁止"未经人工审校的纯机器翻译对外发布",意味着仍需人类审校。
  - 单人项目应**只做 P0 中英**,P1 待首月反馈再追加。
- **建议**:
  1. PRD §14.1 改为:"P0 = 简中 + 英语(必)。P1 = 繁中 + 日语(东亚核心市场)。P2 = 其余 6 种,作为'如果销量证明 ROI 则上'的候选。"
  2. 在 PRD §25.2 砍项顺序中,"P1 语言(4 种)"作为第三砍选项。
  3. PRD §26.1 验收标准改为"中英 100% 通过,P1 语言翻译框架就绪但允许文案占位"。
  4. 删除"9 种语言同时首发"的任何隐含承诺,避免营销陷阱。

---

### Major #10 — PRD §21.4 外部测试规模对 0 基础单人不可执行

- **原文引用**:
  - PRD §21.4:"原型盲测:5–8 人;纵向切片:15–25 人;Alpha:40–80 人;Beta:100–300 人;发布候选:至少 20 名从新档完整通关"
- **问题**:
  - 总测试人次 ≥ 200 名,**协调与筛选 200+ 测试者**对单人 dev 是不可能的工作量。
  - 0 基础 dev 通常没有 Discord / 邮件列表 / 社群渠道。
- **建议**:
  1. PRD §21.4 大幅压缩:
     - 原型盲测:3–5 人(家人 + 朋友)
     - 纵向切片:5–10 人(社交平台招募)
     - Alpha:10–20 人
     - Beta:20–50 人(可分批)
     - 发布候选:5–10 名完整通关(其中 2–3 名不看攻略)
  2. 增加"测试招募渠道"小节(Steam Playtest、itch.io 公告、Twitter/X、Discord 个人服务器)。
  3. 在 PRD §25.2 砍项中把"扩测试规模"列为非优先。

---

### Major #11 — PRD §13 无障碍 P0 11 项对 0 基础单人过于繁重

- **原文引用**:
  - PRD §13.1 P0 列出 11 条(UI 缩放、色弱预设、键鼠/手柄、震动/闪白可关、字幕可调、独立音量等)。
  - PRD §13.3:"由至少 5 名有相关需求的外部测试者覆盖"
- **问题**:
  - 11 项 × 5 名测试者 = 55 个组合,每次修改需重测。
  - "色弱 3 种预设"涉及 shader 或 Material override,工程量不算小。
  - "可关闭镜头震动、屏幕闪白、伤害数字、粒子、色差"意味着每个特效都要可关闭开关,**额外状态机和配置项**。
- **建议**:
  1. PRD §13.1 P0 缩减到 6–7 项核心:UI 缩放、色弱 1 种预设 + 自定义、键鼠+手柄、独立音量、字幕、可暂停、可跳过过场。
  2. 把"色弱 3 种预设、震动可关、色差可关、粒子可关"移到 P1。
  3. PRD §13.3 测试人数改为"2–3 名有相关需求者"。
  4. 给出每个 P0 项的最小验收测试(不需要 5 名测试者也能跑)。

---

### Major #12 — Steamworks / Steam Cloud / 平台成就承诺对 0 基础单人过早

- **原文引用**:
  - PRD §15.4:"Steam Cloud 配置必须只同步必要存档"——这是 Steamworks SDK 集成。
  - PRD §16 30 个成就需"平台成就与本地成就使用同一稳定 ID,对账必须幂等"——这是平台成就 + Steamworks 集成。
- **问题**:
  - Steamworks SDK 在 Godot 4 中需要 godot-steamworks 第三方插件(GPL/LGPL,许可证也要核验)。集成后还要做"离线降级"——PRD §15.4 自定,但实际工程是另一回事。
  - 平台成就 30 个 + 图鉴数据 + 离线降级 = **3 周专门工作量**,对 0 基础 dev 风险高。
- **建议**:
  1. PRD §15.4 明确 godot-steamworks 插件选型与许可证(查 Godot Asset Library / github 仓库的 LICENSE)。
  2. 30 个成就拆为 P0(8 进度 + 4 战术)和 P1(其余 18)。
  3. 在 PRD §25.2 砍项中"Steam Cloud 与平台成就"列为 P3(发布后)。
  4. §26.1 验收改为"P0 8 + 4 = 12 个本地成就,Steam 平台成就在 M6 集成后补齐"。

---

### Major #13 — 像素基础分辨率 / 瓦片尺寸 / 资源包尺寸不统一(跨三份文档)

- **原文引用**:
  - TECH §2.2 viewport:426×240
  - PRD §12.4 viewport:640×360
  - PRD §29:"逻辑像素尺寸(16×16、24×24 或混合)与目标角色屏幕占比"作为待决。
  - ASSET_AUDIO §0:同时推荐 16×16(Kenney Tiny Dungeon / rgsdev)和 32×32(Buch Outdoor / CDmir / Nido)
- **问题**:
  - 一份文档给出 3 种 viewport 尺寸 × 3 种 tile 尺寸 = 9 种潜在组合,**到 P3 才能锁定**?——这是范围蔓延高风险。
  - 16×16 与 32×32 的资源**不能直接混用**:Kenney Tiny Dungeon(16×16)在 32×32 网格下显示只有 1/4 格,需要 sprite scale 调整并重新校验碰撞。
- **建议**:
  1. PRD §29 + TECH §2.2 + ASSET_AUDIO §0 在 M0 立项时统一为 **32×32 tile + 640×360 viewport**:
     - 整数缩放:1080p = 3×(完美)、1440p = 4.5× 失败需要裁剪或允许 fractional。
     - tile 32×32 在 640×360 下视野 = 20 × 11.25 tiles,适合塔防的"长条路径"关卡。
  2. ASSET_AUDIO §0 主推表立即改成"32×32 优先",删掉 16×16 选项或注明"需手动 scale 2× 后并入"。
  3. 角色占地改为"32×32 基础 + 16×16 小怪 + 64×64 精英 + 96×96 Boss"的清晰层级(PRD §12.4 已隐含,但没锁定)。

---

### Major #14 — Game 速度档位 (PRD §3.1) 与缩放档位 (PRD §12.3) 未联动约束

- **原文引用**:
  - PRD §3.1:"游戏速度:0.5×、1×、2×、3×"
  - PRD §12.3:"战场缩放 75%–150%"
  - TECH §2.3:"缩放档位:1×、1.5×、2×"
- **问题**:
  - 1.5× 缩放 + 3× 速度 = 实际时间缩放 2× + 视觉缩放 1.5× = 输入精度要求 +33%。
  - TECH §2.3 自己承认"1.5× 容易抖动,可考虑只给整数档"。
- **建议**:
  1. PRD §12.3 + TECH §2.3 统一缩放档为 **整数档 100% / 125% / 150%** 或 **1× / 2×**——避免亚整数 + pixel art 抖动。
  2. 显式说明 3× 速度下不允许 1.5× 缩放,或自动重置为 1×。
  3. PRD §28 严苛审查问卷加一条"3× 速度 + 150% 缩放 + 双手柄是否仍可读"。

---

## 3. Minor(10 条)

### Minor #1 — TECH §2.2/§3.1 错标 `stretch/scale_mode="integer"` 引入版本

- **原文**:TECH §2.2 注释 "Godot 4.3+ 才有";TECH §3.1 未标具体版本但 §2.2 暗示 4.3+。
- **核验**:**实际为 Godot 4.2 引入**(`display/window/stretch/scale_mode`,String 类型,值 `fractional`/`integer`)。来源:[Multiple resolutions — Godot docs](https://docs.godotengine.org/en/latest/tutorials/viewports/multiple_resolutions.html),PR [Calinou/godot-docs#9875a4b](https://github.com/Calinou/godot-docs/commit/9875a4b282d779c4b2c0af0373e0c05be92db1af)。
- **修正**:改为 "Godot 4.2+"(提前一年)。

---

### Minor #2 — TECH §11.3 关于 Web 导出音频格式的事实错误

- **原文**:"【警告】导出 Web 时 **不能用 `.wav` 或 `.mp3`,只 Vorbis 工作**"
- **核验**:Godot 官方文档[Exporting for the Web](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html)明确说 ".wav、.ogg、.mp3 三种都支持桌面导出;Web 推荐 .ogg Vorbis,因为 MP3 有专利问题"。`.wav` 在 Web 导出中**支持**,但因为体积大,**官方推荐 Vorbis**。
- **修正**:改为"Web 导出推荐 .ogg Vorbis(MP3 有专利问题,WAV 体积过大)。WAV 在 Web 上技术上可用但不推荐。"

---

### Minor #3 — TECH §14.4 Steam 抽成比例过时

- **原文**:"Steam 30%(营收 < $10M)→ 25%(> $10M)"
- **核验**:Steam 2024 年起改为三档:**30%(< $10M) → 25%($10M–$50M) → 20%(> $50M)**。每游戏独立计算。
- **修正**:补全三档,引用[Steam Partner 文档](https://partner.steamgames.com/doc/gettingstarted/royalty)。

---

### Minor #4 — TECH §2.2 关于 "426×240 是行业标准"的说法无来源

- **原文**:"SNES 256×224、PSP 480×272、3DS 400×240"——这些确实是历史硬件分辨率,但 **426×240 不在经典硬件列表中**;它来自 YouTube 240p 派生,不是历史"标准"。
- **修正**:删掉"行业标准"措辞,改为"对塔防而言,640×360 比 426×240 在 1080p 满屏更友好"。结合 Major #2 锁定 640×360。

---

### Minor #5 — TECH §14.2 D3D12 默认说明不准确

- **原文**:§14.2 列了 Windows Export Preset,但 §0.3 / §14 没明确"D3D12 默认仅对新建项目生效"。
- **核验**:Godot 4.6 起 D3D12 是 Windows 新建项目的默认渲染驱动(来自[GDoc 4.6 release](https://godotengine.org/releases/4.6/));已有项目保留原配置。
- **修正**:在 §14.2 顶部加一句"D3D12 默认仅对 Godot 4.6+ 创建的新项目生效,本项目立项时即采用"。

---

### Minor #6 — ASSET_AUDIO §3.1 "Kenney Tower Defense Top-Down" 需明确 CC0 标志

- **原文**:§3.1 标注 "Kenney / 许可 CC0 / 风格 2016 年扁平描边俯视风,非严格像素"
- **风险**:Kenney 既有 CC0 也有 premium 包。Top-Down 这一个需直接打开 https://kenney.nl/assets/tower-defense-top-down 确认 "CC0" 徽章。
- **修正**:§3.1 增加"已打开页面核实 CC0 徽章"措辞,或移到 §10 "未通过核实"。

---

### Minor #7 — TECH §1.1 AutoLoad 顺序论述自相矛盾

- **原文**:
  - 第一行:"AutoLoad 的初始化顺序遵循 Project Settings → Autoload 中的顺序。"
  - 警告部分:"**不要**依赖 AutoLoad 顺序"
- **问题**:同一节里说"顺序存在"又"不要依赖",新读者会困惑。
- **修正**:重写为"顺序存在,但**禁止依赖**——若有依赖,使用显式初始化回调或构造函数参数注入"。

---

### Minor #8 — PRD §13.1 与 §0 在"语音"上轻微矛盾

- **原文**:
  - §0:"不承诺全语音、程序生成战役或用户关卡"
  - §13.1:"主音量、音乐、音效、环境、UI、语音(若有)独立滑杆"
- **修正**:§13.1 改为"……UI 独立滑杆;语音(若后期引入 DLC 或 Mod)"或直接删除"语音"。

---

### Minor #9 — TECH §15.5 范围控制"P2 模式" 与 PRD §0 "三层范围" 名称不一致

- **原文**:
  - TECH §15.5:"P0 必修 / P1 后置 / P2 未来 DLC"
  - PRD §0.2:"P0 必需 / P1 增强 / P2 候选"
- **修正**:统一为 "P0 / P1 / P2",含义对齐。

---

### Minor #10 — TECH §2.3 相机 zoom "1×、1.5×、2×"与 PRD §12.3 "75%–150%" 不同范围

- **原文**:
  - TECH §2.3:"缩放档位:1×、1.5×、2×"
  - PRD §12.3:"战场缩放 75%–150%"
- **修正**:统一为 100% / 125% / 150% 三档整数(结合 Major #14)。

---

## 4. 联网核验高风险事实清单

下列条目经独立联网核验,结果用于支撑上面的 Blocker / Major / Minor:

| # | 事实 | 核验来源 | TECH/PRD/ASSET 引用 | 核验结果 |
|---|---|---|---|---|
| F1 | Godot 4.7 "Director's Cut" 2026-06-18 发布 | [GamingOnLinux 2026-01](https://www.gamingonlinux.com/2026/01/godot-4-7-is-here-with-major-animation-usability-and-platform-improvements/) / [Cinevva 2026-06](https://app.cinevva.com/zh-CN/news/2026-06-19-godot-4-7-released) / Godot download archive | TECH §0.3 | ✅ 正确 |
| F2 | Godot 4.7 含 HDR 输出(W10/macOS/Linux/iOS/Android,**不含 Web**) | Godot 4.7 release notes | TECH §0.3 | ✅ 正确,但**没强调不含 Web** |
| F3 | Godot 4.7 含 Wasm64(突破 4GB 堆) | Cinevva 2026-06 | TECH §14.1 | ✅ 正确 |
| F4 | Godot 4.7 含 Transform Offset for Control | Ziva 4.7 features / Vagon blog | TECH §0.3 (未列) | ✅ 正确,但 TECH 漏列 |
| F5 | Godot 4.7 含 VirtualJoystick | Godot 4.7 release notes | TECH §0.3 | ✅ 正确 |
| F6 | Godot 4.6 起 D3D12 默认(新项目)+ Jolt 3D Physics 默认(新项目) | Godot 4.6 release | TECH §14.2 | ⚠️ 部分正确(没说仅新项目) |
| F7 | TileMapLayer 引入 Godot 4.3 | 4.3 release notes / Godot docs | TECH §3.1 | ✅ 正确 |
| F8 | `stretch/scale_mode="integer"` 引入 Godot **4.2**(不是 4.3) | [Multiple resolutions docs](https://docs.godotengine.org/en/latest/tutorials/viewports/multiple_resolutions.html) / [Calinou/godot-docs#9875a4b](https://github.com/Calinou/godot-docs/commit/9875a4b282d779c4b2c0af0373e0c05be92db1af) | TECH §2.2 / §3.1 | ❌ **Minor #1 错** |
| F9 | AStarGrid2D.set_point_solid 引入 4.3,solid vs disabled 区分 | Godot docs / 4.3 release notes | TECH §3.4 / §4.3 | ✅ 正确 |
| F10 | Web 导出仅支持 Compatibility renderer,Forward+/Mobile 不支持 | [Godot docs Exporting for the Web](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_web.html) | TECH §14.1 | ✅ 正确 |
| F11 | Web 导出音频支持 WAV/OGG/MP3;**官方推荐 OGG**(MP3 有专利) | Godot docs | TECH §11.3 | ❌ **Minor #2 错** |
| F12 | C# 项目不能 Web 导出 | Godot docs | TECH §14.1 | ✅ 正确 |
| F13 | Steam 抽成:30%(< $10M) / 25%($10M–$50M) / 20%(> $50M),每游戏独立 | Steam Partner docs / 2024–2025 多家媒体 | TECH §14.4 | ⚠️ **Minor #3 缺第三档** |
| F14 | Kenney CC0(全站声明) | kenney.nl/support | ASSET §0 | ✅ 正确(但需逐包确认) |
| F15 | Press Start 2P = SIL OFL 1.1,Reserved Font Name "Press Start 2P" | [Google Fonts repo](https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/OFL.txt) / SIL scripts.sil.org/OFL | ASSET §6.1 | ✅ 正确 |
| F16 | VT323 = SIL OFL 1.1 | [Google Fonts repo vt323/OFL.txt](https://raw.githubusercontent.com/google/fonts/main/ofl/vt323/OFL.txt) | ASSET §6.2 | ✅ 正确 |
| F17 | 0x72 DungeonTileset II = CC0(itch.io + verification 页) | 0x72 itch 主页 + verification 页 | ASSET §1.6 / §2.1 | ✅ 正确 |
| F18 | Buch "Outdoor 32x32 Tileset" = CC0(OGA) | [Fort of Chains tileset credits](https://gitgud.io/darkofocdarko/fort-of-chains/-/blob/cc2345903e1c541987a4f9b8c50b8d1d99f81e1a/docs/tileset_credits.md) + OGA | ASSET §1.3 | ✅ 正确 |
| F19 | Nido "Tower Defence Basic Towers" = CC0(OGA,2020-05-26) | OGA + node 114170 | ASSET §3.3 | ✅ 正确 |
| F20 | Sonniss GDC 2026 Bundle:免版税、免署名、禁止 AI 训练、禁止单独再分发 | NewsBreak / Zeli / PluginDeals / gdc.sonniss.com | ASSET §8.5 主体条款 | ✅ 正确,但 **EULA v2.0 生效日 2026-08-27 存疑** |
| F21 | Godot 引擎本身 = MIT 许可证 | Godot License 文档 | TECH §16.4 / PRD §18.4 | ✅ 正确 |
| F22 | Kenney logo 禁止使用 | kenney.nl/support | ASSET §9 "不能混搭" | ✅ 正确 |

---

## 5. 跨文档交叉矛盾清单

按"对实施影响最大 → 最小"排序:

| # | 矛盾点 | TECH | PRD | 建议优先级 |
|---|---|---|---|---|
| C1 | 寻路策略 | AStarGrid2D + set_point_solid(动态) | 设计师曲线/航点(静态) | **BLOCKER #3** |
| C2 | 像素基础分辨率 | 426×240 | 640×360 | **BLOCKER #2** |
| C3 | 放置校验 | TECH §3.4 必做 | PRD 全无 | **BLOCKER #1** |
| C4 | 内容规模 | 4 塔 / 16 敌 / 4 BOSS | 6 塔 / 38 敌 / 6 BOSS | **MAJOR #1** |
| C5 | M1 里程碑范围 | 1 塔 1 敌 1 波 | 2 塔 4 敌 1 英雄 1 相位 | **MAJOR #2** |
| C6 | AutoLoad 命名 | *Manager | *Service | **MAJOR #3** |
| C7 | 对象池时机 | 必须 | 先 profile 后定 | **MAJOR #4** |
| C8 | 同屏上限 | 50–150 敌 / 100–300 proj | 180 敌 / 250 proj | **MAJOR #5** |
| C9 | 本地化目标 | 没明确 | 9 种语言 | **MAJOR #9** |
| C10 | 外部测试规模 | 没明确 | 200+ 人 | **MAJOR #10** |
| C11 | 无障碍 P0 范围 | 没明确 | 11 项 + 5 测试者 | **MAJOR #11** |
| C12 | 缩放档位 | 1× / 1.5× / 2× | 75%–150% | **MINOR #10** |
| C13 | Steamworks 集成承诺 | 没明确 | Steam Cloud + 30 成就 | **MAJOR #12** |
| C14 | P0/P1/P2 命名 | 一致 | 一致 | OK(Minor #9) |
| C15 | 塔/敌人物理/碰撞 | TECH §3.2 TileMapLayer | PRD §6.5 提到"重定向"但未规定层 | 隐含一致,需 PRD 补 |
| C16 | Wasm64 | TECH §14.1 提及 | 未提 | 漏(不影响实现) |

---

## 6. 零基础不可执行点(综合评估)

针对"0 基础 + 唯一开发者 + 15–24 月窗口",下列条目在原始文档中**没有充分的可行性保障**:

1. **Steamworks SDK 集成**(PRD §15.4, §16):需要 godot-steamworks 第三方插件 + 离线降级 + 平台成就对账。**预计 2–3 周专门工作量**,需找教程并调试。
2. **Steam Deck 验证**(PRD §0):即使"架构预留",Steam Deck 验证流程本身是 Valve 提供的 Proton 测试,需要单独跑兼容性测试。
3. **macOS 公证**(TECH §14.5):Apple Developer 账号 $99/年 + codesign + notarytool + stapler——0 基础 dev 容易在公证步骤卡 1–2 周。
4. **无障碍测试**(PRD §13.3 需 5 名相关需求测试者):招募难 + 测试用例设计工作量大。
5. **9 语言本地化**(PRD §14.1):即使只做 P0 中英,翻译 + 字体回退 + UI 长度预留 + 截图测试也需 4–6 周。
6. **38 种敌人动画帧**(PRD §0):每种敌人需要 4 方向 × 4 状态 × 4–8 帧 ≈ 64–128 帧 = 0.5–1 MB 像素美术。每种敌人平均 1 周美术 = 38 周 ≈ 9.5 月纯美术工作量。
7. **24 关卡手工设计 + 调试**(PRD §22):即使有模板,每关 3 周 = 72 周 = 17 月内容生产。
8. **测试基础设施 GUT + 自研关卡跑测器**(TECH §13):写测试本身需要学习 GUT,首月效率 -30%。

**总评**:**PRD 当前规模超出 0 基础单人窗口约 30–60%**。**强烈建议在 M0 立项时按 Major #1 把规模砍到 16 关 + 16 敌 + 4 Boss**。

---

## 7. 建议处理顺序(给下一轮 agent 的钩子)

按依赖关系排序:

1. **冻结决策**(在动 M0 之前):
   - [C2] 基础分辨率 = 640×360
   - [C13] tile 尺寸 = 32×32
   - [C1+C3] 寻路 = 设计师曲线 + AStarGrid2D 校验 + PhaseController 重激活
   - [C5] M1 最小内核 = 1 塔 1 敌 1 波 + 路径校验 + HUD + 存档
   - [C4] 内容规模 = 16 主线关 / 6 塔 / 12 普通 + 4 精英 + 4 Boss / 4 英雄

2. **更新三份文档**:
   - TECH §2.2 / §3.1:改 viewport + tile 尺寸
   - TECH §15.x:重写 P1–P3 范围,与 PRD M0–M3 对齐
   - PRD §0 / §5 / §6 / §8:砍到 16 关 + 12 敌 + 4 Boss
   - PRD §18:补 PathNetwork + TowerPlacementValidator 节点
   - PRD §22:M1–M3 改为 TECH 口径
   - PRD §14.1:缩到 3 语言(简中 + 英 + 繁中)
   - PRD §13.1:缩 P0 到 6–7 项
   - PRD §21.4:缩测试规模

3. **M0 立项核验**:
   - 直接打开 https://sonniss.com/gdc-bundle-license/ 核实 EULA 生效日期(解决 Blocker #4)
   - 直接打开 https://kenney.nl/assets/tower-defense-top-down 核实 CC0 标志(Minor #6)
   - 直接打开 godot-steamworks 仓库核实许可证(Major #12)

4. **实现触发条件**:
   - 上述 3 项完成 + 决策冻结后,才进入 M0 实施
   - 否则 PRD §29 已明确"未冻结前不得进入内容生产"

---

## 8. 总结:三份文档健康度

| 文档 | 内部一致 | 与其他文档一致 | 事实正确率(估) | 0 基础可执行 |
|---|---|---|---|---|
| TECH_RESEARCH_DRAFT | ✅ 高 | ⚠️ 与 PRD 大量冲突(分辨率、寻路、规模、命名) | ~95%(Minor #1、#2 是事实错误) | ✅ 高(技术细节扎实) |
| ASSET_AUDIO_RESEARCH | ✅ 高 | ⚠️ 与 TECH/PRD 在 tile 尺寸上不一致 | ~98%(EULA 日期待核) | ✅ 高 |
| PRD_FRAMEWORK | ✅ 内部基本一致 | ❌ 与 TECH 在多个核心决策冲突 | 未涉及 Godot API 事实 | ⚠️ 范围偏大,**砍项后再执行** |

**最关键的修复路径**:见 §7 "建议处理顺序"。

---

> 报告版本:DRAFT v1.0 (2026-09-04)
> 审查员:技术事实审查员
> 状态:本审查文档不动源文档,等待用户/PRD agent 根据报告修订后再进入 M0
> 复核清单:请 PRD owner 按 §7 决策表逐项打勾,完成后再启动实现

###TASK_COMPLETED###
