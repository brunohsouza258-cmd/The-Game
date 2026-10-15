extends Control

# Diário do protagonista: cada entrada de data/diary.json aparece quando seus requisitos
# (flags, dia, pavor, loop...) são atendidos.
const DIARY_PATH := "res://data/diary.json"

@onready var list: VBoxContainer = $Scroll/List
@onready var counter: Label = $CounterLabel
@onready var back_button: Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	var entries := _load_entries()
	var shown := 0
	for entry in entries:
		var ok := true
		var requires: Dictionary = entry.get("requires", {})
		for key in requires.keys():
			if not GameState.meets_requirement(key, int(requires[key])):
				ok = false
				break
		if not ok:
			continue
		shown += 1
		var title := Label.new()
		title.text = String(entry.get("title", ""))
		title.add_theme_font_size_override("font_size", 20)
		title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.92))
		list.add_child(title)
		var text := Label.new()
		text.text = String(entry.get("text", "")).format({"player_name": GameState.player_name})
		text.autowrap_mode = TextServer.AUTOWRAP_WORD
		text.custom_minimum_size = Vector2(900, 0)
		list.add_child(text)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 10)
		list.add_child(gap)
	counter.text = "%d de %d lembranças" % [shown, entries.size()]
	if shown == 0:
		var empty := Label.new()
		empty.text = "Ainda não há nada escrito."
		list.add_child(empty)

func _load_entries() -> Array:
	var file := FileAccess.open(DIARY_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed.get("entries", []) if typeof(parsed) == TYPE_DICTIONARY else []

func _on_back_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.show_screen("res://scenes/main/Hub.tscn")
