# 塔防（像素俯视角）美术与音频资产调研草稿

- 调研日期：2026-09-04
- 目标项目：Godot 像素俯视角塔防，完整商业级原型/独立游戏（闭源商用发行）
- 许可优先级：CC0 > MIT / CC-BY / OGA-BY / OFL；**明确避开 CC-BY-NC、CC-BY-SA、GPL、来源/许可不明**
- 核实原则：所有条目均经联网核实（打开来源页或许可条款页）。个别条目受网络限制无法直接核实，已逐条标注。
- 推荐等级定义：**S** = 强烈推荐可直接商用；**A** = 推荐（需署名或有小注意点）；**B** = 可用但有明显注意点；**C** = 勉强/有风险。

---

## 0. 总体结论与推荐组合

**主推"真 16px 像素"组合（全 CC0 + 少量 CC-BY，可闭源商用）：**

| 类别 | 首选 | 备选 |
|---|---|---|
| 地形 | Kenney Tiny Dungeon（16×16, CC0） | Buch Outdoor 32×32（CC0）、rgsdev 16×16 模板（CC0） |
| 敌人 | 0x72 DungeonTileset II 怪物（CC0） | CraftPix 史莱姆（OGA-BY 3.0）、Camacebra 蜘蛛（公有级） |
| 塔 | Kenney Tiny Battle 炮台/车辆改作（CC0） | Nido Basic Towers（CC0）、zintoki Ground Shaker（CC0） |
| UI | Kenney Pixel UI Pack（CC0） | UI Pack – Pixel Adventure（CC0） |
| VFX | BenHickling Animated Fire（CC0） | Clint Bellanger Sparks（CC-BY 3.0）、Kenney Pixel Shmup 爆炸帧 |
| 字体 | Press Start 2P（OFL，标题）+ VT323（OFL，HUD 数值） | m5x7（CC0，待人工复核） |
| 音乐 | OGA CC0 chiptune 三件套 + PPEAK 13 曲包（CC-BY 4.0） | Kevin MacLeod（CC-BY 4.0） |
| SFX | Kenney Audio（CC0）+ SubspaceAudio 512 8-bit SFX（CC0） | Sonniss GDC 包（自有 EULA）、Freesound 精选 |

**已知内容缺口（需自绘或后续补源）：**
1. 严格俯视像素的"防御塔"素材整体稀缺——Kenney Tiny 系无专门塔、OGA 的塔多为非像素或等距视角。塔体建议自绘或用 Tiny Battle / Nido / zintoki 改造。
2. 中文字体：Press Start 2P / VT323 / m5x7 均无 CJK 字形；若游戏需中文界面，像素 CJK 字体需另行调研（不在本次范围）。
3. Kenney Tiny 系敌人动画帧有限，怪物动画多样性靠 0x72 包补充。

---

## 1. 地形 / Tileset

### 1.1 Kenney – Tiny Dungeon —— 推荐 S
- URL：https://kenney.nl/assets/tiny-dungeon
- 许可条款页：https://kenney.nl/support （全站 CC0 官方声明）
- 作者：Kenney｜许可：**CC0**｜可商用：是｜署名：不要求（可选 "Kenney"，**禁用 Kenney logo**）
- 格式：130× 独立 PNG，tile size **16×16**，附 Tiled 示例文件
- 风格：像素地牢/下水道，含墙体、地板、武器、物品、少量角色
- 适用：像素 TD 的地面/墙体/障碍 tileset（Godot TileMapLayer）
- 风险：无现成"塔"；怪物动画有限；中世纪题材若配现代单位需统一世界观
- 核实状态：✅ 已直接核实

### 1.2 Kenney – Tiny Town —— 推荐 A
- URL：https://kenney.nl/assets/tiny-town
- 作者：Kenney｜许可：CC0｜可商用：是｜署名：不要求
- 格式：130× PNG，tile size 16×16（town/overworld/map/pixel）
- 适用：主基地、家园区、城镇装饰
- 风险：内容清单未逐项公布，"路径拼接砖"有无需下载后核对
- 核实状态：✅ 已直接核实

### 1.3 Buch – Outdoor 32×32 Tileset（OpenGameArt）—— 推荐 S
- URL：https://opengameart.org/content/outdoor-32x32-tileset
- 许可条款页：https://creativecommons.org/publicdomain/zero/1.0/
- 作者：Buch｜许可：**CC0**｜可商用：是｜署名：无
- 格式：PNG tilesheet，**32×32** 正交俯视（草地/岩石/水体/树桩/标牌）
- 适用：草地/水体/岩石地表基础层，道路预留位叠路径瓦
- 风险：装饰元素偏少，需配道路/塔位瓦
- 核实状态：✅ 已直接核实（抓取页面 HTML 侧栏许可字段）

