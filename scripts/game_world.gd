extends Node2D

# Day/Night cycle - 5 minute real-time cycle (300 seconds)
const CYCLE_DURATION: float = 300.0

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
var cycle_time: float = 0.0

# Terrain: array of Vector2 points defining the ground surface
# Pattern per swamp: entry_slope_top, basin_left, basin_right, exit_slope_top
# Plus initial left shore and final right shore
var terrain_points: Array[Vector2] = [
	Vector2(0, 136), Vector2(80, 136),              # Left shore (pump area)
	Vector2(108, 160), Vector2(178, 164),            # Puddle: gentle entry, tilted floor (+4)
	Vector2(214, 146), Vector2(278, 158),            # Ridge 1 (lower, slopes down)
	Vector2(338, 206), Vector2(462, 212),            # Pond: wide, slight tilt (+6)
	Vector2(538, 184), Vector2(598, 198),            # Ridge 2 (lower)
	Vector2(682, 250), Vector2(828, 258),            # Marsh: wide, tilt (+8)
	Vector2(908, 232), Vector2(958, 250),            # Ridge 3 (lower)
	Vector2(1048, 306), Vector2(1215, 316),          # Bog: wide, tilt (+10)
	Vector2(1308, 286), Vector2(1358, 306),          # Ridge 4 (lower)
	Vector2(1468, 360), Vector2(1685, 372),          # Deep Swamp: very wide, tilt (+12)
	Vector2(1775, 344), Vector2(1920, 362),          # Right shore (much lower)
]

# Swamp geometry indices: swamp i -> terrain_points indices
const SWAMP_COUNT: int = 5
const WATER_SHADER = preload("res://shaders/water.gdshader")
const POST_PROCESS_SHADER = preload("res://shaders/post_process.gdshader")

# Visual nodes created procedurally
var water_polygons: Array[Polygon2D] = []
var water_surface_lines: Array[Line2D] = []
var terrain_polygon: Polygon2D = null
var terrain_body: StaticBody2D = null
var water_detect_areas: Array[Area2D] = []
var water_walls: Array = []
var swamp_labels: Array[Label] = []
var swamp_percent_labels: Array[Label] = []
var clouds: Array[Node2D] = []
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
var camels: Array[Dictionary] = []

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
var fish: Array[Dictionary] = []
var frogs: Array[Dictionary] = []
var glow_plants: Array[Dictionary] = []
var seaweed: Array[Dictionary] = []
var ripples: Array[Dictionary] = []
var ripple_timer: float = 0.0
var butterflies: Array[Dictionary] = []
var butterfly_timer: float = 0.0
var shooting_stars: Array[Dictionary] = []
var shooting_star_timer: float = 0.0
var turtles: Array[Dictionary] = []
var tadpoles: Array[Dictionary] = []

# Shader effects
var post_process_layer: CanvasLayer = null
var post_process_rect: ColorRect = null
var water_glow_lines: Array[Line2D] = []

# Parallax layers
var parallax_bg: ParallaxBackground = null
var sky_layer: ParallaxLayer = null
var far_hills_layer: ParallaxLayer = null
var near_hills_layer: ParallaxLayer = null
var treeline_layer: ParallaxLayer = null

# Weather system
var weather_state: String = "clear"
var weather_timer: float = 0.0
var weather_duration: float = 90.0
var lightning_timer: float = 20.0
var rain_layer: CanvasLayer = null
var rain_particles: CPUParticles2D = null
var lightning_rect: ColorRect = null

# Enhanced vegetation
var ferns_list: Array[Node2D] = []
var wind_direction: float = 1.0
var wind_timer: float = 0.0

# Drain-revealed objects per swamp
var drain_reveals: Array[Array] = []

# Growing vegetation on drained land (Phase 15b)
var grown_plants: Array[Dictionary] = []
var last_drain_thresholds: Array[float] = []

# Atmosphere effects (Phase 17)
var pump_steam_particles: Array[Dictionary] = []
var morning_mist_rects: Array[ColorRect] = []
var aurora_lines: Array[Dictionary] = []
var aurora_active: bool = false
var aurora_timer: float = 0.0
var aurora_fade: float = 0.0
var owl_node: Node2D = null
var owl_blink_timer: float = 4.0

# Dynamic shadows (Phase 13c)
var player_shadow: ColorRect = null

# Pump station glow (Phase 11b)
var pump_glow_rect: ColorRect = null

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

# Per-pool water colors — distinct identity per pool
const SWAMP_WATER_COLORS: Array[Color] = [
	Color(0.30, 0.55, 0.60, 0.70),  # Puddle: crystal clear light aqua
	Color(0.18, 0.42, 0.22, 0.88),  # Pond: classic pastoral green
	Color(0.30, 0.28, 0.15, 0.92),  # Marsh: murky brown-olive
	Color(0.12, 0.10, 0.08, 0.95),  # Bog: dark peaty brown-black
	Color(0.08, 0.12, 0.20, 0.97),  # Deep Swamp: inky dark blue
]
const SWAMP_WATER_EMPTY_COLORS: Array[Color] = [
	Color(0.45, 0.65, 0.68, 0.45),  # Puddle: pale aqua
	Color(0.30, 0.52, 0.32, 0.55),  # Pond: faded green
	Color(0.40, 0.38, 0.25, 0.60),  # Marsh: dried mud
	Color(0.22, 0.18, 0.14, 0.65),  # Bog: dark peat residue
	Color(0.15, 0.18, 0.28, 0.68),  # Deep Swamp: dark slate
]
const SWAMP_DEPTH_COLORS: Array[Color] = [
	Color(0.15, 0.35, 0.38, 0.40),  # Puddle: light teal depth
	Color(0.06, 0.22, 0.08, 0.55),  # Pond: forest green depth
	Color(0.18, 0.14, 0.06, 0.65),  # Marsh: mud brown depth
	Color(0.05, 0.04, 0.03, 0.75),  # Bog: near-black depth
	Color(0.03, 0.05, 0.12, 0.80),  # Deep Swamp: dark navy depth
]
# Per-pool shader parameters: [wave_strength, specular, choppiness, turbidity, foam_density]
const POOL_SHADER_PARAMS: Array[Array] = [
	[0.5, 0.4, 0.0, 0.0, 0.3],     # Puddle: calm, clear, minimal foam
	[1.2, 0.3, 0.3, 0.15, 0.8],    # Pond: gentle waves, some sheen
	[1.5, 0.15, 0.8, 0.5, 1.2],    # Marsh: choppy, murky
	[1.8, 0.1, 1.2, 0.7, 1.5],     # Bog: rough, opaque
	[2.5, 0.08, 2.0, 0.85, 2.0],   # Deep Swamp: wild, very murky
]
# Per-pool foam colors
const POOL_FOAM_COLORS: Array[Color] = [
	Color(0.95, 0.97, 1.0, 0.35),   # Puddle: clean white
	Color(0.85, 0.92, 0.85, 0.30),  # Pond: green-white
	Color(0.65, 0.58, 0.42, 0.28),  # Marsh: brownish foam
	Color(0.45, 0.38, 0.28, 0.25),  # Bog: dark brown foam
	Color(0.30, 0.35, 0.48, 0.22),  # Deep Swamp: dark bluish foam
]
# Per-pool wave params: [amplitude, frequency]
const POOL_WAVE_PARAMS: Array[Array] = [
	[0.5, 3.0],   # Puddle: small/fast ripples
	[1.0, 2.2],   # Pond: moderate
	[1.6, 1.5],   # Marsh: medium/slower
	[2.2, 1.1],   # Bog: large/slow
	[3.0, 0.8],   # Deep Swamp: large/very slow
]
# Per-pool bowl depth for rounded basin shape
const POOL_BOWL_DEPTHS: Array[float] = [1.0, 2.0, 3.0, 4.0, 5.0]
const GRASS_COLOR := Color(0.25, 0.48, 0.15)
const GRASS_LIGHT_COLOR := Color(0.35, 0.58, 0.2)
const ROCK_COLOR := Color(0.42, 0.4, 0.38)
const ROCK_DARK_COLOR := Color(0.32, 0.3, 0.28)

var wave_time: float = 0.0

func _ready() -> void:
	cycle_time = CYCLE_DURATION * 0.2
	_build_parallax()
	_build_sky()
	_build_sun()
	_build_clouds()
	_build_distant_hills()
	_build_treeline()
	_build_terrain()
	_build_terrain_details()
	_build_terrain_zones()
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
	_build_fish()
	_build_frogs()
	_build_glow_plants()
	_build_seaweed()
	_build_turtles()
	_build_tadpoles()
	_build_pool_features()
	_build_left_boundary()
	_build_right_boundary()
	_build_post_processing()
	_build_weather()
	_build_drain_reveals()
	_build_atmosphere()
	_build_player_shadow()
	_init_drain_thresholds()

	GameManager.water_level_changed.connect(_on_water_level_changed)
	GameManager.swamp_completed.connect(_on_swamp_completed)
	GameManager.camel_changed.connect(_on_camel_changed)
	_build_camels()

# --- Parallax ---
func _build_parallax() -> void:
	parallax_bg = ParallaxBackground.new()
	add_child(parallax_bg)
	sky_layer = ParallaxLayer.new()
	sky_layer.motion_scale = Vector2(0, 0)
	parallax_bg.add_child(sky_layer)
	far_hills_layer = ParallaxLayer.new()
	far_hills_layer.motion_scale = Vector2(0.1, 0)
	parallax_bg.add_child(far_hills_layer)
	near_hills_layer = ParallaxLayer.new()
	near_hills_layer.motion_scale = Vector2(0.3, 0)
	parallax_bg.add_child(near_hills_layer)
	treeline_layer = ParallaxLayer.new()
	treeline_layer.motion_scale = Vector2(0.6, 0)
	parallax_bg.add_child(treeline_layer)

# --- Sky & Atmosphere ---
func _build_sky() -> void:
	# Three-band sky gradient
	var sky_top := ColorRect.new()
	sky_top.position = Vector2(-100, -80)
	sky_top.size = Vector2(2120, 100)
	sky_top.color = SKY_COLOR_TOP
	sky_top.z_index = -12
	sky_layer.add_child(sky_top)

	var sky_mid := ColorRect.new()
	sky_mid.position = Vector2(-100, 20)
	sky_mid.size = Vector2(2120, 80)
	sky_mid.color = SKY_COLOR_MID
	sky_mid.z_index = -12
	sky_layer.add_child(sky_mid)

	var sky_bot := ColorRect.new()
	sky_bot.position = Vector2(-100, 96)
	sky_bot.size = Vector2(2120, 100)
	sky_bot.color = SKY_COLOR_BOTTOM
	sky_bot.z_index = -12
	sky_layer.add_child(sky_bot)

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
		cloud_group.position = Vector2(cd["x"], cd["y"])
		add_child(cloud_group)

		# Main cloud body (local coords relative to group)
		var main := ColorRect.new()
		main.size = Vector2(cd["w"], cd["h"])
		main.color = Color(0.92, 0.94, 0.98, 0.7)
		cloud_group.add_child(main)

		# Cloud puff left
		var puff_l := ColorRect.new()
		puff_l.position = Vector2(-8, 4)
		puff_l.size = Vector2(16, cd["h"] - 4)
		puff_l.color = Color(0.88, 0.92, 0.96, 0.5)
		cloud_group.add_child(puff_l)

		# Cloud puff right
		var puff_r := ColorRect.new()
		puff_r.position = Vector2(cd["w"] - 8, 4)
		puff_r.size = Vector2(16, cd["h"] - 4)
		puff_r.color = Color(0.88, 0.92, 0.96, 0.5)
		cloud_group.add_child(puff_r)

		# Cloud highlight top
		var highlight := ColorRect.new()
		highlight.position = Vector2(6, -4)
		highlight.size = Vector2(cd["w"] - 12, 6)
		highlight.color = Color(0.96, 0.97, 1.0, 0.5)
		cloud_group.add_child(highlight)

		clouds.append(cloud_group)

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
	far_hills_layer.add_child(hills)

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
	near_hills_layer.add_child(hills2)

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
	treeline_layer.add_child(treeline)

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
	treeline_layer.add_child(treeline2)

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

	# Dithered transition at grass-to-dirt boundary (Phase 18a)
	for pt_idx in range(0, terrain_points.size() - 1, 2):
		var tp: Vector2 = terrain_points[pt_idx]
		for dx in range(0, 4):
			for dy in range(0, 3):
				if (dx + dy) % 2 == 0:
					var dither := ColorRect.new()
					dither.size = Vector2(1, 1)
					dither.position = Vector2(tp.x + dx, tp.y + 3 + dy)
					dither.color = GRASS_COLOR.lerp(GROUND_COLOR, float(dy) / 3.0)
					dither.color.a = 0.5
					dither.z_index = 1
					add_child(dither)

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
		Vector2(220, 138), Vector2(245, 148),
		Vector2(545, 162), Vector2(580, 170),
		Vector2(912, 190), Vector2(948, 206),
		Vector2(1316, 224), Vector2(1348, 242),
		Vector2(1790, 274), Vector2(1880, 288),
	]
	for rp in rock_positions:
		_place_rock(rp, randf_range(4, 10), randf_range(4, 8))

	# Dirt specks on terrain surface (zone-tinted)
	for i in range(60):
		var rx: float = randf_range(0, 1920)
		var ry: float = _get_terrain_y_at(rx)
		if ry > 0:
			var speck := ColorRect.new()
			speck.position = Vector2(rx, ry + randf_range(2, 12))
			speck.size = Vector2(randf_range(2, 6), randf_range(2, 4))
			var base_col: Color = GROUND_DARK_COLOR.lerp(GROUND_COLOR, randf_range(0, 1))
			var zone_col: Color = ZONE_TINT_COLORS[_get_zone_index(rx)]
			speck.color = base_col.lerp(zone_col, 0.3)
			speck.color.a = randf_range(0.3, 0.6)
			speck.z_index = 0
			add_child(speck)

	# Soil strata lines - horizontal bands of slightly different color
	for i in range(25):
		var rx: float = randf_range(0, 1800)
		var ry: float = _get_terrain_y_at(rx)
		if ry > 0:
			var stratum := ColorRect.new()
			var depth: float = randf_range(14, 50)
			stratum.position = Vector2(rx, ry + depth)
			stratum.size = Vector2(randf_range(20, 80), randf_range(1, 3))
			var shade: float = randf_range(0.0, 0.3)
			stratum.color = Color(0.35 + shade * 0.1, 0.22 + shade * 0.1, 0.08 + shade * 0.06, randf_range(0.2, 0.4))
			stratum.z_index = 0
			add_child(stratum)

	# Small pebbles embedded in dirt
	for i in range(35):
		var rx: float = randf_range(0, 1920)
		var ry: float = _get_terrain_y_at(rx)
		if ry > 0:
			var pebble := ColorRect.new()
			pebble.position = Vector2(rx, ry + randf_range(1, 8))
			var sz: float = randf_range(2, 4)
			pebble.size = Vector2(sz, sz * randf_range(0.6, 1.0))
			pebble.color = ROCK_COLOR.lerp(ROCK_DARK_COLOR, randf())
			pebble.color.a = randf_range(0.5, 0.8)
			pebble.z_index = 0
			add_child(pebble)

	# Root-like dark lines near surface
	for i in range(18):
		var rx: float = randf_range(0, 1900)
		var ry: float = _get_terrain_y_at(rx)
		if ry > 0:
			var root := Line2D.new()
			root.width = randf_range(1.0, 2.0)
			root.default_color = Color(0.22, 0.14, 0.06, randf_range(0.25, 0.5))
			root.z_index = 0
			var segments: int = randi_range(3, 6)
			var px: float = rx
			var py: float = ry + randf_range(4, 16)
			for j in range(segments):
				root.add_point(Vector2(px, py))
				px += randf_range(6, 18)
				py += randf_range(-3, 5)
			add_child(root)

	# Dark dirt patches (clay/humus areas)
	for i in range(12):
		var rx: float = randf_range(0, 1900)
		var ry: float = _get_terrain_y_at(rx)
		if ry > 0:
			var patch := ColorRect.new()
			patch.position = Vector2(rx, ry + randf_range(6, 30))
			patch.size = Vector2(randf_range(12, 40), randf_range(6, 16))
			patch.color = Color(0.3, 0.18, 0.06, randf_range(0.15, 0.3))
			patch.z_index = 0
			add_child(patch)

	# Sandy/lighter patches on ridges
	for i in range(10):
		var rx: float = randf_range(0, 1900)
		var ry: float = _get_terrain_y_at(rx)
		if ry > 0:
			var sandy := ColorRect.new()
			sandy.position = Vector2(rx, ry + randf_range(1, 6))
			sandy.size = Vector2(randf_range(8, 24), randf_range(3, 8))
			sandy.color = Color(0.55, 0.42, 0.25, randf_range(0.15, 0.3))
			sandy.z_index = 0
			add_child(sandy)

	# Small worm holes / burrows
	for i in range(8):
		var rx: float = randf_range(50, 1880)
		var ry: float = _get_terrain_y_at(rx)
		if ry > 0:
			var hole := ColorRect.new()
			hole.position = Vector2(rx, ry + randf_range(1, 4))
			hole.size = Vector2(3, 3)
			hole.color = Color(0.15, 0.08, 0.02, 0.5)
			hole.z_index = 0
			add_child(hole)

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

