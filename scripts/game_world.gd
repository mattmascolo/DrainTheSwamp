extends Node2D

# Day/Night cycle - 5 minute real-time cycle (300 seconds)
const CYCLE_DURATION: float = 300.0

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
var cycle_time: float = 0.0

# Terrain: array of Vector2 points defining the ground surface
# Pattern per swamp: entry_slope_top, basin_left, basin_right, exit_slope_top
# Plus initial left shore and final right shore
var terrain_points: Array[Vector2] = [
	Vector2(0, 136), Vector2(80, 136),            # Left shore (high, pump here)
	Vector2(120, 160), Vector2(170, 160),          # Puddle basin (shallow, depth 24)
	Vector2(210, 144), Vector2(270, 148),          # Ridge 1 (slopes down)
	Vector2(350, 200), Vector2(450, 200),          # Pond basin (depth 52)
	Vector2(520, 164), Vector2(590, 172),          # Ridge 2 (slopes down)
	Vector2(690, 240), Vector2(810, 240),          # Marsh basin (depth 68)
	Vector2(890, 196), Vector2(960, 204),          # Ridge 3 (slopes down)
	Vector2(1060, 284), Vector2(1200, 284),        # Bog basin (depth 80)
	Vector2(1290, 230), Vector2(1360, 240),        # Ridge 4 (slopes down)
	Vector2(1480, 330), Vector2(1660, 330),        # Deep Swamp basin (depth 90)
	Vector2(1760, 280), Vector2(1920, 290),        # Right shore (lowest)
]

# Swamp geometry indices: swamp i -> terrain_points indices
const SWAMP_COUNT: int = 5

# Visual nodes created procedurally
var water_polygons: Array[Polygon2D] = []
var water_surface_lines: Array[Line2D] = []
var terrain_polygon: Polygon2D = null
var terrain_body: StaticBody2D = null
var water_detect_areas: Array[Area2D] = []
var water_walls: Array = []
var swamp_labels: Array[Label] = []
var clouds: Array[ColorRect] = []
var cattails: Array[Node2D] = []
var stars: Array[ColorRect] = []
var fireflies: Array[Dictionary] = []
var leaves: Array[Dictionary] = []
var leaf_timer: float = 0.0
var lily_pads: Array[Dictionary] = []
var depth_polygons: Array[Polygon2D] = []
var shimmer_lines: Array[Line2D] = []
var mud_patches: Array[Dictionary] = []
var player_in_pump_area: bool = false
var pump_player_ref: Node2D = null

# Second pass visuals
var moon: Node2D = null
var moon_glow: ColorRect = null
var moon_body: ColorRect = null
var bubbles: Array[Dictionary] = []
var bubble_timer: float = 0.0
var foam_lines: Array[Line2D] = []
var pollen: Array[Dictionary] = []
var pollen_timer: float = 0.0
var birds: Array[Dictionary] = []
var bird_timer: float = 0.0
var fog_patches: Array[Dictionary] = []
var dragonflies: Array[Dictionary] = []
var pump_light_ref: ColorRect = null
var water_highlights: Array[Dictionary] = []
var sun_node: Node2D = null

# Colors
const SKY_COLOR_TOP := Color(0.22, 0.38, 0.72)
const SKY_COLOR_MID := Color(0.45, 0.62, 0.88)
const SKY_COLOR_BOTTOM := Color(0.62, 0.78, 0.92)
const GROUND_COLOR := Color(0.45, 0.32, 0.16)
const GROUND_MID_COLOR := Color(0.38, 0.25, 0.12)
const GROUND_DARK_COLOR := Color(0.28, 0.18, 0.08)
const WATER_COLOR := Color(0.18, 0.32, 0.22, 0.92)
const WATER_EMPTY_COLOR := Color(0.3, 0.45, 0.32, 0.65)
const WATER_SURFACE_COLOR := Color(0.35, 0.55, 0.4, 0.6)
const GRASS_COLOR := Color(0.25, 0.48, 0.15)
const GRASS_LIGHT_COLOR := Color(0.35, 0.58, 0.2)
const ROCK_COLOR := Color(0.42, 0.4, 0.38)
const ROCK_DARK_COLOR := Color(0.32, 0.3, 0.28)

var wave_time: float = 0.0

func _ready() -> void:
	cycle_time = CYCLE_DURATION * 0.2
	_build_sky()
	_build_sun()
	_build_clouds()
	_build_distant_hills()
	_build_treeline()
	_build_terrain()
	_build_terrain_details()
	_build_pump_station()
	_build_water()
	_build_water_walls()
	_build_water_detect_areas()
	_build_swamp_labels()
	_build_vegetation()
	_build_stars()
	_build_fireflies()
	_build_tree_trunks()
	_build_lily_pads()
	_build_depth_gradients()
	_build_shimmer_lines()
	_build_mud_patches()
	_build_mushrooms()
	_build_ferns()
	_build_moon()
	_build_foam_lines()
	_build_fog_patches()
	_build_dragonflies()
	_build_water_highlights()

	GameManager.water_level_changed.connect(_on_water_level_changed)
	GameManager.swamp_completed.connect(_on_swamp_completed)

# --- Sky & Atmosphere ---
func _build_sky() -> void:
	# Three-band sky gradient
	var sky_top := ColorRect.new()
	sky_top.position = Vector2(-100, -80)
	sky_top.size = Vector2(2120, 100)
	sky_top.color = SKY_COLOR_TOP
	sky_top.z_index = -12
	add_child(sky_top)

	var sky_mid := ColorRect.new()
	sky_mid.position = Vector2(-100, 20)
	sky_mid.size = Vector2(2120, 80)
	sky_mid.color = SKY_COLOR_MID
	sky_mid.z_index = -12
	add_child(sky_mid)

	var sky_bot := ColorRect.new()
	sky_bot.position = Vector2(-100, 96)
	sky_bot.size = Vector2(2120, 100)
	sky_bot.color = SKY_COLOR_BOTTOM
	sky_bot.z_index = -12
	add_child(sky_bot)

func _build_sun() -> void:
	sun_node = Node2D.new()
	sun_node.z_index = -10
	sun_node.visible = false
	add_child(sun_node)

	# Outer glow
	var glow := ColorRect.new()
	glow.size = Vector2(48, 48)
	glow.position = Vector2(-24, -24)
	glow.color = Color(1, 0.95, 0.6, 0.12)
	sun_node.add_child(glow)

	# Sun body
	var body := ColorRect.new()
	body.size = Vector2(24, 24)
	body.position = Vector2(-12, -12)
	body.color = Color(1, 0.95, 0.55)
	sun_node.add_child(body)

	# Sun core
	var core := ColorRect.new()
	core.size = Vector2(14, 14)
	core.position = Vector2(-7, -7)
	core.color = Color(1, 1, 0.85)
	sun_node.add_child(core)

	# Sun rays (4 small rects for sparkle)
	for angle_i in range(4):
		var ray := ColorRect.new()
		ray.size = Vector2(2, 6)
		ray.position = Vector2(-1, -20 if angle_i < 2 else 14)
		ray.rotation = angle_i * PI / 4.0
		ray.color = Color(1, 0.95, 0.6, 0.3)
		sun_node.add_child(ray)

func _build_clouds() -> void:
	var cloud_data: Array = [
		{"x": 100, "y": 10, "w": 56, "h": 16},
		{"x": 360, "y": 36, "w": 40, "h": 12},
		{"x": 700, "y": 4, "w": 70, "h": 18},
		{"x": 1040, "y": 24, "w": 48, "h": 14},
		{"x": 1400, "y": 12, "w": 60, "h": 16},
		{"x": 1700, "y": 30, "w": 44, "h": 12},
	]
	for cd in cloud_data:
		var cloud_group := Node2D.new()
		cloud_group.z_index = -8
		add_child(cloud_group)

		# Main cloud body
		var main := ColorRect.new()
		main.position = Vector2(cd["x"], cd["y"])
		main.size = Vector2(cd["w"], cd["h"])
		main.color = Color(0.92, 0.94, 0.98, 0.7)
		cloud_group.add_child(main)

		# Cloud puff left
		var puff_l := ColorRect.new()
		puff_l.position = Vector2(cd["x"] - 8, cd["y"] + 4)
		puff_l.size = Vector2(16, cd["h"] - 4)
		puff_l.color = Color(0.88, 0.92, 0.96, 0.5)
		cloud_group.add_child(puff_l)

		# Cloud puff right
		var puff_r := ColorRect.new()
		puff_r.position = Vector2(cd["x"] + cd["w"] - 8, cd["y"] + 4)
		puff_r.size = Vector2(16, cd["h"] - 4)
		puff_r.color = Color(0.88, 0.92, 0.96, 0.5)
		cloud_group.add_child(puff_r)

		# Cloud highlight top
		var highlight := ColorRect.new()
		highlight.position = Vector2(cd["x"] + 6, cd["y"] - 4)
		highlight.size = Vector2(cd["w"] - 12, 6)
		highlight.color = Color(0.96, 0.97, 1.0, 0.5)
		cloud_group.add_child(highlight)

		clouds.append(main)

