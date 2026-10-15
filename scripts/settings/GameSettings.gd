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
# Persists across new games: how many times the player has started this story.
var loop_count: int = 0

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
		loop_count = config.get_value("meta", "loop_count", loop_count)
	_apply_all()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("text", "speed", text_speed)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("meta", "loop_count", loop_count)
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

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_fullscreen()
	save_settings()

func reset_to_defaults() -> void:
	master_volume = 0.8
	music_volume = 0.7
	sfx_volume = 0.8
	text_speed = 0.03
	fullscreen = false
	_apply_all()
	save_settings()

func register_new_loop() -> void:
	loop_count += 1
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