# Zone palette for terrain: left (sandy) to right (dark)
const ZONE_TINT_COLORS: Array[Color] = [
	Color(0.65, 0.55, 0.35, 0.18),  # Zone 0 (Puddle): warm sandy tan
	Color(0.50, 0.38, 0.22, 0.20),  # Zone 1 (Pond): earthy medium brown
	Color(0.38, 0.28, 0.14, 0.22),  # Zone 2 (Marsh): dark muddy brown
	Color(0.25, 0.18, 0.10, 0.25),  # Zone 3 (Bog): very dark peaty brown
	Color(0.12, 0.10, 0.08, 0.28),  # Zone 4 (Deep Swamp): nearly black
]

func _get_zone_index(x: float) -> int:
	# Zone boundaries at midpoints between pools
	# Pool centers: ~143(Puddle), ~400(Pond), ~755(Marsh), ~1131(Bog), ~1576(Deep Swamp)
	var zone_boundaries: Array[float] = [270.0, 570.0, 940.0, 1360.0]
	for i in range(zone_boundaries.size()):
		if x < zone_boundaries[i]:
			return i
	return 4

func _build_terrain_zones() -> void:
	# Zone tinting via small patches buried well below terrain surface
	# to avoid peeking above slopes into the sky
	var zone_centers: Array[float] = [135.0, 400.0, 755.0, 1130.0, 1575.0]
	var zone_radii: Array[float] = [180.0, 200.0, 220.0, 250.0, 280.0]

	for zi in range(5):
		var center_x: float = zone_centers[zi]
		var radius: float = zone_radii[zi]
		var col: Color = ZONE_TINT_COLORS[zi]
		# Scatter small tinted patches well below terrain surface
		for _j in range(25):
			var px: float = center_x + randf_range(-radius, radius)
			px = clampf(px, 0.0, 1920.0)
			var py: float = _get_terrain_y_at(px)
			if py < 0:
				continue
			var dist_frac: float = absf(px - center_x) / radius
			var alpha: float = col.a * (1.0 - dist_frac * dist_frac)
			if alpha < 0.02:
				continue
			var patch := ColorRect.new()
			var pw: float = randf_range(12, 30)
			var ph: float = randf_range(8, 20)
			# Push patches well below surface so they never peek above on slopes
			patch.position = Vector2(px - pw * 0.5, py + randf_range(10, 25))
			patch.size = Vector2(pw, ph)
			patch.color = Color(col.r, col.g, col.b, alpha)
			patch.z_index = 0
			add_child(patch)

	# Ridge crack details between pools
	_build_ridge_details()
	# Basin slope erosion marks
	_build_slope_erosion()

func _build_ridge_details() -> void:
	# Ridges are between pools: indices 4-5, 8-9, 12-13, 16-17 in terrain_points
	var ridge_indices: Array[int] = [4, 8, 12, 16]
	for ri in ridge_indices:
		if ri + 1 >= terrain_points.size():
			continue
		var ridge_left: Vector2 = terrain_points[ri]
		var ridge_right: Vector2 = terrain_points[ri + 1]
		var ridge_mid_x: float = (ridge_left.x + ridge_right.x) * 0.5
		var ridge_w: float = ridge_right.x - ridge_left.x

		# 3-5 short cracks on the ridge
		for _j in range(randi_range(3, 5)):
			var crack := Line2D.new()
			crack.width = 1.0
			crack.default_color = Color(0.58, 0.50, 0.38, randf_range(0.2, 0.4))
			crack.z_index = 1
			var cx: float = randf_range(ridge_left.x + 4, ridge_right.x - 4)
			var cy: float = _get_terrain_y_at(cx)
			if cy < 0:
				continue
			cy += randf_range(1, 4)
			crack.add_point(Vector2(cx, cy))
			crack.add_point(Vector2(cx + randf_range(-6, 6), cy + randf_range(3, 8)))
			add_child(crack)

		# 1-2 dry patches on the ridge
		for _j in range(randi_range(1, 2)):
			var dry := ColorRect.new()
			var dx: float = randf_range(ridge_left.x + 2, ridge_right.x - 8)
			var dy: float = _get_terrain_y_at(dx)
			if dy < 0:
				continue
			dry.position = Vector2(dx, dy + randf_range(1, 3))
			dry.size = Vector2(randf_range(6, 14), randf_range(3, 5))
			dry.color = Color(0.58, 0.48, 0.32, randf_range(0.15, 0.25))
			dry.z_index = 1
			add_child(dry)

