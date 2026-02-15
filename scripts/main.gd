extends Node2D

@onready var hud = $HUD
@onready var shop_panel = $UILayer/ShopPanel
@onready var stat_panel = $UILayer/StatPanel
@onready var pump_panel = $UILayer/PumpPanel
@onready var menu_panel = $UILayer/MenuPanel
@onready var player = $GameWorld/Player

func _ready() -> void:
	hud.shop_pressed.connect(_on_shop_pressed)
	hud.stats_pressed.connect(_on_stats_pressed)
	hud.menu_pressed.connect(_on_menu_pressed)
	player.pump_requested.connect(_on_pump_requested)
	menu_panel.reset_confirmed.connect(_on_reset_confirmed)

func _close_all_panels() -> void:
	shop_panel.visible = false
	stat_panel.visible = false
	pump_panel.visible = false

func _on_shop_pressed() -> void:
	_close_all_panels()
	shop_panel.open()

func _on_stats_pressed() -> void:
	_close_all_panels()
	stat_panel.open()

func _on_pump_requested() -> void:
	_close_all_panels()
	pump_panel.open()

func _on_menu_pressed() -> void:
	_close_all_panels()
	menu_panel.open()

func _on_reset_confirmed() -> void:
	_close_all_panels()
	GameManager.reset_game()
	SaveManager.save_game()
	player.position = Vector2(20, 63)
	player.velocity = Vector2.ZERO
	player.near_water = false
	player.near_swamp_index = -1
	player.near_pump = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if menu_panel.visible:
			menu_panel._close()
		elif shop_panel.visible or stat_panel.visible or pump_panel.visible:
			_close_all_panels()
		else:
			menu_panel.open()
