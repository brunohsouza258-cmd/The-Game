extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var name_plate: Panel = $NamePlate
@onready var name_label: Label = $NamePlate/NameLabel
@onready var text_label: Label = $Panel/TextLabel
@onready var choices_container: VBoxContainer = $ChoicesContainer
@onready var type_timer: Timer = $TypeTimer
@onready var history_button: Button = $HistoryButton
@onready var history_panel: Panel = $HistoryPanel
@onready var history_list: VBoxContainer = $HistoryPanel/ScrollContainer/HistoryList
@onready var history_close_button: Button = $HistoryPanel/CloseButton
@onready var auto_button: Button = $AutoButton

const AUTO_SECONDS_PER_CHAR := 0.02
const SKIP_INTERVAL := 0.07

const PACES := {"slow": 2.5, "crawl": 5.0, "fast": 0.4}
const CORRUPT_GLYPHS := "█▓▒░#@%&§¤¿?¡"
const PANEL_HOME := Vector2(40, 520)

var _auto_timer: Timer
var _noauto: bool = false
var _pace: float = 1.0
var _node_serial: int = 0
var _corrupt_left: float = 0.0
var _corrupt_tick: float = 0.0
var _real_name: String = ""
var _name_garble_left: float = 0.0
var _skip_cooldown: float = 0.0

var _full_text: String = ""
var _char_index: int = 0
var _pending_choices: Array = []
var _name_color: Color = Color(1, 1, 1, 1)

func _ready() -> void:
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(1, 1, 1, 0.94)
	plate.set_corner_radius_all(10)
	plate.content_margin_left = 10.0
	plate.content_margin_right = 10.0
	name_plate.add_theme_stylebox_override("panel", plate)
	name_label.add_theme_color_override("font_color", Color(0.1, 0.06, 0.12))
	name_label.add_theme_font_size_override("font_size", 21)
	_hide_all()
	type_timer.timeout.connect(_on_type_tick)
	history_button.pressed.connect(_on_history_pressed)
	history_close_button.pressed.connect(_on_history_close_pressed)
	_auto_timer = Timer.new()
	_auto_timer.one_shot = true
	_auto_timer.timeout.connect(_on_auto_timeout)
	add_child(_auto_timer)
	auto_button.toggle_mode = true
	auto_button.button_pressed = GameSettings.auto_advance
	_refresh_auto_button()
	auto_button.toggled.connect(_on_auto_toggled)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_node_shown.connect(_on_node_shown)
	EventBus.dialogue_ended.connect(_on_dialogue_closed)
	EventBus.dialogue_cancelled.connect(_on_dialogue_closed)

# Segurar Ctrl avança o texto rápido (pula falas), sem tocar nas escolhas.
func _corrupt(text: String, chance: float = 0.22) -> String:
	var out := ""
	for ch in text:
		if ch != " " and ch != "
" and randf() < chance:
			out += CORRUPT_GLYPHS[randi() % CORRUPT_GLYPHS.length()]
		else:
			out += ch
	return out

# Com o pavor alto a própria interface "adoece": a caixa treme e o nome falha.
func _dread_interface(delta: float) -> void:
	var dread := GameState.dread
	if dread >= 70:
		var power := (dread - 60) / 40.0 * 2.5
		panel.position = PANEL_HOME + Vector2(randf_range(-power, power), randf_range(-power, power))
	else:
		panel.position = PANEL_HOME
	if _name_garble_left > 0.0:
		_name_garble_left -= delta
		if _name_garble_left <= 0.0:
			name_label.text = _real_name
	elif dread >= 75 and name_plate.visible and _real_name != "" and randf() < 0.01:
		name_label.text = _corrupt(_real_name, 0.6)
		_name_garble_left = 0.12

func _process(delta: float) -> void:
	if panel.visible:
		_dread_interface(delta)
	if _corrupt_left > 0.0:
		_corrupt_left -= delta
		_corrupt_tick -= delta
		if _corrupt_tick <= 0.0:
			_corrupt_tick = 0.07
			text_label.text = _corrupt(_full_text.substr(0, _char_index))
		if _corrupt_left <= 0.0:
			text_label.text = _full_text.substr(0, _char_index)
	if not panel.visible or history_panel.visible or not Input.is_key_pressed(KEY_CTRL):
		return
	_skip_cooldown -= delta
	if _skip_cooldown > 0.0:
		return
	_skip_cooldown = SKIP_INTERVAL
	if _char_index < _full_text.length():
		_finish_typing()
	elif _pending_choices.is_empty():
		_auto_timer.stop()
		DialogueManager.advance()

func _refresh_auto_button() -> void:
	auto_button.text = "Auto: Sim" if GameSettings.auto_advance else "Auto: Não"

func _on_auto_toggled(value: bool) -> void:
	SfxPlayer.play_click()
	GameSettings.set_auto_advance(value)
	_refresh_auto_button()
	if value:
		_start_auto_wait()
	else:
		_auto_timer.stop()

func _start_auto_wait() -> void:
	if not GameSettings.auto_advance or not panel.visible:
		return
	if _noauto or not _pending_choices.is_empty() or _char_index < _full_text.length():
		return
	_auto_timer.start(GameSettings.auto_seconds + _full_text.length() * AUTO_SECONDS_PER_CHAR)

func _on_auto_timeout() -> void:
	if history_panel.visible or not visible:
		_auto_timer.start(1.0)
		return
	if panel.visible and _pending_choices.is_empty():
		DialogueManager.advance()