### 1.4 CDmir – Desert Tileset（OpenGameArt）—— 推荐 A
- URL：https://opengameart.org/content/desert-tileset-1
- 作者：CDmir｜许可：CC0｜可商用：是｜署名：无
- 格式：`desert_tileset32x32.png`，32×32
- 适用：第二关/沙漠关地形，与 Buch 绿地瓦同规格可切换关卡主题
- 风险：单一色系一套，扩张需自绘
- 核实状态：✅ 已直接核实

### 1.5 rgsdev – Free CC0 Top Down Tileset Template（itch.io + OGA 镜像）—— 推荐 A
- URL：https://rgsdev.itch.io/free-cc0-top-down-tileset-template-pixel-art （itch 页**未能直接核实**）；OGA 镜像 https://opengameart.org/content/free-cc0-top-down-tileset-template-pixel-art （已核实 CC0）
- 作者：Raphael Gonçalves（rgsdev）｜许可：**CC0**｜可商用：是｜署名：无
- 格式：PNG tileset，**16×16**，5 套配色变体
- 适用：顶视地图草地/路面/空地打底，16px 网格 TD 天然适配
- 风险：低保真模板风、无动画单位；商用版建议在其上叠装饰层
- 核实状态：⚠️ itch 页不可达（本环境 DNS 问题），经 OGA 镜像 HTML 许可字段核实

### 1.6 0x72 – 16×16 DungeonTileset II（itch.io）—— 推荐 S（兼作敌人来源，见 §2）
- URL：https://0x72.itch.io/dungeontileset-ii （itch 页**未能直接核实**）
- 作者：Robert Norenberg（0x72）｜许可：**CC0**（多份独立 GitHub 项目 CREDITS 原文印证）｜可商用：是｜署名：无
- 格式：PNG 图集，**16×16**，v1.7 起含 autotile
- 适用：地牢地形 autotile + 数十种怪物 + 陷阱/道具
- 风险：无炮塔类单位；题材偏暗需调色；itch 页未亲见，下载后以包内 license 文件为准
- 核实状态：⚠️ 间接核实（GitHub CREDITS 交叉印证，强度较高）

---

## 2. 敌人 / 角色

### 2.1 0x72 – DungeonTileset II 怪物集 —— 推荐 S
（条目同 1.6）骷髅/史莱姆等数十种怪物，直接充当敌人波次，CC0。

### 2.2 CraftPix – Slime Monster Pixel Art for Top-Down RPG（OpenGameArt）—— 推荐 A
- URL：https://opengameart.org/content/slime-monster-pixel-art-for-top-down-rpg
- 许可条款页：https://opengameart.org/content/oga-by-30-faq
- 作者：CraftPix.net 2D Game Assets｜许可：**OGA-BY 3.0**（= CC-BY 3.0 去掉反 DRM 条款）｜可商用：是｜署名：**要求**（作者名 + 许可链接；OGA 可自动生成 credits 文件）
- 格式：PNG spritesheet + GIF 预览，彩色俯视像素史莱姆含动画，多配色变种
- 适用：炮灰敌人波（史莱姆群）
- 风险：需纳入署名清单；为 CraftPix 商店免费品，页面上无附加条款（已核实）
- 核实状态：✅ 已直接核实

### 2.3 rileygombart – Animated Top Down Zombie（OpenGameArt）—— 推荐 B
- URL：https://opengameart.org/content/animated-top-down-zombie
- 作者：rileygombart｜许可：**CC0**｜可商用：是｜署名：无
- 格式：PNG 序列 + GIF；Spine 骨骼导出的俯视行走僵尸动画
- 适用：中后期近战敌人/尸潮波次
- 风险：Spine 平滑渲染**非硬边像素**，与 32×32 像素瓦混用需实测缩放融合度；无死亡动画
- 核实状态：✅ 已直接核实

### 2.4 Camacebra Games – Spider Pixel Art Pack 16×16（itch.io）—— 推荐 B
- URL：https://camacebra.itch.io/spider-pixel-art-pack-16x16 （itch 页**未能直接核实**）
- 作者：Camacebra Games｜许可：Public license（公有领域级，无需署名——搜索引擎索引的页面原文）｜可商用：是｜署名：无
- 格式：PNG 精灵帧，**16×16**，顶视/侧视蜘蛛，4 方向 idle(5帧)/move(4帧)，橙/紫双色
- 适用：爬行类小怪兵种，四方向行走帧适合 Godot 顶视寻路单位
- 风险：单一兵种；"Public license" 为非标准措辞，商用前建议人工复核 itch 页原文
- 核实状态：⚠️ 间接核实（搜索引擎索引原文摘录）

