# 《余烬潮汐》资产目录(ASSET_CATALOG)

> **文档状态**:Proposed v1.0（候选资产目录；单项资产须经发行白名单批准）
> **撰写日期**:2026-09-04
> **Owner**:技术主理人(美术 / 音频)
> **Approver**:项目主理人
> **Supersedes**:`ASSET_AUDIO_RESEARCH_DRAFT.md`(v0.1);冲突以本文件为准
> **本文不修改其他草稿/审查稿**

---

## 目录

- [0. 文档目的与资产生命周期](#0-文档目的与资产生命周期)
- [1. 正式风格路线](#1-正式风格路线)
- [2. 不能混搭项](#2-不能混搭项)
- [3. 像素规格与基线](#3-像素规格与基线)
- [4. 美术候选表](#4-美术候选表)
- [5. 字体候选表(拉丁 + CJK)](#5-字体候选表)
- [6. 音乐候选表](#6-音乐候选表)
- [7. SFX 候选表](#7-sfx-候选表)
- [8. 候选 vs Shipping-approved 分级](#8-候选-vs-shipping-approved-分级)
- [9. C01–C03 资产缺口](#9-c01c03-资产缺口)
- [10. CJK 字体深度调研(含 Ark Pixel Font)](#10-cjk-字体深度调研)
- [11. 音频事件矩阵](#11-音频事件矩阵)
- [12. 资产许可台账流程](#12-资产许可台账流程)
- [13. 风格 vs 许可证双评分](#13-风格-vs-许可证双评分)
- [14. 风险与政策声明](#14-风险与政策声明)
- [附录 A 台账模板](#附录-a-台账模板)
- [附录 B 间接核实清单(未批准)](#附录-b-间接核实清单)
- [附录 C 来源 URL 清单](#附录-c-来源-url-清单)

---

## 0. 文档目的与资产生命周期

### 0.1 文档目的

1. 为《余烬潮汐》v1.0 给出 **正式风格路线**,并提供 **候选池** 供纵向切片和正式生产选用。
2. 明确区分 **候选(candidate)** 与 **Shipping-approved**(已批准进入发行构建),**间接核实** 不进入 shipping。
3. 提供 **资产许可台账模板**,保证每个第三方文件可追溯、可审计、可生成 credits。
4. 提供 **C01–C03 资产缺口清单**,这是 Gate B 退出门槛之一。

### 0.2 资产生命周期

**【Policy】** 所有资产必须遵循以下生命周期:

```
Research  →  Proposed  →  Approved  →  Implemented  →  Verified  →  Shipping
```

| 阶段 | 含义 | 谁可以推进 | 推进条件 |
|---|---|---|---|
| **Research** | 调研池中,未承诺采用 | 调研者 | 链接可访问,初步风格相符 |
| **Proposed** | 提议进入候选表,待评审 | 任何 agent | 调研完整,许可证初判 |
| **Approved** | 已被批准使用(进入设计稿 / 灰盒) | 项目主理人 | 风格 + 许可证双通过 |
| **Implemented** | 已用于实际场景 / 音频 / 字体 | 实现者 | Approved 状态下导入并 hash 校验 |
| **Verified** | 实际渲染/播放效果与设计一致 | 项目主理人 + 至少 1 名外部测试者 | 截图 / 听感评审通过 |
| **Shipping** | 进入发行构建 | 项目主理人 | Verified + 许可证证据完整 + credits 已加入 |

**【Policy】** **Shipping 状态不得跳过**;缺失证据的资产不得进入发行构建。

---

## 1. 正式风格路线

### 1.1 视觉识别

**【Policy】** 《余烬潮汐》视觉基调:

| 维度 | 锁定 |
|---|---|
| 像素密度 | **32×32 tile / 角色占地 32×32** |
| 投影视角 | **正交俯视**(非等距) |
| 色板 | 冷蓝深紫(夜海) + 暖琥珀(余烬) + 锈绿(苔铜);完整色板见 ASSET_STYLE_GUIDE |
| 光向 | 单一主光(西北 315°);不混合冷暖 |
| 描边 | 1 px 深色外描边;角色与塔必须有轮廓 |
| 饱和度 | 中等偏低;高对比用于危险/关键交互 |
| 帧率 | 角色 idle 6 fps,攻击 12 fps,死亡 24 fps |
| 动画 | 不使用 Spine 平滑插值;全像素逐帧 |

### 1.2 UI 视觉语言

**【Policy】** UI 视觉基于 **潮汐航海仪器**:

| 元素 | 视觉 |
|---|---|
| 主面板 | 黄铜框 + 海图底纹 + 棱镜折射高光 |
| 按钮 | 黄铜边框 + 蚀刻文字 + 指针 hover |
| 进度条 | 深度刻度盘(下沉式动画) |
| 弹窗 | 透镜式景深模糊背景 |
| 计时轴 | 潮汐仪表盘(明潮 / 暮潮切换为潮水涨落) |
| 商店/升级 | 航线图(节点 = 港口,等级 = 距离) |

**【Policy / 禁止项】**:
- ❌ 木质卷轴中世纪 UI(避免与某经典塔防过近)
- ❌ 默认 Godot 主题(过通用)
- ❌ 高饱和度荧光色(破坏海洋基调)

### 1.3 塔视觉识别

| 塔 | 视觉锚点 |
|---|---|
| 针轨弩台 | 长形轨道,磁吸箭头,夜蓝金属 |
| 余烬喷井 | 喷口边缘结炭,内部琥珀光 |
| 回声桩阵 | 两根低矮桩柱,中间弦线波动 |
| 风帆机巢 | 编织帆布 + 木骨架,可展开翼 |
| 铸潮砧塔 | 重型砧座,周围散落碎片 |
| 棱镜苗圃 | 半透明多面体,折射环境光 |

### 1.4 章节视觉递进

| 章节 | 主色调 | 视觉变化 |
|---|---|---|
| 序章 + 第一章「盐风浅滩」 | 夜蓝 + 灰白 | 海雾、礁石、简陋木杆 |
| 第二章「玻璃沼泽」 | 蓝紫 + 翠绿 | 玻璃质、孢光、扭曲倒影 |
| 第三章「沉钟群岛」 | 深青 + 锈铜 | 钟声雕刻、藤壶、青苔 |
| 第四章「无昼海眼」 | 黑紫 + 余烬红 | 永恒暮色,余烬残光 |

---

## 2. 不能混搭项

**【Policy】** 严禁同画面/同音频层混搭:

| 类型 | 不能与同画面混搭 |
|---|---|
| 美术 | 16×16(Kenney Tiny Dungeon)与 32×32(Buch Outdoor) |
| 美术 | 硬边像素(Kenney Tiny / Buch)与平滑 Spine(rileygombart Zombie) |
| 美术 | 正交俯视(Tiny / Buch / Nido)与等距视角(bart Towers) |
| 美术 | 扁平描边(Kenney Tower Defense Top-Down / Particle Pack)与硬边像素 |
| 美术 | 木卷轴 UI(Kenney Pixel UI Pack / Pixel Adventure)与潮汐仪器 UI(本项目) |
| 音频 | 写实录音(OwlishMedia)与 8-bit chiptune(Kenney Audio / SubspaceAudio)同事件 |
| 视觉/UI | Kenney logo / 任何原水印(kenney.nl/support 明文禁止) |

**【Policy】** 任何潜在混搭必须由 §13 双评分(Art Fit + License Confidence)独立判定,不得仅凭许可证选用。

---

## 3. 像素规格与基线

**【Policy】** 与 RESEARCH_REPORT §4 一致:

- 逻辑分辨率 **640×360**
- tile **32×32**
- 角色占地 **32×32** 基础,精英 **64×64**,Boss **96×96** 或 **128×128**
- 同色板范围(每个章节一份 `.tres` ColorPalette)
- 渲染后端 Forward+
- 默认纹理过滤 Nearest
- 整数缩放

---

## 4. 美术候选表

> **图例**:Evidence = Verified(本表元数据已直连核实) / Indirect(仅间接核实,不可 Shipping) / Not verified(待补)
> **Style Fit**:高 / 中 / 低 / 不符
> **License Confidence**:高 / 中 / 低 / 不符

### 4.1 Tileset / 地形

| ID | 名称 | URL | 作者 | 许可证 | 可商用 | 署名 | 像素密度 | 风格匹配 | 证据 | License Confidence | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| AT-TER-001 | Buch – Outdoor 32×32 Tileset | https://opengameart.org/content/outdoor-32x32-tileset | Michele "Buch" Bucelli | CC0 | 是 | 不要求 | 32×32 | 中(需重涂为海主题) | Verified | 高 | https://gitgud.io/darkofocdarko/fort-of-chains/-/blob/cc2345903e1c541987a4f9b8c50b8d1d99f81e1a/docs/tileset_credits.md 印证 |
| AT-TER-002 | CDmir – Desert Tileset | https://opengameart.org/content/desert-tileset-1 | CDmir | CC0 | 是 | 不要求 | 32×32 | 中(沙漠不适合海洋主题) | Verified | 高 | 仅作变体章节候选 |
| AT-TER-003 | rgsdev – Free CC0 Top-Down Tileset Template | https://opengameart.org/content/free-cc0-top-down-tileset-template-pixel-art | Raphael Gonçalves (rgsdev) | CC0 | 是 | 不要求 | 16×16 | **低**(密度不符) | Indirect(itch 页不可达) | 中 | 需 scale 2× 并入 32×32 网格 |
| AT-TER-004 | 0x72 – DungeonTileset II | https://0x72.itch.io/dungeontileset-ii | Robert Norenberg (0x72) | CC0 | 是 | 不要求 | 16×16 | **低**(密度不符 + 题材偏地牢) | Indirect | 中 | 仅作章节 III 钟声雕刻参考 |
| AT-TER-005 | Kenney – Tiny Dungeon | https://kenney.nl/assets/tiny-dungeon | Kenney Vleij | CC0 | 是 | 不要求 | 16×16 | **低**(密度不符) | Verified(kenney.nl/support) | 高 | 灰盒原型可用,正式必须改 32×32 |
| AT-TER-006 | Kenney – Tiny Town | https://kenney.nl/assets/tiny-town | Kenney Vleij | CC0 | 是 | 不要求 | 16×16 | **低**(密度不符) | Verified | 高 | 同上 |
| AT-TER-007 | **原创 tileset** | (内制 / 委托) | 项目内 | 项目自有 | 是 | 不要求 | 32×32 | 高 | — | — | **正式推荐路线:原创 + Buch 灰盒参考** |

### 4.2 角色 / 敌人

| ID | 名称 | URL | 作者 | 许可证 | 可商用 | 署名 | 像素密度 | 风格匹配 | 证据 | License Confidence | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| AT-CHA-001 | 0x72 DungeonTileset II 怪物集 | https://0x72.itch.io/dungeontileset-ii | Robert Norenberg | CC0 | 是 | 不要求 | 16×16 | **低**(密度不符) | Indirect | 中 | 灰盒原型用 |
| AT-CHA-002 | CraftPix – Slime Monster Pixel Art | https://opengameart.org/content/slime-monster-pixel-art-for-top-down-rpg | CraftPix | OGA-BY 3.0 | 是 | **要求** | 不明 | 中(可作史莱姆参考) | Verified | 中 | 必须改色;**OGA-BY 3.0 ≠ CC0** |
| AT-CHA-003 | rileygombart – Animated Top Down Zombie | https://opengameart.org/content/animated-top-down-zombie | rileygombart | CC0 | 是 | 不要求 | 不明(Spine) | **不符**(Spine 平滑) | Verified | 高 | 仅参考动作;**正式不能直接用** |
| AT-CHA-004 | Camacebra – Spider Pixel Art Pack | https://camacebra.itch.io/spider-pixel-art-pack-16x16 | Camacebra | "Public license" | 是 | 不要求(声明) | 16×16 | **低**(密度不符 + 许可措辞非标准) | Indirect | **低** | **不建议进入 shipping** |
| AT-CHA-005 | Kenney – Pixel Shmup | https://kenney.nl/assets/pixel-shmup | Kenney Vleij | CC0 | 是 | 不要求 | 16×16 | **低**(密度不符) | Verified | 高 | 仅取飞行敌人轮廓参考 |
| AT-CHA-006 | Kenney – Tower Defense (Top-Down) 敌人 | https://kenney.nl/assets/tower-defense-top-down | Kenney Vleij | CC0 | 是 | 不要求 | 不一(混合) | **不符**(扁平风) | Verified | 高 | **不采用**;扁平风与硬边像素冲突 |
| AT-CHA-007 | **原创 24+8+6 敌人精灵** | (内制 / 委托) | 项目内 | 项目自有 | 是 | 不要求 | 32×32 | 高 | — | — | **正式推荐路线** |

### 4.3 塔 / 防御单位

| ID | 名称 | URL | 作者 | 许可证 | 可商用 | 署名 | 像素密度 | 风格匹配 | 证据 | License Confidence | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| AT-TWR-001 | Kenney – Tower Defense (Top-Down) | https://kenney.nl/assets/tower-defense-top-down | Kenney Vleij | CC0 | 是 | 不要求 | 不一(混合) | **不符**(扁平风) | Verified | 高 | **不采用**;只作灰盒布局参考 |
| AT-TWR-002 | Kenney – Tiny Battle | https://kenney.nl/assets/tiny-battle | Kenney Vleij | CC0 | 是 | 不要求 | 16×16 | **低**(密度不符 + 军事题材) | Verified | 高 | 仅作灰盒布局 |
| AT-TWR-003 | Nido – Tower Defence Basic Towers | https://opengameart.org/content/tower-defence-basic-towers | Nido | CC0 | 是 | 不要求 | "high resolution" | **不符**(非像素) | Verified | 高 | **不采用**;视觉与本项目不匹配 |
| AT-TWR-004 | zintoki – Ground Shaker | https://zintoki.itch.io/ground-shaker | zintoki | CC0 | 是 | 不要求 | 不明 | 中 | Indirect(itch 不可达) | 中 | 需目测后定 |
| AT-TWR-005 | bart – Towers of Defense | https://opengameart.org/content/towers-of-defense | bart | CC0 | 是 | 不要求 | 等距 | **不符**(等距视角) | Verified | 高 | **不采用** |
| AT-TWR-006 | **原创 6 塔精灵** | (内制 / 委托) | 项目内 | 项目自有 | 是 | 不要求 | 32×32 | 高 | — | — | **正式推荐路线** |

**【Policy / 重要发现】** 严格俯视像素的现成"塔"在免费来源**几乎稀缺**——所有候选都需要大幅重绘或完全原创。本项目塔、英雄、Boss 主视觉 **必须原创**。

### 4.4 VFX / 特效

| ID | 名称 | URL | 作者 | 许可证 | 可商用 | 署名 | 像素密度 | 风格匹配 | 证据 | License Confidence | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| AT-VFX-001 | BenHickling – Animated Fire | https://opengameart.org/content/animated-fire | BenHickling | CC0 | 是 | 不要求 | 64×64,60 帧 | 高 | Verified | 高 | 余烬喷井火焰 |
| AT-VFX-002 | Clint Bellanger – Sparks (Fire, Ice, Blood) | https://opengameart.org/content/sparks-fire-ice-blood | Clint Bellanger | CC-BY 3.0 | 是 | **要求** | 64×64,4 帧 | 高 | Verified | 高 | 弹命中溅射;需署名 |
| AT-VFX-003 | Kenney – Particle Pack | https://kenney.nl/assets/particle-pack | Kenney Vleij | CC0 | 是 | 不要求 | 512×512 | **不符**(柔渲) | Verified | 高 | **不采用**;软边缘像素违和 |
| AT-VFX-004 | **原创 VFX 帧** | (内制) | 项目内 | 项目自有 | 是 | 不要求 | 32×32 | 高 | — | — | **正式推荐路线** |

### 4.5 UI 主视觉

| ID | 名称 | URL | 作者 | 许可证 | 可商用 | 署名 | 风格匹配 | 证据 | License Confidence | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| AT-UI-001 | Kenney – Pixel UI Pack | https://kenney.nl/assets/pixel-ui-pack | Kenney Vleij | CC0 | 是 | 不要求 | **不符**(木卷轴) | Verified | 高 | **不采用**;视觉与本项目 UI 不符 |
| AT-UI-002 | Kenney – UI Pack – Pixel Adventure | https://kenney.nl/assets/ui-pack-pixel-adventure | Kenney Vleij | CC0 | 是 | 不要求 | **不符**(木卷轴 + 中世纪) | Verified | 高 | **不采用**;同上 |
| AT-UI-003 | Kenney – UI Pack 2.0 | https://kenney.nl/assets/ui-pack | Kenney Vleij | CC0 | 是 | 不要求 | **不符**(扁平) | Verified | 高 | **不采用**;同 §2 不能混搭 |
| AT-UI-004 | **原创 UI(潮汐航海仪器)** | (内制) | 项目内 | 项目自有 | 是 | 不要求 | 高 | — | — | **正式推荐路线** |

**【Policy / 重要】** 免费 UI 资产在风格上**均不适合本项目**;所有 UI 主视觉必须原创(可能是 9-slice 黄铜边框 + 海图底纹)。

---

## 5. 字体候选表

### 5.1 拉丁 / 显示字体

| ID | 名称 | URL | 作者 | 许可证 | 可商用 | 署名 | 风格匹配 | 证据 | License Confidence | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| FT-LAT-001 | Press Start 2P | https://fonts.google.com/specimen/Press+Start+2P | Cody "CodeMan38" Boisclair | SIL OFL 1.1(保留字体名) | 是 | OFL 文本随 .ttf 分发 | 高(8-bit 像素标题) | Verified(Google Fonts 仓库 OFL 文件) | 高 | 用于标题、菜单、VICTORY/DEFEAT |
| FT-LAT-002 | VT323 | https://fonts.google.com/specimen/VT323 | Peter Hull | SIL OFL 1.1 | 是 | OFL 文本随 .ttf 分发 | 高(CRT 终端风,数字等宽) | Verified | 高 | 用于 HUD 数值 |
| FT-LAT-003 | m5x7 | https://managore.itch.io/m5x7 | Daniel Linssen | 声明 CC0 | 是 | 无强制 | 高(5×7 极小像素) | Indirect(itch 不可达) | **中** | **不进入 shipping,仅作 spike** |
| FT-LAT-004 | **自定义 / 委托显示字体** | (内制 / 委托) | 项目内 | 项目自有 | 是 | 不要求 | 高 | — | — | **正式推荐:后期视品质决定** |

**【Policy】** 所有 .ttf 文件必须随 `licenses/OFL.txt` 或 `licenses/CC0.txt` 入库,且 `licenses/press_start_2p_NOTICE.txt` 记录 Reserved Font Name 提醒。

### 5.2 CJK 字体(详见 §10)

| ID | 名称 | 候选 URL | 许可证 | 可商用 | 备注 |
|---|---|---|---|---|---|
| FT-CJK-001 | 思源黑体 / Noto Sans CJK SC | https://github.com/notofonts/noto-cjk | SIL OFL 1.1 | 是 | 跨平台,体积大,需 subset |
| FT-CJK-002 | 思源宋体 / Noto Serif CJK SC | https://github.com/notofonts/noto-cjk | SIL OFL 1.1 | 是 | 同上 |
| FT-CJK-003 | 像素 CJK(待选:Ark Pixel Font / unifont / 美咲フォント) | 见 §10 | 待核 | 待核 | M0 锁定;要求像素风格 |

> 详见 §10 CJK 字体深度调研。

---

## 6. 音乐候选表

| ID | 名称 | URL | 作者 | 许可证 | 可商用 | 署名 | 风格匹配 | 证据 | License Confidence | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| MU-001 | Wolfgang_ – 8-bit cave loop | https://opengameart.org/content/8-bit-cave-loop | Wolfgang_ | CC0 | 是 | 不要求 | 高(8-bit 地下循环) | Verified | 高 | 序章 + 第一章战斗 |
| MU-002 | pmiller – Chiptune Battle Music | https://opengameart.org/content/chiptune-battle-music | pmiller | CC0 | 是 | 不要求 | 高(无缝循环) | Verified | 高 | 战斗层短循环 |
| MU-003 | request – Rin's Theme (loopable chiptune) | https://opengameart.org/content/rins-theme-loopable-chiptune-adventurebattle-bgm | request | CC0 | 是 | 不要求 | 高(高速弹幕感) | Verified | 高 | 后期波次主循环 |
| MU-004 | PPEAK / Preston Peak – Free Action Chiptune Music Pack | https://opengameart.org/content/free-action-chiptune-music-pack | PPEAK | CC-BY 4.0 | 是 | **要求**(署名 + 链接) | 高(13 首循环) | Verified | 高 | Boss 主题、菜单 BGM |
| MU-005 | Kevin MacLeod – incompetech 音乐库 | https://incompetech.com/music/royalty-free/music.html | Kevin MacLeod | CC-BY 4.0 | 是 | **要求**(规定格式) | 中(电子/动作,非地道 chiptune) | Verified | 高 | chiptune 不足时补充 |
| MU-006 | Kenney – Music Jingles | https://kenney.nl/assets/music-jingles | Kenney Vleij | CC0 | 是 | 不要求 | 高(短 jingle) | Verified | 高 | 胜负/升级/布塔短奏 |
| MU-007 | CodeManu – 8-bit Music Pack (Loopable) | https://opengameart.org/content/8-bit-music-pack-loopable | CodeManu | 推断 CC0 | 是 | 待复核 | 高(6 首循环) | **Not verified**(未直接看到 CC0 徽标) | **中** | **不进入 shipping** |
| MU-008 | **原创 / 委托章节 BGM** | (内制 / 委托) | 项目内 | 项目自有 | 是 | 不要求 | 高 | — | — | **正式推荐:每章 2–3 层动态混音** |

---

## 7. SFX 候选表

| ID | 名称 | URL | 作者 | 许可证 | 可商用 | 署名 | 风格匹配 | 证据 | License Confidence | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| SF-001 | Kenney Audio – Impact Sounds | https://kenney.nl/assets/impact-sounds | Kenney Vleij | CC0 | 是 | 不要求 | 高 | Verified | 高 | 命中、爆炸 |
| SF-002 | Kenney Audio – RPG Audio | https://kenney.nl/assets/rpg-audio | Kenney Vleij | CC0 | 是 | 不要求 | 高 | Verified | 高 | 施法、近战、foley |
| SF-003 | Kenney Audio – Interface Sounds | https://kenney.nl/assets/interface-sounds | Kenney Vleij | CC0 | 是 | 不要求 | 高 | Verified | 高 | UI 按钮 |
| SF-004 | Kenney Audio – Casino Audio | https://kenney.nl/assets/casino-audio | Kenney Vleij | CC0 | 是 | 不要求 | 中(赌场铃声) | Verified | 高 | 火种增减 |
| SF-005 | SubspaceAudio – 512 Sound Effects (8-bit) | https://opengameart.org/content/512-sound-effects-8-bit-style | SubspaceAudio | CC0 | 是 | 不要求 | 高(8-bit NES 风) | Verified | 高 | 一站式通用 SFX |
| SF-006 | phoenix1291 – Sound Effects Pack 2 | https://opengameart.org/content/sound-effects-pack-2 | phoenix1291 | CC0 | 是 | 不要求 | 高(OGA 常见类) | Verified | 高 | 金币/拾取/命中 |
| SF-007 | OwlishMedia – Sound Effects Pack | https://opengameart.org/content/sound-effects-pack | OwlishMedia | CC0 | 是 | 不要求 | **不符**(写实录音) | Verified | 高 | **不采用**;写实与 chiptune 冲突 |
| SF-008 | Sonniss – GDC Game Audio Bundle(2026+) | https://gdc.sonniss.com/ | Sonniss Ltd + 17 vendor | 专有 EULA | 是 | 不要求 | 中(专业录音) | **Not verified**(EULA 全文未直接核到) | **低** | **不进入 shipping,直到 EULA 直接核实** |
| SF-009 | Freesound 精选 CC0(6 条) | https://freesound.org/ | 见台账 | CC0 | 是 | 不要求 | 高 | Verified | 高 | 详见台账 |
| SF-010 | Freesound 精选 CC-BY 4.0(2 条) | https://freesound.org/ | 见台账 | CC-BY 4.0 | 是 | **要求**(规定格式) | 高 | Verified | 高 | 详见台账 |
| SF-011 | **原创 / 委托事件 SFX** | (内制 / 委托) | 项目内 | 项目自有 | 是 | 不要求 | 高 | — | — | **正式推荐:关键事件需原创** |

---

## 8. 候选 vs Shipping-approved 分级

**【Policy】** 发行构建中允许出现的资产,必须满足:

| 资产类型 | Shipping-approved 条件 |
|---|---|
| 美术 | 风格匹配 ≥ 中 + License Confidence ≥ 高 + 已 Approved+Implemented+Verified |
| 字体 | License Confidence ≥ 高 + 包含完整许可文本 + Reserved Font Name 已记录 |
| 音乐 | License Confidence ≥ 高 + 完整署名文本已生成 + 已 Approved |
| SFX | License Confidence ≥ 高 + 完整署名文本已生成 + 已 Approved |

**【Policy / 不进入 shipping】**:
- 所有 `Indirect` 证据等级(itch.io / google fonts specimen 页不可达)
- 所有 `Not verified` 等级
- CodeManu 8-bit Music Pack(SF-008 类似,无直接许可徽标)
- Sonniss GDC Bundle(直到 EULA 全文直连核实)
- m5x7(直到 itch 页直连核实)
- 任何包含 CC-BY-SA / GPL / CC-BY-NC 的资产(项目政策:风险控制)

---

## 9. C01–C03 资产缺口

> C01–C03 是 Gate B(发布质量纵向切片)退出门槛之一,必须 100% 资产列成可勾选清单。

### 9.1 C01「离港火线」资产需求

| 类别 | ID | 数量 | 风格/规格 | 候选 | 状态 |
|---|---|---|---|---|---|
| 地形 | sea_ground / rocky_shore / path_stone | 1 set | 32×32,夜蓝 + 灰 | AT-TER-001(灰盒)→ AT-TER-007(正式) | 缺口 |
| 敌人 | salt_shell_walker / mast_rat | 2 类 | 32×32,4 方向 × 4 状态 | AT-CHA-007(原创) | 缺口 |
| 塔 | needle_rail I / II / III | 1 塔 3 档 | 32×32,夜蓝金属 | AT-TWR-006(原创) | 缺口 |
| 投射物 | needle_bolt | 1 | 8×8,夜蓝 | AT-TWR-006 衍生 | 缺口 |
| 状态效果 | slow / pierce | 2 | 32×32,VFX 帧 | AT-VFX-004(原创) | 缺口 |
| 英雄 | lanzhou_wei(可选)C01 可不带英雄 | 1 | 32×32,海风帆布 | AT-CHA-007(原创) | 缺口 |
| UI | HUD / 暂停 / 关卡选择 / 结算 | 4 屏 | 潮汐航海仪器 | AT-UI-004(原创) | 缺口 |
| 字体 | 标题 + HUD 数值 + CJK | 3 套 | 见 §5 / §10 | FT-LAT-001/002 + FT-CJK-??? | 缺口 |
| BGM | 序章战斗 | 1 首 | 8-bit 短循环 | MU-001/002 | 候选 |
| SFX | 命中/敌人死亡/塔开火/UI 点击/波次提示/舰队扣血 | ≥ 6 | 8-bit | SF-001/002/003/005 | 候选 |

### 9.2 C02「潮门初启」资产新增

| 类别 | ID | 数量 | 风格/规格 | 状态 |
|---|---|---|---|---|
| 敌人 | splitfin_dasher(迅捷) | +1 | 32×32 | 缺口 |
| 塔 | needle_rail IV + ember_well I/II/III | +1 塔 + 1 塔 3 档 | 32×32,余烬喷井琥珀光 | 缺口 |
| 投射物 | ember_burst | +1 | 8×8 | 缺口 |
| 状态效果 | burn | +1 | VFX | 缺口 |
| 视觉 | 暮潮配色切换 | +1 palette | 蓝紫 → 黑紫 | 缺口 |
| BGM | 第一章战斗层 | 1 首 | 8-bit | MU-002/003 候选 |

### 9.3 C03「失火灯塔」资产新增

| 类别 | ID | 数量 | 风格/规格 | 状态 |
|---|---|---|---|---|
| 敌人 | rust_armor_carrier(重甲) | +1 | 32×32,厚甲轮廓 | 缺口 |
| 塔 | 6 塔骨架补齐到 I/II | +4 塔 | 32×32 | 缺口 |
| 英雄 | lanzhou_wei(正式登场) | 1 | 32×32 + 4 技能 | 缺口 |
| 投射物 | per tower 1 | +5 | 各异 | 缺口 |
| 状态效果 | armor_break | +1 | VFX | 缺口 |
| BGM | 第一章 Boss 主题 | 1 首 | 8-bit 紧张 | MU-004 候选(需署名) |

**【Policy】** Gate B 退出条件:C01–C03 的所有上述资产 100% 处于 Approved+Implemented+Verified 状态,且 ≥ 1 张商店级战斗截图与 30 秒战斗录屏。

---

## 10. CJK 字体深度调研

> PRD §14.1 要求 P0 = 简中 + 英文,且中文必须可读。M0 必须锁定字体。

### 10.1 像素 CJK 字体候选

| 名称 | URL | 风格 | 许可证 | 可商用 | 备注 |
|---|---|---|---|---|---|
| **Ark Pixel Font** | https://github.com/TakWolf/ark-pixel-font | 12px 像素 CJK + 拉丁 | SIL OFL 1.1 | 是 | **优先候选**:12px 适配 32×32 角色头标 + HUD 数字;OFL 1.1 明确允许商用与修改 |
| **美咲フォント(Misaki Gothic)** | https://littlelimit.net/misaki.htm | 8px 极小像素 | 免费(freeware,非 OSI) | 是 | 字体本身免费但 **非 OFL/CC0**;商用前需查最新条款 |
| **Unifont** | https://unifoundry.com/unifont/ | 全 Unicode 单色 | SIL OFL 1.1(部分版本 GPL+exception) | 是(选 OFL 版) | 体积大,单色无衬线;适合极端 size |
| **Droid Sans Fallback** | https://github.com/StefanLobbenmeier/DroidSansFallback | Android 系统 | Apache 2.0 | 是 | 非像素,作 fallback |
| **思源黑体 / Noto Sans CJK SC** | https://github.com/notofonts/noto-cjk | 非像素(矢量) | SIL OFL 1.1 | 是 | fallback 用;**不能**作为主显示 |
| **Sarasa Mono SC** | https://github.com/be5invis/Sarasa-Gothic | 等宽(基于思源) | SIL OFL 1.1 | 是 | 等宽;适合数字/调试 |

### 10.2 Ark Pixel Font 详细评估

**【Verified】** Ark Pixel Font 来自 TakWolf(GitHub):

| 维度 | 评估 |
|---|---|
| 风格 | 12 像素等宽 CJK + 拉丁;硬边像素 |
| 字符集 | 简体 + 繁体 + 日文 + 韩文 + 拉丁 + 符号(全 Unicode BMP 覆盖) |
| 许可证 | **SIL OFL 1.1** |
| 可商用 | **是**(OFL 明确允许) |
| 署名要求 | 随字体分发 OFL 文本;不要求额外 credit(虽然 recommended) |
| 修改 | 允许;修改版不得使用保留名(本字体无保留名) |
| 体积 | 完整版约 10–30 MB;subset 后可降至 1–3 MB |
| 适配性 | 12px 高度适配 32×32 角色头顶"Hero_01"小标签;HUD 短文本需 ≥ 16px 等效 |

**【Recommendation】**:
- **P0 主字体**:Ark Pixel Font 12px(标题 / HUD / 短文本)
- **P0 副字体**:Noto Sans CJK SC(超长文本 / 多行 / 段间距)
- **fallback**:Droid Sans Fallback

**【Policy】** M0 必须:
1. 下载 Ark Pixel Font OFL 版(https://github.com/TakWolf/ark-pixel-font/releases)
2. 用 fontTools 制作中文常用字 subset(3500 字一级 + 7000 字二级)
3. 放入 `assets/fonts/`,OFL.txt 放入 `licenses/`
4. 在 C01 灰盒实测 16:10 / 21:9 / 1080p / UI 160% 缩放下的可读性

### 10.3 不可采用的 CJK 字体

| 名称 | 原因 |
|---|---|
| 任何微软系统字体(MS YaHei, SimSun) | EULA 禁止独立分发 |
| 任何 macOS 系统字体(PingFang) | 同上 |
| 任何未声明许可证的"免费中文字体" | 项目政策:不进入 shipping |

---

## 11. 音频事件矩阵

**【Policy】** 每个威胁/事件必须有可辨识声音,且全部 8-bit 风格统一。

| 事件 | 触发 | 候选 SFX | 备注 |
|---|---|---|---|
| 敌人飞行进入 | 飞行敌人进入射程 | SF-005 flight buzz | |
| 隐匿显形 | 隐匿敌人离开草丛/被侦测 | SF-002 reveal chime | |
| 治疗施放 | 治疗敌人引导 | SF-002 heal hum | |
| 出口告急 | 敌人距离出口 < 3 cell | SF-005 alert siren | |
| 相位将变 | 切换前 20 秒 | SF-002 tide bell | |
| 塔开火 | 任意塔攻击 | SF-001/002 per tower | 6 塔各异 |
| 敌人死亡 | 敌人 HP ≤ 0 | SF-001 death pop | per 敌人家族 |
| 英雄技能 | 英雄释放技能 | SF-002/005 | per 技能 |
| 终极技 | 终极技释放 | SF-002/005 dramatic stinger | |
| 火种增减 | 拾取/扣费 | SF-003 coin | |
| 升级成功 | 塔升级 | SF-003 upgrade chime | |
| 胜利 | 关卡完成 | SF-003 win jingle | |
| 失败 | 舰队完整度 ≤ 0 | SF-003 lose jingle | |
| UI 点击 | 任何按钮 | SF-003 click | |
| 暂停 | 暂停切换 | SF-003 pause blip | |
| 波次开始 | 波次倒计时结束 | SF-002/005 wave horn | |
| BGM | 关卡 / 战斗 / Boss | 见 §6 音乐候选 | 至少 3 层 |

**【Policy】** 同类连续音效需 3–5 个变体与音高微调,避免重复感。

---

## 12. 资产许可台账流程

### 12.1 台账文件

**【Policy】** 项目根目录维护 `ASSET_LICENSE_LEDGER.csv`,UTF-8 编码,字段:

```csv
asset_id,asset_name,asset_type,author,source_url,download_date,download_hash,license_text_path,license_short,commercial_use,attribution_required,redistribution_allowed,derivation_allowed,project_path,replaces,status,verifier,verified_at,notes
```

示例:
```csv
AT-TER-001,Buch Outdoor 32x32 Tileset,tileset,Michele Bucelli,https://opengameart.org/content/outdoor-32x32-tileset,2026-09-04,sha256:abc123...,licenses/buch_outdoor_32x32_CC0.txt,CC0,yes,no,yes,yes,assets/art/tilesets/buch/,灰盒参考,Verified,wxb,2026-09-04,https://gitgud.io/darkofocdarko/fort-of-chains/-/blob/cc2345903e1c541987a4f9b8c50b8d1d99f81e1a/docs/tileset_credits.md 印证
```

### 12.2 落地流程

1. **Research** → 调研者把候选加入台账,`status=Research`
2. **Proposed** → 调研完成 + 许可证初步判定,`status=Proposed`
3. **Approved** → 项目主理人批准,`status=Approved`,`verifier+verified_at` 填写
4. **Implemented** → 实际导入项目,`project_path` 填写,`download_hash` 必须实际校验
5. **Verified** → 渲染/听感通过,`status=Verified`
6. **Shipping** → 进入发行构建,`status=Shipping`

### 12.3 派生文件 metadata

**【Policy】** 派生资产(裁切/调色/重命名/转换格式)必须在 metadata 保留:
- `source_asset_id`(指向原资产)
- `derivation_note`(裁切/调色/...)
- 重新计算 `download_hash`(派生文件 hash)

**【Policy】** Credits 文本从台账 **自动生成**,人工复核后放入 `licenses/CREDITS.txt` 与游戏内致谢屏。

### 12.4 下载时必做

- 保存原始压缩包到 `licenses/sources/`(只读,不参与发行构建)
- 校验 SHA256
- 抓取许可证原文 PDF/HTML 到 `licenses/sources/<asset_id>/LICENSE.txt`
- 抓取下载页面截图(PNG/PDF)
- 记录下载日期(精确到日)

---

## 13. 风格 vs 许可证双评分

**【Policy】** 每个候选资产必须有两个独立评分(0–5):

| 评分 | 维度 | 高(4–5)含义 | 低(0–2)含义 |
|---|---|---|---|
| **Style Fit** | 美术是否符合本项目视觉风格(密度、视角、色板、光向、轮廓) | 与 §1 完全一致 | 完全冲突 |
| **License Confidence** | 许可证证据等级与可商用确认度 | Verified 直连 + OFL/CC0 + 完整证据 | 间接核实 / 措辞模糊 / NC/SA |

**【Policy】** Shipping-approved 条件:
- Style Fit ≥ 3(且非"不符"档)
- License Confidence = 5(Verified)
- 已 Approved+Implemented+Verified

**【Policy】** 任何 Style Fit < 3 或 License Confidence < 5 的资产 **不进入 shipping**;即使许可免费也不采用。

---

## 14. 风险与政策声明

### 14.1 项目风险政策(降低 v1.0 复杂度)

**【Policy】** v1.0 不采用以下许可证,不论技术上是否可行:

| 许可证 | 风险 | 项目政策 |
|---|---|---|
| CC-BY-SA(任何版本) | ShareAlike 传染,与闭源商用冲突 | v1.0 不采用 |
| CC-BY-NC(任何版本) | 商用即违约 | v1.0 不采用 |
| GPL(任何版本) | 强传染 | v1.0 不采用 |
| "Public license" 等模糊措辞 | 法律风险 | 不进入 shipping |
| 来源不明 / 无许可徽标 | 风险过高 | 不进入 shipping |
| 间接核实(itch 不可达等) | 证据不足 | 不进入 shipping |
| AI 训练数据(任何 EULA 含禁止条款) | 已含禁止条款 | 不采用 |

**【Disclaimer】** 本节是项目内部风险管理政策,**不构成法律意见**。CC-BY-SA、CC-BY-NC、GPL 的法律含义在不同司法管辖区有差异,正式发布前由具备资质的人复核。

### 14.2 商标清查

**【Policy】** 《余烬潮汐》(Ashen Tides)为工作代号,正式名称需:
1. 搜索 Steam、主流商店、搜索引擎、域名、社媒
2. 查询目标销售地区商标数据库
3. 由合格法律人士对高风险名称复核
4. 记录搜索日期和结果

---

## 附录 A 台账模板

`ASSET_LICENSE_LEDGER.csv`(节选):

| asset_id | asset_name | asset_type | author | source_url | download_date | license | commercial | attribution | redistribution | status |
|---|---|---|---|---|---|---|---|---|---|---|
| AT-TER-001 | Buch Outdoor 32x32 Tileset | tileset | Michele Bucelli | https://opengameart.org/content/outdoor-32x32-tileset | TBD | CC0 | yes | no | yes | Research |
| AT-CHA-002 | CraftPix Slime | character | CraftPix | https://opengameart.org/content/slime-monster-pixel-art-for-top-down-rpg | TBD | OGA-BY 3.0 | yes | **yes** | yes | Research |
| FT-LAT-001 | Press Start 2P | font | CodeMan38 | https://fonts.google.com/specimen/Press+Start+2P | TBD | SIL OFL 1.1 | yes | OFL 文本随 .ttf | yes | Research |
| FT-CJK-001 | Ark Pixel Font | font | TakWolf | https://github.com/TakWolf/ark-pixel-font | TBD | SIL OFL 1.1 | yes | OFL 文本随 .ttf | yes | Research |
| MU-004 | PPEAK Chiptune Pack | music | PPEAK | https://opengameart.org/content/free-action-chiptune-music-pack | TBD | CC-BY 4.0 | yes | **yes** | yes | Research |
| SF-008 | Sonniss GDC Bundle | sfx | Sonniss | https://gdc.sonniss.com/ | TBD | 专有 EULA | yes | no | **partial** | **Not verified** |

---

## 附录 B 间接核实清单(未批准)

**【Policy】** 以下条目处于 Indirect 证据等级, **不进入 shipping**,仅作 spike 或调研参考:

| 资产 | 间接核实原因 |
|---|---|
| AT-TER-003 rgsdev Top-Down Tileset Template | itch 页不可达,仅 OGA 镜像 |
| AT-TER-004 0x72 DungeonTileset II | itch 页不可达 |
| AT-CHA-001 0x72 怪物集 | 同上 |
| AT-CHA-004 Camacebra Spider | itch 页不可达,许可措辞"Public license"非标准 |
| AT-TWR-004 zintoki Ground Shaker | itch 页不可达 |
| FT-LAT-003 m5x7 | itch 页不可达,GitHub README 佐证 |
| MU-007 CodeManu 8-bit Music Pack | OGA 页未显示 CC0 徽标 |
| SF-008 Sonniss GDC Bundle | EULA 全文未直连核实,2026-08-27 生效日期可疑(2026-03 已发布) |

---

## 附录 C 来源 URL 清单

### Tileset
- [Buch – Outdoor 32×32 Tileset](https://opengameart.org/content/outdoor-32x32-tileset)
- [CDmir – Desert Tileset](https://opengameart.org/content/desert-tileset-1)
- [rgsdev – Free CC0 Top-Down Tileset Template](https://opengameart.org/content/free-cc0-top-down-tileset-template-pixel-art)
- [0x72 – DungeonTileset II](https://0x72.itch.io/dungeontileset-ii)
- [Kenney – Tiny Dungeon](https://kenney.nl/assets/tiny-dungeon)
- [Kenney – Tiny Town](https://kenney.nl/assets/tiny-town)
- [Kenney Support / 全站 CC0 声明](https://kenney.nl/support)

### Character / Tower / VFX
- [CraftPix – Slime Monster Pixel Art](https://opengameart.org/content/slime-monster-pixel-art-for-top-down-rpg)
- [rileygombart – Animated Top Down Zombie](https://opengameart.org/content/animated-top-down-zombie)
- [Camacebra – Spider Pixel Art Pack](https://camacebra.itch.io/spider-pixel-art-pack-16x16)
- [Kenney – Pixel Shmup](https://kenney.nl/assets/pixel-shmup)
- [Kenney – Tower Defense (Top-Down)](https://kenney.nl/assets/tower-defense-top-down)
- [Kenney – Tiny Battle](https://kenney.nl/assets/tiny-battle)
- [Nido – Tower Defence Basic Towers](https://opengameart.org/content/tower-defence-basic-towers)
- [zintoki – Ground Shaker](https://zintoki.itch.io/ground-shaker)
- [bart – Towers of Defense](https://opengameart.org/content/towers-of-defense)
- [BenHickling – Animated Fire](https://opengameart.org/content/animated-fire)
- [Clint Bellanger – Sparks (Fire, Ice, Blood)](https://opengameart.org/content/sparks-fire-ice-blood)
- [Kenney – Particle Pack](https://kenney.nl/assets/particle-pack)

### UI
- [Kenney – Pixel UI Pack](https://kenney.nl/assets/pixel-ui-pack)
- [Kenney – UI Pack – Pixel Adventure](https://kenney.nl/assets/ui-pack-pixel-adventure)
- [Kenney – UI Pack 2.0](https://kenney.nl/assets/ui-pack)

### 字体
- [Press Start 2P (Google Fonts)](https://fonts.google.com/specimen/Press+Start+2P)
- [VT323 (Google Fonts)](https://fonts.google.com/specimen/VT323)
- [m5x7 (itch.io)](https://managore.itch.io/m5x7)
- [Ark Pixel Font — 优先候选 (GitHub)](https://github.com/TakWolf/ark-pixel-font)
- [Noto CJK — Fallback (GitHub)](https://github.com/notofonts/noto-cjk)
- [美咲フォント Misaki Gothic](https://littlelimit.net/misaki.htm)
- [Unifont](https://unifoundry.com/unifont/)

### 音乐
- [Wolfgang_ – 8-bit cave loop](https://opengameart.org/content/8-bit-cave-loop)
- [pmiller – Chiptune Battle Music](https://opengameart.org/content/chiptune-battle-music)
- [request – Rin's Theme](https://opengameart.org/content/rins-theme-loopable-chiptune-adventurebattle-bgm)
- [PPEAK – Free Action Chiptune Music Pack](https://opengameart.org/content/free-action-chiptune-music-pack)
- [Kevin MacLeod – incompetech](https://incompetech.com/music/royalty-free/music.html)
- [Kenney – Music Jingles](https://kenney.nl/assets/music-jingles)
- [CodeManu – 8-bit Music Pack(不进入 shipping)](https://opengameart.org/content/8-bit-music-pack-loopable)

### SFX
- [Kenney – Impact Sounds](https://kenney.nl/assets/impact-sounds)
- [Kenney – RPG Audio](https://kenney.nl/assets/rpg-audio)
- [Kenney – Interface Sounds](https://kenney.nl/assets/interface-sounds)
- [Kenney – Casino Audio](https://kenney.nl/assets/casino-audio)
- [SubspaceAudio – 512 Sound Effects (8-bit)](https://opengameart.org/content/512-sound-effects-8-bit-style)
- [phoenix1291 – Sound Effects Pack 2](https://opengameart.org/content/sound-effects-pack-2)
- [OwlishMedia – Sound Effects Pack(不采用)](https://opengameart.org/content/sound-effects-pack)
- [Sonniss GDC Game Audio Bundle(待 EULA 核实)](https://gdc.sonniss.com/)

---

> 文档版本:Proposed v1.0(2026-09-04)
> 状态:候选资产目录；仅单项达到 Shipping 状态后才可进入发行构建
> 建议下一步:项目主理人拍板后，在 M0 初始化台账、锁定字体并试做灰盒 C01
