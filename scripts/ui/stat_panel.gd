extends PanelContainer

@onready var stat_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/StatList
@onready var close_button: Button = $MarginContainer/VBoxContainer/TopBar/CloseButton

func _ready() -> void:
	close_button.pressed.connect(func() -> void: visible = false)
	GameManager.money_changed.connect(func(_m: float) -> void: _refresh())
	GameManager.stat_upgraded.connect(func(_s: String, _l: int) -> void: _refresh())
	visible = false

func open() -> void:
	visible = true
	_refresh()

func _refresh() -> void:
	for child in stat_list.get_children():
		child.queue_free()

	for stat_id in GameManager.stat_definitions:
		var sid: String = stat_id
		var defn: Dictionary = GameManager.stat_definitions[sid]
		var level: int = GameManager.stat_levels[sid]
		var value: float = GameManager.get_stat_value(sid)
		var cost: float = GameManager.get_stat_upgrade_cost(sid)

		# Row background
		var row_panel := PanelContainer.new()
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(0.1, 0.12, 0.16, 0.6)
		row_style.corner_radius_top_left = 2
		row_style.corner_radius_top_right = 2
		row_style.corner_radius_bottom_left = 2
		row_style.corner_radius_bottom_right = 2
		row_style.content_margin_left = 4
		row_style.content_margin_right = 4
		row_style.content_margin_top = 2
		row_style.content_margin_bottom = 2
		row_panel.add_theme_stylebox_override("panel", row_style)

		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 4)

		var info_label := Label.new()
		info_label.add_theme_font_size_override("font_size", 7)
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
		info_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		info_label.add_theme_constant_override("shadow_offset_x", 1)
		info_label.add_theme_constant_override("shadow_offset_y", 1)

		if sid == "carrying_capacity":
			info_label.text = "%s Lv%d: %.3f gal" % [defn["name"], level, value]
		elif sid == "movement_speed":
			info_label.text = "%s Lv%d: %.1fx" % [defn["name"], level, value]
		elif sid == "stamina_regen":
			info_label.text = "%s Lv%d: %.1f/s" % [defn["name"], level, value]
		else:
			info_label.text = "%s Lv%d: %.0f" % [defn["name"], level, value]
		entry.add_child(info_label)

		# Level indicator dots
		var dots_label := Label.new()
		dots_label.add_theme_font_size_override("font_size", 6)
		var dot_count: int = mini(level, 10)
		var dot_str: String = ""
		for i in range(dot_count):
			dot_str += "|"
		dots_label.text = dot_str
		dots_label.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0, 0.6))
		entry.add_child(dots_label)

		var upgrade_btn := Button.new()
		upgrade_btn.add_theme_font_size_override("font_size", 7)
		upgrade_btn.text = "Up %s" % Economy.format_money(cost)
		upgrade_btn.custom_minimum_size = Vector2(48, 0)
		if GameManager.money < cost:
			upgrade_btn.disabled = true
		else:
			upgrade_btn.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
			var s: String = sid
			upgrade_btn.pressed.connect(func() -> void: GameManager.upgrade_stat(s); _refresh())
		_style_button(upgrade_btn, Color(0.1, 0.18, 0.3))
		entry.add_child(upgrade_btn)

		row_panel.add_child(entry)
		stat_list.add_child(row_panel)

func _style_button(btn: Button, bg_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = bg_color.lightened(0.4)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = bg_color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed_style)