func _build_distant_hills() -> void:
	# Far hills silhouette
	var hills := Polygon2D.new()
	hills.polygon = PackedVector2Array([
		Vector2(-100, 124), Vector2(120, 100), Vector2(300, 110),
		Vector2(500, 90), Vector2(760, 104), Vector2(1000, 96),
		Vector2(1240, 110), Vector2(1500, 84), Vector2(1760, 100),
		Vector2(1920, 116), Vector2(1920, 150), Vector2(-100, 150)
	])
	hills.color = Color(0.12, 0.28, 0.12, 0.6)
	hills.z_index = -7
	add_child(hills)

	# Mid hills
	var hills2 := Polygon2D.new()
	hills2.polygon = PackedVector2Array([
		Vector2(-100, 130), Vector2(200, 110), Vector2(400, 120),
		Vector2(640, 104), Vector2(900, 116), Vector2(1160, 106),
		Vector2(1400, 120), Vector2(1660, 108), Vector2(1920, 124),
		Vector2(1920, 156), Vector2(-100, 156)
	])
	hills2.color = Color(0.08, 0.22, 0.08, 0.7)
	hills2.z_index = -6
	add_child(hills2)

func _build_treeline() -> void:
	# Dense treeline - jagged top edge for tree canopy look
	var tree_points := PackedVector2Array()
	var x: float = -100.0
	while x < 2020.0:
		var tree_h: float = randf_range(12, 28)
		tree_points.append(Vector2(x, 136 - tree_h))
		tree_points.append(Vector2(x + randf_range(6, 16), 136 - tree_h + randf_range(4, 10)))
		x += randf_range(10, 24)
	tree_points.append(Vector2(2020, 136))
	tree_points.append(Vector2(2020, 164))
	tree_points.append(Vector2(-100, 164))

	var treeline := Polygon2D.new()
	treeline.polygon = tree_points
	treeline.color = Color(0.06, 0.18, 0.05)
	treeline.z_index = -5
	add_child(treeline)

	# Lighter highlight trees in front
	var tree_points2 := PackedVector2Array()
	x = -100.0
	while x < 2020.0:
		var tree_h: float = randf_range(8, 20)
		tree_points2.append(Vector2(x, 140 - tree_h))
		tree_points2.append(Vector2(x + randf_range(6, 12), 140 - tree_h + randf_range(4, 8)))
		x += randf_range(12, 28)
	tree_points2.append(Vector2(2020, 140))
	tree_points2.append(Vector2(2020, 164))
	tree_points2.append(Vector2(-100, 164))

	var treeline2 := Polygon2D.new()
	treeline2.polygon = tree_points2
	treeline2.color = Color(0.1, 0.25, 0.08)
	treeline2.z_index = -4
	add_child(treeline2)

func _build_terrain() -> void:
	# Main ground polygon
	terrain_polygon = Polygon2D.new()
	var ground_points: PackedVector2Array = PackedVector2Array()
	for pt in terrain_points:
		ground_points.append(pt)
	ground_points.append(Vector2(terrain_points[-1].x, 480))
	ground_points.append(Vector2(terrain_points[0].x, 480))
	terrain_polygon.polygon = ground_points
	terrain_polygon.color = GROUND_COLOR
	terrain_polygon.z_index = 0
	add_child(terrain_polygon)

	# Mid soil layer
	var midsoil := Polygon2D.new()
	var mid_points: PackedVector2Array = PackedVector2Array()
	for pt in terrain_points:
		mid_points.append(Vector2(pt.x, pt.y + 10))
	mid_points.append(Vector2(terrain_points[-1].x, 480))
	mid_points.append(Vector2(terrain_points[0].x, 480))
	midsoil.polygon = mid_points
	midsoil.color = GROUND_MID_COLOR
	midsoil.z_index = -1
	add_child(midsoil)

	# Dark subsoil layer
	var subsoil := Polygon2D.new()
	var sub_points: PackedVector2Array = PackedVector2Array()
	for pt in terrain_points:
		sub_points.append(Vector2(pt.x, pt.y + 24))
	sub_points.append(Vector2(terrain_points[-1].x, 480))
	sub_points.append(Vector2(terrain_points[0].x, 480))
	subsoil.polygon = sub_points
	subsoil.color = GROUND_DARK_COLOR
	subsoil.z_index = -2
	add_child(subsoil)

	# Grass strip on top of terrain - two layers for depth
	var grass_dark := Line2D.new()
	grass_dark.width = 6.0
	grass_dark.default_color = GRASS_COLOR
	for pt in terrain_points:
		grass_dark.add_point(pt)
	grass_dark.z_index = 1
	add_child(grass_dark)

	var grass_light := Line2D.new()
	grass_light.width = 3.0
	grass_light.default_color = GRASS_LIGHT_COLOR
	for pt in terrain_points:
		grass_light.add_point(Vector2(pt.x, pt.y - 1.0))
	grass_light.z_index = 1
	add_child(grass_light)

	# Collision: build segments between each pair of terrain points
	terrain_body = StaticBody2D.new()
	add_child(terrain_body)

	for i in range(terrain_points.size() - 1):
		var seg := CollisionShape2D.new()
		var shape := SegmentShape2D.new()
		shape.a = terrain_points[i]
		shape.b = terrain_points[i + 1]
		seg.shape = shape
		terrain_body.add_child(seg)

	# Left wall
	var left_wall := CollisionShape2D.new()
	var lw_shape := SegmentShape2D.new()
	lw_shape.a = Vector2(-20, -100)
	lw_shape.b = Vector2(-20, 480)
	left_wall.shape = lw_shape
	terrain_body.add_child(left_wall)

	# Right wall
	var right_wall := CollisionShape2D.new()
	var rw_shape := SegmentShape2D.new()
	rw_shape.a = Vector2(1940, -100)
	rw_shape.b = Vector2(1940, 480)
	right_wall.shape = rw_shape
	terrain_body.add_child(right_wall)

func _build_terrain_details() -> void:
	# Rocks scattered on ridges and shores
	var rock_positions: Array[Vector2] = [
		Vector2(30, 134), Vector2(64, 134),
		Vector2(220, 142), Vector2(240, 142),
		Vector2(530, 162), Vector2(570, 170),
		Vector2(910, 194), Vector2(940, 202),
		Vector2(1310, 228), Vector2(1350, 238),
		Vector2(1790, 278), Vector2(1880, 288),
	]
	for rp in rock_positions:
		_place_rock(rp, randf_range(4, 10), randf_range(4, 8))

	# Dirt specks on terrain surface
	for i in range(40):
		var rx: float = randf_range(0, 1920)
		var ry: float = _get_terrain_y_at(rx)
		if ry > 0:
			var speck := ColorRect.new()
			speck.position = Vector2(rx, ry + randf_range(2, 12))
			speck.size = Vector2(randf_range(2, 6), randf_range(2, 4))
			speck.color = GROUND_DARK_COLOR.lerp(GROUND_COLOR, randf_range(0, 1))
			speck.color.a = randf_range(0.3, 0.6)
			speck.z_index = 0
			add_child(speck)

func _place_rock(pos: Vector2, w: float, h: float) -> void:
	var rock := Polygon2D.new()
	rock.polygon = PackedVector2Array([
		Vector2(pos.x + 2, pos.y),
		Vector2(pos.x + w - 2, pos.y),
		Vector2(pos.x + w, pos.y + h * 0.4),
		Vector2(pos.x + w - 1.0, pos.y + h),
		Vector2(pos.x + 1.0, pos.y + h),
		Vector2(pos.x, pos.y + h * 0.4),
	])
	rock.color = ROCK_COLOR
	rock.z_index = 1
	add_child(rock)

	# Rock highlight
	var hl := ColorRect.new()
	hl.position = Vector2(pos.x + 2, pos.y + 1.0)
	hl.size = Vector2(w - 4, 2)
	hl.color = Color(0.55, 0.53, 0.5, 0.5)
	hl.z_index = 1
	add_child(hl)

func _build_vegetation() -> void:
	# Cattails near water edges
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var entry_top: Vector2 = geo["entry_top"]
		var exit_top: Vector2 = geo["exit_top"]

		# Place cattails near entry slope
		for j in range(randi_range(2, 4)):
			var cx: float = entry_top.x + randf_range(-10, 16)
			var cy: float = entry_top.y + randf_range(-4, 6)
			_place_cattail(Vector2(cx, cy))

		# Place cattails near exit slope
		for j in range(randi_range(1, 3)):
			var cx: float = exit_top.x + randf_range(-16, 10)
			var cy: float = exit_top.y + randf_range(-4, 6)
			_place_cattail(Vector2(cx, cy))

	# Grass tufts on ridges
	for i in range(terrain_points.size()):
		var pt: Vector2 = terrain_points[i]
		# Only on relatively flat areas (ridges, shores)
		if i > 0 and i < terrain_points.size() - 1:
			var dy: float = absf(terrain_points[i + 1].y - pt.y) / absf(terrain_points[i + 1].x - pt.x + 0.01)
			if dy < 0.3:  # Mostly flat
				for j in range(randi_range(2, 5)):
					var gx: float = pt.x + randf_range(-20, 20)
					_place_grass_tuft(Vector2(gx, _get_terrain_y_at(gx)))

	# Flowers scattered on shore and ridges
	var flower_colors: Array[Color] = [
		Color(0.9, 0.3, 0.3), Color(0.9, 0.85, 0.2),
		Color(0.8, 0.4, 0.7), Color(0.95, 0.95, 0.9)
	]
	for i in range(12):
		var fx: float = randf_range(10, 1900)
		var fy: float = _get_terrain_y_at(fx)
		if fy > 0:
			var flower := ColorRect.new()
			flower.position = Vector2(fx, fy - randf_range(4, 8))
			flower.size = Vector2(4, 4)
			flower.color = flower_colors[randi() % flower_colors.size()]
			flower.z_index = 1
			add_child(flower)

			var stem := ColorRect.new()
			stem.position = Vector2(fx + 1.0, fy - 2)
			stem.size = Vector2(2, 4)
			stem.color = Color(0.2, 0.4, 0.15)
			stem.z_index = 1
			add_child(stem)

