extends Node

const CHARACTERS := ["maya", "yuna", "alice", "hikari"]
const RELATIONSHIP_MIN := -30
const RELATIONSHIP_MAX := 30

var affinity: Dictionary = {}
var trust: Dictionary = {}
var flags: Dictionary = {}
var choice_history: Array = []
var visited: Dictionary = {}
var player_name: String = "Jogador"
var day: int = 1
var dread: int = 0
var last_seen_main_event_day: int = 0

func _ready() -> void:
	reset_for_new_game(player_name)

func reset_for_new_game(new_name: String) -> void:
	player_name = new_name
	day = 1
	dread = 0
	last_seen_main_event_day = 0
	flags.clear()
	choice_history.clear()
	visited.clear()
	for char_id in CHARACTERS:
		affinity[char_id] = 0
		trust[char_id] = 0

func change_affinity(char_id: String, amount: int) -> void:
	affinity[char_id] = clampi(int(affinity.get(char_id, 0)) + amount, RELATIONSHIP_MIN, RELATIONSHIP_MAX)

func change_trust(char_id: String, amount: int) -> void:
	trust[char_id] = clampi(int(trust.get(char_id, 0)) + amount, RELATIONSHIP_MIN, RELATIONSHIP_MAX)

func change_dread(amount: int) -> void:
	dread = clampi(dread + amount, 0, 100)

func set_flag(flag_name: String, value: bool) -> void:
	flags[flag_name] = value

func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func mark_visited(key: String) -> void:
	visited[key] = day

func visited_today(key: String) -> bool:
	return int(visited.get(key, -1)) == day

func meets_requirement(key: String, min_value: int) -> bool:
	match key:
		"dread":
			return dread >= min_value
		"loop":
			return GameSettings.loop_count >= min_value
	var parts := key.split(".")
	if parts.size() != 2:
		return true
	var category := parts[0]
	var char_id := parts[1]
	match category:
		"affinity":
			return int(affinity.get(char_id, 0)) >= min_value
		"trust":
			return int(trust.get(char_id, 0)) >= min_value
		"flags":
			# "flags.x": 1 requires the flag set; "flags.x": 0 requires it unset.
			return has_flag(char_id) == (min_value > 0)
		_:
			return true

func apply_effect(key: String, value) -> void:
	if key == "dread":
		change_dread(int(value))
		return
	var parts := key.split(".")
	if parts.size() != 2:
		return
	var category := parts[0]
	var target := parts[1]
	match category:
		"affinity":
			change_affinity(target, int(value))
		"trust":
			change_trust(target, int(value))
		"flags":
			set_flag(target, bool(value))

func to_dict() -> Dictionary:
	return {
		"version": 2,
		"affinity": affinity,
		"trust": trust,
		"flags": flags,
		"choice_history": choice_history,
		"visited": visited,
		"player_name": player_name,
		"day": day,
		"dread": dread,
		"last_seen_main_event_day": last_seen_main_event_day,
	}

func from_dict(data: Dictionary) -> void:
	affinity = data.get("affinity", affinity)
	trust = data.get("trust", trust)
	flags = data.get("flags", {})
	choice_history = data.get("choice_history", [])
	visited = data.get("visited", {})
	player_name = data.get("player_name", "Jogador")
	day = int(data.get("day", 1))
	dread = int(data.get("dread", 0))
	last_seen_main_event_day = int(data.get("last_seen_main_event_day", 0))
