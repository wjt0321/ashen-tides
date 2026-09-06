#!/usr/bin/env python3
"""Append Kenney CC0 resource rows to ASSET_LICENSE_LEDGER.csv.
本批新增 19 个 Adopted 项(12 PNG + 5 OGG + 2 LICENSE 文本); 替换为 Ledger 中已存在的同 ID 行。
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LEDGER = os.path.join(ROOT, "ASSET_LICENSE_LEDGER.csv")

# 12 UI PNG + 5 OGG + 2 LICENSE 文本
# 统一 schema 同既已存在的 C01 占位 sprite 行
KENNEY_ROWS = [
    # UI Pack 12 PNG (Kenney UI Pack 2.0, Kenney Vleugels, CC0 1.0)
    ("kenney_ui_button_rectangle_border", "button_rectangle_border.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/button_rectangle_border.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §2.1 主按钮底图 9-slice; modulate 调到项目深海蓝 #2e4a6b; 12 资源试装第一批准入; status=Integrated placeholder replacement（不是 Shipping）; catalog 决策 docs/current/art/C01_RESOURCE_DECISIONS.md §1"),
    ("kenney_ui_button_rectangle_depth_border", "button_rectangle_depth_border.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/button_rectangle_depth_border.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §2.1 按下/已选态底图; modulate = 0.10,0.22,0.45"),
    ("kenney_ui_button_rectangle_flat", "button_rectangle_flat.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/button_rectangle_flat.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §2.1 锁定/禁用态底图; modulate = 0.12,0.18,0.30,0.7"),
    ("kenney_ui_button_round_border", "button_round_border.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/button_round_border.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §2.1 圆角小按钮(槽位卡操作/返回)"),
    ("kenney_ui_button_square_border", "button_square_border.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/button_square_border.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §2.1 方按钮(英雄/关卡卡头像槽预留)"),
    ("kenney_ui_icon_circle", "icon_circle.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/icon_circle.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §3.3 战役海图已通节点 + Result 印记徽章(已通)"),
    ("kenney_ui_icon_checkmark", "icon_checkmark.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/icon_checkmark.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §3.5 Briefing 确认标记预留"),
    ("kenney_ui_icon_cross", "icon_cross.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/icon_cross.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §3.3 战役海图锁定节点; 形+色 双重编码 (PRD §13.1)"),
    ("kenney_ui_icon_square", "icon_square.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/icon_square.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §3.3 战役海图未通节点"),
    ("kenney_ui_star", "star.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/star.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §3.5 Result 印记徽章 1 颗 = 1 mark; modulate 已通亮 / 未通灰"),
    ("kenney_ui_arrow_basic_e", "arrow_basic_e.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/arrow_basic_e.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §3.4 Briefing 敌情列「下一项」"),
    ("kenney_ui_arrow_basic_w", "arrow_basic_w.png",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI Pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/ui/blue/Default/arrow_basic_w.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §3.2/3.4 屏标题左侧「返回」箭头"),
    # UI Audio 5 OGG (Kenney UI SFX Set, Kenney Vleugels, CC0 1.0)
    ("kenney_ui_audio_click1", "click1.ogg",
     "https://kenney.nl/assets/ui-audio", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE-UI-AUDIO.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI SFX Set by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/audio/click1.ogg",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §6 动作：ui_select (按钮悬停/聚焦); 8-bit click @ 44.1kHz; 文件缺失回退 AudioService 占位合成"),
    ("kenney_ui_audio_click3", "click3.ogg",
     "https://kenney.nl/assets/ui-audio", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE-UI-AUDIO.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI SFX Set by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/audio/click3.ogg",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §6 动作：ui_confirm (主确认 新档/进入下一关/开始战斗)"),
    ("kenney_ui_audio_switch1", "switch1.ogg",
     "https://kenney.nl/assets/ui-audio", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE-UI-AUDIO.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI SFX Set by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/audio/switch1.ogg",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §6 动作：ui_error (覆盖未确认/槽位已占用/非法)"),
    ("kenney_ui_audio_switch2", "switch2.ogg",
     "https://kenney.nl/assets/ui-audio", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE-UI-AUDIO.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI SFX Set by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/audio/switch2.ogg",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §6 动作：ui_transition (Title→Slot, Campaign→Briefing 等屏切换)"),
    ("kenney_ui_audio_mouserelease1", "mouserelease1.ogg",
     "https://kenney.nl/assets/ui-audio", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE-UI-AUDIO.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI SFX Set by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/audio/mouserelease1.ogg",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §6 动作：ui_cancel (Esc 取消/返回)"),
    # 2 个 License 文本副本（仅作台账项，不算美术/音频条目）
    ("kenney_ui_pack_license", "LICENSE.txt",
     "https://kenney.nl/assets/ui-pack-2-0", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt",
     "commercial + redistribution (CC0)", "no", "no",
     "n/a (license text only)", "yes",
     "assets/vendor/c01/kenney/LICENSE.txt",
     "license-text-only", "verified",
     "Kenney UI Pack 2.0 License.txt 文本副本; 同步入 doc/CREDITS.md 准备"),
    ("kenney_ui_audio_license", "LICENSE-UI-AUDIO.txt",
     "https://kenney.nl/assets/ui-audio", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt",
     "commercial + redistribution (CC0)", "no", "no",
     "n/a (license text only)", "yes",
     "assets/vendor/c01/kenney/LICENSE-UI-AUDIO.txt",
     "license-text-only", "verified",
     "Kenney UI SFX Set License.txt 文本副本"),
    # pirate pack 1 ship ornament (linter 增补)
    ("kenney_pirate_ship_01", "ship_01.png",
     "https://kenney.nl/assets/pirate-pack", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE-PIRATE-PACK.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "Pirate pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/nautical/ship_01.png",
     "integrated placeholder replacement", "verified",
     "C01 Style Bible §2.4 / §3.1 屏右下角装饰船型 (66x113); modulate = 0.78,0.60,0.30,0.20 (低对比装饰)"),
]

# 防御性：避免与既有 asset_id 重复
with open(LEDGER, encoding="utf-8") as f:
    existing_ids = set()
    for line in f.readlines()[1:]:
        first = line.split(",", 1)[0].strip()
        if first:
            existing_ids.add(first)

new_rows = []
skipped = []
for row in KENNEY_ROWS:
    if row[0] in existing_ids:
        skipped.append(row[0])
        continue
    new_rows.append(row)
    existing_ids.add(row[0])

print(f"Existing {len(existing_ids) - len(new_rows)} kenney rows; adding {len(new_rows)} new; skipped {len(skipped)} duplicates")

# 字段顺序
HEADER = "asset_id,file_name,source_url,author,download_date,license_name,license_text_ref,allowed_uses,modified,attribution_required,attribution_text,redistributable,project_path,replacement_status,status,notes"

def to_csv_line(t):
    # asset_id,file_name,source_url,author,download_date,license_name,license_text_ref,allowed_uses,modified,attribution_required,attribution_text,redistributable,project_path,replacement_status,status,notes
    return ",".join(quote(s) for s in t)

def quote(s):
    if s is None: return ""
    s = str(s)
    if any(c in s for c in [",", "\"", "\n"]):
        return "\"" + s.replace("\"", "\"\"") + "\""
    return s

# 写入（追加）
with open(LEDGER, "a", encoding="utf-8", newline="") as f:
    for row in new_rows:
        f.write(to_csv_line(row) + "\n")

print(f"Appended {len(new_rows)} rows to {LEDGER}")
print(f"Skipped: {skipped}")
