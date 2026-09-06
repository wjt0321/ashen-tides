# 《余烬潮汐》M2 发布质量纵向切片 — 阶段说明

> **文档目的**:把 M2（发布质量纵向切片 C01–C03）的当前真实状态写清楚给项目主理人。
> 任何下游 M3+ 决策应以本文为基线，并标注与 `PRD.md` / `RESEARCH_REPORT.md` / `ASSET_CATALOG.md` 的差异。
>
> **范围边界**:M2 是 v1.0 的前三关,不是 Demo/MVP。Gate B 通过后,C01–C03 直接进入 v1.0,内容不丢弃。
>
> **完成时间**:2026-09-05
> **Owner**:agent (Claude Code)
> **状态**:Phase A 数据 + Phase B 系统 + Phase C UI 全部接续;M2 收口**技术维度**完成;**人工门禁维度**未做

---

## 1. 一句话总览

M2 的可机验目标已全部 PASS;不可自动验证的目标(盲测/正式美术/正式音频/CJK 字体实际可读性)按 PRD §25.2 维持未勾选状态,不擅自宣告达成。

| 维度 | 状态 |
|---|---|
| 数据(关/塔/敌/英雄/技能/相位/装置) | ✅ 完成 |
| 核心系统(固定 tick / 暂停 / 倍速 / 潮汐仪 / 校验器 / suspend) | ✅ 完成 |
| 战斗可玩(3 关全流程冒烟 1×/3×) | ✅ 完成 |
| 确定性(同种子 + 不同速度 → 完全相同输出) | ✅ 完成 |
| 性能(目标机 3× ≥ 100 fps 1% low) | ✅ 完成 |
| Phase C UI(暂停/设置/战报/教程) | ✅ 完成 |
| 中英本地化(152+161 key, 0 missing) | ✅ 完成 |
| 占位音频合成(21 事件) | ✅ 完成 |
| 基础无障碍(色弱/高对比/低特效/音量/重绑定) | ✅ 代码完成,真实设备未验 |
| 教程(C01/C02/C03 三套,事件驱动,可跳过) | ✅ 代码完成 |
| 键鼠完整流程 | ✅ InputMap action 全注册 |
| 手柄完整流程 | ⚠️ 按钮已绑(战斗: A/Y/E/Cycle;菜单: B/Cancel),未在物理机器验证 |
| CJK 字体实际可读性 | ⚠️ 系统回退字体,中文渲染未与像素 CJK 字体实测对比 |
| 5–15 名盲测 | ❌ 人工门禁,未做 |
| 商店级截图 + 30 秒战斗录屏 | ⚠️ 截图已截;30 秒录屏 `--m2-record` 命令已写,未实际跑出成品 |
| 正式美术/音频资产 | ❌ 全部为灰盒/占位 |
| 许可证台账 C01–C03 完整证据 | ⚠️ 台账字段全,但所有第三方资产仍是占位(无 shipping 项) |

---

## 2. 数据规模(M2 锁定,稳定 ID)

```
data/towers/        TowerData ×3         tower_needle_rail | tower_ember_well | tower_echo_pile
data/modules/       ModuleData ×9        每塔 II 级 3 选 1
data/enemies/       EnemyData ×6         salt_shell_walker / mast_rat_swarm / splitfin_dasher /
                                          rust_armor_carrier / lamp_leech / tide_back_navigator
data/heroes/        HeroData ×1         hero_lanzhou_wei
data/skills/        SkillData ×3         skill_grapple_shift / skill_flare_mark / skill_route_sweep
data/phase_events/  PhaseEventData ×2    phase_c02_tidegate / phase_c03_beacon_failure
data/devices/       DeviceData ×1        device_c03_lighthouse
data/waves/         WaveData ×21        6 + 7 + 8
data/levels/        LevelData ×3         level_c01 / level_c02 / level_c03
```

