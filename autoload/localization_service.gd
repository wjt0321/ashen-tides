extends Node
## LocalizationService：运行时从 res://data/i18n/ui.csv 构建 Translation 并注册（M2，PRD §12）。
## 不依赖编辑器导入的 .translation 二进制，保证 headless/命令行与导出包行为一致。
## CSV 格式：keys,zh_CN,en（首列 key 同时作为 StringName 查找键）。
## 语言持久化在 SettingsService 的 system/locale；切换后广播 EventBus.settings_applied 让 UI 刷新。

const CSV_PATH: String = "res://data/i18n/ui.csv"
const LOCALES: Array[String] = ["zh_CN", "en"]

var current_locale: String = "zh_CN"
var _missing_keys: Dictionary = {} ## key -> true（校验与调试，避免重复警告）


func _ready() -> void:
	_load_csv()
	var saved := String(SettingsService.get_value("system", "locale", "zh_CN"))
	set_locale(saved if LOCALES.has(saved) else "zh_CN")
	print("[M2] LocalizationService ready (locale=%s, keys=%d)" % [current_locale, TranslationServer.get_translation_object(current_locale).get_message_count() if TranslationServer.get_translation_object(current_locale) != null else 0])


func _load_csv() -> void:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("[M2] i18n csv missing: %s" % CSV_PATH)
		return
	var header := file.get_csv_line()
	var translations := {}
	for i: int in range(1, header.size()):
		var locale := header[i].strip_edges()
		var translation := Translation.new()
		translation.locale = locale
		translations[locale] = translation
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2 or row[0].strip_edges().is_empty():
			continue
		for i: int in range(1, mini(row.size(), header.size())):
			var locale: String = header[i].strip_edges()
			(translations[locale] as Translation).add_message(row[0], row[i])
	for locale: String in translations:
		TranslationServer.add_translation(translations[locale])


func set_locale(locale: String) -> void:
	if not LOCALES.has(locale):
		locale = "zh_CN"
	current_locale = locale
	TranslationServer.set_locale(locale)


func switch_locale(locale: String) -> void:
	set_locale(locale)
	SettingsService.set_value("system", "locale", current_locale)
	EventBus.settings_applied.emit()


## 缺失 key 时回退 key 本身并记录（工具 tools/check_i18n.gd 可汇总）。
func tr_key(key: StringName) -> String:
	var text := tr(key)
	if text == String(key) and not key.begins_with("ET_"):
		if not _missing_keys.has(key):
			_missing_keys[key] = true
			push_warning("[M2] i18n missing key: %s" % key)
	return text


func missing_keys() -> Array:
	return _missing_keys.keys()
