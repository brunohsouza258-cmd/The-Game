extends Node

const HUB_SCENE := "res://scenes/main/Hub.tscn"
const SAVE_SLOTS_SCENE := "res://scenes/main/SaveSlots.tscn"
const SETTINGS_SCENE := "res://scenes/main/Settings.tscn"
const CREDITS_SCENE := "res://scenes/main/Credits.tscn"
const GALLERY_SCENE := "res://scenes/main/EndingsGallery.tscn"

@onready var title_screen: CanvasLayer = $TitleScreen
@onready var menu_panel: Control = $TitleScreen/MenuPanel
@onready var name_prompt: Control = $TitleScreen/NamePrompt
@onready var name_input: LineEdit = $TitleScreen/NamePrompt/Panel/VBoxContainer/NameInput
@onready var continue_button: Button = $TitleScreen/MenuPanel/VBoxContainer/ContinueButton
@onready var content_root: Node = $ContentRoot

const FADE_SECONDS := 0.4

var _in_game: bool = false
var _fade: ColorRect
var _paused: bool = false
var _pause_layer: CanvasLayer
var _pause_menu: Control
var _overlay: Node = null

func _ready() -> void:
	# Main continua recebendo input com o jogo pausado; o conteúdo do jogo pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for path in ["ContentRoot", "TitleScreen", "DialogueBox", "GlitchOverlay"]:
		var node := get_node_or_null(path)
		if node:
			node.process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_pause_menu()
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.modulate.a = 0.0
	fade_layer.add_child(_fade)
	name_input.text_submitted.connect(func(_text): _on_name_confirm_pressed())
	show_title()

func _build_pause_menu() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 90
	add_child(_pause_layer)
	_pause_menu = Control.new()
	_pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_menu.visible = false
	_pause_layer.add_child(_pause_menu)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_menu.add_child(dim)
	var box := VBoxContainer.new()
	box.position = Vector2(490, 170)
	box.custom_minimum_size = Vector2(300, 0)
	box.add_theme_constant_override("separation", 8)
	_pause_menu.add_child(box)
	var title := Label.new()
	title.text = "Pausado"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	var entries := [
		["Continuar", _toggle_pause],
		["Salvar / Carregar", _open_overlay.bind(SAVE_SLOTS_SCENE)],
		["Configurações", _open_overlay.bind(SETTINGS_SCENE)],
		["Voltar ao hub", func(): _resume(); show_screen(HUB_SCENE)],
		["Voltar ao título", func(): _resume(); show_title()],
	]
	for entry in entries:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(300, 46)
		button.pressed.connect(func(): SfxPlayer.play_click())
		button.pressed.connect(entry[1])
		box.add_child(button)

func _toggle_pause() -> void:
	if _overlay != null:
		_close_overlay()
		return
	_paused = not _paused
	get_tree().paused = _paused
	_pause_menu.visible = _paused

func _open_overlay(path: String) -> void:
	_pause_menu.visible = false
	_overlay = load(path).instantiate()
	_pause_layer.add_child(_overlay)

func _close_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
	_pause_menu.visible = _paused

func _resume() -> void:
	_paused = false
	get_tree().paused = false
	_pause_menu.visible = false
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null

func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if not _in_game or key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE:
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_F5:
		SaveManager.save_game()
	elif key_event.keycode == KEY_F9 and SaveManager.has_save():
		_load_and_enter(1)

func show_title() -> void:
	_in_game = false
	_resume()
	DialogueManager.cancel()
	for child in content_root.get_children():
		child.queue_free()
	_fade_in()
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
	if _overlay != null:
		_close_overlay()
		return
	if _in_game:
		show_screen(HUB_SCENE)
	else:
		show_title()

func load_slot(slot: int) -> void:
	_load_and_enter(slot)

func _load_and_enter(slot: int) -> void:
	_resume()
	DialogueManager.cancel()
	if SaveManager.load_game(slot):
		History.clear()
		enter_game()

func _refresh_continue_button() -> void:
	var any_save := false
	for slot in range(SaveManager.AUTOSAVE_SLOT, SaveManager.SLOT_COUNT + 1):
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

func _on_endings_pressed() -> void:
	SfxPlayer.play_click()
	title_screen.visible = false
	show_screen(GALLERY_SCENE)

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
	_fade_in()
	return screen

# Cada troca de tela surge de um preto suave em vez de um corte seco.
func _fade_in() -> void:
	_fade.modulate.a = 1.0
	create_tween().tween_property(_fade, "modulate:a", 0.0, FADE_SECONDS)