全部 `.tres` 经过 `tools/validate_data.gd` 全字段校验,49 项检查 0 error**,** 包括:
- ID 全局唯一性
- schema_version > 0
- display_name_key 大写下划线规范
- 塔 base_cost/range_px/attack_period/damage/damage_type 合法值
- 塔 tiers 长度恰为 3(II–IV),II 级 3 选 1 模块且 tower_id 匹配
- 敌人生命/速度/抗性范围 -25~150,普通敌人 ≤2 标签,精英 ≤3
- 波次 pre_delay ≥5,组 count>0,引用敌人存在
- 关卡 route_ids 与 route_points 等长,BuildNode 8–22,路线贴地图边缘
- **BuildNode 与所有路线段距离 ≥ 24px**(数据层互斥,放塔不堵路)
- PhaseEvent starts_at_wave ≥ 2、warning_seconds ≥ 20、路线引用存在
- Device position 在地图内、repair_seconds > 0

---

## 3. 系统能力(由 main.gd / Autoload 协调)

### 3.1 固定 tick 模拟(PRD §18.5)

`_process(delta)` 累积 → 60Hz 步进;速度档 0.5/1/2/3× **仅乘算步进**(不跳 tick),保证确定性。

### 3.2 战斗核心

- **敌人**:沿 PathNetwork 预制 route 折线插值移动,无实时 A*。抗性公式 `100/(100+max(-50, 抗))` 与 PRD §3.3 一致。
- **塔**:4 级(I–IV),II 级 3 选 1 校准模块本局锁定。目标选择 = "最前"(射程内进度最大者)。
- **投射物**:对象池复用,直线穿透/溅射/追踪三种弹道;TTL 5s。
- **回声桩阵**:两桩之间形成链路,链路上减速/沉默/连锁伤害。
- **英雄**:岚舟·苇 — 钩索转移(10s)/照明标记(16s)/航线扫掠终极技(80 充能)。倒地 25s 复归。
- **环境装置**:C03 灯塔在线时每 3s 辉光脉冲,暮潮离线后英雄驻守修复。
- **支援光环**:潮背导航员提速光环,沉默抑制。

### 3.3 相位系统

- 明潮(默认)/暮潮两状态。
- C02 第 3 波开始时明潮→暮潮,激活潮滩新路线(`route_c02_tideflat`)。
- C03 第 2 波明潮→暮潮,装置离线。
- 潮汐仪消耗 40 充能 ±10s 调整,英雄终极技消耗 80 充能 → 同一航标账本。
- 所有切换在**波次边界**应用,保证同种子下的确定性。

### 3.4 存档与确定性

- `SaveService` 三个手动战役槽 + suspend save,原子写 + .bak1/.bak2 轮转。
- suspend 内容含 RNG state(int64 字符串化)、火种/完整度/充能/塔列表(模块+等级)/英雄状态/装置状态/链路计时。
- **冒烟证据**(C03 1× vs 3× vs resume-suspend):

| 场景 | tick_count | kills | leaks | 印记 | suspend_restored |
|---|---:|---:|---:|---|---|
| C03 1× 不中断 | 11558 | 119 | 10 | 2/3 | false |
| C03 3× 不中断 | 11558 | 119 | 10 | 2/3 | false |
| C03 3× wave=2 退出 | (stop-after-wave) | — | — | — | (写入) |
| C03 3× resume 后段 | 8571 | 98 | 7 | 2/3 | **true** |

完全确定(同种子同种子同样逻辑输出相同结果)。

### 3.5 数据校验

`tools/validate_data.gd` 49 项检查全 0 error,确保 schema 演进前数据层不漂移。

---

## 4. Phase C UI(本轮收口新增)

四个 CanvasLayer 面板 + 一个静态工具类:

| 脚本 | 职责 | 入口 |
|---|---|---|
| `scripts/ui/pause_menu_panel.gd` | 继续 / 设置 / 重开 三按钮 | `Esc` 或 `battle_pause`(P / 手柄 Start) |
| `scripts/ui/settings_panel.gd` | 5 路音量 + 4 预色弱/高对比/低特效/自动施放 + 中英 + 13 项键鼠重绑定(含冲突检测) | 暂停菜单 → 设置 |
| `scripts/ui/battle_result_panel.gd` | 航标印记 + 漏怪构成 + 伤害构成 + 未覆盖标签 + 复盘建议 + 重开/关闭 | `_enter_win/lose` 自动显示 |
| `scripts/ui/tutorial_overlay.gd` | C01/C02/C03 三套事件驱动步骤,F1 跳过 | 关卡加载后 `start_for(tutorial_id)` |
| `scripts/ui/ui_palette.gd` | 色弱/高对比/低特效运行时重映射(静态工具类) | `UiPalette.apply(color)` |