### 2.5 Kenney – Pixel Shmup（飞行敌人/弹丸）—— 推荐 B
- URL：https://kenney.nl/assets/pixel-shmup
- 作者：Kenney｜许可：CC0｜可商用：是｜署名：不要求
- 格式：128× PNG，tile size 16×16
- 适用：科幻向 TD 的飞行敌人、子弹、爆炸帧
- 风险：题材锁定科幻飞机；中古/地面战主题只取特效素材
- 核实状态：✅ 已直接核实

### 2.6 Kenney – Tower Defense (Top-Down) 敌人部分 —— 推荐 A（风格限定）
（条目同 3.1）包内含坦克/士兵/飞机敌人，但为扁平描边风而非严格像素。

---

## 3. 塔 / 防御单位

> ⚠️ **本类别是最大缺口**：严格俯视像素的现成"塔"在免费来源中稀缺，下列多为改造方案。

### 3.1 Kenney – Tower Defense (Top-Down) —— 推荐 A（扁平风路线时升 S）
- URL：https://kenney.nl/assets/tower-defense-top-down
- 许可条款页：https://kenney.nl/support
- 作者：Kenney｜许可：**CC0**｜可商用：是｜署名：不要求
- 格式：300× PNG（塔、敌人、地面/道路、投射物、粒子、HUD 数字一站式）
- 风格：2016 年扁平描边俯视风，**非严格像素**
- 适用：若接受扁平风则是最快完整 TD 原型方案；若坚持 16px 像素则画面与 Tiny 系违和
- 风险：风格与"像素"立项冲突；OGA 镜像正文被反爬挡住，内容细节建议下载后按目录核对
- 核实状态：✅ 已直接核实

### 3.2 Kenney – Tiny Battle —— 推荐 A（像素路线塔体改造首选）
- URL：https://kenney.nl/assets/tiny-battle
- 作者：Kenney｜许可：CC0｜可商用：是｜署名：不要求
- 格式：190× PNG，tile size 16×16（坦克/战车/步兵）
- 适用：炮台/车辆改作防御塔，步兵改作敌人；与 Tiny Dungeon/Town 同为 16px 可直混
- 风险：现代军事题材，配地牢奇幻需统一世界观；无"塔"命名素材，需自拼逻辑
- 核实状态：✅ 已直接核实

### 3.3 Nido – Tower Defence Basic Towers（OpenGameArt）—— 推荐 A
- URL：https://opengameart.org/content/tower-defence-basic-towers
- 作者：Nido｜许可：**CC0**｜可商用：是｜署名：无
- 格式：zip，1 塔身 + 3 炮塔形态（可当升级档位）
- 风险：作者称 "high resolution"——**可能非像素风**，下载后需目检；仅 4 个建筑
- 核实状态：✅ 已直接核实

### 3.4 zintoki – Ground Shaker（itch.io）—— 推荐 B
- URL：https://zintoki.itch.io/ground-shaker （itch 页**未能直接核实**；索引原文摘录明写 "Asset license, Creative Commons Zero v1.0 Universal"）
- 作者：zintoki｜许可：**CC0**｜可商用：是｜署名：无
- 风格：军事/坦克类顶视像素炮塔（标签含 Tower Defense/turret）
- 适用：直接充当一座顶视炮塔，省自绘塔基
- 风险：单体小包，升级态需自行改色扩展；质量未目测
- 核实状态：⚠️ 间接核实

### 3.5 bart – Towers of Defense（OpenGameArt）—— 推荐 B（视角不匹配，仅参考）
- URL：https://opengameart.org/content/towers-of-defense
- 作者：bart｜许可：CC0｜可商用：是｜署名：无
- 风格：**等距（isometric）像素**塔体，模块拼搭式
- 风险：与正投影俯视地图不匹配，通常不适配，仅作等距分支或风格参考
- 核实状态：✅ 已直接核实

---

## 4. UI

### 4.1 Kenney – Pixel UI Pack（750 assets）—— 推荐 S
- URL：https://kenney.nl/assets/pixel-ui-pack ；OGA 官方镜像：https://opengameart.org/content/pixel-ui-pack-750-assets
- 作者：Kenney｜许可：**CC0**｜可商用：是｜署名：不要求
- 格式：独立 9-slice PNG（30 张）+ spritesheet；社区导入参数 16×16 图块、margin 0、spacing 2
- 风格：真·复古像素 UI（面板/按钮/游标/血条/勾选框/滚动条），与像素地图同源同格
- 适用：HUD、商店、塔升级界面；Godot 中 9-slice 直接做 StyleBoxTexture
- 核实状态：✅ 已直接核实

