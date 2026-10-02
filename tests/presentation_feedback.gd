extends SceneTree
# Run with an isolated XDG_DATA_HOME so test activity cannot alter a real save.
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
	gm.water_sold.emit(10.0)
	gm.lore_read.emit("muddy_hollow", "test_lore")
	gm.loot_collected.emit("muddy_hollow", "test_loot", "Story discovery")
	gm.swamp_completed.emit(0, 50.0)
	sm.show_lore_popup("Story lore")
	sm.show_single_newspaper({"headline": "Story paper"})
	sm.show_endgame_newspapers([{"headline": "Story ending"}])
	sm.show_ending_choice(func(_choice: String) -> void: failures.append("Ending choice shown"))
	await create_timer(2.2).timeout
	_check(sm.phone_queue.is_empty(), "Story phone messages still queued")
	_check(not sm.showing_lore and not sm.showing_newspaper and not sm.endgame_active, "Story modal still visible")
	_check(not sm.cave_popup.visible, "Loot still opens a story popup")
	sm.show_popup("Gameplay help", 0.2)
	_check(sm.cave_popup.visible, "Gameplay help was removed")
	await create_timer(0.3).timeout
	_check(not sm.cave_popup.visible, "Gameplay help does not dismiss")
	sm.show_document_popup("Gameplay help", "HOW TO PLAY")
	await create_timer(0.9).timeout
	var dismiss_key := InputEventKey.new()
	dismiss_key.keycode = KEY_A
	dismiss_key.pressed = true
	sm._input(dismiss_key)
	await create_timer(0.6).timeout
	_check(not sm.showing_lore, "Brief arbitrary key press does not dismiss gameplay help")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var world = main.get_node("GameWorld")
	var signage = get_first_node_in_group("signage")
	_check(signage != null and signage._basin.size() == world.SWAMP_COUNT, "Water-hole information signs were removed")
	if signage != null:
		gm._drain_swamp(0, 1.0)
		_check(signage._basin[0]["name"].text == "Puddle", "Water-hole name is missing")
		_check(signage._basin[0]["pct"].text == "80.0%", "Water-hole percentage no longer updates")
		_check(signage._basin[0]["gal"].text.contains("4.0 / 5.0"), "Water-hole gallons no longer update")
	for sprite in main.find_children("*", "Sprite2D", true, false):
		_check(sprite.texture == null or not sprite.texture.resource_path.ends_with("/billboard.png"), "Story billboard still appears in the world")
	for node in main.find_children("*", "Control", true, false):
		if node is Label or node is Button:
			_check(not node.text.contains("SWAMP TIMES"), "Swamp Times strip still appears in gameplay")
	var hud = main.hud
	_check(not hud.has_node("MarginContainer/VBoxContainer/TopBar/HBox/WaterCell"), "HUD still shows the global water percentage")
	_check(hud.get_node("MarginContainer/VBoxContainer").get_child_count() == 3, "HUD still attaches a news strip")
	world._on_reached_island()
	_check(main.player.is_physics_processing(), "Story ending freezes the player")
	var night = world.get("night_skin")
	# Inspect the actual night module rather than rely on the holder's name.
	for node in world.get_children():
		if node.get_script() == load("res://scripts/world/night.gd"):
			night = node
	_check(night != null, "Night module missing")
	if night != null:
		_check(night._floor_wash.position.x < world.terrain_points[0].x, "Night wash edge crosses playable town")
	_check(PixelUI.THEME.default_font_size >= 12, "Body font is too small")
	main.queue_free()
	await process_frame
	var title = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title)
	current_scene = title
	title._start_new_game()
	_check(title.character_picker.visible, "New game does not offer character selection")
	title._begin_game()
	await create_timer(1.5).timeout
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/main.tscn", "New game still waits for a story intro")
	for failure in failures:
		push_error(failure)
	print("Presentation feedback checks: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
