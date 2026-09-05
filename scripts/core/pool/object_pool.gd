class_name ObjectPool
extends RefCounted
## 通用对象池（M0 最小实现）。PRD §18.5：对象池不后置。
## factory 负责创建新对象；release/acquire 循环复用，由调用方管理节点挂载与显隐。

var _factory: Callable
var _free: Array = []


func _init(factory: Callable) -> void:
	_factory = factory


func acquire() -> Variant:
	if _free.is_empty():
		return _factory.call()
	return _free.pop_back()


func release(obj: Variant) -> void:
	_free.append(obj)


func free_count() -> int:
	return _free.size()
