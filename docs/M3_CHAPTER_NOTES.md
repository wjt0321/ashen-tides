# M3 第一章阶段记录

## 状态

**PARTIAL：主要代码与内容基线已落地；最终退出门禁未完成。**

## 已完成

- 新增第 4–6 座塔与 9 个模块资源
- 新增第二名英雄铸手·穆恩与 3 个技能资源
- 新增第一章 C04–C08 关卡数据，每关 12 波
- 新增 6 个敌人资源，其中包含精英与 C08 Boss
- C08 Boss 三阶段运行时与报告字段已接入
- 新增 M3 smoke、性能和确定性回归工具
- 数据校验通过：`checked=141 errors=0`
- 内容测试通过：`pass=117 fail=0`
- i18n 校验通过：`referenced=175 defined=202 missing=0`
- C04–C08 1×/3×基础 smoke 报告已生成，均为 12/12 波 win
- C08 suspend/resume 报告文件已生成

## 证据

- `out/m3_smoke_level_c04_speed1.0.json` 至 `out/m3_smoke_level_c08_speed3.0.json`
- `out/m3_smoke_level_c08_speed3.0_resumed.json`
- `out/m3_tests_escalated.log`
- `out/m3_i18n_after.log`
- `out/m3_data_validate_3.log`
- `out/m3_smoke_aggregator.log`

## 未完成 / 不得误读

- 最终合并回归命令未完整确认
- M3 性能聚合未完整确认（当前仅 C04–C06 有性能 JSON）
- C08 suspend/resume 的最终一致性聚合未确认
- Godot editor headless 导入门禁曾遇 Windows/Godot settings 异常退出，未宣称通过
- M3 smoke 使用 `simulation_assist`，不能替代标准难度平衡证明
- 每关 3 套真实构筑可通未验证
- 正式美术、音频、字体、实体手柄、盲测、30 秒正式录屏未完成
- M3 退出评审未完成

## 下一步

先修复/验证 C07–C08 性能报告、最终 regression、suspend 一致性和导入门禁，再由项目主理人确认 M3 退出评审。