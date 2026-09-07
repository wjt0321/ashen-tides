#!/usr/bin/env python3
"""C01+C02 v2 自绘像素资产 → 运行时 PNG + DERIVED_MANIFEST 重建。

作者库 tools/pixel_v2.py（作者网格 = 运行时 / 2，NEAREST ×2）。
C01 契约：enemy 512x192(8x3x64) / tower 576x96(6x96) / props 1024x128(8x128)
          / 6x 640x360 背景 + briefing_map 320x180。
C02 契约：tower/enemy 64x64（含 protan/deutan/tritan）/ gate 160x112 /
          fx 96x32 / projectile 16x16（无变体）。
"""
import csv
import hashlib
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
import pixel_v2 as pv  # noqa: E402

C01 = ROOT / "assets" / "art" / "c01" / "runtime"
C02 = ROOT / "assets" / "art" / "c02" / "runtime"
LEDGER = ROOT / "ASSET_LICENSE_LEDGER.csv"
REGISTRY = ROOT / "ART_ASSET_REGISTRY.csv"
EVIDENCE = [
    "docs/evidence/c01/title.png",
    "docs/evidence/c01/campaign.png",
    "docs/evidence/c01/briefing.png",
    "docs/evidence/c01/battle-early.png",
    "docs/evidence/c01/battle-busy.png",
    "docs/evidence/c01/result-win.png",
    "docs/evidence/c01/result-lose.png",
]
GENERATED_ON = "2026-09-08"
BUILDER = "tools/build_v2_assets.py"
SOURCE = "Ember Tide dev v2 hand-authored pixel art (tools/pixel_v2.py)"
SUPERSEDE_NOTE = ("Foozle-derived C01 raster superseded 2026-09-08 by v2 hand-authored art; "
                  "vendor archives retained as CC0 source provenance")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def enemy_sheet(side, front, back):
    im = Image.new("RGBA", (512, 192), (0, 0, 0, 0))
    for row, frames in enumerate((side, front, back)):
        for col, fr in enumerate(frames):
            big = pv.x2(fr)
            im.paste(big, (col * 64, row * 64), big)
    return im


def tower_sheet():
    im = Image.new("RGBA", (576, 96), (0, 0, 0, 0))
    for f in range(6):
        big = pv.x2(pv.needle_frame(f))
        im.paste(big, (f * 96, 0), big)
    return im


