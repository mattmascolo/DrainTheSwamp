extends Node

const SAVE_PATH: String = "user://save_data.json"
const SAVE_INTERVAL: float = 30.0

var save_timer: float = 0.0

func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	save_timer += delta
	if save_timer >= SAVE_INTERVAL:
		save_timer = 0.0
		save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()

func save_game() -> void:
	var data: Dictionary = GameManager.get_save_data()
	var json_string: String = JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_string: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var result: int = json.parse(json_string)
	if result != OK:
		return
	var data = json.get_data()
	if data is Dictionary:
		GameManager.load_save_data(data)