func _build_slope_erosion() -> void:
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var entry_top: Vector2 = geo["entry_top"]
		var basin_left: Vector2 = geo["basin_left"]
		var basin_right: Vector2 = geo["basin_right"]
		var exit_top: Vector2 = geo["exit_top"]

		# Entry slope erosion grooves
		for _j in range(randi_range(2, 3)):
			var erosion := Line2D.new()
			erosion.width = 1.0
			erosion.default_color = Color(0.30, 0.20, 0.10, randf_range(0.2, 0.35))
			erosion.z_index = 1
			var offset: float = randf_range(3, 8)
			var t1: float = randf_range(0.1, 0.3)
			var t2: float = randf_range(0.7, 0.9)
			erosion.add_point(Vector2(
				lerpf(entry_top.x, basin_left.x, t1),
				lerpf(entry_top.y, basin_left.y, t1) + offset
			))
			erosion.add_point(Vector2(
				lerpf(entry_top.x, basin_left.x, t2),
				lerpf(entry_top.y, basin_left.y, t2) + offset
			))
			add_child(erosion)

		# Exit slope erosion grooves
		for _j in range(randi_range(2, 3)):
			var erosion := Line2D.new()
			erosion.width = 1.0
			erosion.default_color = Color(0.30, 0.20, 0.10, randf_range(0.2, 0.35))
			erosion.z_index = 1
			var offset: float = randf_range(3, 8)
			var t1: float = randf_range(0.1, 0.3)
			var t2: float = randf_range(0.7, 0.9)
			erosion.add_point(Vector2(
				lerpf(basin_right.x, exit_top.x, t1),
				lerpf(basin_right.y, exit_top.y, t1) + offset
			))
			erosion.add_point(Vector2(
				lerpf(basin_right.x, exit_top.x, t2),
				lerpf(basin_right.y, exit_top.y, t2) + offset
			))
			add_child(erosion)

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
		# Additive glow pool under each firefly
		var glow := ColorRect.new()
		glow.size = Vector2(8, 6)
		glow.position = Vector2(-3, -2)
		glow.color = Color(0.9, 1.0, 0.4, 0.0)
		glow.z_index = 5
		var glow_mat := CanvasItemMaterial.new()
		glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = glow_mat
		fly.add_child(glow)
		fireflies.append({
			"node": fly,
			"glow": glow,
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
		treeline_layer.add_child(trunk)

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
		dp.color = SWAMP_DEPTH_COLORS[i]
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
	var basin_y: float = maxf(basin_left.y, basin_right.y)
	var overflow_y: float = maxf(entry_top.y, exit_top.y)
	var water_y: float = basin_y - fill * (basin_y - overflow_y)
	# Depth zone covers bottom 60% of water
	var depth_y: float = lerpf(water_y, basin_y, 0.4)
	var left_x: float = _lerp_x_at_y(entry_top, basin_left, depth_y)
	var right_x: float = _lerp_x_at_y(basin_right, exit_top, depth_y)
	depth_polygons[swamp_index].polygon = PackedVector2Array([
		Vector2(left_x, depth_y),
		Vector2(basin_left.x, basin_left.y),
		Vector2(basin_right.x, basin_right.y),
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
	ferns_list.append(fern)
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
	var base_foam: Color = POOL_FOAM_COLORS[swamp_index]
	var alpha: float = lerpf(base_foam.a * 0.5, base_foam.a, (sin(wave_time * 1.2) + 1.0) * 0.5)
	line.default_color = Color(base_foam.r, base_foam.g, base_foam.b, alpha)

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

func _spawn_ripple(rx: float, ry: float) -> void:
	var rp_line := Line2D.new()
	rp_line.width = 1.5
	rp_line.default_color = Color(0.6, 0.8, 0.7, 0.4)
	rp_line.z_index = 4
	add_child(rp_line)
	ripples.append({
		"node": rp_line,
		"x": rx,
		"y": ry,
		"max_radius": randf_range(6, 14),
		"lifetime": 0.0,
		"max_life": randf_range(1.5, 3.0),
	})

func _spawn_butterfly() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d() if get_viewport() else null
	var cam_x: float = cam.get_screen_center_position().x if cam else 320.0
	var bf_node := Node2D.new()
	bf_node.z_index = 6
	add_child(bf_node)
	# Body
	var bf_body := ColorRect.new()
	bf_body.size = Vector2(2, 4)
	bf_body.position = Vector2(-1, -2)
	bf_body.color = Color(0.15, 0.12, 0.08)
	bf_node.add_child(bf_body)
	# Wings - pick a random color scheme
	var wing_colors: Array[Color] = [
		Color(0.95, 0.6, 0.15, 0.9),   # Orange monarch
		Color(0.3, 0.5, 0.95, 0.9),    # Blue morpho
		Color(0.95, 0.95, 0.4, 0.9),   # Yellow swallowtail
		Color(0.9, 0.3, 0.5, 0.9),     # Pink
		Color(0.95, 0.4, 0.2, 0.9),    # Red admiral
	]
	var wing_color: Color = wing_colors[randi() % wing_colors.size()]
	# Left wing
	var wing_l := ColorRect.new()
	wing_l.size = Vector2(5, 4)
	wing_l.position = Vector2(-6, -3)
	wing_l.color = wing_color
	wing_l.pivot_offset = Vector2(5, 2)
	bf_node.add_child(wing_l)
	# Right wing
	var wing_r := ColorRect.new()
	wing_r.size = Vector2(5, 4)
	wing_r.position = Vector2(1, -3)
	wing_r.color = wing_color
	wing_r.pivot_offset = Vector2(0, 2)
	bf_node.add_child(wing_r)
	# Wing spots
	var spot_l := ColorRect.new()
	spot_l.size = Vector2(2, 2)
	spot_l.position = Vector2(-4, -2)
	spot_l.color = wing_color.darkened(0.3)
	bf_node.add_child(spot_l)
	var spot_r := ColorRect.new()
	spot_r.size = Vector2(2, 2)
	spot_r.position = Vector2(2, -2)
	spot_r.color = wing_color.darkened(0.3)
	bf_node.add_child(spot_r)
	# Antennae
	var ant_l := ColorRect.new()
	ant_l.size = Vector2(1, 3)
	ant_l.position = Vector2(-2, -5)
	ant_l.color = Color(0.2, 0.15, 0.1, 0.7)
	bf_node.add_child(ant_l)
	var ant_r := ColorRect.new()
	ant_r.size = Vector2(1, 3)
	ant_r.position = Vector2(1, -5)
	ant_r.color = Color(0.2, 0.15, 0.1, 0.7)
	bf_node.add_child(ant_r)

	var bx: float = cam_x + randf_range(-350, 350)
	var by: float = randf_range(20, 105)
	bf_node.position = Vector2(bx, by)
	butterflies.append({
		"node": bf_node,
		"wing_l": wing_l,
		"wing_r": wing_r,
		"phase": randf() * TAU,
		"flutter_speed": randf_range(6.0, 10.0),
		"drift_x": randf_range(-15, 15),
		"bob_amp": randf_range(5, 12),
		"base_y": by,
		"lifetime": 0.0,
		"max_life": randf_range(8, 18),
	})

func _spawn_shooting_star() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d() if get_viewport() else null
	var cam_x: float = cam.get_screen_center_position().x if cam else 320.0
	var ss_node := Node2D.new()
	ss_node.z_index = -9
	add_child(ss_node)
	# Bright head
	var ss_head := ColorRect.new()
	ss_head.size = Vector2(3, 3)
	ss_head.color = Color(1.0, 1.0, 0.9, 0.9)
	ss_node.add_child(ss_head)
	# Trail line
	var ss_line := Line2D.new()
	ss_line.width = 2.0
	ss_line.default_color = Color(0.8, 0.85, 1.0, 0.6)
	ss_node.add_child(ss_line)

	var start_x: float = cam_x + randf_range(-300, 100)
	var start_y: float = randf_range(-40, 30)
	shooting_stars.append({
		"node": ss_node,
		"head": ss_head,
		"line": ss_line,
		"start_x": start_x,
		"start_y": start_y,
		"speed_x": randf_range(200, 400),
		"speed_y": randf_range(30, 80),
		"lifetime": 0.0,
		"max_life": randf_range(0.6, 1.2),
	})

# --- Fish ---
func _build_fish() -> void:
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var basin_left: Vector2 = geo["basin_left"]
		var basin_right: Vector2 = geo["basin_right"]
		var basin_w: float = basin_right.x - basin_left.x
		var count: int = clampi(int(basin_w / 40.0), 1, 5)
		for j in range(count):
			var fish_node := Node2D.new()
			fish_node.z_index = 4
			add_child(fish_node)
			# Fish body
			var body := ColorRect.new()
			body.size = Vector2(6, 3)
			body.position = Vector2(-3, -1.5)
			var fish_hue: float = randf_range(0.05, 0.15)
			body.color = Color.from_hsv(fish_hue, 0.6, 0.7, 0.9)
			fish_node.add_child(body)
			# Tail
			var tail := ColorRect.new()
			tail.size = Vector2(3, 4)
			tail.position = Vector2(-6, -2)
			tail.color = Color.from_hsv(fish_hue, 0.5, 0.6, 0.85)
			fish_node.add_child(tail)
			# Eye
			var eye := ColorRect.new()
			eye.size = Vector2(1, 1)
			eye.position = Vector2(1, -1)
			eye.color = Color(0.1, 0.1, 0.1)
			fish_node.add_child(eye)
			# Belly highlight
			var belly := ColorRect.new()
			belly.size = Vector2(4, 1)
			belly.position = Vector2(-2, 0.5)
			belly.color = Color(0.9, 0.85, 0.7, 0.5)
			fish_node.add_child(belly)

			var fx: float = basin_left.x + randf_range(12, basin_w - 12)
			fish.append({
				"node": fish_node,
				"swamp": i,
				"x": fx,
				"swim_phase": randf() * TAU,
				"swim_speed": randf_range(0.6, 1.4),
				"swim_range": randf_range(15, 35),
				"depth_offset": randf_range(0.3, 0.7),
				"direction": 1.0 if randf() > 0.5 else -1.0,
				"alive": true,
				"death_timer": 0.0,
				"jump_timer": randf_range(12.0, 35.0),
				"jumping": false,
				"jump_time": 0.0,
			})

# --- Frogs ---
func _build_frogs() -> void:
	var placed: int = 0
	for lp in lily_pads:
		if placed >= 8:
			break
		if randf() < 0.4:
			continue
		var pad_node: Node2D = lp["node"]
		var frog_node := Node2D.new()
		frog_node.z_index = 5
		pad_node.add_child(frog_node)
		# Body
		var body := ColorRect.new()
		body.size = Vector2(5, 4)
		body.position = Vector2(-2.5, -6)
		body.color = Color(0.2, 0.5, 0.15, 0.95)
		frog_node.add_child(body)
		# Head
		var head := ColorRect.new()
		head.size = Vector2(4, 3)
		head.position = Vector2(-2, -9)
		head.color = Color(0.25, 0.55, 0.18, 0.95)
		frog_node.add_child(head)
		# Left eye
		var eye_l := ColorRect.new()
		eye_l.size = Vector2(2, 2)
		eye_l.position = Vector2(-2, -11)
		eye_l.color = Color(0.8, 0.75, 0.1)
		frog_node.add_child(eye_l)
		# Right eye
		var eye_r := ColorRect.new()
		eye_r.size = Vector2(2, 2)
		eye_r.position = Vector2(1, -11)
		eye_r.color = Color(0.8, 0.75, 0.1)
		frog_node.add_child(eye_r)
		# Eye pupils
		var pupil_l := ColorRect.new()
		pupil_l.size = Vector2(1, 1)
		pupil_l.position = Vector2(-1, -10)
		pupil_l.color = Color(0.05, 0.05, 0.05)
		frog_node.add_child(pupil_l)
		var pupil_r := ColorRect.new()
		pupil_r.size = Vector2(1, 1)
		pupil_r.position = Vector2(2, -10)
		pupil_r.color = Color(0.05, 0.05, 0.05)
		frog_node.add_child(pupil_r)
		# Belly
		var belly := ColorRect.new()
		belly.size = Vector2(3, 2)
		belly.position = Vector2(-1.5, -4)
		belly.color = Color(0.55, 0.7, 0.35, 0.7)
		frog_node.add_child(belly)

		frogs.append({
			"node": frog_node,
			"swamp": lp["swamp"],
			"hop_timer": randf_range(3.0, 10.0),
			"hopping": false,
			"hop_progress": 0.0,
			"base_y": 0.0,
			"eye_l": eye_l,
			"eye_r": eye_r,
			"blink_timer": randf_range(2.0, 6.0),
		})
		placed += 1

# --- Bioluminescent Plants ---
func _build_glow_plants() -> void:
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var entry_top: Vector2 = geo["entry_top"]
		var basin_left: Vector2 = geo["basin_left"]
		var basin_right: Vector2 = geo["basin_right"]
		var exit_top: Vector2 = geo["exit_top"]
		# Place 2-3 glow plants per swamp near water edges
		var positions: Array[Vector2] = [
			Vector2(entry_top.x + randf_range(2, 12), entry_top.y),
			Vector2(exit_top.x + randf_range(-12, -2), exit_top.y),
		]
		if randf() < 0.6:
			var mid_x: float = lerpf(basin_left.x, basin_right.x, randf_range(0.2, 0.8))
			positions.append(Vector2(mid_x - 8, _get_terrain_y_at(mid_x - 8)))
		for pos in positions:
			if pos.y <= 0:
				continue
			var plant := Node2D.new()
			plant.z_index = 4
			add_child(plant)
			# Stem
			var stem_h: float = randf_range(8, 16)
			var stem := ColorRect.new()
			stem.size = Vector2(2, stem_h)
			stem.position = Vector2(pos.x - 1, pos.y - stem_h)
			stem.color = Color(0.1, 0.3, 0.15, 0.8)
			plant.add_child(stem)
			# Glowing bulb
			var bulb := ColorRect.new()
			var bulb_size: float = randf_range(4, 7)
			bulb.size = Vector2(bulb_size, bulb_size)
			bulb.position = Vector2(pos.x - bulb_size * 0.5, pos.y - stem_h - bulb_size * 0.5)
			var glow_color: Color
			var color_roll: float = randf()
			if color_roll < 0.4:
				glow_color = Color(0.2, 0.9, 0.4, 0.0)  # Green
			elif color_roll < 0.7:
				glow_color = Color(0.3, 0.6, 1.0, 0.0)   # Blue
			else:
				glow_color = Color(0.8, 0.4, 0.9, 0.0)    # Purple
			bulb.color = glow_color
			plant.add_child(bulb)
			# Outer glow aura
			var aura := ColorRect.new()
			var aura_size: float = bulb_size + 6
			aura.size = Vector2(aura_size, aura_size)
			aura.position = Vector2(pos.x - aura_size * 0.5, pos.y - stem_h - aura_size * 0.5)
			aura.color = Color(glow_color.r, glow_color.g, glow_color.b, 0.0)
			plant.add_child(aura)
			# Small leaves on stem
			var leaf := ColorRect.new()
			leaf.size = Vector2(4, 2)
			leaf.position = Vector2(pos.x, pos.y - stem_h * 0.5)
			leaf.color = Color(0.12, 0.35, 0.12, 0.7)
			plant.add_child(leaf)

			glow_plants.append({
				"node": plant,
				"bulb": bulb,
				"aura": aura,
				"glow_color": glow_color,
				"phase": randf() * TAU,
				"pulse_speed": randf_range(1.2, 2.5),
			})

# --- Underwater Seaweed ---
func _build_seaweed() -> void:
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var basin_left: Vector2 = geo["basin_left"]
		var basin_right: Vector2 = geo["basin_right"]
		var basin_w: float = basin_right.x - basin_left.x
		var count: int = clampi(int(basin_w / 20.0), 2, 8)
		for j in range(count):
			var sw_x: float = basin_left.x + randf_range(8, basin_w - 8)
			var sw_height: float = randf_range(10, 28)
			var segments: int = randi_range(3, 5)
			var green_hue: float = randf_range(0.25, 0.38)
			# Anchor node at basin floor so rotation pivots from base
			var sw_node := Node2D.new()
			sw_node.z_index = 2
			sw_node.position = Vector2(sw_x, basin_left.y)
			add_child(sw_node)
			for s in range(segments):
				var strand := ColorRect.new()
				strand.size = Vector2(2, sw_height / segments + randf_range(-2, 2))
				strand.position = Vector2(s * 2 - segments, -sw_height + s * (sw_height / segments))
				strand.color = Color.from_hsv(green_hue, randf_range(0.5, 0.8), randf_range(0.3, 0.5), 0.7)
				sw_node.add_child(strand)
			# Tip accent
			var tip := ColorRect.new()
			tip.size = Vector2(3, 2)
			tip.position = Vector2(-1, -sw_height - 1)
			tip.color = Color.from_hsv(green_hue, 0.6, 0.55, 0.8)
			sw_node.add_child(tip)
			seaweed.append({
				"node": sw_node,
				"swamp": i,
				"x": sw_x,
				"height": sw_height,
				"phase": randf() * TAU,
				"sway_speed": randf_range(1.0, 2.0),
			})

# --- Turtles ---
func _build_turtles() -> void:
	for i in range(SWAMP_COUNT):
		if randf() > 0.6:
			continue
		var geo: Dictionary = _get_swamp_geometry(i)
		var entry_top: Vector2 = geo["entry_top"]
		var exit_top: Vector2 = geo["exit_top"]
		# Place turtle near a pool edge
		var side: bool = randf() > 0.5
		var tx: float
		var ty: float
		if side:
			tx = entry_top.x + randf_range(2, 10)
			ty = entry_top.y + randf_range(-2, 4)
		else:
			tx = exit_top.x + randf_range(-10, -2)
			ty = exit_top.y + randf_range(-2, 4)
		var turtle_node := Node2D.new()
		turtle_node.z_index = 3
		add_child(turtle_node)
		# Shell
		var shell := ColorRect.new()
		shell.size = Vector2(8, 6)
		shell.position = Vector2(tx - 4, ty - 6)
		shell.color = Color(0.3, 0.4, 0.2, 0.95)
		turtle_node.add_child(shell)
		# Shell pattern
		var pattern := ColorRect.new()
		pattern.size = Vector2(6, 4)
		pattern.position = Vector2(tx - 3, ty - 5)
		pattern.color = Color(0.35, 0.48, 0.25, 0.7)
		turtle_node.add_child(pattern)
		# Shell highlight
		var shell_hl := ColorRect.new()
		shell_hl.size = Vector2(4, 1)
		shell_hl.position = Vector2(tx - 2, ty - 6)
		shell_hl.color = Color(0.45, 0.55, 0.3, 0.5)
		turtle_node.add_child(shell_hl)
		# Head
		var head := ColorRect.new()
		head.size = Vector2(3, 3)
		head.position = Vector2(tx + 4, ty - 5)
		head.color = Color(0.35, 0.45, 0.2, 0.95)
		turtle_node.add_child(head)
		# Eye
		var eye := ColorRect.new()
		eye.size = Vector2(1, 1)
		eye.position = Vector2(tx + 6, ty - 5)
		eye.color = Color(0.1, 0.1, 0.1)
		turtle_node.add_child(eye)
		# Legs
		for lx in [-3, 3]:
			var leg := ColorRect.new()
			leg.size = Vector2(2, 2)
			leg.position = Vector2(tx + lx - 1, ty - 1)
			leg.color = Color(0.3, 0.42, 0.18, 0.9)
			turtle_node.add_child(leg)
		turtles.append({
			"node": turtle_node,
			"swamp": i,
			"head_ref": head,
			"phase": randf() * TAU,
		})

# --- Tadpoles ---
func _build_tadpoles() -> void:
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var basin_left: Vector2 = geo["basin_left"]
		var basin_right: Vector2 = geo["basin_right"]
		var basin_w: float = basin_right.x - basin_left.x
		var count: int = clampi(int(basin_w / 50.0), 1, 4)
		for j in range(count):
			var tp_node := Node2D.new()
			tp_node.z_index = 3
			add_child(tp_node)
			# Tiny body
			var body := ColorRect.new()
			body.size = Vector2(3, 2)
			body.position = Vector2(-1.5, -1)
			body.color = Color(0.15, 0.15, 0.12, 0.85)
			tp_node.add_child(body)
			# Tail
			var tail := ColorRect.new()
			tail.size = Vector2(4, 1)
			tail.position = Vector2(-5.5, -0.5)
			tail.color = Color(0.2, 0.2, 0.15, 0.7)
			tp_node.add_child(tail)

			var tpx: float = basin_left.x + randf_range(8, basin_w - 8)
			tadpoles.append({
				"node": tp_node,
				"swamp": i,
				"x": tpx,
				"swim_phase": randf() * TAU,
				"swim_speed": randf_range(1.5, 3.0),
				"swim_range": randf_range(10, 25),
				"depth_offset": randf_range(0.5, 0.9),
			})

func _get_terrain_y_at(x: float) -> float:
	for i in range(terrain_points.size() - 1):
		if x >= terrain_points[i].x and x <= terrain_points[i + 1].x:
			var t: float = (x - terrain_points[i].x) / (terrain_points[i + 1].x - terrain_points[i].x + 0.001)
			return lerpf(terrain_points[i].y, terrain_points[i + 1].y, t)
	return -1.0

# --- Unique Pool Features ---
func _build_pool_features() -> void:
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var bl: Vector2 = geo["basin_left"]
		var br: Vector2 = geo["basin_right"]
		var et: Vector2 = geo["entry_top"]
		var xt: Vector2 = geo["exit_top"]
		var bw: float = br.x - bl.x
		var basin_y: float = maxf(bl.y, br.y)
		match i:
			0: _build_puddle_features(bl, br, et, xt, bw, basin_y)
			1: _build_pond_features(bl, br, et, xt, bw, basin_y)
			2: _build_marsh_features(bl, br, et, xt, bw, basin_y)
			3: _build_bog_features(bl, br, et, xt, bw, basin_y)
			4: _build_deep_swamp_features(bl, br, et, xt, bw, basin_y)

# Puddle: pebbles and sandy patch
func _build_puddle_features(bl: Vector2, br: Vector2, _et: Vector2, _xt: Vector2, bw: float, basin_y: float) -> void:
	# Sandy patch on bottom
	var sand := ColorRect.new()
	sand.size = Vector2(bw * 0.6, 4)
	sand.position = Vector2(bl.x + bw * 0.2, basin_y - 3)
	sand.color = Color(0.62, 0.55, 0.38, 0.35)
	sand.z_index = 1
	add_child(sand)
	# Small pebbles
	for j in range(randi_range(5, 8)):
		var peb := ColorRect.new()
		var sz: float = randf_range(2, 5)
		peb.size = Vector2(sz, sz * randf_range(0.5, 0.8))
		peb.position = Vector2(bl.x + randf_range(4, bw - 4), basin_y - randf_range(1, 4))
		var gray: float = randf_range(0.35, 0.55)
		peb.color = Color(gray, gray * randf_range(0.9, 1.1), gray * randf_range(0.85, 1.0), 0.7)
		peb.z_index = 1
		add_child(peb)

# Pond: submerged log with branch and weeds
func _build_pond_features(bl: Vector2, br: Vector2, _et: Vector2, _xt: Vector2, bw: float, basin_y: float) -> void:
	# Submerged log
	var log_line := Line2D.new()
	log_line.width = 4.0
	log_line.default_color = Color(0.28, 0.18, 0.10, 0.8)
	log_line.z_index = 1
	var log_x1: float = bl.x + bw * 0.15
	var log_x2: float = bl.x + bw * 0.75
	log_line.add_point(Vector2(log_x1, basin_y - 2))
	log_line.add_point(Vector2(log_x2, basin_y - 5))
	add_child(log_line)
	# Broken branch sticking up
	var branch := Line2D.new()
	branch.width = 2.0
	branch.default_color = Color(0.32, 0.22, 0.12, 0.75)
	branch.z_index = 2
	var branch_x: float = lerpf(log_x1, log_x2, 0.6)
	var branch_base_y: float = lerpf(basin_y - 2, basin_y - 5, 0.6)
	branch.add_point(Vector2(branch_x, branch_base_y))
	branch.add_point(Vector2(branch_x + 4, branch_base_y - 16))
	branch.add_point(Vector2(branch_x + 8, branch_base_y - 22))
	add_child(branch)
	# Water weeds growing off log
	for j in range(3):
		var weed := ColorRect.new()
		weed.size = Vector2(2, randf_range(6, 12))
		var wx: float = lerpf(log_x1, log_x2, randf_range(0.2, 0.8))
		var wy: float = lerpf(basin_y - 2, basin_y - 5, (wx - log_x1) / (log_x2 - log_x1))
		weed.position = Vector2(wx, wy - weed.size.y)
		weed.color = Color(0.2, 0.45, 0.18, 0.65)
		weed.z_index = 2
		add_child(weed)

# Marsh: root network, reed clusters, silt overlay
func _build_marsh_features(bl: Vector2, br: Vector2, et: Vector2, xt: Vector2, bw: float, basin_y: float) -> void:
	# Exposed roots from slopes into water
	for j in range(randi_range(3, 4)):
		var root := Line2D.new()
		root.width = randf_range(2.0, 3.0)
		root.default_color = Color(0.35, 0.22, 0.12, 0.7)
		root.z_index = 1
		var from_left: bool = j < 2
		var start_x: float
		var start_y: float
		if from_left:
			start_x = et.x + randf_range(2, 12)
			start_y = et.y + randf_range(-2, 4)
		else:
			start_x = xt.x - randf_range(2, 12)
			start_y = xt.y + randf_range(-2, 4)
		var end_x: float = bl.x + randf_range(bw * 0.2, bw * 0.8)
		var end_y: float = basin_y - randf_range(0, 4)
		root.add_point(Vector2(start_x, start_y))
		root.add_point(Vector2(lerpf(start_x, end_x, 0.5), lerpf(start_y, end_y, 0.5) + randf_range(-3, 3)))
		root.add_point(Vector2(end_x, end_y))
		add_child(root)
	# Thick reed clusters at edges
	for j in range(4):
		var rx: float
		if j < 2:
			rx = et.x + randf_range(-4, 8)
		else:
			rx = xt.x + randf_range(-8, 4)
		var ry: float = et.y if j < 2 else xt.y
		for k in range(randi_range(2, 4)):
			var reed := Line2D.new()
			reed.width = 1.5
			reed.default_color = Color(0.3, 0.42, 0.18, 0.8)
			reed.z_index = 4
			var reed_h: float = randf_range(14, 24)
			reed.add_point(Vector2(rx + k * 2, ry))
			reed.add_point(Vector2(rx + k * 2 + randf_range(-2, 2), ry - reed_h))
			add_child(reed)
			# Bulrush top
			var bulrush := ColorRect.new()
			bulrush.size = Vector2(3, 5)
			bulrush.position = Vector2(rx + k * 2 - 1, ry - reed_h - 5)
			bulrush.color = Color(0.35, 0.25, 0.12, 0.85)
			bulrush.z_index = 4
			add_child(bulrush)
	# Murky silt overlay on bottom third
	var silt := Polygon2D.new()
	silt.color = Color(0.3, 0.22, 0.12, 0.15)
	silt.z_index = 2
	var silt_y: float = lerpf(et.y, basin_y, 0.65)
	silt.polygon = PackedVector2Array([
		Vector2(bl.x + 4, silt_y),
		Vector2(bl.x, bl.y),
		Vector2(br.x, br.y),
		Vector2(br.x - 4, silt_y),
	])
	add_child(silt)

# Bog: peat mounds, submerged stumps, moss
func _build_bog_features(bl: Vector2, br: Vector2, _et: Vector2, _xt: Vector2, bw: float, basin_y: float) -> void:
	# Submerged tree stumps
	for j in range(2):
		var stump := Polygon2D.new()
		stump.color = Color(0.25, 0.16, 0.08, 0.8)
		stump.z_index = 1
		var sx: float = bl.x + bw * (0.25 + j * 0.45) + randf_range(-8, 8)
		var sw: float = randf_range(8, 14)
		var sh: float = randf_range(10, 18)
		var stump_base_y: float = _get_terrain_y_at(sx)
		if stump_base_y < 0 or stump_base_y < basin_y:
			stump_base_y = basin_y
		stump.polygon = PackedVector2Array([
			Vector2(sx - sw * 0.5, stump_base_y),
			Vector2(sx - sw * 0.35, stump_base_y - sh),
			Vector2(sx + sw * 0.35, stump_base_y - sh),
			Vector2(sx + sw * 0.5, stump_base_y),
		])
		add_child(stump)
		# Moss patch on stump top
		var moss := ColorRect.new()
		moss.size = Vector2(sw * 0.5, 3)
		moss.position = Vector2(sx - sw * 0.25, stump_base_y - sh - 1)
		moss.color = Color(0.22, 0.45, 0.15, 0.6)
		moss.z_index = 2
		add_child(moss)
	# Peat mounds on basin floor
	for j in range(randi_range(3, 4)):
		var peat := Polygon2D.new()
		peat.color = Color(0.15, 0.12, 0.06, 0.65)
		peat.z_index = 1
		var px: float = bl.x + randf_range(10, bw - 10)
		var pw: float = randf_range(8, 16)
		var ph: float = randf_range(3, 6)
		peat.polygon = PackedVector2Array([
			Vector2(px - pw * 0.5, basin_y),
			Vector2(px - pw * 0.3, basin_y - ph),
			Vector2(px + pw * 0.3, basin_y - ph),
			Vector2(px + pw * 0.5, basin_y),
		])
		add_child(peat)

# Deep Swamp: dead trees, hanging moss, extra glow
func _build_deep_swamp_features(bl: Vector2, br: Vector2, _et: Vector2, _xt: Vector2, bw: float, basin_y: float) -> void:
	# Dead trees on terrain edges near pool
	for j in range(2):
		var tx: float
		if j == 0:
			tx = bl.x - randf_range(8, 25)
		else:
			tx = br.x + randf_range(8, 25)
		var base_y: float = _get_terrain_y_at(tx)
		if base_y < 0:
			base_y = basin_y
		var tree_h: float = randf_range(25, 45)
		# Trunk
		var trunk := Line2D.new()
		trunk.width = 4.0
		trunk.default_color = Color(0.22, 0.15, 0.08, 0.85)
		trunk.z_index = 4
		trunk.add_point(Vector2(tx, base_y))
		trunk.add_point(Vector2(tx + randf_range(-3, 3), base_y - tree_h))
		add_child(trunk)
		var top_x: float = tx + randf_range(-3, 3)
		var top_y: float = base_y - tree_h
		# Bare branches
		for k in range(randi_range(3, 5)):
			var br_line := Line2D.new()
			br_line.width = 2.0
			br_line.default_color = Color(0.25, 0.18, 0.10, 0.75)
			br_line.z_index = 4
			var branch_y: float = top_y + randf_range(5, tree_h * 0.4)
			var branch_dir: float = 1.0 if randf() > 0.5 else -1.0
			var branch_len: float = randf_range(12, 28)
			br_line.add_point(Vector2(tx, branch_y))
			br_line.add_point(Vector2(tx + branch_dir * branch_len, branch_y - randf_range(4, 12)))
			add_child(br_line)
			# Hanging moss strands from branches
			if randf() > 0.4:
				var moss_line := Line2D.new()
				moss_line.width = 1.0
				moss_line.default_color = Color(0.28, 0.42, 0.22, 0.5)
				moss_line.z_index = 4
				var moss_x: float = tx + branch_dir * branch_len * randf_range(0.3, 0.8)
				var moss_top_y: float = branch_y - randf_range(2, 8)
				moss_line.add_point(Vector2(moss_x, moss_top_y))
				moss_line.add_point(Vector2(moss_x + randf_range(-2, 2), moss_top_y + randf_range(8, 18)))
				add_child(moss_line)
	# Extra glow spots in deep water
	for j in range(randi_range(3, 5)):
		var glow_node := Node2D.new()
		glow_node.z_index = 2
		glow_node.position = Vector2(bl.x + randf_range(10, bw - 10), basin_y - randf_range(4, 20))
		add_child(glow_node)
		var glow_color := Color(0.3, 0.6, 0.5)
		var bulb := ColorRect.new()
		bulb.size = Vector2(3, 3)
		bulb.position = Vector2(-1.5, -1.5)
		bulb.color = Color(glow_color.r, glow_color.g, glow_color.b, 0.6)
		glow_node.add_child(bulb)
		var aura := ColorRect.new()
		aura.size = Vector2(7, 7)
		aura.position = Vector2(-3.5, -3.5)
		aura.color = Color(glow_color.r, glow_color.g, glow_color.b, 0.15)
		glow_node.add_child(aura)
		glow_plants.append({
			"node": glow_node,
			"bulb": bulb,
			"aura": aura,
			"glow_color": glow_color,
			"phase": randf() * TAU,
			"pulse_speed": randf_range(1.2, 2.5),
		})

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
	water_glow_lines.clear()
	for i in range(SWAMP_COUNT):
		var wp := Polygon2D.new()
		wp.color = SWAMP_WATER_COLORS[i]
		wp.z_index = 2
		var wmat := ShaderMaterial.new()
		wmat.shader = WATER_SHADER
		wmat.set_shader_parameter("wave_strength", POOL_SHADER_PARAMS[i][0])
		wmat.set_shader_parameter("specular_intensity", POOL_SHADER_PARAMS[i][1])
		wmat.set_shader_parameter("choppiness", POOL_SHADER_PARAMS[i][2])
		wmat.set_shader_parameter("turbidity", POOL_SHADER_PARAMS[i][3])
		wmat.set_shader_parameter("foam_density", POOL_SHADER_PARAMS[i][4])
		wp.material = wmat
		add_child(wp)
		water_polygons.append(wp)

		# Water surface shine line
		var wl := Line2D.new()
		wl.width = 3.0
		wl.default_color = WATER_SURFACE_COLOR
		wl.z_index = 3
		add_child(wl)
		water_surface_lines.append(wl)

		# Water edge glow (additive blend)
		var glow := Line2D.new()
		glow.width = 8.0
		glow.default_color = Color(0.2, 0.75, 0.65, 0.12)
		glow.z_index = 3
		var glow_mat := CanvasItemMaterial.new()
		glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow.material = glow_mat
		add_child(glow)
		water_glow_lines.append(glow)

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
		if swamp_index < water_glow_lines.size():
			water_glow_lines[swamp_index].clear_points()
		return

	# Use the deeper basin point as reference for water level
	var basin_y: float = maxf(basin_left.y, basin_right.y)
	var overflow_y: float = maxf(entry_top.y, exit_top.y)
	var water_y: float = basin_y - fill * (basin_y - overflow_y)

	var left_x: float = _lerp_x_at_y(entry_top, basin_left, water_y)
	var right_x: float = _lerp_x_at_y(basin_right, exit_top, water_y)

	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var bowl_depth: float = POOL_BOWL_DEPTHS[swamp_index]

	# Top-left corner
	points.append(Vector2(left_x, water_y))
	uvs.append(Vector2(0, 0))

	# Left basin point
	points.append(Vector2(basin_left.x, basin_left.y))

	# 3 intermediate bowl points along basin floor
	var basin_floor_y: float = lerpf(basin_left.y, basin_right.y, 0.5)
	for bi in range(3):
		var bt: float = (float(bi) + 1.0) / 4.0
		var bx: float = lerpf(basin_left.x, basin_right.x, bt)
		var by: float = lerpf(basin_left.y, basin_right.y, bt) + sin(bt * PI) * bowl_depth
		points.append(Vector2(bx, by))

	# Right basin point
	points.append(Vector2(basin_right.x, basin_right.y))

	# Top-right corner
	points.append(Vector2(right_x, water_y))

	# Generate UVs based on normalized positions
	var min_y: float = water_y
	var max_y: float = basin_floor_y + bowl_depth
	var y_range: float = maxf(max_y - min_y, 1.0)
	uvs.clear()
	var total_pts: int = points.size()
	for pi in range(total_pts):
		var ux: float = float(pi) / float(total_pts - 1)
		var uy: float = clampf((points[pi].y - min_y) / y_range, 0.0, 1.0)
		uvs.append(Vector2(ux, uy))

	water_polygons[swamp_index].polygon = points
	water_polygons[swamp_index].uv = uvs

	# Tint water based on fill using per-pool colors
	var col: Color = SWAMP_WATER_COLORS[swamp_index].lerp(SWAMP_WATER_EMPTY_COLORS[swamp_index], 1.0 - fill)
	water_polygons[swamp_index].color = col

	# Update surface line
	_update_water_surface_line(swamp_index, left_x, right_x, water_y)

func _update_water_surface_line(swamp_index: int, left_x: float, right_x: float, water_y: float) -> void:
	var line: Line2D = water_surface_lines[swamp_index]
	line.clear_points()
	var segments: int = int((right_x - left_x) / 6.0)
	segments = maxi(segments, 4)
	var wave_amp: float = POOL_WAVE_PARAMS[swamp_index][0]
	var wave_freq: float = POOL_WAVE_PARAMS[swamp_index][1]
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var px: float = lerpf(left_x, right_x, t)
		var wave_offset: float = sin(wave_time * wave_freq + px * 0.15) * wave_amp
		line.add_point(Vector2(px, water_y + wave_offset))
	# Update water edge glow
	if swamp_index < water_glow_lines.size():
		var glow: Line2D = water_glow_lines[swamp_index]
		glow.clear_points()
		for i in range(segments + 1):
			var gt: float = float(i) / float(segments)
			var gpx: float = lerpf(left_x, right_x, gt)
			var gwave: float = sin(wave_time * 1.5 + gpx * 0.12) * 2.0
			glow.add_point(Vector2(gpx, water_y + gwave))

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

	var basin_y: float = maxf(basin_left.y, basin_right.y)
	var overflow_y: float = maxf(entry_top.y, exit_top.y)
	var water_y: float = basin_y - fill * (basin_y - overflow_y)

	var left_x: float = _lerp_x_at_y(entry_top, basin_left, water_y)
	var right_x: float = _lerp_x_at_y(basin_right, exit_top, water_y)

	left_body.position = Vector2(left_x, water_y - 28)
	right_body.position = Vector2(right_x, water_y - 28)

# --- Right Boundary Wall ---
func _build_left_boundary() -> void:
	var wall_body := StaticBody2D.new()
	wall_body.position = Vector2(-4, terrain_points[0].y - 60)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 200)
	col.shape = rect
	wall_body.add_child(col)
	add_child(wall_body)

func _build_right_boundary() -> void:
	var last_point: Vector2 = terrain_points[terrain_points.size() - 1]
	var wall_body := StaticBody2D.new()
	wall_body.position = Vector2(last_point.x + 4, last_point.y - 60)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 200)
	col.shape = rect
	wall_body.add_child(col)
	add_child(wall_body)

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
	swamp_percent_labels.clear()
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var basin_mid_x: float = (geo["basin_left"].x + geo["basin_right"].x) * 0.5
		var label_y: float = geo["entry_top"].y - 24
		var basin_y: float = maxf(geo["basin_left"].y, geo["basin_right"].y)

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

		# Percentage label below basin
		var pct_label := Label.new()
		var pct: float = GameManager.get_swamp_water_percent(i)
		pct_label.text = "%.1f%%" % pct
		pct_label.add_theme_font_size_override("font_size", 10)
		pct_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85, 0.6))
		pct_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
		pct_label.add_theme_constant_override("shadow_offset_x", 1)
		pct_label.add_theme_constant_override("shadow_offset_y", 1)
		pct_label.position = Vector2(basin_mid_x - 16, basin_y + 8)
		pct_label.z_index = 5
		add_child(pct_label)
		swamp_percent_labels.append(pct_label)

