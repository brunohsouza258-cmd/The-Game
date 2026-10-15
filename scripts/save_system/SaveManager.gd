extends Node

const SAVE_PATH_FORMAT := "user://save_slot_%d.json"
const SLOT_COUNT := 3
const AUTOSAVE_SLOT := 0
const THUMB_PATH_FORMAT := "user://save_slot_%d.png"

func autosave() -> void:
	save_game(AUTOSAVE_SLOT)

func save_game(slot: int = 1) -> void:
	var file := FileAccess.open(SAVE_PATH_FORMAT % slot, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível salvar o jogo: %s" % FileAccess.get_open_error())
		return
	var data := GameState.to_dict()
	data["saved_at"] = Time.get_datetime_string_from_system(false, true).substr(0, 16)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var image := get_viewport().get_texture().get_image()
	if image != null and not image.is_empty():
		image.resize(320, 180, Image.INTERPOLATE_BILINEAR)
		image.save_png(THUMB_PATH_FORMAT % slot)

func load_game(slot: int = 1) -> bool:
	if not has_save(slot):
		return false
	var data := _read_slot(slot)
	if data.is_empty():
		return false
	GameState.from_dict(data)
	return true

func has_save(slot: int = 1) -> bool:
	return FileAccess.file_exists(SAVE_PATH_FORMAT % slot)

func thumbnail(slot: int) -> Texture2D:
	var path := THUMB_PATH_FORMAT % slot
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	return ImageTexture.create_from_image(image) if image != null else null

func peek(slot: int) -> Dictionary:
	return _read_slot(slot)

func _read_slot(slot: int) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH_FORMAT % slot):
		return {}
	var file := FileAccess.open(SAVE_PATH_FORMAT % slot, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
