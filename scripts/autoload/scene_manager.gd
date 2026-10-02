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

# Compatibility flags for callers of the retired story UI.
var showing_newspaper: bool = false
var endgame_active: bool = false

# --- Lore popup ---
var lore_layer: CanvasLayer = null
var showing_lore: bool = false
var _dismiss_help: Callable

# --- Burner phone (Northwind Analytics) ---
# Texts queue up and wait for a clear screen (no newspaper/lore/transition), so a
# pool-completion text never fights the milestone newspaper for the same keypress.
var phone_queue: Array[String] = []
var phone_cooldown: float = 0.0

# One-shot NA handler texts, keyed by story beat. Each beat is gated by a
# persisted story flag ("na_text_<key>") so it fires once per save, ever —
# the handler doesn't reintroduce herself after prestige.
const NA_TEXTS: Dictionary = {
	"first_sell": [
		"First payment cleared. Not from them. From us.\n\nYou do good work. Do not thank me. Just keep draining. The water hides much.\n\n— a Friend"
	],
	"pond": [
		"The puddle, now the pond. The papers say nobody cares. Somebody cares. Somebody bought you this phone.\n\nKeep everything you find in the water. Especially the papers.\n\n— a Friend"
	],
	"first_lore": [
		"The document from the cave. Photograph it. Front and back. Good light, no shadow.\n\nA hobbyist asks. I am the hobbyist.\n\n— a Friend"
	],
	"bog": [
		"Excellent labors, com— friend. My friend.\n\nThe trucks that refill the water at night — we have photographed the drivers. For no reason. We photograph many things.\n\n— a Friend",
		"Also: the drop box at the west edge of town. It is ours. Check it when the flag is up.\n\nDo not wave back at the flag.\n\n— a Friend"
	],
	"lake": [
		"Funds are not a problem. Buy the bigger bucket. We believe in you like a mother believes in a strong ox.\n\n— a Friend",
		"A man in town asked about you today. We asked about him. He has stopped asking.\n\nDo not worry about this.\n\n— a Friend"
	],
	"lagoon": [
		"Enough pretense. The containers from the lagoon — Northwind Analytics requires their contents catalogued. You will be compensated. You are always compensated.\n\nNotice this.\n\n— NA",
		"Your government wants you in a cell. We want you employed.\n\nConsider which is the better retirement plan.\n\n— NA"
	],
	"bayou": [
		"Fourteen officials fled the country this week. Twelve flew with airlines we also own. Business is good.\n\nKeep draining.\n\n— NA"
	],
	"atlantic": [
		"The ocean is gone. There is a list at the bottom. There is an island past it.\n\nBring the List to the island. We will handle everything after. We are very good at handling.\n\n— NA"
	],
	"first_prestige": [
		"You sold out. Good. Sentiment is a luxury for people with pensions.\n\nThe swamp refills. The arrangement continues. It always continues.\n\n— NA"
	],
	"prestige_2": [
		"Twice now. We are impressed. We sent camels — a caravan says: this man is settled, he is not going anywhere.\n\nAlso, they carry water.\n\n— NA"
	],
	"prestige_3": [
		"Our couriers now collect inside the caves, and photograph the documents so you do not have to squint.\n\nDo not ask how they got down there first. They are professionals.\n\n— NA"
	],
	"prestige_4": [
		"Sometimes a buyer needs water gone quickly, quietly, and at twice the price. You will know the moment when it arrives.\n\nIt is not subtle.\n\n— NA"
	]
}

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

const POPUP_MAX_WIDTH: float = 260.0

