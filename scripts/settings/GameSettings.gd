extends Node

const CONFIG_PATH := "user://settings.cfg"
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var text_speed: float = 0.03
var fullscreen: bool = false
# Avanço automático: espera auto_seconds + um tempo proporcional ao tamanho da fala.
var auto_advance: bool = true
# Acessibilidade: tira flashes fortes e tremores; escala do texto da caixa de diálogo.
var reduce_flashing: bool = false
var font_scale: float = 1.0
var content_warning_seen: bool = false
# Aviso de saúde: reaparece quando passam WARNING_DAYS desde a última confirmação.
const WARNING_DAYS := 7
var warning_ack_time: int = 0
var auto_seconds: float = 2.0
# Persists across new games: how many times the player has started this story.
var loop_count: int = 0
# Finais já vistos (persiste entre partidas, como o loop_count).
var unlocked_endings: Array = []

func _ready() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)
	load_settings()

func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var toggle := key_event.keycode == KEY_F11 or (key_event.keycode == KEY_ENTER and key_event.alt_pressed)
	if toggle:
		set_fullscreen(not fullscreen)
		get_viewport().set_input_as_handled()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, BUS_MASTER)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		master_volume = config.get_value("audio", "master", master_volume)
		music_volume = config.get_value("audio", "music", music_volume)
		sfx_volume = config.get_value("audio", "sfx", sfx_volume)
		text_speed = config.get_value("text", "speed", text_speed)
		fullscreen = config.get_value("display", "fullscreen", fullscreen)
		auto_advance = config.get_value("text", "auto_advance", auto_advance)
		auto_seconds = config.get_value("text", "auto_seconds", auto_seconds)
		reduce_flashing = config.get_value("access", "reduce_flashing", reduce_flashing)
		font_scale = config.get_value("access", "font_scale", font_scale)
		content_warning_seen = config.get_value("access", "content_warning_seen", content_warning_seen)
		warning_ack_time = int(config.get_value("access", "warning_ack_time", warning_ack_time))
		loop_count = config.get_value("meta", "loop_count", loop_count)
		unlocked_endings = config.get_value("meta", "unlocked_endings", unlocked_endings)
	_apply_all()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("text", "speed", text_speed)
	config.set_value("text", "auto_advance", auto_advance)
	config.set_value("text", "auto_seconds", auto_seconds)
	config.set_value("access", "reduce_flashing", reduce_flashing)
	config.set_value("access", "font_scale", font_scale)
	config.set_value("access", "content_warning_seen", content_warning_seen)
	config.set_value("access", "warning_ack_time", warning_ack_time)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("meta", "loop_count", loop_count)
	config.set_value("meta", "unlocked_endings", unlocked_endings)
	config.save(CONFIG_PATH)

func set_master_volume(value: float) -> void:
	master_volume = value
	_apply_volume(BUS_MASTER, value)
	save_settings()

func set_music_volume(value: float) -> void:
	music_volume = value
	_apply_volume(BUS_MUSIC, value)
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = value
	_apply_volume(BUS_SFX, value)
	save_settings()

func set_text_speed(value: float) -> void:
	text_speed = value
	save_settings()

func set_auto_advance(value: bool) -> void:
	auto_advance = value
	save_settings()

func set_reduce_flashing(value: bool) -> void:
	reduce_flashing = value
	save_settings()

func set_font_scale(value: float) -> void:
	font_scale = value
	save_settings()

func health_warning_due() -> bool:
	if warning_ack_time <= 0:
		return true
	return int(Time.get_unix_time_from_system()) - warning_ack_time >= WARNING_DAYS * 86400

func mark_content_warning_seen() -> void:
	content_warning_seen = true
	warning_ack_time = int(Time.get_unix_time_from_system())
	save_settings()

func set_auto_seconds(value: float) -> void:
	auto_seconds = value
	save_settings()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_fullscreen()
	save_settings()

func reset_to_defaults() -> void:
	master_volume = 0.8
	music_volume = 0.7
	sfx_volume = 0.8
	text_speed = 0.03
	auto_advance = true
	auto_seconds = 2.0
	reduce_flashing = false
	font_scale = 1.0
	fullscreen = false
	_apply_all()
	save_settings()

func register_new_loop() -> void:
	loop_count += 1
	save_settings()

func unlock_ending(ending_id: String) -> void:
	if ending_id == "" or unlocked_endings.has(ending_id):
		return
	unlocked_endings.append(ending_id)
	save_settings()

func _apply_all() -> void:
	_apply_volume(BUS_MASTER, master_volume)
	_apply_volume(BUS_MUSIC, music_volume)
	_apply_volume(BUS_SFX, sfx_volume)
	_apply_fullscreen()

func _apply_volume(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(index, linear_to_db(max(value, 0.0001)))
	AudioServer.set_bus_mute(index, value <= 0.001)

func _apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
