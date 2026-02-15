extends CharacterBody2D

const BASE_SPEED: float = 120.0
const GRAVITY: float = 800.0
const SCOOP_COOLDOWN: float = 0.3
const STAMINA_REGEN_DELAY_TIME: float = 0.0

signal pump_requested()

var near_water: bool = false
var near_swamp_index: int = -1
var near_pump: bool = false
var scoop_cooldown_timer: float = 0.0
var stamina_idle_timer: float = 0.0
var facing_right: bool = true
var flash_tween: Tween = null
var tool_tween: Tween = null
var walk_time: float = 0.0
var is_walking: bool = false
var dust_timer: float = 0.0
var auto_scoop_timer: float = 0.0

@onready var visual: Node2D = $Visual
@onready var tool_sprite: Node2D = $Visual/ToolSprite
@onready var boot_left: ColorRect = $Visual/BootLeft
@onready var boot_right: ColorRect = $Visual/BootRight
@onready var boot_sole_left: ColorRect = $Visual/BootSoleLeft
@onready var boot_sole_right: ColorRect = $Visual/BootSoleRight
@onready var boot_lace_left: ColorRect = $Visual/BootLaceLeft
@onready var boot_lace_right: ColorRect = $Visual/BootLaceRight
@onready var arm_right: ColorRect = $Visual/ArmRight
@onready var hand_right: ColorRect = $Visual/HandRight

# Tool visual elements (built dynamically)
var tool_visuals: Array[ColorRect] = []

func _ready() -> void:
	add_to_group("player")
	GameManager.tool_changed.connect(func(_d: Dictionary) -> void: _update_tool_visual())
	_update_tool_visual()

func _unhandled_input(event: InputEvent) -> void:
	# Dev mode: F1 = +$1k, F2 = +$10k, F3 = +$100k
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				GameManager.money += 1000.0
				GameManager.money_changed.emit(GameManager.money)
				_spawn_floating_text("+$1,000", Color(1.0, 0.85, 0.2))
			KEY_F2:
				GameManager.money += 10000.0
				GameManager.money_changed.emit(GameManager.money)
				_spawn_floating_text("+$10,000", Color(1.0, 0.85, 0.2))
			KEY_F3:
				GameManager.money += 100000.0
				GameManager.money_changed.emit(GameManager.money)
				_spawn_floating_text("+$100,000", Color(1.0, 0.85, 0.2))

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Movement
	var direction: float = Input.get_axis("move_left", "move_right")
	var speed: float = BASE_SPEED * GameManager.get_movement_speed_multiplier()
	velocity.x = direction * speed

	if direction != 0.0:
		facing_right = direction > 0.0
		visual.scale.x = 1.0 if facing_right else -1.0

	is_walking = direction != 0.0 and is_on_floor()

	move_and_slide()

	# Walk animation
	if is_walking:
		walk_time += delta * 8.0
		var bob: float = sin(walk_time) * 1.6
		visual.position.y = bob
		# Leg animation
		var leg_offset: float = sin(walk_time) * 3.0
		boot_left.position.y = -8.0 + leg_offset
		boot_right.position.y = -8.0 - leg_offset
		boot_sole_left.position.y = -2.0 + leg_offset
		boot_sole_right.position.y = -2.0 - leg_offset
		boot_lace_left.position.y = -6.0 + leg_offset
		boot_lace_right.position.y = -6.0 - leg_offset
		# Arm swing
		var arm_offset: float = sin(walk_time + PI) * 2.0
		arm_right.position.y = -24.0 + arm_offset
		hand_right.position.y = -13.0 + arm_offset
		# Tool swings with the arm
		tool_sprite.rotation = sin(walk_time + PI) * 0.15
		# Dust particles
		dust_timer += delta
		if dust_timer >= 0.25:
			dust_timer = 0.0
			_spawn_dust()
	else:
		walk_time = 0.0
		var breath: float = sin(Time.get_ticks_msec() * 0.003) * 0.6
		visual.position.y = breath
		boot_left.position.y = -8.0
		boot_right.position.y = -8.0
		boot_sole_left.position.y = -2.0
		boot_sole_right.position.y = -2.0
		boot_lace_left.position.y = -6.0
		boot_lace_right.position.y = -6.0
		arm_right.position.y = -24.0
		hand_right.position.y = -13.0
		tool_sprite.rotation = 0.0
		dust_timer = 0.0

	# Scoop cooldown
	if scoop_cooldown_timer > 0.0:
		scoop_cooldown_timer -= delta

	# Stamina regen
	stamina_idle_timer += delta
	if stamina_idle_timer >= STAMINA_REGEN_DELAY_TIME:
		GameManager.regen_stamina(delta)

	# Hold-to-scoop: auto-scoop while space held
	if Input.is_action_pressed("scoop") and scoop_cooldown_timer <= 0.0:
		_handle_scoop()

	# Auto-scoop on timer when near water (always active, upgrades speed it up)
	var auto_interval: float = GameManager.get_auto_scoop_interval()
	if near_water and near_swamp_index >= 0:
		auto_scoop_timer += delta
		if auto_scoop_timer >= auto_interval:
			auto_scoop_timer -= auto_interval
			if scoop_cooldown_timer <= 0.0:
				_handle_scoop()
	else:
		auto_scoop_timer = 0.0

