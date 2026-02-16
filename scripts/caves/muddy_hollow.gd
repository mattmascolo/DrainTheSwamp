extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "muddy_hollow"
	crystal_color = Color(0.8, 0.6, 0.2)  # Warm amber

	# ~1280px wide cave, gentle floor
	cave_terrain_points = [
		Vector2(0, 200),
		Vector2(100, 198),
		Vector2(220, 202),
		Vector2(360, 196),
		Vector2(480, 200),
		Vector2(600, 205),
		Vector2(720, 198),
		Vector2(840, 203),
		Vector2(960, 197),
		Vector2(1100, 201),
		Vector2(1280, 195),
	]

	# Ceiling ~100-120px above floor
	cave_ceiling_points = [
		Vector2(0, 80),
		Vector2(120, 74),
		Vector2(260, 82),
		Vector2(400, 70),
		Vector2(520, 78),
		Vector2(640, 72),
		Vector2(780, 80),
		Vector2(920, 75),
		Vector2(1060, 82),
		Vector2(1280, 76),
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

	# Scrap metal pile at x=800
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "scrap_metal"
	loot1.cave_id = cave_id
	loot1.reward_money = 75.0
	loot1.reward_text = "Found scrap metal! +$75"
	loot1.position = Vector2(800, _get_cave_terrain_y_at(800))
	add_child(loot1)

	# Old toolbox at x=1100 — unlocks Spoon for free
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "old_toolbox"
	loot2.cave_id = cave_id
	loot2.reward_tool_unlock = "spoon"
	loot2.reward_text = "Found an old toolbox! Gained a Spoon!"
	loot2.position = Vector2(1100, _get_cave_terrain_y_at(1100))
	add_child(loot2)

	# Strange symbol lore wall at x=500
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "strange_symbol"
	lore1.cave_id = cave_id
	lore1.lore_text = "Strange markings on the wall... They seem to depict an ancient drainage system. Someone was here before you."
	lore1.position = Vector2(500, _get_cave_terrain_y_at(500))
	add_child(lore1)

	# Mud puddles (decorative)
	for i in range(5):
		var px: float = randf_range(100, 1200)
		var py: float = _get_cave_terrain_y_at(px)
		var puddle := ColorRect.new()
		puddle.size = Vector2(randf_range(12, 28), randf_range(3, 6))
		puddle.position = Vector2(px - puddle.size.x * 0.5, py - puddle.size.y)
		puddle.color = Color(0.35, 0.25, 0.15, 0.6)
		puddle.z_index = 2
		add_child(puddle)
