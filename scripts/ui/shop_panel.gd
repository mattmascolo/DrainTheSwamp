extends PanelContainer

@onready var tool_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ToolList
@onready var close_button: Button = $MarginContainer/VBoxContainer/TopBar/CloseButton

var _dirty: bool = false
var _refresh_cooldown: float = 0.0
const REFRESH_INTERVAL: float = 0.3

func _ready() -> void:
	close_button.pressed.connect(func() -> void: close())
	GameManager.money_changed.connect(func(_m: float) -> void: _dirty = true)
	GameManager.tool_upgraded.connect(func(_t: String, _l: int) -> void: _dirty = true; _refresh_cooldown = REFRESH_INTERVAL)
	GameManager.tool_changed.connect(func(_d: Dictionary) -> void: _dirty = true; _refresh_cooldown = REFRESH_INTERVAL)
	GameManager.camel_changed.connect(func() -> void: _dirty = true; _refresh_cooldown = REFRESH_INTERVAL)
	GameManager.upgrade_changed.connect(func() -> void: _dirty = true; _refresh_cooldown = REFRESH_INTERVAL)
	visible = false

func _process(delta: float) -> void:
	if _dirty and visible:
		_refresh_cooldown -= delta
		if _refresh_cooldown <= 0.0:
			_dirty = false
			_refresh_cooldown = REFRESH_INTERVAL
			_refresh()

func open() -> void:
	visible = true
	_refresh_cooldown = 0.0
	_refresh()
	# Slide in from right (Phase 10a)
	var vp_w: float = get_viewport_rect().size.x
	position.x = vp_w
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position:x", 0.0, 0.2)

