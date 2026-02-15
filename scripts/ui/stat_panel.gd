extends PanelContainer

@onready var stat_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/StatList
@onready var close_button: Button = $MarginContainer/VBoxContainer/TopBar/CloseButton

var _dirty: bool = false
var _refresh_cooldown: float = 0.0
const REFRESH_INTERVAL: float = 0.3

func _ready() -> void:
	close_button.pressed.connect(func() -> void: close())
	GameManager.money_changed.connect(func(_m: float) -> void: _dirty = true)
	GameManager.stat_upgraded.connect(func(_s: String, _l: int) -> void: _dirty = true; _refresh_cooldown = REFRESH_INTERVAL)
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
	# Slide in from left (Phase 10a)
	var vp_w: float = get_viewport_rect().size.x
	position.x = -vp_w
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position:x", 0.0, 0.2)

func close() -> void:
	var vp_w: float = get_viewport_rect().size.x
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "position:x", -vp_w, 0.15)
	tw.tween_callback(func() -> void: visible = false)

func _refresh() -> void:
	for child in stat_list.get_children():
		stat_list.remove_child(child)
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
		row_style.corner_radius_top_left = 4
		row_style.corner_radius_top_right = 4
		row_style.corner_radius_bottom_left = 4
		row_style.corner_radius_bottom_right = 4
		row_style.content_margin_left = 8
		row_style.content_margin_right = 8
		row_style.content_margin_top = 4
		row_style.content_margin_bottom = 4
		row_panel.add_theme_stylebox_override("panel", row_style)

		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 8)

		var info_label := Label.new()
		info_label.add_theme_font_size_override("font_size", 14)
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
		info_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		info_label.add_theme_constant_override("shadow_offset_x", 2)
		info_label.add_theme_constant_override("shadow_offset_y", 2)

		var fmt: String = defn.get("format", "value")
		match fmt:
			"gal":
				info_label.text = "%s Lv%d: %.1f gal" % [defn["name"], level, value]
			"multiplier":
				info_label.text = "%s Lv%d: %.1fx" % [defn["name"], level, value]
			"per_sec":
				info_label.text = "%s Lv%d: %.1f/s" % [defn["name"], level, value]
			"percent":
				info_label.text = "%s Lv%d: %.0f%%" % [defn["name"], level, value * 100.0]
			_:
				info_label.text = "%s Lv%d: %.0f" % [defn["name"], level, value]
		entry.add_child(info_label)

		# Level indicator dots
		var dots_label := Label.new()
		dots_label.add_theme_font_size_override("font_size", 12)
		var dot_count: int = mini(level, 10)
		var dot_str: String = ""
		for i in range(dot_count):
			dot_str += "|"
		dots_label.text = dot_str
		dots_label.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0, 0.6))
		entry.add_child(dots_label)

		var upgrade_btn := Button.new()
		upgrade_btn.add_theme_font_size_override("font_size", 14)
		upgrade_btn.text = "Up %s" % Economy.format_money(cost)
		upgrade_btn.custom_minimum_size = Vector2(96, 0)
		if GameManager.money < cost:
			upgrade_btn.disabled = true
		else:
			upgrade_btn.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
			var s: String = sid
			upgrade_btn.pressed.connect(func() -> void: GameManager.upgrade_stat(s))
		_style_button(upgrade_btn, Color(0.1, 0.18, 0.3))
		entry.add_child(upgrade_btn)

		# Tooltip
		row_panel.tooltip_text = _get_stat_tooltip(sid, defn, level, value, cost)
		row_panel.mouse_filter = Control.MOUSE_FILTER_PASS

		row_panel.add_child(entry)
		stat_list.add_child(row_panel)

func _get_stat_tooltip(sid: String, defn: Dictionary, level: int, value: float, cost: float) -> String:
	var tip: String = defn["name"]
	var fmt: String = defn.get("format", "value")

	# Current value
	tip += "\nCurrent (Lv%d): %s" % [level, _format_stat_value(fmt, value)]

	# Next level
	var next_val: float = GameManager.get_stat_value_at_level(sid, level + 1)
	tip += "\nNext (Lv%d): %s" % [level + 1, _format_stat_value(fmt, next_val)]

	# Delta
	if defn.get("scale", "linear") == "exponential":
		var pct: float = (next_val / maxf(value, 0.001) - 1.0) * 100.0
		tip += " (+%.1f%%)" % pct
	else:
		var delta: float = next_val - value
		tip += " (+%s)" % _format_stat_value(fmt, delta)

	tip += "\nUpgrade: %s" % Economy.format_money(cost)

	# Preview Lv+5
	var lv5: int = level + 5
	var val5: float = GameManager.get_stat_value_at_level(sid, lv5)
	tip += "\nLv%d: %s" % [lv5, _format_stat_value(fmt, val5)]

	if defn.has("max_value"):
		tip += "\nMax: %s" % _format_stat_value(fmt, defn["max_value"])

	return tip

func _format_stat_value(fmt: String, value: float) -> String:
	match fmt:
		"gal":
			return "%.1f gal" % value
		"multiplier":
			return "%.2fx" % value
		"per_sec":
			return "%.1f/s" % value
		"percent":
			return "%.0f%%" % (value * 100.0)
		_:
			return "%.0f" % value

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
