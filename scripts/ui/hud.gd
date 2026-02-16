extends CanvasLayer

@onready var money_label: Label = $MarginContainer/VBoxContainer/TopBar/HBox/MoneyLabel
@onready var carry_label: Label = $MarginContainer/VBoxContainer/TopBar/HBox/CarryLabel
@onready var water_label: Label = $MarginContainer/VBoxContainer/TopBar/HBox/WaterLabel
@onready var day_label: Label = $MarginContainer/VBoxContainer/TopBar/HBox/DayLabel
@onready var tool_label: Label = $MarginContainer/VBoxContainer/BottomBar/HBox/ToolLabel
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/BottomBar/HBox/StaminaBar
@onready var hose_label: Label = $MarginContainer/VBoxContainer/BottomBar/HBox/HoseLabel
@onready var menu_button: Button = $MarginContainer/VBoxContainer/BottomBar/HBox/MenuButton

signal menu_pressed

# Phase 10c: Money counter animation
var displayed_money: float = 0.0
var money_tween: Tween = null

func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.water_level_changed.connect(_on_water_level_changed)
	GameManager.tool_changed.connect(func(_d: Dictionary) -> void: _update_tool_label())
	GameManager.tool_upgraded.connect(func(_t: String, _l: int) -> void: _update_tool_label())
	GameManager.stat_upgraded.connect(_on_stat_upgraded)
	GameManager.stamina_changed.connect(_on_stamina_changed)
	GameManager.hose_state_changed.connect(_on_hose_state_changed)
	GameManager.swamp_completed.connect(_on_swamp_completed)
	GameManager.water_carried_changed.connect(_on_water_carried_changed)
	GameManager.day_changed.connect(_on_day_changed)

	menu_button.pressed.connect(func() -> void: menu_pressed.emit())

	# Initialize
	displayed_money = GameManager.money
	_on_money_changed(GameManager.money)
	_update_water_label()
	_update_tool_label()
	_on_stamina_changed(GameManager.current_stamina, GameManager.get_max_stamina())
	_on_water_carried_changed(GameManager.water_carried, GameManager.get_stat_value("carrying_capacity"))
	hose_label.visible = false
	_update_day_label()

func _process(_delta: float) -> void:
	_update_day_label()

func _update_day_label() -> void:
	var t: float = GameManager.cycle_progress
	var time_str: String
	if t < 0.15:
		time_str = "Night"
	elif t < 0.25:
		time_str = "Dawn"
	elif t < 0.45:
		time_str = "Morning"
	elif t < 0.55:
		time_str = "Midday"
	elif t < 0.65:
		time_str = "Afternoon"
	elif t < 0.75:
		time_str = "Dusk"
	else:
		time_str = "Night"
	day_label.text = "Day %d - %s" % [GameManager.current_day, time_str]

func _on_day_changed(_day: int) -> void:
	_update_day_label()

func _on_money_changed(amount: float) -> void:
	var delta_money: float = amount - displayed_money
	# Smooth roll-up animation (Phase 10c)
	if money_tween and money_tween.is_valid():
		money_tween.kill()
	money_tween = create_tween()
	money_tween.tween_method(func(val: float) -> void:
		displayed_money = val
		money_label.text = Economy.format_money(val)
	, displayed_money, amount, 0.3)
	# Golden pulse on big earnings
	if delta_money > 10.0:
		money_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		var glow_tw := create_tween()
		glow_tw.tween_interval(0.15)
		glow_tw.tween_callback(func() -> void:
			money_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		)

func _on_water_level_changed(_swamp_index: int, _percent: float) -> void:
	_update_water_label()

func _update_water_label() -> void:
	var total_pct: float = GameManager.get_total_water_percent()
	water_label.text = "Water: %.1f%%" % total_pct

func _update_tool_label() -> void:
	var tool_data: Dictionary = GameManager.tool_definitions[GameManager.current_tool_id]
	if GameManager.current_tool_id == "hose":
		var output: float = GameManager.get_tool_output("hose")
		tool_label.text = "%s (%.3f g/s)" % [tool_data["name"], output]
	else:
		var output: float = GameManager.get_effective_scoop(GameManager.current_tool_id)
		if output >= 10.0:
			tool_label.text = "%s (%.1f g)" % [tool_data["name"], output]
		elif output >= 1.0:
			tool_label.text = "%s (%.2f g)" % [tool_data["name"], output]
		else:
			tool_label.text = "%s (%.4f g)" % [tool_data["name"], output]

func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current

func _on_hose_state_changed(active: bool, time_remaining: float) -> void:
	hose_label.visible = active
	if active:
		hose_label.text = "HOSE: %.1fs" % time_remaining

func _on_stat_upgraded(_stat_id: String, _new_level: int) -> void:
	_update_tool_label()
	_on_water_carried_changed(GameManager.water_carried, GameManager.get_stat_value("carrying_capacity"))

func _on_water_carried_changed(current: float, capacity: float) -> void:
	if capacity >= 10.0:
		carry_label.text = "Bag: %.1f/%.1f" % [current, capacity]
	elif capacity >= 1.0:
		carry_label.text = "Bag: %.2f/%.2f" % [current, capacity]
	else:
		carry_label.text = "Bag: %.3f/%.3f" % [current, capacity]

func _on_swamp_completed(swamp_index: int, _reward: float) -> void:
	_update_water_label()
