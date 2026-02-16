extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "gator_den"
	crystal_color = Color(0.8, 0.6, 0.2)  # Warm amber

	# ~1400px wide cave, uneven floor with bone-scattered theme
	cave_terrain_points = [
		Vector2(0, 210),
		Vector2(120, 206),
		Vector2(240, 214),
		Vector2(360, 208),
		Vector2(480, 216),
		Vector2(600, 210),
		Vector2(720, 218),
		Vector2(840, 212),
		Vector2(960, 220),
		Vector2(1080, 214),
		Vector2(1200, 208),
		Vector2(1400, 212),
	]

	cave_ceiling_points = [
		Vector2(0, 86),
		Vector2(140, 78),
		Vector2(280, 84),
		Vector2(420, 72),
		Vector2(560, 80),
		Vector2(700, 76),
		Vector2(840, 82),
		Vector2(980, 74),
		Vector2(1120, 80),
		Vector2(1280, 78),
		Vector2(1400, 82),
	]

func _setup_loot_and_lore() -> void:
	# Bone pile at x=300
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "bone_pile"
	loot1.cave_id = cave_id
	loot1.reward_money = 500.0
	loot1.reward_text = "Found valuable bones! +$500"
	loot1.position = Vector2(300, _get_cave_terrain_y_at(300))
	add_child(loot1)

	# Rusty Bucket at x=800 — unlocks Bucket for free
	var loot2 = preload("res://scripts/caves/loot_node.gd").new()
	loot2.loot_id = "rusty_bucket"
	loot2.cave_id = cave_id
	loot2.reward_tool_unlock = "bucket"
	loot2.reward_text = "Found a rusty bucket! Gained a Bucket!"
	loot2.position = Vector2(800, _get_cave_terrain_y_at(800))
	add_child(loot2)

	# Lantern upgrade at x=1200
	var loot3 = preload("res://scripts/caves/loot_node.gd").new()
	loot3.loot_id = "old_lamp"
	loot3.cave_id = cave_id
	loot3.reward_upgrades = {"lantern": 2}
	loot3.reward_text = "Found an old lamp! Lantern upgraded!"
	loot3.position = Vector2(1200, _get_cave_terrain_y_at(1200))
	add_child(loot3)

	# Gator warning lore at x=600
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "gator_warning"
	lore1.cave_id = cave_id
	lore1.lore_text = "Scratch marks cover the walls. Something large once called this place home. Bones are scattered everywhere..."
	lore1.position = Vector2(600, _get_cave_terrain_y_at(600))
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
