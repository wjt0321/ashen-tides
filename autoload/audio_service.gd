extends Node
## AudioService：M2 音频总线与事件接口（占位合成音，零外部资产依赖）。
## - 音量：读取 SettingsService 的 audio/<bus>_volume（线性 0.0–1.0）换算各 bus volume_db（PRD §10.2）。
## - 事件：连接 EventBus 现有信号 -> play_event()，事件 id 与信号一一映射（见 _connect_event_bus）。
## - 占位音：按事件类别用固定基频/时长/波形合成 16-bit PCM -> AudioStreamWAV 并缓存复用
##   （等价于把 AudioStreamGenerator 输出离线渲染成 wav；Deterministic，每类事件参数恒定）。
## 依赖规则：AutoLoad 只依赖已注册单例（SettingsService / EventBus），不依赖其他模块 _init。

const MIX_RATE: int = 22050

# 占位音波形
const WAVE_SINE: int = 0
const WAVE_SQUARE: int = 1
const WAVE_SAW: int = 2

# 播放池：SFX 12 个 + UI 4 个 = 16（任务规格）；UI 类事件走 "UI" bus，服从 ui_volume。
const POOL_SFX_COUNT: int = 12
const POOL_UI_COUNT: int = 4

## bus -> SettingsService 音量键。Voice 暂未定义独立设置键，回退 1.0（由 Master 统一兜底）。
const BUS_VOLUME_KEYS: Dictionary = {
	&"Master": "master_volume",
	&"Music": "music_volume",
	&"SFX": "sfx_volume",
	&"Ambient": "ambient_volume",
	&"UI": "ui_volume",
	&"Voice": "voice_volume",
}

## 未注册事件的回退事件。
const FALLBACK_EVENT: StringName = &"ui_denied"