func _place_cattail(pos: Vector2) -> void:
	var cattail := Node2D.new()
	cattail.position = pos  # Pivot at base on ground
	cattail.z_index = 3
	add_child(cattail)

	# Stem goes upward from base
	var stem_h: float = randf_range(16, 28)
	var stem_offset_x: float = randf_range(-2, 2)
	var stem := Line2D.new()
	stem.width = 2.0
	stem.default_color = Color(0.3, 0.45, 0.2)
	stem.add_point(Vector2(0, 0))
	stem.add_point(Vector2(stem_offset_x, -stem_h))
	cattail.add_child(stem)

	# Cattail head (brown oval) at top of stem
	var head := ColorRect.new()
	head.position = Vector2(stem_offset_x - 2, -stem_h - 6)
	head.size = Vector2(4, 8)
	head.color = Color(0.45, 0.3, 0.15)
	cattail.add_child(head)

	# Leaf curving out from mid-stem
	var leaf := Line2D.new()
	leaf.width = 2.0
	leaf.default_color = Color(0.25, 0.4, 0.18, 0.8)
	leaf.add_point(Vector2(0, -stem_h * 0.4))
	leaf.add_point(Vector2(randf_range(6, 12), -stem_h * 0.6))
	cattail.add_child(leaf)

	# Second leaf on opposite side
	var leaf2 := Line2D.new()
	leaf2.width = 1.5
	leaf2.default_color = Color(0.22, 0.38, 0.15, 0.7)
	leaf2.add_point(Vector2(0, -stem_h * 0.6))
	leaf2.add_point(Vector2(randf_range(-10, -5), -stem_h * 0.75))
	cattail.add_child(leaf2)

	cattails.append(cattail)

func _place_grass_tuft(pos: Vector2) -> void:
	for k in range(randi_range(2, 4)):
		var blade := Line2D.new()
		blade.width = 1.6
		blade.default_color = GRASS_COLOR.lerp(GRASS_LIGHT_COLOR, randf())
		blade.default_color.a = randf_range(0.6, 1.0)
		var blade_h: float = randf_range(6, 12)
		var blade_lean: float = randf_range(-4, 4)
		blade.add_point(pos)
		blade.add_point(Vector2(pos.x + blade_lean, pos.y - blade_h))
		blade.z_index = 1
		add_child(blade)

# --- Stars ---
func _build_stars() -> void:
	for i in range(35):
		var star := ColorRect.new()
		var sz: float = randf_range(1, 3)
		star.size = Vector2(sz, sz)
		star.position = Vector2(randf_range(-100, 2020), randf_range(-80, 100))
		# Warm-to-cool whites
		var warmth: float = randf()
		star.color = Color(1.0, lerp(0.9, 1.0, warmth), lerp(0.75, 1.0, warmth), 0.0)
		star.z_index = -11
		add_child(star)
		stars.append(star)

# --- Fireflies ---
func _build_fireflies() -> void:
	for i in range(20):
		var fly := ColorRect.new()
		fly.size = Vector2(2, 2)
		fly.color = Color(0.8, 1.0, 0.3, 0.0)
		fly.z_index = 6
		var base_x: float = randf_range(50, 1870)
		var base_y: float = randf_range(80, 260)
		fly.position = Vector2(base_x, base_y)
		add_child(fly)
		fireflies.append({
			"node": fly,
			"base_x": base_x,
			"base_y": base_y,
			"phase_x": randf() * TAU,
			"phase_y": randf() * TAU,
			"speed_x": randf_range(0.3, 0.8),
			"speed_y": randf_range(0.4, 0.9),
			"amp_x": randf_range(15, 40),
			"amp_y": randf_range(10, 25),
			"glow_phase": randf() * TAU,
		})

# --- Tree Trunks ---
func _build_tree_trunks() -> void:
	for i in range(50):
		var trunk := Line2D.new()
		var tx: float = randf_range(-80, 2000)
		var tw: float = randf_range(2, 4)
		trunk.width = tw
		trunk.default_color = Color(0.15, 0.1, 0.05, randf_range(0.3, 0.6))
		var top_y: float = randf_range(100, 130)
		trunk.add_point(Vector2(tx, top_y))
		trunk.add_point(Vector2(tx + randf_range(-1, 1), 160))
		trunk.z_index = -5
		add_child(trunk)

# --- Lily Pads ---
func _build_lily_pads() -> void:
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var basin_left: Vector2 = geo["basin_left"]
		var basin_right: Vector2 = geo["basin_right"]
		var basin_w: float = basin_right.x - basin_left.x
		var count: int = clampi(int(basin_w / 30.0), 1, 6)
		for j in range(count):
			var pad_group := Node2D.new()
			pad_group.z_index = 3
			add_child(pad_group)
			var pad_x: float = basin_left.x + randf_range(10, basin_w - 10)
			var pad_w: float = randf_range(6, 10)
			# Dark green pad
			var pad := ColorRect.new()
			pad.size = Vector2(pad_w, pad_w * 0.5)
			pad.position = Vector2(-pad_w * 0.5, -pad_w * 0.25)
			pad.color = Color(0.12, 0.35, 0.1, 0.85)
			pad_group.add_child(pad)
			# Highlight
			var hl := ColorRect.new()
			hl.size = Vector2(pad_w * 0.4, 1)
			hl.position = Vector2(-pad_w * 0.2, -pad_w * 0.15)
			hl.color = Color(0.25, 0.5, 0.2, 0.5)
			pad_group.add_child(hl)
			# Optional flower
			if randf() < 0.3:
				var flower := ColorRect.new()
				flower.size = Vector2(3, 3)
				flower.position = Vector2(-1.5, -pad_w * 0.35)
				flower.color = Color(0.9, 0.5, 0.6, 0.9)
				pad_group.add_child(flower)
			lily_pads.append({
				"node": pad_group,
				"swamp": i,
				"x": pad_x,
				"phase": randf() * TAU,
			})

# --- Water Depth Gradients ---
func _build_depth_gradients() -> void:
	for i in range(SWAMP_COUNT):
		var dp := Polygon2D.new()
		dp.color = Color(0.08, 0.18, 0.1, 0.6)
		dp.z_index = 1
		add_child(dp)
		depth_polygons.append(dp)
		_update_depth_gradient(i)

func _update_depth_gradient(swamp_index: int) -> void:
	var fill: float = GameManager.get_swamp_fill_fraction(swamp_index)
	if fill <= 0.001:
		depth_polygons[swamp_index].polygon = PackedVector2Array()
		return
	var geo: Dictionary = _get_swamp_geometry(swamp_index)
	var entry_top: Vector2 = geo["entry_top"]
	var basin_left: Vector2 = geo["basin_left"]
	var basin_right: Vector2 = geo["basin_right"]
	var exit_top: Vector2 = geo["exit_top"]
	var basin_y: float = basin_left.y
	var overflow_y: float = maxf(entry_top.y, exit_top.y)
	var water_y: float = basin_y - fill * (basin_y - overflow_y)
	# Depth zone covers bottom 60% of water
	var depth_y: float = lerpf(water_y, basin_y, 0.4)
	var left_x: float = _lerp_x_at_y(entry_top, basin_left, depth_y)
	var right_x: float = _lerp_x_at_y(basin_right, exit_top, depth_y)
	depth_polygons[swamp_index].polygon = PackedVector2Array([
		Vector2(left_x, depth_y),
		Vector2(basin_left.x, basin_y),
		Vector2(basin_right.x, basin_y),
		Vector2(right_x, depth_y),
	])

# --- Water Shimmer Lines ---
func _build_shimmer_lines() -> void:
	for i in range(SWAMP_COUNT):
		var sl := Line2D.new()
		sl.width = 1.5
		sl.default_color = Color(0.35, 0.55, 0.4, 0.2)
		sl.z_index = 3
		add_child(sl)
		shimmer_lines.append(sl)

func _update_shimmer_line(swamp_index: int, left_x: float, right_x: float, water_y: float) -> void:
	var line: Line2D = shimmer_lines[swamp_index]
	line.clear_points()
	var segments: int = maxi(int((right_x - left_x) / 8.0), 3)
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var px: float = lerpf(left_x, right_x, t)
		var wave_offset: float = sin(wave_time * 1.5 + px * 0.2) * 1.2
		line.add_point(Vector2(px, water_y + 3.0 + wave_offset))
	# Pulsing alpha
	var alpha: float = lerpf(0.15, 0.3, (sin(wave_time * 0.8) + 1.0) * 0.5)
	line.default_color = Color(0.35, 0.55, 0.4, alpha)

