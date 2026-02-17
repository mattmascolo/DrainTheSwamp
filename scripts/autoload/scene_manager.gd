extends Node

# --- State ---
var return_position: Vector2 = Vector2.ZERO
var return_scene_path: String = "res://scenes/main.tscn"
var is_transitioning: bool = false

# --- Visual nodes ---
var fade_layer: CanvasLayer = null
var fade_rect: ColorRect = null
var popup_layer: CanvasLayer = null
var cave_popup: PanelContainer = null
var popup_label: Label = null
var popup_close_btn: Button = null
var popup_timer: float = 0.0
var popup_auto_close: float = 0.0

# --- Newspaper popup ---
var newspaper_layer: CanvasLayer = null
var newspaper_overlay: ColorRect = null
var newspaper_panel: PanelContainer = null
var newspaper_date_label: Label = null
var newspaper_headline: Label = null
var newspaper_subhead: Label = null
var newspaper_body: Label = null
var newspaper_prompt: Label = null
var showing_newspaper: bool = false
var newspaper_ready_for_input: bool = false
var milestone_newspapers: Array = []

func _ready() -> void:
	# Fade overlay — layer 100, full-screen black, starts transparent
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)

	# Popup layer — layer 90
	popup_layer = CanvasLayer.new()
	popup_layer.layer = 90
	add_child(popup_layer)
	_build_popup()
	_init_milestone_newspapers()
	_build_newspaper_overlay()

func _build_popup() -> void:
	cave_popup = PanelContainer.new()
	cave_popup.visible = false
	cave_popup.anchors_preset = Control.PRESET_CENTER_BOTTOM
	cave_popup.position = Vector2(160, 280)
	cave_popup.size = Vector2(320, 80)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.92)
	style.border_color = Color(0.6, 0.5, 0.3, 0.8)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	cave_popup.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	cave_popup.add_child(vbox)

	popup_label = Label.new()
	popup_label.text = ""
	popup_label.add_theme_font_size_override("font_size", 12)
	popup_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(popup_label)

	popup_close_btn = Button.new()
	popup_close_btn.text = "[Close]"
	popup_close_btn.add_theme_font_size_override("font_size", 10)
	popup_close_btn.flat = true
	popup_close_btn.pressed.connect(_close_popup)
	vbox.add_child(popup_close_btn)

	popup_layer.add_child(cave_popup)

	# Connect to GameManager signals
	GameManager.loot_collected.connect(_on_loot_collected)
	GameManager.swamp_completed.connect(_on_swamp_completed)

var _newspaper_elapsed: float = 0.0

func _process(delta: float) -> void:
	if popup_auto_close > 0.0:
		popup_timer += delta
		if popup_timer >= popup_auto_close:
			_close_popup()

	if Input.is_action_just_pressed("ui_cancel") and cave_popup.visible:
		_close_popup()

	# Newspaper prompt pulse
	if showing_newspaper and newspaper_prompt:
		_newspaper_elapsed += delta
		newspaper_prompt.modulate.a = 0.5 + 0.5 * sin(_newspaper_elapsed * 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if not showing_newspaper or not newspaper_ready_for_input:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_dismiss_milestone_newspaper()
	elif event is InputEventMouseButton and event.pressed:
		_dismiss_milestone_newspaper()

func show_popup(text: String, auto_close_time: float = 0.0) -> void:
	popup_label.text = text
	cave_popup.visible = true
	popup_timer = 0.0
	popup_auto_close = auto_close_time
	# Center horizontally
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	cave_popup.position = Vector2((vp_size.x - 320) * 0.5, vp_size.y - 100)

func _close_popup() -> void:
	cave_popup.visible = false
	popup_auto_close = 0.0

func _on_loot_collected(_cave_id: String, _loot_id: String, reward_text: String) -> void:
	show_popup(reward_text, 3.0)

func _on_swamp_completed(swamp_index: int, _reward: float) -> void:
	if swamp_index == 2:
		show_popup("A stray camel wanders out of the drained marsh!\nCamel now available in the Shop.", 5.0)
	# Show milestone newspaper after a short delay
	if swamp_index >= 0 and swamp_index < milestone_newspapers.size():
		var idx: int = swamp_index
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			_show_milestone_newspaper(idx)
		)