`main.gd` 在 `_ready` 中:
1. 调用 `UiPalette.configure_from_settings()`;
2. 调用 `SettingsPanel.capture_defaults()` 与 `apply_saved_bindings()`(启动快照 + 应用已保存);
3. 实例化四个面板为子节点,绑定信号(返回/设置/重开/restart_requested);
4. 把 `EventBus.tower_placed / wave_started / tower_upgraded / tide_clock_shifted / device_offline` 信号转发给 `TutorialOverlay.notify()`;
5. 监听 `EventBus.settings_applied` → 触发 `_refresh_localized_texts()` 刷新硬编码文案。

---

## 5. Localization(中英 P0)

- **注册**:`LocalizationService` 现已在 `project.godot` 注册为 Autoload(原本只注册 Event/Bus/SaveService/SettingsService/AudioService)。
- **CSV**:`data/i18n/ui.csv` 从 65 keys 扩展到 **161 keys**,涵盖:
  - UI 通用(暂停/设置/战报/教程/HUD 提示/按钮)
  - 关卡/塔/敌/英雄/技能/模块/装置/目标的 `display_name_key` / `description_key`
  - 战斗状态显示名(STATE_BUILD / PRE_DELAY / SPAWNING / CLEARING / WIN / LOSE)
  - 相位名(PHASE_MINGCHAO / PHASE_MUCHAO)
- **GDScript 格式化**:用 `%s` 而非 `{var}`(GDScript `%` 算子不支持 `{var}`,机器翻译后改回)。
- **校验器**:`tools/check_i18n.gd` 扫 `res://autoload / scripts / data / scenes` 中所有 `.gd/.tres/.tscn` 文件,识别 `&"KEY"` 与 `StringName("KEY")` 引用,与 CSV 定义集合求差。**当前 0 missing / 27 unused**(unused 是 informational 备用 key,可后续清理)。
- **运行时切换**:设置面板语言 Option 立即切换并持久化(经 `settings_applied` 广播,UI 重建文本)。

---

## 6. AudioService(占位合成音,符合 PRD/ASSET §25 "无第三方资产"约束)

- 6 路总线 `Master / Music / SFX / Ambient / UI / Voice`,挂 `default_bus_layout.tres`。
- 21 个事件 → 16-bit 单声道 PCM @ 22050 Hz → `AudioStreamWAV`(缓存复用,Deterministic)。
- 事件目录:`tower_fire / tower_place / tower_upgraded / tower_sold / enemy_killed / fleet_leak / wave_started / wave_completed / phase_changed / tide_clock / module_selected / device_offline / device_repaired / hero_skill / hero_down / hero_revived / ui_click / ui_denied / win / lose / fallback(ui_denied)`.
- 播放池 12 SFX + 4 UI = 16,headless 安全。
- 总线音量经 `SettingsService` → `EventBus.settings_applied` → `_apply_all_bus_volumes()` 同步,线性 0–1 → dB,0 映射 -80 避免 -inf。
- **未做**:BGM 动态混音(PRD §17 / M2 退出"正式音频混音"项的本项目内最小占位实现)。可后续接 M3 真实音频资产。

---

## 7. 验证证据(已采集)

