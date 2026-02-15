extends PanelContainer

@onready var tool_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ToolList
@onready var close_button: Button = $MarginContainer/VBoxContainer/TopBar/CloseButton

func _ready() -> void:
	close_button.pressed.connect(func() -> void: visible = false)
	GameManager.money_changed.connect(func(_m: float) -> void: _refresh())
	GameManager.tool_upgraded.connect(func(_t: String, _l: int) -> void: _refresh())
	visible = false

func open() -> void:
	visible = true
	_refresh()

func _refresh() -> void:
	for child in tool_list.get_children():
		child.queue_free()

	var sorted_tools: Array = GameManager.tool_definitions.keys()
	sorted_tools.sort_custom(func(a: Variant, b: Variant) -> bool: return GameManager.tool_definitions[a]["order"] < GameManager.tool_definitions[b]["order"])

	for tool_id in sorted_tools:
		var tid: String = tool_id
		var defn: Dictionary = GameManager.tool_definitions[tid]
		var owned_data: Dictionary = GameManager.tools_owned[tid]

		# Row background
		var row_panel := PanelContainer.new()
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(0.12, 0.12, 0.16, 0.6)
		row_style.corner_radius_top_left = 2
		row_style.corner_radius_top_right = 2
		row_style.corner_radius_bottom_left = 2
		row_style.corner_radius_bottom_right = 2
		row_style.content_margin_left = 4
		row_style.content_margin_right = 4
		row_style.content_margin_top = 2
		row_style.content_margin_bottom = 2
		if GameManager.current_tool_id == tid:
			row_style.border_width_left = 1
			row_style.border_color = Color(0.3, 0.9, 0.4, 0.5)
		row_panel.add_theme_stylebox_override("panel", row_style)

		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 4)

		var info_label := Label.new()
		info_label.add_theme_font_size_override("font_size", 7)
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		info_label.add_theme_constant_override("shadow_offset_x", 1)
		info_label.add_theme_constant_override("shadow_offset_y", 1)

		if owned_data["owned"]:
			var output: float = GameManager.get_tool_output(tid)
			if defn["type"] == "semi_auto":
				info_label.text = "%s Lv%d (%.3f g/s)" % [defn["name"], owned_data["level"], output]
			else:
				info_label.text = "%s Lv%d (%.4f g)" % [defn["name"], owned_data["level"], output]
			if GameManager.current_tool_id == tid:
				info_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			else:
				info_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		else:
			info_label.text = "%s [LOCKED]" % defn["name"]
			info_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))

		entry.add_child(info_label)

		if owned_data["owned"]:
			# Equip button (gold)
			var equip_btn := Button.new()
			equip_btn.add_theme_font_size_override("font_size", 7)
			equip_btn.custom_minimum_size = Vector2(32, 0)
			if GameManager.current_tool_id == tid:
				equip_btn.text = "[ON]"
				equip_btn.disabled = true
			else:
				equip_btn.text = "Equip"
				equip_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
				var t: String = tid
				equip_btn.pressed.connect(func() -> void: GameManager.equip_tool(t); _refresh())
			_style_button(equip_btn, Color(0.3, 0.28, 0.1))
			entry.add_child(equip_btn)

			# Upgrade button (blue)
			var upgrade_btn := Button.new()
			upgrade_btn.add_theme_font_size_override("font_size", 7)
			var cost: float = GameManager.get_tool_upgrade_cost(tid)
			upgrade_btn.text = "Up %s" % Economy.format_money(cost)
			upgrade_btn.custom_minimum_size = Vector2(48, 0)
			if GameManager.money < cost:
				upgrade_btn.disabled = true
			else:
				upgrade_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
				var t: String = tid
				upgrade_btn.pressed.connect(func() -> void: GameManager.upgrade_tool(t); _refresh())
			_style_button(upgrade_btn, Color(0.1, 0.18, 0.3))
			entry.add_child(upgrade_btn)
		else:
			# Buy button (green)
			var buy_btn := Button.new()
			buy_btn.add_theme_font_size_override("font_size", 7)
			buy_btn.text = "Buy %s" % Economy.format_money(defn["cost"])
			buy_btn.custom_minimum_size = Vector2(55, 0)
			var prev_owned := true
			for other_id in sorted_tools:
				var oid: String = other_id
				if GameManager.tool_definitions[oid]["order"] == defn["order"] - 1:
					if not GameManager.tools_owned[oid]["owned"]:
						prev_owned = false
					break
			if GameManager.money < defn["cost"] or not prev_owned:
				buy_btn.disabled = true
			else:
				buy_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
				var t: String = tid
				buy_btn.pressed.connect(func() -> void: GameManager.buy_tool(t); GameManager.equip_tool(t); _refresh())
			_style_button(buy_btn, Color(0.08, 0.22, 0.1))
			entry.add_child(buy_btn)

		row_panel.add_child(entry)
		tool_list.add_child(row_panel)

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