func _init_milestone_newspapers() -> void:
	milestone_newspapers = [
		{
			"date": "Vol. XLII, No. 8 — Friday, March 15",
			"headline": "SWAMP EMPLOYEE SOMEHOW DRAINS PUDDLE",
			"subhead": "Government takes credit; allocates $0 for further progress",
			"body": "\"This proves the system works,\" said Press Secretary Spinwell at a hastily organized press conference. When asked how a man with no tools managed to drain a puddle, Spinwell responded, \"American ingenuity,\" before being escorted away by aides.\n\nSenator Swampsworth released a statement taking personal credit for the puddle's removal, calling it \"a direct result of my leadership.\" Records show he has never visited the swamp."
		},
		{
			"date": "Vol. XLII, No. 12 — Tuesday, March 19",
			"headline": "SWAMP MAN CONTINUES, POLITICIANS MILDLY ANNOYED",
			"subhead": "\"We didn't think he'd still be here,\" admits unnamed official",
			"body": "The lone swamp drainer has now cleared a second body of water, prompting mild concern among government officials who assumed he would have quit by now.\n\n\"The plan was for him to get discouraged and leave,\" said an anonymous source. \"Nobody actually wants the swamp drained. Have you seen what's in there?\""
		},
		{
			"date": "Vol. XLII, No. 19 — Tuesday, March 26",
			"headline": "DRAINING REVEALS BURIED CAMPAIGN SIGNS FROM 1987",
			"subhead": "\"Those were supposed to stay buried,\" says nervous city councilman",
			"body": "The draining of the marsh has uncovered hundreds of old campaign signs, several unmarked filing cabinets, and what appears to be a shredded Rolodex belonging to a former mayor.\n\nCity officials have requested that the drainer \"please stop finding things.\" A cease-and-desist letter was drafted but could not be delivered because no one knows the drainer's name."
		},
		{
			"date": "Vol. XLII, No. 28 — Thursday, April 4",
			"headline": "SCIENTISTS WARN: DRAINING SWAMP \"COULD DISRUPT ECOSYSTEM\"",
			"subhead": "Study funded by Senator Swampsworth's wife's foundation",
			"body": "A new study warns that continued swamp draining could endanger several species of mosquito and an \"unusually large\" population of leeches.\n\n\"Won't somebody think of the mosquitoes?\" pleaded a lobbyist from the newly formed Americans for Swamp Preservation. The organization was registered yesterday and lists its address as Senator Swampsworth's vacation home."
		},
		{
			"date": "Vol. XLII, No. 35 — Thursday, April 11",
			"headline": "ACTUAL SWAMP NOW DRAINED, GOVERNMENT IN EMERGENCY SESSION",
			"subhead": "Congress votes to rename remaining water \"Definitely Not A Swamp\"",
			"body": "In an unprecedented move, Congress held an emergency session to address the fact that the swamp has been drained. A bipartisan resolution was passed to reclassify all remaining bodies of water as \"Definitely Not Swamps.\"\n\n\"You can't drain what isn't a swamp,\" explained Congresswoman Lobbyton, visibly sweating. Legal experts say the reclassification has no practical effect."
		},
		{
			"date": "Vol. XLII, No. 44 — Saturday, April 20",
			"headline": "MAN WITH BUCKET OUTPERFORMS ENTIRE GOVERNMENT PROGRAM",
			"subhead": "$200M initiative has produced 0 results; one guy has drained 6 bodies of water",
			"body": "An audit of the Swamp Draining Initiative reveals that of the $200M budget, $0 was spent on actual draining. Meanwhile, one man with purchased tools has drained six bodies of water.\n\nThe Consultant's latest $500,000 report recommends \"continued monitoring.\" It is three pages long and two of them are the cover page."
		},
		{
			"date": "Vol. XLII, No. 53 — Monday, April 29",
			"headline": "BOTH PARTIES ISSUE RARE JOINT STATEMENT: \"STOP DRAINING\"",
			"subhead": "Republicans and Democrats agree for first time since naming a post office",
			"body": "In what historians are calling \"the most bipartisan moment in decades,\" both parties have jointly demanded that the swamp drainer cease all operations immediately.\n\n\"Some things should stay wet,\" said Senator Swampsworth. \"The swamp is part of our national heritage,\" added Congresswoman Lobbyton. Neither could explain why they suddenly care about swamp preservation."
		},
		{
			"date": "Vol. XLII, No. 61 — Tuesday, May 7",
			"headline": "LEAKED DOCUMENTS SHOW POLITICIANS STORED VALUABLES IN SWAMP",
			"subhead": "\"It's not corruption, it's 'waterproof asset management,'\" says lawyer",
			"body": "Draining of the lagoon has revealed waterproof containers belonging to multiple elected officials. Contents include offshore account records, blackmail photographs, and what appears to be \"a truly staggering amount of cash.\"\n\nA spokesperson for the implicated officials called the discovery \"a coincidence\" and suggested the containers \"must have floated there from somewhere else.\""
		},
		{
			"date": "Vol. XLII, No. 70 — Thursday, May 16",
			"headline": "POLITICIANS FLEE COUNTRY AS BAYOU DRAINAGE REVEALS PAPER TRAIL",
			"subhead": "Senator Swampsworth's passport found; he's \"on vacation indefinitely\"",
			"body": "At least fourteen elected officials have left the country following the draining of the bayou, which exposed a comprehensive paper trail linking both parties to decades of corruption.\n\nSenator Swampsworth was last seen boarding a private jet to a \"non-extradition country.\" His office says he is \"on a fact-finding mission\" and will return \"when the swamp refills.\""
		},
		{
			"date": "Vol. XLII, No. 82 — Friday, May 30",
			"headline": "THE ATLANTIC OCEAN IS DRAINING AND IT'S ONE MAN'S FAULT",
			"subhead": "\"We should have given him a shovel,\" admits former Press Secretary",
			"body": "Former Press Secretary Spinwell, speaking from an undisclosed location, expressed regret over the government's handling of the swamp drainer. \"In hindsight, maybe we should have just given him a shovel and let him drain the puddle. Instead we gave him nothing and he drained the ocean.\"\n\nThe drainer could not be reached for comment. He was last seen heading east with a very large bucket."
		}
	]