def projectile_ember():
    src = pv.ember_burst()
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    im.paste(src, (0, (16 - src.height) // 2), src)
    return im


def save(im: Image.Image, directory: Path, name: str, variants=False):
    path = directory / name
    im.save(path)
    out = [name]
    if variants:
        for preset in ("protan", "deutan", "tritan"):
            vname = path.stem + "_" + preset + ".png"
            pv.remap(im, preset).save(directory / vname)
            out.append(vname)
    return out


def build_c01():
    names = []
    names += save(pv.battle_background(), C01, "battle_background.png")
    names += save(pv.poster(2), C01, "briefing_background.png")
    names += save(pv.briefing_map(), C01, "briefing_map.png")
    names += save(pv.poster(1), C01, "campaign_background.png")
    names += save(enemy_sheet(pv.salt_frames(), pv.salt_front_frames(), pv.salt_back_frames()),
                  C01, "enemy_salt_shell.png")
    names += save(enemy_sheet(pv.rat_frames(), pv.rat_front_frames(), pv.rat_back_frames()),
                  C01, "enemy_mast_rat.png")
    names += save(pv.props_atlas().resize((1024, 128), Image.NEAREST), C01, "harbor_props.png")
    names += save(pv.poster(4), C01, "result_lose_background.png")
    names += save(pv.poster(3), C01, "result_win_background.png")
    names += save(pv.poster(0), C01, "title_background.png")
    names += save(tower_sheet(), C01, "tower_needle_rail.png")
    return names


def build_c02():
    names = []
    for tier in (1, 2, 3, 4):
        names += save(pv.x2(pv.well_tier(tier)), C02, f"tower_ember_well_tier{tier}.png", True)
        names += save(pv.x2(pv.rail_tier(tier)), C02, f"tower_needle_rail_tier{tier}.png", True)
    names += save(pv.x2(pv.dasher_frames()[0]), C02, "enemy_splitfin_dasher.png", True)
    names += save(pv.x2(pv.render(pv._RAT_SWARM)), C02, "enemy_mast_rat_swarm.png", True)
    names += save(pv.x2(pv.carrier_frames()[0]), C02, "enemy_rust_armor_carrier.png", True)
    names += save(pv.x2(pv.tide_gate(False)), C02, "tide_gate_closed.png")
    names += save(pv.x2(pv.tide_gate(True)), C02, "tide_gate_open.png")
    names += save(projectile_ember(), C02, "projectile_ember_burst.png")
    names += save(pv.x2(pv.tide_fx_strip()), C02, "fx_tide_gate_strip3.png")
    return names


def write_manifest(directory: Path, names):
    files = {}
    for name in sorted(set(names)):
        path = directory / name
        files[name] = {"sha256": sha256(path), "bytes": path.stat().st_size}
    data = {
        "generated_on": GENERATED_ON,
        "builder": BUILDER,
        "source": SOURCE,
        "files": files,
    }
    (directory / "DERIVED_MANIFEST.json").write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return files


def sync_governance(c01_files):
    with LEDGER.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        fields = reader.fieldnames
        ledger = list(reader)
    have = {row["asset_id"] for row in ledger}
    for row in ledger:
        if row["asset_id"].startswith("c01_foozle_"):
            row["project_path"] = "n/a (runtime overwritten by c01_v2_*)"
            row["replacement_status"] = "superseded by c01_v2_*"
            row["status"] = "superseded"
            row["notes"] = SUPERSEDE_NOTE
        elif row["asset_id"] == "c02_tide_gate_presentation":
            row["notes"] = ("C02专属潮门、潮汐敌、双塔等级、余烬弹体与相位 FX；"
                            "生成器 tools/build_v2_assets.py（v2 自绘）")
    for name, meta in sorted(c01_files.items()):
        aid = "c01_v2_" + Path(name).stem
        if aid in have:
            continue
        ledger.append({
            "asset_id": aid,
            "file_name": name,
            "source_url": "n/a (generated)",
            "author": "Ember Tide dev (v2 hand-authored pixel grid)",
            "download_date": GENERATED_ON,
            "license_name": "Project-owned (original)",
            "license_text_ref": "n/a",
            "allowed_uses": "all",
            "modified": "no",
            "attribution_required": "no",
            "attribution_text": "n/a",
            "redistributable": "yes",
            "project_path": f"assets/art/c01/runtime/{name}",
            "replacement_status": "integrated",
            "status": "verified",
            "notes": (f"generated by {BUILDER}; SHA256={meta['sha256']}; "
                      f"bytes={meta['bytes']}; v2 hand-authored supersedes Foozle raster"),
        })
    with LEDGER.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(ledger)

    with REGISTRY.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        rfields = reader.fieldnames
        registry = list(reader)
    rids = {row["asset_id"] for row in registry}
    for row in registry:
        if row["asset_id"] == "C01_FOOZLE_RASTER_PRESENTATION":
            row["art_status"] = "Reference-only"
            row["placeholder"] = "true"
            row["active_version"] = "superseded-by-v2-handauthored"
            row["visual_qa_evidence"] = ""
            row["approval_record"] = (row["approval_record"] +
                                      " | 2026-09-08 superseded by owner work order (v2 hand-authored)")
    if "C01_V2_HANDAUTHORED_PRESENTATION" not in rids:
        anim = ("salt_shell 8x3(side/front/back); mast_rat 8x3(side/front/back); needle_rail 6; "
                "flow backgrounds 6; briefing map 1; harbor props atlas")
        registry.append({
            "asset_id": "C01_V2_HANDAUTHORED_PRESENTATION",
            "runtime_ids": "level_c01;tower_needle_rail;salt_shell_walker;mast_rat_swarm;C01 flow shell",
            "chapter": "prologue",
            "first_level": "C01",
            "asset_lifecycle_status": "Implemented",
            "art_status": "Integrated",
            "placeholder": "false",
            "active_version": "v2-handauthored",
            "source_hash": "",
            "export_hash": "",
            "license_ledger_id": "c01_v2_*",
            "required_animations": anim,
            "completed_animations": anim,
            "visual_qa_evidence": "; ".join(EVIDENCE),
            "player_test_evidence": ("automated C01 smoke; owner work-order 2026-09-08 redo; "
                                     "external player recognition test still required"),
            "approved_by": "project owner (user)",
            "approval_record": ("2026-09-08: 工作单『C01 也不好看，重做两关』授权自绘 v2 "
                                "取代 Foozle 基线（两关全量一次铺开）"),
            "target_build": "C01/C02 v2 visual baseline",
        })
    with REGISTRY.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=rfields)
        writer.writeheader()
        writer.writerows(registry)


def main():
    c01 = build_c01()
    c02 = build_c02()
    m1 = write_manifest(C01, c01)
    m2 = write_manifest(C02, c02)
    sync_governance(m1)
    print(f"c01 files={len(m1)} c02 files={len(m2)}")
    for name, meta in m1.items():
        print(f"  c01/{name} {meta['bytes']}B {meta['sha256'][:12]}")


if __name__ == "__main__":
    main()
