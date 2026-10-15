extends Control

const FINAL_DAY := 12
const CHARACTER_NAMES := {
	"maya": "Maya",
	"yuna": "Yuna",
	"alice": "Alice",
	"hikari": "Hikari",
}

@onready var day_label: Label = $DayLabel
@onready var status_label: Label = $StatusLabel
@onready var poem_button: Button = $Panel/VBoxContainer/PoemButton
@onready var walk_button: Button = $Panel/VBoxContainer/WalkButton
@onready var late_button: Button = $Panel/VBoxContainer/LateButton
@onready var next_day_button: Button = $Panel/VBoxContainer/NextDayButton
@onready var end_button: Button = $Panel/VBoxContainer/EndButton
@onready var character_buttons := {
	"maya": $Panel/VBoxContainer/MayaButton,
	"yuna": $Panel/VBoxContainer/YunaButton,
	"alice": $Panel/VBoxContainer/AliceButton,
	"hikari": $Panel/VBoxContainer/HikariButton,
}

func _ready() -> void:
	if GameState.last_seen_main_event_day < GameState.day:
		_play_main_event()
		return
	MusicPlayer.play_mood("menu")
	_refresh()

func _refresh() -> void:
	day_label.text = "Dia %d" % GameState.day
	for char_id in character_buttons:
		var button: Button = character_buttons[char_id]
		var done := GameState.visited_today(char_id)
		button.disabled = done
		button.text = ("Já conversou com %s hoje" if done else "Falar com %s") % CHARACTER_NAMES[char_id]
	var poem_done := GameState.visited_today("poem")
	poem_button.disabled = poem_done
	poem_button.text = "Poema de hoje já escrito" if poem_done else "Escrever um poema"
	var walk_path := _walk_path()
	walk_button.visible = FileAccess.file_exists(walk_path)
	var walk_done := GameState.visited_today("walk")
	walk_button.disabled = walk_done
	walk_button.text = "Você já passeou pela escola hoje" if walk_done else "Passear pela escola"
	late_button.visible = FileAccess.file_exists(_late_path())
	var late_done := GameState.visited_today("late")
	late_button.disabled = late_done
	late_button.text = "Você já ficou até tarde hoje" if late_done else "Ficar até mais tarde"
	var final_day := GameState.day >= FINAL_DAY
	next_day_button.visible = not final_day
	end_button.visible = final_day
	status_label.text = _status_text(final_day)

func _status_text(final_day: bool) -> String:
	var pending: PackedStringArray = []
	for char_id in character_buttons:
		if not GameState.visited_today(char_id):
			pending.append(CHARACTER_NAMES[char_id])
	var text := "Você já falou com todas hoje." if pending.is_empty() else "Ainda dá tempo de falar com: %s.\nQuem ficar sem conversa perde 1 de afinidade ao virar o dia." % ", ".join(pending)
	if final_day:
		text += "\n\nÉ a noite do festival. Quando estiver pronto, suba ao telhado. Depois disso, não tem volta."
	return text

func _play_main_event() -> void:
	GameState.last_seen_main_event_day = GameState.day
	_start_dialogue("res://data/dialogue/main_day%d.json" % GameState.day)

func _start_dialogue(path: String) -> void:
	var vn_scene = get_tree().current_scene.show_screen("res://scenes/vn/VNScene.tscn")
	vn_scene.start(path)

func _on_character_button_pressed(character_id: String) -> void:
	SfxPlayer.play_click()
	GameState.mark_visited(character_id)
	_start_dialogue("res://data/dialogue/%s_day%d.json" % [character_id, GameState.day])

func _walk_path() -> String:
	return "res://data/dialogue/extra_day%d.json" % GameState.day

func _late_path() -> String:
	return "res://data/dialogue/late_day%d.json" % GameState.day

func _on_late_button_pressed() -> void:
	SfxPlayer.play_click()
	GameState.mark_visited("late")
	_start_dialogue(_late_path())

func _on_walk_button_pressed() -> void:
	SfxPlayer.play_click()
	GameState.mark_visited("walk")
	_start_dialogue(_walk_path())

func _on_poem_button_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.show_screen("res://scenes/poem/PoemGame.tscn")

func _on_next_day_button_pressed() -> void:
	SfxPlayer.play_click()
	if GameState.day >= FINAL_DAY:
		return
	# Quem foi ignorada hoje sente a falta.
	for char_id in character_buttons:
		if not GameState.visited_today(char_id):
			GameState.change_affinity(char_id, -1)
	GameState.day += 1
	SaveManager.autosave()
	_play_main_event()

func _on_save_load_button_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.show_screen("res://scenes/main/SaveSlots.tscn")

func _on_settings_button_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.show_screen("res://scenes/main/Settings.tscn")

func _on_end_button_pressed() -> void:
	SfxPlayer.play_click()
	GameState.ending_scene_played = false
	get_tree().current_scene.show_screen("res://scenes/ending/EndingScene.tscn")

func _on_title_button_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.show_title()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