# 事件目录：event_id -> {"bus": bus 名, "notes": [{start_ms, dur_ms, f0[, f1], wave, amp}]}。
# f1 省略时等于 f0（定频）；f0 != f1 时为线性滑频；amp 为单音振幅。参数全部固定 -> Deterministic。
const EVENT_CATALOG: Dictionary = {
	# —— 塔（PRD §6 / §8）——
	&"tower_fire": {"bus": &"SFX", "notes": [
		{"start_ms": 0.0, "dur_ms": 60.0, "f0": 880.0, "wave": WAVE_SINE, "amp": 0.30},
	]},
	# C01 第二批：按塔职责分开的确定性合成候选；仅 Integrated candidate，非最终音频。
	&"tower_needle_attack": {"bus": &"SFX", "notes": [
		{"start_ms": 0.0, "dur_ms": 42.0, "f0": 1450.0, "f1": 980.0, "wave": WAVE_SQUARE, "amp": 0.18},
	]},
	&"tower_ember_attack": {"bus": &"SFX", "notes": [
		{"start_ms": 0.0, "dur_ms": 120.0, "f0": 210.0, "f1": 95.0, "wave": WAVE_SAW, "amp": 0.20},
	]},
	&"tower_echo_pulse": {"bus": &"SFX", "notes": [
		{"start_ms": 0.0, "dur_ms": 180.0, "f0": 420.0, "f1": 690.0, "wave": WAVE_SINE, "amp": 0.18},
		{"start_ms": 30.0, "dur_ms": 150.0, "f0": 840.0, "wave": WAVE_SINE, "amp": 0.08},
	]},
	&"combat_hit": {"bus": &"SFX", "notes": [
		{"start_ms": 0.0, "dur_ms": 38.0, "f0": 1180.0, "f1": 520.0, "wave": WAVE_SQUARE, "amp": 0.12},
	]},
	&"tower_place": {"bus": &"SFX", "notes": [
		# 180→110Hz 低沉 thud（tower_placed 信号）
		{"start_ms": 0.0, "dur_ms": 100.0, "f0": 180.0, "f1": 110.0, "wave": WAVE_SQUARE, "amp": 0.22},
	]},
	&"tower_upgraded": {"bus": &"SFX", "notes": [
		# 523.25+783.99Hz 双音上行/250ms（C5+E5）
		{"start_ms": 0.0, "dur_ms": 250.0, "f0": 523.25, "wave": WAVE_SINE, "amp": 0.20},
		{"start_ms": 0.0, "dur_ms": 250.0, "f0": 783.99, "wave": WAVE_SINE, "amp": 0.16},
	]},
	&"tower_sold": {"bus": &"SFX", "notes": [
		# 987.77→659.25Hz 快速下滑“退款”音
		{"start_ms": 0.0, "dur_ms": 90.0, "f0": 987.77, "f1": 659.25, "wave": WAVE_SINE, "amp": 0.26},
	]},
	# —— 敌人 / 波次（SFX）——
	&"enemy_killed": {"bus": &"SFX", "notes": [
		# 1320→660Hz 下滑/120ms（击杀返还音）
		{"start_ms": 0.0, "dur_ms": 120.0, "f0": 1320.0, "f1": 660.0, "wave": WAVE_SINE, "amp": 0.30},
	]},
	&"fleet_leak": {"bus": &"SFX", "notes": [
		# 440→220Hz 锯齿下滑警示（fleet_leaked 信号）
		{"start_ms": 0.0, "dur_ms": 200.0, "f0": 440.0, "f1": 220.0, "wave": WAVE_SAW, "amp": 0.24},
	]},
	&"wave_started": {"bus": &"SFX", "notes": [
		# 440Hz 上行琶音/300ms（C4/E4/G4 三连上行）
		{"start_ms": 0.0, "dur_ms": 100.0, "f0": 440.0, "wave": WAVE_SINE, "amp": 0.26},
		{"start_ms": 100.0, "dur_ms": 100.0, "f0": 554.37, "wave": WAVE_SINE, "amp": 0.26},
		{"start_ms": 200.0, "dur_ms": 100.0, "f0": 659.25, "wave": WAVE_SINE, "amp": 0.26},
	]},
	&"wave_completed": {"bus": &"SFX", "notes": [
		# 下行两音收尾（G5/E5/C4）
		{"start_ms": 0.0, "dur_ms": 110.0, "f0": 659.25, "wave": WAVE_SINE, "amp": 0.24},
		{"start_ms": 120.0, "dur_ms": 110.0, "f0": 523.25, "wave": WAVE_SINE, "amp": 0.24},
		{"start_ms": 240.0, "dur_ms": 160.0, "f0": 392.0, "wave": WAVE_SINE, "amp": 0.22},
	]},
	# —— 相位 / 潮汐仪（SFX）——
	&"phase_changed": {"bus": &"SFX", "notes": [
		# 330Hz/400ms 持续长音（相位变更）
		{"start_ms": 0.0, "dur_ms": 400.0, "f0": 330.0, "wave": WAVE_SINE, "amp": 0.30},
	]},
	&"tide_clock": {"bus": &"SFX", "notes": [
		# 双 tick（潮汐仪拨动，tide_clock_shifted 信号）
		{"start_ms": 0.0, "dur_ms": 25.0, "f0": 1200.0, "wave": WAVE_SQUARE, "amp": 0.16},
		{"start_ms": 60.0, "dur_ms": 25.0, "f0": 1600.0, "wave": WAVE_SQUARE, "amp": 0.16},
	]},
	# —— 模块 / 装置（SFX / UI）——
	&"module_selected": {"bus": &"UI", "notes": [
		# 高频 blip（模块选中，UI bus）
		{"start_ms": 0.0, "dur_ms": 50.0, "f0": 1318.5, "wave": WAVE_SINE, "amp": 0.22},
	]},
	&"device_offline": {"bus": &"SFX", "notes": [
		# 220→110Hz 锯齿下滑/500ms（装置离线警报）
		{"start_ms": 0.0, "dur_ms": 500.0, "f0": 220.0, "f1": 110.0, "wave": WAVE_SAW, "amp": 0.25},
	]},
	&"device_repaired": {"bus": &"SFX", "notes": [
		# 上滑 + 尾音（装置修复完成）
		{"start_ms": 0.0, "dur_ms": 130.0, "f0": 523.25, "f1": 783.99, "wave": WAVE_SINE, "amp": 0.24},
		{"start_ms": 140.0, "dur_ms": 120.0, "f0": 659.25, "wave": WAVE_SINE, "amp": 0.20},
	]},
	# —— 英雄（SFX）——
	&"hero_skill": {"bus": &"SFX", "notes": [
		# 660Hz/200ms + 990Hz 泛音（英雄技能）
		{"start_ms": 0.0, "dur_ms": 200.0, "f0": 660.0, "wave": WAVE_SINE, "amp": 0.26},
		{"start_ms": 0.0, "dur_ms": 180.0, "f0": 990.0, "wave": WAVE_SINE, "amp": 0.10},
	]},
	&"hero_down": {"bus": &"SFX", "notes": [
		# 196→98Hz 方波下沉（英雄倒地）
		{"start_ms": 0.0, "dur_ms": 380.0, "f0": 196.0, "f1": 98.0, "wave": WAVE_SQUARE, "amp": 0.28},
	]},
	&"hero_revived": {"bus": &"SFX", "notes": [
		# 上行两音（英雄复活）
		{"start_ms": 0.0, "dur_ms": 200.0, "f0": 392.0, "wave": WAVE_SINE, "amp": 0.22},
		{"start_ms": 170.0, "dur_ms": 220.0, "f0": 587.33, "wave": WAVE_SINE, "amp": 0.22},
	]},
	# —— UI / 结局（UI bus）——
	&"ui_click": {"bus": &"UI", "notes": [
		# 2000Hz/30ms 方波短 click
		{"start_ms": 0.0, "dur_ms": 30.0, "f0": 2000.0, "wave": WAVE_SQUARE, "amp": 0.16},
	]},
	&"ui_denied": {"bus": &"UI", "notes": [
		# 双低音 deny（潮汐仪无航标 / 非法操作，ultimate_failed_no_becon 信号）
		{"start_ms": 0.0, "dur_ms": 70.0, "f0": 196.0, "wave": WAVE_SQUARE, "amp": 0.20},
		{"start_ms": 85.0, "dur_ms": 90.0, "f0": 147.0, "wave": WAVE_SQUARE, "amp": 0.20},
	]},
	&"win": {"bus": &"UI", "notes": [
		# 上行大调短旋律（C5/E5/G5/C6）
		{"start_ms": 0.0, "dur_ms": 130.0, "f0": 523.25, "wave": WAVE_SINE, "amp": 0.22},
		{"start_ms": 120.0, "dur_ms": 130.0, "f0": 659.25, "wave": WAVE_SINE, "amp": 0.22},
		{"start_ms": 240.0, "dur_ms": 130.0, "f0": 783.99, "wave": WAVE_SINE, "amp": 0.22},
		{"start_ms": 360.0, "dur_ms": 280.0, "f0": 1046.5, "wave": WAVE_SINE, "amp": 0.24},
	]},
	&"lose": {"bus": &"UI", "notes": [
		# 下行小调短旋律（G4/E4/C4/G3）
		{"start_ms": 0.0, "dur_ms": 160.0, "f0": 392.0, "wave": WAVE_SINE, "amp": 0.20},
		{"start_ms": 150.0, "dur_ms": 160.0, "f0": 311.13, "wave": WAVE_SINE, "amp": 0.20},
		{"start_ms": 300.0, "dur_ms": 160.0, "f0": 261.63, "wave": WAVE_SINE, "amp": 0.20},
		{"start_ms": 450.0, "dur_ms": 260.0, "f0": 196.0, "wave": WAVE_SINE, "amp": 0.22},
	]},
}

