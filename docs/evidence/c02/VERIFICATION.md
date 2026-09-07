# C02「潮门初启」完成度验证

> 验证日期：2026-09-07（Asia/Shanghai）
> 范围：C02 运行时、美术资产、战斗平衡、玩家流程壳层与回归检查。

## 运行结果

- C02 M1 window smoke：`result=win`，7/7 波，94 击杀，2 次漏怪，舰队完整度 16/20，印记 3/3。
- C02 策略目标：`use_tide_clock` 已触发，潮汐仪提前切换记录于 wave 2 / tick 1761，最终相位 `muchao`。
- 固定模拟：60 Hz，9275 ticks，154.60 simulated seconds，`invincible=false`，`simulation_assist=false`。
- 资产加载：潮门开/闭、针轨弩台 I–IV、余烬喷井 I–IV、裂鳍疾行者、桅鼠群、锈甲载体、余烬弹体 FX 均通过 `ArtLibrary` 路径解析；色弱变体随 unit 资源矩阵生成。

## 可视化证据

- `briefing.png`：C02 战前简报，展示双路线、潮门、策略目标、裂鳍疾行者与 C02 专属塔形象。
- `battle-wave4.png`：双路线实战，展示潮门、锈甲载体、桅鼠群、C02 塔形象与波次 HUD。
- `battle-wave5.png`：双路线实战，展示潮门、裂鳍疾行者、C02 塔形象与波次 HUD。
- `result-win.png`：C02 结算海报，潮门开启、3/3 印记与结果按钮。
- `assets-montage.png`：C02 资产抽样及等级/状态对比。

## 自动化检查

```text
Godot --headless --path . --script tools/run_tests.gd
[M1-TEST] total: pass=523 fail=0
[M1-TEST] PASS

Godot --headless --path . --script tools/validate_data.gd
[M1-VALIDATE] checked=243 errors=0
[M1-VALIDATE] PASS

Godot --headless --path . --script tools/check_i18n.gd
[I18N-CHECK] referenced=216 defined=264 missing=0

python docs/current/engineering/validate_docs.py
markdown_files=39 broken_local_links=0

python tools/validate_c01_assets.py
C01-ASSETS ... errors=0
```

## 设计修正

- C02 波 4/6/7 的后段密度做了小幅收口，保留“重甲 + 群聚 + 迅捷双路”识别重点，同时让正确布防与一次潮汐仪干预能稳定获得完整度印记。
- 暂停/恢复按关卡隔离；C02 简报不会误恢复 C01 的 suspend 存档；覆盖存档确认节点查找修正。
- 结算文案改为关卡显示名，不再向玩家显示 `level_c02` 内部 ID；战斗通知现在会进入 HUD。

## 发布门槛状态

- **实现 / 自动化：通过。**
- **人类玩家确认：待项目 owner 亲自走一遍 C01→C02、暂停/恢复、潮汐仪提前切换与 C02 结算。**
