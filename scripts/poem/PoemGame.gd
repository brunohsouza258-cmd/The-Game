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
const MAX_SCORE := 15  # 5 palavras × 3 pontos
const DOLL_SIZE := 110.0
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
@onready var winner_doll: TextureRect = $ResultPanel/WinnerDoll

var _words: Array = []
var _reactions: Dictionary = {}
var _selected: Array = []
var _cells: Dictionary = {}
var _pop_count: int = 0

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
	_cells.clear()
	for char_id in GameState.CHARACTERS:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		score_row.add_child(cell)

		# Bonequinha: o topo do sprite, que pula quando a palavra combina com ela.
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(0, DOLL_SIZE + 18)
		cell.add_child(holder)
		var doll := TextureRect.new()
		doll.texture = _doll_texture(char_id)
		doll.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		doll.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		doll.size = Vector2(DOLL_SIZE, DOLL_SIZE)
		doll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(doll)
		doll.position = Vector2(0, 18)
		holder.resized.connect(func(): doll.position.x = (holder.size.x - DOLL_SIZE) / 2.0)

		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		cell.add_child(label)

		var bar := ProgressBar.new()
		bar.max_value = MAX_SCORE
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 12)
		cell.add_child(bar)

		_cells[char_id] = {"holder": holder, "doll": doll, "label": label, "bar": bar}

func _doll_texture(char_id: String) -> Texture2D:
	var texture: Texture2D = load("res://assets/characters/%s.png" % char_id)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	var size := texture.get_size()
	# Quadrado do topo (rosto e ombros), do mesmo tamanho para todas.
	atlas.region = Rect2(0, 0, size.x, minf(size.x, size.y))
	return atlas

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
	for char_id in _cells:
		var points := int(weights.get(char_id, 0))
		if points == 0:
			continue
		_react(char_id, points)

# Reação da bonequinha: pula e brilha se gostou, treme e esfria se não gostou.
func _react(char_id: String, points: int) -> void:
	var cell: Dictionary = _cells[char_id]
	var doll: TextureRect = cell["doll"]
	var holder: Control = cell["holder"]
	var rest_y := 18.0
	var tween := create_tween()
	if points > 0:
		var height := 6.0 + 6.0 * points
		doll.modulate = Color(1.0, 0.7, 0.85)
		tween.set_parallel(true)
		tween.tween_property(doll, "modulate", Color.WHITE, 0.5)
		doll.position.y = rest_y - height
		tween.tween_property(doll, "position:y", rest_y, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	else:
		doll.modulate = Color(0.6, 0.7, 1.0)
		tween.tween_property(doll, "modulate", Color.WHITE, 0.6)
		var base_x := doll.position.x
		var shake := create_tween()
		for dx in [6.0, -6.0, 4.0, -4.0, 0.0]:
			shake.tween_property(doll, "position:x", base_x + dx, 0.05)
	var pop := Label.new()
	pop.text = ("+%d ♥" % points) if points > 0 else ("%d" % points)
	pop.add_theme_font_size_override("font_size", 22)
	pop.add_theme_color_override("font_color", Color(1.0, 0.55, 0.75) if points > 0 else Color(0.6, 0.7, 1.0))
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(pop)
	# Escalona os "+N" para não se sobreporem quando várias aparecem juntas.
	var slot := _pop_count % 3
	_pop_count += 1
	pop.position = Vector2(holder.size.x / 2.0 + DOLL_SIZE / 2.0 - 10.0 + slot * 6.0, 40 + slot * 14)
	var float_tween := create_tween().set_parallel(true)
	float_tween.tween_property(pop, "position:y", -14.0, 1.0)
	float_tween.tween_property(pop, "modulate:a", 0.0, 1.0)
	float_tween.chain().tween_callback(pop.queue_free)

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
	var leader := _leader(totals)
	for char_id in _cells:
		var cell: Dictionary = _cells[char_id]
		var crown := "★ " if char_id == leader else ""
		cell["label"].text = "%s%s: %d" % [crown, CHARACTER_NAMES[char_id], totals[char_id]]
		cell["bar"].value = maxi(totals[char_id], 0)

# Quem está na frente agora (só conta se houver pontos e nenhum empate no topo).
func _leader(totals: Dictionary) -> String:
	var best := ""
	var best_score := 0
	var tied := false
	for char_id in GameState.CHARACTERS:
		var score: int = totals[char_id]
		if score > best_score:
			best = char_id
			best_score = score
			tied = false
		elif score == best_score and best != "":
			tied = true
	return "" if tied else best

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
	winner_doll.texture = load("res://assets/characters/%s.png" % winner)
	word_select.visible = false
	result_panel.visible = true

func _reaction_text(char_id: String, tier: String) -> String:
	var character_reactions: Dictionary = _reactions.get(char_id, {})
	return character_reactions.get(tier, "Ela lê em silêncio.")

func _on_back_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.show_screen(HUB_SCENE)
