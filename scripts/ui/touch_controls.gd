extends CanvasLayer

var enabled: bool = false
var _left_pressed: bool = false
var _right_pressed: bool = false
var _scoop_pressed: bool = false
var _cancel_scoop_this_frame: bool = false

var left_btn: TouchScreenButton
var right_btn: TouchScreenButton
var scoop_btn: TouchScreenButton

var _container: Control

const LEFT_SIZE := Vector2(50, 50)
const RIGHT_SIZE := Vector2(50, 50)
const SCOOP_SIZE := Vector2(72, 72)

func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Run physics before player (default 0) so we can cancel spurious scoops
	process_physics_priority = -1

	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)

	left_btn = _create_button("<", LEFT_SIZE, 20)
	right_btn = _create_button(">", RIGHT_SIZE, 20)
	scoop_btn = _create_button("SCOOP", SCOOP_SIZE, 14)

	# Viewport is 640x360, position above bottom bar
	left_btn.position = Vector2(8, 260)
	right_btn.position = Vector2(66, 260)
	scoop_btn.position = Vector2(560, 248)

	_container.add_child(left_btn)
	_container.add_child(right_btn)
	_container.add_child(scoop_btn)

	# Auto-detect touchscreen on first run
	if not GameManager.touch_controls_enabled:
		if DisplayServer.is_touchscreen_available():
			GameManager.touch_controls_enabled = true

	# Apply initial state
	if GameManager.touch_controls_enabled:
		_activate()
	else:
		_deactivate()

func _create_button(text: String, btn_size: Vector2, font_size: int) -> TouchScreenButton:
	var btn := TouchScreenButton.new()

	var img := Image.create(int(btn_size.x), int(btn_size.y), false, Image.FORMAT_RGBA8)
	var bg_color := Color(0.15, 0.2, 0.25, 0.45)
	var border_color := Color(0.4, 0.5, 0.6, 0.5)

	img.fill(bg_color)
	for x in range(int(btn_size.x)):
		for y in range(2):
			img.set_pixel(x, y, border_color)
			img.set_pixel(x, int(btn_size.y) - 1 - y, border_color)
	for y in range(int(btn_size.y)):
		for x in range(2):
			img.set_pixel(x, y, border_color)
			img.set_pixel(int(btn_size.x) - 1 - x, y, border_color)

	btn.texture_normal = ImageTexture.create_from_image(img)

	var img_pressed := Image.create(int(btn_size.x), int(btn_size.y), false, Image.FORMAT_RGBA8)
	img_pressed.fill(Color(0.25, 0.35, 0.45, 0.6))
	for x in range(int(btn_size.x)):
		for y in range(2):
			img_pressed.set_pixel(x, y, Color(0.5, 0.65, 0.8, 0.7))
			img_pressed.set_pixel(x, int(btn_size.y) - 1 - y, Color(0.5, 0.65, 0.8, 0.7))
	for y in range(int(btn_size.y)):
		for x in range(2):
			img_pressed.set_pixel(x, y, Color(0.5, 0.65, 0.8, 0.7))
			img_pressed.set_pixel(int(btn_size.x) - 1 - x, y, Color(0.5, 0.65, 0.8, 0.7))
	btn.texture_pressed = ImageTexture.create_from_image(img_pressed)

	btn.passby_press = true

	# Label inside a Control wrapper so alignment works
	# (TouchScreenButton is Node2D — anchors don't work on direct children)
	var label_wrap := Control.new()
	label_wrap.position = Vector2.ZERO
	label_wrap.size = btn_size
	label_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = text
	label.position = Vector2.ZERO
	label.size = btn_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.8))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_wrap.add_child(label)
	btn.add_child(label_wrap)

	btn.pressed.connect(_on_button_pressed.bind(text))
	btn.released.connect(_on_button_released.bind(text))

	return btn

func _on_button_pressed(which: String) -> void:
	match which:
		"<":
			if not _left_pressed:
				_left_pressed = true
				Input.action_press("move_left")
		">":
			if not _right_pressed:
				_right_pressed = true
				Input.action_press("move_right")
		"SCOOP":
			if not _scoop_pressed:
				_scoop_pressed = true
				Input.action_press("scoop")

func _on_button_released(which: String) -> void:
	match which:
		"<":
			if _left_pressed:
				_left_pressed = false
				Input.action_release("move_left")
		">":
			if _right_pressed:
				_right_pressed = false
				Input.action_release("move_right")
		"SCOOP":
			if _scoop_pressed:
				_scoop_pressed = false
				Input.action_release("scoop")

func _input(event: InputEvent) -> void:
	if not enabled or not _container.visible:
		return
	# When a touch lands on an arrow button, the emulated mouse click also
	# triggers scoop. Flag it so _physics_process can cancel before player sees it.
	if event is InputEventScreenTouch and event.pressed:
		if _point_on_arrow(event.position):
			_cancel_scoop_this_frame = true

func _physics_process(_delta: float) -> void:
	# Runs before player (priority -1 vs 0) to cancel spurious scoops
	if _cancel_scoop_this_frame:
		_cancel_scoop_this_frame = false
		# Only cancel if scoop wasn't intentionally pressed via SCOOP button
		if not _scoop_pressed:
			Input.action_release("scoop")

func _point_on_arrow(pos: Vector2) -> bool:
	var left_rect := Rect2(left_btn.position, LEFT_SIZE)
	var right_rect := Rect2(right_btn.position, RIGHT_SIZE)
	return left_rect.has_point(pos) or right_rect.has_point(pos)

func _process(_delta: float) -> void:
	if not enabled:
		return
	var player: Node = _get_player()
	var should_show: bool = player != null and not player.ui_panel_open
	if _container.visible != should_show:
		_container.visible = should_show
		if not should_show:
			_release_all()

func _get_player() -> Node:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _release_all() -> void:
	if _left_pressed:
		_left_pressed = false
		Input.action_release("move_left")
	if _right_pressed:
		_right_pressed = false
		Input.action_release("move_right")
	if _scoop_pressed:
		_scoop_pressed = false
		Input.action_release("scoop")

func set_enabled(value: bool) -> void:
	if value:
		_activate()
	else:
		_deactivate()

func _activate() -> void:
	enabled = true
	_container.visible = true

func _deactivate() -> void:
	enabled = false
	_container.visible = false
	_release_all()
