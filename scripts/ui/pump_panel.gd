extends PanelContainer

@onready var content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/Content
@onready var close_button: Button = $MarginContainer/VBoxContainer/TopBar/CloseButton

var _dirty: bool = false

func _ready() -> void:
	close_button.pressed.connect(func() -> void: visible = false)
	GameManager.money_changed.connect(func(_m: float) -> void: _dirty = true)
	GameManager.pump_changed.connect(func() -> void: _dirty = true)
	visible = false

func _process(_delta: float) -> void:
	if _dirty and visible:
		_dirty = false
		_refresh()

func open() -> void:
	visible = true
	_refresh()

func _refresh() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	if not GameManager.pump_owned:
		var info := Label.new()
		info.add_theme_font_size_override("font_size", 14)
		info.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		info.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		info.add_theme_constant_override("shadow_offset_x", 2)
		info.add_theme_constant_override("shadow_offset_y", 2)
		info.text = "Water Pump"
		content.add_child(info)

		var desc := Label.new()
		desc.add_theme_font_size_override("font_size", 12)
		desc.text = "Drains water automatically\nfrom a connected swamp."
		desc.add_theme_color_override("font_color", Color(0.6, 0.62, 0.7))
		content.add_child(desc)

		var buy_btn := Button.new()
		buy_btn.add_theme_font_size_override("font_size", 14)
		buy_btn.text = "Buy Pump %s" % Economy.format_money(GameManager.PUMP_COST)
		if GameManager.money < GameManager.PUMP_COST:
			buy_btn.disabled = true
		else:
			buy_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			buy_btn.pressed.connect(func() -> void: GameManager.buy_pump())
		_style_button(buy_btn, Color(0.08, 0.22, 0.1))
		content.add_child(buy_btn)
	else:
		var drain_rate: float = GameManager.get_pump_drain_rate()
		var income: float = GameManager.get_pump_income_rate()

		var status := Label.new()
		status.add_theme_font_size_override("font_size", 14)
		status.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		status.add_theme_constant_override("shadow_offset_x", 2)
		status.add_theme_constant_override("shadow_offset_y", 2)
		status.text = "Pump Lv%d (%.4f g/s)" % [GameManager.pump_level, drain_rate]
		if income > 0:
			status.text += "\nEarning: %s/s" % Economy.format_money(income)
			status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		else:
			status.text += "\nNo target selected!"
			status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		content.add_child(status)

		# Upgrade button
		var upgrade_cost: float = GameManager.get_pump_upgrade_cost()
		var up_btn := Button.new()
		up_btn.add_theme_font_size_override("font_size", 14)
		up_btn.text = "Upgrade %s" % Economy.format_money(upgrade_cost)
		if GameManager.money < upgrade_cost:
			up_btn.disabled = true
		else:
			up_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
			up_btn.pressed.connect(func() -> void: GameManager.upgrade_pump())
		_style_button(up_btn, Color(0.1, 0.18, 0.3))
		content.add_child(up_btn)

		# Target selection
		var sep := HSeparator.new()
		content.add_child(sep)

		var target_header := Label.new()
		target_header.add_theme_font_size_override("font_size", 14)
		target_header.text = "Connect to:"
		target_header.add_theme_color_override("font_color", Color(0.4, 0.85, 1))
		target_header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		target_header.add_theme_constant_override("shadow_offset_x", 2)
		target_header.add_theme_constant_override("shadow_offset_y", 2)
		content.add_child(target_header)

		for i in range(GameManager.get_swamp_count()):
			var idx: int = i
			var defn: Dictionary = GameManager.swamp_definitions[i]
			var btn := Button.new()
			btn.add_theme_font_size_override("font_size", 14)

			if GameManager.is_swamp_completed(i):
				btn.text = "%s [DONE]" % defn["name"]
				btn.disabled = true
				_style_button(btn, Color(0.1, 0.15, 0.1))
			elif GameManager.pump_target_swamp == i:
				btn.text = "> %s [ACTIVE] <" % defn["name"]
				btn.disabled = true
				btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
				_style_button(btn, Color(0.08, 0.22, 0.1))
			else:
				btn.text = defn["name"]
				btn.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
				btn.pressed.connect(func() -> void: GameManager.set_pump_target(idx))
				_style_button(btn, Color(0.12, 0.15, 0.2))
			content.add_child(btn)

func _style_button(btn: Button, bg_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = bg_color.lightened(0.4)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = bg_color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style := style.duplicate()
	disabled_style.bg_color = Color(0.08, 0.08, 0.1, 0.5)
	disabled_style.border_color = Color(0.15, 0.15, 0.18, 0.4)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	btn.add_theme_color_override("font_disabled_color", Color(0.35, 0.35, 0.4))
