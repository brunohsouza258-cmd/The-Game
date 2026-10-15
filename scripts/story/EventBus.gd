extends Node

signal dialogue_started(dialogue_meta: Dictionary)
signal dialogue_node_shown(node_data: Dictionary)
signal dialogue_ended(dialogue_id: String)
signal dialogue_cancelled()
signal choice_made(choice_text: String, effects: Dictionary)
signal glitch_requested()
signal horror_requested(kind: String, data: Dictionary)
