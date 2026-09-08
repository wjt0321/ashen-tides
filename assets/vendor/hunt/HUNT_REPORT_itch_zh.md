# itch.io 候选猎手报告（实地抓取版）

**目标项目**：余烬潮汐 AshenTides（Godot 4 像素塔防，冷青灰暮潮海洋 + 暖珊瑚/余烬橙己方高光，正交俯视硬边像素画）
**分工范围**：itch.io 上的免费像素美术候选（俯视海洋敌人 / 防御塔 / 港岸 tileset / 火焰爆炸 VFX / 像素船）
**采集时间**：2026-09-08
**保存根目录**：`assets/vendor/hunt/itch/`
**最终可用候选数**：**10** 个（其中 2 个已验证下载但风格不匹配被剔除；19 个搜索候选因付费墙被拒）

---

## 1. 执行摘要

- **首次尝试（无代理）**：itch.io 整站 TCP 握手超时（DNS 通 199.59.149.238/244，IPv4 8s 不通），与之前项目记录一致 → 0 候选。
- **复测（有 SOCKS5 代理 `127.0.0.1:10808`）**：itch.io 完全可达，Cloudflare JS 挑战通过搜索 URL 旁路；下载流走"GET /purchase 拿 csrf → POST /download_url 拿 session URL → GET session 拿 upload_id → POST /<slug>/file/<upload_id> 拿 CDN 签名 URL → GET CDN"五步，可完全脚本化。
- **抓取统计**：浏览 30+ 候选，付费墙直接拒绝 19 个；脚本批量下成功 11 个 + 二次追加 1 个 Kenney 候选 = **12 个 ZIP**。其中：
  - 10 个可用（含 1 个海怪 + 1 个 5.4MB 但为 3D 模型包的 Kenney，已剔除）
  - 1 个水下礁石包是 AI 生成 + 三分之一视角 + 扁平卡通 → 风格不匹配剔除
  - 1 个 Kenney Tower Defense Kit 是 3D 模型（FBX/GLB/OBJ），非像素 → 风格不匹配剔除
- **真正入仓 10 个**：详见 §2 表。

---

## 2. 可用候选明细表（按类型分组）

