extends SceneTree

# Simulador de partidas (sem janela):
#   Godot --headless --path . --script tools/simulate.gd
# Joga a história inteira N vezes com várias estratégias e conta quais finais saem,
# para checar se todos são alcançáveis e se algum domina o jogo.

const RUNS_PER_STRATEGY := 400
const GIRLS := ["maya", "yuna", "alice", "hikari"]
const LATE_DAYS := [3, 5, 6, 8, 10, 11]

var _dm
var _gs
var _settings
var _ending_script
var _words: Array = []

func _initialize() -> void:
	_dm = root.get_node("DialogueManager")
	_gs = root.get_node("GameState")
	_settings = root.get_node("GameSettings")
	_ending_script = load("res://scripts/ending/EndingScene.gd").new()
	var file := FileAccess.open("res://data/poems/word_bank.json", FileAccess.READ)
	_words = JSON.parse_string(file.get_as_text()).get("words", [])
	file.close()
	var saved_loops: int = _settings.loop_count
	var strategies := [
		{"name": "aleatório, fala com todas, 1ª partida", "girls": "all", "policy": "random", "loops": 1},
		{"name": "aleatório, fala com todas, 3ª partida", "girls": "all", "policy": "random", "loops": 3},
		{"name": "conforto (baixo pavor), todas", "girls": "all", "policy": "comfort", "loops": 1},
		{"name": "investigar (alto pavor), todas", "girls": "all", "policy": "investigate", "loops": 1},
		{"name": "investigar, 3ª partida, todas", "girls": "all", "policy": "investigate", "loops": 3},
		{"name": "aleatório, só uma garota", "girls": "focus", "policy": "random", "loops": 1},
		{"name": "investigar, só uma garota", "girls": "focus", "policy": "investigate", "loops": 1},
		{"name": "conforto, só uma garota", "girls": "focus", "policy": "comfort", "loops": 1},
		{"name": "aleatório, pula tudo (só avança o dia)", "girls": "none", "policy": "random", "loops": 1},
	]
	for strat in strategies:
		var counts := {}
		for i in RUNS_PER_STRATEGY:
			var ending := _play_run(strat)
			counts[ending] = int(counts.get(ending, 0)) + 1
		print("%s -> %s" % [strat["name"], JSON.stringify(counts)])
	_settings.loop_count = saved_loops
	quit()

func _play_run(strat: Dictionary) -> String:
	_gs.reset_for_new_game("Sim")
	_settings.loop_count = int(strat["loops"])
	var focus: String = GIRLS[randi() % GIRLS.size()]
	for day in range(1, 13):
		_gs.day = day
		_play("res://data/dialogue/main_day%d.json" % day, strat["policy"])
		if day >= 2 and day < 12:
			if strat["girls"] != "none":
				_talk_day(day, strat, focus)
			_poem(strat, focus)
			var walk := "res://data/dialogue/extra_day%d.json" % day
			if FileAccess.file_exists(walk):
				_play(walk, strat["policy"])
			if LATE_DAYS.has(day):
				_play("res://data/dialogue/late_day%d.json" % day, strat["policy"])
		if day >= 9:
			var route := _route_character()
			if route != "":
				_play("res://data/dialogue/route_%s_day%d.json" % [route, day], strat["policy"])
		if day == 12:
			if strat["girls"] != "none":
				_talk_day(day, strat, focus)
			_play("res://data/dialogue/extra_day12.json", strat["policy"])
		else:
			# virar o dia: quem não foi visitada perde 1 de afinidade
			for g in GIRLS:
				if not _gs.visited_today(g):
					_gs.change_affinity(g, -1)
	return _ending_script._determine_ending()

func _talk_day(day: int, strat: Dictionary, focus: String) -> void:
	for g in GIRLS:
		if strat["girls"] == "focus" and g != focus:
			continue
		var path := "res://data/dialogue/%s_day%d.json" % [g, day]
		if FileAccess.file_exists(path):
			_gs.mark_visited(g)
			_play(path, strat["policy"])

func _route_character() -> String:
	var best := ""
	var best_value := -999
	var tied := false
	for g in GIRLS:
		var v := int(_gs.affinity.get(g, 0))
		if v > best_value:
			best = g
			best_value = v
			tied = false
		elif v == best_value:
			tied = true
	if tied or best_value < 8:
		return ""
	var path := "res://data/dialogue/route_%s_day%d.json" % [best, _gs.day]
	return best if FileAccess.file_exists(path) else ""

# Poema: 5 palavras de 18 sorteadas; no foco, escolhe as que mais combinam com a garota.
func _poem(strat: Dictionary, focus: String) -> void:
	var pool := _words.duplicate()
	pool.shuffle()
	pool = pool.slice(0, 18)
	var picks: Array = []
	if strat["girls"] == "focus":
		pool.sort_custom(func(a, b): return int(a.get("weights", {}).get(focus, 0)) > int(b.get("weights", {}).get(focus, 0)))
		picks = pool.slice(0, 5)
	else:
		picks = pool.slice(0, 5)
	var totals := {}
	for g in GIRLS:
		totals[g] = 0
		for w in picks:
			totals[g] += int(w.get("weights", {}).get(g, 0))
	var winner := ""
	for g in GIRLS:
		if winner == "" or totals[g] > totals[winner]:
			winner = g
	var score: int = totals[winner]
	var affinity_gain := 3 if score >= 10 else (1 if score >= 5 else 0)
	var trust_gain := 2 if score >= 10 else (1 if score >= 5 else -1)
	_gs.change_affinity(winner, affinity_gain)
	_gs.change_trust(winner, trust_gain)
	for g in GIRLS:
		if g != winner and totals[g] >= 6:
			_gs.change_affinity(g, 1)

func _play(path: String, policy: String) -> void:
	_dm.start_dialogue(path)
	var steps := 0
	while _dm._active and steps < 800:
		var node: Dictionary = _dm._dialogue_data.get("nodes", {}).get(_dm._current_node_id, {})
		var choices: Array = _dm._available_choices(node.get("choices", []))
		if choices.is_empty():
			_dm.advance()
		else:
			_dm.choose(_pick(choices, policy))
		steps += 1
	_dm.cancel()

func _pick(choices: Array, policy: String) -> int:
	if policy == "random":
		return randi() % choices.size()
	var best := 0
	var best_score := -9999
	for i in choices.size():
		var eff: Dictionary = choices[i].get("effects", {})
		var dread := int(eff.get("dread", 0))
		var score := dread if policy == "investigate" else -dread
		score += int(eff.get("flags.accept_loss", false)) * (3 if policy == "comfort" else 0)
		if score > best_score:
			best_score = score
			best = i
	return best