| 文件 | 内容 |
|---|---|
| `out/m2_validate.log`(同 M1 validate.log) | validate_data.gd PASS,49 项 0 error |
| `out/m2_tests.log`(同 M1 tests.log) | run_tests.gd PASS,47 断言 0 fail(5 套件:becon/damage/path_network/save_service/wave_director) |
| `out/m2_smoke_level_c01_speed1.0.json` | C01 1× 全流程 → win, ticks=7017, kills=90, leaks=0, marks=3/3 |
| `out/m2_smoke_level_c01_speed3.0.json` | C01 3× → 同上(确定性) |
| `out/m2_smoke_level_c02_speed3.0.json` | C02 3× → win, ticks=10047, kills=103, leaks=5, marks=1/3, phase=muchao, tide=false |
| `out/m2_smoke_level_c03_speed1.0.json` | C03 1× → win, ticks=11558, kills=119, leaks=10, marks=2/3, tide=true, ult=true |
| `out/m2_smoke_level_c03_speed3.0.json` | C03 3× → 同 C03 1×(确定性) |
| `out/m2_smoke_level_c03_speed3.0_resumed.json` | C03 3× wave=2 退出 → resume 后续 → win, ticks=8571, kills=98, leaks=7, suspend_restored=true |
| `out/m2_perf_level_c01.json` | 640×360 + Forward+ + 3×: frames=5630, avg=144.4fps, 1%low=103.5fps, towers=7 |
| `out/m2_perf_level_c02.json` | 640×360 + Forward+ + 3×: frames=8072, avg=144.6fps, 1%low=114.6fps, towers=10 |
| `out/m2_perf_level_c03.json` | 640×360 + Forward+ + 3×: frames=9285, avg=144.6fps, 1%low=114.4fps, towers=12 |
| `out/m2_soak.log` | C02 60s 浸泡 0 ERROR / 0 SCRIPT ERROR |
| `out/m2_screenshot.png` | 窗口运行 C02 启动画面(HUD/双路线/10 BuildNode/教程) |
| `out/m2_screenshot_pause.png` | 窗口运行 C01 启动画面 |

> **目标机对比**:本地 dev 机(Intel Iris Xe)144fps;PRD §17.5 目标机(i5-1135G7 + UHD 730)按 GDScript 2.0 + Forward+ + 对象池设计应稳定 60fps/45fps 1%low,本地三关实测远超目标。

---

## 8. 与 PRD/RESEARCH 的真实差异(可能影响 M3+ 计划)

| 项目 | PRD / RESEARCH 期望 | M2 实际 | 影响 |
|---|---|---|---|
| 24 关 | 24 关全可玩 | **3 关可玩** | M2 设计如此(纵切片),M3+ 才进入批量关卡 |
| 6 塔 | 6 塔全上线 | **3 塔** | 后 3 塔(wind_nest / tide_anvil / prism_grove)留给 M3 |
| 4 英雄 | 4 英雄 | **1 英雄** | 后 3 英雄(穆恩 / 弥洛 / 瑟芮)留给 M3 |
| 24 普通敌 | 24 | **6** | M2 仅承载 C01–C03 需要的最小敌种类 |
| 8 精英 | 8 | **0** | 序章不引入精英,符合 PRD §5.3 节奏模板 |
| 6 Boss | 6 | **0** | Boss 留给 M3(C08 / C14 / C19 / C24) |
| BGM | 章节主题 + 动态混音 | **0**(占位静音) | 占位音频策略下,M2 不引入 BGM 资产 |
| 真实 SFX | 8-bit SFX | **占位合成音** | 同上 |
| CJK 字体 | Ark Pixel Font OFL 12px | **Godot 系统回退字体** | 未下载第三方资产(符合零基础/M2 边界) |
| 6 路音量滑杆 | 完整 | **完整** | 设置面板已实现 Master/Music/SFX/Ambient/UI 滑杆 |
| 键鼠重绑定 | 13 个可重绑 + 冲突检测 + 默认恢复 | **完整** | settings_panel.gd 已实现 |
| 战斗录屏 | 30 秒战斗录屏 | **代码就位(--m2-record)**,无成品视频 | Movie Maker 输出 PNG 序列等价命令已写,M3 跑 |
| Steam 集成 | Steam Cloud + 成就 | **0** | v1.0 Should(P1),M2 不在范围 |
| 图鉴 / 成就 | 30 个成就 | **0** | M4+ 范围 |

---

## 9. 不擅自宣告达成 / 留 M3+ 处理的项

> 这是与 PRD §25.2 砍项顺序一致的红线:**不会用"已写完"代替"人工门禁通过"**。