### 4.2 Kenney – UI Pack – Pixel Adventure —— 推荐 S
- URL：https://kenney.nl/assets/ui-pack-pixel-adventure
- 作者：Kenney｜许可：CC0｜可商用：是｜署名：不要求
- 格式：500× PNG + spritesheet（2024 年发布）
- 风格：像素奇幻/冒险主题 UI（木质、卷轴、中世纪面板），密度比 Pixel UI Pack 精致
- 适用：幻想/中世纪主题 TD 的按钮/面板/HUD
- 风险：官网未标 tile size，多尺寸元素需对 16px 世界做缩放观感测试；科幻主题不匹配
- 核实状态：✅ 已直接核实

### 4.3 Kenney – UI Pack 2.0（扁平风备选）—— 推荐 S（扁平路线）
- URL：https://kenney.nl/assets/ui-pack
- 作者：Kenney｜许可：CC0｜可商用：是｜署名：不要求
- 格式：430+ PNG、spritesheet、矢量源文件；**附 2 款 CC0 TTF 字体 + 6 个 UI 音效**
- 适用：主菜单/设置/商店全套 UI 骨架（配扁平风路线）
- 核实状态：✅ 已直接核实

---

## 5. VFX / 特效

### 5.1 BenHickling – Animated Fire（OpenGameArt）—— 推荐 S
- URL：https://opengameart.org/content/animated-fire
- 许可条款页：https://creativecommons.org/publicdomain/zero/1.0/
- 作者：BenHickling｜许可：**CC0**｜可商用：是｜署名：无
- 格式：透明 PNG 序列/spritesheet，**64×64、60 帧**像素火焰
- 适用：火焰塔灼烧、熔岩陷阱、地图火源
- 核实状态：✅ 已直接核实

### 5.2 Clint Bellanger – Sparks (Fire, Ice, Blood)（OpenGameArt）—— 推荐 A
- URL：https://opengameart.org/content/sparks-fire-ice-blood
- 许可条款页：https://creativecommons.org/licenses/by/3.0/
- 作者：Clint Bellanger｜许可：**CC-BY 3.0**｜可商用：是｜署名：**要求**（作者名 + 许可名 + 许可链接）
- 格式：PNG，像素 4 帧 64×64 元素溅射（火/冰/血）
- 适用：塔弹命中火花、元素塔攻击命中特效
- 风险：仅有命中溅射，无弹道弹体；需署名
- 核实状态：✅ 已直接核实

### 5.3 Kenney – Particle Pack —— 推荐 B（配扁平风路线）
- URL：https://kenney.nl/assets/particle-pack
- 作者：Kenney｜许可：CC0｜可商用：是｜署名：不要求
- 格式：80× PNG，**512×512** 柔渲粒子贴图（**非像素**）
- 适用：爆炸/烟雾/能量光效，Additive 混合（Godot GPUParticles/CPUParticles）
- 风险：软边缘与 16px 硬像素违和；像素路线仅建议用于全屏辉光层
- 核实状态：✅ 已直接核实

---

## 6. 字体

### 6.1 Press Start 2P（Google Fonts）—— 推荐 S
- 来源页：https://fonts.google.com/specimen/Press+Start+2P （⚠️ Google Fonts 页面本环境未能直接打开；已通过官方仓库核实许可）
- 许可条款页（已核实）：https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/OFL.txt
- 作者：CodeMan38（Cody Boisclair）｜许可：**SIL OFL 1.1**（保留字体名 "Press Start 2P"）｜可商用：是
- 署名要求：随游戏分发 .ttf 时**必须附带版权声明与 OFL 文本**（Google Fonts 的 TTF 已内嵌 OFL，拷入即可满足）；游戏画面渲染出的文字不受 OFL 约束（OFL §5）；修改版字体不得使用保留字体名（§3）
- 格式：TTF（仅 Regular 400），8-bit 街机像素体
- 适用：游戏标题、波次播报、VICTORY/DEFEAT 强调文字
- 风险：**无 CJK 字形**；小字号可读性一般，正文不宜多用
- 核实状态：✅ 许可经官方仓库文件核实（specimen 页未直接打开）

### 6.2 VT323（Google Fonts）—— 推荐 A
- 来源页：https://fonts.google.com/specimen/VT323 （⚠️ 同上，经官方仓库核实）
- 许可条款页（已核实）：https://raw.githubusercontent.com/google/fonts/main/ofl/vt323/OFL.txt
- 作者：Peter Hull｜许可：**SIL OFL 1.1**｜可商用：是｜署名：同 6.1（随 .ttf 附带许可文本）
- 格式：TTF，**等宽** CRT 终端风像素字体（数字等宽，数值滚动不跳动）
- 适用：HUD 生命值/金币/波次数字、伤害数字、正文
- 风险：无 CJK；风格与 Press Start 2P 需区分使用
- 核实状态：✅ 许可经官方仓库文件核实