func close() -> void:
	var vp_w: float = get_viewport_rect().size.x
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position:x", vp_w, 0.15)
	tw.tween_callback(func() -> void: visible = false)

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

		# Tooltip
		row_panel.tooltip_text = _get_tool_tooltip(tid, defn, owned_data)
		row_panel.mouse_filter = Control.MOUSE_FILTER_PASS

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

	# Camel buy tooltip
	var camel_tip: String = "Camel - Auto-sell carrier\n"
	if GameManager.camel_count == 0:
		camel_tip += "Walks to you, picks up water,\ncarries it to the pump and sells.\n"
	else:
		camel_tip += "Owned: %d | Capacity: %.1f gal | Speed: %.0f px/s\n" % [GameManager.camel_count, GameManager.get_camel_capacity(), GameManager.get_camel_speed()]
	camel_tip += "Next camel: %s" % Economy.format_money(camel_cost)
	if GameManager.camel_count > 0:
		var next_cost: float = GameManager.CAMEL_BASE_COST * pow(GameManager.CAMEL_COST_EXPONENT, GameManager.camel_count + 1)
		camel_tip += "\nAfter that: %s" % Economy.format_money(next_cost)
	camel_buy_panel.tooltip_text = camel_tip
	camel_buy_panel.mouse_filter = Control.MOUSE_FILTER_PASS

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
		var cur_cap: float = GameManager.get_camel_capacity()
		var next_cap: float = 1.0 * pow(1.25, GameManager.camel_capacity_level + 1)
		cap_btn.tooltip_text = "Camel Capacity Lv%d\nCurrent: %.1f gal\nNext: %.1f gal (+25%%)\nCost: %s" % [GameManager.camel_capacity_level, cur_cap, next_cap, Economy.format_money(cap_cost)]
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
		var cur_spd: float = GameManager.get_camel_speed()
		var next_spd: float = 35.0 * pow(1.20, GameManager.camel_speed_level + 1)
		spd_btn.tooltip_text = "Camel Speed Lv%d\nCurrent: %.0f px/s\nNext: %.0f px/s (+20%%)\nCost: %s" % [GameManager.camel_speed_level, cur_spd, next_spd, Economy.format_money(spd_cost)]
		if GameManager.money < spd_cost:
			spd_btn.disabled = true
		else:
			spd_btn.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
			spd_btn.pressed.connect(func() -> void: GameManager.upgrade_camel_speed())
		_style_button(spd_btn, Color(0.1, 0.15, 0.2))
		up_row.add_child(spd_btn)

		upgrade_panel.add_child(up_row)
		tool_list.add_child(upgrade_panel)

	# --- Upgrades Section ---
	var upgrade_sep := HSeparator.new()
	upgrade_sep.add_theme_constant_override("separation", 8)
	tool_list.add_child(upgrade_sep)

	var upgrade_header := Label.new()
	upgrade_header.text = "-- Upgrades --"
	upgrade_header.add_theme_font_size_override("font_size", 14)
	upgrade_header.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	upgrade_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tool_list.add_child(upgrade_header)

	var sorted_upgrades: Array = GameManager.upgrade_definitions.keys()
	sorted_upgrades.sort_custom(func(a: Variant, b: Variant) -> bool: return GameManager.upgrade_definitions[a]["order"] < GameManager.upgrade_definitions[b]["order"])

	for upgrade_id in sorted_upgrades:
		var uid: String = upgrade_id
		var udefn: Dictionary = GameManager.upgrade_definitions[uid]
		var level: int = GameManager.upgrades_owned[uid]
		var is_maxed: bool = GameManager.is_upgrade_maxed(uid)

		var u_panel := PanelContainer.new()
		var u_style := StyleBoxFlat.new()
		u_style.bg_color = Color(0.1, 0.14, 0.1, 0.6)
		u_style.corner_radius_top_left = 4
		u_style.corner_radius_top_right = 4
		u_style.corner_radius_bottom_left = 4
		u_style.corner_radius_bottom_right = 4
		u_style.content_margin_left = 8
		u_style.content_margin_right = 8
		u_style.content_margin_top = 4
		u_style.content_margin_bottom = 4
		u_panel.add_theme_stylebox_override("panel", u_style)

		var u_row := HBoxContainer.new()
		u_row.add_theme_constant_override("separation", 8)

		var u_info := Label.new()
		u_info.add_theme_font_size_override("font_size", 14)
		u_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		u_info.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		u_info.add_theme_constant_override("shadow_offset_x", 2)
		u_info.add_theme_constant_override("shadow_offset_y", 2)

		if level > 0:
			u_info.text = "%s Lv%d" % [udefn["name"], level]
			u_info.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6))
		else:
			u_info.text = "%s" % udefn["name"]
			u_info.add_theme_color_override("font_color", Color(0.55, 0.6, 0.55))
		u_row.add_child(u_info)

		if is_maxed:
			var max_label := Label.new()
			max_label.text = "[MAX]"
			max_label.add_theme_font_size_override("font_size", 14)
			max_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			u_row.add_child(max_label)
		else:
			var u_btn := Button.new()
			u_btn.add_theme_font_size_override("font_size", 14)
			var u_cost: float = GameManager.get_upgrade_cost(uid)
			if level == 0:
				u_btn.text = "Buy %s" % Economy.format_money(u_cost)
			else:
				u_btn.text = "Up %s" % Economy.format_money(u_cost)
			u_btn.custom_minimum_size = Vector2(110, 0)
			if GameManager.money < u_cost:
				u_btn.disabled = true
			else:
				u_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
				var u: String = uid
				u_btn.pressed.connect(func() -> void: GameManager.buy_upgrade(u))
			_style_button(u_btn, Color(0.08, 0.2, 0.08))
			u_row.add_child(u_btn)

		# Tooltip
		u_panel.tooltip_text = _get_upgrade_tooltip(uid, udefn, level)
		u_panel.mouse_filter = Control.MOUSE_FILTER_PASS

		u_panel.add_child(u_row)
		tool_list.add_child(u_panel)

