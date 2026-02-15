extends PanelContainer

@onready var tool_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ToolList
@onready var close_button: Button = $MarginContainer/VBoxContainer/TopBar/CloseButton

var _dirty: bool = false

func _ready() -> void:
	close_button.pressed.connect(func() -> void: visible = false)
	GameManager.money_changed.connect(func(_m: float) -> void: _dirty = true)
	GameManager.tool_upgraded.connect(func(_t: String, _l: int) -> void: _dirty = true)
	GameManager.tool_changed.connect(func(_d: Dictionary) -> void: _dirty = true)
	GameManager.camel_changed.connect(func() -> void: _dirty = true)
	visible = false

func _process(_delta: float) -> void:
	if _dirty and visible:
		_dirty = false
		_refresh()

func open() -> void:
	visible = true
	_refresh()

func _refresh() -> void:
	for child in tool_list.get_children():
		tool_list.remove_child(child)
		child.queue_free()

	var sorted_tools: Array = GameManager.tool_definitions.keys()
	sorted_tools.sort_custom(func(a: Variant, b: Variant) -> bool: return GameManager.tool_definitions[a]["cost"] < GameManager.tool_definitions[b]["cost"])

	for tool_id in sorted_tools:
		var tid: String = tool_id
		var defn: Dictionary = GameManager.tool_definitions[tid]
		var owned_data: Dictionary = GameManager.tools_owned[tid]

		# Row background
		var row_panel := PanelContainer.new()
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(0.12, 0.12, 0.16, 0.6)
		row_style.corner_radius_top_left = 4
		row_style.corner_radius_top_right = 4
		row_style.corner_radius_bottom_left = 4
		row_style.corner_radius_bottom_right = 4
		row_style.content_margin_left = 8
		row_style.content_margin_right = 8
		row_style.content_margin_top = 4
		row_style.content_margin_bottom = 4
		if GameManager.current_tool_id == tid:
			row_style.border_width_left = 2
			row_style.border_color = Color(0.3, 0.9, 0.4, 0.5)
		row_panel.add_theme_stylebox_override("panel", row_style)

		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 8)

		var info_label := Label.new()
		info_label.add_theme_font_size_override("font_size", 14)
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		info_label.add_theme_constant_override("shadow_offset_x", 2)
		info_label.add_theme_constant_override("shadow_offset_y", 2)

		if owned_data["owned"]:
			var output: float = GameManager.get_tool_output(tid)
			if defn["type"] == "semi_auto":
				info_label.text = "%s Lv%d (%.3f g/s)" % [defn["name"], owned_data["level"], output]
			elif output >= 10.0:
				info_label.text = "%s Lv%d (%.1f g)" % [defn["name"], owned_data["level"], output]
			elif output >= 1.0:
				info_label.text = "%s Lv%d (%.2f g)" % [defn["name"], owned_data["level"], output]
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
			equip_btn.add_theme_font_size_override("font_size", 14)
			equip_btn.custom_minimum_size = Vector2(64, 0)
			if GameManager.current_tool_id == tid:
				equip_btn.text = "[ON]"
				equip_btn.disabled = true
			else:
				equip_btn.text = "Equip"
				equip_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
				var t: String = tid
				equip_btn.pressed.connect(func() -> void: GameManager.equip_tool(t))
			_style_button(equip_btn, Color(0.3, 0.28, 0.1))
			entry.add_child(equip_btn)

			# Upgrade button (blue)
			var upgrade_btn := Button.new()
			upgrade_btn.add_theme_font_size_override("font_size", 14)
			var cost: float = GameManager.get_tool_upgrade_cost(tid)
			upgrade_btn.text = "Up %s" % Economy.format_money(cost)
			upgrade_btn.custom_minimum_size = Vector2(96, 0)
			if GameManager.money < cost:
				upgrade_btn.disabled = true
			else:
				upgrade_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
				var t: String = tid
				upgrade_btn.pressed.connect(func() -> void: GameManager.upgrade_tool(t))
			_style_button(upgrade_btn, Color(0.1, 0.18, 0.3))
			entry.add_child(upgrade_btn)
		else:
			# Buy button (green)
			var buy_btn := Button.new()
			buy_btn.add_theme_font_size_override("font_size", 14)
			buy_btn.text = "Buy %s" % Economy.format_money(defn["cost"])
			buy_btn.custom_minimum_size = Vector2(110, 0)
			var prev_owned := true
			var tool_index: int = sorted_tools.find(tid)
			if tool_index > 0:
				var prev_id: String = sorted_tools[tool_index - 1]
				if not GameManager.tools_owned[prev_id]["owned"]:
					prev_owned = false
			if GameManager.money < defn["cost"] or not prev_owned:
				buy_btn.disabled = true
			else:
				buy_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
				var t: String = tid
				buy_btn.pressed.connect(func() -> void: GameManager.buy_tool(t); GameManager.equip_tool(t))
			_style_button(buy_btn, Color(0.08, 0.22, 0.1))
			entry.add_child(buy_btn)

		row_panel.add_child(entry)
		tool_list.add_child(row_panel)

	# --- Camel Section ---
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	tool_list.add_child(sep)

	var camel_header := Label.new()
	camel_header.text = "-- Camels --"
	camel_header.add_theme_font_size_override("font_size", 14)
	camel_header.add_theme_color_override("font_color", Color(0.85, 0.7, 0.4))
	camel_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tool_list.add_child(camel_header)

	# Buy Camel button
	var camel_buy_panel := PanelContainer.new()
	var camel_buy_style := StyleBoxFlat.new()
	camel_buy_style.bg_color = Color(0.16, 0.12, 0.06, 0.6)
	camel_buy_style.corner_radius_top_left = 4
	camel_buy_style.corner_radius_top_right = 4
	camel_buy_style.corner_radius_bottom_left = 4
	camel_buy_style.corner_radius_bottom_right = 4
	camel_buy_style.content_margin_left = 8
	camel_buy_style.content_margin_right = 8
	camel_buy_style.content_margin_top = 4
	camel_buy_style.content_margin_bottom = 4
	camel_buy_panel.add_theme_stylebox_override("panel", camel_buy_style)

	var camel_buy_row := HBoxContainer.new()
	camel_buy_row.add_theme_constant_override("separation", 8)

	var camel_info := Label.new()
	camel_info.add_theme_font_size_override("font_size", 14)
	camel_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	camel_info.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	camel_info.add_theme_constant_override("shadow_offset_x", 2)
	camel_info.add_theme_constant_override("shadow_offset_y", 2)
	if GameManager.camel_count > 0:
		camel_info.text = "Camels: %d (Cap: %.1fg, Spd: %.0f)" % [GameManager.camel_count, GameManager.get_camel_capacity(), GameManager.get_camel_speed()]
		camel_info.add_theme_color_override("font_color", Color(0.85, 0.7, 0.4))
	else:
		camel_info.text = "Camel (auto-sell carrier)"
		camel_info.add_theme_color_override("font_color", Color(0.6, 0.5, 0.35))
	camel_buy_row.add_child(camel_info)

	var buy_camel_btn := Button.new()
	buy_camel_btn.add_theme_font_size_override("font_size", 14)
	var camel_cost: float = GameManager.get_camel_cost()
	if GameManager.camel_count == 0:
		buy_camel_btn.text = "Buy %s" % Economy.format_money(camel_cost)
	else:
		buy_camel_btn.text = "+1 %s" % Economy.format_money(camel_cost)
	buy_camel_btn.custom_minimum_size = Vector2(110, 0)
	if GameManager.money < camel_cost:
		buy_camel_btn.disabled = true
	else:
		buy_camel_btn.add_theme_color_override("font_color", Color(0.85, 0.7, 0.3))
		buy_camel_btn.pressed.connect(func() -> void: GameManager.buy_camel())
	_style_button(buy_camel_btn, Color(0.2, 0.15, 0.05))
	camel_buy_row.add_child(buy_camel_btn)

	camel_buy_panel.add_child(camel_buy_row)
	tool_list.add_child(camel_buy_panel)

	# Camel upgrades (only if camels owned)
	if GameManager.camel_count > 0:
		var upgrade_panel := PanelContainer.new()
		var up_style := StyleBoxFlat.new()
		up_style.bg_color = Color(0.14, 0.1, 0.05, 0.6)
		up_style.corner_radius_top_left = 4
		up_style.corner_radius_top_right = 4
		up_style.corner_radius_bottom_left = 4
		up_style.corner_radius_bottom_right = 4
		up_style.content_margin_left = 8
		up_style.content_margin_right = 8
		up_style.content_margin_top = 4
		up_style.content_margin_bottom = 4
		upgrade_panel.add_theme_stylebox_override("panel", up_style)

		var up_row := HBoxContainer.new()
		up_row.add_theme_constant_override("separation", 8)

		var up_spacer := Control.new()
		up_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		up_row.add_child(up_spacer)

		# Capacity upgrade
		var cap_btn := Button.new()
		cap_btn.add_theme_font_size_override("font_size", 14)
		var cap_cost: float = GameManager.get_camel_capacity_upgrade_cost()
		cap_btn.text = "Cap Lv%d %s" % [GameManager.camel_capacity_level + 1, Economy.format_money(cap_cost)]
		cap_btn.custom_minimum_size = Vector2(130, 0)
		if GameManager.money < cap_cost:
			cap_btn.disabled = true
		else:
			cap_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
			cap_btn.pressed.connect(func() -> void: GameManager.upgrade_camel_capacity())
		_style_button(cap_btn, Color(0.1, 0.15, 0.2))
		up_row.add_child(cap_btn)

		# Speed upgrade
		var spd_btn := Button.new()
		spd_btn.add_theme_font_size_override("font_size", 14)
		var spd_cost: float = GameManager.get_camel_speed_upgrade_cost()
		spd_btn.text = "Spd Lv%d %s" % [GameManager.camel_speed_level + 1, Economy.format_money(spd_cost)]
		spd_btn.custom_minimum_size = Vector2(130, 0)
		if GameManager.money < spd_cost:
			spd_btn.disabled = true
		else:
			spd_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
			spd_btn.pressed.connect(func() -> void: GameManager.upgrade_camel_speed())
		_style_button(spd_btn, Color(0.1, 0.15, 0.2))
		up_row.add_child(spd_btn)

		upgrade_panel.add_child(up_row)
		tool_list.add_child(upgrade_panel)

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
