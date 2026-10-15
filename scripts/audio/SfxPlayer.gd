extends Node

const SAMPLE_RATE := 44100.0
const CLICK_SECONDS := 0.05
const GLITCH_SECONDS := 0.4

var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _click_left: int = 0
var _glitch_left: int = 0
var _time: float = 0.0

func _ready() -> void:
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

func play_click() -> void:
	_click_left = int(SAMPLE_RATE * CLICK_SECONDS)

func play_glitch() -> void:
	_glitch_left = int(SAMPLE_RATE * GLITCH_SECONDS)

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
		_playback.push_frame(Vector2(sample, sample))
