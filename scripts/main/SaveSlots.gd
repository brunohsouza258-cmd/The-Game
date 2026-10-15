extends Control

@onready var slots_container: VBoxContainer = $SlotsContainer
@onready var back_button: Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_slots()

func _build_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		var row := HBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size = Vector2(360, 0)
		label.text = _slot_description(slot)
		row.add_child(label)

		var save_button := Button.new()
		save_button.text = "Salvar"
		save_button.disabled = not get_tree().current_scene.is_in_game()
		save_button.pressed.connect(_on_save_pressed.bind(slot))
		row.add_child(save_button)

		var load_button := Button.new()
		load_button.text = "Carregar"
		load_button.disabled = not SaveManager.has_save(slot)
		load_button.pressed.connect(_on_load_pressed.bind(slot))
		row.add_child(load_button)

		slots_container.add_child(row)

func _slot_description(slot: int) -> String:
	var data := SaveManager.peek(slot)
	if data.is_empty():
		return "Slot %d — vazio" % slot
	var player_name: String = data.get("player_name", "Jogador")
	var day: int = data.get("day", 1)
	return "Slot %d — %s, dia %d" % [slot, player_name, day]

func _on_save_pressed(slot: int) -> void:
	SfxPlayer.play_click()
	SaveManager.save_game(slot)
	_build_slots()

func _on_load_pressed(slot: int) -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.load_slot(slot)

func _on_back_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.return_from_menu()
