extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "the_mire"
	crystal_color = Color(0.2, 0.5, 0.15)  # Dark green

	# ~2000px wide cave, tangled swamp underground
	cave_terrain_points = [
		Vector2(0, 238),
		Vector2(130, 244),
		Vector2(250, 236),
		Vector2(380, 250),
		Vector2(500, 240),
		Vector2(620, 252),
		Vector2(750, 238),
		Vector2(870, 248),
		Vector2(1000, 236),
		Vector2(1130, 250),
		Vector2(1260, 242),
		Vector2(1400, 254),
		Vector2(1530, 240),
		Vector2(1650, 248),
		Vector2(1780, 236),
		Vector2(1900, 246),
		Vector2(2000, 240),
	]

	cave_ceiling_points = [
		Vector2(0, 90),
		Vector2(200, 82),
		Vector2(400, 88),
		Vector2(600, 74),
		Vector2(800, 84),
		Vector2(1000, 76),
		Vector2(1200, 86),
		Vector2(1400, 78),
		Vector2(1600, 84),
		Vector2(1800, 76),
		Vector2(2000, 82),
	]

func _setup_loot_and_lore() -> void:
	# Swamp treasure at x=500
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "swamp_treasure"
	loot1.cave_id = cave_id
	loot1.reward_money = 500000.0
	loot1.reward_text = "Found a chest buried in the muck! +$500,000"
	loot1.position = Vector2(500, _get_cave_terrain_y_at(500))
	add_child(loot1)

	# Drain mastery relic at x=1300
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "drain_relic"
	loot2.cave_id = cave_id
	loot2.reward_stat_levels = {"drain_mastery": 5}
	loot2.reward_text = "An ancient drain relic pulses with power! Drain Mastery +5 levels!"
	loot2.position = Vector2(1300, _get_cave_terrain_y_at(1300))
	add_child(loot2)

	# Mire lore at x=900
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "mire_depths"
	lore1.cave_id = cave_id
	lore1.lore_text = "Twisted roots claw through the walls. The mire has been swallowing things for centuries. The deeper you go, the older it gets..."
	lore1.position = Vector2(900, _get_cave_terrain_y_at(900))
	add_child(lore1)

	# Tangled vines and hanging moss (mire theme)
	for i in range(12):
		var vx: float = randf_range(100, 1900)
		var vy: float = _get_cave_ceiling_y_at(vx)
		var vine := Line2D.new()
		vine.width = randf_range(1.0, 2.0)
		vine.default_color = Color(0.18, 0.35, 0.12, 0.6)
		var hang: float = randf_range(15, 40)
		vine.add_point(Vector2(vx, vy))
		vine.add_point(Vector2(vx + randf_range(-6, 6), vy + hang * 0.4))
		vine.add_point(Vector2(vx + randf_range(-8, 8), vy + hang * 0.7))
		vine.add_point(Vector2(vx + randf_range(-4, 4), vy + hang))
		vine.z_index = 5
		add_child(vine)

	# Glowing fungi on floor
	for i in range(8):
		var fx: float = randf_range(80, 1920)
		var fy: float = _get_cave_terrain_y_at(fx)
		var fungus := ColorRect.new()
		fungus.size = Vector2(randf_range(3, 6), randf_range(4, 8))
		fungus.position = Vector2(fx - fungus.size.x * 0.5, fy - fungus.size.y)
		fungus.color = Color(0.3, 0.6, 0.2, 0.5)
		fungus.z_index = 2
		var glow_mat := CanvasItemMaterial.new()
		glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		fungus.material = glow_mat
		add_child(fungus)
