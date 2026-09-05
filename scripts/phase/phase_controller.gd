class_name PhaseController
extends Node
## 相位控制器（PRD §4 / RESEARCH_REPORT.md §9）。
## 预告：事件 starts_at_wave = N 时，在第 N-1 波开始时发出预告（一整波提前量，
## 数据层 warning_seconds >= 20 由校验器强制）。
## 切换：默认在第 N 波开始时应用（波次边界，保证确定性）；
## 潮汐仪（PRD §4.2）消耗 40 充能把下一次切换提前（立即生效）或延后（第 N 波开始后 +10 秒）。
## Boss 剧情切换 player_interruptible = false，潮汐仪拒绝干预。

const MINGCHAO: StringName = &"mingchao" ## 明潮
const MUCHAO: StringName = &"muchao" ## 暮潮
const DISPLAY_NAMES: Dictionary = {MINGCHAO: "明潮", MUCHAO: "暮潮"}
const TIDE_DELAY_SECONDS: float = 10.0

## M2：相位模板 2 —— 环境变化由战斗场景应用到装置运行时（PRD §4.1）
signal environment_change_requested(change: Dictionary)

var current_phase: StringName = MINGCHAO
var path_network: PathNetwork
var becon: BeconLedger

var _events: Array = [] ## Array[PhaseEventData]
var _pending: PhaseEventData = null ## 已预告、待下一波切换的事件
var _shift_later_id: StringName = &"" ## 被潮汐仪延后的事件 id
var _delayed_event: PhaseEventData = null ## 延后切换中的事件
var _delayed_left: float = -1.0
var _applied_ids: Dictionary = {} ## 已应用事件（潮汐仪提前后避免波次边界重复应用）
var transition_log: Array = [] ## 冒烟测试证据：[{wave, tick, to_phase}]
var tick_now: int = -1 ## 由战斗场景每个 sim tick 更新，供日志记录
var _last_wave_number: int = -1


func setup(events: Array, p_network: PathNetwork, p_becon: BeconLedger) -> void:
	_events = events
	path_network = p_network
	becon = p_becon
	current_phase = MINGCHAO
	_pending = null
	_shift_later_id = &""
	_delayed_event = null
	_delayed_left = -1.0
	_applied_ids.clear()
	transition_log.clear()


func has_pending() -> bool:
	return _pending != null


func pending_description() -> String:
	if _pending == null:
		return ""
	return "下波相位→%s（潮汐仪：, 提前 / . 延后，%d 充能）" % [
		DISPLAY_NAMES.get(_pending.to_phase, _pending.to_phase), _pending.becon_cost
	]


## HUD 相位条（Polish）：待切换事件的目标相位，无则空。
func pending_to_phase() -> StringName:
	return _pending.to_phase if _pending != null else &""


## HUD 相位条（Polish）：待切换事件的生效波次（1 起），无则 -1。
func pending_wave() -> int:
	return _pending.starts_at_wave if _pending != null else -1


## wave_number 为 1 起的人类波次号；由战斗场景在 director.wave_started 时调用。
func on_wave_started(wave_number: int, tick: int) -> void:
	_last_wave_number = wave_number
	# 预告下一波的相位事件（提前一整波，PRD §4.1）
	for event: PhaseEventData in _events:
		if event.enabled and event.starts_at_wave == wave_number + 1:
			_pending = event
			EventBus.phase_warning.emit(event.to_phase, event.warning_seconds)
			print("[M1] phase warning: wave %d -> %s" % [event.starts_at_wave, event.to_phase])
	# 应用本波开始的切换（已被潮汐仪提前应用过的跳过）
	for event: PhaseEventData in _events:
		if not event.enabled or event.starts_at_wave != wave_number or _applied_ids.has(event.id):
			continue
		if event.id == _shift_later_id:
			_delayed_event = event
			_delayed_left = TIDE_DELAY_SECONDS
			_shift_later_id = &""
			print("[M1] phase switch delayed +%.0fs by tide clock: %s" % [TIDE_DELAY_SECONDS, event.id])
		else:
			_apply(event, wave_number, tick)
		if _pending == event:
			_pending = null


func sim_tick(delta: float) -> void:
	if _delayed_left > 0.0:
		_delayed_left -= delta
		if _delayed_left <= 0.0 and _delayed_event != null:
			_apply(_delayed_event, _last_wave_number, tick_now)
			_delayed_event = null


## 潮汐仪干预：earlier=true 立即切换（提前），false 延后到下一波开始后 +10 秒。
func request_shift(earlier: bool) -> bool:
	if _pending == null:
		return false
	if not _pending.player_interruptible:
		print("[M1] tide clock refused: boss-locked phase event %s" % _pending.id)
		return false
	if not becon.try_spend(_pending.becon_cost):
		EventBus.tide_clock_failed.emit(&"no_becon")
		return false
	var event := _pending
	if earlier:
		_apply(event, _last_wave_number, tick_now)
		_pending = null
	else:
		_shift_later_id = event.id
	EventBus.tide_clock_shifted.emit(&"earlier" if earlier else &"later")
	print("[M1] tide clock shift %s: %s (becon left=%d)" % ["earlier" if earlier else "later", event.id, becon.current])
	return true


## 存档恢复：直接把相位设为指定值，并按事件表应用路线差分（M1 单事件线性模型）。
func restore_phase(phase_id: StringName) -> void:
	current_phase = phase_id
	for event: PhaseEventData in _events:
		if event.enabled and event.to_phase == phase_id:
			for route_id: StringName in event.activates_routes:
				path_network.activate_route(route_id)
			for route_id: StringName in event.deactivates_routes:
				path_network.deactivate_route(route_id)
			for change: Variant in event.environment_changes:
				if change is Dictionary:
					environment_change_requested.emit(change)


func _apply(event: PhaseEventData, wave_number: int, tick: int) -> void:
	_applied_ids[event.id] = true
	for route_id: StringName in event.activates_routes:
		path_network.activate_route(route_id)
	for route_id: StringName in event.deactivates_routes:
		path_network.deactivate_route(route_id)
	for change: Variant in event.environment_changes:
		if change is Dictionary:
			environment_change_requested.emit(change)
	current_phase = event.to_phase
	transition_log.append({"wave": wave_number, "tick": tick, "event": String(event.id), "to_phase": String(event.to_phase)})
	EventBus.phase_changed.emit(event.to_phase)
	print("[M1] phase changed -> %s (event=%s)" % [event.to_phase, event.id])