# --- Mud Patches ---
func _build_mud_patches() -> void:
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var basin_left: Vector2 = geo["basin_left"]
		var basin_right: Vector2 = geo["basin_right"]
		var basin_w: float = basin_right.x - basin_left.x
		var count: int = clampi(int(basin_w / 20.0), 2, 8)
		for j in range(count):
			var mud := ColorRect.new()
			var mw: float = randf_range(6, 14)
			var mh: float = randf_range(2, 4)
			mud.size = Vector2(mw, mh)
			var mx: float = basin_left.x + randf_range(4, basin_w - 4)
			mud.position = Vector2(mx, basin_left.y - mh)
			mud.color = Color(0.25, 0.18, 0.08, 0.7)
			mud.z_index = 0
			mud.visible = false
			add_child(mud)
			# Wet sheen highlight
			var sheen := ColorRect.new()
			sheen.size = Vector2(mw - 2, 1)
			sheen.position = Vector2(mx + 1, basin_left.y - mh + 1)
			sheen.color = Color(0.4, 0.35, 0.25, 0.4)
			sheen.z_index = 0
			sheen.visible = false
			add_child(sheen)
			mud_patches.append({
				"mud": mud,
				"sheen": sheen,
				"swamp": i,
			})

func _update_mud_visibility() -> void:
	for mp in mud_patches:
		var fill: float = GameManager.get_swamp_fill_fraction(mp["swamp"])
		var visible: bool = fill < 0.15
		mp["mud"].visible = visible
		mp["sheen"].visible = visible

# --- Mushrooms ---
func _build_mushrooms() -> void:
	var cap_colors: Array[Color] = [
		Color(0.75, 0.2, 0.15),  # Red
		Color(0.55, 0.35, 0.15), # Brown
		Color(0.8, 0.65, 0.2),   # Gold
	]
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var entry_top: Vector2 = geo["entry_top"]
		var exit_top: Vector2 = geo["exit_top"]
		# Place near entry
		if randf() < 0.7:
			_place_mushroom(Vector2(entry_top.x + randf_range(-12, 4), entry_top.y), cap_colors)
		# Place near exit
		if randf() < 0.7:
			_place_mushroom(Vector2(exit_top.x + randf_range(-4, 12), exit_top.y), cap_colors)
	# A few extra scattered ones
	for i in range(3):
		var mx: float = randf_range(20, 1900)
		var my: float = _get_terrain_y_at(mx)
		if my > 0:
			_place_mushroom(Vector2(mx, my), cap_colors)

func _place_mushroom(pos: Vector2, cap_colors: Array[Color]) -> void:
	var mushroom := Node2D.new()
	mushroom.z_index = 1
	add_child(mushroom)
	# Stem
	var stem := ColorRect.new()
	stem.size = Vector2(2, 5)
	stem.position = Vector2(pos.x - 1, pos.y - 5)
	stem.color = Color(0.9, 0.88, 0.8)
	mushroom.add_child(stem)
	# Cap
	var cap_w: float = randf_range(5, 8)
	var cap := ColorRect.new()
	cap.size = Vector2(cap_w, 3)
	cap.position = Vector2(pos.x - cap_w * 0.5, pos.y - 8)
	var cap_color: Color = cap_colors[randi() % cap_colors.size()]
	cap.color = cap_color
	mushroom.add_child(cap)
	# Highlight
	var cap_hl := ColorRect.new()
	cap_hl.size = Vector2(cap_w - 2, 1)
	cap_hl.position = Vector2(pos.x - cap_w * 0.5 + 1, pos.y - 8)
	cap_hl.color = cap_color.lightened(0.3)
	cap_hl.color.a = 0.6
	mushroom.add_child(cap_hl)
	# Red mushrooms get white spots
	if cap_color.r > 0.6 and cap_color.g < 0.3:
		var spot := ColorRect.new()
		spot.size = Vector2(1, 1)
		spot.position = Vector2(pos.x - 1, pos.y - 7)
		spot.color = Color(0.95, 0.95, 0.9, 0.8)
		mushroom.add_child(spot)
		if cap_w > 6:
			var spot2 := ColorRect.new()
			spot2.size = Vector2(1, 1)
			spot2.position = Vector2(pos.x + 1, pos.y - 7)
			spot2.color = Color(0.95, 0.95, 0.9, 0.8)
			mushroom.add_child(spot2)

# --- Ferns ---
func _build_ferns() -> void:
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var entry_top: Vector2 = geo["entry_top"]
		var exit_top: Vector2 = geo["exit_top"]
		# Near entry
		for j in range(randi_range(1, 2)):
			_place_fern(Vector2(entry_top.x + randf_range(-16, 8), entry_top.y))
		# Near exit
		for j in range(randi_range(1, 2)):
			_place_fern(Vector2(exit_top.x + randf_range(-8, 16), exit_top.y))

func _place_fern(pos: Vector2) -> void:
	var fern := Node2D.new()
	fern.z_index = 1
	add_child(fern)
	var frond_count: int = randi_range(3, 5)
	for i in range(frond_count):
		var frond := Line2D.new()
		frond.width = 1.5
		var green_val: float = randf_range(0.3, 0.55)
		frond.default_color = Color(0.15, green_val, 0.1, 0.8)
		var angle: float = randf_range(-1.2, 1.2)
		var length: float = randf_range(6, 14)
		var mid_x: float = pos.x + sin(angle) * length * 0.5
		var mid_y: float = pos.y - length * 0.5
		var tip_x: float = pos.x + sin(angle) * length
		var tip_y: float = pos.y - length * 0.3
		frond.add_point(pos)
		frond.add_point(Vector2(mid_x, mid_y))
		frond.add_point(Vector2(tip_x, tip_y))
		fern.add_child(frond)

# --- Leaf Particles ---
func _spawn_leaf() -> void:
	if leaves.size() >= 8:
		return
	var leaf := ColorRect.new()
	leaf.size = Vector2(3, 2)
	var is_brown: bool = randf() < 0.4
	if is_brown:
		leaf.color = Color(0.5, 0.35, 0.15, 0.7)
	else:
		leaf.color = Color(0.25, 0.45, 0.15, 0.7)
	var start_y: float = randf_range(60, 200)
	leaf.position = Vector2(-10, start_y)
	leaf.z_index = 5
	add_child(leaf)
	leaves.append({
		"node": leaf,
		"speed": randf_range(15, 35),
		"wobble_phase": randf() * TAU,
		"wobble_amp": randf_range(8, 20),
		"lifetime": 0.0,
		"max_life": randf_range(12, 25),
		"base_y": start_y,
	})

# --- Moon ---
func _build_moon() -> void:
	moon = Node2D.new()
	moon.z_index = -11
	add_child(moon)
	# Moon glow
	moon_glow = ColorRect.new()
	moon_glow.size = Vector2(40, 40)
	moon_glow.position = Vector2(-20, -20)
	moon_glow.color = Color(0.7, 0.75, 0.9, 0.0)
	moon.add_child(moon_glow)
	# Moon body
	moon_body = ColorRect.new()
	moon_body.size = Vector2(16, 16)
	moon_body.position = Vector2(-8, -8)
	moon_body.color = Color(0.9, 0.92, 1.0, 0.0)
	moon.add_child(moon_body)
	# Moon highlight (crescent effect)
	var moon_hl := ColorRect.new()
	moon_hl.size = Vector2(10, 12)
	moon_hl.position = Vector2(-4, -6)
	moon_hl.color = Color(1.0, 1.0, 1.0, 0.0)
	moon.add_child(moon_hl)
	# Moon crater
	var crater := ColorRect.new()
	crater.size = Vector2(3, 3)
	crater.position = Vector2(1, -2)
	crater.color = Color(0.75, 0.78, 0.88, 0.0)
	moon.add_child(crater)
	moon.position = Vector2(1500, 30)

# --- Foam Lines (Shore Froth) ---
func _build_foam_lines() -> void:
	for i in range(SWAMP_COUNT):
		var fl := Line2D.new()
		fl.width = 1.5
		fl.default_color = Color(0.8, 0.9, 0.85, 0.3)
		fl.z_index = 4
		add_child(fl)
		foam_lines.append(fl)

func _update_foam_line(swamp_index: int, left_x: float, right_x: float, water_y: float) -> void:
	var line: Line2D = foam_lines[swamp_index]
	line.clear_points()
	var segments: int = maxi(int((right_x - left_x) / 6.0), 3)
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var px: float = lerpf(left_x, right_x, t)
		# Foam only near edges (first/last 20% of width)
		var edge_frac: float = 1.0 - absf(t - 0.5) * 2.0
		var foam_strength: float = 0.0
		if t < 0.2:
			foam_strength = 1.0 - t / 0.2
		elif t > 0.8:
			foam_strength = (t - 0.8) / 0.2
		var wave_offset: float = sin(wave_time * 3.0 + px * 0.3) * 0.8 * foam_strength
		line.add_point(Vector2(px, water_y - 0.5 + wave_offset))
	var alpha: float = lerpf(0.15, 0.35, (sin(wave_time * 1.2) + 1.0) * 0.5)
	line.default_color = Color(0.85, 0.92, 0.88, alpha)

# --- Fog Patches Near Swamps ---
func _build_fog_patches() -> void:
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var basin_left: Vector2 = geo["basin_left"]
		var basin_right: Vector2 = geo["basin_right"]
		var entry_top: Vector2 = geo["entry_top"]
		var basin_w: float = basin_right.x - basin_left.x
		var count: int = clampi(int(basin_w / 40.0), 1, 4)
		for j in range(count):
			var fog := ColorRect.new()
			var fw: float = randf_range(20, 50)
			var fh: float = randf_range(6, 14)
			fog.size = Vector2(fw, fh)
			var fx: float = basin_left.x + randf_range(0, basin_w - fw)
			var fy: float = entry_top.y - randf_range(8, 24)
			fog.position = Vector2(fx, fy)
			fog.color = Color(0.8, 0.85, 0.9, 0.0)
			fog.z_index = 5
			add_child(fog)
			fog_patches.append({
				"node": fog,
				"base_x": fx,
				"phase": randf() * TAU,
			})