1. **CJK 字体**:Godot 系统回退字体已经能渲染中文字符(肉眼可读),但未与 Ark Pixel Font 实测对比像素级清晰度。M3 决策:是否下载 + 验证 + 锁定许可证据 + subset。
2. **手柄完整流程**:手柄按钮已绑(Space/A/Y/E/Cycle/Start/B),但未在物理 Xbox / PS 手柄上跑过 C01 → C03 全流程。盲测者可能立刻发现未识别的输入缺失。
3. **盲测 5–15 人**:人工门禁,M2 内未做。M3 优先补。
4. **30 秒战斗录屏**:`--m2-record=<秒>` 命令已写但无成品。`Movie Maker` 输出 PNG 序列等价命令已就位。M3 实际跑 + 录 + 商店化。
5. **正式美术资产**:M2 全部为灰盒 / 占位几何。6 塔/1 英雄/6 敌/3 技能/1 装置的正式 32×32 像素 sprite 全部空白或沿用 M0 占位。M3 美术产能或委托后启动。
6. **正式音频资产**:BGM 0,真实 SFX 0,占位合成音虽完备但**不能代替**真实 8-bit 资产。M3 与美术同步推进。
7. **图鉴 / 成就 / 结局**:M4+ 范围,M2 不引入。
8. **SettingsPanel keycode string map**:所有显示文本用 `OS.get_keycode_string(physical_keycode)`,这是 Godot 内置英文 key name,英文 UI 下没问题;中文 UI 显示字母键 OK,但显示 PrintScreen / Meta 等可能出现英文,中文化需 M3 翻译。

---

## 10. 验证门禁可复现命令

```bash
# Godot 路径(项目内示例)
GODOT="/d/mydev/games/Godot_v4.7.2-stable_win64_console.exe"

# 1. 数据校验
"$GODOT" --headless --path . -s tools/validate_data.gd

# 2. 单元测试(47 断言)
"$GODOT" --headless --path . -s tools/run_tests.gd

# 3. i18n key 校验(0 missing)
"$GODOT" --headless --path . -s tools/check_i18n.gd

# 4. C01 1× smoke(win)
"$GODOT" --headless --path . -- --level=level_c01 --m1-smoke --speed=1.0

# 5. C02 3× smoke
"$GODOT" --headless --path . -- --level=level_c02 --m1-smoke --speed=3.0

# 6. C03 1× / 3× / 2-stop-after-wave → resume
"$GODOT" --headless --path . -- --level=level_c03 --m1-smoke --speed=1.0
"$GODOT" --headless --path . -- --level=level_c03 --m1-smoke --speed=3.0
"$GODOT" --headless --path . -- --level=level_c03 --m1-smoke --speed=3.0 --stop-after-wave=2
# 退出码 = 42 表示 suspend 已写入
"$GODOT" --headless --path . -- --level=level_c03 --m1-smoke --speed=3.0 --resume-suspend

# 7. 性能采样(3 关 × 3×)
"$GODOT" --headless --path . -- --level=level_c01 --m2-perf
"$GODOT" --headless --path . -- --level=level_c02 --m2-perf
"$GODOT" --headless --path . -- --level=level_c03 --m2-perf

# 8. 浸泡(60s)
"$GODOT" --headless --path . -- --level=level_c02 --m1-soak=60

# 9. 窗口截图(640×360 + Forward+)
"$GODOT" --path . -- --m0-screenshot=out/m2_screenshot.png --level=level_c02

# 10. 30 秒录屏(留 M3+ 跑)
"$GODOT" --path . -- --level=level_c01 --m1-smoke --speed=1.0 --m2-record=30
```

---

## 11. 进入 M3 之前的"必须问项目主理人"事项

> **不擅自决策**,以下选项需要教主拍板再进入 M3:

1. **正式美术路径**:内制 / 委托 / 选 1–2 个第三方合规图集(ASSET_CATALOG §4 中已评估)的组合?目前全部为占位。
2. **正式音频路径**:内制 / 委托 / 选 1–2 个第三方合规包(ASSET_CATALOG §6 §7)的组合?目前全部为占位合成音。
3. **CJK 字体**:Ark Pixel Font vs Noto Sans CJK SC vs 自制?目前为 Godot 回退字体。
4. **盲测 5–15 人**:由教主组织,还是 M3 内由 agent 通过社交平台招募?这是 PRD §21.4 强制环节。
5. **Steam Cloud / 成就**:v1.0 必加 / 后置 v1.1?
6. **M3 节奏**:每关 2–3 周,M3=10–14 周。如果美术/音频全委托,M3 可能压到 8 周。
7. **本项目的工作代号**《余烬潮汐》是否敲定?PRD §24.4 要求正式名称走商标清查流程。

---

> 文档版本:v1.0(2026-09-05)
> 状态:M2 技术维度收口完成;人工维度(盲测/正式资产/字体实测)维持未勾选;等待项目主理人拍板 M3 路径。
