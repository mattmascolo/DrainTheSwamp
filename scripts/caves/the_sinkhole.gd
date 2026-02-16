extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "the_sinkhole"
	crystal_color = Color(0.3, 0.6, 0.8)  # Blue-green

	# ~1600px wide cave, wet theme with many dips
	cave_terrain_points = [
		Vector2(0, 220),
		Vector2(120, 216),
		Vector2(260, 226),
		Vector2(400, 218),
		Vector2(520, 228),
		Vector2(640, 222),
		Vector2(780, 230),
		Vector2(920, 224),
		Vector2(1060, 232),
		Vector2(1180, 220),
		Vector2(1320, 226),
		Vector2(1460, 218),
		Vector2(1600, 222),
	]

	cave_ceiling_points = [
		Vector2(0, 88),
		Vector2(160, 80),
		Vector2(320, 86),
		Vector2(480, 74),
		Vector2(640, 82),
		Vector2(800, 76),
		Vector2(960, 84),
		Vector2(1120, 78),
		Vector2(1280, 82),
		Vector2(1440, 76),
		Vector2(1600, 80),
	]

func _setup_loot_and_lore() -> void:
	# Waterlogged safe at x=400
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "waterlogged_safe"
	loot1.cave_id = cave_id
	loot1.reward_money = 5000.0
	loot1.reward_text = "Cracked open a waterlogged safe! +$5,000"
	loot1.position = Vector2(400, _get_cave_terrain_y_at(400))
	add_child(loot1)

	# Broken pump parts at x=900
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "pump_parts"
	loot2.cave_id = cave_id
	loot2.reward_pump_levels = 5
	loot2.reward_text = "Found broken pump parts! Pump upgraded +5 levels!"
	loot2.position = Vector2(900, _get_cave_terrain_y_at(900))
	add_child(loot2)

	# Stat crystal at x=1350
	var loot3 = preload("res://scripts/caves/loot_node.gd").new()
	loot3.loot_id = "stat_crystal"
	loot3.cave_id = cave_id
	loot3.reward_stat_levels = {"scoop_power": 3}
	loot3.reward_text = "A crystal pulses with power! Scoop Power +3 levels!"
	loot3.position = Vector2(1350, _get_cave_terrain_y_at(1350))
	add_child(loot3)

	# Sinkhole lore at x=700
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "sinkhole_origin"
	lore1.cave_id = cave_id
	lore1.lore_text = "The ground collapsed here long ago. Water seeps from every crack. This sinkhole connects to something deeper..."
	lore1.position = Vector2(700, _get_cave_terrain_y_at(700))
	add_child(lore1)

	# Extra water puddles (wet theme)
	for i in range(8):
		var px: float = randf_range(80, 1520)
		var py: float = _get_cave_terrain_y_at(px)
		var puddle := ColorRect.new()
		puddle.size = Vector2(randf_range(16, 32), randf_range(3, 6))
		puddle.position = Vector2(px - puddle.size.x * 0.5, py - puddle.size.y)
		puddle.color = Color(0.2, 0.35, 0.45, 0.5)
		puddle.z_index = 2
		add_child(puddle)
