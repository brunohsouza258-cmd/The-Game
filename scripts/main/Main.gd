extends Node

const HUB_SCENE := "res://scenes/main/Hub.tscn"
const SAVE_SLOTS_SCENE := "res://scenes/main/SaveSlots.tscn"
const SETTINGS_SCENE := "res://scenes/main/Settings.tscn"
const CREDITS_SCENE := "res://scenes/main/Credits.tscn"

@onready var title_screen: CanvasLayer = $TitleScreen
@onready var menu_panel: Control = $TitleScreen/MenuPanel
@onready var name_prompt: Control = $TitleScreen/NamePrompt
@onready var name_input: LineEdit = $TitleScreen/NamePrompt/Panel/VBoxContainer/NameInput
@onready var continue_button: Button = $TitleScreen/MenuPanel/VBoxContainer/ContinueButton
@onready var content_root: Node = $ContentRoot

var _in_game: bool = false

func _ready() -> void:
	name_input.text_submitted.connect(func(_text): _on_name_confirm_pressed())
	show_title()

func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if not _in_game or key_event == null or not key_event.pressed:
		return
	if key_event.keycode == KEY_F5:
		SaveManager.save_game()
	elif key_event.keycode == KEY_F9 and SaveManager.has_save():
		_load_and_enter(1)

func show_title() -> void:
	_in_game = false
	DialogueManager.cancel()
	for child in content_root.get_children():
		child.queue_free()
	title_screen.visible = true
	menu_panel.visible = true
	name_prompt.visible = false
	_refresh_continue_button()
	MusicPlayer.play_mood("title")

func enter_game() -> void:
	_in_game = true
	title_screen.visible = false
	show_screen(HUB_SCENE)

func is_in_game() -> bool:
	return _in_game

func return_from_menu() -> void:
	if _in_game:
		show_screen(HUB_SCENE)
	else:
		show_title()

func load_slot(slot: int) -> void:
	_load_and_enter(slot)

func _load_and_enter(slot: int) -> void:
	DialogueManager.cancel()
	if SaveManager.load_game(slot):
		History.clear()
		enter_game()

func _refresh_continue_button() -> void:
	var any_save := false
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		if SaveManager.has_save(slot):
			any_save = true
			break
	continue_button.disabled = not any_save

func _on_new_game_pressed() -> void:
	SfxPlayer.play_click()
	menu_panel.visible = false
	name_prompt.visible = true
	name_input.text = ""
	name_input.grab_focus()

func _on_name_confirm_pressed() -> void:
	SfxPlayer.play_click()
	var typed := name_input.text.strip_edges()
	GameState.reset_for_new_game(typed if typed != "" else "Jogador")
	GameSettings.register_new_loop()
	History.clear()
	enter_game()

func _on_name_cancel_pressed() -> void:
	SfxPlayer.play_click()
	name_prompt.visible = false
	menu_panel.visible = true

func _on_continue_pressed() -> void:
	SfxPlayer.play_click()
	title_screen.visible = false
	show_screen(SAVE_SLOTS_SCENE)

func _on_settings_pressed() -> void:
	SfxPlayer.play_click()
	title_screen.visible = false
	show_screen(SETTINGS_SCENE)

func _on_credits_pressed() -> void:
	SfxPlayer.play_click()
	show_credits()

func show_credits() -> void:
	title_screen.visible = false
	show_screen(CREDITS_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

func show_screen(scene_path: String) -> Node:
	DialogueManager.cancel()
	for child in content_root.get_children():
		child.queue_free()
	var screen: Node = load(scene_path).instantiate()
	content_root.add_child(screen)
	return screen
