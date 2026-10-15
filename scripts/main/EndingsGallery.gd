extends Control

const ENDINGS_PATH := "res://data/endings/endings.json"
const ORDER := ["truth", "route_maya", "route_yuna", "route_alice", "route_hikari", "illusion", "restart", "secret"]

@onready var list: VBoxContainer = $List
@onready var detail: Label = $Detail
@onready var counter: Label = $CounterLabel
@onready var back_button: Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	var endings := _load_endings()
	var unlocked := 0
	for id in ORDER:
		var data: Dictionary = endings.get(id, {})
		if data.is_empty():
			continue
		var open := GameSettings.unlocked_endings.has(id)
		if open:
			unlocked += 1
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 40)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = data.get("title", id) if open else "???"
		button.pressed.connect(_on_ending_pressed.bind(data, open))
		list.add_child(button)
	counter.text = "Finais descobertos: %d / %d" % [unlocked, ORDER.size()]
	detail.text = "Escolha um final."

func _load_endings() -> Dictionary:
	var file := FileAccess.open(ENDINGS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed.get("endings", {}) if typeof(parsed) == TYPE_DICTIONARY else {}

func _on_ending_pressed(data: Dictionary, open: bool) -> void:
	SfxPlayer.play_click()
	if open:
		detail.text = String(data.get("text", "")).format({"player_name": GameState.player_name})
	else:
		var hint: String = data.get("hint", "")
		if data.has("hint_full") and GameSettings.unlocked_endings.size() >= ORDER.size() - 1:
			hint = data["hint_full"]
		detail.text = "Dica: %s" % hint

func _on_back_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.show_title()
