extends SceneTree
## M3 performance gate: checks C04-C08 reports and fixed tick accounting.
const LEVELS := ["level_c04", "level_c05", "level_c06", "level_c07", "level_c08"]
func _initialize() -> void:
	var failures: Array[String] = []
	for level_id: String in LEVELS:
		var path := "res://out/m3_perf_%s.json" % level_id
		if not FileAccess.file_exists(path): failures.append("missing " + path); continue
		var file := FileAccess.open(path, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(file.get_as_text()); file.close()
		if not (parsed is Dictionary): failures.append("invalid json " + path); continue
		if float(parsed.get("avg_fps", 0.0)) <= 0.0 or float(parsed.get("low1_fps", 0.0)) <= 0.0: failures.append("invalid fps " + level_id)
		if int(parsed.get("ticks", 0)) <= 0: failures.append("no ticks " + level_id)
	print("[M3-PERF] levels=%d failures=%d" % [LEVELS.size(), failures.size()])
	for failure: String in failures: printerr("[M3-PERF] FAIL: " + failure)
	if failures.is_empty(): print("[M3-PERF] PASS")
	quit(1 if not failures.is_empty() else 0)
