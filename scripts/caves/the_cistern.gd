extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "the_cistern"
	crystal_color = Color(0.45, 0.55, 0.7)  # Steel blue

	# ~2400px wide cave, angular and industrial
	cave_terrain_points = [
		Vector2(0, 235),
		Vector2(130, 240),
		Vector2(260, 232),
		Vector2(390, 248),
		Vector2(520, 236),
		Vector2(650, 244),
		Vector2(780, 230),
		Vector2(910, 246),
		Vector2(1040, 238),
		Vector2(1170, 252),
		Vector2(1300, 234),
		Vector2(1430, 248),
		Vector2(1560, 236),
		Vector2(1690, 250),
		Vector2(1820, 240),
		Vector2(1950, 254),
		Vector2(2080, 238),
		Vector2(2210, 246),
		Vector2(2400, 240),
	]

	cave_ceiling_points = [
		Vector2(0, 88),
		Vector2(240, 80),
		Vector2(480, 86),
		Vector2(720, 72),
		Vector2(960, 82),
		Vector2(1200, 74),
		Vector2(1440, 84),
		Vector2(1680, 76),
		Vector2(1920, 82),
		Vector2(2160, 76),
		Vector2(2400, 80),
	]

func _setup_loot_and_lore() -> void:
	# Cistern vault at x=700
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "cistern_vault"
	loot1.cave_id = cave_id
	loot1.reward_money = 10000000.0
	loot1.reward_text = "Cracked open a sealed cistern vault! +$10,000,000"
	loot1.position = Vector2(700, _get_cave_terrain_y_at(700))
	add_child(loot1)

	# Water wagon blueprint at x=1400
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "wagon_blueprint"
	loot2.cave_id = cave_id
	loot2.reward_tool_unlock = "water_wagon"
	loot2.reward_text = "Found a Water Wagon blueprint! Gained a Water Wagon!"
	loot2.position = Vector2(1400, _get_cave_terrain_y_at(1400))
	add_child(loot2)

	# Scoop power amplifier at x=2100
	var loot3 = preload("res://scripts/caves/loot_node.gd").new()
	loot3.loot_id = "power_amplifier"
	loot3.cave_id = cave_id
	loot3.reward_stat_levels = {"scoop_power": 10}
	loot3.reward_text = "A power amplifier surges through you! Scoop Power +10 levels!"
	loot3.position = Vector2(2100, _get_cave_terrain_y_at(2100))
	add_child(loot3)

	# Cistern lore at x=1100
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "cistern_builders"
	lore1.cave_id = cave_id
	lore1.lore_text = "Precise stonework lines these walls. Someone built this cistern to hold unimaginable amounts of water. The engineering is beyond anything modern..."
	lore1.position = Vector2(1100, _get_cave_terrain_y_at(1100))
	add_child(lore1)

	# Concrete pillars (industrial cistern theme)
	for i in range(8):
		var px: float = 200.0 + i * 280.0
		var floor_y: float = _get_cave_terrain_y_at(px)
		var ceil_y: float = _get_cave_ceiling_y_at(px)
		var pillar := ColorRect.new()
		pillar.size = Vector2(6, floor_y - ceil_y - 4)
		pillar.position = Vector2(px - 3, ceil_y + 2)
		pillar.color = Color(0.42, 0.42, 0.44)
		pillar.z_index = 1
		add_child(pillar)
		# Pillar cap
		var cap := ColorRect.new()
		cap.size = Vector2(10, 3)
		cap.position = Vector2(px - 5, ceil_y + 2)
		cap.color = Color(0.38, 0.38, 0.40)
		cap.z_index = 1
		add_child(cap)

	# Pipe fragments
	for i in range(5):
		var pipe_x: float = randf_range(100, 2300)
		var pipe_y: float = _get_cave_terrain_y_at(pipe_x)
		var pipe := ColorRect.new()
		pipe.size = Vector2(randf_range(12, 24), randf_range(3, 5))
		pipe.position = Vector2(pipe_x - pipe.size.x * 0.5, pipe_y - pipe.size.y)
		pipe.color = Color(0.5, 0.45, 0.35, 0.7)
		pipe.rotation = randf_range(-0.3, 0.3)
		pipe.z_index = 2
		add_child(pipe)
