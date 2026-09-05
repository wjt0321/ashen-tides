extends SceneTree
## M3 smoke aggregator: verifies C01-C12 report contracts after main.gd runs.
const LEVELS := ["level_c01", "level_c02", "level_c03", "level_c04", "level_c05", "level_c06", "level_c07", "level_c08",
	"level_c09", "level_c10", "level_c11", "level_c12"]
func _initialize() -> void:
	var failures: Array[String] = []
	for level_id: String in LEVELS:
		var path := "res://out/%s_smoke_%s_speed3.0.json" % ["m3" if level_id >= "level_c04" else "m2", level_id]
		if not FileAccess.file_exists(path):
			failures.append("missing " + path)
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if not (parsed is Dictionary):
			failures.append("invalid json " + path)
			continue
		if parsed.get("result") != "win": failures.append("not win " + level_id)
		if int(parsed.get("fixed_tick_hz", 0)) != 60: failures.append("tick != 60 " + level_id)
		if int(parsed.get("waves_started", 0)) < 6: failures.append("insufficient waves " + level_id)
	print("[M3-SMOKE] levels=%d failures=%d" % [LEVELS.size(), failures.size()])
	for failure: String in failures: printerr("[M3-SMOKE] FAIL: " + failure)
	if failures.is_empty(): print("[M3-SMOKE] PASS")
	quit(1 if not failures.is_empty() else 0)
