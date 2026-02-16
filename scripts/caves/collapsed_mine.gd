extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "collapsed_mine"
	crystal_color = Color(0.3, 0.6, 0.8)  # Blue-green

	# ~1800px wide cave, mine theme with varied floor
	cave_terrain_points = [
		Vector2(0, 230),
		Vector2(140, 224),
		Vector2(280, 234),
		Vector2(420, 226),
		Vector2(560, 236),
		Vector2(700, 228),
		Vector2(840, 238),
		Vector2(980, 230),
		Vector2(1120, 240),
		Vector2(1260, 232),
		Vector2(1400, 236),
		Vector2(1540, 228),
		Vector2(1680, 234),
		Vector2(1800, 226),
	]

	cave_ceiling_points = [
		Vector2(0, 90),
		Vector2(180, 82),
		Vector2(360, 88),
		Vector2(540, 76),
		Vector2(720, 84),
		Vector2(900, 78),
		Vector2(1080, 86),
		Vector2(1260, 80),
		Vector2(1440, 84),
		Vector2(1620, 78),
		Vector2(1800, 82),
	]

func _setup_loot_and_lore() -> void:
	# Mining haul at x=500
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "mining_haul"
	loot1.cave_id = cave_id
	loot1.reward_money = 50000.0
	loot1.reward_text = "Found a massive mining haul! +$50,000"
	loot1.position = Vector2(500, _get_cave_terrain_y_at(500))
	add_child(loot1)

	# Generator core at x=1100 — unlocks Wheelbarrow
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "generator_core"
	loot2.cave_id = cave_id
	loot2.reward_tool_unlock = "wheelbarrow"
	loot2.reward_text = "Found a generator core! Gained a Wheelbarrow!"
	loot2.position = Vector2(1100, _get_cave_terrain_y_at(1100))
	add_child(loot2)

	# Efficiency module at x=1550
	var loot3 = preload("res://scripts/caves/loot_node.gd").new()
	loot3.loot_id = "efficiency_module"
	loot3.cave_id = cave_id
	loot3.reward_stat_levels = {"water_value": 5}
	loot3.reward_text = "Found an efficiency module! Water Value +5 levels!"
	loot3.position = Vector2(1550, _get_cave_terrain_y_at(1550))
	add_child(loot3)

	# Mine history lore at x=800
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "mine_history"
	lore1.cave_id = cave_id
	lore1.lore_text = "Old mine cart tracks disappear into rubble. This mine was abandoned in a hurry. Equipment lies scattered everywhere."
	lore1.position = Vector2(800, _get_cave_terrain_y_at(800))
	add_child(lore1)

	# Wooden beam supports (mine theme decorations)
	for i in range(6):
		var bx: float = 200.0 + i * 260.0
		var floor_y: float = _get_cave_terrain_y_at(bx)
		var ceil_y: float = _get_cave_ceiling_y_at(bx)
		# Vertical beam
		var beam := ColorRect.new()
		beam.size = Vector2(4, floor_y - ceil_y - 4)
		beam.position = Vector2(bx - 2, ceil_y + 2)
		beam.color = Color(0.4, 0.28, 0.14)
		beam.z_index = 1
		add_child(beam)
		# Horizontal crossbeam
		var cross := ColorRect.new()
		cross.size = Vector2(20, 3)
		cross.position = Vector2(bx - 10, ceil_y + 2)
		cross.color = Color(0.35, 0.24, 0.12)
		cross.z_index = 1
		add_child(cross)

	# Metal debris
	for i in range(5):
		var dx: float = randf_range(100, 1700)
		var dy: float = _get_cave_terrain_y_at(dx)
		var debris := ColorRect.new()
		debris.size = Vector2(randf_range(3, 8), randf_range(2, 5))
		debris.position = Vector2(dx - debris.size.x * 0.5, dy - debris.size.y)
		debris.color = Color(0.45, 0.42, 0.4, 0.7)
		debris.rotation = randf_range(-0.4, 0.4)
		debris.z_index = 2
		add_child(debris)
