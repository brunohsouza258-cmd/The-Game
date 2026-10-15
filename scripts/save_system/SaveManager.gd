extends Node

const SAVE_PATH_FORMAT := "user://save_slot_%d.json"
const SLOT_COUNT := 3

func save_game(slot: int = 1) -> void:
	var file := FileAccess.open(SAVE_PATH_FORMAT % slot, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível salvar o jogo: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	file.close()

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