func _get_upgrade_tooltip(uid: String, defn: Dictionary, level: int) -> String:
	var tip: String = "%s - %s" % [defn["name"], defn["description"]]
	match uid:
		"rain_collector":
			if level > 0:
				tip += "\nCurrent: $%.2f/s" % GameManager.get_rain_collector_rate()
				var next_rate: float = 0.50 * pow(1.30, level)
				tip += "\nNext: $%.2f/s (+30%%)" % next_rate
			else:
				tip += "\nBase: $0.50/s, +30% per level"
		"splash_guard":
			if level > 0:
				tip += "\nStamina cost: %.0f%%" % (GameManager.get_splash_guard_multiplier() * 100.0)
				var next_mult: float = pow(0.82, level + 1)
				tip += "\nNext: %.0f%% (-18%%)" % (next_mult * 100.0)
			else:
				tip += "\nBase: -18% stamina cost per level"
		"auto_seller":
			if level > 0:
				tip += "\nActive! Auto-sells when inventory full."
			else:
				tip += "\nAuto-sell water when inventory full\nNo walking to pump needed!"
		"lucky_charm":
			if level > 0:
				tip += "\n2x money chance: %.0f%%" % (GameManager.get_lucky_charm_chance() * 100.0)
				var next_chance: float = minf(0.05 * pow(1.35, level), 0.80)
				tip += "\nNext: %.0f%% (+35%%)" % (next_chance * 100.0)
			else:
				tip += "\nBase: 5% chance for 2x money, x1.35 per level"
		"auto_scooper":
			var cur_interval: float = GameManager.get_auto_scoop_interval()
			tip += "\nScoop every %.2fs" % cur_interval
			var next_interval: float = maxf(2.5 * pow(0.88, level + 1), 0.1)
			tip += "\nNext: %.2fs (-12%%)" % next_interval
		"lantern":
			if level > 0:
				tip += "\nRadius: %.0fpx, Brightness: %.2f" % [GameManager.get_lantern_radius(), GameManager.get_lantern_energy()]
				var next_radius: float = 48.0 * pow(1.40, level)
				var next_energy: float = minf(2.4 * pow(1.12, level), 8.0)
				tip += "\nNext: %.0fpx radius, %.2f brightness" % [next_radius, next_energy]
			else:
				tip += "\nAutomatic light during night\nBase 48px radius"
	if not GameManager.is_upgrade_maxed(uid):
		tip += "\nCost: %s" % Economy.format_money(GameManager.get_upgrade_cost(uid))
	return tip

func _get_tool_tooltip(tid: String, defn: Dictionary, owned_data: Dictionary) -> String:
	var tip: String = "%s" % defn["name"]
	if defn["type"] == "semi_auto":
		tip += " (auto-drain)"
	else:
		tip += " (manual scoop)"

	if owned_data["owned"]:
		var level: int = owned_data["level"]
		var cur_output: float = GameManager.get_tool_output(tid)
		if defn["type"] == "semi_auto":
			tip += "\nOutput: %.4f gal/s" % cur_output
		else:
			tip += "\nOutput: %.4f gal/scoop" % cur_output

		var next_output: float = defn["base_output"] * pow(1.30, level + 1)
		if defn["type"] == "manual":
			next_output *= GameManager.get_stat_value("scoop_power")
		var gain_pct: float = (next_output / cur_output - 1.0) * 100.0
		if defn["type"] == "semi_auto":
			tip += "\nNext Lv%d: %.4f gal/s (+%.0f%%)" % [level + 1, next_output, gain_pct]
		else:
			tip += "\nNext Lv%d: %.4f gal (+%.0f%%)" % [level + 1, next_output, gain_pct]

		var cost: float = GameManager.get_tool_upgrade_cost(tid)
		tip += "\nUpgrade: %s" % Economy.format_money(cost)
	else:
		var base_out: float = defn["base_output"]
		if defn["type"] == "manual":
			base_out *= GameManager.get_stat_value("scoop_power")
		if defn["type"] == "semi_auto":
			tip += "\nBase output: %.4f gal/s" % base_out
		else:
			tip += "\nBase output: %.4f gal/scoop" % base_out
		tip += "\nCost: %s" % Economy.format_money(defn["cost"])
	return tip

func _style_button(btn: Button, bg_color: Color) -> void:
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
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
