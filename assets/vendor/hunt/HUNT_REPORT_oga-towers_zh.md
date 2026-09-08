# OGA 塔与特效候选猎手报告

**目标项目**：余烬潮汐 AshenTides（Godot 4 像素塔防，冷青灰暮潮海洋 + 暖珊瑚/余烬橙己方高光，正交俯视硬边像素画）
**分工范围**：opengameart.org 上的俯视像素炮塔/弩炮/防御塔素材，以及像素火焰/爆炸 VFX
**采集时间**：2026-09-08
**保存根目录**：`assets/vendor/hunt/oga-towers/`
**最终候选数**：6（位于任务要求的 4–6 区间内）

---

## 1. 筛选流程与硬性规则

- **视角/画风白名单**：正交俯视（top-down）、硬边像素画（pixel art）、32–96 px 像素密度
- **拒绝项**：平滑矢量、3D 渲染、厚涂、卡通扁平、等距视角、超大像素
- **许可证白名单**：CC0 / CC-BY / OGA-BY（OGA-BY 与 CC-BY 等同允许）
- **许可证拒绝项**：CC-BY-SA、CC-BY-NC、GPL、无明确声明
- **抓取礼仪**：顺序 GET，间隔 ≥ 1.5 s；只下载筛选后的真实候选包，不整站镜像
- **下载方式**：`curl -sL --max-time 120 -A "Mozilla/5.0"`；ZIP 用 `unzip` 解开，7z 用 `py7zr`；用 `python + PIL` 校验像素尺寸和色数（< 200 色 ≈ 真像素画）

补充搜索关键词：`tower defense pixel`, `turret pixel top down`, `cannon pixel art`, `ballista`, `pixel fire animation`, `pixel explosion`, `cannon pixel`, `siege weapons`, `flame CC0`。

---

## 2. 候选明细表

| # | 名称 | 作者 | URL | 许可证 | 本地路径 | 像素尺寸 | 包含内容 | 风格匹配 |
|---|------|------|-----|--------|----------|----------|----------|----------|
| 1 | Pixel Turret Animation | zerohero | https://opengameart.org/content/pixel-turret-animation | CC0 | `01_pixel_turret_animation/` | 单帧 54×47 px（部署帧 432×47 = 8 帧） | 5 张 PNG：base 静止/部署 8 帧/炮塔头射击 6 帧+空闲 5 帧/高光层 | **高** — 正交俯视、硬边像素、造型像海防炮台；像素密度略低于 64 px，但放大或贴两层不影响 |
| 2 | Animated Fire（已知候选） | benhickling | https://opengameart.org/content/animated-fire | CC0 | `04_animated_fire/` | 8 张 640×384（每张 10×6 = 60 帧 × 64×64） | 8 个独立火苗动画形态（fire1–fire8），总 480 帧 | **高** — 64×64 完全符合目标像素密度；暖橙/珊瑚调色与本项目"余烬高光"主题高度契合 |
| 3 | Pixel Explosion (12 Frames) | （OGA 用户 2dpixx / ajmeyer 社区） | https://opengameart.org/content/pixel-explosion-12-frames | CC-BY 3.0 | `05_pixel_explosion_12_frames/Explosion_2.png` | 1152×96（12 帧 × 96×96） | 单条爆炸 12 帧 | **高** — 96×96 球状像素爆炸，每帧仅 8 色硬边像素，正好匹配炮塔/弩炮命中爆点 |
| 4 | Sparks (Fire, Ice, Blood)（已知候选） | Clint Bellanger | https://opengameart.org/content/sparks-fire-ice-blood | CC-BY 3.0 | `06_sparks_fire_ice_blood/sparks.png` | 256×384 | 3 套粒子 × 各 3 帧 = 9 个粒子形态（血、火、冰），PNG + 原始 .blend 源 | **高** — 小颗粒火花，硬边像素，可直接用 Godot `GPUParticles2D` 拆帧；蓝色冰颗粒正好补充本项目"冷青"调色 |
| 5 | Pixel Flame VFX | zonked / megupets（用户页面） | https://opengameart.org/content/pixel-flame-vfx | CC0 | `09_pixel_flame_vfx/` | fire-a 168×62 / fire-b 294×77 / fire-c 245×67 / fire-d 144×54（每行 7 帧） | 4 套独立火苗动画（共 28 帧） | **高** — 顶视硬边像素火苗，调色更接近本项目"珊瑚/余烬"；可作塔顶点火、闸门火盆、炮弹尾焰 |
| 6 | Explosion Animations | dvh / b3l7 / artificialintelligence | https://opengameart.org/content/explosion-animations | CC0 | `11_explosion_animations/explosion3.png` | 480×362（5×3 网格 ×96 px） | 5 种形态爆炸（球/十字/环/烟等）各 6 帧 | **高** — 全图仅 9 种硬边像素色，多种爆炸变体（球状、十字、星形、烟状）正好覆盖不同塔种命中效果 |

