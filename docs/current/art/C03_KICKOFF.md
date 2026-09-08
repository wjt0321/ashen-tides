# C03「失火灯塔」入场上下文（KICKOFF）

> **建立日期**：2026-09-08
> **目的**：让任何人（或下一个 agent）不读历史会话也能直接开工 C03 美术与接入。
> **权威关系**：视觉规则以 `ART_STYLE_BASELINE.md` 为准；资产成熟度以 `ART_ASSET_REGISTRY.csv` 为准；许可以 `ASSET_LICENSE_LEDGER.csv` 为准；本文是操作入口，不取代上述文档。

---

## 1. 现状速览（2026-09-08 收盘状态）

- C01/C02 战斗主体美术已切换为 **sourced-cc0-ccby-v1**：外部 CC0/CC-BY 素材（OpenGameArt）经确定性派生管线接入，游戏内验证全绿（validate_data 243 项 0 错、run_tests 529 全过、c01/c02 smoke 全程获胜）。
- 运行时美术两个入口：
  1. `scripts/ui/c01_sprite_library.gd`（C01SpriteLibrary）——C01 流程壳层，`preload()` 路径常量；敌人图条 8 帧 × 3 方向（行0=侧面**朝左**、行1=正面朝下、行2=背面朝上）64×64/帧，塔 6 帧 96×96（帧0 待机、帧1–5 开火包络），道具图集 8 格 128×128（索引语义以 `tools/pixel_v2.py` 的 `props_atlas()` 为准）。
  2. `scripts/core/art_library.gd`（ArtLibrary）——战斗/跨章节路径模板 + 缓存；`tower_tex`/`enemy_tex`/`c02_*` 系列走 `_unit_cached`，自动按 `UiPalette.preset()` 追加 `_protan/_deutan/_tritan` 后缀加载色弱变体，失败回退基图；`c02_landmark_tex`/`c02_vfx_tex` 走 `_load_cached`，**无色弱变体**。
- 数据驱动：`.tres` 只持 `id`，**换图不需要改任何 .tres/.gd**；只有新尺寸/新布局才需要回看 `greybox_enemy.gd`（视觉缩放系数 336–344 行）等绘制代码。
- 证据：`docs/evidence/c01/{battle,briefing}-sourced.png`、`docs/evidence/c02/{battle,briefing}-sourced.png`。

## 2. C03 资产需求（以 `data/levels/level_c03.tres` 实际内容核对）

C03 实际配置：8 波（wave_c03_01–08）、双路线（route_c03_main + route_c03_north）、12 BuildNode、初始 ember 550。

| 需求 | 明细 | 状态 |
|---|---|---|
| 敌人（已有） | salt_shell_walker / mast_rat_swarm / splitfin_dasher / rust_armor_carrier | ✅ 已有 sourced 素材（`assets/art/enemies/enemy_<id>.png` 通用目录 + 色弱变体），C03 直接走 `ArtLibrary.enemy_tex` |
| 敌人（新增） | **lamp_leech**（护盾标签，护盾先于生命承伤）、**tide_back_navigator**（支援标签，光环加速友军） | ❌ 缺口；功能轮廓须可辨（基线 §6.2：护盾/治疗等功能需像素主体变化或明显状态附件） |
| 塔 | allowed = needle_rail / ember_well / **echo_pile**；前两者已有 sourced 素材 | echo_pile（回声桩阵：两座桩 + 中间辉光伤害线，glow 伤害）❌ 缺口；视觉锚点见 ASSET_CATALOG §1.3（两根低矮桩柱 + 弦线/潮汐脉冲） |
| 英雄 | **hero_lanzhou_wei**（岚舟·苇，机动侦察；skill_a=grapple_shift、skill_b=flare_mark、ult=route_sweep；hero_spawn=(320,304)） | ❌ 缺口；`ArtLibrary.hero_tex` → `assets/art/characters/hero_lanzhou_wei.png` 32×32 + 3 色弱变体；英雄须暖色友军标记（基线 §6.3），**英雄主视觉仍走原创路线**（ASSET_CATALOG §9.1 附注） |
| 装置/地标 | **device_c03_lighthouse**（灯塔）+ **phase_c03_beacon_failure**（暮潮装置失效、英雄修复相位） | ❌ 缺口；灯塔亮/灭双态呼应 Result 视觉语言（基线 §7）；C03 地标 = 灯塔本身（基线 §5 每关一个可复述地标） |
| 投射物 | echo_pile 的脉冲弹 + 既有塔复用 | ❌ 缺口 |
| 状态效果 | armor_break（破甲，对应 rust_armor_carrier 出场波） | ❌ 缺口；可从已入库 explosion/sparks 派生 |
| BGM | 第一章 Boss/紧张主题 | 候选 MU-004（PPEAK，CC-BY 4.0，**需署名**） |

