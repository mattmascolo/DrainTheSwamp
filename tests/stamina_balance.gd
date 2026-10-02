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
	var maximum: float = gm.get_max_stamina()
	var successful: int = 0
	for i in range(20):
		gm.regen_stamina(0.3)
		if gm.try_scoop(0):
			successful += 1
	_check(successful >= 15 and successful < 20, "Starting stamina does not interrupt six seconds of scooping")
	_check(gm.current_stamina < maximum * 0.15, "Starting stamina barely depletes")
	gm.current_stamina = 1.0
	var drained: float = gm.swamp_states[0]["gallons_drained"]
	_check(not gm.try_scoop(0), "Insufficient stamina still collects water")
	_check(gm.current_stamina == 1.0 and gm.swamp_states[0]["gallons_drained"] == drained, "Failed scoop consumes stamina or drains water")
	gm.regen_stamina(7.0)
	_check(is_equal_approx(gm.current_stamina, maximum), "Rest fails to recover stamina or overfills the bar")
	_check(gm.try_scoop(0), "Scooping cannot resume after resting")
	_check(is_equal_approx(gm.current_stamina, maximum - 2.0), "Surface scoop has wrong stamina cost")
	gm.water_carried = gm.get_carrying_capacity()
	var before: float = gm.current_stamina
	_check(not gm.try_scoop(0) and gm.current_stamina == before, "Full bag wastes stamina")
	gm.upgrades_owned["overflow_valve"] = 1
	_check(gm.try_scoop(0), "Overflow scoop no longer works")
	_check(is_equal_approx(gm.current_stamina, before - 2.0), "Overflow bypasses scoop stamina cost")
	gm.reset_game()
	gm.swamp_states[0]["gallons_drained"] = gm.swamp_definitions[0]["total_gallons"]
	gm.enter_cave("muddy_hollow")
	_check(gm.try_scoop_cave_pool("muddy_hollow", 0), "Cave scoop no longer works")
	_check(is_equal_approx(gm.current_stamina, maximum - 2.0), "Cave scoop bypasses stamina cost")
	gm.current_stamina = 1.0
	_check(not gm.try_scoop_cave_pool("muddy_hollow", 0), "Cave scoops ignore exhaustion")
	gm.reset_game()
	gm.stat_levels["stamina"] = 1
	gm.stat_levels["stamina_regen"] = 1
	_check(gm.get_max_stamina() > maximum and gm.get_stamina_regen_rate() > 3.0, "Stamina upgrades lost their benefit")
	for failure in failures:
		push_error(failure)
	print("Stamina balance checks: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