# 合成流缓存：event_id -> AudioStreamWAV（首次合成后复用）
var _stream_cache: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _ui_cursor: int = 0

# C01 STYLE BIBLE §6 音效映射：UI 事件 -> Kenney .ogg 文件（vendor/kenney/audio/）。
# 资源缺失时回退占位合成音（per FALLBACK_EVENT）。
const UI_AUDIO_MAP: Dictionary = {
	&"ui_select": "res://assets/vendor/c01/kenney/audio/click1.ogg",
	&"ui_confirm": "res://assets/vendor/c01/kenney/audio/click3.ogg",
	&"ui_error": "res://assets/vendor/c01/kenney/audio/switch1.ogg",
	&"ui_transition": "res://assets/vendor/c01/kenney/audio/switch2.ogg",
	&"ui_cancel": "res://assets/vendor/c01/kenney/audio/mouserelease1.ogg",
}
var _ui_audio_players: Array[AudioStreamPlayer] = []
var _ui_audio_cursor: int = 0


func _ready() -> void:
	_build_pools()
	_build_ui_audio_players()
	_connect_event_bus()
	# 设置变更（含音量滑杆）后重读音量
	EventBus.settings_applied.connect(_apply_all_bus_volumes)
	_apply_all_bus_volumes()
	print("[M2] AudioService ready (buses=6, placeholder sfx synthesized)")


## 对外事件入口：播放一个占位合成音（未注册事件回退 FALLBACK_EVENT）。
func play_event(event_id: StringName) -> void:
	if not EVENT_CATALOG.has(event_id):
		push_warning("[M2] AudioService: 未注册占位事件 %s，回退 %s" % [event_id, FALLBACK_EVENT])
		event_id = FALLBACK_EVENT
	var stream: AudioStreamWAV = _get_stream(event_id)
	var spec: Dictionary = EVENT_CATALOG[event_id]
	if StringName(spec.get("bus", &"SFX")) == &"UI":
		_ui_cursor = _play_on_pool(_ui_players, _ui_cursor, stream)
	else:
		_sfx_cursor = _play_on_pool(_sfx_players, _sfx_cursor, stream)


