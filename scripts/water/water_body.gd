extends ColorRect

@export var basin_bottom_y: float = 326.0
@export var basin_top_y: float = 200.0
var full_height: float = 126.0

# Color shifts: murky when full, clearer when low
var color_full := Color(0.2, 0.32, 0.12, 0.92)
var color_empty := Color(0.25, 0.5, 0.4, 0.7)

func _ready() -> void:
	full_height = basin_bottom_y - basin_top_y
	GameManager.water_level_changed.connect(_on_water_level_changed)
	_on_water_level_changed(GameManager.get_water_percent())

func _on_water_level_changed(percent: float) -> void:
	var frac: float = percent / 100.0
	var water_height: float = full_height * frac
	size.y = water_height
	position.y = basin_bottom_y - water_height
	color = color_full.lerp(color_empty, 1.0 - frac)
