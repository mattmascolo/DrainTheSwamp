extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "sunken_grotto"
	crystal_color = Color(0.2, 0.65, 0.6)  # Teal

	# ~2200px wide cave, flooded and dripping
	cave_terrain_points = [
		Vector2(0, 242),
		Vector2(140, 248),
		Vector2(270, 238),
		Vector2(400, 252),
		Vector2(530, 244),
		Vector2(660, 256),
		Vector2(790, 240),
		Vector2(920, 250),
		Vector2(1050, 238),
		Vector2(1180, 254),
		Vector2(1310, 244),
		Vector2(1440, 258),
		Vector2(1570, 242),
		Vector2(1700, 252),
		Vector2(1830, 236),
		Vector2(1960, 248),
		Vector2(2080, 240),
		Vector2(2200, 246),
	]

	cave_ceiling_points = [
		Vector2(0, 86),
		Vector2(220, 78),
		Vector2(440, 84),
		Vector2(660, 72),
		Vector2(880, 80),
		Vector2(1100, 74),
		Vector2(1320, 82),
		Vector2(1540, 76),
		Vector2(1760, 84),
		Vector2(1980, 78),
		Vector2(2200, 82),
	]

func _setup_loot_and_lore() -> void:
	# Sunken riches at x=600
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "sunken_riches"
	loot1.cave_id = cave_id
	loot1.reward_money = 2000000.0
	loot1.reward_text = "Found sunken riches in the grotto! +$2,000,000"
	loot1.position = Vector2(600, _get_cave_terrain_y_at(600))
	add_child(loot1)

	# Capacity relic at x=1500
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "capacity_relic"
	loot2.cave_id = cave_id
	loot2.reward_stat_levels = {"carrying_capacity": 8}
	loot2.reward_text = "A waterlogged relic expands your capacity! Carrying Capacity +8 levels!"
	loot2.position = Vector2(1500, _get_cave_terrain_y_at(1500))
	add_child(loot2)

	# Grotto lore at x=1000
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "grotto_secrets"
	lore1.cave_id = cave_id
	lore1.lore_text = "Water drips endlessly from every surface. This grotto was once part of an underground river. The water remembers its path..."
	lore1.position = Vector2(1000, _get_cave_terrain_y_at(1000))
	add_child(lore1)

	# Dripping water features (grotto theme)
	for i in range(15):
		var dx: float = randf_range(80, 2120)
		var dy: float = _get_cave_ceiling_y_at(dx) + randf_range(1, 4)
		var drip_line := Line2D.new()
		drip_line.width = 1.0
		drip_line.default_color = Color(0.3, 0.55, 0.6, 0.4)
		drip_line.add_point(Vector2(dx, dy))
		drip_line.add_point(Vector2(dx + randf_range(-1, 1), dy + randf_range(4, 12)))
		drip_line.z_index = 5
		add_child(drip_line)

	# Shallow floor pools (more than usual for flooded theme)
	for i in range(6):
		var px: float = randf_range(100, 2100)
		var py: float = _get_cave_terrain_y_at(px)
		var pw: float = randf_range(20, 40)
		var ph: float = randf_range(3, 6)
		var pool := ColorRect.new()
		pool.size = Vector2(pw, ph)
		pool.position = Vector2(px - pw * 0.5, py - ph)
		pool.color = Color(0.15, 0.35, 0.45, 0.5)
		pool.z_index = 1
		add_child(pool)