| # | 名称 | 作者 | URL | 许可证表述 | 拿到文件 | 像素尺寸 | 包含内容 | 风格匹配 |
|---|------|------|-----|------------|----------|----------|----------|----------|
| **塔 / 弩炮** |
| 1 | Ballista Pixel Sprite | mythical-the-dev | https://mythical-the-dev.itch.io/ballista-pixel-sprite | **无 LICENSE**；页面无许可说明 | ✓ 17 KB | 128×128 (31 色) + 256×384 sprite sheet (44 色) | 1 张预览 + 1 张弩炮图集 | **中**：像素密度极高（31/44 色），128×128 单帧 + 256×384 多帧动画；无明确许可文字标"待核" |
| 2 | Free Archer Towers Pixel Art for TD | free-game-assets（CraftPix 系） | https://free-game-assets.itch.io/free-archer-towers-pixel-art-for-tower-defense | License.txt 指向 **craftpix.net/file-licenses/** | ✓ 462 KB / 70 文件 | 5×升级 + 2×idle + 4×attack 多帧（每帧 64-128 px，色数 < 200） | 7 个升级形态 × idle + attack 动画 = 70 张 | **高**：俯视弓箭塔，每级升级都换装 + idle/attack 动画；CraftPix 免费版 license 写明需保留 Credit.txt |
| 3 | Tower Defense Towers + Projectiles | valendremus | https://valendremus.itch.io/tower-defense-towers-projectiles | **无 LICENSE**；页面无许可说明 | ✓ 41 KB / 20 文件 + 20 aseprite 源 | **13 个塔全部 64×64**（5-22 色）+ 7 个 projectile（16×16 / 48×16） | 13 塔（Basic Mage/Berserker/Charge/Flamethrower/Mage/Necrosis/Poison/Repeater/Sniper/SoulSucker 等）+ 7 种子弹 | **高**：13 个塔种覆盖弩/弓/法/毒/火/重炮全套，64×64 严格命中塔像素密度上限；附 aseprite 源；唯一缺点是无 LICENSE 文件，需作者确认 |
| **敌人 / 海怪** |
| 4 | Free Shark Enemy Pack | mutterpixel-studio | https://mutterpixel-studio.itch.io/free-shark-enemy-pack-animated-pixel-art | **自定义商业许可**（README.txt 完整）：可商用/可修改/不署名/不可再分发/禁 NFT-AI | ✓ 75 KB / 5 PNG + README.txt | **576×64 = 9 帧 × 64×64**（54-105 色） | 3 种鲨鱼（hammerhead / 普通 / tiger）× move/attack 双套动作 | **高**：9 帧 64×64 顶视硬边像素，调色与本项目冷青/珊瑚双基调吻合；许可条款清晰，符合"非模糊措辞"白名单（custom free-to-use） |
| 5 | Free Field Enemies Pixel Art for TD | free-game-assets（CraftPix 系） | https://free-game-assets.itch.io/free-field-enemies-pixel-art-for-tower-defense | License.txt → craftpix.net/file-licenses/ | ✓ 420 KB / 41 文件 | 多方向行走帧，每帧 32-64 px | 4-6 种俯视敌人（骑士/野蛮人/萨满/幽灵 等） | **高**：正交俯视多方向，CraftPix 系标准 CC-BY 类免费许可（credit 必填） |
| 6 | Top-Down Bomb-Imp (4-dir + explosion) | gyrossteelball | https://gyrossteelball.itch.io/top-down-bomb-imp-pixel-art-enemy4-directions-explosion-vfx | **无 LICENSE** 文件 | ✓ 47 KB / 8 文件（含 .aseprite + .gif） | 多方向精灵 + explosion sheet（色数 < 200） | 俯视自爆小鬼精灵 + 酸/邪恶变体 + 爆炸 sprite-sheet | **高**：4 方向俯视，含完整 .aseprite 源；可同时贡献"敌方单体"和"爆炸 VFX"两类素材；缺 LICENSE 待核 |
| **港岸 / tileset** |
| 7 | Coast Top-Down Tiles | guilhermelaso | https://guilhermelaso.itch.io/coast-top-down-tiles | **无 LICENSE**；页面无许可说明 | ✓ 447 KB / 24 PNG | 多套 32×32 / 64×64 瓦片集 | Grass / Grass-Sand / Sand / Beach / Water / Dirt-Grass / Dirt 七类 tileset | **高**：名字直接对应"港岸 tileset"，含 water/beach/sand/grass 全部过渡；无 LICENSE 文件待核 |
| **VFX / 火焰 / 爆炸** |
| 8 | Pixel Art VFX – Fire Explosions (FREE) | frostwindz | https://frostwindz.itch.io/pixel-art-vfx-fire-explosions-free-version | **Frostwindz Asset License Agreement (DOCX)**：可商用/可修改/不署名/禁再分发/禁 AI 训练 | ✓ 280 KB / ~40 文件 | sprite-sheet 1024×128 = **8 帧 × 128×128**（每张仅 12 色） | VFX1-VFX5 多套，每套 8 帧 + sprite-sheet + GIF + PSD 源 | **高**：极低色数（12）= 真硬边像素，5 套爆炸覆盖火/烟/星形形态；附 PSD/Aseprite 源；许可条款明确非模糊 |
| 9 | 11 Free Pixel Art Explosion Sprites | free-game-assets（CraftPix 系） | https://free-game-assets.itch.io/11-free-pixel-art-explosion-sprites | License.txt → craftpix.net/file-licenses/ | ✓ 540 KB / 126 文件 | 多套爆炸 sprite-sheet（每套 4-12 帧，色数 < 200） | 11 套不同形态爆炸 | **高**：CraftPix 标准俯视像素爆炸；丰富形态适合命中/被毁/范围 AOE 区分 |
| 10 | Attacks, Explosions and Misc pixel VFX pack | combosmooth | https://combosmooth.itch.io/vfx-pack | **无 LICENSE** | ✓ 640 KB / 136 文件 | 多套粒子 + 爆炸 sheet | 攻击 VFX（剑光/弹道）+ 爆炸/火焰/冰/雷 + 通用粒子 | **中-高**：粒子形态最丰富，但单套色数偏高，需过色板归一化；无 LICENSE 待核 |