### 6.3 m5x7（Daniel Linssen / Managore）—— 推荐 B
- 来源页：https://managore.itch.io/m5x7 （⚠️ **未能直接核实**，itch.io 不可达）
- 佐证（已核实）：https://raw.githubusercontent.com/boringcactus/m5x7/master/README.md （声明 "the m5x7 font, is CC0 licensed"）
- 作者：Daniel Linssen｜许可：声明为 **CC0**｜可商用：是（按声明）｜署名：无强制
- 风格：5×7 点阵等宽极小像素字体
- 适用：极小尺寸正文/状态数字
- 风险：**上线商用前务必人工打开 itch 页复核 CC0 原文**；或改用 OFL 双字体方案规避
- 核实状态：⚠️ 间接核实（第三方仓库佐证）

---

## 7. 音乐 / BGM

### 7.1 Wolfgang_ – 8-bit cave loop（OpenGameArt）—— 推荐 S
- URL：https://opengameart.org/content/8-bit-cave-loop
- 作者：Wolfgang_｜许可：**CC0**｜可商用：是｜署名：无
- 格式：WAV（16.9MB）+ Famitracker .ftm / NSF 源文件（便于二次编曲）
- 风格：8-bit chiptune 洞穴/地下循环曲
- 适用：地下城/遗迹关卡、后期防守波次 BGM
- 核实状态：✅ 已直接核实

### 7.2 pmiller – Chiptune Battle Music（OpenGameArt）—— 推荐 S
- URL：https://opengameart.org/content/chiptune-battle-music
- 作者：pmiller｜许可：**CC0**（页面原文 "Free to use without attribution"）｜可商用：是｜署名：无
- 格式：无缝循环音频（循环点约 7.5 秒处）
- 适用：波次来袭/战斗状态短循环 BGM
- 风险：曲目很短，适合战斗层而非主旋律
- 核实状态：✅ 已直接核实

### 7.3 request – Rin's Theme（OpenGameArt）—— 推荐 S
- URL：https://opengameart.org/content/rins-theme-loopable-chiptune-adventurebattle-bgm
- 作者：request（request.moe）｜许可：**CC0**｜可商用：是｜署名：无强制（作者注明署名为加分项）
- 风格：可循环 chiptune 冒险/战斗主题，高速弹幕感
- 适用：关卡进行/据点攻防主循环，契合后期波次
- 风险：抓取中未显示文件清单，下载前确认容器格式；情绪偏激烈，不宜做菜单曲
- 核实状态：✅ 已直接核实

### 7.4 PPEAK / Preston Peak – Free Action Chiptune Music Pack「surpass your limits!」（OpenGameArt）—— 推荐 A
- URL：https://opengameart.org/content/free-action-chiptune-music-pack
- 许可条款页：https://creativecommons.org/licenses/by/4.0/
- 作者：PPEAK / Preston Peak｜许可：**CC-BY 4.0**｜可商用：是（页面原文 "Free For Commercial use!"）｜署名：**要求**（署名 "PPEAK" 或 "Preston Peak"，附 OGA 链接与 CC-BY 4.0 链接）
- 格式：13 首循环 chiptune（>20 分钟），MP3 320kbps + WAV 24bit，官方保证无缝循环，附淡出 extended 版
- 适用：Boss 主题、紧张波次、基地/主菜单 BGM 一站式
- 核实状态：✅ 已直接核实

### 7.5 Kevin MacLeod – incompetech 音乐库 —— 推荐 A（需署名，非 chiptune）
- 来源页：https://incompetech.com/music/royalty-free/music.html ；许可/署名规范页（已核实）：https://incompetech.com/music/royalty-free/faq.html 与 https://incompetech.com/music/royalty-free/licenses/
- 作者：Kevin MacLeod｜许可：**CC-BY 4.0**（另有付费免署名 Standard License）｜可商用：是
- 署名要求（FAQ 原文格式，放在 credits 屏）：
  ```
  Title Kevin MacLeod (incompetech.com)
  Licensed under Creative Commons: By Attribution 4.0
  https://creativecommons.org/licenses/by/4.0/
  ```
  剪辑/混编时须在 credits 写明哪部分是其原曲。
- 风格：电子/动作/悬疑/科幻（**非地道 chiptune**），需人工试听筛 loop 友好曲目
- 适用：上述 chiptune 不够用时的补充源
- 核实状态：✅ 许可页已直接核实；曲目级下载页未逐曲抓取（FAQ/索引行均标 CC-BY 4.0）

