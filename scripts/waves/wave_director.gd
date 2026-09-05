class_name WaveDirector
extends Node
## 波次导演（M0 最小实现）。
## 状态机（RESEARCH_REPORT.md §13.2）：
## BUILD → PRE_DELAY → SPAWNING → CLEARING →（有下一波 ? BUILD : WIN）；外部可切 LOSE。
## tick 由战斗场景显式驱动，配合暂停与倍速；生成请求经 signal 发出，自身不创建节点。

enum State { BUILD, PRE_DELAY, SPAWNING, CLEARING, WIN, LOSE }

signal state_changed(new_state: State)
signal spawn_requested(enemy_id: StringName, route_id: StringName)
signal wave_started(wave_index: int)
signal wave_completed(wave_index: int, reward_ember: int, reward_becon: int)
signal all_waves_completed()

class GroupRuntime:
	var data: WaveGroup
	var remaining: int = 0
	var next_in: float = 0.0 ## 距下次生成秒数

var state: State = State.BUILD

var _waves: Array = []
var _current_index: int = -1
var _pre_delay_left: float = 0.0
var _groups: Array[GroupRuntime] = []
var _alive: int = 0


func setup(waves: Array) -> void:
	_waves = waves
	reset()


func reset() -> void:
	_current_index = -1
	_alive = 0
	_groups.clear()
	_pre_delay_left = 0.0
	state = State.BUILD


func total_waves() -> int:
	return _waves.size()


## HUD 波次横幅（Polish）：按 0 起索引取波次数据，越界返回 null。
func wave_at(index: int) -> WaveData:
	return _waves[index] if index >= 0 and index < _waves.size() else null


## 已开始的波数（HUD 显示用）。
func waves_started() -> int:
	return clampi(_current_index + 1, 0, _waves.size())


func pre_delay_remaining() -> float:
	return _pre_delay_left


## 仅 BUILD 状态可开波；成功返回 true。
func start_wave() -> bool:
	if state != State.BUILD:
		return false
	if _current_index + 1 >= _waves.size():
		return false
	_current_index += 1
	var wave: WaveData = _waves[_current_index]
	_pre_delay_left = wave.pre_delay_seconds
	_set_state(State.PRE_DELAY)
	return true


func notify_enemy_removed() -> void:
	_alive = maxi(0, _alive - 1)


func enter_lose() -> void:
	_set_state(State.LOSE)


## 存档恢复：completed 为已完成波数（人类计数），恢复到下一波的 BUILD 状态。
func restore_progress(completed: int) -> void:
	_current_index = clampi(completed - 1, -1, _waves.size() - 1)
	_alive = 0
	_groups.clear()
	_pre_delay_left = 0.0
	state = State.BUILD


## Debug 跳波：清空剩余生成并直接进入清场（存活敌人由场景移除，移除后下一 tick 结算）。
func debug_finish_wave() -> bool:
	if state != State.PRE_DELAY and state != State.SPAWNING and state != State.CLEARING:
		return false
	_groups.clear()
	_set_state(State.CLEARING)
	return true


func tick(delta: float) -> void:
	match state:
		State.PRE_DELAY:
			_pre_delay_left -= delta
			if _pre_delay_left <= 0.0:
				_begin_spawning()
		State.SPAWNING:
			var all_done := true
			for group: GroupRuntime in _groups:
				if group.remaining <= 0:
					continue
				all_done = false
				group.next_in -= delta
				while group.remaining > 0 and group.next_in <= 0.0:
					group.remaining -= 1
					if group.remaining > 0:
						group.next_in += group.data.interval_seconds
					_alive += 1
					spawn_requested.emit(group.data.enemy_id, group.data.route_id)
			if all_done:
				_set_state(State.CLEARING)
		State.CLEARING:
			if _alive <= 0:
				_finish_wave()


func _begin_spawning() -> void:
	_groups.clear()
	var wave: WaveData = _waves[_current_index]
	for group: Variant in wave.groups:
		var runtime := GroupRuntime.new()
		runtime.data = group
		runtime.remaining = group.count
		runtime.next_in = group.delay_after_prev_seconds
		_groups.append(runtime)
	_set_state(State.SPAWNING)
	wave_started.emit(_current_index)


func _finish_wave() -> void:
	var wave: WaveData = _waves[_current_index]
	var is_last: bool = _current_index + 1 >= _waves.size()
	# 先切换状态再发奖励信号，监听者可在 wave_completed 中直接开下一波
	if is_last:
		_set_state(State.WIN)
	else:
		_set_state(State.BUILD)
	wave_completed.emit(_current_index, wave.completion_reward_ember, wave.completion_reward_becon)
	if is_last:
		all_waves_completed.emit()


func _set_state(new_state: State) -> void:
	if state != new_state:
		state = new_state
		state_changed.emit(new_state)
