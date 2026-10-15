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

var _full_text: String = ""
var _char_index: int = 0
var _pending_choices: Array = []
var _name_color: Color = Color(1, 1, 1, 1)

func _ready() -> void:
	_hide_all()
	type_timer.timeout.connect(_on_type_tick)
	history_button.pressed.connect(_on_history_pressed)
	history_close_button.pressed.connect(_on_history_close_pressed)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_node_shown.connect(_on_node_shown)
	EventBus.dialogue_ended.connect(_on_dialogue_closed)
	EventBus.dialogue_cancelled.connect(_on_dialogue_closed)

func _unhandled_input(event: InputEvent) -> void:
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
	var color_hex: String = meta.get("character_color", "")
	_name_color = Color(color_hex) if color_hex != "" else Color(1, 1, 1, 1)

func _on_node_shown(node_data: Dictionary) -> void:
	var speaker: String = node_data.get("speaker", "")
	name_label.text = speaker
	name_plate.visible = speaker != ""
	name_plate.modulate = _name_color
	_full_text = node_data.get("text", "")
	_pending_choices = node_data.get("choices", [])
	_char_index = 0
	text_label.text = ""
	_clear_choices()
	type_timer.wait_time = max(GameSettings.text_speed, 0.001)
	type_timer.start()

func _on_type_tick() -> void:
	_char_index += 1
	text_label.text = _full_text.substr(0, _char_index)
	if _char_index >= _full_text.length():
		_finish_typing()

func _finish_typing() -> void:
	type_timer.stop()
	text_label.text = _full_text
	_char_index = _full_text.length()
	_show_choices()

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
	SfxPlayer.play_click()
	DialogueManager.advance()

func _choose(index: int) -> void:
	SfxPlayer.play_click()
	DialogueManager.choose(index)

func _clear_choices() -> void:
	choices_container.visible = false
	for child in choices_container.get_children():
		child.queue_free()

func _on_dialogue_closed(_arg = null) -> void:
	type_timer.stop()
	_full_text = ""
	_pending_choices = []
	_hide_all()

func _hide_all() -> void:
	panel.visible = false
	name_plate.visible = false
	choices_container.visible = false
	history_button.visible = false
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