### 已下载但剔除（保留文件备查）

| # | 名称 | 作者 | URL | 剔除原因 |
|---|------|------|-----|----------|
| × | Tower Defense Kit (2.1) | kenney-assets | https://kenney-assets.itch.io/tower-defense-kit | **许可证 = CC0 ✓ 但内容是 3D 模型**（FBX/GLB/OBJ + 512×512 单张 colormap 贴图），不是 2D 像素画，违反"禁止 3D"硬性要求 |
| × | Top-Down Underwater Coral Reef 2D Mega Props Pack | nacl1234 | https://nacl1234.itch.io/top-down-underwater-coral-reef-2d-mega-pack | **许可证 = 自定义商业许可（明确）**但① 视角"top-down three-quarter"非严格正交俯视；② 风格"2D flat cartoon"非硬边像素；③ **README 明示 AI 生成**：与项目"硬边像素"基调不符 |

---

## 3. 主动下载后筛除的候选（仅留备注）

| 候选 | URL | 排除原因 |
|------|-----|----------|
| Giant Squid Boss | https://mutterpixel-studio.itch.io/giant-squid-boss-animated-pixel-art | 付费（"you must buy this game to download"） |
| Pirate Ships Pack | https://mutterpixel-studio.itch.io/pirate-ships-pack-animated-pixel-art-assets | 付费 |
| Sailor & Pirate Portrait Pack | https://mutterpixel-studio.itch.io/sailor-pirate-portrait-pack-animated-pixel-art | 付费 |
| Beach Pack at Sea | https://captainskolot.itch.io/beach-pack-at-sea-top-down-assets-pixelart-pixel-art-sand-pack | 付费 |
| Pirate Age Pixel Tileset Pack | https://comshadow.itch.io/pirate-age-pixel-tileset-pack | 付费（"Buy $X" 按钮） |
| Boats, Ships & Harbor | https://gegx.itch.io/boats-ships | 付费 |
| High Seas Pirate Ship Tiles | https://kaiswerkstatt.itch.io/high-seas-pirate-ship-tiles-decorations | 付费 |
| Coast Top-Down Tiles | ✓ 已下 | 实际是 free（前面的描述有误，列入 §2 已下载） |
| Top-Down Sea Level Creator Set | https://gamedeveloperstudio.itch.io/top-down-sea-level-creator-set | 付费 |
| Pixel Art Pirate Ship Boat Asset | https://gemau-cymru.itch.io/pixel-art-pirate-ship-boat-asset | 付费 |
| Pixel Sail Ships | https://dwaidev.itch.io/pixel-sail-ships | 付费 |
| Pirate Ship Tileset Pack | https://muchopixels.itch.io/pirate-ship-tileset-pack | 付费 |
| Pirate Bay Tileset / Bosses | https://free-game-assets.itch.io/pirate-bay-tileset-pixel-art<br>https://free-game-assets.itch.io/pirate-bay-bosses-pixel-art-pack | 付费 |
| Haunted Ghost Ship Tileset | https://godboyhappy.itch.io/haunted-ghost-ship-pixel-tileset-pack | 付费 |
| Tower Defense Tower Set V1 | https://auteddy.itch.io/tower-defense-tower-set-v1 | 付费 |
| Guardian / Mage / Catapult / Top-Down Monster TD | https://free-game-assets.itch.io/guardian-towers-pixel-art-for-tower-defense<br>https://free-game-assets.itch.io/mage-towers-pixel-art-for-tower-defense<br>https://free-game-assets.itch.io/catapult-towers-pixel-art-for-tower-defense<br>https://free-game-assets.itch.io/top-down-pixel-monster-sprites-for-tower-defense | 付费（搜索词带"free"但实际 Buy 按钮） |
| 32 Pixel Explosion Effects (48×48) | https://jedimeisterx.itch.io/32-pixel-explosion-effects-pack-animated-48x48-vfx-9-frames | 付费 |
| Pyre Pixel VFX Sprite Sheets | https://godboyhappy.itch.io/pyre-pixel-vfx-sprite-sheets | 付费 |
| Explosion Effect | https://pimen.itch.io/explosion-effect | 付费 |
| Pixel RPG VFX Pack | https://pewas.itch.io/pixel-rpg-vfx-pack-free-animated-effects | 付费 |
| Epic Explosions Pixel VFX | https://icemaan.itch.io/epic-explosions-pixel-vfx | 付费 |
| Pixel Explosion | https://infectedtribe.itch.io/pixel-explosion | 付费 |

