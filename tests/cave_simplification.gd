extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var gm = root.get_node("GameManager")
	var sm = root.get_node("SceneManager")
	gm.reset_game()
	gm.swamp_states[0]["gallons_drained"] = gm.swamp_definitions[0]["total_gallons"]
	_check(gm.enter_cave("muddy_hollow"), "Eligible cave cannot be entered")
	gm.water_carried = 0.5
	var cave = load("res://scenes/caves/muddy_hollow.tscn").instantiate()
	root.add_child(cave)
	await process_frame
	gm._process(180.0)
	await process_frame
	_check(gm.in_cave and not sm.is_transitioning, "Cave still has a timed forced exit")
	_check(gm.water_carried == 0.5, "Cave timer drops carried water")
	var hud = load("res://scenes/ui/hud.tscn").instantiate()
	root.add_child(hud)
	_check(hud.find_children("*", "ProgressBar", true, false).size() == 1, "HUD still creates an air bar")
	for path in ["res://scripts/world/dead_drop.gd", "res://scripts/caves/lore_wall.gd"]:
		var decoration = load(path).new()
		root.add_child(decoration)
		_check(decoration.find_children("*", "Area2D", true, false).is_empty(), "Story decoration still offers interaction")
		_check(decoration.find_children("*", "Label", true, false).is_empty(), "Story decoration still has a reading prompt")
		decoration.queue_free()
	var loot = load("res://scripts/caves/loot_node.gd").new()
	loot.cave_id = "muddy_hollow"
	loot.loot_id = "test_reward"
	loot.reward_money = 25.0
	loot.reward_tool_unlock = "spoon"
	root.add_child(loot)
	loot._on_body_entered(cave.player_ref)
	_check(loot.hint_label.visible and loot.hint_label.text.contains("Collect"), "Rewards lost their collection prompt")
	var before: float = gm.money
	cave.player_ref.set_physics_process(false)
	Input.action_press("scoop")
	loot._process(0.016)
	Input.action_release("scoop")
	_check(gm.money == before + 25.0, "Reward has missing cash or timed-air multiplier")
	_check(gm.tools_owned["spoon"]["owned"], "Tool reward removed")
	_check(gm.is_loot_collected("muddy_hollow", "test_reward") and not loot.hint_label.visible, "Collected reward remains interactive")
	loot._collect()
	_check(gm.money == before + 25.0, "Reward can be collected twice")
	_check(not sm.showing_lore and not sm.showing_newspaper, "Reward triggers a story popup")
	gm._drain_cave_pool("muddy_hollow", 0, 100.0)
	_check(gm.is_cave_pool_completed("muddy_hollow", 0), "Cave drainage rewards no longer progress")
	loot.queue_free()
	hud.queue_free()
	cave.queue_free()
	await process_frame
	# Walk into The Mire's real water barriers, then scoop using player input.
	gm.reset_game()
	gm.swamp_states[4]["gallons_drained"] = gm.swamp_definitions[4]["total_gallons"]
	_check(gm.enter_cave("the_mire"), "The Mire cannot be entered")
	var mire = load("res://scenes/caves/the_mire.tscn").instantiate()
	root.add_child(mire)
	await physics_frame
	for pool_index in [0, 1]:
		var refs: Dictionary = mire.cave_pool_refs[pool_index]
		var shore: float = refs["wall_coll"].position.x
		mire.player_ref.position = Vector2(shore - 65.0, mire._get_cave_terrain_y_at(shore - 65.0) - 2.0)
		mire.player_ref.velocity = Vector2.ZERO
		Input.action_press("move_right")
		for frame in range(60):
			await physics_frame
		Input.action_release("move_right")
		_check(mire.player_ref.position.x < shore, "Player crossed an undrained Mire pool barrier")
		_check(mire.player_ref.near_cave_pool and mire.player_ref.cave_pool_index == pool_index, "Mire barrier blocks scoop detection at pool %d" % pool_index)
		gm.water_carried = 0.0
		gm.current_stamina = gm.get_max_stamina()
		var drained_before: float = gm.cave_pool_states["the_mire"][pool_index]["gallons_drained"]
		mire.player_ref._handle_scoop()
		_check(gm.cave_pool_states["the_mire"][pool_index]["gallons_drained"] > drained_before and gm.water_carried > 0.0, "Player cannot scoop at Mire pool %d" % pool_index)
		gm._drain_cave_pool("the_mire", pool_index, 100000.0)
		await physics_frame
	mire.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("Cave simplification checks: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
