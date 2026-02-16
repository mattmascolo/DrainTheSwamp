extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "muddy_hollow"
	crystal_color = Color(0.8, 0.6, 0.2)  # Warm amber

	# Theme colors: warm brown
	ground_color = Color(0.35, 0.25, 0.14)
	ceiling_color = Color(0.25, 0.18, 0.12)
	wall_color = Color(0.22, 0.15, 0.10)
	rock_mid_color = Color(0.30, 0.20, 0.12)
	rock_sub_color = Color(0.24, 0.16, 0.10)
	rock_inner_ceil_color = Color(0.28, 0.20, 0.14)

	# ~1280px wide cave, dramatic hills and one valley for the pool
	# Valley at ~600-800 for pool 0
	cave_terrain_points = [
		Vector2(0, 200),
		Vector2(100, 195),
		Vector2(220, 190),
		Vector2(360, 185),
		Vector2(480, 192),
		Vector2(560, 210),   # slope into valley
		Vector2(640, 230),   # valley floor (pool)
		Vector2(720, 232),   # valley floor
		Vector2(800, 212),   # slope out
		Vector2(900, 192),
		Vector2(1000, 188),
		Vector2(1100, 193),
		Vector2(1280, 190),
	]

	# Ceiling mirrors floor waviness (lower over valley)
	cave_ceiling_points = [
		Vector2(0, 80),
		Vector2(120, 74),
		Vector2(260, 78),
		Vector2(400, 72),
		Vector2(560, 68),
		Vector2(700, 62),   # lower over valley
		Vector2(800, 66),
		Vector2(920, 72),
		Vector2(1060, 78),
		Vector2(1280, 74),
	]

	# 1 pool: valley at x=560-800
	cave_pool_defs = [
		{
			"x_range": [560.0, 800.0],
			"pool_index": 0,
			"loot_data": {
				"loot_id": "muddy_pool_loot",
				"reward_money": 200.0,
				"reward_stat_levels": {"move_speed": 2},
				"reward_text": "The pool reveals hidden treasures! +$200, Move Speed +2!",
			},
		},
	]

func _setup_loot_and_lore() -> void:
	# Old lantern near entrance at x=150
	var lantern_loot = preload("res://scripts/caves/loot_node.gd").new()
	lantern_loot.loot_id = "old_lantern"
	lantern_loot.cave_id = cave_id
	lantern_loot.reward_upgrades = {"lantern": 3}
	lantern_loot.reward_text = "Found a powerful old lantern! The darkness recedes..."
	lantern_loot.position = Vector2(150, _get_cave_terrain_y_at(150))
	add_child(lantern_loot)

	# Old toolbox at x=1100 — unlocks Spoon for free
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "old_toolbox"
	loot2.cave_id = cave_id
	loot2.reward_tool_unlock = "spoon"
	loot2.reward_text = "Found an old toolbox! Gained a Spoon!"
	loot2.position = Vector2(1100, _get_cave_terrain_y_at(1100))
	add_child(loot2)

	# Strange symbol lore wall at x=400
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "strange_symbol"
	lore1.cave_id = cave_id
	lore1.lore_text = "Strange markings on the wall... They seem to depict an ancient drainage system. Someone was here before you."
	lore1.position = Vector2(400, _get_cave_terrain_y_at(400))
	add_child(lore1)

	# Mud puddles (decorative) — only on non-pool terrain
	for i in range(5):
		var px: float = randf_range(100, 500)
		var py: float = _get_cave_terrain_y_at(px)
		var puddle := ColorRect.new()
		puddle.size = Vector2(randf_range(12, 28), randf_range(3, 6))
		puddle.position = Vector2(px - puddle.size.x * 0.5, py - puddle.size.y)
		puddle.color = Color(0.35, 0.25, 0.15, 0.6)
		puddle.z_index = 2
		add_child(puddle)
