extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "gator_den"
	crystal_color = Color(0.6, 0.7, 0.2)  # Yellow-green

	# Theme colors: dark olive
	ground_color = Color(0.25, 0.28, 0.15)
	ceiling_color = Color(0.18, 0.22, 0.12)
	wall_color = Color(0.15, 0.18, 0.10)
	rock_mid_color = Color(0.22, 0.24, 0.13)
	rock_sub_color = Color(0.18, 0.20, 0.10)
	rock_inner_ceil_color = Color(0.20, 0.24, 0.14)

	# ~1400px wide cave, one valley for pool at ~700-900
	cave_terrain_points = [
		Vector2(0, 210),
		Vector2(120, 205),
		Vector2(240, 198),
		Vector2(360, 192),
		Vector2(500, 196),
		Vector2(600, 208),    # slope into valley
		Vector2(700, 232),    # valley floor (pool)
		Vector2(800, 236),    # valley floor
		Vector2(900, 214),    # slope out
		Vector2(1020, 198),
		Vector2(1140, 194),
		Vector2(1260, 200),
		Vector2(1400, 196),
	]

	cave_ceiling_points = [
		Vector2(0, 86),
		Vector2(140, 78),
		Vector2(280, 82),
		Vector2(420, 74),
		Vector2(560, 70),
		Vector2(700, 64),    # lower over valley
		Vector2(840, 62),
		Vector2(980, 68),
		Vector2(1120, 76),
		Vector2(1280, 80),
		Vector2(1400, 78),
	]

	# 1 pool: valley at x=600-900
	cave_pool_defs = [
		{
			"x_range": [600.0, 900.0],
			"pool_index": 0,
			"loot_data": {
				"loot_id": "gator_pool_loot",
				"reward_money": 1000.0,
				"reward_stat_levels": {"stamina": 3},
				"reward_text": "Drained the gator's pool! +$1,000, Stamina +3!",
			},
		},
	]

func _setup_loot_and_lore() -> void:
	# Rusty Bucket at x=300 — unlocks Bucket for free
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "rusty_bucket"
	loot1.cave_id = cave_id
	loot1.reward_tool_unlock = "bucket"
	loot1.reward_text = "Found a rusty bucket! Gained a Bucket!"
	loot1.position = Vector2(300, _get_cave_terrain_y_at(300))
	add_child(loot1)

	# Lantern upgrade at x=1200
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "old_lamp"
	loot2.cave_id = cave_id
	loot2.reward_upgrades = {"lantern": 2}
	loot2.reward_text = "Found an old lamp! Lantern upgraded!"
	loot2.position = Vector2(1200, _get_cave_terrain_y_at(1200))
	add_child(loot2)

	# Gator warning lore at x=450
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "gator_warning"
	lore1.cave_id = cave_id
	lore1.lore_text = "Scratch marks cover the walls. Something large once called this place home. Bones are scattered everywhere..."
	lore1.position = Vector2(450, _get_cave_terrain_y_at(450))
	add_child(lore1)

	# Scattered bones (decorative)
	for i in range(8):
		var bx: float = randf_range(100, 1300)
		var by: float = _get_cave_terrain_y_at(bx)
		var bone := ColorRect.new()
		bone.size = Vector2(randf_range(4, 10), randf_range(1, 3))
		bone.position = Vector2(bx - bone.size.x * 0.5, by - bone.size.y)
		bone.color = Color(0.75, 0.7, 0.6, 0.7)
		bone.rotation = randf_range(-0.3, 0.3)
		bone.z_index = 2
		add_child(bone)