# --- Signal Handlers ---
func _on_swamp_body_entered(body: Node2D, swamp_index: int) -> void:
	if body is CharacterBody2D and body.has_method("set_near_water"):
		body.set_near_water(true, swamp_index)

func _on_swamp_body_exited(body: Node2D, swamp_index: int) -> void:
	if body is CharacterBody2D and body.has_method("set_near_water"):
		body.set_near_water(false, swamp_index)

# --- Camels ---
func _on_camel_changed() -> void:
	_build_camels()

func _build_camels() -> void:
	# Remove existing camel nodes
	for cd in camels:
		if is_instance_valid(cd["node"]):
			cd["node"].queue_free()
	camels.clear()

	for i in range(GameManager.camel_count):
		var camel_node := Node2D.new()
		camel_node.z_index = 5

		# Ensure state exists
		if i >= GameManager.camel_states.size():
			GameManager.camel_states.append({"state": "to_player", "x": 30.0, "water_carried": 0.0, "source_swamp": 0, "state_timer": 0.0})
		var start_x: float = GameManager.camel_states[i]["x"]
		camel_node.position = Vector2(start_x, _get_terrain_y_at(start_x))

		# Body (sandy brown)
		var body := ColorRect.new()
		body.size = Vector2(20, 12)
		body.position = Vector2(-10, -20)
		body.color = Color(0.76, 0.6, 0.38)
		camel_node.add_child(body)

		# Hump
		var hump := ColorRect.new()
		hump.size = Vector2(8, 6)
		hump.position = Vector2(-2, -26)
		hump.color = Color(0.72, 0.56, 0.34)
		camel_node.add_child(hump)

		# Neck
		var neck := ColorRect.new()
		neck.size = Vector2(4, 10)
		neck.position = Vector2(8, -30)
		neck.color = Color(0.74, 0.58, 0.36)
		camel_node.add_child(neck)

		# Head
		var head := ColorRect.new()
		head.size = Vector2(8, 6)
		head.position = Vector2(6, -36)
		head.color = Color(0.78, 0.62, 0.4)
		camel_node.add_child(head)

		# Eye
		var eye := ColorRect.new()
		eye.size = Vector2(2, 2)
		eye.position = Vector2(12, -35)
		eye.color = Color(0.15, 0.1, 0.05)
		camel_node.add_child(eye)

		# Front legs
		var leg_fl := ColorRect.new()
		leg_fl.size = Vector2(3, 10)
		leg_fl.position = Vector2(5, -8)
		leg_fl.color = Color(0.68, 0.52, 0.32)
		camel_node.add_child(leg_fl)

		var leg_fr := ColorRect.new()
		leg_fr.size = Vector2(3, 10)
		leg_fr.position = Vector2(8, -8)
		leg_fr.color = Color(0.65, 0.5, 0.3)
		camel_node.add_child(leg_fr)

		# Back legs
		var leg_bl := ColorRect.new()
		leg_bl.size = Vector2(3, 10)
		leg_bl.position = Vector2(-8, -8)
		leg_bl.color = Color(0.68, 0.52, 0.32)
		camel_node.add_child(leg_bl)

		var leg_br := ColorRect.new()
		leg_br.size = Vector2(3, 10)
		leg_br.position = Vector2(-5, -8)
		leg_br.color = Color(0.65, 0.5, 0.3)
		camel_node.add_child(leg_br)

		# Tail
		var tail := ColorRect.new()
		tail.size = Vector2(2, 8)
		tail.position = Vector2(-12, -18)
		tail.color = Color(0.62, 0.48, 0.28)
		camel_node.add_child(tail)

		# Saddlebag (shows water fill)
		var bag := ColorRect.new()
		bag.size = Vector2(10, 6)
		bag.position = Vector2(-7, -18)
		bag.color = Color(0.5, 0.38, 0.2)
		camel_node.add_child(bag)

		add_child(camel_node)
		camels.append({
			"node": camel_node,
			"body": body,
			"head": head,
			"neck": neck,
			"hump": hump,
			"leg_fl": leg_fl,
			"leg_fr": leg_fr,
			"leg_bl": leg_bl,
			"leg_br": leg_br,
			"tail": tail,
			"bag": bag,
			"eye": eye,
			"walk_time": 0.0,
			"facing_right": true
		})