func _build_newspaper_overlay() -> void:
	newspaper_layer = CanvasLayer.new()
	newspaper_layer.layer = 95
	add_child(newspaper_layer)

	var vp_size: Vector2 = Vector2(640, 360)

	newspaper_overlay = ColorRect.new()
	newspaper_overlay.size = vp_size
	newspaper_overlay.color = Color(0, 0, 0, 0.0)
	newspaper_overlay.visible = false
	newspaper_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	newspaper_layer.add_child(newspaper_overlay)

	newspaper_panel = PanelContainer.new()
	var panel_w: float = 400.0
	var panel_h: float = 280.0
	newspaper_panel.position = Vector2((vp_size.x - panel_w) * 0.5, (vp_size.y - panel_h) * 0.5)
	newspaper_panel.size = Vector2(panel_w, panel_h)
	newspaper_panel.modulate = Color(1, 1, 1, 0)

	var paper_style := StyleBoxFlat.new()
	paper_style.bg_color = Color(0.92, 0.88, 0.78)
	paper_style.border_color = Color(0.3, 0.25, 0.2)
	paper_style.border_width_top = 2
	paper_style.border_width_bottom = 2
	paper_style.border_width_left = 2
	paper_style.border_width_right = 2
	paper_style.corner_radius_top_left = 2
	paper_style.corner_radius_top_right = 2
	paper_style.corner_radius_bottom_left = 2
	paper_style.corner_radius_bottom_right = 2
	paper_style.content_margin_left = 16
	paper_style.content_margin_right = 16
	paper_style.content_margin_top = 12
	paper_style.content_margin_bottom = 12
	newspaper_panel.add_theme_stylebox_override("panel", paper_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	newspaper_panel.add_child(vbox)

	var masthead := Label.new()
	masthead.text = "THE SWAMP GAZETTE"
	masthead.add_theme_font_size_override("font_size", 16)
	masthead.add_theme_color_override("font_color", Color(0.15, 0.12, 0.10))
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(masthead)

	newspaper_date_label = Label.new()
	newspaper_date_label.add_theme_font_size_override("font_size", 8)
	newspaper_date_label.add_theme_color_override("font_color", Color(0.4, 0.38, 0.35))
	newspaper_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(newspaper_date_label)

	var sep1 := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.3, 0.25, 0.2, 0.5)
	sep_style.content_margin_top = 2
	sep_style.content_margin_bottom = 2
	sep1.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep1)

	newspaper_headline = Label.new()
	newspaper_headline.add_theme_font_size_override("font_size", 12)
	newspaper_headline.add_theme_color_override("font_color", Color(0.12, 0.10, 0.08))
	newspaper_headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	newspaper_headline.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(newspaper_headline)

	newspaper_subhead = Label.new()
	newspaper_subhead.add_theme_font_size_override("font_size", 9)
	newspaper_subhead.add_theme_color_override("font_color", Color(0.35, 0.32, 0.28))
	newspaper_subhead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	newspaper_subhead.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(newspaper_subhead)

	var sep2 := HSeparator.new()
	var sep_style2 := StyleBoxFlat.new()
	sep_style2.bg_color = Color(0.3, 0.25, 0.2, 0.5)
	sep_style2.content_margin_top = 2
	sep_style2.content_margin_bottom = 2
	sep2.add_theme_stylebox_override("separator", sep_style2)
	vbox.add_child(sep2)

	newspaper_body = Label.new()
	newspaper_body.add_theme_font_size_override("font_size", 8)
	newspaper_body.add_theme_color_override("font_color", Color(0.18, 0.15, 0.12))
	newspaper_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	newspaper_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(newspaper_body)

	newspaper_prompt = Label.new()
	newspaper_prompt.text = "[Press any key to continue]"
	newspaper_prompt.add_theme_font_size_override("font_size", 10)
	newspaper_prompt.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	newspaper_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(newspaper_prompt)

	newspaper_overlay.add_child(newspaper_panel)

