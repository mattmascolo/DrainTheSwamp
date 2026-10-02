extends SceneTree
# Run with an isolated XDG_DATA_HOME to avoid touching a real save.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var gm = root.get_node("GameManager")
	gm.reset_game()
	for cave_id in gm.CAVE_DEFINITIONS:
		var si: int = gm.CAVE_DEFINITIONS[cave_id]["swamp_index"]
		var total: float = gm.swamp_definitions[si]["total_gallons"]
		for fraction in [0.0, 0.5, 0.999999]:
			gm.swamp_states[si]["gallons_drained"] = total * fraction
			gm.cave_data[cave_id]["unlocked"] = true # legacy half-drained save
			_check(not gm.is_cave_unlocked(cave_id), "%s accessible at %s" % [cave_id, fraction])
			_check(not gm.enter_cave(cave_id), "%s entered before empty" % cave_id)
		gm.cave_data[cave_id]["unlocked"] = false
		gm.swamp_states[si]["gallons_drained"] = total - 1.0
		gm._drain_swamp(si, 1.0)
		_check(gm.is_cave_unlocked(cave_id), "%s blocked after final gallon" % cave_id)
		_check(gm.enter_cave(cave_id), "%s cannot enter empty pool" % cave_id)
		gm.exit_cave()
	_check(not gm.enter_cave("missing"), "Unknown cave entered")
	gm.reset_game()
	gm.swamp_states[0]["gallons_drained"] = gm.swamp_definitions[0]["total_gallons"] * 0.5
	gm.cave_data["muddy_hollow"]["unlocked"] = true
	gm.cave_data["muddy_hollow"]["loot_collected"]["test_loot"] = true
	var saved: Dictionary = gm.get_save_data()
	gm.load_save_data(saved)
	_check(not gm.cave_data["muddy_hollow"]["unlocked"], "Legacy unlock retained on load")
	_check(gm.is_loot_collected("muddy_hollow", "test_loot"), "Legacy loot lost")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var world = main.get_node("GameWorld")
	for ce in world.cave_entrances:
		_check(not ce["root"].visible, "Undrained cave rendered")
		_check(not ce["area"].monitoring, "Undrained cave monitors entry")
	# Dummy rendering does not expose shader uniform defaults.
	world.post_process_rect.material.set_shader_parameter("warmth", 0.0)
	gm._drain_swamp(0, gm.swamp_definitions[0]["total_gallons"])
	await create_timer(0.5).timeout
	_check(world.cave_entrances[0]["root"].visible, "Drained cave remains hidden")
	for label in world.cave_entrances[0]["root"].find_children("*", "Label", true, false):
		_check(not label.text.to_upper().contains("MUDDY HOLLOW"), "Surface cave nameplate remains")
	_check(world.cave_entrances[0]["hint"].text.contains("SPACE"), "Useful cave entry prompt was removed")
	_check(world.cave_entrances[0]["area"].monitoring, "Drained cave has no interaction")
	gm.swamp_states[0]["gallons_drained"] -= 1.0
	gm.water_level_changed.emit(0, gm.get_swamp_water_percent(0))
	await process_frame
	_check(not world.cave_entrances[0]["root"].visible, "Refilled cave remains visible")
	_check(not gm.enter_cave("muddy_hollow"), "Refilled cave entered")
	var actor = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(actor)
	actor.set_physics_process(false)
	for action in ["move_right", "move_left"]:
		Input.action_press(action)
		actor._physics_process(1.0 / 60.0)
		Input.action_release(action)
		var skin = actor._skin
		for strip in ["idle", "walk", "scoop"]:
			skin._set_strip(strip)
			var native_facing: float = skin._sprite.global_transform.x.x * (-1.0 if skin._sprite.flip_h else 1.0)
			_check((native_facing > 0.0) == (action == "move_right"), "%s faces wrong during %s" % [strip, action])
	actor.queue_free()
	main.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("Cave access checks: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
