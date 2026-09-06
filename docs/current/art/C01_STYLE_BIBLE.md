# C01 Style Bible（最终样板实现）

> **全局视觉权威**：`docs/current/art/ART_STYLE_BASELINE.md`。
> **用途**：本文只记录 C01 如何实现全局基线，不再重复维护全项目风格规则。
> **批准记录**：2026-09-06，项目主理人采用当前 C01 栅格像素风格，并指定后续关卡全部沿用。
> **成熟度状态**：只查看根目录 `ART_ASSET_REGISTRY.csv`。

## 1. C01 色板

| 角色 | 代表色 | 用途 |
|---|---|---|
| Ink | `#171b1d` | 外轮廓、前景礁石、深色面板 |
| Sea Dark | `#203638` | 深水与阴影 |
| Sea | `#355756` | 主海面与潮湿石材 |
| Sea Light | `#53736d` | 波纹、石材高光 |
| Bone | `#e8ddc8` | 标题、正文、航迹高光 |
| Coral | `#ef684b` | 港灯、己方塔、CTA、舰队识别 |
| Ember | `#ff9b55` | 小面积光源和攻击高光 |
| Tide Cyan | `#2b8f94` | 敌潮状态与危险提示 |

暖色只用于焦点；敌人主体保持冷青灰和深色轮廓。

## 2. C01 栅格资产

| 输出 | 用途 | 规格 |
|---|---|---|
| `enemy_salt_shell.png` | 盐壳行者 | 8 帧 × 3 方向，64×64 源帧，运行时约 52px |
| `enemy_mast_rat.png` | 桅鼠群 | 8 帧 × 3 方向，3 个错位小体组成逻辑单位 |
| `tower_needle_rail.png` | 针轨弩台 | 6 帧，96×96 源帧，塔基 + 机械弩 |
| `harbor_props.png` | 灯塔、舰船、码头与岸防道具 | 8 个 128×128 单元 |
| `battle_background.png` | C01 战场 | 640×360，包含两条既定路线的世界化表现 |
| `title/campaign/briefing/result_*_background.png` | 完整流程背景 | 640×360 |
| `briefing_map.png` | 战前简报地图 | 真实栅格战场缩略图 |

所有输出位于 `assets/art/c01/runtime/`，由 `tools/build_c01_foozle_assets.py` 从保留的 Foozle CC0 ZIP 确定性生成。

## 3. 屏幕构图

### 3.1 Title

- 左侧灯塔为主地标；暖色光束横贯画面；舰队位于右侧航线上。
- 标题与主操作位于画面中右部，避免遮挡灯塔。
- 同屏只允许一个高饱和主 CTA。

### 3.2 Campaign

- 使用同一港区背景，C01 按钮附着灯塔港，C02 按钮附着远处潮门。
- 交互层只保留地点按钮，不再绘制抽象多边形岸线、圆形节点或流程图航线。

### 3.3 Briefing

- 左侧使用 `briefing_map.png`，明确显示路线、舰船、灯塔和防区。
- 右侧直接展示盐壳行者、桅鼠群和针轨弩台栅格主体。
- 保留 C01 无英雄规则与原有正式 UI 节点契约。

### 3.4 Battle

- 地形背景负责海面、岸线、栈桥、灯塔、舰船和道路材质。
- `PathNetwork` 只绘制轻微激活辉光和端点，不重复绘制整条抽象道路。
- BuildNode、状态条、选择范围与攻击反馈仍作为清晰的功能叠层。

### 3.5 Result

- 胜利：灯塔亮起、暖光出现、舰队继续通过。
- 失败：灯塔熄灭、暖色收缩、港区转冷。
- 三个大数字和主 CTA 叠在世界场景上，不回退为居中统计弹窗。

## 4. 运行时规则

- 统一纹理入口：`scripts/ui/c01_sprite_library.gd`。
- 所有相关 CanvasItem 使用 Nearest 过滤。
- 程序化绘制只保留薄雾、颗粒、暗角、状态条、潮汐 tint、攻击辉光和交互反馈。
- 玩法数值、路线点、BuildNode、波次、奖励和生命周期与美术层严格分离。
- Campaign、Briefing、Battle 与 Result 复用同一灯塔/舰船/敌塔资产语言。

## 5. UI 与音频

- 字体：Ark Pixel 12px CJK。
- 主操作：暖珊瑚；次操作：炭黑低对比；危险状态：冷青或警示色。
- Kenney UI Audio 继续承担：`ui_select`、`ui_confirm`、`ui_cancel`、`ui_transition`、`ui_error`。
- Kenney UI/FX 保留为兼容层或辅助层，不再主导 C01 世界美术。

## 6. 验收证据

- Title：`docs/evidence/c01/title.png`
- Campaign：`docs/evidence/c01/campaign.png`
- Briefing：`docs/evidence/c01/briefing.png`
- Battle Early：`docs/evidence/c01/battle-early.png`
- Battle Busy：`docs/evidence/c01/battle-busy.png`
- Result Win：`docs/evidence/c01/result-win.png`
- Result Lose：`docs/evidence/c01/result-lose.png`

后续关卡应按 `docs/current/art/ART_STYLE_BASELINE.md` 的生产模板生成同类证据；C01 是黄金参考，不再另起视觉体系。