## 3. 可用素材库存（直接取用，不必重新爬）

`assets/vendor/hunt/` 下已入库（许可状态以各猎手报告为准）：

| 包 | 路径 | 许可 | C03 可用点 |
|---|---|---|---|
| Archer Towers（7 级升级链 + idle/attack） | `itch/14_archer_towers/` | CraftPix 免费版（须保留 Credit.txt） | echo_pile 结构参考；**注意 CraftPix 许可不在 CC0/CC-BY 白名单，使用前需主理人确认** |
| Field Enemies（4–6 种俯视敌人） | `itch/18_field_enemies/` | CraftPix 免费版 | lamp_leech / tide_back_navigator 造型参考（同上许可注意） |
| 11 Free Explosions | `itch/28_11_free_explosions/` | CraftPix 免费版 | armor_break / 灯塔爆炸 VFX |
| Coast Top-Down Tiles | `itch/09_coast_tiles/` | **无 LICENSE，待核** | 港岸地形；核实许可前不得接入 |
| Bomb-Imp（4 方向 + 爆炸） | `itch/33_bomb_imp/` | **无 LICENSE，待核** | 同上 |
| TD Towers + Projectiles（13 塔 64×64） | `itch/22_td_towers_proj/` | **无 LICENSE，待核** | 同上 |
| Ballista（128×128 拉弦动画） | `itch/13_ballista/` | **无 LICENSE，待核**（页面仅 "comes without outline"） | 样式极配针轨弩台；需联系作者 mythical-the-dev 确认许可后才可用 |
| Shark Pack（9 帧 64×64） | `itch/01_shark_pack/` | 自定义许可（可商用/可改/不署名/禁再分发/禁 NFT-AI，README 完整） | **侧视**，不可用于俯视战斗单位；可作简报/海报素材 |
| OGA 未用候选 | `oga-enemies/`（乌龟 64×64 CC0、海盗骷髅 CC-BY 等）、`oga-terrain/`（Buch 户外 CC0、水 tileset×3、Wesnoth 水波动画 CC0）、`oga-towers/`（pixel flame vfx 等） | 各见 `HUNT_REPORT_*.md` | 海龟→新甲壳敌；水动画→潮道；骷髅→后续章节 |
| CraftPix 官网三件套 | `craftpix/manual_required/`（**空**） | CraftPix 自定义 | 海底敌人/俯视军舰/魔法陷阱 VFX；需用户浏览器登录 craftpix.net 手动下载后放入该目录 |

## 4. 生产管线操作手册

### 4.1 派生管线（美术）

```bash
python tools/build_sourced_assets.py   # 幂等；改动后重跑即可，末尾自检色弱变体与基底 SHA 差异
```