func _update_camels(delta: float) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	var player_x: float = 80.0
	if players.size() > 0 and is_instance_valid(players[0]):
		player_x = players[0].global_position.x

	var camel_speed: float = GameManager.get_camel_speed()
	var camel_cap: float = GameManager.get_camel_capacity()

	for i in range(GameManager.camel_states.size()):
		if i >= camels.size():
			break
		var cs: Dictionary = GameManager.camel_states[i]
		var cd: Dictionary = camels[i]
		var node: Node2D = cd["node"]

		match cs["state"]:
			"to_player":
				# Walk toward player
				var dx: float = player_x - cs["x"]
				if absf(dx) > 15.0:
					var dir: float = signf(dx)
					cs["x"] += dir * camel_speed * delta
					cd["facing_right"] = dir > 0.0
					cd["walk_time"] += delta * 6.0
					_animate_camel_walk(cd)
				else:
					# Arrived at player
					cs["state"] = "loading"
					cs["state_timer"] = 0.0
					_animate_camel_idle(cd)

			"loading":
				cs["state_timer"] += delta
				_animate_camel_idle(cd)
				# Chase if player moves away
				var chase_dx: float = player_x - cs["x"]
				if absf(chase_dx) > 30.0:
					cs["state"] = "to_player"
				elif cs["state_timer"] >= 0.5:
					if GameManager.water_carried > 0.0001:
						GameManager.camel_take_water(i)
						cs["state"] = "to_pump"
						cs["state_timer"] = 0.0
					else:
						# No water, retry
						cs["state_timer"] = 0.0

			"to_pump":
				# Walk left to pump (x≈30)
				var pump_x: float = 30.0
				var dx2: float = pump_x - cs["x"]
				if absf(dx2) > 5.0:
					var dir2: float = signf(dx2)
					cs["x"] += dir2 * camel_speed * delta
					cd["facing_right"] = dir2 > 0.0
					cd["walk_time"] += delta * 6.0
					_animate_camel_walk(cd)
				else:
					cs["state"] = "unloading"
					cs["state_timer"] = 0.0
					_animate_camel_idle(cd)

			"unloading":
				cs["state_timer"] += delta
				_animate_camel_idle(cd)
				if cs["state_timer"] >= 0.5:
					var earned: float = GameManager.camel_sell_water(i)
					if earned > 0.01:
						_spawn_camel_sell_text(cs["x"], _get_terrain_y_at(cs["x"]) - 40, earned)
					cs["state"] = "to_player"
					cs["state_timer"] = 0.0

		# Update position on terrain
		var terrain_y: float = _get_terrain_y_at(cs["x"])
		if terrain_y > 0:
			node.position = Vector2(cs["x"], terrain_y)
		else:
			node.position.x = cs["x"]

		# Flip direction
		node.scale.x = 1.0 if cd["facing_right"] else -1.0

		# Camel dust trail when walking
		var is_walking: bool = (cs["state"] == "to_player" or cs["state"] == "to_pump")
		if is_walking:
			cd["dust_timer"] = cd.get("dust_timer", 0.0) + delta
			if cd["dust_timer"] >= 0.3:
				cd["dust_timer"] = 0.0
				_spawn_camel_dust(cs["x"], node.position.y)

		# Update saddlebag color based on water fill
		var bag: ColorRect = cd["bag"]
		var fill_frac: float = 0.0
		if camel_cap > 0.0:
			fill_frac = clampf(cs["water_carried"] / camel_cap, 0.0, 1.0)
		if fill_frac > 0.01:
			bag.color = Color(0.5, 0.38, 0.2).lerp(Color(0.25, 0.45, 0.7), fill_frac)
		else:
			bag.color = Color(0.5, 0.38, 0.2)

func _animate_camel_walk(cd: Dictionary) -> void:
	var wt: float = cd["walk_time"]
	var leg_offset: float = sin(wt) * 3.0
	cd["leg_fl"].position.y = -8.0 + leg_offset
	cd["leg_fr"].position.y = -8.0 - leg_offset
	cd["leg_bl"].position.y = -8.0 - leg_offset
	cd["leg_br"].position.y = -8.0 + leg_offset
	# Body bob
	var bob: float = sin(wt * 2.0) * 1.0
	cd["body"].position.y = -20.0 + bob
	cd["hump"].position.y = -26.0 + bob
	cd["bag"].position.y = -18.0 + bob
	# Head bob
	var head_bob: float = sin(wt * 2.0 + 0.5) * 1.5
	cd["head"].position.y = -36.0 + head_bob
	cd["neck"].position.y = -30.0 + head_bob * 0.5
	cd["eye"].position.y = -35.0 + head_bob
	# Tail swing
	var tail_swing: float = sin(wt * 1.5) * 2.0
	cd["tail"].position.x = -12.0 + tail_swing

func _animate_camel_idle(cd: Dictionary) -> void:
	# Breathing motion
	var breath: float = sin(Time.get_ticks_msec() * 0.002) * 0.5
	cd["body"].position.y = -20.0 + breath
	cd["hump"].position.y = -26.0 + breath
	cd["bag"].position.y = -18.0 + breath
	cd["head"].position.y = -36.0 + breath * 0.5
	cd["neck"].position.y = -30.0 + breath * 0.3
	cd["eye"].position.y = -35.0 + breath * 0.5
	# Reset legs
	cd["leg_fl"].position.y = -8.0
	cd["leg_fr"].position.y = -8.0
	cd["leg_bl"].position.y = -8.0
	cd["leg_br"].position.y = -8.0
	cd["tail"].position.x = -12.0

func _spawn_camel_dust(x: float, y: float) -> void:
	for i in range(2):
		var dust := ColorRect.new()
		dust.size = Vector2(3, 2)
		dust.color = Color(0.55, 0.45, 0.3, 0.4)
		dust.position = Vector2(x + randf_range(-4, 4), y + randf_range(-2, 0))
		dust.z_index = -1
		add_child(dust)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(dust, "position", dust.position + Vector2(randf_range(-6, 6), randf_range(-6, -3)), 0.5)
		tw.tween_property(dust, "modulate:a", 0.0, 0.5)
		tw.set_parallel(false)
		tw.tween_callback(dust.queue_free)