# --- Dragonflies (Daytime) ---
func _build_dragonflies() -> void:
	var df_colors: Array[Color] = [
		Color(0.2, 0.5, 0.9),   # Blue
		Color(0.3, 0.8, 0.4),   # Green
		Color(0.7, 0.3, 0.6),   # Purple
		Color(0.9, 0.4, 0.2),   # Orange
	]
	for i in range(8):
		var df := Node2D.new()
		df.z_index = 6
		add_child(df)
		# Body
		var body := ColorRect.new()
		body.size = Vector2(4, 1)
		body.position = Vector2(-2, 0)
		body.color = df_colors[i % df_colors.size()]
		df.add_child(body)
		# Wings
		var wing_l := ColorRect.new()
		wing_l.size = Vector2(3, 2)
		wing_l.position = Vector2(-3, -2)
		wing_l.color = Color(0.8, 0.9, 1.0, 0.4)
		df.add_child(wing_l)
		var wing_r := ColorRect.new()
		wing_r.size = Vector2(3, 2)
		wing_r.position = Vector2(0, -2)
		wing_r.color = Color(0.8, 0.9, 1.0, 0.4)
		df.add_child(wing_r)
		var base_x: float = randf_range(80, 1840)
		var base_y: float = randf_range(100, 240)
		df.position = Vector2(base_x, base_y)
		dragonflies.append({
			"node": df,
			"base_x": base_x,
			"base_y": base_y,
			"phase_x": randf() * TAU,
			"phase_y": randf() * TAU,
			"speed": randf_range(0.8, 1.5),
			"amp_x": randf_range(30, 60),
			"amp_y": randf_range(15, 30),
			"wing_l": wing_l,
			"wing_r": wing_r,
		})

# --- Water Reflection Highlights ---
func _build_water_highlights() -> void:
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var basin_left: Vector2 = geo["basin_left"]
		var basin_right: Vector2 = geo["basin_right"]
		var basin_w: float = basin_right.x - basin_left.x
		var count: int = clampi(int(basin_w / 30.0), 1, 4)
		for j in range(count):
			var hl := ColorRect.new()
			hl.size = Vector2(randf_range(4, 10), 1)
			hl.color = Color(1.0, 1.0, 0.9, 0.0)
			hl.z_index = 4
			add_child(hl)
			water_highlights.append({
				"node": hl,
				"swamp": i,
				"offset_x": randf_range(0.1, 0.9),
				"phase": randf() * TAU,
			})

# --- Bubble Spawner ---
func _spawn_bubble(swamp_index: int) -> void:
	if bubbles.size() >= 12:
		return
	var geo: Dictionary = _get_swamp_geometry(swamp_index)
	var basin_left: Vector2 = geo["basin_left"]
	var basin_right: Vector2 = geo["basin_right"]
	var fill: float = GameManager.get_swamp_fill_fraction(swamp_index)
	if fill < 0.05:
		return
	var entry_top: Vector2 = geo["entry_top"]
	var exit_top: Vector2 = geo["exit_top"]
	var basin_y: float = basin_left.y
	var overflow_y: float = maxf(entry_top.y, exit_top.y)
	var water_y: float = basin_y - fill * (basin_y - overflow_y)
	var bx: float = randf_range(basin_left.x + 5, basin_right.x - 5)
	var bubble := ColorRect.new()
	var bsize: float = randf_range(2, 4)
	bubble.size = Vector2(bsize, bsize)
	bubble.position = Vector2(bx, basin_y - 2)
	bubble.color = Color(0.6, 0.8, 0.7, 0.5)
	bubble.z_index = 4
	add_child(bubble)
	bubbles.append({
		"node": bubble,
		"target_y": water_y - 2,
		"speed": randf_range(12, 25),
		"wobble_phase": randf() * TAU,
	})

# --- Bird Spawner ---
func _spawn_bird() -> void:
	if birds.size() >= 3:
		return
	var bird := Node2D.new()
	bird.z_index = -7
	add_child(bird)
	# Simple V-shape silhouette
	var wing_l := Line2D.new()
	wing_l.width = 1.5
	wing_l.default_color = Color(0.1, 0.1, 0.15, 0.6)
	wing_l.add_point(Vector2(-4, 2))
	wing_l.add_point(Vector2(0, 0))
	bird.add_child(wing_l)
	var wing_r := Line2D.new()
	wing_r.width = 1.5
	wing_r.default_color = Color(0.1, 0.1, 0.15, 0.6)
	wing_r.add_point(Vector2(0, 0))
	wing_r.add_point(Vector2(4, 2))
	bird.add_child(wing_r)
	var start_x: float = -20
	var start_y: float = randf_range(20, 90)
	bird.position = Vector2(start_x, start_y)
	birds.append({
		"node": bird,
		"wing_l": wing_l,
		"wing_r": wing_r,
		"speed": randf_range(30, 55),
		"flap_speed": randf_range(4.0, 7.0),
		"y_drift": randf_range(-0.3, 0.3),
	})

# --- Pollen Spawner ---
func _spawn_pollen() -> void:
	if pollen.size() >= 15:
		return
	var mote := ColorRect.new()
	mote.size = Vector2(1, 1)
	mote.color = Color(1.0, 0.95, 0.7, 0.0)
	mote.z_index = 5
	var px: float = randf_range(-50, 1970)
	var py: float = randf_range(60, 240)
	mote.position = Vector2(px, py)
	add_child(mote)
	pollen.append({
		"node": mote,
		"phase": randf() * TAU,
		"speed_x": randf_range(2, 8),
		"amp_y": randf_range(5, 15),
		"lifetime": 0.0,
		"max_life": randf_range(8, 18),
		"base_y": py,
	})

func _get_terrain_y_at(x: float) -> float:
	for i in range(terrain_points.size() - 1):
		if x >= terrain_points[i].x and x <= terrain_points[i + 1].x:
			var t: float = (x - terrain_points[i].x) / (terrain_points[i + 1].x - terrain_points[i].x + 0.001)
			return lerpf(terrain_points[i].y, terrain_points[i + 1].y, t)
	return -1.0

# --- Swamp Geometry ---
func _get_swamp_geometry(swamp_index: int) -> Dictionary:
	var base: int = 4 * swamp_index
	return {
		"entry_top": terrain_points[base + 1],
		"basin_left": terrain_points[base + 2],
		"basin_right": terrain_points[base + 3],
		"exit_top": terrain_points[base + 4]
	}

# --- Water ---
func _build_water() -> void:
	water_polygons.clear()
	water_surface_lines.clear()
	for i in range(SWAMP_COUNT):
		var wp := Polygon2D.new()
		wp.color = WATER_COLOR
		wp.z_index = 2
		add_child(wp)
		water_polygons.append(wp)

		# Water surface shine line
		var wl := Line2D.new()
		wl.width = 3.0
		wl.default_color = WATER_SURFACE_COLOR
		wl.z_index = 3
		add_child(wl)
		water_surface_lines.append(wl)

		_update_water_polygon(i)

func _update_water_polygon(swamp_index: int) -> void:
	var fill: float = GameManager.get_swamp_fill_fraction(swamp_index)
	var geo: Dictionary = _get_swamp_geometry(swamp_index)
	var entry_top: Vector2 = geo["entry_top"]
	var basin_left: Vector2 = geo["basin_left"]
	var basin_right: Vector2 = geo["basin_right"]
	var exit_top: Vector2 = geo["exit_top"]

	if fill <= 0.001:
		water_polygons[swamp_index].polygon = PackedVector2Array()
		water_surface_lines[swamp_index].clear_points()
		return

	var basin_y: float = basin_left.y
	var overflow_y: float = maxf(entry_top.y, exit_top.y)
	var water_y: float = basin_y - fill * (basin_y - overflow_y)

	var left_x: float = _lerp_x_at_y(entry_top, basin_left, water_y)
	var right_x: float = _lerp_x_at_y(basin_right, exit_top, water_y)

	var points := PackedVector2Array()
	points.append(Vector2(left_x, water_y))
	points.append(Vector2(basin_left.x, basin_y))
	points.append(Vector2(basin_right.x, basin_y))
	points.append(Vector2(right_x, water_y))

	water_polygons[swamp_index].polygon = points

	# Tint water based on fill
	var col: Color = WATER_COLOR.lerp(WATER_EMPTY_COLOR, 1.0 - fill)
	water_polygons[swamp_index].color = col

	# Update surface line
	_update_water_surface_line(swamp_index, left_x, right_x, water_y)

func _update_water_surface_line(swamp_index: int, left_x: float, right_x: float, water_y: float) -> void:
	var line: Line2D = water_surface_lines[swamp_index]
	line.clear_points()
	var segments: int = int((right_x - left_x) / 6.0)
	segments = maxi(segments, 4)
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var px: float = lerpf(left_x, right_x, t)
		var wave_offset: float = sin(wave_time * 2.0 + px * 0.15) * 1.6
		line.add_point(Vector2(px, water_y + wave_offset))

func _lerp_x_at_y(p1: Vector2, p2: Vector2, target_y: float) -> float:
	if absf(p2.y - p1.y) < 0.001:
		return p1.x
	var t: float = (target_y - p1.y) / (p2.y - p1.y)
	t = clampf(t, 0.0, 1.0)
	return p1.x + t * (p2.x - p1.x)

