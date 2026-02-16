extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "mariana_trench"
	crystal_color = Color(0.2, 0.4, 0.9)  # Bioluminescent blue

	# ~3200px wide cave, the deepest abyss
	cave_terrain_points = [
		Vector2(0, 246),
		Vector2(160, 252),
		Vector2(310, 240),
		Vector2(460, 258),
		Vector2(610, 244),
		Vector2(760, 260),
		Vector2(910, 242),
		Vector2(1060, 256),
		Vector2(1210, 238),
		Vector2(1360, 262),
		Vector2(1510, 248),
		Vector2(1660, 264),
		Vector2(1810, 244),
		Vector2(1960, 258),
		Vector2(2110, 240),
		Vector2(2260, 256),
		Vector2(2410, 242),
		Vector2(2560, 260),
		Vector2(2710, 248),
		Vector2(2860, 256),
		Vector2(3010, 242),
		Vector2(3200, 250),
	]

	cave_ceiling_points = [
		Vector2(0, 78),
		Vector2(320, 68),
		Vector2(640, 76),
		Vector2(960, 64),
		Vector2(1280, 72),
		Vector2(1600, 66),
		Vector2(1920, 74),
		Vector2(2240, 68),
		Vector2(2560, 76),
		Vector2(2880, 70),
		Vector2(3200, 74),
	]

func _setup_loot_and_lore() -> void:
	# Abyssal treasure at x=900
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "abyssal_treasure"
	loot1.cave_id = cave_id
	loot1.reward_money = 1000000000.0
	loot1.reward_text = "Found the abyssal treasure! +$1,000,000,000"
	loot1.position = Vector2(900, _get_cave_terrain_y_at(900))
	add_child(loot1)

	# All stats boost at x=2200
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "trench_core"
	loot2.cave_id = cave_id
	loot2.reward_stat_levels = {
		"carrying_capacity": 10,
		"move_speed": 10,
		"stamina": 10,
		"stamina_regen": 10,
		"water_value": 10,
		"scoop_power": 10,
		"drain_mastery": 10,
	}
	loot2.reward_text = "The Trench Core surges through you! ALL stats +10 levels!"
	loot2.position = Vector2(2200, _get_cave_terrain_y_at(2200))
	add_child(loot2)

	# Final lore at x=1600
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "trench_truth"
	lore1.cave_id = cave_id
	lore1.lore_text = "At the bottom of everything, where pressure crushes stone and light has never reached... the source of all water. The beginning and the end of every swamp, every ocean, every drop."
	lore1.position = Vector2(1600, _get_cave_terrain_y_at(1600))
	add_child(lore1)

	# Bioluminescent organisms (deep sea theme)
	for i in range(20):
		var bx: float = randf_range(100, 3100)
		var by: float
		if randf() > 0.5:
			by = _get_cave_terrain_y_at(bx) - randf_range(1, 5)
		else:
			by = _get_cave_ceiling_y_at(bx) + randf_range(2, 10)
		var glow := ColorRect.new()
		glow.size = Vector2(randf_range(2, 6), randf_range(2, 4))
		glow.position = Vector2(bx - glow.size.x * 0.5, by)
		var hue: float = randf_range(0.55, 0.7)
		glow.color = Color.from_hsv(hue, 0.7, 0.8, 0.35)
		glow.z_index = 2
		var glow_mat := CanvasItemMaterial.new()
		glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = glow_mat
		add_child(glow)

	# Whale bone fragments
	for i in range(4):
		var wx: float = randf_range(400, 2800)
		var wy: float = _get_cave_terrain_y_at(wx)
		# Rib-like curved line
		var bone := Line2D.new()
		bone.width = randf_range(2.0, 3.0)
		bone.default_color = Color(0.75, 0.72, 0.68, 0.5)
		var curve_h: float = randf_range(10, 20)
		bone.add_point(Vector2(wx - 4, wy))
		bone.add_point(Vector2(wx, wy - curve_h))
		bone.add_point(Vector2(wx + 4, wy - curve_h * 0.3))
		bone.z_index = 2
		add_child(bone)

	# Sunken ship debris
	for i in range(3):
		var sx: float = randf_range(600, 2600)
		var sy: float = _get_cave_terrain_y_at(sx)
		# Plank
		var plank := ColorRect.new()
		plank.size = Vector2(randf_range(14, 28), randf_range(3, 5))
		plank.position = Vector2(sx - plank.size.x * 0.5, sy - plank.size.y)
		plank.color = Color(0.3, 0.22, 0.14, 0.6)
		plank.rotation = randf_range(-0.5, 0.5)
		plank.z_index = 2
		add_child(plank)

	# Kelp strands from ceiling
	for i in range(10):
		var kx: float = randf_range(150, 3050)
		var ky: float = _get_cave_ceiling_y_at(kx)
		var kelp := Line2D.new()
		kelp.width = randf_range(1.5, 2.5)
		kelp.default_color = Color(0.15, 0.4, 0.2, 0.5)
		var hang: float = randf_range(20, 50)
		kelp.add_point(Vector2(kx, ky))
		kelp.add_point(Vector2(kx + randf_range(-4, 4), ky + hang * 0.3))
		kelp.add_point(Vector2(kx + randf_range(-6, 6), ky + hang * 0.6))
		kelp.add_point(Vector2(kx + randf_range(-3, 3), ky + hang))
		kelp.z_index = 5
		add_child(kelp)