func _spawn_camel_sell_text(x: float, y: float, earned: float) -> void:
	var label := Label.new()
	label.text = "+%s" % Economy.format_money(earned)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.position = Vector2(x - 20, y)
	label.z_index = 10
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 32, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _on_water_level_changed(swamp_index: int, _percent: float) -> void:
	if swamp_index >= 0 and swamp_index < SWAMP_COUNT:
		_update_water_polygon(swamp_index)
		_update_water_walls(swamp_index)
		_update_depth_gradient(swamp_index)
		_update_mud_visibility()
		if swamp_index < swamp_percent_labels.size():
			var pct: float = GameManager.get_swamp_water_percent(swamp_index)
			swamp_percent_labels[swamp_index].text = "%.1f%%" % pct

func _on_swamp_completed(swamp_index: int, _reward: float) -> void:
	if swamp_index >= 0 and swamp_index < swamp_labels.size():
		swamp_labels[swamp_index].add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 0.9))
		swamp_labels[swamp_index].text = GameManager.swamp_definitions[swamp_index]["name"] + " [DONE]"
	if swamp_index >= 0 and swamp_index < swamp_percent_labels.size():
		swamp_percent_labels[swamp_index].text = "0.0%"
		swamp_percent_labels[swamp_index].add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 0.9))
	# Phase 7a: Heavy screen shake on swamp drained
	_screen_shake(5.0, 0.3)
	# Phase 7c: Milestone flash — golden vignette pulse + brief scale bounce
	_milestone_flash()

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

# --- Weather System ---
func _build_weather() -> void:
	rain_layer = CanvasLayer.new()
	rain_layer.layer = 50
	add_child(rain_layer)
	rain_particles = CPUParticles2D.new()
	rain_particles.emitting = false
	rain_particles.amount = 200
	rain_particles.lifetime = 0.5
	rain_particles.position = Vector2(160, -10)
	rain_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain_particles.emission_rect_extents = Vector2(200, 4)
	rain_particles.direction = Vector2(-0.2, 1.0)
	rain_particles.spread = 8.0
	rain_particles.initial_velocity_min = 200.0
	rain_particles.initial_velocity_max = 280.0
	rain_particles.gravity = Vector2(-30, 400)
	rain_particles.color = Color(0.55, 0.65, 0.85, 0.3)
	rain_particles.scale_amount_min = 0.5
	rain_particles.scale_amount_max = 1.2
	rain_layer.add_child(rain_particles)
	lightning_rect = ColorRect.new()
	lightning_rect.size = Vector2(320, 180)
	lightning_rect.color = Color(1, 1, 1, 0)
	lightning_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rain_layer.add_child(lightning_rect)

# --- Drain-Revealed Objects ---
func _build_drain_reveals() -> void:
	drain_reveals.clear()
	for i in range(SWAMP_COUNT):
		var geo: Dictionary = _get_swamp_geometry(i)
		var bl: Vector2 = geo["basin_left"]
		var br: Vector2 = geo["basin_right"]
		var cx: float = (bl.x + br.x) * 0.5
		var by: float = maxf(bl.y, br.y)
		var reveals: Array = []
		# 75% - mud patches at edges
		var mud_l := ColorRect.new()
		mud_l.size = Vector2(8, 3)
		mud_l.position = Vector2(bl.x + 4, by - 2)
		mud_l.color = Color(0.3, 0.22, 0.1, 0.7)
		mud_l.z_index = 1
		mud_l.visible = false
		add_child(mud_l)
		var mud_r := ColorRect.new()
		mud_r.size = Vector2(8, 3)
		mud_r.position = Vector2(br.x - 12, by - 2)
		mud_r.color = Color(0.3, 0.22, 0.1, 0.7)
		mud_r.z_index = 1
		mud_r.visible = false
		add_child(mud_r)
		reveals.append({"threshold": 0.75, "nodes": [mud_l, mud_r]})
		# 50% - exposed rocks
		var rock1 := ColorRect.new()
		rock1.size = Vector2(5, 4)
		rock1.position = Vector2(cx - 15, by - 3)
		rock1.color = Color(0.42, 0.4, 0.38, 0.85)
		rock1.z_index = 1
		rock1.visible = false
		add_child(rock1)
		var rock2 := ColorRect.new()
		rock2.size = Vector2(4, 3)
		rock2.position = Vector2(cx + 10, by - 2)
		rock2.color = Color(0.38, 0.36, 0.34, 0.85)
		rock2.z_index = 1
		rock2.visible = false
		add_child(rock2)
		reveals.append({"threshold": 0.50, "nodes": [rock1, rock2]})
		# 25% - rusty sign, old boot
		var boot := ColorRect.new()
		boot.size = Vector2(4, 5)
		boot.position = Vector2(cx + 5, by - 4)
		boot.color = Color(0.35, 0.2, 0.1, 0.75)
		boot.z_index = 1
		boot.visible = false
		add_child(boot)
		var sign_post := ColorRect.new()
		sign_post.size = Vector2(2, 8)
		sign_post.position = Vector2(cx - 20, by - 7)
		sign_post.color = Color(0.5, 0.35, 0.2, 0.8)
		sign_post.z_index = 1
		sign_post.visible = false
		add_child(sign_post)
		var sign_board := ColorRect.new()
		sign_board.size = Vector2(8, 5)
		sign_board.position = Vector2(cx - 24, by - 12)
		sign_board.color = Color(0.55, 0.4, 0.25, 0.7)
		sign_board.z_index = 1
		sign_board.visible = false
		add_child(sign_board)
		reveals.append({"threshold": 0.25, "nodes": [boot, sign_post, sign_board]})
		# 0% - treasure chest
		var chest := ColorRect.new()
		chest.size = Vector2(8, 6)
		chest.position = Vector2(cx, by - 5)
		chest.color = Color(0.7, 0.55, 0.15, 0.9)
		chest.z_index = 1
		chest.visible = false
		add_child(chest)
		var chest_lid := ColorRect.new()
		chest_lid.size = Vector2(10, 3)
		chest_lid.position = Vector2(cx - 1, by - 8)
		chest_lid.color = Color(0.6, 0.45, 0.1, 0.9)
		chest_lid.z_index = 1
		chest_lid.visible = false
		add_child(chest_lid)
		reveals.append({"threshold": 0.0, "nodes": [chest, chest_lid]})
		drain_reveals.append(reveals)

func _flash_lightning() -> void:
	if lightning_rect:
		lightning_rect.color.a = 0.5

# --- Coin Fly (Phase 16c) ---
func _spawn_coin_fly(from_pos: Vector2) -> void:
	for i in range(3):
		var coin := ColorRect.new()
		coin.size = Vector2(2, 2)
		coin.color = Color(1.0, 0.85, 0.2, 0.9)
		coin.position = from_pos + Vector2(randf_range(-4, 4), randf_range(-8, -4))
		coin.z_index = 12
		add_child(coin)
		# Fly upward and to the left (toward HUD corner)
		var target: Vector2 = Vector2(from_pos.x - 40 + randf_range(-20, 20), from_pos.y - 60)
		var tw := create_tween()
		tw.tween_property(coin, "position", target, 0.5 + randf_range(0, 0.2))
		tw.parallel().tween_property(coin, "modulate:a", 0.0, 0.6)
		tw.tween_callback(coin.queue_free)

# --- Pump Steam (Phase 17a) ---
func _spawn_pump_steam() -> void:
	if not pump_light_ref or not is_instance_valid(pump_light_ref):
		return
	var px: float = pump_light_ref.global_position.x + randf_range(-6, 6)
	var py: float = pump_light_ref.global_position.y - 8
	var steam := ColorRect.new()
	steam.size = Vector2(randf_range(3, 6), randf_range(2, 4))
	steam.position = Vector2(px, py)
	steam.color = Color(0.9, 0.9, 0.95, 0.3)
	steam.z_index = 8
	add_child(steam)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(steam, "position:y", py - randf_range(12, 20), 0.8)
	tw.tween_property(steam, "position:x", px + randf_range(-6, 6), 0.8)
	tw.tween_property(steam, "size", steam.size + Vector2(3, 2), 0.8)
	tw.tween_property(steam, "modulate:a", 0.0, 0.8)
	tw.set_parallel(false)
	tw.tween_callback(steam.queue_free)

# --- Screen Effects (Phase 7) ---
func _screen_shake(amount: float, duration: float) -> void:
	var cam: Camera2D = get_viewport().get_camera_2d() if get_viewport() else null
	if not cam:
		return
	var shake_tw := create_tween()
	var steps: int = int(duration / 0.05)
	for i in range(steps):
		var offset: Vector2 = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		var decay: float = 1.0 - float(i) / float(steps)
		shake_tw.tween_property(cam, "offset", offset * decay, 0.05)
	shake_tw.tween_property(cam, "offset", Vector2.ZERO, 0.05)

func _milestone_flash() -> void:
	# Golden vignette pulse via post-process tint
	if post_process_rect and post_process_rect.material:
		var pp_mat: ShaderMaterial = post_process_rect.material as ShaderMaterial
		var orig_warmth: float = pp_mat.get_shader_parameter("warmth")
		var flash_tw := create_tween()
		flash_tw.tween_method(func(val: float) -> void:
			pp_mat.set_shader_parameter("warmth", val)
		, 0.08, orig_warmth, 0.6)
	# Particle burst around player
	var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player_node:
		for i in range(16):
			var spark := ColorRect.new()
			spark.size = Vector2(2, 2)
			spark.color = Color(1.0, 0.85, 0.2, 0.9)
			spark.position = player_node.global_position
			spark.z_index = 10
			add_child(spark)
			var angle: float = float(i) / 16.0 * TAU
			var target: Vector2 = spark.position + Vector2(cos(angle) * 30, sin(angle) * 30)
			var stw := create_tween()
			stw.tween_property(spark, "position", target, 0.5)
			stw.parallel().tween_property(spark, "modulate:a", 0.0, 0.5)
			stw.tween_callback(spark.queue_free)

# --- Atmosphere (Phase 17) ---
func _build_atmosphere() -> void:
	# Morning mist wisps (dawn-specific)
	for i in range(6):
		var mist := ColorRect.new()
		mist.size = Vector2(randf_range(40, 80), randf_range(6, 12))
		mist.position = Vector2(randf_range(0, 1800), randf_range(100, 140))
		mist.color = Color(0.9, 0.85, 0.7, 0.0)
		mist.z_index = 4
		add_child(mist)
		morning_mist_rects.append(mist)

	# Aurora borealis lines (rare night event)
	for i in range(5):
		var aline := Line2D.new()
		aline.width = 3.0
		aline.z_index = 2
		var aurora_colors: Array[Color] = [
			Color(0.2, 0.9, 0.4, 0.0),
			Color(0.3, 0.5, 0.9, 0.0),
			Color(0.6, 0.2, 0.8, 0.0),
			Color(0.2, 0.8, 0.7, 0.0),
			Color(0.4, 0.3, 0.9, 0.0),
		]
		aline.default_color = aurora_colors[i]
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		aline.material = mat
		add_child(aline)
		aurora_lines.append({"line": aline, "base_y": 15.0 + i * 8.0, "speed": randf_range(0.3, 0.6), "phase": randf() * TAU})

	# Owl (perched in treeline at night)
	owl_node = Node2D.new()
	owl_node.z_index = 5
	owl_node.position = Vector2(randf_range(400, 1600), 65)
	owl_node.visible = false
	add_child(owl_node)
	# Body
	var owl_body := ColorRect.new()
	owl_body.size = Vector2(6, 8)
	owl_body.position = Vector2(-3, -4)
	owl_body.color = Color(0.35, 0.3, 0.25)
	owl_node.add_child(owl_body)
	# Head
	var owl_head := ColorRect.new()
	owl_head.size = Vector2(8, 6)
	owl_head.position = Vector2(-4, -10)
	owl_head.color = Color(0.4, 0.35, 0.28)
	owl_node.add_child(owl_head)
	# Eyes
	var owl_eye_l := ColorRect.new()
	owl_eye_l.size = Vector2(2, 2)
	owl_eye_l.position = Vector2(-3, -9)
	owl_eye_l.color = Color(1.0, 0.9, 0.2, 0.9)
	owl_node.add_child(owl_eye_l)
	var owl_eye_r := ColorRect.new()
	owl_eye_r.size = Vector2(2, 2)
	owl_eye_r.position = Vector2(1, -9)
	owl_eye_r.color = Color(1.0, 0.9, 0.2, 0.9)
	owl_node.add_child(owl_eye_r)
	# Ear tufts
	var owl_ear_l := ColorRect.new()
	owl_ear_l.size = Vector2(2, 3)
	owl_ear_l.position = Vector2(-4, -13)
	owl_ear_l.color = Color(0.35, 0.3, 0.22)
	owl_node.add_child(owl_ear_l)
	var owl_ear_r := ColorRect.new()
	owl_ear_r.size = Vector2(2, 3)
	owl_ear_r.position = Vector2(2, -13)
	owl_ear_r.color = Color(0.35, 0.3, 0.22)
	owl_node.add_child(owl_ear_r)

	# Pump station glow
	if pump_light_ref and is_instance_valid(pump_light_ref):
		pump_glow_rect = ColorRect.new()
		pump_glow_rect.size = Vector2(20, 14)
		pump_glow_rect.position = Vector2(pump_light_ref.global_position.x - 10, pump_light_ref.global_position.y - 7)
		pump_glow_rect.color = Color(0.2, 0.8, 0.3, 0.0)
		pump_glow_rect.z_index = 0
		var glow_mat := CanvasItemMaterial.new()
		glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		pump_glow_rect.material = glow_mat
		add_child(pump_glow_rect)

# --- Player Shadow (Phase 13c) ---
func _build_player_shadow() -> void:
	player_shadow = ColorRect.new()
	player_shadow.size = Vector2(10, 3)
	player_shadow.color = Color(0.0, 0.0, 0.0, 0.2)
	player_shadow.z_index = -1
	player_shadow.visible = false
	add_child(player_shadow)

# --- Growing Vegetation Init (Phase 15b) ---
func _init_drain_thresholds() -> void:
	for i in range(SWAMP_COUNT):
		last_drain_thresholds.append(GameManager.get_swamp_fill_fraction(i))

