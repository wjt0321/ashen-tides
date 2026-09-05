# M3 Polish：表现与可玩性增强记录（2026-09-05)

> 触发：用户试玩反馈"方向正确，但整体太简陋"。目标是在不改核心规则/范围、不下载第三方资产、
> 不外发的前提下，把 C01–C08 从"技术灰盒可跑"提升为"更像游戏的可试玩 build"。
> 全部视觉仍为程序化矢量绘制（无 sprite/贴图资产）；正式美术、最终字体、正式音频、盲测仍是后续门禁。

## 1. 做了什么

### 1.1 视觉主题层（新增 `scripts/ui/visual_theme.gd`）
- `VisualTheme` 静态类：8 关调色板（海面双色/泡沫/陆地双色/岸线/路面/强调色/微光）、
  相位氛围色（明潮暖 / 暮潮冷）、漏怪/胜负闪光色、确定性单元格 hash、明度缩放/混色辅助。
- 所有颜色经 `UiPalette.apply` 过无障碍重映射（色弱预设/高对比继续生效）。

### 1.2 地形主题（`scripts/boot/greybox_map.gd` 重写）
- 海底 32×32 双色格 + 确定性浪尖短划线/泡沫点；陆地双色斑块 + 石砾 + 岸线描边。
- 每关 1–2 个主题小元素：C01 栈桥桩锚灯、C02 潮门闸柱+雾弧、C03 灯塔光晕、C04 盐壳白斑、
  C05 漂木青苔、C06 沉船肋骨、C07 断桥板条、C08 暗红裂缝渗光。
- 装饰在 setup 时预计算进数组，`_draw` 只遍历不现算 hash。
- `phase_tint`：相位全屏氛围只罩地形层（战斗实体可读性优先），由 main 随相位驱动。

### 1.3 路线可视化（`scripts/path_network/path_network.gd`）
- 路线画成"路"：14px 深色路底 + 8px 内芯 + 每 48px 指向终点的地面箭头。
- 入口三层同心圆环 portal（激活时带外泛光）、出口方块闸门；未激活路线整体 alpha×0.35。
- 按关卡主题取色（`level_id` 字段，main 注入）。

### 1.4 塔/装置/投射物/回声链（`greybox_tower.gd` 等）
- 6 塔各自剪影：针轨弩台（弩臂横杆+轨道亮线）、余烬喷井（圆炉+火口双焰）、回声桩阵、
  风巢（叶片随 sim_tick 旋转）、潮汐砧、棱镜丛；未知 id 回退原方块。
- 主色 = 模块 tint 或塔族色，过无障碍重映射；等级 I–IV 色点角标保留。
- 开火炮口闪光（sim_tick 衰减，暂停定格）；选中塔射程环增亮（`highlight_range`）。
- 装置：灯塔条纹塔身 + 灯室 + 脉冲；投射物按 damage_type/pierce 分形状；
  回声链：16px 底带 + 2px 芯 + 3 个流动光点。

### 1.5 敌人/英雄（`greybox_enemy.gd` / `greybox_hero.gd`）
- 12 敌剪影按 data.id 分形；朝向（facing）旋转；受击 0.06s 闪白；精英金描边；
  Boss 阶段壳色泛红 + 裂纹；血条/护盾条/标签浮标（色+形+文字三重编码）。
- 标签浮标补全映射：群/迅/甲/盾/援/辉/疗/机/王（此前 engineer/glow/healer/boss 显示 "?"，已修）。
- 英雄双剪影（岚舟·苇船形 / 竹守·穆恩锤头），攻击前冲 2px 回弹（sim_tick 衰减）。

### 1.6 FX 反馈层（新增 `scripts/ui/fx_layer.gd`）
- 一次性特效数组池（上限 80，不逐条建节点）：命中火花（按伤害类型着色）、击杀爆点、
  建造尘环、升级上升光环、Boss 阶段爆发、漏怪红闪、相位切换闪光、胜/负全屏闪。
- 由固定 tick 驱动衰减（暂停定格，与全项目视觉规则一致）；胜负后 sim 停摆时用真实帧衰减闪光。
- 漏怪震屏：场景根 2–3px 衰减偏移，只动视觉、不消耗战斗 RNG；
  `accessibility/screen_shake` 关闭或 `low_fx` 开启时自动禁用/降级。

### 1.7 HUD 增强（新增 `scripts/ui/hud_extras.gd`，CanvasLayer layer=2）
- 顶中相位条：当前相位色块 + 待切换预告（"→ 第N波 暮潮"）+ 潮汐仪可干预标记。
- 波次横幅："第 N/M 波 · 敌×数 …"（数据来自 WaveData.groups），2.5s 淡出；
  Boss 阶段/相位切换事件横幅（醒目色）。