## C01 STYLE BIBLE §6：UI 屏动作 → 实际 Kenney .ogg。
## action ∈ {ui_select, ui_confirm, ui_cancel, ui_transition, ui_error}。
## .ogg 缺失 / 未注册 / 资源加载失败时静默回退，不报错。
func play_ui_event(action: StringName) -> void:
	if not UI_AUDIO_MAP.has(action):
		return
	var path: String = UI_AUDIO_MAP[action]
	if not ResourceLoader.exists(path):
		return
	if _ui_audio_players.is_empty():
		return
	# 找空闲播放
	var idx := _ui_audio_cursor
	for offset in _ui_audio_players.size():
		var cand := (_ui_audio_cursor + offset) % _ui_audio_players.size()
		if not _ui_audio_players[cand].playing:
			idx = cand
			break
	var player := _ui_audio_players[idx]
	player.stop()
	player.stream = load(path)
	player.play()
	_ui_audio_cursor = (idx + 1) % _ui_audio_players.size()


func _build_ui_audio_players() -> void:
	for _i in 3: # 3 个 UI 短音足够；事件不重叠时
		var p := AudioStreamPlayer.new()
		p.bus = &"UI" if AudioServer.get_bus_index(&"UI") >= 0 else &"Master"
		add_child(p)
		_ui_audio_players.append(p)


## 把 EventBus 现有信号映射到占位事件（事件 id 见 EVENT_CATALOG）。
func _connect_event_bus() -> void:
	# 波次 / 敌人 / 塔（M0 灰盒战斗，event_bus.gd §M0）
	EventBus.tower_placed.connect(func(_tower_id: StringName, _node_id: StringName) -> void: play_event(&"tower_place"))
	EventBus.enemy_killed.connect(func(_enemy_id: StringName, _reward_ember: int) -> void: play_event(&"enemy_killed"))
	EventBus.fleet_leaked.connect(func(_enemy_id: StringName, _integrity_loss: int) -> void: play_event(&"fleet_leak"))
	EventBus.wave_started.connect(func(_wave_index: int) -> void: play_event(&"wave_started"))
	EventBus.wave_completed.connect(func(_wave_index: int) -> void: play_event(&"wave_completed"))
	# 相位 / 潮汐仪（M1，event_bus.gd §M1）
	EventBus.phase_changed.connect(func(_new_phase: StringName) -> void: play_event(&"phase_changed"))
	EventBus.tide_clock_shifted.connect(func(_direction: StringName) -> void: play_event(&"tide_clock"))
	# M2：塔升级 / 模块 / 出售 / 装置 / 英雄 / 设置
	EventBus.tower_upgraded.connect(func(_tower_id: StringName, _node_id: StringName, _new_tier: int) -> void: play_event(&"tower_upgraded"))
	EventBus.module_selected.connect(func(_tower_id: StringName, _module_id: StringName) -> void: play_event(&"module_selected"))
	EventBus.tower_sold.connect(func(_tower_id: StringName, _node_id: StringName, _refund: int) -> void: play_event(&"tower_sold"))
	EventBus.device_offline.connect(func(_device_id: StringName) -> void: play_event(&"device_offline"))
	EventBus.device_repaired.connect(func(_device_id: StringName) -> void: play_event(&"device_repaired"))
	EventBus.hero_down.connect(func() -> void: play_event(&"hero_down"))
	EventBus.hero_revived.connect(func() -> void: play_event(&"hero_revived"))
	EventBus.hero_skill_used.connect(func(_skill_id: StringName) -> void: play_event(&"hero_skill"))
	EventBus.ultimate_failed_no_becon.connect(func() -> void: play_event(&"ui_denied"))


# —— 音量：SettingsService 线性值 -> bus volume_db ——

## 线性 0.0–1.0 -> dB；0 音量映射到 -80（AudioServer 下限），避免 -inf。
func _linear_to_db(linear: float) -> float:
	var v: float = clampf(linear, 0.0, 1.0)
	if v <= 0.0:
		return -80.0
	return linear_to_db(v) # @GlobalScope 全局函数（Godot 4 无 AudioServer.linear_to_db）


