class_name TestBase
extends RefCounted
## 最小测试基类（GUT 等价物，M1；不下载第三方插件）。
## 子类放在 tests/unit/test_*.gd，所有 test_* 方法由 tools/run_tests.gd 自动执行。

var failures: Array[String] = []
var passes: int = 0


func check(condition: bool, message: String) -> void:
	if condition:
		passes += 1
	else:
		failures.append(message)
		printerr("    FAIL: %s" % message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s（期望 %s，实际 %s）" % [message, expected, actual])


func check_approx(actual: float, expected: float, epsilon: float, message: String) -> void:
	check(absf(actual - expected) <= epsilon, "%s（期望≈%s，实际 %s）" % [message, expected, actual])


func run_all() -> void:
	for method: Dictionary in get_method_list():
		var method_name := String(method.name)
		if method_name.begins_with("test_"):
			Callable(self, method_name).call()
