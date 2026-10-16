extends Node

const FADE_SECONDS := 1.5
const SILENT_DB := -60.0
const GLITCH_DURATION := 0.4

const MOOD_TRACKS := {
	"title": "res://assets/music/title_yoiyami_core_theme.wav",
	"menu": "res://assets/music/calm_relax.mp3",
	"classroom": "res://assets/music/contemplation.mp3",
	"clubroom": "res://assets/music/happy_clappy_loop.wav",
	"courtyard": "res://assets/music/happy_clappy_loop.wav",
	"festival": "res://assets/music/menu_loop.mp3",
	"hallway": "res://assets/music/starfield_romance.wav",
	"night": "res://assets/music/emerald_tower.ogg",
	"tense": "res://assets/music/insistent.ogg",
	"sad": "res://assets/music/sadness.ogg",
	"piano": "res://assets/music/piano_loop.wav",
	"corrupted": "res://assets/music/abandoned_passages.ogg",
	"ending": "res://assets/music/first_light_particles.wav",
}

var _players: Array[AudioStreamPlayer] = []
var _active: int = 0
var _current_path: String = ""
var _tween: Tween
var _time: float = 0.0
var _glitch_time: float = -1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = GameSettings.BUS_MUSIC
		player.volume_db = SILENT_DB
		player.finished.connect(player.play)
		add_child(player)
		_players.append(player)
	EventBus.glitch_requested.connect(_on_glitch_requested)

func play_mood(mood_id: String) -> void:
	var path: String = MOOD_TRACKS.get(mood_id, "")
	if path == "" or path == _current_path:
		return
	_current_path = path
	if _tween:
		_tween.kill()
	var outgoing := _players[_active]
	_active = 1 - _active
	var incoming := _players[_active]
	incoming.stream = load(path)
	incoming.volume_db = SILENT_DB
	incoming.play()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(incoming, "volume_db", 0.0, FADE_SECONDS)
	_tween.tween_property(outgoing, "volume_db", SILENT_DB, FADE_SECONDS)
	_tween.chain().tween_callback(outgoing.stop)

func _on_glitch_requested() -> void:
	_glitch_time = 0.0

func _process(delta: float) -> void:
	_time += delta
	var pitch := 1.0
	if _glitch_time >= 0.0:
		_glitch_time += delta
		pitch = 1.0 + sin(_time * 40.0) * 0.15
		if _glitch_time > GLITCH_DURATION:
			_glitch_time = -1.0
			pitch = 1.0
	for player in _players:
		player.pitch_scale = pitch
