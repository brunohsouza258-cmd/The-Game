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
var _in_dialogue: bool = false
const THUD_SECONDS := 0.5

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
	EventBus.dialogue_started.connect(func(_m): _in_dialogue = true)
	EventBus.dialogue_ended.connect(func(_id): _in_dialogue = false)
	EventBus.dialogue_cancelled.connect(func(): _in_dialogue = false)

func play_click() -> void:
	_click_left = int(SAMPLE_RATE * CLICK_SECONDS)

func play_glitch() -> void:
	_glitch_left = int(SAMPLE_RATE * GLITCH_SECONDS)

func play_static(seconds: float = 0.6) -> void:
	_static_total = maxi(1, int(SAMPLE_RATE * seconds))
	_static_left = _static_total

func play_thud() -> void:
	_thud_left = int(SAMPLE_RATE * THUD_SECONDS)

# Batimento cardíaco: aparece com o pavor >= 40 e acelera/engrossa até 100.
func _heartbeat_sample(dread: int) -> float:
	var strength := clampf((dread - 40) / 60.0, 0.0, 1.0)
	if strength <= 0.0 or not _in_dialogue or get_tree().paused:
		return 0.0
	var bpm := 58.0 + 80.0 * strength
	var period := 60.0 / bpm
	_beat_clock = fmod(_beat_clock + 1.0 / SAMPLE_RATE, period)
	var lub := _thump(_beat_clock)
	var dub := _thump(_beat_clock - period * 0.28) * 0.7
	return (lub + dub) * (0.12 + 0.4 * strength)

func _thump(t: float) -> float:
	if t < 0.0:
		return 0.0
	return sin(TAU * 48.0 * t) * exp(-t * 20.0)

func _process(_delta: float) -> void:
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