func _spawn_drain_plant(sx: float, sy: float) -> void:
	var plant := Node2D.new()
	plant.position = Vector2(sx, sy)
	plant.z_index = 2
	plant.scale = Vector2(0.0, 0.0)
	add_child(plant)

	var plant_type: int = randi() % 3
	if plant_type == 0:
		# Small flower
		var stem := ColorRect.new()
		stem.size = Vector2(1, 5)
		stem.position = Vector2(0, -5)
		stem.color = Color(0.25, 0.55, 0.2)
		plant.add_child(stem)
		var petal_colors: Array[Color] = [Color(0.9, 0.3, 0.4), Color(0.9, 0.7, 0.2), Color(0.7, 0.3, 0.9), Color(0.3, 0.6, 0.9)]
		var petal := ColorRect.new()
		petal.size = Vector2(4, 3)
		petal.position = Vector2(-1.5, -8)
		petal.color = petal_colors[randi() % petal_colors.size()]
		plant.add_child(petal)
	elif plant_type == 1:
		# Grass tuft
		for j in range(3):
			var blade := ColorRect.new()
			blade.size = Vector2(1, randf_range(4, 7))
			blade.position = Vector2(-1 + j, -blade.size.y)
			blade.color = Color(0.3, 0.55 + randf_range(0, 0.1), 0.18)
			plant.add_child(blade)
	else:
		# Sapling
		var trunk := ColorRect.new()
		trunk.size = Vector2(2, 6)
		trunk.position = Vector2(-1, -6)
		trunk.color = Color(0.45, 0.3, 0.15)
		plant.add_child(trunk)
		var canopy := ColorRect.new()
		canopy.size = Vector2(6, 4)
		canopy.position = Vector2(-3, -10)
		canopy.color = Color(0.2, 0.5, 0.18)
		plant.add_child(canopy)

	# Sprout animation: grow from 0 to full
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(plant, "scale", Vector2(1.0, 1.0), 0.8)
	grown_plants.append({"node": plant})

# --- Post-Processing ---
func _build_post_processing() -> void:
	post_process_layer = CanvasLayer.new()
	post_process_layer.layer = 100
	add_child(post_process_layer)
	post_process_rect = ColorRect.new()
	post_process_rect.size = Vector2(320, 180)
	post_process_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = POST_PROCESS_SHADER
	post_process_rect.material = mat
	post_process_layer.add_child(post_process_rect)