func _build_popup() -> void:
	# v3 hud: pixel wood card (was a flat StyleBoxFlat + default font — the
	# "HOLD SPACE to scoop water" hint popup Wes flagged as plain/smooth).
	# Shrink-wraps to content now (round 5: was a fixed 320x210-ish box with
	# one line crammed at the top and the rest empty plank) — width is capped
	# so long toast text (the buyback-window / audit lines) still wraps
	# instead of stretching edge to edge; height comes from the wrapped text.
	cave_popup = PanelContainer.new()
	cave_popup.visible = false
	cave_popup.theme = PixelUI.THEME
	cave_popup.anchors_preset = Control.PRESET_CENTER_BOTTOM
	cave_popup.add_theme_stylebox_override("panel", PixelUI.frame(10, 8))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cave_popup.add_child(vbox)

	popup_label = PixelUI.caption("", PixelUI.CREAM, true)
	popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	popup_label.custom_minimum_size = Vector2(POPUP_MAX_WIDTH, 0)
	vbox.add_child(popup_label)

	popup_close_btn = Button.new()
	popup_close_btn.text = "[Close]"
	popup_close_btn.custom_minimum_size = Vector2(72, 14)
	popup_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	PixelUI.button(popup_close_btn)
	popup_close_btn.pressed.connect(_close_popup)
	vbox.add_child(popup_close_btn)

	popup_layer.add_child(cave_popup)

	# Connect to GameManager signals
	GameManager.loot_collected.connect(_on_loot_collected)
	GameManager.swamp_completed.connect(_on_swamp_completed)

	# Burner-phone story triggers (Northwind Analytics)
	GameManager.water_sold.connect(func(_amount: float) -> void: _queue_na_text("first_sell"))
	GameManager.lore_read.connect(func(_cave_id: String, _lore_id: String) -> void: _queue_na_text("first_lore"))
	GameManager.prestige_performed.connect(func() -> void:
		_queue_na_text("first_prestige")
		# Arrangement perk unlocks (P2-P4) each get their own handler text
		if GameManager.prestige_count >= 2:
			_queue_na_text("prestige_2")
		if GameManager.prestige_count >= 3:
			_queue_na_text("prestige_3")
		if GameManager.prestige_count >= 4:
			_queue_na_text("prestige_4")
	)
	GameManager.swamp_completed.connect(_on_story_swamp_completed)

func _process(delta: float) -> void:
	if popup_auto_close > 0.0:
		popup_timer += delta
		if popup_timer >= popup_auto_close:
			_close_popup()

	if Input.is_action_just_pressed("ui_cancel") and cave_popup.visible:
		_close_popup()

	# Burner phone: deliver the next queued text once the screen is clear.
	# While anything story-modal is up, hold at 1s so the text lands a beat
	# after the other surface closes instead of the same frame.
	if phone_queue.size() > 0:
		if showing_lore or showing_newspaper or endgame_active or is_transitioning:
			phone_cooldown = maxf(phone_cooldown, 1.0)
		elif phone_cooldown > 0.0:
			phone_cooldown -= delta
		else:
			var msg: String = phone_queue.pop_front()
			AudioManager.play("loot", 1.3, -6.0)
			show_document_popup(msg, "MESSAGE RECEIVED", "phone")
			phone_cooldown = 0.8

func _input(event: InputEvent) -> void:
	# Handle the event itself; frame polling can miss brief key presses on web.
	if showing_lore and _dismiss_help.is_valid():
		if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			_dismiss_help.call()
			get_viewport().set_input_as_handled()
			return

func show_popup(text: String, auto_close_time: float = 0.0) -> void:
	popup_label.text = text
	cave_popup.visible = true
	popup_timer = 0.0
	popup_auto_close = auto_close_time
	# Reposition after the container re-sorts to its (now correct,
	# shrink-wrapped) minimum size for this text — sizing a Control the same
	# frame its content changes reads its stale pre-resize size.
	call_deferred("_position_cave_popup")

func _position_cave_popup() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	cave_popup.position = Vector2((vp_size.x - cave_popup.size.x) * 0.5, vp_size.y - cave_popup.size.y - 16.0)

func _close_popup() -> void:
	cave_popup.visible = false
	popup_auto_close = 0.0

