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
var _warning_panel: Control
var _warning_ok: Button
var _boot_layer: CanvasLayer
var _boot_active: bool = true
var _sick_timer: Timer

func _ready() -> void:
	# Main continua recebendo input com o jogo pausado; o conteúdo do jogo pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for path in ["ContentRoot", "TitleScreen", "DialogueBox", "GlitchOverlay"]:
		var node := get_node_or_null(path)
		if node:
			node.process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_pause_menu()
	_build_content_warning()
	_build_sick_title()
	add_child(load("res://scripts/effects/HorrorFX.gd").new())
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

# Aviso de saúde e bem-estar: aparece SEMPRE que o jogo abre, antes do título e da música.
const WARNING_SECTIONS := [
	["Luzes e sons", "O jogo tem luzes piscantes, tremores de tela, falsas \"quedas\" do jogo e sons repentinos. Se você tem epilepsia ou sensibilidade à luz, ative a redução abaixo. Ajuste o volume antes de começar."],
	["Conteúdo", "Terror psicológico. Fala de luto, culpa, perda de um amigo, sugestão de morte e de autolesão, ansiedade e a sensação de estar preso. Não há cenas explícitas, mas pode ser pesado."],
	["Cuide de você", "Jogue em um lugar confortável e iluminado. Faça pausas a cada 30 a 60 minutos. Se algo ficar pesado, aperte Esc para pausar, ou feche o jogo. Você pode parar a qualquer momento."],
	["Se precisar de ajuda", "Se você está passando por um momento difícil ou pensando em se machucar, procure alguém. No Brasil, o CVV atende 24 horas, de graça, pelo telefone 188 ou em cvv.org.br. Em emergência, ligue 192 (SAMU)."],
	["Sobre o seu computador", "Em um dos finais o jogo mostra o nome de usuário do seu computador, só na tela. Nada é enviado para fora."],
]

func _build_content_warning() -> void:
	_boot_layer = CanvasLayer.new()
	_boot_layer.layer = 85
	add_child(_boot_layer)
	_warning_panel = Control.new()
	_warning_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boot_layer.add_child(_warning_panel)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.08, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_warning_panel.add_child(bg)
	var box := VBoxContainer.new()
	box.position = Vector2(170, 24)
	box.size = Vector2(940, 672)
	box.add_theme_constant_override("separation", 7)
	_warning_panel.add_child(box)
	var title := Label.new()
	title.text = "Antes de começar"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	for section in WARNING_SECTIONS:
		var head := Label.new()
		head.text = section[0]
		head.add_theme_font_size_override("font_size", 19)
		head.add_theme_color_override("font_color", Color(1.0, 0.82, 0.9))
		box.add_child(head)
		var body := Label.new()
		body.text = section[1]
		body.autowrap_mode = TextServer.AUTOWRAP_WORD
		body.custom_minimum_size = Vector2(940, 0)
		body.add_theme_font_size_override("font_size", 17)
		box.add_child(body)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	_warning_ok = Button.new()
	_warning_ok.custom_minimum_size = Vector2(0, 42)
	_warning_ok.disabled = true
	_warning_ok.pressed.connect(_accept_warning.bind(false))
	box.add_child(_warning_ok)
	var calm := Button.new()
	calm.text = "Ativar redução de luzes e tremores e continuar"
	calm.custom_minimum_size = Vector2(0, 42)
	calm.pressed.connect(_accept_warning.bind(true))
	box.add_child(calm)
	var quit_button := Button.new()
	quit_button.text = "Sair do jogo"
	quit_button.custom_minimum_size = Vector2(0, 38)
	quit_button.pressed.connect(func(): get_tree().quit())
	box.add_child(quit_button)
	_boot_countdown()

# O botão de continuar libera depois de alguns segundos, para dar tempo de ler.
func _boot_countdown() -> void:
	for remaining in range(4, 0, -1):
		_warning_ok.text = "Li e quero continuar (%d)" % remaining
		await get_tree().create_timer(1.0).timeout
	_warning_ok.text = "Li e quero continuar"
	_warning_ok.disabled = false

func _accept_warning(reduce: bool) -> void:
	SfxPlayer.play_click()
	if reduce:
		GameSettings.set_reduce_flashing(true)
	GameSettings.mark_content_warning_seen()
	_boot_layer.visible = false
	_boot_active = false
	MusicPlayer.play_mood("title")

# Depois dos finais, a tela de título "adoece": o nome falha e as garotas somem por instantes.
func _build_sick_title() -> void:
	_sick_timer = Timer.new()
	_sick_timer.wait_time = 7.0
	_sick_timer.autostart = true
	_sick_timer.timeout.connect(_title_glitch)
	add_child(_sick_timer)

func _title_glitch() -> void:
	var endings := GameSettings.unlocked_endings.size()
	if endings == 0 or not title_screen.visible or not menu_panel.visible or randf() < 0.35:
		return
	var title: Label = $TitleScreen/TitleLabel
	var author: Label = $TitleScreen/AuthorLabel
	var original_title := "Lanternas de Papel"
	var original_author := "um jogo de Bruno"
	var glyphs := "█▓▒░#@%&"
	var broken := ""
	for ch in original_title:
		broken += glyphs[randi() % glyphs.length()] if (ch != " " and randf() < 0.3) else ch
	title.text = broken
	if endings >= 8:
		author.text = "obrigado por soltar"
	elif endings >= 3:
		author.text = ["ele ainda está aqui", "volta", "segura a minha mão", "21:47"].pick_random()
	var cast := [$TitleScreen/CastMaya, $TitleScreen/CastYuna, $TitleScreen/CastAlice, $TitleScreen/CastHikari]
	var victim: Control = null
	if endings >= 3 and not GameSettings.reduce_flashing:
		victim = cast.pick_random()
		victim.modulate = Color(0, 0, 0, 0.95)
	await get_tree().create_timer(0.3).timeout
	title.text = original_title
	author.text = original_author
	if victim:
		victim.modulate = Color.WHITE

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
	var joy := event as InputEventJoypadButton
	if joy != null and joy.pressed and joy.button_index == JOY_BUTTON_START and _in_game:
		_toggle_pause()
		return
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
	if not _boot_active:
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
	_open_name_prompt()

func _open_name_prompt() -> void:
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