# --- Water Walls ---
func _build_water_walls() -> void:
	water_walls.clear()
	for i in range(SWAMP_COUNT):
		var left_body := StaticBody2D.new()
		var left_col := CollisionShape2D.new()
		var left_rect := RectangleShape2D.new()
		left_rect.size = Vector2(8, 56)
		left_col.shape = left_rect
		left_body.add_child(left_col)
		add_child(left_body)

		var right_body := StaticBody2D.new()
		var right_col := CollisionShape2D.new()
		var right_rect := RectangleShape2D.new()
		right_rect.size = Vector2(8, 56)
		right_col.shape = right_rect
		right_body.add_child(right_col)
		add_child(right_body)

		water_walls.append({"left": left_body, "right": right_body})
		_update_water_walls(i)

func _update_water_walls(swamp_index: int) -> void:
	var fill: float = GameManager.get_swamp_fill_fraction(swamp_index)
	var walls: Dictionary = water_walls[swamp_index]
	var left_body: StaticBody2D = walls["left"]
	var right_body: StaticBody2D = walls["right"]
	var left_col: CollisionShape2D = left_body.get_child(0) as CollisionShape2D
	var right_col: CollisionShape2D = right_body.get_child(0) as CollisionShape2D

	if fill <= 0.001:
		left_col.disabled = true
		right_col.disabled = true
		left_body.visible = false
		right_body.visible = false
		return

	left_col.disabled = false
	right_col.disabled = false
	left_body.visible = true
	right_body.visible = true

	var geo: Dictionary = _get_swamp_geometry(swamp_index)
	var entry_top: Vector2 = geo["entry_top"]
	var basin_left: Vector2 = geo["basin_left"]
	var basin_right: Vector2 = geo["basin_right"]
	var exit_top: Vector2 = geo["exit_top"]

	var basin_y: float = basin_left.y
	var overflow_y: float = maxf(entry_top.y, exit_top.y)
	var water_y: float = basin_y - fill * (basin_y - overflow_y)

	var left_x: float = _lerp_x_at_y(entry_top, basin_left, water_y)
	var right_x: float = _lerp_x_at_y(basin_right, exit_top, water_y)

	left_body.position = Vector2(left_x, water_y - 28)
	right_body.position = Vector2(right_x, water_y - 28)

# --- Water Detection ---
func _build_water_detect_areas() -> void:
	water_detect_areas.clear()
	for i in range(SWAMP_COUNT):
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 1
		add_child(area)
		water_detect_areas.append(area)

		var geo: Dictionary = _get_swamp_geometry(i)
		var entry_top: Vector2 = geo["entry_top"]
		var basin_left: Vector2 = geo["basin_left"]
		var basin_right: Vector2 = geo["basin_right"]
		var exit_top: Vector2 = geo["exit_top"]

		# Entry slope detection
		var entry_mid: Vector2 = (entry_top + basin_left) * 0.5
		var entry_shape := CollisionShape2D.new()
		var entry_rect := RectangleShape2D.new()
		entry_rect.size = Vector2((basin_left - entry_top).length(), 40)
		entry_shape.shape = entry_rect
		entry_shape.position = entry_mid + Vector2(0, -10)
		entry_shape.rotation = atan2(basin_left.y - entry_top.y, basin_left.x - entry_top.x)
		area.add_child(entry_shape)

		# Basin floor detection
		var basin_mid: Vector2 = (basin_left + basin_right) * 0.5
		var basin_shape := CollisionShape2D.new()
		var basin_rect := RectangleShape2D.new()
		basin_rect.size = Vector2(basin_right.x - basin_left.x, 32)
		basin_shape.shape = basin_rect
		basin_shape.position = basin_mid + Vector2(0, -12)
		area.add_child(basin_shape)

		# Exit slope detection
		var exit_mid: Vector2 = (basin_right + exit_top) * 0.5
		var exit_shape := CollisionShape2D.new()
		var exit_rect := RectangleShape2D.new()
		exit_rect.size = Vector2((exit_top - basin_right).length(), 40)
		exit_shape.shape = exit_rect
		exit_shape.position = exit_mid + Vector2(0, -10)
		exit_shape.rotation = atan2(exit_top.y - basin_right.y, exit_top.x - basin_right.x)
		area.add_child(exit_shape)

		var idx: int = i
		area.body_entered.connect(func(body: Node2D) -> void: _on_swamp_body_entered(body, idx))
		area.body_exited.connect(func(body: Node2D) -> void: _on_swamp_body_exited(body, idx))

# --- Swamp Labels ---
func _build_swamp_labels() -> void:
	swamp_labels.clear()
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var basin_mid_x: float = (geo["basin_left"].x + geo["basin_right"].x) * 0.5
		var label_y: float = geo["entry_top"].y - 24

		var label := Label.new()
		label.text = GameManager.swamp_definitions[i]["name"]
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.7))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.position = Vector2(basin_mid_x - 30, label_y)
		label.z_index = 5
		add_child(label)
		swamp_labels.append(label)

# --- Signal Handlers ---
func _on_swamp_body_entered(body: Node2D, swamp_index: int) -> void:
	if body is CharacterBody2D and body.has_method("set_near_water"):
		body.set_near_water(true, swamp_index)

func _on_swamp_body_exited(body: Node2D, swamp_index: int) -> void:
	if body is CharacterBody2D and body.has_method("set_near_water"):
		body.set_near_water(false, swamp_index)

func _on_water_level_changed(swamp_index: int, _percent: float) -> void:
	if swamp_index >= 0 and swamp_index < SWAMP_COUNT:
		_update_water_polygon(swamp_index)
		_update_water_walls(swamp_index)
		_update_depth_gradient(swamp_index)
		_update_mud_visibility()

func _on_swamp_completed(swamp_index: int, _reward: float) -> void:
	if swamp_index >= 0 and swamp_index < swamp_labels.size():
		swamp_labels[swamp_index].add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 0.9))
		swamp_labels[swamp_index].text = GameManager.swamp_definitions[swamp_index]["name"] + " [DONE]"

# --- Pump Station ---
func _build_pump_station() -> void:
	# Platform/base
	var platform := ColorRect.new()
	platform.position = Vector2(6, 130)
	platform.size = Vector2(44, 6)
	platform.color = Color(0.4, 0.38, 0.36)
	platform.z_index = 2
	add_child(platform)

	# Pump body - main housing
	var pump_body := ColorRect.new()
	pump_body.position = Vector2(12, 100)
	pump_body.size = Vector2(28, 30)
	pump_body.color = Color(0.5, 0.5, 0.55)
	pump_body.z_index = 3
	add_child(pump_body)

	# Pump body highlight
	var pump_hl := ColorRect.new()
	pump_hl.position = Vector2(14, 102)
	pump_hl.size = Vector2(8, 26)
	pump_hl.color = Color(0.58, 0.58, 0.62)
	pump_hl.z_index = 3
	add_child(pump_hl)

	# Pump top cap
	var pump_cap := ColorRect.new()
	pump_cap.position = Vector2(10, 96)
	pump_cap.size = Vector2(32, 6)
	pump_cap.color = Color(0.42, 0.42, 0.46)
	pump_cap.z_index = 3
	add_child(pump_cap)

	# Pipe extending right
	var pump_pipe := ColorRect.new()
	pump_pipe.position = Vector2(40, 112)
	pump_pipe.size = Vector2(20, 6)
	pump_pipe.color = Color(0.4, 0.4, 0.45)
	pump_pipe.z_index = 3
	add_child(pump_pipe)

	# Pipe joint
	var pipe_joint := ColorRect.new()
	pipe_joint.position = Vector2(38, 110)
	pipe_joint.size = Vector2(6, 10)
	pipe_joint.color = Color(0.45, 0.45, 0.5)
	pipe_joint.z_index = 3
	add_child(pipe_joint)

	# Indicator light
	var pump_light := ColorRect.new()
	pump_light.position = Vector2(20, 104)
	pump_light.size = Vector2(6, 6)
	pump_light.color = Color(0.2, 0.85, 0.3)
	pump_light.z_index = 4
	add_child(pump_light)
	pump_light_ref = pump_light

	# Vines growing on pump housing
	for vi in range(3):
		var vine := Line2D.new()
		vine.width = 1.5
		vine.default_color = Color(0.2, 0.4, 0.15, 0.7)
		var vx: float = 12.0 + vi * 8.0
		vine.add_point(Vector2(vx, 130))
		vine.add_point(Vector2(vx + randf_range(-3, 3), 118))
		vine.add_point(Vector2(vx + randf_range(-4, 4), 106))
		vine.z_index = 4
		add_child(vine)
		# Small leaf on vine
		var vine_leaf := ColorRect.new()
		vine_leaf.size = Vector2(3, 2)
		vine_leaf.position = Vector2(vx + randf_range(-3, 2), randf_range(110, 122))
		vine_leaf.color = Color(0.25, 0.5, 0.18, 0.8)
		vine_leaf.z_index = 4
		add_child(vine_leaf)

	# Gauge (small circle-ish)
	var gauge := ColorRect.new()
	gauge.position = Vector2(28, 110)
	gauge.size = Vector2(8, 8)
	gauge.color = Color(0.15, 0.15, 0.2)
	gauge.z_index = 4
	add_child(gauge)
	var gauge_needle := ColorRect.new()
	gauge_needle.position = Vector2(30, 111.0)
	gauge_needle.size = Vector2(4, 2)
	gauge_needle.color = Color(0.9, 0.3, 0.2)
	gauge_needle.z_index = 4
	add_child(gauge_needle)

	# Label
	var pump_lbl := Label.new()
	pump_lbl.text = "PUMP"
	pump_lbl.add_theme_font_size_override("font_size", 10)
	pump_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 0.8))
	pump_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	pump_lbl.add_theme_constant_override("shadow_offset_x", 1)
	pump_lbl.add_theme_constant_override("shadow_offset_y", 1)
	pump_lbl.position = Vector2(10, 80)
	pump_lbl.z_index = 5
	add_child(pump_lbl)

	# "SELL" indicator
	var sell_lbl := Label.new()
	sell_lbl.text = "SELL"
	sell_lbl.add_theme_font_size_override("font_size", 10)
	sell_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 0.7))
	sell_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	sell_lbl.add_theme_constant_override("shadow_offset_x", 1)
	sell_lbl.add_theme_constant_override("shadow_offset_y", 1)
	sell_lbl.position = Vector2(14, 92)
	sell_lbl.z_index = 5
	add_child(sell_lbl)

	# Detection area for player interaction
	var pump_area := Area2D.new()
	pump_area.collision_layer = 0
	pump_area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 52)
	shape.shape = rect
	shape.position = Vector2(30, 112)
	pump_area.add_child(shape)
	add_child(pump_area)

	pump_area.body_entered.connect(_on_pump_body_entered)
	pump_area.body_exited.connect(_on_pump_body_exited)