### 7.6 Kenney – Music Jingles —— 推荐 B（仅短音效，非 BGM）
- URL：https://kenney.nl/assets/music-jingles
- 作者：Kenney｜许可：CC0｜可商用：是｜署名：不要求
- 风格：8-bit 短 jingle（数秒级），85 文件
- 适用：胜利/失败/升级/布塔等事件短奏，不宜作主 BGM
- 核实状态：✅ 已直接核实

### 7.7 CodeManu – 8-bit Music Pack (Loopable)（OpenGameArt）—— 推荐 B（待复核）
- URL：https://opengameart.org/content/8-bit-music-pack-loopable
- 作者：CodeManu｜许可：推断 CC0（多次出现于 OGA CC0 集合），**但本次抓取未直接显示许可徽标**
- 内容：6 首无缝循环 8-bit 曲
- 风险：**下载前务必在页面复核许可徽标**，确认后升 S/A
- 核实状态：⚠️ 部分核实

---

## 8. SFX / 音效

### 8.1 Kenney Audio 系列 —— 推荐 S
- 来源页：https://kenney.nl/assets/category:Audio ；子包：
  - Impact Sounds https://kenney.nl/assets/impact-sounds （130 文件，CC0 徽章已核实）
  - RPG Audio https://kenney.nl/assets/rpg-audio （50 文件，CC0 徽章已核实）
  - Interface Sounds https://kenney.nl/assets/interface-sounds （2020；承接旧版 UI Audio）
  - Casino Audio https://kenney.nl/assets/casino-audio
- 许可条款页：https://kenney.nl/support
- 作者：Kenney｜许可：**CC0**｜可商用：是｜署名：不要求（禁用 logo）
- 格式：包内以 **OGG** 为主（Godot 原生支持），另附 WAV/MP3，zip 内含 License.txt
- 风格：干净清脆的通用游戏 SFX，与像素俯视 TD 高度搭调
- 适用：Impact（命中/爆炸）、Interface Sounds（按钮/购买/波次提示）、Casino Audio（金币/计费）、RPG Audio（施法/近战/foley）
- 风险：UI Audio(2012) 与 Interface Sounds(2020) 内容重叠，避免重复打包；CC0 高频素材有"撞声"可能，可对常用音微调 pitch
- 核实状态：✅ 已直接核实

### 8.2 SubspaceAudio – 512 Sound Effects (8-bit style)（OpenGameArt）—— 推荐 S
- URL：https://opengameart.org/content/512-sound-effects-8-bit-style
- 作者：SubspaceAudio｜许可：**CC0**（HTML 许可字段 + 作者回帖自证）｜可商用：是｜署名：无
- 格式：WAV zip；NES/8-bit 复古风（coins、explosions、hit、laser、power-up、UI、teleport 等）
- 适用：建塔/升级/金币/命中/爆炸/警报/按钮音一条龙，像素 TD 天作之合
- 风险：94k+ 下载，高频事件音建议微调 pitch/时长差异化
- 核实状态：✅ 已直接核实

### 8.3 phoenix1291 – Sound Effects Pack 2（OpenGameArt）—— 推荐 S
- URL：https://opengameart.org/content/sound-effects-pack-2
- 作者：phoenix1291｜许可：**CC0**｜可商用：是｜署名：无
- 格式：110 个音效，每条同时提供 **FLAC/MP3/OGG/WAV** 四格式（1up/Blip/Coins/Explosions/Hit/Laser-weapon/Lose/Power-up/Teleport）
- 适用：金币经济、命中击杀、远程塔、升级、胜负反馈；与 8.2 二选一避免重复
- 风险：其完整系列在 itch 为付费内容——**只取 OGA 免费 zip**，勿混入付费包
- 核实状态：✅ 已直接核实

### 8.4 OwlishMedia – Sound Effects Pack（OpenGameArt）—— 推荐 A
- URL：https://opengameart.org/content/sound-effects-pack
- 作者：OwlishMedia｜许可：**CC0**｜可商用：是｜署名：无
- 格式：WAV zip（142.4MB），写实录音（环境氛围/脚步/人声/水流/机械）
- 适用：关卡环境底噪、布防反馈、陷阱触发；给 8-bit 声铺"真实感"底层
- 风险：业余实用级音质，需手工挑音；与 8-bit 素材混用需风格调和
- 核实状态：✅ 已直接核实

