extends Control

const CREDITS_PATH := "res://data/credits.json"
const SCROLL_SPEED := 45.0
const SCREEN_HEIGHT := 720.0

@onready var roll: VBoxContainer = $Roll
@onready var skip_button: Button = $SkipButton

var _finished: bool = false

func _ready() -> void:
	skip_button.pressed.connect(_finish)
	_build()
	roll.position.y = SCREEN_HEIGHT
	MusicPlayer.play_mood("ending")

func _build() -> void:
	var file := FileAccess.open(GameSettings.localized_path(CREDITS_PATH), FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	for section in parsed.get("sections", []):
		var title: String = section.get("title", "")
		if title != "":
			roll.add_child(_label(title, 30, Color(1, 0.8, 0.9)))
		for line in section.get("lines", []):
			var text: String = String(line).format({"player_name": GameState.player_name})
			roll.add_child(_label(text, 22, Color(1, 1, 1)))
		roll.add_child(_label("", 22, Color(1, 1, 1)))
		roll.add_child(_label("", 22, Color(1, 1, 1)))

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(roll.size.x, 0)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _process(delta: float) -> void:
	if _finished:
		return
	roll.position.y -= SCROLL_SPEED * delta
	if roll.position.y + roll.size.y < 0:
		_finish()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_finish()

func _finish() -> void:
	if _finished:
		return
	_finished = true
	SfxPlayer.play_click()
	get_tree().current_scene.show_title()
