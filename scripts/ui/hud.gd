extends CanvasLayer

@onready var money_label: Label = $MarginContainer/VBoxContainer/TopBar/HBox/MoneyLabel
@onready var carry_label: Label = $MarginContainer/VBoxContainer/TopBar/HBox/CarryLabel
@onready var water_label: Label = $MarginContainer/VBoxContainer/TopBar/HBox/WaterLabel
@onready var tool_label: Label = $MarginContainer/VBoxContainer/BottomBar/HBox/ToolLabel
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/BottomBar/HBox/StaminaBar
@onready var hose_label: Label = $MarginContainer/VBoxContainer/BottomBar/HBox/HoseLabel
@onready var shop_button: Button = $MarginContainer/VBoxContainer/BottomBar/HBox/ShopButton
@onready var stats_button: Button = $MarginContainer/VBoxContainer/BottomBar/HBox/StatsButton
@onready var menu_button: Button = $MarginContainer/VBoxContainer/BottomBar/HBox/MenuButton

signal shop_pressed
signal stats_pressed
signal menu_pressed

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

	shop_button.pressed.connect(func() -> void: shop_pressed.emit())
	stats_button.pressed.connect(func() -> void: stats_pressed.emit())
	menu_button.pressed.connect(func() -> void: menu_pressed.emit())

	# Initialize
	_on_money_changed(GameManager.money)
	_update_water_label()
	_update_tool_label()
	_on_stamina_changed(GameManager.current_stamina, GameManager.get_max_stamina())
	_on_water_carried_changed(GameManager.water_carried, GameManager.get_stat_value("carrying_capacity"))
	hose_label.visible = false

func _on_money_changed(amount: float) -> void:
	money_label.text = Economy.format_money(amount)

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
	carry_label.text = "Bag: %.3f/%.3f" % [current, capacity]

func _on_swamp_completed(swamp_index: int, _reward: float) -> void:
	_update_water_label()
