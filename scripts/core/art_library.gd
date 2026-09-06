class_name ArtLibrary
extends RefCounted
## M4-A 正式资产加载层：按规范路径加载 PNG，缓存；缺失时返回 null（调用方回退程序化绘制）。
## 规范见 docs/current/engineering/M4_ASSET_SPEC.md §5/§6：命名与数据层 id 一致、必须有程序化回退。

const TOWER_DIR := "res://assets/art/towers/"
const ENEMY_DIR := "res://assets/art/enemies/"
const HERO_DIR := "res://assets/art/characters/"
const TERRAIN_DIR := "res://assets/art/tilesets/"
const VFX_DIR := "res://assets/art/vfx/"
const UI_DIR := "res://assets/art/ui/"

static var _cache: Dictionary = {}


static func _load_cached(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_cache[path] = tex
	return tex


## M4-B 色弱适配：非默认预设时优先加载 <stem>_<preset>.png 变体（生成器同矩阵），缺失回退基础图。
static func _unit_cached(base_path: String) -> Texture2D:
	var preset := UiPalette.preset()
	if preset != &"default":
		var variant := base_path.get_basename() + "_" + String(preset) + ".png"
		var tex := _load_cached(variant)
		if tex != null:
			return tex
	return _load_cached(base_path)


static func tower_tex(tower_id: StringName) -> Texture2D:
	return _unit_cached(TOWER_DIR + "tower_" + String(tower_id).trim_prefix("tower_") + ".png")


static func enemy_tex(enemy_id: StringName) -> Texture2D:
	return _unit_cached(ENEMY_DIR + "enemy_" + String(enemy_id) + ".png")


static func hero_tex(hero_id: StringName) -> Texture2D:
	return _unit_cached(HERO_DIR + "hero_" + String(hero_id) + ".png")


## level_id 例：&"level_c01" → tilesets/c01/terrain_<name>.png
static func terrain_tex(level_id: StringName, tile_name: String) -> Texture2D:
	var chapter := String(level_id).trim_prefix("level_")
	return _load_cached(TERRAIN_DIR + chapter + "/terrain_" + tile_name + ".png")


static func vfx_tex(strip_name: String) -> Texture2D:
	return _load_cached(VFX_DIR + strip_name + ".png")


static func ui_icon(icon_name: String) -> Texture2D:
	return _load_cached(UI_DIR + icon_name + ".png")
