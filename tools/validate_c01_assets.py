from pathlib import Path
import csv
import hashlib
import json
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
SOURCE_MANIFEST = ROOT / "assets/vendor/c01/foozle/SOURCE_MANIFEST.json"
DERIVED_MANIFEST = ROOT / "assets/art/c01/runtime/DERIVED_MANIFEST.json"
LEDGER = ROOT / "ASSET_LICENSE_LEDGER.csv"
REGISTRY = ROOT / "ART_ASSET_REGISTRY.csv"
EVIDENCE = ROOT / "docs/evidence/c01"
EXPECTED_EVIDENCE = {
    "title.png",
    "campaign.png",
    "briefing.png",
    "battle-early.png",
    "battle-busy.png",
    "result-win.png",
    "result-lose.png",
}

errors = []

def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

source = json.loads(SOURCE_MANIFEST.read_text(encoding="utf-8-sig"))
for item in source["items"]:
    path = ROOT / item["archive"]
    if not path.is_file():
        errors.append(f"missing source archive: {item['archive']}")
        continue
    if path.stat().st_size != item["bytes"]:
        errors.append(f"source size mismatch: {item['archive']}")
    if sha256(path) != item["sha256"]:
        errors.append(f"source hash mismatch: {item['archive']}")

derived = json.loads(DERIVED_MANIFEST.read_text(encoding="utf-8-sig"))
for name, metadata in derived["files"].items():
    path = DERIVED_MANIFEST.parent / name
    if not path.is_file():
        errors.append(f"missing derived asset: {path.relative_to(ROOT).as_posix()}")
        continue
    if path.stat().st_size != metadata["bytes"]:
        errors.append(f"derived size mismatch: {name}")
    if sha256(path) != metadata["sha256"]:
        errors.append(f"derived hash mismatch: {name}")

ledger_vendor_rows = 0
with LEDGER.open(encoding="utf-8-sig", newline="") as handle:
    for row in csv.DictReader(handle):
        project_path = row["project_path"].strip()
        if not project_path.startswith("assets/vendor/c01/"):
            continue
        ledger_vendor_rows += 1
        path = ROOT / project_path
        if not path.is_file():
            errors.append(f"ledger path missing: {project_path}")
        else:
            recorded_hash = re.search(r"sha256=([0-9a-fA-F]{64})", row["notes"])
            if recorded_hash and sha256(path) != recorded_hash.group(1).lower():
                errors.append(f"ledger hash mismatch: {project_path}")
        license_ref = row["license_text_ref"]
        for ref in (part.strip() for part in license_ref.split("+") if part.strip()):
            if ref.startswith(("assets/", "licenses/")) and not (ROOT / ref).is_file():
                errors.append(f"license reference missing: {ref}")

with REGISTRY.open(encoding="utf-8-sig", newline="") as handle:
    rows = {row["asset_id"]: row for row in csv.DictReader(handle)}
row = rows.get("C01_FOOZLE_RASTER_PRESENTATION")
if row is None:
    errors.append("registry row missing: C01_FOOZLE_RASTER_PRESENTATION")
else:
    if row["placeholder"].lower() != "false" or row["art_status"] != "Integrated":
        errors.append("C01 final presentation registry state is not Integrated/non-placeholder")
    evidence_paths = {part.strip() for part in row["visual_qa_evidence"].split(";") if part.strip()}
    for rel in evidence_paths:
        if not (ROOT / rel).is_file():
            errors.append(f"registry evidence missing: {rel}")

for name in EXPECTED_EVIDENCE:
    path = EVIDENCE / name
    if not path.is_file():
        errors.append(f"missing C01 evidence: {name}")
        continue
    data = path.read_bytes()
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        errors.append(f"invalid PNG evidence: {name}")
        continue
    width, height = struct.unpack(">II", data[16:24])
    if (width, height) != (640, 360):
        errors.append(f"unexpected evidence dimensions: {name}={width}x{height}")

vendor_payloads = [
    path for path in (ROOT / "assets/vendor/c01").rglob("*")
    if path.is_file() and path.suffix.lower() in {".png", ".ogg", ".zip"}
]
print(
    f"C01-ASSETS source_archives={len(source['items'])} "
    f"derived={len(derived['files'])} vendor_payloads={len(vendor_payloads)} "
    f"ledger_rows={ledger_vendor_rows} evidence={len(EXPECTED_EVIDENCE)} errors={len(errors)}"
)
for error in errors:
    print(f"ERROR {error}")
raise SystemExit(1 if errors else 0)
