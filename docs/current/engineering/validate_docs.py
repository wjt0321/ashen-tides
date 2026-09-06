from pathlib import Path
from urllib.parse import unquote
import re

ROOT = Path(__file__).resolve().parents[3]
AUTHORITATIVE = [
    ROOT / "docs/current/engineering/RESEARCH_REPORT.md",
    ROOT / "docs/current/art/ASSET_CATALOG.md",
    ROOT / "docs/current/product/PRD.md",
    ROOT / "docs/current/product/PROJECT_EXECUTION_BASELINE.md",
    ROOT / "docs/current/art/ART_STYLE_BASELINE.md",
]
ARCHIVED_TODO = ROOT / "docs/archive/plans/TOWER_DEFENSE_TODO.md"
EXPECTED_DIRS = [
    ROOT / "docs/current/product",
    ROOT / "docs/current/art",
    ROOT / "docs/current/engineering",
    ROOT / "docs/current/quality",
    ROOT / "docs/archive/milestones",
    ROOT / "docs/archive/plans",
    ROOT / "docs/archive/reviews",
    ROOT / "docs/archive/drafts",
    ROOT / "docs/evidence/c01",
]
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")

failed = False
for path in AUTHORITATIVE:
    text = path.read_text(encoding="utf-8-sig")
    bad_cite = "turn0search" in text or "cite" in text
    print(
        f"{path.relative_to(ROOT).as_posix()}: "
        f"lines={len(text.splitlines())}, chars={len(text)}, "
        f"urls={text.count('http')}, bad_cite={bad_cite}"
    )
    failed |= bad_cite

for directory in EXPECTED_DIRS:
    exists = directory.is_dir()
    print(f"directory {directory.relative_to(ROOT).as_posix()}: exists={exists}")
    failed |= not exists

todo = ARCHIVED_TODO.read_text(encoding="utf-8-sig")
print(f"archived_open_todo={todo.count('- [ ]')}")

broken = []
markdown_files = [ROOT / "README.md", *sorted((ROOT / "docs").rglob("*.md"))]
for source in markdown_files:
    text = source.read_text(encoding="utf-8-sig")
    for raw in LINK_RE.findall(text):
        target = raw.strip()
        if not target or target.startswith(("#", "http://", "https://", "mailto:", "res://", "data:")):
            continue
        # Remove an optional quoted title and fragment.
        target = re.split(r"\s+[\"']", target, maxsplit=1)[0]
        target = target.split("#", 1)[0].strip("<>")
        if not target:
            continue
        candidate = (source.parent / unquote(target)).resolve()
        try:
            candidate.relative_to(ROOT)
        except ValueError:
            broken.append((source, raw, "outside repository"))
            continue
        if not candidate.exists():
            broken.append((source, raw, "missing"))

print(f"markdown_files={len(markdown_files)} broken_local_links={len(broken)}")
for source, target, reason in broken:
    print(f"BROKEN {source.relative_to(ROOT).as_posix()} -> {target} ({reason})")
failed |= bool(broken)
raise SystemExit(1 if failed else 0)
