extends Node

const SAMPLE_RATE := 44100.0
const CLICK_SECONDS := 0.05
const GLITCH_SECONDS := 0.4

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _click_left: int = 0
var _glitch_left: int = 0
var _time: float = 0.0
var _static_left: int = 0
var _static_total: int = 1
var _thud_left: int = 0
var _beat_clock: float = 0.0
var _beat_left: float = 0.0  # segundos restantes de batimento depois de uma cena de tensão
var _in_dialogue: bool = false
const THUD_SECONDS := 0.5
const SAMPLE_DIR := "res://assets/sfx/"
const AMBIENCE := {
	"rain": "rain.ogg",
	"night": "night_crickets.mp3",
	"wind": "birds_wind.ogg",
	"clock": "clock_tick.wav",
}
const AMBIENCE_DB := {"rain": -6.0, "night": -9.0, "wind": -13.0, "clock": -8.0}

var _amb_player: AudioStreamPlayer
var _amb_name: String = ""
var _sample_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.1
	_player.stream = generator
	_player.bus = GameSettings.BUS_SFX
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()
	EventBus.glitch_requested.connect(play_glitch)
	EventBus.horror_requested.connect(func(_kind, _data): _beat_left = 7.0)
	EventBus.dialogue_started.connect(func(_m): _in_dialogue = true)
	EventBus.dialogue_ended.connect(func(_id): _in_dialogue = false; set_ambience(""))
	EventBus.dialogue_cancelled.connect(func(): _in_dialogue = false; set_ambience(""))

func play_click() -> void:
	_click_left = int(SAMPLE_RATE * CLICK_SECONDS)

func play_glitch() -> void:
	_glitch_left = int(SAMPLE_RATE * GLITCH_SECONDS)

func _sample_stream(file: String) -> AudioStream:
	var stream = load(SAMPLE_DIR + file)
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	return stream

# Efeito pontual (porta, passos...): play_sample("door_open") toca assets/sfx/door_open.wav.
func play_sample(sample_name: String) -> void:
	var path := SAMPLE_DIR + sample_name + ".wav"
	if not ResourceLoader.exists(path):
		return
	var player: AudioStreamPlayer = null
	for p in _sample_players:
		if not p.playing:
			player = p
			break
	if player == null:
		player = AudioStreamPlayer.new()
		player.bus = GameSettings.BUS_SFX
		add_child(player)
		_sample_players.append(player)
	player.stream = load(path)
	player.play()

# Ambiência em loop (chuva...). set_ambience("") para parar.
func set_ambience(amb_name: String) -> void:
	if amb_name == _amb_name:
		return
	_amb_name = amb_name
	if _amb_player == null:
		_amb_player = AudioStreamPlayer.new()
		_amb_player.bus = GameSettings.BUS_SFX
		add_child(_amb_player)
		# WAV não tem loop embutido: recomeça quando termina.
		_amb_player.finished.connect(func(): if _amb_name != "": _amb_player.play())
	if amb_name == "" or not AMBIENCE.has(amb_name):
		_amb_player.stop()
		return
	_amb_player.stream = _sample_stream(AMBIENCE[amb_name])
	_amb_player.volume_db = float(AMBIENCE_DB.get(amb_name, -8.0))
	_amb_player.play()

func play_static(seconds: float = 0.6) -> void:
	_static_total = maxi(1, int(SAMPLE_RATE * seconds))
	_static_left = _static_total

func play_thud() -> void:
	_thud_left = int(SAMPLE_RATE * THUD_SECONDS)

# Batimento cardíaco: aparece com o pavor >= 40 e acelera/engrossa até 100.
func _heartbeat_sample(dread: int) -> float:
	var strength := clampf((dread - 40) / 60.0, 0.0, 1.0)
	if strength <= 0.0 or _beat_left <= 0.0 or not _in_dialogue or get_tree().paused:
		return 0.0
	var bpm := 58.0 + 80.0 * strength
	var period := 60.0 / bpm
	_beat_clock = fmod(_beat_clock + 1.0 / SAMPLE_RATE, period)
	var lub := _thump(_beat_clock)
	var dub := _thump(_beat_clock - period * 0.28) * 0.7
	return (lub + dub) * (0.12 + 0.4 * strength) * clampf(_beat_left / 2.0, 0.0, 1.0)

func _thump(t: float) -> float:
	if t < 0.0:
		return 0.0
	return sin(TAU * 48.0 * t) * exp(-t * 20.0)

func _process(delta: float) -> void:
	_beat_left = maxf(0.0, _beat_left - delta)
	if _playback == null:
		return
	var frames_available := _playback.get_frames_available()
	for i in range(frames_available):
		_time += 1.0 / SAMPLE_RATE
		var sample := 0.0
		if _click_left > 0:
			var envelope := float(_click_left) / (SAMPLE_RATE * CLICK_SECONDS)
			sample += sin(_time * TAU * 880.0) * 0.2 * envelope
			_click_left -= 1
		if _glitch_left > 0:
			sample += (randf() * 2.0 - 1.0) * 0.3 * (1.0 + sin(_time * 180.0) * 0.3)
			_glitch_left -= 1
		if _static_left > 0:
			var fade := float(_static_left) / float(_static_total)
			sample += (randf() * 2.0 - 1.0) * 0.35 * fade
			_static_left -= 1
		if _thud_left > 0:
			var env := float(_thud_left) / (SAMPLE_RATE * THUD_SECONDS)
			sample += sin(_time * TAU * 38.0) * 0.7 * env * env
			_thud_left -= 1
		sample += _heartbeat_sample(GameState.dread)
		_playback.push_frame(Vector2(sample, sample))