func show_document_popup(text: String, title: String = "CAVE INSCRIPTION", kind: String = "paper") -> void:
	if showing_lore:
		return
	# "paper" = aged document; "phone" = dark burner-phone screen (NA texts)
	var is_phone: bool = kind == "phone"

	showing_lore = true
	lore_layer = CanvasLayer.new()
	lore_layer.layer = 90
	add_child(lore_layer)

	var vp_size: Vector2 = get_viewport().get_visible_rect().size

	var overlay := ColorRect.new()
	overlay.size = vp_size
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	lore_layer.add_child(overlay)

	# CenterContainer does the shrink-wrap + centering (same proven pattern as
	# menu_panel.tscn's Box): a bare Control outside any Container parent does
	# NOT auto-fit to its children's minimum size, which is what produced a
	# giant blank/black panel here before this container was added.
	var centerer := CenterContainer.new()
	centerer.size = vp_size
	centerer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(centerer)

	# v3 hud: pixel panel instead of flat StyleBoxFlat + default font. "paper"
	# (cave inscriptions/discoveries) reads as parchment; "phone" (burner-phone
	# NA texts) reads as a dark wood card with a green terminal-text tint —
	# same two-kind distinction as before, just built from the baked kit.
	# Shrink-wraps to content (round 5): fixed WIDTH so short hints and long
	# NA-phone paragraphs wrap the same way, auto HEIGHT from the wrapped
	# text instead of a one-size 380x240 box.
	var panel := PanelContainer.new()
	panel.theme = PixelUI.THEME
	panel.modulate = Color(1, 1, 1, 0)
	panel.add_theme_stylebox_override("panel",
		PixelUI.inset(Color(0.35, 0.85, 0.55), 16, 12) if is_phone else PixelUI.parchment(16, 12))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.custom_minimum_size = Vector2(260.0, 0.0)
	panel.add_child(vbox)

	var title_lbl := PixelUI.header(title, Color(0.55, 0.85, 0.60) if is_phone else PixelUI.INK)
	vbox.add_child(title_lbl)

	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.30, 0.50, 0.38, 0.5) if is_phone else Color(0.3, 0.25, 0.2, 0.5)
	sep_style.content_margin_top = 2
	sep_style.content_margin_bottom = 2
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	var body := PixelUI.caption(text, Color(0.72, 0.88, 0.75) if is_phone else PixelUI.INK, true)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(body)

	var prompt := PixelUI.caption("[Press any key to close]", PixelUI.GOLD, true)
	vbox.add_child(prompt)

	centerer.add_child(panel)

	# Fade in
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay, "color:a", 0.7, 0.4)
	tw.tween_property(panel, "modulate:a", 1.0, 0.4)
	tw.set_parallel(false)
	tw.tween_interval(0.3)
	tw.tween_callback(func() -> void:
		_wait_for_lore_dismiss(overlay, panel, prompt)
	)

func show_lore_popup(text: String) -> void:
	pass # Story popups removed; gameplay remains uninterrupted.

func _wait_for_lore_dismiss(overlay: ColorRect, panel: PanelContainer, prompt: Label) -> void:
	var elapsed_ref: Array[float] = [0.0]
	var dismissed: Array[bool] = [false]
	var layer_ref: CanvasLayer = lore_layer
	var frame_ref: Array[Callable] = [Callable()]
	_dismiss_help = func() -> void:
		if dismissed[0]:
			return
		dismissed[0] = true
		var tw_out := create_tween()
		tw_out.set_parallel(true)
		tw_out.tween_property(overlay, "color:a", 0.0, 0.3)
		tw_out.tween_property(panel, "modulate:a", 0.0, 0.3)
		tw_out.set_parallel(false)
		tw_out.tween_interval(0.2)
		tw_out.tween_callback(func() -> void:
			if get_tree().process_frame.is_connected(frame_ref[0]):
				get_tree().process_frame.disconnect(frame_ref[0])
			_dismiss_help = Callable()
			layer_ref.queue_free()
			showing_lore = false
			lore_layer = null
		)
	frame_ref[0] = func() -> void:
		if not dismissed[0] and is_instance_valid(layer_ref):
			elapsed_ref[0] += get_process_delta_time()
			prompt.modulate.a = 0.5 + 0.5 * sin(elapsed_ref[0] * 2.0)
	get_tree().process_frame.connect(frame_ref[0])

func _on_loot_collected(_cave_id: String, _loot_id: String, reward_text: String) -> void:
	pass # Story popups removed; gameplay remains uninterrupted.

func _queue_na_text(key: String) -> void:
	if not NA_TEXTS.has(key):
		return
	if not GameManager.mark_story_flag("na_text_" + key):
		return
	# Keep the story beat recorded without opening a phone message.

func _on_story_swamp_completed(swamp_index: int, _reward: float) -> void:
	match swamp_index:
		1: _queue_na_text("pond")
		3: _queue_na_text("bog")
		5: _queue_na_text("lake")
		7: _queue_na_text("lagoon")
		8: _queue_na_text("bayou")
		9: _queue_na_text("atlantic")

func _on_swamp_completed(swamp_index: int, _reward: float) -> void:
	pass # Story popups removed; gameplay remains uninterrupted.

func show_single_newspaper(data: Dictionary) -> void:
	pass # Story popups removed; gameplay remains uninterrupted.

func show_endgame_newspapers(newspapers: Array) -> void:
	pass # Story popups removed; gameplay remains uninterrupted.

func show_ending_choice(on_choice: Callable) -> void:
	pass # Story popups removed; gameplay remains uninterrupted.

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
	if OS.get_environment("DTS_FREEZE") != "":
		return  # debug-only: hold the scene for screenshots (never set in real builds)
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
