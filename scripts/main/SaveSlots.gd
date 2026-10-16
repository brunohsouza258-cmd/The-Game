extends Control

@onready var slots_container: VBoxContainer = $SlotsContainer
@onready var back_button: Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_build_slots()

func _build_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	for slot in range(SaveManager.AUTOSAVE_SLOT, SaveManager.SLOT_COUNT + 1):
		var row := HBoxContainer.new()
		var thumb := TextureRect.new()
		thumb.custom_minimum_size = Vector2(128, 72)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.texture = SaveManager.thumbnail(slot)
		row.add_child(thumb)
		var label := Label.new()
		label.custom_minimum_size = Vector2(560, 0)
		label.text = _slot_description(slot)
		row.add_child(label)

		var save_button := Button.new()
		save_button.text = "Salvar"
		save_button.disabled = slot == SaveManager.AUTOSAVE_SLOT or not get_tree().current_scene.is_in_game()
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
	var label := tr("Autosave") if slot == SaveManager.AUTOSAVE_SLOT else tr("Slot %d") % slot
	if data.is_empty():
		return tr("%s — vazio") % label
	var player_name: String = data.get("player_name", "Jogador")
	var day: int = data.get("day", 1)
	var stamp: String = data.get("saved_at", "")
	var base := tr("%s — %s, dia %d") % [label, player_name, day]
	return base if stamp == "" else "%s (%s)" % [base, stamp]

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