### 8.5 Sonniss – GDC Game Audio Bundle（2026 版，7.47GB+）—— 推荐 S（注意专有 EULA）
- 来源页：https://gdc.sonniss.com/ （免费下载，表单/邮箱发放）
- 许可条款页（已核实全文）：https://sonniss.com/gdc-bundle-license/ （**EULA v2.0，生效 2026-08-27**——就在调研前一周更新，务必以下载当日版本为准）
- 作者：Sonniss Ltd（英国）及 17 家入库厂商｜许可：**专有 EULA（非 CC0）**：全球非独占**免版税**，**可商用、免署名**，不限项目数
- 格式：WAV，专业录音棚品质（爆炸/机械/科幻 UI/人声/环境，非 8-bit）
- 适用：高品质拟真爆炸/炮击/氛围，与 Kenney/OGA 轻量 SFX 互补
- 风险（**务必遵守**）：
  1. 禁止将素材（含加工版）单独转售/打包成素材库/模板再分发（EULA §RESTRICTIONS c）；
  2. 禁止用于 AI/ML 训练；
  3. 禁止对原始录音主张著作权；
  4. 仅允许在成品项目内同步使用并销售成品；
  5. 只从 sonniss.com 官方渠道下载，勿用第三方镜像；保留下载日的 EULA 版本记录。
- 推论：若项目资产夹将来要开源或随模板分发，**只放 CC0 素材，别放 Sonniss 音频**
- 核实状态：✅ 已直接核实（EULA 全文）

### 8.6 Freesound 精选（逐条核实，CC0 优先）

平台机制（已核实）：浏览不需登录，**下载需免费注册**；搜索支持 `f=license:"Creative Commons 0"` / `f=license:"Attribution"` 过滤；每页有独立许可徽章。勿用脚本批量爬站（API 需 key）。

**CC0 条目（免署名，直接进工程）：**

| 资产 | 作者 | URL | 格式/规格 | 用途 | 推荐 |
|---|---|---|---|---|---|
| Retro Blaster Fire | astrand | https://freesound.org/people/astrand/sounds/328011/ | WAV 44.1k/16bit 0.17s | 塔开火主音效 | S |
| lasersPewPew.wav | Masamundane | https://freesound.org/people/Masamundane/sounds/628256/ | WAV 16kHz/32bit 1.15s | 第二座塔"pew"变体（低保真，复古契合） | A |
| Explosion 1.wav | Deganoth | https://freesound.org/people/Deganoth/sounds/165911/ | WAV 44.1k/24bit 7.6s | 大型爆炸（截取前 0.8–1.5s） | A |
| Plingy Coin | Fupicat | https://freesound.org/people/Fupicat/sounds/538146/ | WAV 44.1k/16bit 0.9s | 金币拾取/扣费确认 | S |
| menu_click | jackosnb | https://freesound.org/people/jackosnb/sounds/736912/ | WAV 44.1k/16bit 0.17s | UI 点击/切换/确认 | S |
| Puff of Smoke | qubodup | https://freesound.org/people/qubodup/sounds/714257/ | WAV 48k/16bit 0.5s | 放置炮塔"poof"/拆塔 | A |

**CC-BY 4.0 条目（必须署名进 credits）：**

| 资产 | 作者 | URL | 格式 | 用途 | 推荐 |
|---|---|---|---|---|---|
| Cap Explosion Big.mp3 | CGEffex | https://freesound.org/people/CGEffex/sounds/92628/ | MP3 44.1k 6.6s | Boss 死亡/重爆炸（裁短 1–2s） | A |
| SFX_Pickup_59.wav | jalastram | https://freesound.org/people/jalastram/sounds/386586/ | WAV 44.1k/24bit 0.47s | 8-bit 拾取变体 | A |

署名格式（Freesound FAQ 推荐）：`"作品名" by 作者 ( 来源URL ) licensed under CC BY 4.0`

- Freesound 通用风险：用户上传内容无法 100% 排除内部含未授权第三方素材；优先选下载量大、作者历史好的条目（本表已筛选）；**保存许可页面截图存档**。作者 jalastram 的其他上传物许可混乱（含 NC/SA），只取已核实条目。
- 核实状态：✅ 8 条均逐页核实（许可徽章 + 作者主页 HTTP 200）

---

## 9. 混搭兼容性规则（必须遵守）

**可以混搭的：**
- 全部 CC0 素材之间任意混搭，零冲突、零署名叠加（Kenney 全系、Buch/CDmir/rgsdev/0x72 地形与敌人、BenHickling 火焰、OGA CC0 音乐与 SFX、Freesound CC0 条目）。
- CC0 + CC-BY/OGA-BY 混搭合法，**无传染性**；代价只是每条 CC-BY 素材各自进 credits（本清单中的 CC-BY 项：CraftPix 史莱姆 OGA-BY 3.0、Clint Bellanger Sparks CC-BY 3.0、PPEAK 音乐包 CC-BY 4.0、incompetech CC-BY 4.0、Freesound 2 条 CC-BY 4.0）。
- OFL 字体（Press Start 2P / VT323）与任何素材兼容；渲染出的游戏画面不受 OFL 约束，只需分发 .ttf 时附带许可文本。
- Sonniss EULA 素材与 CC0/CC-BY 在**成品游戏内**混用合法（免版税、免署名）。

