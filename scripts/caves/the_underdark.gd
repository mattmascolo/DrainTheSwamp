extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "the_underdark"
	crystal_color = Color(0.5, 0.15, 0.65)  # Deep purple

	# ~2800px wide cave, ancient and oppressive
	cave_terrain_points = [
		Vector2(0, 244),
		Vector2(150, 250),
		Vector2(290, 238),
		Vector2(430, 256),
		Vector2(570, 242),
		Vector2(710, 254),
		Vector2(850, 236),
		Vector2(990, 252),
		Vector2(1130, 240),
		Vector2(1270, 258),
		Vector2(1410, 244),
		Vector2(1550, 260),
		Vector2(1690, 242),
		Vector2(1830, 256),
		Vector2(1970, 238),
		Vector2(2110, 252),
		Vector2(2250, 240),
		Vector2(2390, 254),
		Vector2(2530, 244),
		Vector2(2670, 252),
		Vector2(2800, 246),
	]

	cave_ceiling_points = [
		Vector2(0, 82),
		Vector2(280, 74),
		Vector2(560, 80),
		Vector2(840, 68),
		Vector2(1120, 76),
		Vector2(1400, 70),
		Vector2(1680, 78),
		Vector2(1960, 72),
		Vector2(2240, 80),
		Vector2(2520, 74),
		Vector2(2800, 78),
	]

func _setup_loot_and_lore() -> void:
	# Ancient hoard at x=800
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "ancient_hoard"
	loot1.cave_id = cave_id
	loot1.reward_money = 250000000.0
	loot1.reward_text = "Found an ancient hoard from a forgotten age! +$250,000,000"
	loot1.position = Vector2(800, _get_cave_terrain_y_at(800))
	add_child(loot1)

	# Drain mastery obelisk at x=2000
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "drain_obelisk"
	loot2.cave_id = cave_id
	loot2.reward_stat_levels = {"drain_mastery": 15}
	loot2.reward_text = "An obelisk of pure drain energy! Drain Mastery +15 levels!"
	loot2.position = Vector2(2000, _get_cave_terrain_y_at(2000))
	add_child(loot2)

	# Underdark lore at x=1400
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "underdark_warning"
	lore1.cave_id = cave_id
	lore1.lore_text = "Runes carved by something inhuman cover these walls. A warning? An invitation? The darkness here is older than the swamp itself..."
	lore1.position = Vector2(1400, _get_cave_terrain_y_at(1400))
	add_child(lore1)

	# Ancient stone pillars (crumbling, alien)
	for i in range(10):
		var px: float = 180.0 + i * 260.0
		var floor_y: float = _get_cave_terrain_y_at(px)
		var ceil_y: float = _get_cave_ceiling_y_at(px)
		# Some pillars are broken
		var broken: bool = randf() < 0.3
		var pillar_h: float = floor_y - ceil_y - 4
		if broken:
			pillar_h *= randf_range(0.3, 0.6)
		var pillar := ColorRect.new()
		pillar.size = Vector2(5, pillar_h)
		pillar.position = Vector2(px - 2.5, floor_y - pillar_h if broken else ceil_y + 2)
		pillar.color = Color(0.28, 0.22, 0.32)
		pillar.z_index = 1
		add_child(pillar)

	# Bioluminescent patches (purple/violet)
	for i in range(12):
		var bx: float = randf_range(100, 2700)
		var by: float
		if randf() > 0.5:
			by = _get_cave_terrain_y_at(bx) - randf_range(1, 4)
		else:
			by = _get_cave_ceiling_y_at(bx) + randf_range(2, 8)
		var glow := ColorRect.new()
		glow.size = Vector2(randf_range(3, 8), randf_range(2, 5))
		glow.position = Vector2(bx - glow.size.x * 0.5, by)
		glow.color = Color(0.4, 0.15, 0.55, 0.3)
		glow.z_index = 2
		var glow_mat := CanvasItemMaterial.new()
		glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = glow_mat
		add_child(glow)

	# Rune markings on walls
	for i in range(6):
		var rx: float = randf_range(200, 2600)
		var on_floor: bool = randf() < 0.5
		var ry: float
		if on_floor:
			ry = _get_cave_terrain_y_at(rx) - randf_range(1, 3)
		else:
			ry = _get_cave_ceiling_y_at(rx) + randf_range(1, 4)
		var rune := ColorRect.new()
		rune.size = Vector2(randf_range(4, 8), randf_range(3, 6))
		rune.position = Vector2(rx - rune.size.x * 0.5, ry)
		rune.color = Color(0.5, 0.2, 0.7, 0.2)
		rune.z_index = 2
		var rune_mat := CanvasItemMaterial.new()
		rune_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		rune.material = rune_mat
		add_child(rune)
