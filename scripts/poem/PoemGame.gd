extends Control

# Poema no estilo Doki Doki: você escolhe palavras sem escolher a destinatária.
# Cada palavra rende pontos às garotas que combinam com ela; quem somar mais
# lê o poema e reage. As outras só reagem se o poema também for a cara delas.

const WORD_BANK_PATH := "res://data/poems/word_bank.json"
const WORDS_TO_PICK := 5
const WORDS_SHOWN := 18
const MIN_LIKED_PER_GIRL := 3  # toda rodada tem pelo menos 3 palavras boas para cada uma
const LIKED_WEIGHT := 2
const BYSTANDER_MIN := 6
const HUB_SCENE := "res://scenes/main/Hub.tscn"
const CHARACTER_NAMES := {"maya": "Maya", "yuna": "Yuna", "alice": "Alice", "hikari": "Hikari"}
const TIER_DELTAS := {
	"great": [3, 2],
	"good": [1, 1],
	"meh": [0, -1],
}

@onready var word_select: VBoxContainer = $WordSelect
@onready var word_grid: GridContainer = $WordSelect/WordGrid
@onready var score_row: HBoxContainer = $WordSelect/ScoreRow
@onready var counter_label: Label = $WordSelect/CounterLabel
@onready var finish_button: Button = $WordSelect/Buttons/FinishButton
@onready var cancel_button: Button = $WordSelect/Buttons/CancelButton
@onready var result_panel: VBoxContainer = $ResultPanel
@onready var poem_label: Label = $ResultPanel/PoemLabel
@onready var result_label: Label = $ResultPanel/ResultLabel
@onready var summary_label: Label = $ResultPanel/SummaryLabel
@onready var back_button: Button = $ResultPanel/BackButton

var _words: Array = []
var _reactions: Dictionary = {}
var _selected: Array = []
var _score_labels: Dictionary = {}

func _ready() -> void:
	var file := FileAccess.open(WORD_BANK_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	_words = parsed.get("words", [])
	_reactions = parsed.get("reactions", {})
	finish_button.pressed.connect(_on_finish_pressed)
	cancel_button.pressed.connect(_on_back_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_start_round()

func _start_round() -> void:
	_selected.clear()
	result_panel.visible = false
	word_select.visible = true
	_build_score_row()
	_build_word_grid(_pick_words())
	_update_counter()

func _pick_words() -> Array:
	var pool := _words.duplicate()
	var best: Array = []
	for _attempt in 30:
		pool.shuffle()
		best = pool.slice(0, mini(WORDS_SHOWN, pool.size()))
		if _covers_every_girl(best):
			break
	return best

func _covers_every_girl(words: Array) -> bool:
	for char_id in GameState.CHARACTERS:
		var liked := 0
		for word_data in words:
			if int(word_data.get("weights", {}).get(char_id, 0)) >= LIKED_WEIGHT:
				liked += 1
		if liked < MIN_LIKED_PER_GIRL:
			return false
	return true

func _build_score_row() -> void:
	for child in score_row.get_children():
		child.queue_free()
	_score_labels.clear()
	for char_id in GameState.CHARACTERS:
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		score_row.add_child(label)
		_score_labels[char_id] = label

func _build_word_grid(words: Array) -> void:
	for child in word_grid.get_children():
		child.queue_free()
	for word_data in words:
		var button := Button.new()
		button.text = word_data.get("text", "")
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_word_toggled.bind(button, word_data))
		word_grid.add_child(button)

func _on_word_toggled(button: Button, word_data: Dictionary) -> void:
	if button.button_pressed:
		if _selected.size() >= WORDS_TO_PICK:
			button.button_pressed = false
			return
		_selected.append(word_data)
		_flash_fans(word_data)
		SfxPlayer.play_click()
	else:
		_selected.erase(word_data)
	_update_counter()

# Faz o placar de quem gosta da palavra piscar, dando o retorno imediato do "acertou".
func _flash_fans(word_data: Dictionary) -> void:
	var weights: Dictionary = word_data.get("weights", {})
	for char_id in _score_labels:
		if int(weights.get(char_id, 0)) < LIKED_WEIGHT:
			continue
		var label: Label = _score_labels[char_id]
		label.modulate = Color(1.0, 0.55, 0.75)
		create_tween().tween_property(label, "modulate", Color.WHITE, 0.6)

func _totals() -> Dictionary:
	var totals := {}
	for char_id in GameState.CHARACTERS:
		totals[char_id] = 0
		for word_data in _selected:
			totals[char_id] += int(word_data.get("weights", {}).get(char_id, 0))
	return totals

func _update_counter() -> void:
	counter_label.text = "%d/%d palavras escolhidas" % [_selected.size(), WORDS_TO_PICK]
	finish_button.disabled = _selected.size() != WORDS_TO_PICK
	var totals := _totals()
	for char_id in _score_labels:
		_score_labels[char_id].text = "%s: %d" % [CHARACTER_NAMES[char_id], totals[char_id]]

func _winner(totals: Dictionary) -> String:
	var best := ""
	for char_id in GameState.CHARACTERS:
		if best == "":
			best = char_id
			continue
		var score: int = totals[char_id]
		var best_score: int = totals[best]
		var closer: bool = int(GameState.affinity.get(char_id, 0)) > int(GameState.affinity.get(best, 0))
		if score > best_score or (score == best_score and closer):
			best = char_id
	return best

func _tier(score: int) -> String:
	if score >= 10:
		return "great"
	if score >= 5:
		return "good"
	return "meh"

func _on_finish_pressed() -> void:
	var totals := _totals()
	var winner := _winner(totals)
	var tier := _tier(totals[winner])
	var delta: Array = TIER_DELTAS[tier]
	GameState.change_affinity(winner, delta[0])
	GameState.change_trust(winner, delta[1])
	var bystanders: PackedStringArray = []
	for char_id in GameState.CHARACTERS:
		if char_id != winner and totals[char_id] >= BYSTANDER_MIN:
			GameState.change_affinity(char_id, 1)
			bystanders.append(CHARACTER_NAMES[char_id])
	GameState.mark_visited("poem")
	SfxPlayer.play_click()

	var texts: PackedStringArray = []
	for word_data in _selected:
		texts.append(String(word_data.get("text", "")))
	poem_label.text = "“%s”" % " · ".join(texts)
	result_label.text = "%s leu o seu poema.\n%s" % [CHARACTER_NAMES[winner], _reaction_text(winner, tier)]
	var lines: PackedStringArray = []
	for char_id in GameState.CHARACTERS:
		lines.append("%s %d" % [CHARACTER_NAMES[char_id], totals[char_id]])
	var summary := "Pontos: " + " · ".join(lines)
	if not bystanders.is_empty():
		summary += "\nO poema também tocou: %s." % ", ".join(bystanders)
	summary_label.text = summary
	word_select.visible = false
	result_panel.visible = true

func _reaction_text(char_id: String, tier: String) -> String:
	var character_reactions: Dictionary = _reactions.get(char_id, {})
	return character_reactions.get(tier, "Ela lê em silêncio.")

func _on_back_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.show_screen(HUB_SCENE)
