extends Node2D

# Day/Night cycle - 5 minute real-time cycle (300 seconds)
const CYCLE_DURATION: float = 300.0

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
var cycle_time: float = 0.0

# Terrain: array of Vector2 points defining the ground surface
# Pattern per swamp: entry_slope_top, basin_left, basin_right, exit_slope_top
# Plus initial left shore and final right shore
var terrain_points: Array[Vector2] = [
	Vector2(0, 68), Vector2(40, 68),            # Left shore (high, pump here)
	Vector2(60, 80), Vector2(85, 80),           # Puddle basin (shallow, depth 12)
	Vector2(105, 72), Vector2(135, 74),         # Ridge 1 (slopes down)
	Vector2(175, 100), Vector2(225, 100),       # Pond basin (depth 26)
	Vector2(260, 82), Vector2(295, 86),         # Ridge 2 (slopes down)
	Vector2(345, 120), Vector2(405, 120),       # Marsh basin (depth 34)
	Vector2(445, 98), Vector2(480, 102),        # Ridge 3 (slopes down)
	Vector2(530, 142), Vector2(600, 142),       # Bog basin (depth 40)
	Vector2(645, 115), Vector2(680, 120),       # Ridge 4 (slopes down)
	Vector2(740, 165), Vector2(830, 165),       # Deep Swamp basin (depth 45)
	Vector2(880, 140), Vector2(960, 145),       # Right shore (lowest)
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

	GameManager.water_level_changed.connect(_on_water_level_changed)
	GameManager.swamp_completed.connect(_on_swamp_completed)

# --- Sky & Atmosphere ---
func _build_sky() -> void:
	# Three-band sky gradient
	var sky_top := ColorRect.new()
	sky_top.position = Vector2(-50, -40)
	sky_top.size = Vector2(1060, 50)
	sky_top.color = SKY_COLOR_TOP
	sky_top.z_index = -12
	add_child(sky_top)

	var sky_mid := ColorRect.new()
	sky_mid.position = Vector2(-50, 10)
	sky_mid.size = Vector2(1060, 40)
	sky_mid.color = SKY_COLOR_MID
	sky_mid.z_index = -12
	add_child(sky_mid)

	var sky_bot := ColorRect.new()
	sky_bot.position = Vector2(-50, 48)
	sky_bot.size = Vector2(1060, 50)
	sky_bot.color = SKY_COLOR_BOTTOM
	sky_bot.z_index = -12
	add_child(sky_bot)

	# Sun with glow
	var sun_glow := ColorRect.new()
	sun_glow.position = Vector2(194, 8)
	sun_glow.size = Vector2(24, 24)
	sun_glow.color = Color(1, 0.95, 0.6, 0.15)
	sun_glow.z_index = -11
	add_child(sun_glow)

	var sun := ColorRect.new()
	sun.position = Vector2(200, 14)
	sun.size = Vector2(12, 12)
	sun.color = Color(1, 0.95, 0.55)
	sun.z_index = -10
	add_child(sun)

	var sun_core := ColorRect.new()
	sun_core.position = Vector2(203, 17)
	sun_core.size = Vector2(6, 6)
	sun_core.color = Color(1, 1, 0.85)
	sun_core.z_index = -9
	add_child(sun_core)

func _build_clouds() -> void:
	var cloud_data: Array = [
		{"x": 50, "y": 5, "w": 28, "h": 8},
		{"x": 180, "y": 18, "w": 20, "h": 6},
		{"x": 350, "y": 2, "w": 35, "h": 9},
		{"x": 520, "y": 12, "w": 24, "h": 7},
		{"x": 700, "y": 6, "w": 30, "h": 8},
		{"x": 850, "y": 15, "w": 22, "h": 6},
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
		puff_l.position = Vector2(cd["x"] - 4, cd["y"] + 2)
		puff_l.size = Vector2(8, cd["h"] - 2)
		puff_l.color = Color(0.88, 0.92, 0.96, 0.5)
		cloud_group.add_child(puff_l)

		# Cloud puff right
		var puff_r := ColorRect.new()
		puff_r.position = Vector2(cd["x"] + cd["w"] - 4, cd["y"] + 2)
		puff_r.size = Vector2(8, cd["h"] - 2)
		puff_r.color = Color(0.88, 0.92, 0.96, 0.5)
		cloud_group.add_child(puff_r)

		# Cloud highlight top
		var highlight := ColorRect.new()
		highlight.position = Vector2(cd["x"] + 3, cd["y"] - 2)
		highlight.size = Vector2(cd["w"] - 6, 3)
		highlight.color = Color(0.96, 0.97, 1.0, 0.5)
		cloud_group.add_child(highlight)

		clouds.append(main)

func _build_distant_hills() -> void:
	# Far hills silhouette
	var hills := Polygon2D.new()
	hills.polygon = PackedVector2Array([
		Vector2(-50, 62), Vector2(60, 50), Vector2(150, 55),
		Vector2(250, 45), Vector2(380, 52), Vector2(500, 48),
		Vector2(620, 55), Vector2(750, 42), Vector2(880, 50),
		Vector2(960, 58), Vector2(960, 75), Vector2(-50, 75)
	])
	hills.color = Color(0.12, 0.28, 0.12, 0.6)
	hills.z_index = -7
	add_child(hills)

	# Mid hills
	var hills2 := Polygon2D.new()
	hills2.polygon = PackedVector2Array([
		Vector2(-50, 65), Vector2(100, 55), Vector2(200, 60),
		Vector2(320, 52), Vector2(450, 58), Vector2(580, 53),
		Vector2(700, 60), Vector2(830, 54), Vector2(960, 62),
		Vector2(960, 78), Vector2(-50, 78)
	])
	hills2.color = Color(0.08, 0.22, 0.08, 0.7)
	hills2.z_index = -6
	add_child(hills2)

func _build_treeline() -> void:
	# Dense treeline - jagged top edge for tree canopy look
	var tree_points := PackedVector2Array()
	var x: float = -50.0
	while x < 1010.0:
		var tree_h: float = randf_range(6, 14)
		tree_points.append(Vector2(x, 68 - tree_h))
		tree_points.append(Vector2(x + randf_range(3, 8), 68 - tree_h + randf_range(2, 5)))
		x += randf_range(5, 12)
	tree_points.append(Vector2(1010, 68))
	tree_points.append(Vector2(1010, 82))
	tree_points.append(Vector2(-50, 82))

	var treeline := Polygon2D.new()
	treeline.polygon = tree_points
	treeline.color = Color(0.06, 0.18, 0.05)
	treeline.z_index = -5
	add_child(treeline)

	# Lighter highlight trees in front
	var tree_points2 := PackedVector2Array()
	x = -50.0
	while x < 1010.0:
		var tree_h: float = randf_range(4, 10)
		tree_points2.append(Vector2(x, 70 - tree_h))
		tree_points2.append(Vector2(x + randf_range(3, 6), 70 - tree_h + randf_range(2, 4)))
		x += randf_range(6, 14)
	tree_points2.append(Vector2(1010, 70))
	tree_points2.append(Vector2(1010, 82))
	tree_points2.append(Vector2(-50, 82))

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
	ground_points.append(Vector2(terrain_points[-1].x, 240))
	ground_points.append(Vector2(terrain_points[0].x, 240))
	terrain_polygon.polygon = ground_points
	terrain_polygon.color = GROUND_COLOR
	terrain_polygon.z_index = 0
	add_child(terrain_polygon)

	# Mid soil layer
	var midsoil := Polygon2D.new()
	var mid_points: PackedVector2Array = PackedVector2Array()
	for pt in terrain_points:
		mid_points.append(Vector2(pt.x, pt.y + 5))
	mid_points.append(Vector2(terrain_points[-1].x, 240))
	mid_points.append(Vector2(terrain_points[0].x, 240))
	midsoil.polygon = mid_points
	midsoil.color = GROUND_MID_COLOR
	midsoil.z_index = -1
	add_child(midsoil)

	# Dark subsoil layer
	var subsoil := Polygon2D.new()
	var sub_points: PackedVector2Array = PackedVector2Array()
	for pt in terrain_points:
		sub_points.append(Vector2(pt.x, pt.y + 12))
	sub_points.append(Vector2(terrain_points[-1].x, 240))
	sub_points.append(Vector2(terrain_points[0].x, 240))
	subsoil.polygon = sub_points
	subsoil.color = GROUND_DARK_COLOR
	subsoil.z_index = -2
	add_child(subsoil)

	# Grass strip on top of terrain - two layers for depth
	var grass_dark := Line2D.new()
	grass_dark.width = 3.0
	grass_dark.default_color = GRASS_COLOR
	for pt in terrain_points:
		grass_dark.add_point(pt)
	grass_dark.z_index = 1
	add_child(grass_dark)

	var grass_light := Line2D.new()
	grass_light.width = 1.5
	grass_light.default_color = GRASS_LIGHT_COLOR
	for pt in terrain_points:
		grass_light.add_point(Vector2(pt.x, pt.y - 0.5))
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
	lw_shape.a = Vector2(-10, -50)
	lw_shape.b = Vector2(-10, 240)
	left_wall.shape = lw_shape
	terrain_body.add_child(left_wall)

	# Right wall
	var right_wall := CollisionShape2D.new()
	var rw_shape := SegmentShape2D.new()
	rw_shape.a = Vector2(970, -50)
	rw_shape.b = Vector2(970, 240)
	right_wall.shape = rw_shape
	terrain_body.add_child(right_wall)

func _build_terrain_details() -> void:
	# Rocks scattered on ridges and shores
	var rock_positions: Array[Vector2] = [
		Vector2(15, 67), Vector2(32, 67),
		Vector2(110, 71), Vector2(120, 71),
		Vector2(265, 81), Vector2(285, 85),
		Vector2(455, 97), Vector2(470, 101),
		Vector2(655, 114), Vector2(675, 119),
		Vector2(895, 139), Vector2(940, 144),
	]
	for rp in rock_positions:
		_place_rock(rp, randf_range(2, 5), randf_range(2, 4))

	# Dirt specks on terrain surface
	for i in range(40):
		var rx: float = randf_range(0, 960)
		var ry: float = _get_terrain_y_at(rx)
		if ry > 0:
			var speck := ColorRect.new()
			speck.position = Vector2(rx, ry + randf_range(1, 6))
			speck.size = Vector2(randf_range(1, 3), randf_range(1, 2))
			speck.color = GROUND_DARK_COLOR.lerp(GROUND_COLOR, randf_range(0, 1))
			speck.color.a = randf_range(0.3, 0.6)
			speck.z_index = 0
			add_child(speck)

func _place_rock(pos: Vector2, w: float, h: float) -> void:
	var rock := Polygon2D.new()
	rock.polygon = PackedVector2Array([
		Vector2(pos.x + 1, pos.y),
		Vector2(pos.x + w - 1, pos.y),
		Vector2(pos.x + w, pos.y + h * 0.4),
		Vector2(pos.x + w - 0.5, pos.y + h),
		Vector2(pos.x + 0.5, pos.y + h),
		Vector2(pos.x, pos.y + h * 0.4),
	])
	rock.color = ROCK_COLOR
	rock.z_index = 1
	add_child(rock)

	# Rock highlight
	var hl := ColorRect.new()
	hl.position = Vector2(pos.x + 1, pos.y + 0.5)
	hl.size = Vector2(w - 2, 1)
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
			var cx: float = entry_top.x + randf_range(-5, 8)
			var cy: float = entry_top.y + randf_range(-2, 3)
			_place_cattail(Vector2(cx, cy))

		# Place cattails near exit slope
		for j in range(randi_range(1, 3)):
			var cx: float = exit_top.x + randf_range(-8, 5)
			var cy: float = exit_top.y + randf_range(-2, 3)
			_place_cattail(Vector2(cx, cy))

	# Grass tufts on ridges
	for i in range(terrain_points.size()):
		var pt: Vector2 = terrain_points[i]
		# Only on relatively flat areas (ridges, shores)
		if i > 0 and i < terrain_points.size() - 1:
			var dy: float = absf(terrain_points[i + 1].y - pt.y) / absf(terrain_points[i + 1].x - pt.x + 0.01)
			if dy < 0.3:  # Mostly flat
				for j in range(randi_range(2, 5)):
					var gx: float = pt.x + randf_range(-10, 10)
					_place_grass_tuft(Vector2(gx, _get_terrain_y_at(gx)))

	# Flowers scattered on shore and ridges
	var flower_colors: Array[Color] = [
		Color(0.9, 0.3, 0.3), Color(0.9, 0.85, 0.2),
		Color(0.8, 0.4, 0.7), Color(0.95, 0.95, 0.9)
	]
	for i in range(12):
		var fx: float = randf_range(5, 950)
		var fy: float = _get_terrain_y_at(fx)
		if fy > 0:
			var flower := ColorRect.new()
			flower.position = Vector2(fx, fy - randf_range(2, 4))
			flower.size = Vector2(2, 2)
			flower.color = flower_colors[randi() % flower_colors.size()]
			flower.z_index = 1
			add_child(flower)

			var stem := ColorRect.new()
			stem.position = Vector2(fx + 0.5, fy - 1)
			stem.size = Vector2(1, 2)
			stem.color = Color(0.2, 0.4, 0.15)
			stem.z_index = 1
			add_child(stem)

func _place_cattail(pos: Vector2) -> void:
	var cattail := Node2D.new()
	cattail.z_index = 3
	add_child(cattail)

	# Stem
	var stem_h: float = randf_range(8, 14)
	var stem := Line2D.new()
	stem.width = 1.0
	stem.default_color = Color(0.3, 0.45, 0.2)
	stem.add_point(Vector2(pos.x, pos.y))
	stem.add_point(Vector2(pos.x + randf_range(-1, 1), pos.y - stem_h))
	cattail.add_child(stem)

	# Cattail head (brown oval)
	var head := ColorRect.new()
	head.position = Vector2(pos.x - 1, pos.y - stem_h - 3)
	head.size = Vector2(2, 4)
	head.color = Color(0.45, 0.3, 0.15)
	cattail.add_child(head)

	# Leaf
	var leaf := Line2D.new()
	leaf.width = 1.0
	leaf.default_color = Color(0.25, 0.4, 0.18, 0.8)
	leaf.add_point(Vector2(pos.x, pos.y - stem_h * 0.4))
	leaf.add_point(Vector2(pos.x + randf_range(3, 6), pos.y - stem_h * 0.6))
	cattail.add_child(leaf)

	cattails.append(cattail)

func _place_grass_tuft(pos: Vector2) -> void:
	for k in range(randi_range(2, 4)):
		var blade := Line2D.new()
		blade.width = 0.8
		blade.default_color = GRASS_COLOR.lerp(GRASS_LIGHT_COLOR, randf())
		blade.default_color.a = randf_range(0.6, 1.0)
		var blade_h: float = randf_range(3, 6)
		var blade_lean: float = randf_range(-2, 2)
		blade.add_point(pos)
		blade.add_point(Vector2(pos.x + blade_lean, pos.y - blade_h))
		blade.z_index = 1
		add_child(blade)

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
		wl.width = 1.5
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
	var segments: int = int((right_x - left_x) / 3.0)
	segments = maxi(segments, 4)
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var px: float = lerpf(left_x, right_x, t)
		var wave_offset: float = sin(wave_time * 2.0 + px * 0.15) * 0.8
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
		left_rect.size = Vector2(4, 28)
		left_col.shape = left_rect
		left_body.add_child(left_col)
		add_child(left_body)

		var right_body := StaticBody2D.new()
		var right_col := CollisionShape2D.new()
		var right_rect := RectangleShape2D.new()
		right_rect.size = Vector2(4, 28)
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

	left_body.position = Vector2(left_x, water_y - 14)
	right_body.position = Vector2(right_x, water_y - 14)

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
		entry_rect.size = Vector2((basin_left - entry_top).length(), 20)
		entry_shape.shape = entry_rect
		entry_shape.position = entry_mid + Vector2(0, -5)
		entry_shape.rotation = atan2(basin_left.y - entry_top.y, basin_left.x - entry_top.x)
		area.add_child(entry_shape)

		# Basin floor detection
		var basin_mid: Vector2 = (basin_left + basin_right) * 0.5
		var basin_shape := CollisionShape2D.new()
		var basin_rect := RectangleShape2D.new()
		basin_rect.size = Vector2(basin_right.x - basin_left.x, 16)
		basin_shape.shape = basin_rect
		basin_shape.position = basin_mid + Vector2(0, -6)
		area.add_child(basin_shape)

		# Exit slope detection
		var exit_mid: Vector2 = (basin_right + exit_top) * 0.5
		var exit_shape := CollisionShape2D.new()
		var exit_rect := RectangleShape2D.new()
		exit_rect.size = Vector2((exit_top - basin_right).length(), 20)
		exit_shape.shape = exit_rect
		exit_shape.position = exit_mid + Vector2(0, -5)
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
		var label_y: float = geo["entry_top"].y - 12

		var label := Label.new()
		label.text = GameManager.swamp_definitions[i]["name"]
		label.add_theme_font_size_override("font_size", 6)
		label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.7))
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.position = Vector2(basin_mid_x - 15, label_y)
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