# --- Day/Night Cycle & Animation ---
func _process(delta: float) -> void:
	# Continuous sell while player stands in pump area
	if player_in_pump_area and is_instance_valid(pump_player_ref):
		var earned: float = GameManager.sell_water()
		if earned > 0.01 and pump_player_ref.has_method("show_floating_text"):
			pump_player_ref.show_floating_text("+%s" % Economy.format_money(earned), Color(1.0, 0.85, 0.2))
			_spawn_pump_steam()
			_spawn_coin_fly(pump_player_ref.global_position)

	# Update camels
	if GameManager.camel_count > 0:
		_update_camels(delta)

	cycle_time += delta
	if cycle_time >= CYCLE_DURATION:
		cycle_time -= CYCLE_DURATION
		GameManager.current_day += 1
		GameManager.day_changed.emit(GameManager.current_day)

	var t: float = cycle_time / CYCLE_DURATION
	GameManager.cycle_progress = t
	var tint: Color = _get_cycle_color(t)
	canvas_modulate.color = tint

	# Update shader uniforms
	for wp in water_polygons:
		if wp.material:
			(wp.material as ShaderMaterial).set_shader_parameter("time", wave_time)
	# World progression: drain progress (used by multiple systems)
	var total_drained: float = 0.0
	var total_capacity: float = 0.0
	for si in range(SWAMP_COUNT):
		var cap: float = GameManager.swamp_definitions[si]["total_gallons"]
		total_capacity += cap
		total_drained += GameManager.swamp_states[si]["gallons_drained"]
	var drain_progress: float = total_drained / maxf(total_capacity, 1.0)

	if post_process_rect and post_process_rect.material:
		var pp_mat: ShaderMaterial = post_process_rect.material as ShaderMaterial
		pp_mat.set_shader_parameter("time", wave_time)
		# Heat shimmer: daytime only (disabled during rain)
		var shimmer: float = 0.0
		if weather_state != "rain":
			if t > 0.25 and t < 0.55:
				shimmer = 1.0
			elif t >= 0.2 and t <= 0.25:
				shimmer = (t - 0.2) / 0.05
			elif t >= 0.55 and t <= 0.6:
				shimmer = 1.0 - (t - 0.55) / 0.05
		pp_mat.set_shader_parameter("heat_shimmer_strength", shimmer)
		# Warm/cool color shift
		var warmth: float = 0.0
		if t >= 0.2 and t <= 0.5:
			warmth = 0.02
		elif t > 0.65 or t < 0.15:
			warmth = -0.02
		pp_mat.set_shader_parameter("warmth", warmth)
		pp_mat.set_shader_parameter("saturation", lerpf(0.75, 1.05, drain_progress))

	# Water glow pulse
	var glow_base_alpha: float = 0.08
	if t > 0.6 or t < 0.2:
		glow_base_alpha = 0.18
	var glow_pulse: float = glow_base_alpha + sin(wave_time * 1.2) * 0.04
	for gl in water_glow_lines:
		gl.default_color.a = glow_pulse

	# Weather system
	weather_timer += delta
	if weather_state == "clear":
		if weather_timer >= weather_duration:
			if randf() < 0.3:
				weather_state = "rain"
				weather_duration = randf_range(30.0, 60.0)
				weather_timer = 0.0
				rain_particles.emitting = true
				lightning_timer = randf_range(15.0, 45.0)
			else:
				weather_duration = randf_range(60.0, 120.0)
				weather_timer = 0.0
	elif weather_state == "rain":
		if weather_timer >= weather_duration:
			weather_state = "clear"
			weather_duration = randf_range(60.0, 120.0)
			weather_timer = 0.0
			rain_particles.emitting = false
		else:
			lightning_timer -= delta
			if lightning_timer <= 0.0:
				lightning_timer = randf_range(15.0, 45.0)
				_flash_lightning()
	if lightning_rect and lightning_rect.color.a > 0.0:
		lightning_rect.color.a = maxf(0.0, lightning_rect.color.a - delta * 3.0)

	# Wind direction shifts
	wind_timer += delta
	if wind_timer >= 8.0:
		wind_timer = 0.0
		wind_direction = lerpf(wind_direction, randf_range(-1.0, 1.0), 0.4)

	# Fern sway
	for fn in ferns_list:
		if is_instance_valid(fn):
			var sway: float = sin(wave_time * 0.8 + fn.position.x * 0.03) * 0.06 * wind_direction
			if weather_state == "rain":
				sway *= 2.0
			fn.rotation = sway

	# Drain-revealed objects
	for i in range(mini(drain_reveals.size(), SWAMP_COUNT)):
		var fill: float = GameManager.get_swamp_fill_fraction(i)
		for reveal in drain_reveals[i]:
			var show: bool = fill <= reveal["threshold"]
			for node in reveal["nodes"]:
				node.visible = show

	# Growing vegetation on drained land (Phase 15b)
	for i in range(mini(last_drain_thresholds.size(), SWAMP_COUNT)):
		var fill_now: float = GameManager.get_swamp_fill_fraction(i)
		var fill_prev: float = last_drain_thresholds[i]
		# Spawn plants when crossing 10% drain thresholds
		if fill_now < fill_prev - 0.05:
			last_drain_thresholds[i] = fill_now
			var geo: Dictionary = _get_swamp_geometry(i)
			var bx: float = randf_range(geo["basin_left"].x - 15, geo["basin_right"].x + 15)
			var by: float = _get_terrain_y_at(bx)
			if by < 0:
				by = geo["basin_left"].y
			if grown_plants.size() < 80:
				_spawn_drain_plant(bx, by)

	# Morning mist (dawn-specific, Phase 17b)
	var mist_alpha: float = 0.0
	if t >= 0.1 and t < 0.15:
		mist_alpha = (t - 0.1) / 0.05
	elif t >= 0.15 and t < 0.2:
		mist_alpha = lerpf(1.0, 0.0, (t - 0.15) / 0.05)
	for mr in morning_mist_rects:
		mr.color.a = mist_alpha * 0.12
		mr.position.x += delta * randf_range(3.0, 8.0)
		if mr.position.x > 2000:
			mr.position.x = -80.0

	# Aurora borealis (rare night event, Phase 17c)
	aurora_timer += delta
	if not aurora_active and (t > 0.75 or t < 0.1):
		if aurora_timer >= 30.0:
			aurora_timer = 0.0
			if randf() < 0.1:
				aurora_active = true
				aurora_fade = 0.0
	elif aurora_active:
		if t > 0.12 and t < 0.7:
			aurora_active = false
		else:
			aurora_fade = minf(aurora_fade + delta * 0.05, 1.0)
	if not aurora_active and aurora_fade > 0.0:
		aurora_fade = maxf(aurora_fade - delta * 0.05, 0.0)
	var cam_au: Camera2D = get_viewport().get_camera_2d() if get_viewport() else null
	var cam_x_au: float = cam_au.get_screen_center_position().x if cam_au else 320.0
	for al in aurora_lines:
		var aline: Line2D = al["line"]
		aline.clear_points()
		if aurora_fade > 0.01:
			for s in range(20):
				var ax: float = cam_x_au - 180.0 + s * 20.0
				var ay: float = al["base_y"] + sin(wave_time * al["speed"] + s * 0.5 + al["phase"]) * 6.0
				aline.add_point(Vector2(ax, ay))
			aline.default_color.a = aurora_fade * 0.3

	# Owl (nighttime perched, Phase 17d)
	if owl_node:
		var owl_vis: bool = t > 0.7 or t < 0.12
		owl_node.visible = owl_vis
		if owl_vis:
			owl_blink_timer -= delta
			if owl_blink_timer <= 0.0:
				owl_blink_timer = randf_range(3.0, 7.0)
				# Blink eyes
				var eyes: Array[Node] = []
				for ch in owl_node.get_children():
					if ch is ColorRect and ch.color.g > 0.8:
						eyes.append(ch)
				for eye in eyes:
					var orig_a: float = eye.color.a
					eye.color.a = 0.0
					var btw := create_tween()
					var e: ColorRect = eye as ColorRect
					btw.tween_interval(0.12)
					btw.tween_callback(func() -> void:
						if is_instance_valid(e): e.color.a = orig_a
					)

	# Pump station glow (Phase 11b)
	if pump_glow_rect:
		var pg_pulse: float = (sin(wave_time * 2.0) + 1.0) * 0.5
		if GameManager.pump_owned:
			pump_glow_rect.color.a = lerpf(0.05, 0.15, pg_pulse)
		else:
			pump_glow_rect.color.a = 0.0

	# Player shadow (Phase 13c)
	if player_shadow:
		var player_node: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player_node:
			# Shadow visible during day, stretch based on sun angle
			var shadow_vis: bool = t >= 0.15 and t <= 0.7
			player_shadow.visible = shadow_vis
			if shadow_vis:
				var sun_progress: float = (t - 0.15) / 0.55
				var shadow_len: float = lerpf(16.0, 6.0, sin(sun_progress * PI))
				var shadow_dir: float = lerpf(-1.0, 1.0, sun_progress)
				player_shadow.size = Vector2(shadow_len, 2)
				player_shadow.position = Vector2(
					player_node.global_position.x + shadow_dir * shadow_len * 0.3,
					player_node.global_position.y + 2
				)
				player_shadow.color.a = lerpf(0.1, 0.25, sin(sun_progress * PI))

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
			if i < water_glow_lines.size():
				water_glow_lines[i].clear_points()

	# Drift clouds slowly
	for ci in range(clouds.size()):
		clouds[ci].position.x += delta * (3.0 + ci * 0.5)
		if clouds[ci].position.x > 1960:
			clouds[ci].position.x = -80

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
		var fly_vis: float = fly_alpha * lerpf(0.2, 0.9, glow)
		node.color.a = fly_vis
		if fd.has("glow"):
			fd["glow"].color.a = fly_vis * 0.35

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
	# Bird spawn rate scales with world health (more drained = more birds)
	var bird_interval: float = lerpf(10.0, 4.0, drain_progress)
	if bird_timer >= bird_interval:
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

	# Fish: swim in water, contained within pool slopes
	for fd in fish:
		var fnode: Node2D = fd["node"]
		var swamp_i: int = fd["swamp"]
		var fill: float = GameManager.get_swamp_fill_fraction(swamp_i)
		var geo_f: Dictionary = _get_swamp_geometry(swamp_i)
		var entry_top_f: Vector2 = geo_f["entry_top"]
		var basin_left_f: Vector2 = geo_f["basin_left"]
		var basin_right_f: Vector2 = geo_f["basin_right"]
		var exit_top_f: Vector2 = geo_f["exit_top"]
		var basin_y_f: float = basin_left_f.y

		if fill < 0.02:
			if fd["alive"]:
				fd["alive"] = false
				fd["death_timer"] = 0.0
			fd["death_timer"] += delta
			fnode.visible = true
			fnode.position.y = basin_y_f - 2
			if fd["death_timer"] < 3.0:
				fnode.rotation = sin(fd["death_timer"] * 12.0) * 0.8
			else:
				fnode.rotation = PI * 0.5
				fnode.modulate.a = maxf(0.3, 1.0 - (fd["death_timer"] - 3.0) * 0.05)
			continue

		if fill < 0.15:
			fd["swim_speed"] = 2.5
		elif not fd["alive"]:
			fd["alive"] = true
			fnode.modulate.a = 1.0
			fnode.rotation = 0.0

		fnode.visible = true
		var overflow_y_f: float = maxf(entry_top_f.y, exit_top_f.y)
		var water_y_f: float = basin_y_f - fill * (basin_y_f - overflow_y_f)
		var surface_left_x: float = _lerp_x_at_y(entry_top_f, basin_left_f, water_y_f)
		var surface_right_x: float = _lerp_x_at_y(basin_right_f, exit_top_f, water_y_f)

		# Depth position
		var fish_y: float = lerpf(water_y_f + 4, basin_y_f - 4, fd["depth_offset"])
		fish_y += sin(fd["swim_phase"] * 0.7) * 2.0
		fish_y = clampf(fish_y, water_y_f + 2, basin_y_f - 2)

		# Calculate valid x range at this depth (respects pool slopes)
		var depth_frac: float = 0.0
		if absf(basin_y_f - water_y_f) > 0.1:
			depth_frac = clampf((fish_y - water_y_f) / (basin_y_f - water_y_f), 0.0, 1.0)
		var bound_left: float = lerpf(surface_left_x, basin_left_f.x, depth_frac) + 6.0
		var bound_right: float = lerpf(surface_right_x, basin_right_f.x, depth_frac) - 6.0

		# Swim horizontally within bounds
		fd["swim_phase"] += delta * fd["swim_speed"]
		var swim_x: float = fd["x"] + sin(fd["swim_phase"]) * fd["swim_range"]
		swim_x = clampf(swim_x, bound_left, bound_right)

		fnode.position = Vector2(swim_x, fish_y)
		var swim_dir: float = cos(fd["swim_phase"])
		fnode.scale.x = 1.0 if swim_dir > 0 else -1.0
		fnode.rotation = sin(fd["swim_phase"] * 2.0) * 0.1
		# Fish jump animation
		if fd["jumping"]:
			fd["jump_time"] += delta
			if fd["jump_time"] >= 0.6:
				fd["jumping"] = false
				fd["jump_time"] = 0.0
			else:
				var arc: float = sin(fd["jump_time"] / 0.6 * PI) * 14.0
				fnode.position.y -= arc
				fnode.rotation -= sin(fd["jump_time"] / 0.6 * PI) * 0.4
		else:
			fd["jump_timer"] -= delta
			if fd["jump_timer"] <= 0.0 and fd["alive"] and fill >= 0.15:
				fd["jumping"] = true
				fd["jump_time"] = 0.0
				fd["jump_timer"] = randf_range(12.0, 35.0)

	# Frogs: occasional hop animation
	for fg in frogs:
		var frog_node: Node2D = fg["node"]
		if not frog_node.get_parent().visible:
			continue
		if fg["hopping"]:
			fg["hop_progress"] += delta * 3.0
			if fg["hop_progress"] >= 1.0:
				fg["hopping"] = false
				fg["hop_progress"] = 0.0
				frog_node.position.y = fg["base_y"]
				fg["hop_timer"] = randf_range(4.0, 12.0)
			else:
				# Arc jump
				var hop_arc: float = sin(fg["hop_progress"] * PI) * -8.0
				frog_node.position.y = fg["base_y"] + hop_arc
		else:
			fg["hop_timer"] -= delta
			if fg["hop_timer"] <= 0.0:
				fg["hopping"] = true
				fg["hop_progress"] = 0.0
				fg["base_y"] = frog_node.position.y
		# Frog blink
		if fg.has("blink_timer"):
			fg["blink_timer"] -= delta
			if fg["blink_timer"] <= 0.0:
				fg["blink_timer"] = randf_range(2.0, 6.0)
				# Brief eye close
				if fg.has("eye_l") and is_instance_valid(fg["eye_l"]):
					var orig_color_l: Color = fg["eye_l"].color
					var orig_color_r: Color = fg["eye_r"].color
					fg["eye_l"].color = Color(0.2, 0.5, 0.15, 0.95)
					fg["eye_r"].color = Color(0.2, 0.5, 0.15, 0.95)
					var blink_tw := create_tween()
					var el: ColorRect = fg["eye_l"]
					var er: ColorRect = fg["eye_r"]
					blink_tw.tween_interval(0.1)
					blink_tw.tween_callback(func() -> void:
						if is_instance_valid(el): el.color = orig_color_l
						if is_instance_valid(er): er.color = orig_color_r
					)

	# Bioluminescent plants: glow at night
	var glow_alpha: float = 0.0
	if t > 0.6:
		glow_alpha = clampf((t - 0.6) / 0.08, 0.0, 1.0)
	elif t < 0.15:
		glow_alpha = 1.0
	elif t < 0.22:
		glow_alpha = clampf(1.0 - (t - 0.15) / 0.07, 0.0, 1.0)
	for gp in glow_plants:
		var pulse: float = (sin(wave_time * gp["pulse_speed"] + gp["phase"]) + 1.0) * 0.5
		var gc: Color = gp["glow_color"]
		var intensity: float = glow_alpha * lerpf(0.4, 1.0, pulse)
		gp["bulb"].color = Color(gc.r, gc.g, gc.b, intensity)
		gp["aura"].color = Color(gc.r, gc.g, gc.b, intensity * 0.25)

	# Seaweed sway underwater
	for sw in seaweed:
		var sw_swamp: int = sw["swamp"]
		var sw_fill: float = GameManager.get_swamp_fill_fraction(sw_swamp)
		sw["node"].visible = sw_fill > 0.05
		if sw["node"].visible:
			var sway_angle: float = sin(wave_time * sw["sway_speed"] + sw["phase"]) * 0.12
			sw["node"].rotation = sway_angle

	# Tadpoles: tiny swimmers contained in pools
	for tp in tadpoles:
		var tp_node: Node2D = tp["node"]
		var tp_swamp: int = tp["swamp"]
		var tp_fill: float = GameManager.get_swamp_fill_fraction(tp_swamp)
		if tp_fill < 0.05:
			tp_node.visible = false
			continue
		tp_node.visible = true
		var tp_geo: Dictionary = _get_swamp_geometry(tp_swamp)
		var tp_entry: Vector2 = tp_geo["entry_top"]
		var tp_bl: Vector2 = tp_geo["basin_left"]
		var tp_br: Vector2 = tp_geo["basin_right"]
		var tp_exit: Vector2 = tp_geo["exit_top"]
		var tp_basin_y: float = tp_bl.y
		var tp_overflow_y: float = maxf(tp_entry.y, tp_exit.y)
		var tp_water_y: float = tp_basin_y - tp_fill * (tp_basin_y - tp_overflow_y)
		var tp_y: float = lerpf(tp_water_y + 3, tp_basin_y - 2, tp["depth_offset"])
		tp["swim_phase"] += delta * tp["swim_speed"]
		var tp_depth_frac: float = 0.0
		if absf(tp_basin_y - tp_water_y) > 0.1:
			tp_depth_frac = clampf((tp_y - tp_water_y) / (tp_basin_y - tp_water_y), 0.0, 1.0)
		var tp_slx: float = _lerp_x_at_y(tp_entry, tp_bl, tp_water_y)
		var tp_srx: float = _lerp_x_at_y(tp_br, tp_exit, tp_water_y)
		var tp_bound_l: float = lerpf(tp_slx, tp_bl.x, tp_depth_frac) + 4.0
		var tp_bound_r: float = lerpf(tp_srx, tp_br.x, tp_depth_frac) - 4.0
		var tp_x: float = tp["x"] + sin(tp["swim_phase"]) * tp["swim_range"]
		tp_x = clampf(tp_x, tp_bound_l, tp_bound_r)
		tp_node.position = Vector2(tp_x, tp_y)
		tp_node.scale.x = 1.0 if cos(tp["swim_phase"]) > 0 else -1.0
		tp_node.rotation = sin(tp["swim_phase"] * 3.0) * 0.2

	# Water ripple rings
	ripple_timer += delta
	if ripple_timer >= 0.8:
		ripple_timer = 0.0
		var ri_swamp: int = randi() % SWAMP_COUNT
		var ri_fill: float = GameManager.get_swamp_fill_fraction(ri_swamp)
		if ri_fill > 0.05:
			var ri_geo: Dictionary = _get_swamp_geometry(ri_swamp)
			var ri_entry: Vector2 = ri_geo["entry_top"]
			var ri_bl: Vector2 = ri_geo["basin_left"]
			var ri_br: Vector2 = ri_geo["basin_right"]
			var ri_exit: Vector2 = ri_geo["exit_top"]
			var ri_basin_y: float = ri_bl.y
			var ri_overflow_y: float = maxf(ri_entry.y, ri_exit.y)
			var ri_water_y: float = ri_basin_y - ri_fill * (ri_basin_y - ri_overflow_y)
			var ri_left_x: float = _lerp_x_at_y(ri_entry, ri_bl, ri_water_y)
			var ri_right_x: float = _lerp_x_at_y(ri_br, ri_exit, ri_water_y)
			var ri_x: float = randf_range(ri_left_x + 8, ri_right_x - 8)
			_spawn_ripple(ri_x, ri_water_y)
	var ripples_to_remove: Array[int] = []
	for i in range(ripples.size()):
		var rd: Dictionary = ripples[i]
		rd["lifetime"] += delta
		if rd["lifetime"] > rd["max_life"]:
			ripples_to_remove.append(i)
			continue
		var rp_frac: float = rd["lifetime"] / rd["max_life"]
		var rp_line: Line2D = rd["node"]
		var rp_width: float = lerpf(2.0, rd["max_radius"], rp_frac)
		rp_line.clear_points()
		var rp_segs: int = 10
		for s in range(rp_segs + 1):
			var angle: float = float(s) / float(rp_segs) * PI
			rp_line.add_point(Vector2(rd["x"] + cos(angle) * rp_width, rd["y"] + sin(angle) * rp_width * 0.3))
		rp_line.default_color.a = (1.0 - rp_frac) * 0.4
	for i in range(ripples_to_remove.size() - 1, -1, -1):
		var idx: int = ripples_to_remove[i]
		ripples[idx]["node"].queue_free()
		ripples.remove_at(idx)

	# Butterflies: daytime only
	var bf_alpha: float = 0.0
	if t > 0.2 and t < 0.55:
		bf_alpha = 1.0
	elif t >= 0.15 and t <= 0.2:
		bf_alpha = (t - 0.15) / 0.05
	elif t >= 0.55 and t <= 0.65:
		bf_alpha = 1.0 - (t - 0.55) / 0.1
	butterfly_timer += delta
	var bf_max: int = int(lerpf(3.0, 10.0, drain_progress))
	if butterfly_timer >= 3.0 and bf_alpha > 0.1 and butterflies.size() < bf_max:
		butterfly_timer = 0.0
		_spawn_butterfly()
	var bf_to_remove: Array[int] = []
	for i in range(butterflies.size()):
		var bd: Dictionary = butterflies[i]
		bd["lifetime"] += delta
		if bd["lifetime"] > bd["max_life"]:
			bf_to_remove.append(i)
			continue
		var bf_node: Node2D = bd["node"]
		bd["phase"] += delta * bd["flutter_speed"]
		bf_node.position.x += bd["drift_x"] * delta
		bf_node.position.y = minf(bd["base_y"] + sin(bd["phase"] * 0.4) * bd["bob_amp"], 120.0)
		# Wing flap
		var wing_scale: float = absf(sin(bd["phase"]))
		bd["wing_l"].scale.x = wing_scale
		bd["wing_r"].scale.x = wing_scale
		var bf_life: float = bd["lifetime"] / bd["max_life"]
		var bf_fade: float = 1.0
		if bf_life < 0.1:
			bf_fade = bf_life / 0.1
		elif bf_life > 0.85:
			bf_fade = (1.0 - bf_life) / 0.15
		bf_node.modulate.a = bf_alpha * bf_fade
	for i in range(bf_to_remove.size() - 1, -1, -1):
		var idx: int = bf_to_remove[i]
		butterflies[idx]["node"].queue_free()
		butterflies.remove_at(idx)

	# Shooting stars at night
	var night_alpha: float = 0.0
	if t > 0.7:
		night_alpha = clampf((t - 0.7) / 0.05, 0.0, 1.0)
	elif t < 0.12:
		night_alpha = 1.0
	elif t < 0.17:
		night_alpha = clampf(1.0 - (t - 0.12) / 0.05, 0.0, 1.0)
	shooting_star_timer += delta
	if shooting_star_timer >= 6.0 and night_alpha > 0.5 and shooting_stars.size() < 2:
		shooting_star_timer = 0.0
		if randf() < 0.4:
			_spawn_shooting_star()
	var ss_to_remove: Array[int] = []
	for i in range(shooting_stars.size()):
		var sd: Dictionary = shooting_stars[i]
		sd["lifetime"] += delta
		if sd["lifetime"] > sd["max_life"]:
			ss_to_remove.append(i)
			continue
		var ss_line: Line2D = sd["line"]
		var ss_head: ColorRect = sd["head"]
		var ss_frac: float = sd["lifetime"] / sd["max_life"]
		var ss_x: float = sd["start_x"] + sd["speed_x"] * sd["lifetime"]
		var ss_y: float = sd["start_y"] + sd["speed_y"] * sd["lifetime"]
		ss_head.position = Vector2(ss_x, ss_y)
		ss_line.clear_points()
		var trail_len: int = 8
		for s in range(trail_len):
			var trail_t: float = float(s) / float(trail_len)
			ss_line.add_point(Vector2(
				ss_x - sd["speed_x"] * trail_t * 0.3,
				ss_y - sd["speed_y"] * trail_t * 0.3
			))
		var ss_fade: float = 1.0
		if ss_frac > 0.6:
			ss_fade = (1.0 - ss_frac) / 0.4
		ss_head.color.a = night_alpha * ss_fade
		ss_line.default_color.a = night_alpha * ss_fade * 0.6
	for i in range(ss_to_remove.size() - 1, -1, -1):
		var idx: int = ss_to_remove[i]
		shooting_stars[idx]["node"].queue_free()
		shooting_stars.remove_at(idx)

	# Turtle head bob
	for tt in turtles:
		var tt_head: ColorRect = tt["head_ref"]
		var head_bob: float = sin(wave_time * 0.8 + tt["phase"]) * 0.5
		tt_head.position.y += head_bob * 0.02

	# Cattail wind sway (enhanced with wind direction + rain)
	var rain_sway_mult: float = 2.0 if weather_state == "rain" else 1.0
	for ct in cattails:
		if is_instance_valid(ct):
			var sway: float = sin(wave_time * 1.2 + ct.position.x * 0.05) * 0.05 * wind_direction * rain_sway_mult
			ct.rotation = sway

func _get_cycle_color(t: float) -> Color:
	var pre_dawn := Color(0.35, 0.3, 0.55)
	var dawn := Color(1.0, 0.65, 0.45)
	var sunrise := Color(1.0, 0.85, 0.7)
	var noon := Color(1.0, 1.0, 1.0)
	var golden_hour := Color(1.0, 0.82, 0.55)
	var sunset := Color(0.95, 0.5, 0.35)
	var dusk := Color(0.65, 0.35, 0.5)
	var night := Color(0.28, 0.32, 0.58)

	if t < 0.1:
		return night.lerp(pre_dawn, t / 0.1)
	elif t < 0.17:
		return pre_dawn.lerp(dawn, (t - 0.1) / 0.07)
	elif t < 0.22:
		return dawn.lerp(sunrise, (t - 0.17) / 0.05)
	elif t < 0.3:
		return sunrise.lerp(noon, (t - 0.22) / 0.08)
	elif t < 0.5:
		return noon
	elif t < 0.55:
		return noon.lerp(golden_hour, (t - 0.5) / 0.05)
	elif t < 0.62:
		return golden_hour.lerp(sunset, (t - 0.55) / 0.07)
	elif t < 0.68:
		return sunset.lerp(dusk, (t - 0.62) / 0.06)
	elif t < 0.75:
		return dusk.lerp(night, (t - 0.68) / 0.07)
	else:
		return night
