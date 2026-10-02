extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var gm = root.get_node("GameManager")
	gm.reset_game()
	gm.influence = 99.0 # A legacy save must not make cash purchases affordable.
	var shop = load("res://scenes/ui/shop_panel.tscn").instantiate()
	root.add_child(shop)
	shop.open()
	_check(shop.tab_buttons.size() == 2, "Shop still has a third currency tab")
	_check(shop.tab_buttons[0].text == "Tools" and shop.tab_buttons[1].text == "Stats", "Shop tabs changed unexpectedly")
	for tab in [0, 1, 2]:
		shop.current_tab = tab
		shop._refresh()
		_check(shop.current_tab <= 1, "Old tab index leaves an empty shop")
		for node in shop.find_children("*", "Control", true, false):
			var text: String = node.tooltip_text
			if node is Label or node is Button:
				text += node.text
			text = text.to_lower()
			_check(not text.contains("influence") and not text.contains("sell out") and not text.contains("pending payout"), "Removed currency remains in shop text")
			_check(not text.contains("pump"), "Shop still offers pool pumps")
	shop.current_tab = 0
	shop._refresh()
	var spoon_button: Button = null
	var cost: float = gm.tool_definitions["spoon"]["cost"]
	for button in shop.find_children("*", "Button", true, false):
		if button.text == "Buy " + Economy.format_money(cost):
			spoon_button = button
	_check(spoon_button != null, "Normal tool purchase missing")
	if spoon_button != null:
		_check(spoon_button.disabled, "Legacy influence buys a cash tool")
		gm.money = cost
		gm.money_changed.emit(cost)
		shop._soft_refresh()
		_check(not spoon_button.disabled, "Cash cannot enable a tool purchase")
		spoon_button.pressed.emit()
		_check(gm.tools_owned["spoon"]["owned"] and gm.current_tool_id == "spoon", "Cash purchase no longer buys and equips")
		_check(is_zero_approx(gm.money) and gm.influence == 99.0, "Purchase deducts wrong currency")
	shop.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("Shop currency checks: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
