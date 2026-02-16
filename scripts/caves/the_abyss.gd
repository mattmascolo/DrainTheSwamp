extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "the_abyss"
	crystal_color = Color(0.6, 0.2, 0.8)  # Purple

	# ~2000px wide cave, deep and alien
	cave_terrain_points = [
		Vector2(0, 240),
		Vector2(160, 234),
		Vector2(320, 246),
		Vector2(480, 236),
		Vector2(640, 248),
		Vector2(800, 238),
		Vector2(960, 250),
		Vector2(1120, 240),
		Vector2(1280, 252),
		Vector2(1440, 242),
		Vector2(1600, 248),
		Vector2(1760, 236),
		Vector2(1880, 244),
		Vector2(2000, 238),
	]

	cave_ceiling_points = [
		Vector2(0, 92),
		Vector2(200, 84),
		Vector2(400, 90),
		Vector2(600, 78),
		Vector2(800, 86),
		Vector2(1000, 80),
		Vector2(1200, 88),
		Vector2(1400, 82),
		Vector2(1600, 86),
		Vector2(1800, 80),
		Vector2(2000, 84),
	]

func _setup_loot_and_lore() -> void:
	# Mineral deposits at x=500
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "mineral_deposits"
	loot1.cave_id = cave_id
	loot1.reward_money = 250000.0
	loot1.reward_text = "Found rare mineral deposits! +$250,000"
	loot1.position = Vector2(500, _get_cave_terrain_y_at(500))
	add_child(loot1)

	# Ancient pump core at x=1200
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "ancient_pump_core"
	loot2.cave_id = cave_id
	loot2.reward_pump_levels = 15
	loot2.reward_text = "Found an ancient pump core! Pump upgraded +15 levels!"
	loot2.position = Vector2(1200, _get_cave_terrain_y_at(1200))
	add_child(loot2)

	# Alien device at x=1750
	var loot3 = preload("res://scripts/caves/loot_node.gd").new()
	loot3.loot_id = "alien_device"
	loot3.cave_id = cave_id
	loot3.reward_stat_levels = {"drain_mastery": 8}
	loot3.reward_text = "An alien device hums with energy! Drain Mastery +8 levels!"
	loot3.position = Vector2(1750, _get_cave_terrain_y_at(1750))
	add_child(loot3)

	# Deep lore at x=900
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "abyss_origin"
	lore1.cave_id = cave_id
	lore1.lore_text = "The walls pulse with an otherworldly glow. Something ancient lives in the deepest waters. This is where the swamp began..."
	lore1.position = Vector2(900, _get_cave_terrain_y_at(900))
	add_child(lore1)

	# Bioluminescent patches (alien theme)
	for i in range(10):
		var bx: float = randf_range(100, 1900)
		var by: float
		if randf() > 0.5:
			by = _get_cave_terrain_y_at(bx) - randf_range(1, 4)
		else:
			by = _get_cave_ceiling_y_at(bx) + randf_range(2, 8)
		var glow := ColorRect.new()
		glow.size = Vector2(randf_range(3, 8), randf_range(2, 5))
		glow.position = Vector2(bx - glow.size.x * 0.5, by)
		glow.color = Color(0.5, 0.2, 0.7, 0.3)
		glow.z_index = 2
		var glow_mat := CanvasItemMaterial.new()
		glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = glow_mat
		add_child(glow)