func _on_swamp_completed(swamp_index: int, _reward: float) -> void:
	if swamp_index >= 0 and swamp_index < swamp_labels.size():
		swamp_labels[swamp_index].add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 0.9))
		swamp_labels[swamp_index].text = GameManager.swamp_definitions[swamp_index]["name"] + " [DONE]"

# --- Pump Station ---
func _build_pump_station() -> void:
	# Platform/base
	var platform := ColorRect.new()
	platform.position = Vector2(3, 65)
	platform.size = Vector2(22, 3)
	platform.color = Color(0.4, 0.38, 0.36)
	platform.z_index = 2
	add_child(platform)

	# Pump body - main housing
	var pump_body := ColorRect.new()
	pump_body.position = Vector2(6, 50)
	pump_body.size = Vector2(14, 15)
	pump_body.color = Color(0.5, 0.5, 0.55)
	pump_body.z_index = 3
	add_child(pump_body)

	# Pump body highlight
	var pump_hl := ColorRect.new()
	pump_hl.position = Vector2(7, 51)
	pump_hl.size = Vector2(4, 13)
	pump_hl.color = Color(0.58, 0.58, 0.62)
	pump_hl.z_index = 3
	add_child(pump_hl)

	# Pump top cap
	var pump_cap := ColorRect.new()
	pump_cap.position = Vector2(5, 48)
	pump_cap.size = Vector2(16, 3)
	pump_cap.color = Color(0.42, 0.42, 0.46)
	pump_cap.z_index = 3
	add_child(pump_cap)

	# Pipe extending right
	var pump_pipe := ColorRect.new()
	pump_pipe.position = Vector2(20, 56)
	pump_pipe.size = Vector2(10, 3)
	pump_pipe.color = Color(0.4, 0.4, 0.45)
	pump_pipe.z_index = 3
	add_child(pump_pipe)

	# Pipe joint
	var pipe_joint := ColorRect.new()
	pipe_joint.position = Vector2(19, 55)
	pipe_joint.size = Vector2(3, 5)
	pipe_joint.color = Color(0.45, 0.45, 0.5)
	pipe_joint.z_index = 3
	add_child(pipe_joint)

	# Indicator light
	var pump_light := ColorRect.new()
	pump_light.position = Vector2(10, 52)
	pump_light.size = Vector2(3, 3)
	pump_light.color = Color(0.2, 0.85, 0.3)
	pump_light.z_index = 4
	add_child(pump_light)

	# Gauge (small circle-ish)
	var gauge := ColorRect.new()
	gauge.position = Vector2(14, 55)
	gauge.size = Vector2(4, 4)
	gauge.color = Color(0.15, 0.15, 0.2)
	gauge.z_index = 4
	add_child(gauge)
	var gauge_needle := ColorRect.new()
	gauge_needle.position = Vector2(15, 55.5)
	gauge_needle.size = Vector2(2, 1)
	gauge_needle.color = Color(0.9, 0.3, 0.2)
	gauge_needle.z_index = 4
	add_child(gauge_needle)

	# Label
	var pump_lbl := Label.new()
	pump_lbl.text = "PUMP"
	pump_lbl.add_theme_font_size_override("font_size", 5)
	pump_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 0.8))
	pump_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	pump_lbl.add_theme_constant_override("shadow_offset_x", 1)
	pump_lbl.add_theme_constant_override("shadow_offset_y", 1)
	pump_lbl.position = Vector2(5, 40)
	pump_lbl.z_index = 5
	add_child(pump_lbl)

	# "SELL" indicator
	var sell_lbl := Label.new()
	sell_lbl.text = "SELL"
	sell_lbl.add_theme_font_size_override("font_size", 5)
	sell_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 0.7))
	sell_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	sell_lbl.add_theme_constant_override("shadow_offset_x", 1)
	sell_lbl.add_theme_constant_override("shadow_offset_y", 1)
	sell_lbl.position = Vector2(7, 46)
	sell_lbl.z_index = 5
	add_child(sell_lbl)

	# Detection area for player interaction
	var pump_area := Area2D.new()
	pump_area.collision_layer = 0
	pump_area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 26)
	shape.shape = rect
	shape.position = Vector2(15, 56)
	pump_area.add_child(shape)
	add_child(pump_area)

	pump_area.body_entered.connect(_on_pump_body_entered)
	pump_area.body_exited.connect(_on_pump_body_exited)

func _on_pump_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("set_near_pump"):
		body.set_near_pump(true)
		var earned: float = GameManager.sell_water()
		if earned > 0.01 and body.has_method("show_floating_text"):
			body.show_floating_text("+%s" % Economy.format_money(earned), Color(1.0, 0.85, 0.2))

func _on_pump_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("set_near_pump"):
		body.set_near_pump(false)

# --- Day/Night Cycle & Animation ---
func _process(delta: float) -> void:
	cycle_time += delta
	if cycle_time >= CYCLE_DURATION:
		cycle_time -= CYCLE_DURATION

	var t: float = cycle_time / CYCLE_DURATION
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

	# Drift clouds slowly
	for ci in range(clouds.size()):
		clouds[ci].position.x += delta * (3.0 + ci * 0.5)
		if clouds[ci].position.x > 980:
			clouds[ci].position.x = -40
			# Also move parent cloud group's other children
			var parent_node: Node2D = clouds[ci].get_parent()
			for child in parent_node.get_children():
				if child != clouds[ci]:
					child.position.x -= 1020

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
