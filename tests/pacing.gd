extends SceneTree
# Behavioral pacing checks; isolate XDG_DATA_HOME when running.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var gm = root.get_node("GameManager")
	gm.reset_game()
	_check(is_equal_approx(gm.tool_definitions["spoon"]["cost"], 22.5), "Spoon price did not rise")
	_check(is_equal_approx(gm.get_tool_upgrade_cost("hands"), 15.0), "Hands upgrade price inconsistent")
	_check(is_equal_approx(gm.get_stat_upgrade_cost("carrying_capacity"), 15.0), "Capacity price inconsistent")
	_check(is_equal_approx(gm.get_pump_cost(0), 18.75), "Pump price inconsistent")
	# First tool must remain attainable promptly, before the first pool is empty.
	var seconds: float = 0.0
	var spoon_cost: float = gm.tool_definitions["spoon"]["cost"]
	while gm.money < spoon_cost and seconds < 150.0:
		gm.regen_stamina(0.3)
		gm.try_scoop(0)
		seconds += 0.3
		var value: float = gm.water_carried * gm.swamp_definitions[0]["money_per_gallon"]
		if gm.is_inventory_full() or gm.money + value >= spoon_cost:
			gm.sell_water()
	_check(seconds >= 100.0 and seconds <= 135.0, "First spoon outside pacing window: %.1fs" % seconds)
	_check(gm.buy_tool("spoon"), "Cannot buy first spoon after earning its cost")
	_check(gm.get_swamp_fill_fraction(0) > 0.5, "First tool arrives after half the Puddle is gone")
	print("First spoon: %.1fs of scoop time, excluding walking" % seconds)
	# Fixed starter build: significantly slower progress through the Puddle.
	gm.reset_game()
	seconds = 0.0
	while not gm.is_swamp_completed(0) and seconds < 750.0:
		gm.regen_stamina(0.3)
		gm.try_scoop(0)
		seconds += 0.3
		if gm.is_inventory_full():
			gm.sell_water()
	_check(gm.is_swamp_completed(0) and seconds >= 600.0 and seconds < 700.0, "Starter drain outside expected window: %.1fs" % seconds)
	print("Unupgraded Puddle: %.1fs of scoop/recovery time, excluding walking" % seconds)
	# Cave tool output retains its original progression scale.
	gm.reset_game()
	var surface_output: float = gm.get_tool_output("hands")
	gm.in_cave = true
	_check(is_equal_approx(gm.get_tool_output("hands", true), 0.015), "Cave scoop output changed unexpectedly")
	gm.in_cave = false
	_check(is_equal_approx(surface_output, 0.005), "Surface starter scoop is not slower")
	gm.pump_levels[0] = 1
	gm._run_pumps(3600.0, 0.5)
	_check(gm.get_swamp_fill_fraction(0) > 0.9, "Offline pump drains early pools too fast")
	# Existing water progress/ownership must survive loading under new prices.
	var save: Dictionary = gm.get_save_data()
	var drained: float = gm.swamp_states[0]["gallons_drained"]
	save["saved_at"] = Time.get_unix_time_from_system()
	gm.load_save_data(save)
	_check(is_equal_approx(gm.swamp_states[0]["gallons_drained"], drained), "Save load changes water progress")
	_check(gm.get_pump_level(0) == 1, "Save load loses pump")
	for failure in failures:
		push_error(failure)
	print("Pacing checks: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