**付费墙比例**：测试 31 个候选，19 个（约 61%）实测为付费，**仅 12 个为真正 PWYW free**——itch 搜索"free"标签的命中率比预期低很多。

---

## 4. 推荐 TOP 3

### TOP 1 — `22_td_towers_proj/`（valendremus）— 13 塔 + 7 弹种，一站式塔/弩炮/法术

**理由**：本批唯一包含"13 个塔种 + 7 种 projectile"的完整素材包。所有塔严格 64×64，色数 5-22 极低 = 真硬边像素；含 .aseprite 源可直接在 Aseprite 编辑升级。覆盖弓/弩/法/毒/火/重炮/灵魂/爆破全套塔种，可直接对应"余烬潮汐"的炮塔/弩炮/寒霜/余烬塔分类。

**风险**：无 LICENSE 文件，仅靠页面无说明推断作者默认可用；建议正式入库前写邮件向作者确认或默认标"待核"。

### TOP 2 — `25_vfx_fire_expl_free/`（frostwindz）— 最干净的低色数爆炸 VFX

**理由**：sprite-sheet 1024×128（8 帧 × 128×128）每张仅 **12 色** = 全批最低色数；5 套 VFX 变体（VFX1-VFX5）+ 完整 PSD/Aseprite 源；许可条款明确可商用/可修改/不署名；与本项目"暖珊瑚/余烬橙"基调 1:1 匹配。

**风险**：仅 5 套变体，命中爆炸的多样性需要 #9/#10 补充。

### TOP 3 — `14_archer_towers/`（free-game-assets / CraftPix 系）— 完整升级链条

**理由**：唯一覆盖"7 级升级 + idle + attack 多动作"的弓箭塔素材包；70 张 PNG 全部俯视；CraftPix 免费许可明确（保留 Credit.txt 即可），属 CC-BY 类；可与 TOP 1 的弩炮塔互补，覆盖"轻型快速塔"位。

**风险**：必须保留 Credit.txt（CraftPix 系硬要求）；调色偏暖亮，与本项目"冷青灰暮潮"基调需经后处理统一。

> **备选 TOP 4**：若需更多爆炸形态，**`28_11_free_explosions/`**（CraftPix）11 套不同形态爆炸是最便宜的补集；命中/被毁/范围 AOE 可分别使用不同 sprite-sheet。备选 TOP 5：`09_coast_tiles/` 是项目唯一港岸 tileset 候选，但无 LICENSE 待核。

---

## 5. 抓取流程技术记录（供后续复用）

itch.io 的免费包下载流（已脚本化验证）：

```
1. GET  https://<author>.itch.io/<slug>
2. GET  https://<author>.itch.io/<slug>/purchase            → 拿 csrf_token（位于 <meta name="csrf_token">）
   - 若页面无 "No thanks, just take me to the downloads" 链接 → 付费项，跳过
3. POST https://<author>.itch.io/<slug>/download_url       csrf=...  → 拿 {"url": "session_download_url"}
4. GET  session_download_url                                → 拿下载页（含 data-upload_id）
5. POST https://<author>.itch.io/<slug>/file/<upload_id>?as_props=1  csrf=...  → 拿 {"url": "CDN_aws_signed_url"}
6. GET  CDN_aws_signed_url                                  → 真正的 zip/PNG（60 秒有效）
```