- 扩展方式：在 `SRC` 归因表（`tools/build_sourced_assets.py:34`）登记新来源（path/title/author/license），照 `build_c02_*` 函数模式新增 builder，输出到 `assets/art/...` 并写入对应 `DERIVED_MANIFEST.json`（SHA-256 + source 归因）。
- 像素铁律：只准整数倍 NEAREST 缩放；对齐尺寸优先裁切/居中/补透明边；敌人冷青灰 + 深色轮廓，己方暖珊瑚/余烬高光（`tools/pixel_v2.py` 的 `PAL` 色板）。
- 色弱变体：必须用 `pixel_v2.remap(im, preset)`（与运行时 `UiPalette.apply` 同矩阵）；**调色须落到 PAL 色板并预埋矩阵触发色**（暖点触发 protan/deutan、冷青点触发 tritan），否则变体与基底同 SHA——2026-09-08 前的旧资产就踩过这个坑，脚本末尾自检会 WARNING。
- 通用敌人/塔单帧：`assets/art/enemies|towers/` 32×32，用脚本里的 `down2_bright`（2×2 取最亮像素）降采样保轮廓。

### 4.2 Godot 验证（可执行文件 `D:\mydev\games\Godot_v4.7.2-stable_win64_console.exe`）

```bash
# 改过 PNG 后必须重导入
Godot --headless --path . --editor --quit
# 数据与单测（必须全绿）
Godot --headless --path . --script tools/validate_data.gd
Godot --headless --path . --script tools/run_tests.gd
# smoke（自动布防跑全程，输出 out/m3_<level>_smoke_speed3.0.json）
Godot --headless --path . -- --level=level_c03 --m3-smoke
# 截图（--shot-at-wave 需窗口模式；参数细节见 scripts/boot/main.gd:1580-1610）
Godot --path . -- --level=level_c03 --shot-at-wave=2 --m0-screenshot=out/c03_battle.png
# C01 资产校验器（hash/证据/许可链）
python tools/validate_c01_assets.py
```

### 4.3 接入顺序建议

1. 新敌人/塔/VFX 派生 → 重导入 → smoke + 截图目检（方向、比例、朝向：侧面帧一律朝左/朝右依现有代码约定，C01 侧帧朝左由代码 flip）
2. 更新 `ASSET_LICENSE_LEDGER.csv`（status 按生命周期，hash 实测）→ `ART_ASSET_REGISTRY.csv` → `docs/current/art/CREDITS.md`
3. 证据归档 `docs/evidence/c03/`，参照 c01/c02 的 VERIFICATION.md 格式

## 5. 合规红线速查

- **白名单**：CC0、CC-BY、OGA-BY、SIL OFL（字体）、措辞完整的自定义免费商用许可（需逐条可读）
- **黑名单（v1.0 不采用）**：CC-BY-SA、CC-BY-NC、GPL、"public license" 等模糊措辞、无许可徽标/待核
- **署名必需（必须进 CREDITS + 游戏内致谢）**：Sevarihk & tapatilorenzo（CC-BY 4.0）、bluecarrot16（CC-BY/OGA-BY 3.0）、Clint Bellanger（CC-BY 3.0）、Jetrel / Frogatto（CC-BY 3.0）
- **Jetrel 案经验**：OGA 页面元数据标 CC0，作者正文更正为 CC-BY 3.0——**一律以作者正文声明为准**，抓页面时连正文声明一起存档到 `licenses/sources/<asset_id>/LICENSE.txt`
- 台账流程见 ASSET_CATALOG §12：Research→Proposed→Approved（主理人）→Implemented→Verified（主理人+外部测试者）→Shipping，**不得跳级**

## 6. 已知遗留（不影响 C03 开工，但别踩）

1. C02 简报左侧地图仍复用 C01 `briefing_map.png`（`docs/evidence/c02/VERIFICATION.md` 已记录）
2. `harbor_props.png` 第 6/7 格（小船/舵轮）仍为 v2 自绘（LPC 包无合适源）
3. vfx 色弱变体文件已生成但运行时 `ArtLibrary.vfx_tex` 不消费（备而不用）
4. Ballista 弩炮样式优于现炮头，许可待作者 mythical-the-dev 确认
5. itch.io 需本地代理 `127.0.0.1:10808`（SOCKS5）才可达；craftpix.net 页面可达但 ZIP 下载有登录墙
