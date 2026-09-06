# Repository Cleanup and Archive Implementation Plan

> **Date:** 2026-09-06
> **Status:** Completed
> **Design:** `2026-09-06-repository-cleanup-archive-design.md`

## Goal

Consolidate the accepted C01 presentation work into a stable repository baseline: preserve the approved art style, separate runtime and third-party art assets, organize current and historical documentation, remove completed/generated workspace debris, verify the project, and publish the result to `origin/main`.

## Constraints

- Preserve all accepted C01 code, art, data, and documentation changes.
- Keep later-chapter generated/legacy art folders untouched.
- Keep source archives, licenses, manifests, and attribution for third-party assets.
- Use repository-relative paths in documentation and `res://` paths at runtime.
- Do not persist proxy configuration; use `127.0.0.1:10808` only for the push command if required.

## Tasks

### 1. Capture the baseline

- Record Git status and current directory inventories.
- Confirm the approved C01 screenshots and source assets exist.
- Preserve the accepted dirty working tree without reset or checkout.

### 2. Preserve C01 evidence

- Create `docs/evidence/c01/`.
- Copy the seven approved title/campaign/briefing/battle/result screenshots from `out/` to stable descriptive filenames.
- Verify every evidence file is a readable, non-empty PNG before old generated output is removed.

### 3. Normalize art asset ownership

- Migrate the legacy C01 sprite directory into the final `assets/art/c01/runtime/` location.
- Move Foozle source material to `assets/vendor/c01/foozle/`.
- Move Kenney source material to `assets/vendor/c01/kenney/`.
- Update GDScript, tools, manifests, registries, license ledgers, and docs to the new paths.
- Verify runtime files and source attribution remain complete.

### 4. Establish the documentation taxonomy

- Keep `docs/README.md` as the documentation entry point.
- Move active product, art, engineering, and quality documents under `docs/current/`.
- Move completed milestone notes, implementation plans, reviews, and drafts under `docs/archive/`.
- Move Superpowers design/plan records into `docs/archive/plans/`.
- Rewrite internal links and path references, then validate that every local Markdown link resolves.

### 5. Clean completed and generated material

- Remove completed root-level `*_TODO.md` markers.
- Remove generated `ART_ASSET_REGISTRY.*.translation` artifacts.
- Remove verified staging/output directories: `third_party/`, `tool_results/`, and old `out/`.
- Retain only durable source, runtime, documentation, and evidence assets.

### 6. Update repository guidance and records

- Rewrite `docs/README.md` with the current/archive/evidence conventions.
- Update root `README.md`, `.gitignore`, the C01 style baseline, catalogs, credits, ledgers, and checklists to match the final layout.
- Add `docs/evidence/c01/VERIFICATION.md` with the final verification evidence and commands.

### 7. Verify the consolidated baseline

- Run a fresh Godot import.
- Run unit/integration tests and data/i18n validation.
- Run C01 smoke/performance validation.
- Run asset/license validation.
- Run documentation-link validation.
- Run `git diff --check` and inspect the final Git status/diff.

### 8. Publish

- Commit the accepted C01 implementation and repository consolidation.
- Push `main` to `origin/main` normally.
- If direct network access fails, retry only that push with temporary HTTP/HTTPS proxy environment variables pointing at `127.0.0.1:10808`.

## Completion Record

Completed on 2026-09-06. The final repository uses the approved current/archive/evidence taxonomy, C01 runtime/vendor asset paths are consolidated, accepted screenshots are tracked as evidence, disposable workspace material is removed from version control scope, and all documented verification commands pass. One ignored local recording file remained open by an external QwenPaw backend process during cleanup; it is not part of the repository or commit.