func _apply_all_bus_volumes() -> void:
	for bus_name: StringName in BUS_VOLUME_KEYS:
		var key: String = BUS_VOLUME_KEYS[bus_name]
		var linear := float(SettingsService.get_value("audio", key, 1.0))
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			push_warning("[M2] AudioService: bus %s 不存在，跳过音量设置" % bus_name)
			continue
		AudioServer.set_bus_volume_db(bus_index, _linear_to_db(linear))


# —— 播放池（16 个 AudioStreamPlayer：12 SFX + 4 UI）——

func _build_pools() -> void:
	for _i in POOL_SFX_COUNT:
		_sfx_players.append(_make_player(&"SFX"))
	for _i in POOL_UI_COUNT:
		_ui_players.append(_make_player(&"UI"))


func _make_player(bus_name: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	# 总线布局未加载（bus 缺失）时兜底到 Master，避免运行期报错
	player.bus = bus_name if AudioServer.get_bus_index(bus_name) >= 0 else &"Master"
	add_child(player)
	return player


## 优先复用空闲播放器；全忙则轮转覆盖最早使用者（占位音极短，可接受）。headless/Dummy 驱动下亦安全。
func _play_on_pool(players: Array[AudioStreamPlayer], cursor: int, stream: AudioStreamWAV) -> int:
	if players.is_empty():
		return 0
	var idx := cursor
	for offset in players.size():
		var candidate := (cursor + offset) % players.size()
		if not players[candidate].playing:
			idx = candidate
			break
	var player := players[idx]
	player.stop()
	player.stream = stream
	player.play()
	return (idx + 1) % players.size()


# —— 合成：确定性参数 -> 16-bit 单声道 PCM -> AudioStreamWAV（缓存复用）——

func _get_stream(event_id: StringName) -> AudioStreamWAV:
	var cached: AudioStreamWAV = _stream_cache.get(event_id)
	if cached != null:
		return cached
	var spec: Dictionary = EVENT_CATALOG.get(event_id, {})
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = _render_pcm(spec)
	_stream_cache[event_id] = wav
	return wav


func _render_pcm(spec: Dictionary) -> PackedByteArray:
	var notes: Array = spec.get("notes", [])
	var end_ms := 0.0
	for note: Dictionary in notes:
		end_ms = maxf(end_ms, float(note.get("start_ms", 0.0)) + float(note.get("dur_ms", 0.0)))
	var sample_count := maxi(1, ceili(end_ms / 1000.0 * float(MIX_RATE)))
	var mix := PackedFloat32Array()
	mix.resize(sample_count)
	for i in sample_count:
		mix[i] = 0.0
	for note: Dictionary in notes:
		_mix_note(mix, note)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for i in sample_count:
		pcm.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 32767.0))
	return pcm


## 把单个 note 叠加进混音缓冲。f0->f1 线性滑频；2ms 起音 + 8ms 释音斜坡 + 指数衰减，避免爆音。
func _mix_note(mix: PackedFloat32Array, note: Dictionary) -> void:
	var sr: float = float(MIX_RATE)
	var start_ms: float = float(note.get("start_ms", 0.0))
	var dur_ms: float = float(note.get("dur_ms", 0.0))
	var f0: float = float(note.get("f0", 440.0))
	var f1: float = float(note.get("f1", f0))
	var wave: int = int(note.get("wave", WAVE_SINE))
	var amp: float = float(note.get("amp", 0.25))
	if dur_ms <= 0.0:
		return
	var dur_s: float = dur_ms / 1000.0
	var start_sample := int(start_ms / 1000.0 * sr)
	var count := int(dur_s * sr)
	var attack_n: int = maxi(1, int(0.002 * sr))
	var release_n: int = maxi(1, int(0.008 * sr))
	var phase := 0.0
	for n in count:
		var idx := start_sample + n
		if idx < 0 or idx >= mix.size():
			break
		var t := float(n) / sr
		var progress: float = t / dur_s
		phase += lerpf(f0, f1, progress) / sr
		var value := 0.0
		match wave:
			WAVE_SINE:
				value = sin(TAU * phase)
			WAVE_SQUARE:
				value = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			WAVE_SAW:
				value = 2.0 * fmod(phase, 1.0) - 1.0
			_:
				value = sin(TAU * phase)
		var env := 1.0
		if n < attack_n:
			env = float(n) / float(attack_n)
		if n >= count - release_n:
			env = minf(env, float(count - n) / float(release_n))
		env *= pow(0.05, progress)
		mix[idx] += value * env * amp