---

## 3. 主动下载后筛除的候选（仅留备注，便于其他人复审）

| 候选 | URL | 排除原因 |
|------|-----|----------|
| Towers of Defense | https://opengameart.org/content/towers-of-defense | 许可证 CC0 ✓，但 `towers_of_defense.png` 是**等距视角**（isometric），违反正交俯视硬性要求 |
| Pixel Art Cannon and Artillery (LPC) | https://opengameart.org/content/pixel-art-cannon-and-artillery-lpc | OGA-BY 4.0 ✓，共 22 个炮种；全部为**侧视**（side view），不能用于俯视塔防 |
| Animated Fireball | https://opengameart.org/content/animated-fireball | CC-BY 3.0 ✓，但主图 `fireball.png` 为软边 painterly，7z 内 `pixart explosion/` 帧质量也一般 |
| 2D Explosion Animations (Ace Bennett) | https://opengameart.org/content/2d-explosion-animations-frame-by-frame | CC0 ✓，但 4096×4096 单图、64 帧实为软边平滑渐变，单帧测出色数远超像素画范围 |
| Ballista | https://opengameart.org/content/ballista | CC-BY 3.0 ✓，但 `pieces/bow.png` 等为**侧视**（side view）平滑矢量风格 |
| Fire Wrath – Magic Effect | https://opengameart.org/content/fire-wrath-magic-effect | CC0 ✓，但每帧约 2937–5153 色，软边 painterly，**不是**像素画 |
| Siege Weapons / LPC Siege Weapons | https://opengameart.org/content/siege-weapons， /lpc-siege-weapons | 同时存在 CC-BY-SA 4.0 + GPL 3.0，许可证不通过 |

---

## 4. 推荐 TOP 3

### TOP 1 — `04_animated_fire/`（CC0, benhickling）
**理由**：64×64 px 严格匹配项目塔/单位像素密度；8 套共 480 帧火焰形态，调色本身已偏向暖橙/珊瑚/余烬，几乎"开箱即用"。可同时承担：①塔顶余烬高光、②炮弹尾焰、③被毁塔残骸着火、④闸门火盆。CC0 商用友好，无署名义务。

### TOP 2 — `01_pixel_turret_animation/`（CC0, zerohero）
**理由**：本次搜索中**唯一**明确俯视、带完整生命周期（部署 8 帧 → 射击 6 帧 → 空闲 5 帧）的炮塔素材。底座可复用为"防御塔/弩炮"底盘，炮头射击动画天然契合本项目弩炮/火炮攻击循环。唯一缺点是单帧 54×47 略小于 64 px 目标线，工程上放大 1.25× 或贴 1 张装饰掩体即可对齐网格。CC0。

### TOP 3 — `06_sparks_fire_ice_blood/`（CC-BY 3.0, Clint Bellanger）
**理由**：唯一同时提供**暖（火）+ 冷（冰）+ 中性（血）** 调色的粒子包，恰好覆盖本项目**冷青灰海洋 vs 暖珊瑚己方高光**的双调色体系：火色给己方塔命中，冰色给敌方寒霜塔命中，血色给物理系敌人溅血。9 张粒子帧可直接拆给 Godot `GPUParticles2D` 的 emission textures。需保留署名："Sparks by Clint Bellanger, CC-BY 3.0"。

> 备选：若需要更多爆炸形态，**TOP 4 → `11_explosion_animations/`**（CC0）一图包含 5 种爆炸变体；命中特效层次更丰富。

---

## 5. 接入与归一化建议（给后续阶段）

- 像素画色板基线已经匹配：暖色 3 包（animated-fire / pixel flame vfx / sparks-fire）与冷色 1 包（sparks-ice）天然互补；后期统一上冷青灰-暮潮后处理即可统一调性。
- 帧大小归一化建议：所有候选的"逻辑单位"统一到 64×64 px 网格，塔体可在 64×64 / 96×96 间二选一（54×47 的 turret 需轻微放大或加底座扩展到 64×64）。
- 许可证落库：CC-BY 3.0 项（`05_pixel_explosion_12_frames`、`06_sparks_fire_ice_blood`）必须在 `ASSET_LICENSE_LEDGER.csv` 加两行；CC0 项（其余 4 项）也建议登记以便审计。

---

## 6. 访问障碍记录

- opengameart.org 主站全程可访问，HTML 页面与 `/sites/default/files/...` 直连均无需登录。
- 已知被排除的 OGA 资源均因"内容不符"或"许可证含 SA/GPL"，非网络原因。
- 没有触发登录墙 / 反爬，本轮未触及 itch.io 等已知登录墙站点。
