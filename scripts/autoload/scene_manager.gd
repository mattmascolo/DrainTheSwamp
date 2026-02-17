extends Node

# --- State ---
var return_position: Vector2 = Vector2.ZERO
var return_scene_path: String = "res://scenes/main.tscn"
var is_transitioning: bool = false

# --- Visual nodes ---
var fade_layer: CanvasLayer = null
var fade_rect: ColorRect = null
var popup_layer: CanvasLayer = null
var cave_popup: PanelContainer = null
var popup_label: Label = null
var popup_close_btn: Button = null
var popup_timer: float = 0.0
var popup_auto_close: float = 0.0

func _ready() -> void:
	# Fade overlay — layer 100, full-screen black, starts transparent
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)

	# Popup layer — layer 90
	popup_layer = CanvasLayer.new()
	popup_layer.layer = 90
	add_child(popup_layer)
	_build_popup()

func _build_popup() -> void:
	cave_popup = PanelContainer.new()
	cave_popup.visible = false
	cave_popup.anchors_preset = Control.PRESET_CENTER_BOTTOM
	cave_popup.position = Vector2(160, 280)
	cave_popup.size = Vector2(320, 80)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.92)
	style.border_color = Color(0.6, 0.5, 0.3, 0.8)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	cave_popup.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	cave_popup.add_child(vbox)

	popup_label = Label.new()
	popup_label.text = ""
	popup_label.add_theme_font_size_override("font_size", 12)
	popup_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(popup_label)

	popup_close_btn = Button.new()
	popup_close_btn.text = "[Close]"
	popup_close_btn.add_theme_font_size_override("font_size", 10)
	popup_close_btn.flat = true
	popup_close_btn.pressed.connect(_close_popup)
	vbox.add_child(popup_close_btn)

	popup_layer.add_child(cave_popup)

	# Connect to GameManager signals
	GameManager.loot_collected.connect(_on_loot_collected)
	GameManager.swamp_completed.connect(_on_swamp_completed)

func _process(delta: float) -> void:
	if popup_auto_close > 0.0:
		popup_timer += delta
		if popup_timer >= popup_auto_close:
			_close_popup()

	if Input.is_action_just_pressed("ui_cancel") and cave_popup.visible:
		_close_popup()

func show_popup(text: String, auto_close_time: float = 0.0) -> void:
	popup_label.text = text
	cave_popup.visible = true
	popup_timer = 0.0
	popup_auto_close = auto_close_time
	# Center horizontally
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	cave_popup.position = Vector2((vp_size.x - 320) * 0.5, vp_size.y - 100)

func _close_popup() -> void:
	cave_popup.visible = false
	popup_auto_close = 0.0

func _on_loot_collected(_cave_id: String, _loot_id: String, reward_text: String) -> void:
	show_popup(reward_text, 3.0)

func _on_swamp_completed(swamp_index: int, _reward: float) -> void:
	if swamp_index == 2:
		show_popup("A stray camel wanders out of the drained marsh!\nCamel now available in the Shop.", 5.0)

# --- Scene Transitions ---
func transition_to_scene(scene_path: String, use_pixelate: bool = false) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	if use_pixelate:
		_pixelate_out(func() -> void: _do_scene_change(scene_path))
	else:
		var tw := create_tween()
		tw.tween_property(fade_rect, "color:a", 1.0, 0.4)
		tw.tween_callback(_do_scene_change.bind(scene_path))

func _do_scene_change(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
	# Fade in after one frame (let new scene _ready run)
	await get_tree().process_frame
	_fade_in()

func transition_to_return() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_pixelate_out(func() -> void: _do_scene_change(return_scene_path))

func fade_in() -> void:
	_fade_in()

func _fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: is_transitioning = false)

func _pixelate_out(on_complete: Callable) -> void:
	# Quick fade with brief white flash, then black
	var tw := create_tween()
	fade_rect.color = Color(1, 1, 1, 0)
	tw.tween_property(fade_rect, "color:a", 0.7, 0.1)
	tw.tween_callback(func() -> void: fade_rect.color = Color(0, 0, 0, 0.7))
	tw.tween_property(fade_rect, "color:a", 1.0, 0.2)
	tw.tween_callback(func() -> void: on_complete.call())

func flash_white(duration: float = 0.15) -> void:
	# Brief white flash for celebrations (pool completion, etc.)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.6)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, duration)
	tw.tween_callback(flash.queue_free)
