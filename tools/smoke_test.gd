extends SceneTree

# Teste de fumaça sem janela:
#   Godot --headless --path . --script tools/smoke_test.gd
# Toca cada diálogo do início ao fim (sempre escolhendo a primeira opção) e
# abre as telas principais. Sai com código 1 se algo falhar.

const MAX_STEPS := 600
var _failures: Array = []

func _initialize() -> void:
	var dm = root.get_node("DialogueManager")
	var gs = root.get_node("GameState")
	var files := DirAccess.get_files_at("res://data/dialogue")
	files.sort()
	var played := 0
	for f in files:
		if not f.ends_with(".json"):
			continue
		gs.reset_for_new_game("Teste")
		dm.start_dialogue("res://data/dialogue/" + f)
		var steps := 0
		while dm._active and steps < MAX_STEPS:
			var node: Dictionary = dm._dialogue_data.get("nodes", {}).get(dm._current_node_id, {})
			var choices: Array = dm._available_choices(node.get("choices", []))
			if choices.is_empty():
				dm.advance()
			else:
				dm.choose(0)
			steps += 1
		if dm._active:
			_failures.append("%s não terminou em %d passos" % [f, MAX_STEPS])
			dm.cancel()
		played += 1
	print("diálogos jogados: %d" % played)

	var main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	gs.reset_for_new_game("Teste")
	gs.last_seen_main_event_day = 1
	for scene_path in [
		"res://scenes/main/Hub.tscn", "res://scenes/main/Settings.tscn",
		"res://scenes/main/SaveSlots.tscn", "res://scenes/main/EndingsGallery.tscn",
		"res://scenes/main/Credits.tscn", "res://scenes/main/Diary.tscn", "res://scenes/poem/PoemGame.tscn",
		"res://scenes/ending/EndingScene.tscn", "res://scenes/vn/VNScene.tscn",
	]:
		if load(scene_path) == null:
			_failures.append("não carregou: " + scene_path)
			continue
		main.show_screen(scene_path)
		await create_timer(0.1).timeout

	for f in _failures:
		printerr("FALHA: ", f)
	print("OK" if _failures.is_empty() else "%d falha(s)" % _failures.size())
	quit(0 if _failures.is_empty() else 1)