func _handle_scoop() -> void:
	if near_pump:
		pump_requested.emit()
		scoop_cooldown_timer = SCOOP_COOLDOWN
		return
	if GameManager.current_tool_id == "hose":
		if near_water and near_swamp_index >= 0:
			GameManager.try_activate_hose(near_swamp_index)
		return
	if not near_water or near_swamp_index < 0:
		return
	if GameManager.try_scoop(near_swamp_index):
		scoop_cooldown_timer = SCOOP_COOLDOWN
		stamina_idle_timer = 0.0
		_scoop_feedback()
	elif GameManager.current_stamina >= GameManager.get_stamina_cost() and GameManager.is_inventory_full():
		_spawn_floating_text("FULL!", Color(1.0, 0.4, 0.3))
		scoop_cooldown_timer = SCOOP_COOLDOWN

func _scoop_feedback() -> void:
	# Flash the sprite
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	flash_tween = create_tween()
	visual.modulate = Color(2.0, 2.0, 2.0)
	flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.15)

	# Scoop arm animation
	var scoop_tween := create_tween()
	scoop_tween.tween_property(arm_right, "rotation", -0.5, 0.08)
	scoop_tween.tween_property(arm_right, "rotation", 0.0, 0.12)

	# Tool swings with the scoop
	if tool_tween and tool_tween.is_valid():
		tool_tween.kill()
	tool_tween = create_tween()
	tool_tween.tween_property(tool_sprite, "rotation", -0.7, 0.08)
	tool_tween.tween_property(tool_sprite, "rotation", 0.0, 0.12)

	# Show gallons collected (blue)
	var output: float = GameManager.get_tool_output(GameManager.current_tool_id)
	var gal_text: String
	if output >= 10.0:
		gal_text = "+%.1f gal" % output
	elif output >= 1.0:
		gal_text = "+%.2f gal" % output
	else:
		gal_text = "+%.4f gal" % output
	_spawn_floating_text(gal_text, Color(0.4, 0.8, 1.0))

	# Splash particles
	_spawn_splash()

func _spawn_splash() -> void:
	for i in range(6):
		var dot := ColorRect.new()
		dot.size = Vector2(2, 2)
		dot.color = Color(0.4, 0.65, 0.85, 0.8)
		dot.position = Vector2(randf_range(-12, 12), -4)
		dot.z_index = 8
		add_child(dot)

		var tw := create_tween()
		tw.tween_property(dot, "position", dot.position + Vector2(randf_range(-16, 16), randf_range(-24, -8)), 0.4)
		tw.parallel().tween_property(dot, "modulate:a", 0.0, 0.4)
		tw.tween_callback(dot.queue_free)

