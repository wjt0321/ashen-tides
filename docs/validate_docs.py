from pathlib import Path

files = ["RESEARCH_REPORT.md", "ASSET_CATALOG.md", "PRD.md"]
failed = False
for name in files:
    path = Path(name)
    text = path.read_text(encoding="utf-8")
    bad_cite = "turn0search" in text or "cite" in text
    print(f"{name}: lines={len(text.splitlines())}, chars={len(text)}, urls={text.count('http')}, bad_cite={bad_cite}")
    failed |= bad_cite

todo = Path("TOWER_DEFENSE_TODO.md").read_text(encoding="utf-8")
print(f"open_todo={todo.count('- [ ]')}")
raise SystemExit(1 if failed else 0)
