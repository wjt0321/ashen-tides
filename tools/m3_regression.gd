extends SceneTree
## M3 deterministic regression gate: compares standard steady builds at 1x/3x and resumed report.
const LEVELS := ["level_c04", "level_c05", "level_c06", "level_c07", "level_c08",
	"level_c09", "level_c10", "level_c11", "level_c12"] # M4-C：C09–C12 纳入 1×/3× 确定性门禁

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func _initialize() -> void:
	var failures: Array[String] = []
	for level_id: String in LEVELS:
		var one := _read("res://out/balance_%s_steady_speed1.0.json" % level_id)
		var three := _read("res://out/balance_%s_steady_speed3.0.json" % level_id)
		if one.is_empty() or three.is_empty():
			failures.append("missing standard speed pair " + level_id)
			continue
		for key: String in ["result", "tick_count", "kills", "leaks", "fleet_integrity", "phase"]:
			if one.get(key) != three.get(key): failures.append("standard speed mismatch %s.%s" % [level_id, key])
		if one.get("result") != "win": failures.append("standard build not win " + level_id)
	var resumed := _read("res://out/m3_smoke_level_c08_speed3.0_resumed.json")
	if resumed.is_empty() or resumed.get("result") != "win": failures.append("resume failed level_c08")
	print("[M3-REGRESSION] levels=%d failures=%d" % [LEVELS.size(), failures.size()])
	for failure: String in failures: printerr("[M3-REGRESSION] FAIL: " + failure)
	if failures.is_empty(): print("[M3-REGRESSION] PASS")
	quit(1 if not failures.is_empty() else 0)