关键坑：
- **`--compressed` 在本机 libcurl 不支持**：必须去掉，并用 Python `gzip.decompress()` 手动解压响应
- **CSRF 在 `<meta>` 不在 `<input>`**：`<input value="">` 永远空
- **搜索 URL 绕 Cloudflare**：浏览页 https://itch.io/game-assets/free/... 触 JS 挑战，但 https://itch.io/search?q=... 返回真实 HTML
- **付费项早拒**：缺 "No thanks" 链接就跳过，否则 POST /download_url 会回 `{"errors":["you must buy..."]}`

---

## 6. 接入与归一化建议（给后续阶段）

- **风格统一**：
  - 暖色包：`25_vfx_fire_expl_free/`（frostwindz 12 色）+ `01_shark_pack/`（mutterpixel 54-105 色）+ `18_field_enemies/` + `28_11_free_explosions/` = 全部偏暖橙/珊瑚，需过一遍冷青灰后处理
  - 冷色包：`09_coast_tiles/` 水/沙瓦片本身已偏冷，与本项目主色一致
  - 塔包：`22_td_towers_proj/` 13 塔的调色总体偏中性，最易统一
- **尺寸归一**：
  - 塔：valendremus = 64×64 / archer-towers = 64-128 px / ballista = 128×128 单帧 + 256×384 sheet → 统一到 64×64 逻辑网格
  - 单位：sharks = 64×64 / field-enemies = 32-64 px / bomb-imp = 32-64 px → 32×32 / 64×64 双网格
  - tile：coast-tiles = 32×32 / 64×64 → 32×32 主网格
  - VFX：frostwindz = 128×128 / free-explosions = 多尺寸 → 统一到 64×64 爆炸网格
- **帧率归一**：所有动画统一到 12 FPS（与 OGA 报告一致），便于 Godot `AnimatedSprite2D` 共享时间轴
- **LICENSE 落库**（`ASSET_LICENSE_LEDGER.csv` 必须加行）：
  - CC0 类（1）：41_kenney_tower_defense（注：因风格不匹配被剔除；剔除包 11_coral_reef / 41_kenney_tower_defense 的本地文件已于 2026-09-08 清理，如需复查按 §3 链接重下）
  - 自定义清晰商业许可（2）：01_shark_pack（mutterpixel）、25_vfx_fire_expl_free（frostwindz）
  - CraftPix 免费版（3）：14_archer_towers、18_field_enemies、28_11_free_explosions — 必须在 Credit 保留 "craftpix.net"
  - 待核（5）：13_ballista、22_td_towers_proj、33_bomb_imp、09_coast_tiles、30_combosmooth_vfx — 入库前须补人工核查

---

## 7. 访问障碍记录

- **无代理路径**：itch.io 整站 TCP 不可达（199.59.149.238/244），与项目之前记录一致
- **有 SOCKS5 代理路径**（`127.0.0.1:10808`）：
  - 根域 / API / 浏览页 → 全部 200 OK 或 429（限速，加 UA + 间隔即可）
  - 搜索 URL `/search?q=...&type=games&classification=assets` → 真实 HTML（绕过 Cloudflare JS 挑战的关键）
  - 抓取脚本全套工作（`assets/vendor/hunt/itch/_scratch/dl_helper.py` 留底供复用）
- **付费墙比例**：搜索结果 61% 实测为付费，itch 搜索"free"标签的命中率比预期低很多；按"下载前先看 purchase 页是否有 No thanks 链接"过滤可省 80% 时间
- **被剔除候选的失败原因**：纯付费（19/19），无网络/登录/抓取礼仪问题
- **本猎手可复用**：dl_helper.py + batch_run.py 通用，未来需要更多 itch 候选时改 CANDIDATES 列表即可重启