func _on_pump_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("set_near_pump"):
		body.set_near_pump(true)
		player_in_pump_area = true
		pump_player_ref = body
		var earned: float = GameManager.sell_water()
		if earned > 0.01 and body.has_method("show_floating_text"):
			body.show_floating_text("+%s" % Economy.format_money(earned), Color(1.0, 0.85, 0.2))

func _on_pump_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("set_near_pump"):
		body.set_near_pump(false)
		player_in_pump_area = false
		pump_player_ref = null

# --- Day/Night Cycle & Animation ---
func _process(delta: float) -> void:
	# Continuous sell while player stands in pump area
	if player_in_pump_area and is_instance_valid(pump_player_ref):
		var earned: float = GameManager.sell_water()
		if earned > 0.01 and pump_player_ref.has_method("show_floating_text"):
			pump_player_ref.show_floating_text("+%s" % Economy.format_money(earned), Color(1.0, 0.85, 0.2))

	cycle_time += delta
	if cycle_time >= CYCLE_DURATION:
		cycle_time -= CYCLE_DURATION
		GameManager.current_day += 1
		GameManager.day_changed.emit(GameManager.current_day)

	var t: float = cycle_time / CYCLE_DURATION
	GameManager.cycle_progress = t
	var tint: Color = _get_cycle_color(t)
	canvas_modulate.color = tint

	# Animate water surface waves
	wave_time += delta
	for i in range(SWAMP_COUNT):
		var fill: float = GameManager.get_swamp_fill_fraction(i)
		if fill > 0.001:
			var geo: Dictionary = _get_swamp_geometry(i)
			var entry_top: Vector2 = geo["entry_top"]
			var basin_left: Vector2 = geo["basin_left"]
			var basin_right: Vector2 = geo["basin_right"]
			var exit_top: Vector2 = geo["exit_top"]
			var basin_y: float = basin_left.y
			var overflow_y: float = maxf(entry_top.y, exit_top.y)
			var water_y: float = basin_y - fill * (basin_y - overflow_y)
			var left_x: float = _lerp_x_at_y(entry_top, basin_left, water_y)
			var right_x: float = _lerp_x_at_y(basin_right, exit_top, water_y)
			_update_water_surface_line(i, left_x, right_x, water_y)
			_update_shimmer_line(i, left_x, right_x, water_y)
		else:
			shimmer_lines[i].clear_points()

	# Drift clouds slowly
	for ci in range(clouds.size()):
		clouds[ci].position.x += delta * (3.0 + ci * 0.5)
		if clouds[ci].position.x > 1960:
			clouds[ci].position.x = -80
			# Also move parent cloud group's other children
			var parent_node: Node2D = clouds[ci].get_parent()
			for child in parent_node.get_children():
				if child != clouds[ci]:
					child.position.x -= 2040

	# Stars: visible at night, twinkle
	var star_alpha: float = 0.0
	if t > 0.65:
		star_alpha = clampf((t - 0.65) / 0.05, 0.0, 1.0)
	elif t < 0.15:
		star_alpha = 1.0
	elif t < 0.2:
		star_alpha = clampf(1.0 - (t - 0.15) / 0.05, 0.0, 1.0)
	for i in range(stars.size()):
		var s: ColorRect = stars[i]
		var twinkle: float = (sin(wave_time * 2.5 + s.position.x * 0.7) + 1.0) * 0.5
		s.color.a = star_alpha * lerpf(0.4, 1.0, twinkle)

	# Fireflies: visible from dusk through night
	var fly_alpha: float = 0.0
	if t > 0.55:
		fly_alpha = clampf((t - 0.55) / 0.05, 0.0, 1.0)
	elif t < 0.15:
		fly_alpha = 1.0
	elif t < 0.2:
		fly_alpha = clampf(1.0 - (t - 0.15) / 0.05, 0.0, 1.0)
	for fd in fireflies:
		var node: ColorRect = fd["node"]
		var px: float = fd["base_x"] + sin(wave_time * fd["speed_x"] + fd["phase_x"]) * fd["amp_x"]
		var py: float = fd["base_y"] + sin(wave_time * fd["speed_y"] + fd["phase_y"]) * fd["amp_y"]
		node.position = Vector2(px, py)
		var glow: float = (sin(wave_time * 1.8 + fd["glow_phase"]) + 1.0) * 0.5
		node.color.a = fly_alpha * lerpf(0.2, 0.9, glow)

	# Leaf particles
	leaf_timer += delta
	if leaf_timer >= 2.0:
		leaf_timer = 0.0
		_spawn_leaf()
	var leaves_to_remove: Array[int] = []
	for i in range(leaves.size()):
		var ld: Dictionary = leaves[i]
		ld["lifetime"] += delta
		if ld["lifetime"] > ld["max_life"]:
			leaves_to_remove.append(i)
			continue
		var node: ColorRect = ld["node"]
		node.position.x += ld["speed"] * delta
		node.position.y = ld["base_y"] + sin(wave_time * 1.2 + ld["wobble_phase"]) * ld["wobble_amp"]
		node.rotation += delta * 0.8
		# Fade near end of life
		var life_frac: float = ld["lifetime"] / ld["max_life"]
		if life_frac > 0.8:
			node.color.a = lerpf(0.7, 0.0, (life_frac - 0.8) / 0.2)
	# Remove dead leaves (reverse order)
	for i in range(leaves_to_remove.size() - 1, -1, -1):
		var idx: int = leaves_to_remove[i]
		leaves[idx]["node"].queue_free()
		leaves.remove_at(idx)

	# Lily pads: bob on water surface
	for lp in lily_pads:
		var swamp_i: int = lp["swamp"]
		var fill: float = GameManager.get_swamp_fill_fraction(swamp_i)
		var node: Node2D = lp["node"]
		if fill < 0.001:
			node.visible = false
			continue
		node.visible = true
		var geo: Dictionary = _get_swamp_geometry(swamp_i)
		var entry_top: Vector2 = geo["entry_top"]
		var basin_left: Vector2 = geo["basin_left"]
		var basin_right: Vector2 = geo["basin_right"]
		var exit_top: Vector2 = geo["exit_top"]
		var basin_y: float = basin_left.y
		var overflow_y: float = maxf(entry_top.y, exit_top.y)
		var water_y: float = basin_y - fill * (basin_y - overflow_y)
		var bob_offset: float = sin(wave_time * 1.5 + lp["phase"]) * 1.0
		node.position = Vector2(lp["x"], water_y + bob_offset)

	# Foam lines at water edges
	for i in range(SWAMP_COUNT):
		var fill: float = GameManager.get_swamp_fill_fraction(i)
		if fill > 0.001:
			var geo: Dictionary = _get_swamp_geometry(i)
			var entry_top: Vector2 = geo["entry_top"]
			var basin_left: Vector2 = geo["basin_left"]
			var basin_right: Vector2 = geo["basin_right"]
			var exit_top: Vector2 = geo["exit_top"]
			var basin_y: float = basin_left.y
			var overflow_y: float = maxf(entry_top.y, exit_top.y)
			var water_y: float = basin_y - fill * (basin_y - overflow_y)
			var left_x: float = _lerp_x_at_y(entry_top, basin_left, water_y)
			var right_x: float = _lerp_x_at_y(basin_right, exit_top, water_y)
			_update_foam_line(i, left_x, right_x, water_y)
		else:
			foam_lines[i].clear_points()

	# Sun arc across sky (sunrise t=0.15 to sunset t=0.70)
	var cam: Camera2D = get_viewport().get_camera_2d() if get_viewport() else null
	var cam_x: float = cam.get_screen_center_position().x if cam else 320.0
	if t >= 0.15 and t <= 0.70:
		var sun_progress: float = (t - 0.15) / 0.55
		sun_node.position.x = cam_x + lerpf(-380.0, 380.0, sun_progress)
		sun_node.position.y = 90.0 - sin(sun_progress * PI) * 110.0
		sun_node.visible = true
		var sun_alpha: float = 1.0
		if sun_progress < 0.1:
			sun_alpha = sun_progress / 0.1
		elif sun_progress > 0.9:
			sun_alpha = (1.0 - sun_progress) / 0.1
		sun_node.modulate.a = sun_alpha
	else:
		sun_node.visible = false

	# Moon arc across sky (moonrise t=0.68 to moonset t=0.17 next day)
	var moon_visible: bool = t >= 0.68 or t <= 0.17
	if moon_visible:
		var moon_progress: float
		if t >= 0.68:
			moon_progress = (t - 0.68) / 0.49
		else:
			moon_progress = (t + 0.32) / 0.49
		moon.position.x = cam_x + lerpf(-380.0, 380.0, moon_progress)
		moon.position.y = 80.0 - sin(moon_progress * PI) * 100.0
		var moon_alpha: float = 1.0
		if moon_progress < 0.1:
			moon_alpha = moon_progress / 0.1
		elif moon_progress > 0.9:
			moon_alpha = (1.0 - moon_progress) / 0.1
		for child in moon.get_children():
			if child is ColorRect:
				child.color.a = moon_alpha * (0.6 if child == moon_glow else 0.9)
	else:
		for child in moon.get_children():
			if child is ColorRect:
				child.color.a = 0.0

	# Pump indicator light pulse
	if pump_light_ref and is_instance_valid(pump_light_ref):
		var pulse: float = (sin(wave_time * 3.0) + 1.0) * 0.5
		if GameManager.pump_owned:
			pump_light_ref.color = Color(0.2, lerpf(0.5, 1.0, pulse), 0.3)
		else:
			pump_light_ref.color = Color(lerpf(0.3, 0.6, pulse), 0.15, 0.1)

	# Swamp gas bubbles
	bubble_timer += delta
	if bubble_timer >= 1.5:
		bubble_timer = 0.0
		var si: int = randi() % SWAMP_COUNT
		_spawn_bubble(si)
	var bubbles_to_remove: Array[int] = []
	for i in range(bubbles.size()):
		var bd: Dictionary = bubbles[i]
		var bnode: ColorRect = bd["node"]
		bnode.position.y -= bd["speed"] * delta
		bnode.position.x += sin(wave_time * 4.0 + bd["wobble_phase"]) * 0.3
		if bnode.position.y <= bd["target_y"]:
			bubbles_to_remove.append(i)
	for i in range(bubbles_to_remove.size() - 1, -1, -1):
		var idx: int = bubbles_to_remove[i]
		bubbles[idx]["node"].queue_free()
		bubbles.remove_at(idx)

	# Dragonflies: visible during daytime
	var df_alpha: float = 0.0
	if t > 0.15 and t < 0.55:
		df_alpha = 1.0
	elif t <= 0.15:
		df_alpha = clampf(t / 0.15, 0.0, 1.0)
	elif t >= 0.55:
		df_alpha = clampf(1.0 - (t - 0.55) / 0.1, 0.0, 1.0)
	for dd in dragonflies:
		var dnode: Node2D = dd["node"]
		var dpx: float = dd["base_x"] + sin(wave_time * dd["speed"] + dd["phase_x"]) * dd["amp_x"]
		var dpy: float = dd["base_y"] + sin(wave_time * dd["speed"] * 0.7 + dd["phase_y"]) * dd["amp_y"]
		dnode.position = Vector2(dpx, dpy)
		dnode.modulate.a = df_alpha
		# Wing flap
		var flap: float = sin(wave_time * 12.0 + dd["phase_x"]) * 0.5
		dd["wing_l"].position.y = -2 + flap
		dd["wing_r"].position.y = -2 - flap

	# Water reflection highlights (daytime)
	var hl_alpha: float = 0.0
	if t > 0.2 and t < 0.55:
		hl_alpha = 1.0
	elif t >= 0.15 and t <= 0.2:
		hl_alpha = (t - 0.15) / 0.05
	elif t >= 0.55 and t <= 0.65:
		hl_alpha = 1.0 - (t - 0.55) / 0.1
	for wh in water_highlights:
		var wh_node: ColorRect = wh["node"]
		var wh_swamp: int = wh["swamp"]
		var wh_fill: float = GameManager.get_swamp_fill_fraction(wh_swamp)
		if wh_fill < 0.01:
			wh_node.visible = false
			continue
		wh_node.visible = true
		var wh_geo: Dictionary = _get_swamp_geometry(wh_swamp)
		var wh_entry: Vector2 = wh_geo["entry_top"]
		var wh_bl: Vector2 = wh_geo["basin_left"]
		var wh_br: Vector2 = wh_geo["basin_right"]
		var wh_exit: Vector2 = wh_geo["exit_top"]
		var wh_basin_y: float = wh_bl.y
		var wh_overflow_y: float = maxf(wh_entry.y, wh_exit.y)
		var wh_water_y: float = wh_basin_y - wh_fill * (wh_basin_y - wh_overflow_y)
		var wh_left_x: float = _lerp_x_at_y(wh_entry, wh_bl, wh_water_y)
		var wh_right_x: float = _lerp_x_at_y(wh_br, wh_exit, wh_water_y)
		var wh_px: float = lerpf(wh_left_x, wh_right_x, wh["offset_x"])
		var shimmer: float = (sin(wave_time * 2.0 + wh["phase"]) + 1.0) * 0.5
		wh_node.position = Vector2(wh_px, wh_water_y + 1)
		wh_node.color.a = hl_alpha * shimmer * 0.25

	# Fog patches: visible at dusk/dawn and night
	var fog_alpha: float = 0.0
	if t > 0.6:
		fog_alpha = clampf((t - 0.6) / 0.1, 0.0, 0.25)
	elif t < 0.2:
		fog_alpha = 0.25
	elif t < 0.25:
		fog_alpha = lerpf(0.25, 0.0, (t - 0.2) / 0.05)
	for fp in fog_patches:
		var fnode: ColorRect = fp["node"]
		fnode.position.x = fp["base_x"] + sin(wave_time * 0.3 + fp["phase"]) * 8.0
		fnode.color.a = fog_alpha * (0.6 + sin(wave_time * 0.5 + fp["phase"]) * 0.4)

	# Pollen motes: daytime only
	var pollen_alpha: float = 0.0
	if t > 0.2 and t < 0.5:
		pollen_alpha = 1.0
	elif t >= 0.15 and t <= 0.2:
		pollen_alpha = (t - 0.15) / 0.05
	elif t >= 0.5 and t <= 0.6:
		pollen_alpha = 1.0 - (t - 0.5) / 0.1
	pollen_timer += delta
	if pollen_timer >= 0.8 and pollen_alpha > 0.1:
		pollen_timer = 0.0
		_spawn_pollen()
	var pollen_to_remove: Array[int] = []
	for i in range(pollen.size()):
		var pd: Dictionary = pollen[i]
		pd["lifetime"] += delta
		if pd["lifetime"] > pd["max_life"]:
			pollen_to_remove.append(i)
			continue
		var pnode: ColorRect = pd["node"]
		pnode.position.x += pd["speed_x"] * delta
		pnode.position.y = pd["base_y"] + sin(wave_time * 0.8 + pd["phase"]) * pd["amp_y"]
		var p_life: float = pd["lifetime"] / pd["max_life"]
		var p_fade: float = 1.0
		if p_life < 0.1:
			p_fade = p_life / 0.1
		elif p_life > 0.8:
			p_fade = (1.0 - p_life) / 0.2
		pnode.color.a = pollen_alpha * p_fade * 0.5
	for i in range(pollen_to_remove.size() - 1, -1, -1):
		var idx: int = pollen_to_remove[i]
		pollen[idx]["node"].queue_free()
		pollen.remove_at(idx)

	# Birds
	bird_timer += delta
	if bird_timer >= 8.0:
		bird_timer = 0.0
		_spawn_bird()
	var birds_to_remove: Array[int] = []
	for i in range(birds.size()):
		var brd: Dictionary = birds[i]
		var bnode: Node2D = brd["node"]
		bnode.position.x += brd["speed"] * delta
		bnode.position.y += brd["y_drift"] * delta
		# Wing flap animation
		var flap_angle: float = sin(wave_time * brd["flap_speed"]) * 3.0
		brd["wing_l"].points[0].y = 2 + flap_angle
		brd["wing_r"].points[1].y = 2 + flap_angle
		if bnode.position.x > 2000:
			birds_to_remove.append(i)
	for i in range(birds_to_remove.size() - 1, -1, -1):
		var idx: int = birds_to_remove[i]
		birds[idx]["node"].queue_free()
		birds.remove_at(idx)

	# Cattail wind sway
	for ct in cattails:
		if is_instance_valid(ct):
			var sway: float = sin(wave_time * 1.2 + ct.position.x * 0.05) * 0.04
			ct.rotation = sway

func _get_cycle_color(t: float) -> Color:
	var dawn := Color(1.0, 0.82, 0.65)
	var noon := Color(1.0, 1.0, 1.0)
	var dusk := Color(1.0, 0.7, 0.55)
	var night := Color(0.3, 0.35, 0.6)

	if t < 0.15:
		return night.lerp(dawn, t / 0.15)
	elif t < 0.3:
		return dawn.lerp(noon, (t - 0.15) / 0.15)
	elif t < 0.5:
		return noon
	elif t < 0.6:
		return noon.lerp(dusk, (t - 0.5) / 0.1)
	elif t < 0.7:
		return dusk.lerp(night, (t - 0.6) / 0.1)
	else:
		return night
