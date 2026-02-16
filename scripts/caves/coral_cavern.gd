extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "coral_cavern"
	crystal_color = Color(0.85, 0.4, 0.5)  # Coral pink

	# ~2600px wide cave, organic coral formations
	cave_terrain_points = [
		Vector2(0, 240),
		Vector2(140, 248),
		Vector2(270, 236),
		Vector2(400, 250),
		Vector2(530, 242),
		Vector2(660, 256),
		Vector2(790, 238),
		Vector2(920, 252),
		Vector2(1050, 240),
		Vector2(1180, 254),
		Vector2(1310, 244),
		Vector2(1440, 258),
		Vector2(1570, 240),
		Vector2(1700, 252),
		Vector2(1830, 236),
		Vector2(1960, 250),
		Vector2(2090, 242),
		Vector2(2220, 256),
		Vector2(2350, 244),
		Vector2(2480, 250),
		Vector2(2600, 242),
	]

	cave_ceiling_points = [
		Vector2(0, 84),
		Vector2(260, 76),
		Vector2(520, 82),
		Vector2(780, 70),
		Vector2(1040, 78),
		Vector2(1300, 72),
		Vector2(1560, 80),
		Vector2(1820, 74),
		Vector2(2080, 82),
		Vector2(2340, 76),
		Vector2(2600, 80),
	]

func _setup_loot_and_lore() -> void:
	# Coral treasure at x=800
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "coral_treasure"
	loot1.cave_id = cave_id
	loot1.reward_money = 50000000.0
	loot1.reward_text = "Found a pearl-encrusted treasure chest! +$50,000,000"
	loot1.position = Vector2(800, _get_cave_terrain_y_at(800))
	add_child(loot1)

	# Water value crystal at x=1800
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "value_crystal"
	loot2.cave_id = cave_id
	loot2.reward_stat_levels = {"water_value": 12}
	loot2.reward_text = "A prismatic crystal refracts pure value! Water Value +12 levels!"
	loot2.position = Vector2(1800, _get_cave_terrain_y_at(1800))
	add_child(loot2)

	# Coral lore at x=1300
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "coral_origins"
	lore1.cave_id = cave_id
	lore1.lore_text = "Living coral grows in impossible colors. This cavern was once an ocean floor, pushed deep underground by forces beyond comprehension..."
	lore1.position = Vector2(1300, _get_cave_terrain_y_at(1300))
	add_child(lore1)

	# Coral formations (organic branching shapes)
	for i in range(14):
		var cx: float = randf_range(100, 2500)
		var on_floor: bool = randf() < 0.7
		var cy: float
		if on_floor:
			cy = _get_cave_terrain_y_at(cx)
		else:
			cy = _get_cave_ceiling_y_at(cx)
		var coral := Line2D.new()
		coral.width = randf_range(2.0, 3.5)
		var hue: float = randf_range(0.0, 0.15)
		coral.default_color = Color.from_hsv(hue, 0.6, 0.8, 0.7)
		var branch_h: float = randf_range(8, 20)
		if on_floor:
			coral.add_point(Vector2(cx, cy))
			coral.add_point(Vector2(cx + randf_range(-3, 3), cy - branch_h * 0.5))
			coral.add_point(Vector2(cx + randf_range(-5, 5), cy - branch_h))
		else:
			coral.add_point(Vector2(cx, cy))
			coral.add_point(Vector2(cx + randf_range(-3, 3), cy + branch_h * 0.5))
			coral.add_point(Vector2(cx + randf_range(-5, 5), cy + branch_h))
		coral.z_index = 3
		add_child(coral)

	# Bioluminescent specks
	for i in range(10):
		var sx: float = randf_range(80, 2520)
		var sy: float
		if randf() > 0.5:
			sy = _get_cave_terrain_y_at(sx) - randf_range(2, 6)
		else:
			sy = _get_cave_ceiling_y_at(sx) + randf_range(2, 8)
		var speck := ColorRect.new()
		speck.size = Vector2(randf_range(2, 4), randf_range(2, 3))
		speck.position = Vector2(sx - speck.size.x * 0.5, sy)
		speck.color = Color(0.9, 0.5, 0.6, 0.35)
		speck.z_index = 2
		var glow_mat := CanvasItemMaterial.new()
		glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		speck.material = glow_mat
		add_child(speck)
