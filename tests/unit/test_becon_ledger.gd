extends TestBase
## 航标充能账本（RESEARCH_REPORT.md §10.2）：0–100 上限；
## 英雄终极技（80）与潮汐仪（40）争夺同一资源（PRD §10.1）。


func test_add_and_cap() -> void:
	var ledger := BeconLedger.new()
	ledger.add(50, &"test")
	check_eq(ledger.current, 50, "充能累加")
	ledger.add(80, &"test")
	check_eq(ledger.current, 100, "充能封顶 100")


func test_spend_and_competition() -> void:
	var ledger := BeconLedger.new()
	ledger.add(100, &"test")
	check(ledger.try_spend(80), "终极技消耗 80 成功")
	check(not ledger.try_spend(40), "剩余 20 不够潮汐仪 40（资源竞争成立）")
	ledger.add(30, &"test")
	check(ledger.try_spend(40), "充能 50 后潮汐仪成功")
	check_eq(ledger.current, 10, "扣费正确")


func test_signals() -> void:
	# 注意：GDScript lambda 按值捕获局部变量，计数器必须用数组包裹。
	var ledger := BeconLedger.new()
	var changes := [0]
	var spent := [0]
	ledger.value_changed.connect(func(_v: int) -> void: changes[0] += 1)
	EventBus.becon_spent.connect(func(_a: int) -> void: spent[0] += 1)
	ledger.add(10, &"test")
	ledger.try_spend(5)
	check_eq(changes[0], 2, "value_changed 发两次")
	check_eq(spent[0], 1, "becon_spent 发一次")