func _update_tool_visual() -> void:
	# Clear existing tool visuals
	for v in tool_visuals:
		if is_instance_valid(v):
			v.queue_free()
	tool_visuals.clear()

	var tool_id: String = GameManager.current_tool_id
	match tool_id:
		"hands":
			# No tool visual — bare hands
			pass
		"spoon":
			var handle := ColorRect.new()
			handle.size = Vector2(2, 10)
			handle.position = Vector2(0, -4)
			handle.color = Color(0.7, 0.7, 0.7)
			tool_sprite.add_child(handle)
			tool_visuals.append(handle)
			var bowl := ColorRect.new()
			bowl.size = Vector2(4, 4)
			bowl.position = Vector2(-1, 6)
			bowl.color = Color(0.8, 0.8, 0.8)
			tool_sprite.add_child(bowl)
			tool_visuals.append(bowl)
		"cup":
			var body := ColorRect.new()
			body.size = Vector2(6, 8)
			body.position = Vector2(-2, 0)
			body.color = Color(0.85, 0.85, 0.9)
			tool_sprite.add_child(body)
			tool_visuals.append(body)
			var rim := ColorRect.new()
			rim.size = Vector2(8, 2)
			rim.position = Vector2(-3, -2)
			rim.color = Color(0.75, 0.75, 0.8)
			tool_sprite.add_child(rim)
			tool_visuals.append(rim)
		"bucket":
			var body := ColorRect.new()
			body.size = Vector2(8, 10)
			body.position = Vector2(-4, -2)
			body.color = Color(0.45, 0.45, 0.5)
			tool_sprite.add_child(body)
			tool_visuals.append(body)
			var handle := ColorRect.new()
			handle.size = Vector2(12, 2)
			handle.position = Vector2(-6, -6)
			handle.color = Color(0.55, 0.55, 0.6)
			tool_sprite.add_child(handle)
			tool_visuals.append(handle)
			var rim := ColorRect.new()
			rim.size = Vector2(10, 2)
			rim.position = Vector2(-5, -2)
			rim.color = Color(0.5, 0.5, 0.55)
			tool_sprite.add_child(rim)
			tool_visuals.append(rim)
		"shovel":
			var shaft := ColorRect.new()
			shaft.size = Vector2(2, 14)
			shaft.position = Vector2(0, -6)
			shaft.color = Color(0.55, 0.35, 0.15)
			tool_sprite.add_child(shaft)
			tool_visuals.append(shaft)
			var blade := ColorRect.new()
			blade.size = Vector2(8, 6)
			blade.position = Vector2(-3, 8)
			blade.color = Color(0.55, 0.55, 0.6)
			tool_sprite.add_child(blade)
			tool_visuals.append(blade)
			var edge := ColorRect.new()
			edge.size = Vector2(8, 2)
			edge.position = Vector2(-3, 14)
			edge.color = Color(0.7, 0.7, 0.75)
			tool_sprite.add_child(edge)
			tool_visuals.append(edge)
		"wheelbarrow":
			var tray := ColorRect.new()
			tray.size = Vector2(12, 8)
			tray.position = Vector2(-6, -2)
			tray.color = Color(0.45, 0.5, 0.45)
			tool_sprite.add_child(tray)
			tool_visuals.append(tray)
			var wheel := ColorRect.new()
			wheel.size = Vector2(4, 4)
			wheel.position = Vector2(-2, 6)
			wheel.color = Color(0.3, 0.3, 0.35)
			tool_sprite.add_child(wheel)
			tool_visuals.append(wheel)
			var leg := ColorRect.new()
			leg.size = Vector2(2, 6)
			leg.position = Vector2(4, 2)
			leg.color = Color(0.5, 0.35, 0.15)
			tool_sprite.add_child(leg)
			tool_visuals.append(leg)
		"barrel":
			var body := ColorRect.new()
			body.size = Vector2(10, 14)
			body.position = Vector2(-5, -4)
			body.color = Color(0.5, 0.3, 0.12)
			tool_sprite.add_child(body)
			tool_visuals.append(body)
			var band_top := ColorRect.new()
			band_top.size = Vector2(12, 2)
			band_top.position = Vector2(-6, -2)
			band_top.color = Color(0.45, 0.45, 0.5)
			tool_sprite.add_child(band_top)
			tool_visuals.append(band_top)
			var band_bot := ColorRect.new()
			band_bot.size = Vector2(12, 2)
			band_bot.position = Vector2(-6, 8)
			band_bot.color = Color(0.45, 0.45, 0.5)
			tool_sprite.add_child(band_bot)
			tool_visuals.append(band_bot)
		"water_wagon":
			var tank := ColorRect.new()
			tank.size = Vector2(16, 10)
			tank.position = Vector2(-8, -6)
			tank.color = Color(0.5, 0.3, 0.12)
			tool_sprite.add_child(tank)
			tool_visuals.append(tank)
			var band := ColorRect.new()
			band.size = Vector2(16, 2)
			band.position = Vector2(-8, -2)
			band.color = Color(0.45, 0.45, 0.5)
			tool_sprite.add_child(band)
			tool_visuals.append(band)
			var wheel_l := ColorRect.new()
			wheel_l.size = Vector2(4, 4)
			wheel_l.position = Vector2(-7, 4)
			wheel_l.color = Color(0.3, 0.3, 0.35)
			tool_sprite.add_child(wheel_l)
			tool_visuals.append(wheel_l)
			var wheel_r := ColorRect.new()
			wheel_r.size = Vector2(4, 4)
			wheel_r.position = Vector2(3, 4)
			wheel_r.color = Color(0.3, 0.3, 0.35)
			tool_sprite.add_child(wheel_r)
			tool_visuals.append(wheel_r)
		"hose":
			var nozzle := ColorRect.new()
			nozzle.size = Vector2(10, 4)
			nozzle.position = Vector2(-2, -2)
			nozzle.color = Color(0.2, 0.55, 0.2)
			tool_sprite.add_child(nozzle)
			tool_visuals.append(nozzle)
			var pipe := ColorRect.new()
			pipe.size = Vector2(4, 8)
			pipe.position = Vector2(-2, 2)
			pipe.color = Color(0.25, 0.5, 0.25)
			tool_sprite.add_child(pipe)
			tool_visuals.append(pipe)

func show_floating_text(text: String, color: Color = Color(0.3, 1.0, 0.4)) -> void:
	_spawn_floating_text(text, color)

func _spawn_floating_text(text: String, color: Color = Color(0.3, 1.0, 0.4)) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.position = Vector2(-28, -48)
	label.z_index = 10
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 32, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func set_near_pump(value: bool) -> void:
	near_pump = value

func set_near_water(value: bool, swamp_index: int = -1) -> void:
	if value:
		near_water = true
		near_swamp_index = swamp_index
	else:
		if swamp_index == near_swamp_index:
			near_water = false
			near_swamp_index = -1

func _spawn_dust() -> void:
	for i in range(2):
		var dot := ColorRect.new()
		dot.size = Vector2(3, 2)
		dot.color = Color(0.45, 0.35, 0.2, 0.6)
		dot.position = Vector2(randf_range(-6, 6), -2)
		dot.z_index = -1
		add_child(dot)
		var tw := create_tween()
		tw.tween_property(dot, "position", dot.position + Vector2(randf_range(-8, 8), randf_range(-6, -2)), 0.5)
		tw.parallel().tween_property(dot, "modulate:a", 0.0, 0.5)
		tw.tween_callback(dot.queue_free)