**不能混搭 / 必须避开的：**
1. **CC-BY-SA（任何版本）**：ShareAlike 会传染衍生作品，与闭源商用发行冲突。OGA 上的 LPC（Liberated Pixel Cup）全套及大量社区资产是 CC-BY-SA 3.0 + GPL 3.0 双授权——**一律排除**。注意 LPC 条目需逐页看字段（少数如 [LPC] Goat 有 CC-BY 选项），不能凭前缀一刀切。
2. **CC-BY-NC**：商用即违约，一律排除（Freesound 上有大量 NC 素材，必须用 license 过滤器）。
3. **GPL 美术资产**、历史遗留 **Sampling+**（Freesound）：排除。
4. **Sonniss 素材**：不得进入任何会被再分发的素材夹/模板/开源仓库；不得喂 AI。
5. **Kenney logo**：任何素材包里都不得使用。
6. **风格层面的"不宜混搭"（非法律问题但同样穿帮）**：
   - Kenney 扁平描边风（Tower Defense Top-Down / Particle Pack）↔ 16px 硬边像素（Tiny 系 / 0x72 / Buch）——同画面勿混，立项时锁定单一美术基线；
   - Spine 平滑渲染（僵尸）与硬边像素瓦混用需缩放置半透明实测；
   - 等距视角（bart 塔）与正投影俯视地图不匹配。

**credits 管理要求：**
- 维护一份 `CREDITS.md` + 游戏内致谢屏：每条 CC-BY/OGA-BY 素材单独列 作品名/作者/来源 URL/许可名与链接。
- OFL 字体的许可文本随 .ttf 放入 `licenses/` 目录。
- CC0 素材署名非义务，建议仍统一列出以示尊重。
- **不要把 CC-BY 素材笼统写成"CC0"**——标注错误等于违约。

---

## 10. 已排除 / 未通过核实的条目（防坑记录）

| 条目 | 原因 |
|---|---|
| Kenney Tower Defense Kit | CC0 属实但为 **3D 模型**包，不适用 2D 像素项目 |
| Kenney 1-Bit Pack | CC0、16×16，但单色审美小众，仅 1-bit 风格适用 |
| Kenney Medieval RTS (Pixel) 等 ★ 像素包 | 仅在付费 All-in-1 捐赠包内，未核到免费站内下载页 |
| Pixel Frog – Tiny Swords（itch.io） | 许可说法冲突（第三方称 custom license 禁再分发），无法读原文 → 按"许可不明"排除 |
| AstroBob – Animated Pixel Art Skeleton（itch.io） | 无任何许可背书 → 排除 |
| OGA Redshrike Tower Defense Prototyping Assets | CC-BY/OGA-BY 可用，但怪物为**侧视**精灵，与俯视相机冲突 |
| OGA DST「Tower Defense Theme」 | 页面只抓到评论、未见许可徽标，来源不清不收录 |
| OGA CodeManu 8-bit Music Pack | 推断 CC0 但未直接显示徽标，降为 B 待复核（见 7.7） |
| HydroGene High Quality 8-bit Musics（itch.io） | 页面未能核实 → 需人工登录确认许可后方可考虑 |
| Freesound 上的 CC-BY-NC / Sampling+ 素材 | 商用违约/不可用，靠 license 过滤器规避 |
| 第三方目录站（gamesounds.xyz 等） | 非官方渠道，一律不碰 |

---

## 11. 调研过程与核实限制说明

- 全部 7 个方向的条目均经 WebSearch 定位 + FetchURL/curl 实际打开来源页或许可条款页核实；每条标注了核实状态（✅ 直接核实 / ⚠️ 间接核实）。
- **本环境网络限制**：itch.io 全域不可达（DNS 解析失败），fonts.google.com specimen 页不可达。受影响条目均已标注 ⚠️，并经 OGA 镜像、google/fonts 官方仓库、多份 GitHub CREDITS 文件或搜索引擎索引原文交叉印证。**商用发行前，建议人工复核所有 ⚠️ 条目的来源页原文**（itch 作者可随时改条款，以下载包内 license 文件为准）。
- OpenGameArt 站内搜索接口故障（500），内容页正常，逐条直连核实。
- Freesound 浏览免登录、下载需免费注册；API 需 key。
- Sonniss EULA 在调研前一周（2026-08-27）刚更新至 v2.0，下载时以当日版本为准。
