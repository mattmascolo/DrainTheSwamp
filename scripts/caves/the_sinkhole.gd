extends "res://scripts/caves/cave_base.gd"

func _init() -> void:
	cave_id = "the_sinkhole"
	crystal_color = Color(0.3, 0.6, 0.8)  # Blue-green

	# Theme colors: grey-blue
	ground_color = Color(0.28, 0.30, 0.35)
	ceiling_color = Color(0.20, 0.22, 0.28)
	wall_color = Color(0.16, 0.18, 0.22)
	rock_mid_color = Color(0.24, 0.26, 0.30)
	rock_sub_color = Color(0.20, 0.22, 0.26)
	rock_inner_ceil_color = Color(0.22, 0.24, 0.30)

	# ~1600px wide cave, 2 valleys for 2 pools
	# Valley 1: x=350-550, Valley 2: x=950-1150
	cave_terrain_points = [
		Vector2(0, 200),
		Vector2(100, 195),
		Vector2(220, 190),
		Vector2(300, 200),    # slope into valley 1
		Vector2(380, 230),    # valley 1 floor
		Vector2(450, 235),    # valley 1 floor (deepest)
		Vector2(530, 228),    # valley 1 floor
		Vector2(600, 198),    # ridge between pools
		Vector2(700, 186),    # ridge peak
		Vector2(800, 182),    # ridge
		Vector2(900, 196),    # slope into valley 2
		Vector2(980, 228),    # valley 2 floor
		Vector2(1060, 234),   # valley 2 floor (deepest)
		Vector2(1140, 226),   # valley 2 floor
		Vector2(1220, 198),   # slope out
		Vector2(1340, 188),
		Vector2(1460, 192),
		Vector2(1600, 190),
	]

	cave_ceiling_points = [
		Vector2(0, 88),
		Vector2(160, 82),
		Vector2(320, 76),
		Vector2(450, 68),   # lower over valley 1
		Vector2(600, 74),
		Vector2(780, 80),   # higher over ridge
		Vector2(960, 72),
		Vector2(1060, 66),  # lower over valley 2
		Vector2(1200, 74),
		Vector2(1400, 80),
		Vector2(1600, 78),
	]

	# 2 pools: valley 1 and valley 2
	cave_pool_defs = [
		{
			"x_range": [300.0, 600.0],
			"pool_index": 0,
			"loot_data": {
				"loot_id": "sinkhole_pool_1",
				"reward_money": 8000.0,
				"reward_text": "The first pool drains away! +$8,000",
			},
		},
		{
			"x_range": [900.0, 1220.0],
			"pool_index": 1,
			"loot_data": {
				"loot_id": "sinkhole_pool_2",
				"reward_stat_levels": {"scoop_power": 4},
				"reward_text": "The deep pool reveals a power crystal! Scoop Power +4!",
			},
		},
	]

func _setup_loot_and_lore() -> void:
	# Sinkhole lore at x=700 (on the ridge between pools)
	var lore1 = preload("res://scripts/caves/lore_wall.gd").new()
	lore1.lore_id = "sinkhole_origin"
	lore1.cave_id = cave_id
	lore1.lore_text = "The ground collapsed here long ago. Water seeps from every crack. This sinkhole connects to something deeper..."
	lore1.position = Vector2(700, _get_cave_terrain_y_at(700))
	add_child(lore1)

	# Waterlogged safe past the pools at x=1400
	var loot1 = preload("res://scripts/caves/loot_node.gd").new()
	loot1.loot_id = "waterlogged_safe"
	loot1.cave_id = cave_id
	loot1.reward_money = 5000.0
	loot1.reward_text = "Cracked open a waterlogged safe! +$5,000"
	loot1.position = Vector2(1400, _get_cave_terrain_y_at(1400))
	add_child(loot1)

	# Extra water puddles (wet theme) — on ridges only
	for i in range(6):
		var px: float = randf_range(620, 880)
		var py: float = _get_cave_terrain_y_at(px)
		var puddle := ColorRect.new()
		puddle.size = Vector2(randf_range(16, 32), randf_range(3, 6))
		puddle.position = Vector2(px - puddle.size.x * 0.5, py - puddle.size.y)
		puddle.color = Color(0.2, 0.35, 0.45, 0.5)
		puddle.z_index = 2
		add_child(puddle)
