extends Node2D

const ENDINGS_PATH := "res://data/endings/endings.json"

@onready var background: TextureRect = $Background
@onready var title_label: Label = $TitleLabel
@onready var text_label: Label = $TextLabel
@onready var back_button: Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	var ending_id := _determine_ending()
	var data := _load_ending(ending_id)
	title_label.text = data.get("title", "")
	text_label.text = _interpolate(data.get("text", ""))
	background.texture = load(data.get("background", "res://assets/backgrounds/hallway_dusk.png"))
	MusicPlayer.play_mood("ending")

func _determine_ending() -> String:
	var trust_maya: int = int(GameState.trust.get("maya", 0))
	var dread: int = GameState.dread

	# Secret: a second run, having asked Maya for the truth, shared the notebook with Alice and chosen to let go.
	if GameSettings.loop_count >= 2 and GameState.has_flag("maya_truth_asked") \
			and GameState.has_flag("shared_notebook_alice") and GameState.has_flag("accept_loss") and dread >= 60:
		return "secret"
	if GameState.has_flag("accept_loss") and trust_maya >= 12 and dread >= 50:
		return "truth"
	if GameState.has_flag("chose_forget") or dread < 30:
		return "illusion"

	var best_char := ""
	var best_affinity := -999
	for char_id in GameState.CHARACTERS:
		var a: int = int(GameState.affinity.get(char_id, 0))
		if a > best_affinity:
			best_affinity = a
			best_char = char_id
	if best_affinity >= 14 and int(GameState.trust.get(best_char, 0)) >= 8:
		return "route_" + best_char

	return "restart"

func _load_ending(ending_id: String) -> Dictionary:
	var file := FileAccess.open(ENDINGS_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed.get("endings", {}).get(ending_id, {})

func _interpolate(text: String) -> String:
	return text.format({"player_name": GameState.player_name})

func _on_back_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.show_credits()
