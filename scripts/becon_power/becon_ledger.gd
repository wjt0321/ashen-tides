class_name BeconLedger
extends Node
## 航标充能账本（RESEARCH_REPORT.md §10.2）：0–100 主动资源。
## 英雄终极技与潮汐仪争夺同一资源（PRD §10.1，本项目核心张力）。

signal value_changed(new_value: int)

const MAX_VALUE: int = 100

var current: int = 0


func add(amount: int, source: StringName) -> void:
	current = clampi(current + amount, 0, MAX_VALUE)
	value_changed.emit(current)
	EventBus.becon_changed.emit(current, source)


func try_spend(amount: int) -> bool:
	if current < amount:
		return false
	current -= amount
	value_changed.emit(current)
	EventBus.becon_spent.emit(amount)
	return true


func set_value_silent(value: int) -> void:
	## 存档恢复用：不发信号，由调用方统一刷新 HUD
	current = clampi(value, 0, MAX_VALUE)
