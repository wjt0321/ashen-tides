#!/usr/bin/env python3
"""Append linter-added Kenney files (ship_01, explosion_01, rollover1) to ledger.
保持 ledger 与 vendor 实际目录一致。"""
import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LEDGER = os.path.join(ROOT, "ASSET_LICENSE_LEDGER.csv")

EXTRAS = [
    ("kenney_ui_audio_rollover1", "rollover1.ogg",
     "https://kenney.nl/assets/ui-audio", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE-UI-AUDIO.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "UI SFX Set by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/audio/rollover1.ogg",
     "integrated placeholder replacement", "verified",
     "Kenney UI Audio 备选悬停; 本批未在 AppFlow 直接调用; 留作 M5+ 备用"),
    ("kenney_pirate_fx_explosion_01", "explosion_01.png",
     "https://kenney.nl/assets/pirate-pack", "Kenney Vleugels (kenney.nl)", "2026-09-06",
     "CC0-1.0", "licenses/CC0-1.0.txt + assets/vendor/c01/kenney/LICENSE-PIRATE-PACK.txt",
     "commercial + redistribution (CC0)", "no", "recommended-not-required",
     "Pirate pack by Kenney (kenney.nl)", "yes",
     "assets/vendor/c01/kenney/fx/explosion_01.png",
     "reference only", "verified",
     "Kenney Pirate Pack 爆炸 FX 参考; 战斗内 FX 由 M3+ 美术管线统一制作,本批不接入"),
]

with open(LEDGER, encoding="utf-8") as f:
    existing = set(line.split(",", 1)[0].strip() for line in f.readlines()[1:] if line.strip())

added, skipped = [], []
for row in EXTRAS:
    if row[0] in existing:
        skipped.append(row[0]); continue
    added.append(row); existing.add(row[0])

def quote(s):
    s = "" if s is None else str(s)
    return "\"" + s.replace("\"", "\"\"") + "\"" if any(c in s for c in [",", "\"", "\n"]) else s

with open(LEDGER, "a", encoding="utf-8", newline="") as f:
    for row in added:
        f.write(",".join(quote(s) for s in row) + "\n")

print(f"Added {len(added)}, skipped {len(skipped)} (duplicates).")
print("Skipped:", skipped)
