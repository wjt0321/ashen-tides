# C01 独立审查 — 2026-09-07

## 范围与结论

审查 HEAD `312450d7a682bc8c107198de26c1736cc3aec4b0`，比较基线 `04fb765`。初始 main 与 origin/main 同步、工作树干净。用户表示第一关大部分代码完成，并加入免费精灵图；本轮只审查和记录，未修改业务代码，未 commit/push。

结论：Foozle 栅格精灵接入确实明显改善塔、敌人、舰船与港口主体；不再沿用被否决的几何占位主体。保留当前方向，优先补流程回归，不需要再次推倒视觉。不能据此宣告完整产品验收或 M2 Gate 通过。

## 独立复跑

- Godot 4.7.2 无头编辑器导入成功。
- 全量 tests：493 pass / 0 fail；故障注入测试有预期保存失败/损坏回退 warning。
- Data：checked=243 errors=0。
- i18n：referenced=216 defined=264 missing=0。注意：扫描器不证明硬编码中文已国际化。
- Asset validator：5 source archives、11 derived、26 vendor payloads、51 vendor ledger rows、7 evidence、errors=0。
- Docs validator：36 Markdown、0 broken links（写入本报告前）。
- 窗口模式 `--level=level_c01 --m2-perf --shot-at-wave=4`：win，6/6 waves，7017 ticks，90 kills，0 gameplay leaks，integrity=20，3/3 marks。
- RTX 3070 / Forward+ / 640×360 / 3x：2915 frames，13.37 ms average（约75 FPS），1% low 18.75 ms（约53 FPS）。与历史144.5/105.9不同；本次环境负载/帧限制未隔离，不据此断言代码性能退化，也不复用历史数值冒充本次结果。
- 退出仍报6个ObjectDB残留，与敌人漏怪0不同。
- git diff --check 无空白错误；有LF/CRLF提示。
- 原始日志：out/review_import.log、review_tests.log、review_data.log、review_i18n.log、review_c01_perf.log；C01报告 out/m2_smoke_level_c01_speed3.0.json、out/m2_perf_level_c01.json。

## 视觉与许可抽查

实际查看 docs/evidence/c01/title.png、battle-busy.png，以及本轮重新运行生成 out/polish_level_c01_wave4.png；新第四波画面与仓库证据一致。标题具备港灯、舰队与主CTA；战斗具备真实塔体/敌群/码头材质。繁忙波次敌群重叠较强、顶部波次大字仍占据战场视线，属于后续可读性优化，不否决整体方向。未进行真人完整路径试玩或完整动画/音频感知验收。

逐个打开5份Foozle ZIP中的Readme：Spire Enemy Pack 2、Tower Pack 1、Scallywag Ships、Water and Islands、Fort 均明确CC0，允许商业使用和修改，无强制署名。核对SOURCE_MANIFEST与派生hash通过。作者Baldur、Pixel Carvel，分发Foozle；Kenney为辅助资源。这里是本地原包声明核验，不声称重新联网核验网站身份。

## 需修复发现

下列代码问题经调用链复核；除导入副作用外属于静态确认，未通过真实用户存档破坏性复现。

### P1 跨关恢复可将成绩记入错误关卡

scripts/app/app_flow.gd:546-551 只检查 has_suspend，C02简报可恢复C01存档；584-593使用selected_level启动，scripts/boot/main.gd:1388-1397随后按suspend切换实际关卡，但app_flow.gd:607-610仍用原selected_level写成绩。可能打赢C01却记录C02并解锁C03。应验证恢复关卡匹配，结算以受验证的实际BattleSession关卡为准。

### P1 已有槽覆盖确认及保存失败提示失效

scripts/app/app_flow.gd:305-323 将 ConfirmLabel/ConfirmRow 挂在FlowContent内；407-415和434-439仍从_screen直接查找，得到null。已有存档覆盖按钮不显示确认行；读写失败提示同样不可见。三个槽占满时会阻断新游戏。应修路径并补真实层级断言测试。

### P2 操作失败通知不再显示

scripts/boot/main.gd:1475-1493 保留_flash_notice写入，但HUD不再消费_notice；资金不足、恢复成功等调用仍存在。应添加不遮挡战场的通知区域，补资金不足路径测试。

### P2 C02简报目标被C01硬编码覆盖

scripts/app/app_flow.gd:503-504 对所有关卡显示“至少完成一次升级”；C02实际策略目标为use_tide_clock（data/levels/level_c02.tres:32-33）。应按数据展示真实目标。其他非C01敌人头像也不应统一替换成桅鼠图。

### 范围限制：C03-C14直接选关入口缺失

scripts/ui/c01_campaign_chart.gd:25-33仅有C01/C02，旧版全目录选关不再存在。当前C01切片锁范围可接受，但不是完整Campaign保留；拥有后续进度的玩家无法从战役直接选择这些已解锁关卡。记录为已知限制，不以此要求扩展/精修后续关卡。

### P2 导入台账被识别为翻译CSV，污染根目录

本轮从干净工作树执行Godot导入后出现13个未跟踪 ASSET_LICENSE_LEDGER.*.translation（allowed/attribution/author/download/file/license/modified/notes/project/redistributable/replacement/source/status）。与既有ART_ASSET_REGISTRY错误导入同类。应把台账导入类型设为保留/禁用翻译导入，而非仅忽略生成文件。本轮未擅自删除这些文件。

## 状态与后续

优先修复跨关恢复和覆盖确认，再处理通知、C02目标及CSV导入。新增测试必须覆盖UI层级和不同关卡恢复，不以493项全绿替代。M2-GATE仍BLOCKED，evaluated_revision仍1495fdd，后续正式评审需要更新证据引用，但本轮不修改批准状态。

保留当前C01精灵方向；当前审查不是人类Gate批准。用户最新反馈“效果上了一个档次”已确认，仓库已有风格批准记载仍以原记录为准。
