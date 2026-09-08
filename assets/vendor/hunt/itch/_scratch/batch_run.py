"""Batch runner: process candidates and save per-game report JSON."""
import os, sys, json, time, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from dl_helper import fetch_one_game, SCRATCH

CANDIDATES = [
    # already downloaded
    ("mutterpixel-studio", "free-shark-enemy-pack-animated-pixel-art", "01_shark_pack"),
    ("mythical-the-dev", "ballista-pixel-sprite", "13_ballista"),
    ("frostwindz", "pixel-art-vfx-fire-explosions-free-version", "25_vfx_fire_expl_free"),
    # marine / sea enemies and terrain
    ("guilhermelaso", "coast-top-down-tiles", "09_coast_tiles"),
    ("gamedeveloperstudio", "top-down-sea-level-creator-set", "10_sea_level_creator"),
    ("nacl1234", "top-down-underwater-coral-reef-2d-mega-pack", "11_coral_reef"),
    ("gemau-cymru", "pixel-art-pirate-ship-boat-asset", "12_pirate_ship_boat"),
    ("kaiswerkstatt", "high-seas-pirate-ship-tiles-decorations", "08_highseas_ship"),
    # ships / sea
    ("dwaidev", "pixel-sail-ships", "37_pixel_sail_ships"),
    ("muchopixels", "pirate-ship-tileset-pack", "38_muchopixels_pirate_ship"),
    ("free-game-assets", "pirate-bay-tileset-pixel-art", "39_pirate_bay_tileset"),
    ("free-game-assets", "pirate-bay-bosses-pixel-art-pack", "40_pirate_bay_bosses"),
    ("godboyhappy", "haunted-ghost-ship-pixel-tileset-pack", "36_ghost_ship"),
    # towers / defense (free-game-assets has many named "free" but most are paid)
    ("valendremus", "tower-defense-towers-projectiles", "22_td_towers_proj"),
    ("auteddy", "tower-defense-tower-set-v1", "23_td_tower_set"),
    ("free-game-assets", "free-archer-towers-pixel-art-for-tower-defense", "14_archer_towers"),
    ("free-game-assets", "guardian-towers-pixel-art-for-tower-defense", "15_guardian_towers"),
    ("free-game-assets", "mage-towers-pixel-art-for-tower-defense", "16_mage_towers"),
    ("free-game-assets", "catapult-towers-pixel-art-for-tower-defense", "17_catapult_towers"),
    ("free-game-assets", "free-field-enemies-pixel-art-for-tower-defense", "18_field_enemies"),
    ("free-game-assets", "top-down-pixel-monster-sprites-for-tower-defense", "24_td_monsters"),
    # VFX
    ("jedimeisterx", "32-pixel-explosion-effects-pack-animated-48x48-vfx-9-frames", "26_32_pixel_explosions"),
    ("godboyhappy", "pyre-pixel-vfx-sprite-sheets", "27_pyre_vfx"),
    ("free-game-assets", "11-free-pixel-art-explosion-sprites", "28_11_free_explosions"),
    ("pimen", "explosion-effect", "29_pimen_explosion"),
    ("combosmooth", "vfx-pack", "30_combosmooth_vfx"),
    ("pewas", "pixel-rpg-vfx-pack-free-animated-effects", "31_pewas_vfx_free"),
    ("icemaan", "epic-explosions-pixel-vfx", "32_icemaan_explosions"),
    ("gyrossteelball", "top-down-bomb-imp-pixel-art-enemy4-directions-explosion-vfx", "33_bomb_imp"),
    ("infectedtribe", "pixel-explosion", "34_infectedtribe_explosion"),
]

OUT_BASE = "D:/mydev/games/Tower Defense/assets/vendor/hunt/itch"
REPORT_FILE = os.path.join(SCRATCH, "batch_results.json")
LOG_FILE = os.path.join(SCRATCH, "batch_log.txt")

if os.path.exists(LOG_FILE):
    try: os.remove(LOG_FILE)
    except: pass

results = []
for i, (author, slug, dir_name) in enumerate(CANDIDATES):
    save_dir = os.path.join(OUT_BASE, dir_name)
    print(f"\n===== [{i+1}/{len(CANDIDATES)}] {author}/{slug} =====")
    try:
        r = fetch_one_game(author, slug, save_dir, log_path=LOG_FILE)
    except Exception as e:
        r = {"author": author, "slug": slug, "error": f"exception: {e}"}
    summary = {k:v for k,v in r.items() if k not in ("page_html","purchase_page_html","download_page_html")}
    results.append(summary)
    # incremental save
    with open(REPORT_FILE, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    if i < len(CANDIDATES) - 1:
        time.sleep(3)  # politeness

print(f"\n=== BATCH DONE: {len(results)} candidates processed ===")
n_ok = sum(1 for r in results if r.get("files") and all("error" not in f for f in r["files"]))
n_partial = sum(1 for r in results if r.get("files") and any("error" in f for f in r["files"]))
n_fail = sum(1 for r in results if not r.get("files"))
print(f"  OK: {n_ok}, Partial: {n_partial}, Fail: {n_fail}")
print(f"  Report: {REPORT_FILE}")