func _show_milestone_newspaper(swamp_index: int) -> void:
	if showing_newspaper:
		return
	var data: Dictionary = milestone_newspapers[swamp_index]
	newspaper_date_label.text = data["date"]
	newspaper_headline.text = data["headline"]
	newspaper_subhead.text = data["subhead"]
	newspaper_body.text = data["body"]

	showing_newspaper = true
	newspaper_ready_for_input = false
	newspaper_overlay.visible = true

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(newspaper_overlay, "color:a", 0.7, 0.5)
	tw.tween_property(newspaper_panel, "modulate:a", 1.0, 0.5)
	tw.set_parallel(false)
	tw.tween_callback(func() -> void: newspaper_ready_for_input = true)

func _dismiss_milestone_newspaper() -> void:
	newspaper_ready_for_input = false
	showing_newspaper = false
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(newspaper_overlay, "color:a", 0.0, 0.4)
	tw.tween_property(newspaper_panel, "modulate:a", 0.0, 0.4)
	tw.set_parallel(false)
	tw.tween_callback(func() -> void:
		newspaper_overlay.visible = false
	)

# --- Scene Transitions ---
func transition_to_scene(scene_path: String, use_pixelate: bool = false) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	if use_pixelate:
		_pixelate_out(func() -> void: _do_scene_change(scene_path))
	else:
		var tw := create_tween()
		tw.tween_property(fade_rect, "color:a", 1.0, 0.4)
		tw.tween_callback(_do_scene_change.bind(scene_path))

func _do_scene_change(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
	# Fade in after one frame (let new scene _ready run)
	await get_tree().process_frame
	_fade_in()

func transition_to_return() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_pixelate_out(func() -> void: _do_scene_change(return_scene_path))

func fade_in() -> void:
	_fade_in()

func _fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: is_transitioning = false)

func _pixelate_out(on_complete: Callable) -> void:
	# Quick fade with brief white flash, then black
	var tw := create_tween()
	fade_rect.color = Color(1, 1, 1, 0)
	tw.tween_property(fade_rect, "color:a", 0.7, 0.1)
	tw.tween_callback(func() -> void: fade_rect.color = Color(0, 0, 0, 0.7))
	tw.tween_property(fade_rect, "color:a", 1.0, 0.2)
	tw.tween_callback(func() -> void: on_complete.call())

func flash_white(duration: float = 0.15) -> void:
	# Brief white flash for celebrations (pool completion, etc.)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.6)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, duration)
	tw.tween_callback(flash.queue_free)