- 顶右 Boss 血条：名字 + 血条 + 护盾覆层 + 阶段阈值刻度。
- 左下英雄技能坞：1/2/3 槽位 + 冷却扫弧 + 终极技航标充能条（与潮汐仪竞争可视化）+ 倒地提示。
- 新增 i18n key：`HUD_HERO_DOWN`、`HUD_WAVE_BANNER`（zh/en）。

### 1.8 工程支持
- `--shot-at-wave=N`：窗口模式第 N 波开始后自动截图到 `out/polish_<level>_waveN.png`（证据采集）。
- PhaseController 增加只读 getter `pending_to_phase()/pending_wave()`；WaveDirector 增加 `wave_at(index)`。
  均为纯增量，不改任何 sim 行为与公共契约。

## 2. 验证证据

- 无头导入：0 编译错误（`--editor --headless --quit`）。
- 数据校验：`tools/validate_data.gd` checked=141 errors=0 PASS。
- 自动化测试：`tools/run_tests.gd` pass=117 fail=0 PASS（6 套件）。
- i18n：`tools/check_i18n.gd` referenced=179 defined=204 missing=0。
- 战斗 smoke（60Hz 固定 tick，seed=20260905）：
  - C01 3× win ticks=7017 kills=90 leaks=0（与 M2 基线逐 tick 一致）
  - C03 3× win ticks=11558 kills=119（与 M2 基线逐 tick 一致）
  - C08 3× win ticks=16661 kills=69（与 M3 基线一致，Boss 三阶段证据保留）
  - C01–C08 全量 3× 无辅助回归：C01/C02/C03/C05/C06/C08 win；C04/C07 无辅助 lose
    （既有平衡缺口，M3 期已存在，非 polish 回归；assist 模式 12/12 win 门禁 PASS）
  - C03 wave-3 suspend/resume：4226+7332=11558 与不间断运行 bit-perfect（M2 修复复验通过）
  - `tools/m3_smoke.gd` 聚合 8 关 PASS；`tools/m3_regression.gd` 速度对 5 关 PASS
    （C08 speed1 旧报告为过期产物 16329 ticks，用当前代码重跑后 1×=3×=16661，门禁转绿）
- 截图目检：`out/polish_level_c01_wave2.png`、`polish_level_c03_wave3.png`（暮潮 tint + 波次横幅 +
  技能坞 + 灯塔）、`polish_level_c06_wave3.png`（标签浮标修复后）、`polish_level_c08_wave12.png`
  （Boss 血条 + 阶段壳色 + 事件横幅）。
- 录屏：`out/polish_c01_combat.avi`（Movie Maker，2242 帧 @60fps，37 秒 C01 实战含建造/开火/击杀反馈）。
- 性能：`out/polish_perf_*.json`（见 §3 数字）。

## 3. 性能

窗口模式 3× 全场帧时间统计（`--m2-perf` / `--m3-perf`，640×360 Forward+）：

| 关卡 | 帧数 | avg | p99 | 1% low |
|---|---|---|---|---|
| C01 | 2912 | 13.39ms（75fps） | 13.64ms | 22.20ms（45fps） |
| C03 | 4800 | 13.38ms（75fps） | 13.64ms | 21.99ms（46fps） |
| C08 | 6926 | 13.36ms（75fps） | 13.64ms | 19.09ms（52fps） |

- 结论：三关 avg/p99 均显著优于 60fps（16.6ms）目标；polish 后 avg 从 M2 期 ~7ms 升至 ~13.4ms
  （逐 tick 敌人重绘 + 地形装饰 + FX 的代价），仍有余量。
- 诚实标注：1% low 跌到 45–52fps（瞬时重绘尖峰），未达"全程 60fps 锁定"；
  本机非目标低端机，低端机验证仍是 M5 门禁。
- 证据：`out/polish_perf_level_c01.json`、`polish_perf_level_c03.json`、`polish_perf_level_c08.json`。

## 4. 已知限制（不伪装完成）

- 正式美术资产仍缺：全部为程序化矢量占位，无 sprite/动画帧；ASSET_LICENSE_LEDGER 未新增条目。
- 动画为 sim_tick 驱动的几何插值，非手绘动画；表现力上限受占位管线约束。
- CJK 字体仍为引擎 fallback（字体锁定属既有 blocker，本阶段未动）。
- 正式音频仍为合成占位音（AudioService 占位，本阶段未动）。
- 手柄物理机验证、5–15 人盲测、录屏成品仍属人工/外部门禁。
- 关卡间地形骨架相同（共用海岸轮廓），差异靠调色板 + 小元素表达；正式 TileMapLayer 地形待资产阶段。
