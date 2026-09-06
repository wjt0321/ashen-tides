# C01 Consolidated Baseline Verification

> **Verified:** 2026-09-06
> **Godot:** 4.7.2-stable (`ed1daf0bf`)
> **Scope:** accepted C01 presentation, art-path consolidation, documentation archive, and repository cleanup

## Result

The accepted C01 presentation remains functional after moving runtime art to `assets/art/c01/runtime/`, consolidating third-party sources under `assets/vendor/c01/`, and reorganizing documentation under `docs/current/` and `docs/archive/`.

| Check | Result |
|---|---|
| Fresh headless editor import | Exit 0; asset reimport completed; no script/import errors observed |
| Automated tests | `pass=493 fail=0` |
| Data validation | `checked=243 errors=0` |
| Localization validation | `referenced=216 defined=264 missing=0` |
| Documentation validation | 35 Markdown files; 0 broken local links |
| C01 asset validation | 5 Foozle source archives; 11 derived runtime assets; 26 vendor payloads; 51 ledger rows; 7 evidence images; 0 errors |
| C01 smoke | win; 6/6 waves; 90 kills; 0 enemy leaks; integrity 20; 3/3 marks; 7017 fixed ticks |
| C01 performance | 144.5 average FPS; 105.9 FPS 1% low; 640×360; Forward+; 3× simulation speed |
| Git whitespace check | Pass; no whitespace errors |

## Commands

```powershell
& 'D:\mydev\games\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --quit
& 'D:\mydev\games\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tools/run_tests.gd
& 'D:\mydev\games\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tools/validate_data.gd
& 'D:\mydev\games\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tools/check_i18n.gd
& 'D:\mydev\games\Godot_v4.7.2-stable_win64_console.exe' --headless --path . -- --level=level_c01 --m2-perf
python docs/current/engineering/validate_docs.py
python tools/validate_c01_assets.py
git diff --check
```

## Accepted Visual Evidence

- [Title](title.png)
- [Campaign](campaign.png)
- [Briefing](briefing.png)
- [Battle — early](battle-early.png)
- [Battle — busy](battle-busy.png)
- [Result — win](result-win.png)
- [Result — lose](result-lose.png)

## Diagnostic Note

The C01 performance run exited successfully but Godot printed `6 ObjectDB instances were leaked at exit`. This is an engine-shutdown diagnostic, distinct from the smoke report's `0` enemy leaks. It does not invalidate the gameplay, data, asset, documentation, or performance results above, but remains visible here rather than being silently omitted.
