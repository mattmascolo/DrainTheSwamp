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
	gm.money = 123.0
	var legacy: Dictionary = gm.get_save_data()
	legacy.erase("character_id")
	gm.character_id = "piggy"
	gm.load_save_data(legacy)
	_check(gm.character_id == "drainer" and gm.money == 123.0, "Legacy save changes appearance or progress")
	legacy.character_id = "unknown_character"
	gm.load_save_data(legacy)
	_check(gm.character_id == "drainer", "Unknown saved character does not fall back safely")
	var title = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title)
	title._start_new_game()
	_check(title.character_picker.visible and title.character_buttons.size() == 4, "Character picker missing choices")
	for i in range(4):
		title.character_buttons[i].button_pressed = true
		title.character_buttons[i].pressed.emit()
		_check(title.selected_character == CharacterCatalog.CHARACTERS[i].id, "Card selects wrong character")
	title._close_character_picker()
	_check(gm.money == 123.0 and not title.character_picker.visible, "Cancelling selection resets the existing run")
	title.queue_free()
	await process_frame
	for character in CharacterCatalog.CHARACTERS:
		gm.character_id = character.id
		var saved: Dictionary = JSON.parse_string(JSON.stringify(gm.get_save_data()))
		gm.character_id = "drainer"
		gm.load_save_data(saved)
		_check(gm.character_id == character.id, "Character lost across JSON save/load")
		var actor = load("res://scenes/player/player.tscn").instantiate()
		root.add_child(actor)
		actor.set_physics_process(false)
		actor._skin.set_process(false)
		var skin = actor._skin
		_check(skin._character_id == character.id, "Player loaded wrong skin")
		for direction in [-1.0, 1.0]:
			actor.visual.scale.x = direction
			for animation in ["idle", "walk", "scoop"]:
				skin._set_strip(animation)
				var facing: float = skin._sprite.global_transform.x.x * (-1.0 if skin._sprite.flip_h else 1.0)
				_check((facing > 0.0) == (direction > 0.0), "%s %s faces backwards" % [character.id, animation])
		actor.velocity = Vector2.ZERO
		actor.is_walking = true
		skin._process(0.15)
		_check(skin._current_strip() == "walk", "Walking transition missing")
		actor.is_walking = false
		skin._process(0.2)
		skin._on_scooped()
		skin._process(0.15)
		_check(skin._current_strip() == "scoop", "Scoop transition missing")
		skin._process(0.5)
		_check(skin._current_strip() == "idle", "Scoop fails to return to idle")
		if character.id != "drainer":
			actor.velocity.y = 180.0
			skin._process(0.1)
			_check(skin._current_strip() == "jump", "Airborne animation missing")
			for animation in ["walk", "scoop", "jump"]:
				var image: Image = skin._strips[animation].get_image()
				_check(image.get_size() == Vector2i(512, 128), "Animation sheet has wrong cells")
				var hashes: Array[int] = []
				for frame in range(4):
					var cell: Image = image.get_region(Rect2i(frame * 128, 0, 128, 128))
					var digest: int = hash(cell.get_data())
					if not hashes.has(digest):
						hashes.append(digest)
					_check(cell.get_used_rect().has_area(), "Animation has an empty frame")
				_check(hashes.size() >= 3, "Animation repeats still artwork")
		gm.current_tool_id = "spoon"
		skin._refresh_tool()
		_check(skin._tool.visible, "Character cannot carry a tool")
		actor.queue_free()
		await process_frame
	gm.character_id = "humphrey"
	gm._reset_progression(0.0)
	_check(gm.character_id == "humphrey", "Prestige reset changes character")
	gm.reset_game()
	_check(gm.character_id == "drainer", "Fresh reset does not restore default")
	var start_title = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(start_title)
	current_scene = start_title
	start_title._start_new_game()
	start_title.character_buttons[1].pressed.emit()
	start_title._begin_game()
	await create_timer(1.5).timeout
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/main.tscn", "Picker does not start gameplay")
	_check(current_scene.player._skin._character_id == "humphrey", "New run loses selected character")
	var file := FileAccess.open("user://save_data.json", FileAccess.READ)
	var disk_save: Dictionary = JSON.parse_string(file.get_as_text())
	_check(disk_save.character_id == "humphrey", "New run does not save selected character")
	current_scene.queue_free()
	current_scene = null
	await process_frame
	gm.swamp_states[0]["gallons_drained"] = gm.swamp_definitions[0]["total_gallons"]
	_check(gm.enter_cave("muddy_hollow"), "Drained cave cannot be entered")
	var cave = load("res://scenes/caves/muddy_hollow.tscn").instantiate()
	root.add_child(cave)
	await process_frame
	_check(cave.player_ref._skin._character_id == "humphrey", "Cave player loses selected character")
	cave.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("Character selection checks: ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
