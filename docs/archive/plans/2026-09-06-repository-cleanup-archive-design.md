# Repository Cleanup and Archive Design

> **Date:** 2026-09-06
> **Approved approach:** Scheme A — layered current documentation, traceable archive, dedicated C01 art/vendor folders, cleanup of completed local artifacts, final commit and push to `origin/main`.

## 1. Goals

1. Keep the repository root focused on runtime code and project-wide registries.
2. Separate current authoritative documentation from historical milestones, reviews, drafts, and completed plans.
3. Keep C01 runtime art and third-party source packages in dedicated C01 folders.
4. Remove completed root TODO markers and disposable local staging/output directories.
5. Preserve final C01 screenshots as tracked evidence rather than references to ignored `out/` files.
6. Update every code, manifest, CSV, Markdown, and Godot resource reference after moves.
7. Verify the complete project, commit the accepted C01 work plus reorganization, and push to `origin/main`.

## 2. Documentation Layout

`docs/README.md` remains the entry point. All other project documents move into one of these folders:

```text
docs/
├─ README.md
├─ current/
│  ├─ product/
│  ├─ art/
│  ├─ engineering/
│  └─ quality/
├─ archive/
│  ├─ milestones/
│  ├─ plans/
│  ├─ reviews/
│  └─ drafts/
└─ evidence/
   └─ c01/
```

### Current product

- `PRD.md`
- `PROJECT_EXECUTION_BASELINE.md`
- `CHECKLIST.md`

### Current art

- `ART_STYLE_BASELINE.md`
- `ASSET_CATALOG.md`
- `ART_PRODUCTION_PLAN.md`
- `C01_STYLE_BIBLE.md`
- `C01_RESOURCE_DECISIONS.md`
- `CREDITS.md`

### Current engineering

- `RESEARCH_REPORT.md`
- `OPEN_SOURCE_TD_RESEARCH.md`
- `M4_ASSET_SPEC.md`
- `M4_ASSET_PIPELINE.md`
- `validate_docs.py`

### Current quality

- `PLAYER_EXPERIENCE_AUDIT.md`
- `gates/M2-GATE.yaml`

### Archive

- `archive/milestones/`: M1/M2/M3/M4 and NEXT_PHASE implementation notes.
- `archive/plans/`: completed TODOs and agent implementation plans/specs.
- `archive/reviews/`: historical product, technical-license, and gate reviews.
- `archive/drafts/`: framework, technical, and asset/audio drafts.

Archived files remain readable and link-correct, but do not define current project authority.

## 3. Asset Layout

```text
assets/
├─ art/
│  ├─ c01/
│  │  └─ runtime/
│  └─ ... existing legacy/generated C02+ folders
└─ vendor/
   └─ c01/
      ├─ foozle/
      └─ kenney/
```

Rules:

- Migrate the former C01 sprite staging directory into `assets/art/c01/runtime/*`.
- Consolidate Foozle source material under `assets/vendor/c01/foozle/*`.
- Consolidate Kenney source material under `assets/vendor/c01/kenney/*`.
- Do not move or delete the existing legacy/generated C02+ art folders because current runtime still uses them.
- Update GDScript constants, Python builder paths, source/derived manifests, ledger paths, registry globs, credits, and art documentation.
- Godot `.import` files are generated cache metadata and are not tracked; path changes are validated by a fresh editor import.

## 4. Evidence and Cleanup

Copy the seven accepted C01 screenshots into `docs/evidence/c01/`:

- `title.png`
- `campaign.png`
- `briefing.png`
- `battle-early.png`
- `battle-busy.png`
- `result-win.png`
- `result-lose.png`

Update `ART_ASSET_REGISTRY.csv` and current docs to reference these tracked paths.

Remove disposable local content after verifying absolute workspace paths:

- root `*_TODO.md` marker files that are ignored/untracked and represent completed work;
- generated root `ART_ASSET_REGISTRY.*.translation` files;
- `third_party/` staging downloads;
- `tool_results/` inspection artifacts;
- old `out/` content after final evidence has been copied.

Verification will recreate a small `out/` directory. After recording the final verification summary in `docs/evidence/c01/VERIFICATION.md`, remove the regenerated local `out/` directory again so the workspace is clean of completed evidence artifacts.

Do not delete source archives under `assets/vendor/c01/foozle/source_archives/`, license files, manifests, or any runtime asset.

## 5. Reference Migration

Use an explicit old-to-new path map. Update:

- relative Markdown links based on each document’s new parent folder;
- plain-text/backtick paths used as policy references;
- GDScript and Python `res://`/filesystem paths;
- `ASSET_LICENSE_LEDGER.csv`, `ART_ASSET_REGISTRY.csv`, and `SOURCE_MANIFEST.json`;
- root `README.md`, `docs/README.md`, code comments, and generator comments.

A repository-wide stale-reference check must find no old active path references except deliberate historical prose inside archived records. Historical prose should still use valid current links when it claims a file is currently available.

## 6. Git and Push

- Work on the existing `main` branch because the user explicitly approved direct push to `origin/main`.
- Preserve all current C01 implementation changes in the final commit; do not discard unrelated dirty changes already included in the accepted C01 slice.
- Before commit, run import, all tests, data validation, i18n validation, deterministic C01 smoke/performance, document/link validation, asset/license hash validation, and `git diff --check`.
- Commit only after all required verification succeeds.
- Push with normal network settings first. If GitHub access fails, retry the push with temporary HTTP/HTTPS proxy `http://127.0.0.1:10808` applied to that command only.
- Do not persist proxy configuration in Git or global Git settings.

## 7. Status Semantics

- The C01 visual direction remains project-owner approved and `placeholder=false`.
- The asset art status remains `Integrated` until external player recognition and full Visual-QA gates are complete.
- Reorganization does not promote the project to Release-ready or Shipping.
- `docs/current/art/ART_STYLE_BASELINE.md` is the sole final visual authority for C02 and all later levels.

## 8. Acceptance Criteria

- Repository root contains no completed ignored TODO marker files or generated translation artifacts.
- `third_party/`, `tool_results/`, and stale `out/` content are removed.
- All current and archived documents are placed according to the documented folder standard.
- C01 runtime and vendor art are under dedicated C01 folders.
- Seven accepted screenshots and a verification summary are tracked under `docs/evidence/c01/`.
- No stale runtime path remains.
- Godot import has zero parse/compile/import errors.
- Tests, data validation, i18n, document checks, and asset/license checks pass; C01 remains exactly 7017 ticks / 90 kills / 0 gameplay leaks / integrity 20.
- Final commit is pushed successfully to `origin/main`.
