extends Node

var _dialogue_data: Dictionary = {}
var _current_node_id: String = ""
var _active: bool = false

func start_dialogue(json_path: String, start_node_id: String = "start") -> void:
	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("Diálogo não encontrado: %s" % json_path)
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JSON de diálogo inválido: %s" % json_path)
		return
	_dialogue_data = GameSettings.localize_dialogue(parsed)
	_current_node_id = start_node_id
	_active = true
	EventBus.dialogue_started.emit(_dialogue_data)
	_show_current_node()

func cancel() -> void:
	if not _active:
		return
	_active = false
	_dialogue_data = {}
	EventBus.dialogue_cancelled.emit()

func choose(choice_index: int) -> void:
	if not _active:
		return
	var node: Dictionary = _dialogue_data.get("nodes", {}).get(_current_node_id, {})
	var choices: Array = _available_choices(node.get("choices", []))
	if choice_index < 0 or choice_index >= choices.size():
		return
	var choice: Dictionary = choices[choice_index]
	var effects: Dictionary = choice.get("effects", {})
	for key in effects.keys():
		GameState.apply_effect(key, effects[key])
	GameState.choice_history.append(choice.get("text", ""))
	EventBus.choice_made.emit(choice.get("text", ""), effects)
	_current_node_id = choice.get("next", "end")
	_show_current_node()

func advance() -> void:
	if not _active:
		return
	var node: Dictionary = _dialogue_data.get("nodes", {}).get(_current_node_id, {})
	if node.get("choices", []).is_empty() or _available_choices(node.get("choices", [])).is_empty():
		if not node.get("choices", []).is_empty() and not node.has("next"):
			push_warning("Todas as escolhas de '%s' foram filtradas e o nó não tem 'next'; encerrando." % _current_node_id)
		_current_node_id = node.get("next", "end")
		_show_current_node()

func _show_current_node() -> void:
	var node: Dictionary = _dialogue_data.get("nodes", {}).get(_current_node_id, {})
	if node.is_empty() or node.get("end", false):
		_active = false
		EventBus.dialogue_ended.emit(_dialogue_data.get("id", ""))
		return
	# "if": o nó só aparece se todos os requisitos forem atendidos; senão, segue para o "next".
	var condition: Dictionary = node.get("if", {})
	for key in condition.keys():
		if not GameState.meets_requirement(key, int(condition[key])):
			_current_node_id = node.get("next", "end")
			_show_current_node()
			return
	var node_effects: Dictionary = node.get("effects", {})
	for key in node_effects.keys():
		GameState.apply_effect(key, node_effects[key])
	var display_node: Dictionary = node.duplicate(true)
	display_node["text"] = _interpolate(node.get("text", ""))
	display_node["choices"] = _available_choices(node.get("choices", []))
	EventBus.dialogue_node_shown.emit(display_node)
	# "fx": glitch | static | flash_red | blackout | thud | shake | crash (ver HorrorFX.gd)
	if node.has("sfx"):
		SfxPlayer.play_sample(str(node["sfx"]))
	if node.has("amb"):
		SfxPlayer.set_ambience(str(node["amb"]))
	var fx: String = str(node.get("fx", ""))
	if node.get("effect", "") == "glitch" and fx == "":
		fx = "glitch"
	if fx != "":
		EventBus.horror_requested.emit(fx, display_node)

func _available_choices(choices: Array) -> Array:
	var available := []
	for choice in choices:
		var requires: Dictionary = choice.get("requires", {})
		var ok := true
		for key in requires.keys():
			if not GameState.meets_requirement(key, int(requires[key])):
				ok = false
				break
		if ok:
			var c: Dictionary = choice.duplicate(true)
			c["text"] = _interpolate(choice.get("text", ""))
			available.append(c)
	return available

func _interpolate(text: String) -> String:
	return text.format({
		"player_name": GameState.player_name,
		"loop_count": GameSettings.loop_count,
		"day": GameState.day,
		"poem_word": GameState.poem_word,
	})