func _toggle_hidden() -> void:
	visible = not visible

func _unhandled_input(event: InputEvent) -> void:
	# H ou botão direito esconde a caixa para ver o cenário; qualquer clique volta.
	if panel.visible:
		var key := event as InputEventKey
		var click := event as InputEventMouseButton
		var hide_key := key != null and key.pressed and not key.echo and key.keycode == KEY_H
		var hide_click := click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT
		if hide_key or hide_click:
			_toggle_hidden()
			get_viewport().set_input_as_handled()
			return
		if not visible and (event.is_action_pressed("ui_accept") or (click != null and click.pressed)):
			visible = true
			get_viewport().set_input_as_handled()
			return
	if not panel.visible or history_panel.visible or not event.is_action_pressed("ui_accept"):
		return
	if event is InputEventWithModifiers and event.alt_pressed:
		return
	get_viewport().set_input_as_handled()
	if _char_index < _full_text.length():
		_finish_typing()
	elif _pending_choices.is_empty():
		_advance()

func _on_dialogue_started(meta: Dictionary) -> void:
	panel.visible = true
	history_button.visible = true
	auto_button.visible = true
	auto_button.set_pressed_no_signal(GameSettings.auto_advance)
	_refresh_auto_button()
	var color_hex: String = meta.get("character_color", "")
	_name_color = Color(color_hex) if color_hex != "" else Color(1, 1, 1, 1)

func _on_node_shown(node_data: Dictionary) -> void:
	var speaker: String = node_data.get("speaker", "")
	_real_name = speaker
	name_label.text = speaker
	name_plate.visible = speaker != ""
	var node_color: String = node_data.get("color", "")
	name_plate.modulate = Color(node_color) if node_color != "" else _name_color
	_full_text = node_data.get("text", "")
	_pending_choices = node_data.get("choices", [])
	_char_index = 0
	text_label.text = ""
	_auto_timer.stop()
	_clear_choices()
	# Controle de ritmo por fala: "pace" (slow/crawl/fast/instant), "pause" (s antes do texto),
	# "noauto" (não avança sozinho) e "corrupt" (s de texto embaralhado).
	_noauto = bool(node_data.get("noauto", false))
	text_label.add_theme_font_size_override("font_size", roundi(22.0 * GameSettings.font_scale))
	var pace_key: String = str(node_data.get("pace", ""))
	_pace = 0.0 if pace_key == "instant" else float(PACES.get(pace_key, 1.0))
	_corrupt_left = float(node_data.get("corrupt", 0.0))
	_corrupt_tick = 0.0
	_node_serial += 1
	var pause := float(node_data.get("pause", 0.0))
	if pause > 0.0:
		get_tree().create_timer(pause).timeout.connect(_begin_typing.bind(_node_serial))
	else:
		_begin_typing(_node_serial)

func _begin_typing(serial: int) -> void:
	if serial != _node_serial or _full_text == "":
		return
	if _pace <= 0.0:
		_finish_typing()
		return
	type_timer.wait_time = max(GameSettings.text_speed * _pace, 0.001)
	type_timer.start()

func _on_type_tick() -> void:
	_char_index += 1
	text_label.text = _full_text.substr(0, _char_index)
	if _char_index >= _full_text.length():
		_finish_typing()

func _finish_typing() -> void:
	type_timer.stop()
	text_label.text = _full_text if _corrupt_left <= 0.0 else _corrupt(_full_text)
	_char_index = _full_text.length()
	_show_choices()
	_start_auto_wait()

func _show_choices() -> void:
	_clear_choices()
	if _pending_choices.is_empty():
		var continue_button := Button.new()
		continue_button.text = "Continuar"
		continue_button.pressed.connect(_advance)
		choices_container.add_child(continue_button)
	else:
		for i in _pending_choices.size():
			var choice: Dictionary = _pending_choices[i]
			var button := Button.new()
			button.text = choice.get("text", "")
			button.custom_minimum_size = Vector2(0, 40)
			button.pressed.connect(_choose.bind(i))
			choices_container.add_child(button)
	choices_container.visible = true

func _advance() -> void:
	_auto_timer.stop()
	SfxPlayer.play_click()
	DialogueManager.advance()

func _choose(index: int) -> void:
	_auto_timer.stop()
	SfxPlayer.play_click()
	DialogueManager.choose(index)

func _clear_choices() -> void:
	choices_container.visible = false
	for child in choices_container.get_children():
		child.queue_free()

func _on_dialogue_closed(_arg = null) -> void:
	type_timer.stop()
	_auto_timer.stop()
	_full_text = ""
	_pending_choices = []
	_hide_all()

func _hide_all() -> void:
	panel.visible = false
	name_plate.visible = false
	choices_container.visible = false
	history_button.visible = false
	auto_button.visible = false
	history_panel.visible = false

func _on_history_pressed() -> void:
	SfxPlayer.play_click()
	for child in history_list.get_children():
		child.queue_free()
	for entry in History.entries:
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		var speaker: String = entry.get("speaker", "")
		label.text = ("%s: %s" % [speaker, entry.get("text", "")]) if speaker != "" else entry.get("text", "")
		history_list.add_child(label)
	history_panel.visible = true

func _on_history_close_pressed() -> void:
	SfxPlayer.play_click()
	history_panel.visible = false
