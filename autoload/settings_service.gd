extends Node
## SettingsService：玩家设置，ConfigFile -> user://settings.cfg（RESEARCH_REPORT.md §3.2 / §14.1）。
## M0 仅提供读写骨架与默认值；设置界面在后续里程碑实现。

const SETTINGS_PATH: String = "user://settings.cfg"

## (section, key) -> 默认值。独立音量与辅助选项要求见 PRD §10.2 / §13.1。
const DEFAULTS: Dictionary = {
	"audio/master_volume": 1.0,
	"audio/music_volume": 1.0,
	"audio/sfx_volume": 1.0,
	"audio/ambient_volume": 1.0,
	"audio/ui_volume": 1.0,
	"audio/voice_volume": 1.0,
	"display/ui_scale": 1.0,
	"gameplay/fixed_damage": false,
	"gameplay/auto_cast_basic": false,
	"accessibility/color_preset": "default",
	"accessibility/screen_shake": true,
	"accessibility/high_contrast": false,
	"accessibility/low_fx": false,
	"system/locale": "zh_CN",
}

var _config := ConfigFile.new()


func _ready() -> void:
	var err := _config.load(SETTINGS_PATH)
	_apply_defaults()
	if err == OK:
		print("[M0] SettingsService ready (loaded %s)" % SETTINGS_PATH)
	else:
		print("[M0] SettingsService ready (defaults, no existing settings.cfg)")
	save()


func _apply_defaults() -> void:
	for compound_key: String in DEFAULTS:
		var parts := compound_key.split("/", true, 1)
		if not _config.has_section_key(parts[0], parts[1]):
			_config.set_value(parts[0], parts[1], DEFAULTS[compound_key])


func get_value(section: String, key: String, fallback: Variant = null) -> Variant:
	var compound_key: String = "%s/%s" % [section, key]
	if fallback == null and DEFAULTS.has(compound_key):
		fallback = DEFAULTS[compound_key]
	return _config.get_value(section, key, fallback)


func set_value(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)
	save()


func save() -> Error:
	return _config.save(SETTINGS_PATH)
