extends Node

var entries: Array = []

func _ready() -> void:
	EventBus.dialogue_node_shown.connect(_on_node_shown)

func _on_node_shown(node_data: Dictionary) -> void:
	var text: String = node_data.get("text", "")
	if text == "":
		return
	entries.append({"speaker": node_data.get("speaker", ""), "text": text})

func clear() -> void:
	entries.clear()
