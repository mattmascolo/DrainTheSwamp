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
	for failure in failures:
		push_error(failure)
	print("Cave simplification checks: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
