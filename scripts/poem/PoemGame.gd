extends Control

const WORD_BANK_PATH := "res://data/poems/word_bank.json"
const WORDS_TO_PICK := 5
const TIER_DELTAS := {
	"great": [3, 2],
	"good": [1, 1],
	"meh": [0, -1],
}

@onready var girl_select: VBoxContainer = $GirlSelect
@onready var word_select: VBoxContainer = $WordSelect
@onready var word_grid: GridContainer = $WordSelect/WordGrid
@onready var counter_label: Label = $WordSelect/CounterLabel
@onready var finish_button: Button = $WordSelect/FinishButton
@onready var result_panel: VBoxContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/ResultLabel
@onready var back_button: Button = $ResultPanel/BackButton

var _words: Array = []
var _reactions: Dictionary = {}
var _target: String = ""
var _selected: Array = []

func _ready() -> void:
	var file := FileAccess.open(WORD_BANK_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	_words = parsed.get("words", [])
	_reactions = parsed.get("reactions", {})
	finish_button.pressed.connect(_on_finish_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_show_girl_select()

func _show_girl_select() -> void:
	girl_select.visible = true
	word_select.visible = false
	result_panel.visible = false

func _on_girl_button_pressed(character_id: String) -> void:
	_target = character_id
	_selected.clear()
	_build_word_grid()
	girl_select.visible = false
	word_select.visible = true
	result_panel.visible = false

func _build_word_grid() -> void:
	for child in word_grid.get_children():
		child.queue_free()
	for word_data in _words:
		var button := Button.new()
		button.text = word_data.get("text", "")
		button.toggle_mode = true
		button.pressed.connect(_on_word_toggled.bind(button, word_data))
		word_grid.add_child(button)
	_update_counter()

func _on_word_toggled(button: Button, word_data: Dictionary) -> void:
	if button.button_pressed:
		if _selected.size() >= WORDS_TO_PICK:
			button.button_pressed = false
			return
		_selected.append(word_data)
	else:
		_selected.erase(word_data)
	_update_counter()

func _update_counter() -> void:
	counter_label.text = "%d/%d palavras escolhidas" % [_selected.size(), WORDS_TO_PICK]
	finish_button.disabled = _selected.size() != WORDS_TO_PICK

func _on_finish_pressed() -> void:
	var score := 0
	for word_data in _selected:
		var weights: Dictionary = word_data.get("weights", {})
		score += int(weights.get(_target, 0))
	var tier := "meh"
	if score >= 10:
		tier = "great"
	elif score >= 5:
		tier = "good"
	var delta: Array = TIER_DELTAS[tier]
	GameState.change_affinity(_target, delta[0])
	GameState.change_trust(_target, delta[1])
	GameState.mark_visited("poem")
	SfxPlayer.play_click()
	result_label.text = _reaction_text(tier)
	word_select.visible = false
	result_panel.visible = true

func _reaction_text(tier: String) -> String:
	var character_reactions: Dictionary = _reactions.get(_target, {})
	return character_reactions.get(tier, "Ela lê em silêncio.")

func _on_back_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.show_screen("res://scenes/main/Hub.tscn")
