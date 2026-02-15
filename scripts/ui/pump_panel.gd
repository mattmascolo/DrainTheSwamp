extends PanelContainer

@onready var content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/Content
@onready var close_button: Button = $MarginContainer/VBoxContainer/TopBar/CloseButton

var _dirty: bool = false
var _refresh_cooldown: float = 0.0
const REFRESH_INTERVAL: float = 0.3

func _ready() -> void:
	close_button.pressed.connect(func() -> void: close())
	GameManager.money_changed.connect(func(_m: float) -> void: _dirty = true)
	GameManager.pump_changed.connect(func() -> void: _dirty = true; _refresh_cooldown = REFRESH_INTERVAL)
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
		status.text = "Pump Lv%d (%.4f g/s base)" % [GameManager.pump_level, drain_rate]
		if income > 0:
			status.text += "\nTotal: %s/s" % Economy.format_money(income)
			status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		else:
			status.text += "\nAll pools drained!"
			status.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4))
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

		# Per-swamp drain status
		var sep := HSeparator.new()
		content.add_child(sep)

		var drain_header := Label.new()
		drain_header.add_theme_font_size_override("font_size", 14)
		drain_header.text = "Draining:"
		drain_header.add_theme_color_override("font_color", Color(0.4, 0.85, 1))
		drain_header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		drain_header.add_theme_constant_override("shadow_offset_x", 2)
		drain_header.add_theme_constant_override("shadow_offset_y", 2)
		content.add_child(drain_header)

		for i in range(GameManager.get_swamp_count()):
			var defn: Dictionary = GameManager.swamp_definitions[i]
			var eff: float = GameManager.PUMP_SWAMP_EFFICIENCY[i] if i < GameManager.PUMP_SWAMP_EFFICIENCY.size() else 0.05
			var lbl := Label.new()
			lbl.add_theme_font_size_override("font_size", 12)
			if GameManager.is_swamp_completed(i):
				lbl.text = "%s - DONE" % defn["name"]
				lbl.add_theme_color_override("font_color", Color(0.4, 0.5, 0.4))
			else:
				var swamp_rate: float = drain_rate * eff
				var swamp_income: float = swamp_rate * defn["money_per_gallon"] * GameManager.get_money_multiplier()
				lbl.text = "%s (%d%%) %.4f g/s  %s/s" % [defn["name"], int(eff * 100), swamp_rate, Economy.format_money(swamp_income)]
				lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
			content.add_child(lbl)

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
