extends CanvasLayer

# Efeitos de terror, no estilo das "quebras" do Doki Doki: glitch de tela rasgada,
# estática, flash vermelho, apagão e a falsa queda do jogo (crash).
# Os diálogos pedem pelo campo "fx" do nó: glitch, static, flash_red, blackout, thud, crash.

const SCREEN := Vector2(1280, 720)
const GLYPHS := "█▓▒░#@%&§¤¿?¡"
const AMBIENT_MIN := 22.0
const AMBIENT_MAX := 40.0
const AMBIENT_DREAD := 60

var _busy: bool = false
var _in_dialogue: bool = false
var _ambient_left: float = 30.0
var _bars: Array[ColorRect] = []
var _flash: ColorRect
var _black: ColorRect
var _noise: TextureRect
var _crash_root: Control
var _crash_label: Label
var _error_window: Panel
var _shake_time: float = 0.0
var _shake_power: float = 0.0
var _mono: SystemFont

func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mono = SystemFont.new()
	_mono.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])

	_noise = TextureRect.new()
	_noise.size = SCREEN
	_noise.stretch_mode = TextureRect.STRETCH_SCALE
	_noise.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_noise.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_noise.visible = false
	add_child(_noise)

	for i in 12:
		var bar := ColorRect.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.visible = false
		add_child(bar)
		_bars.append(bar)

	_flash = _fullscreen_rect(Color(1, 0, 0, 0))
	_black = _fullscreen_rect(Color(0, 0, 0, 0))
	_build_crash()

	EventBus.horror_requested.connect(play)
	EventBus.dialogue_started.connect(func(_m): _in_dialogue = true)
	EventBus.dialogue_ended.connect(func(_id): _in_dialogue = false)
	EventBus.dialogue_cancelled.connect(func(): _in_dialogue = false)

func _fullscreen_rect(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.size = SCREEN
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect

func _build_crash() -> void:
	_crash_root = Control.new()
	_crash_root.size = SCREEN
	_crash_root.visible = false
	_crash_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_crash_root)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = SCREEN
	_crash_root.add_child(bg)

	_error_window = Panel.new()
	_error_window.size = Vector2(560, 190)
	_error_window.position = (SCREEN - _error_window.size) / 2.0
	_crash_root.add_child(_error_window)
	var title := Label.new()
	title.text = "  Lanternas de Papel"
	title.position = Vector2(0, 0)
	title.size = Vector2(560, 30)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	var title_bg := ColorRect.new()
	title_bg.color = Color(0.1, 0.25, 0.55)
	title_bg.size = Vector2(560, 30)
	_error_window.add_child(title_bg)
	_error_window.add_child(title)
	var msg := Label.new()
	msg.text = "Lanternas de Papel parou de responder.\n\nO Windows está procurando uma solução para o problema…"
	msg.position = Vector2(24, 48)
	msg.size = Vector2(520, 110)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	_error_window.add_child(msg)

	_crash_label = Label.new()
	_crash_label.position = Vector2(60, 60)
	_crash_label.size = Vector2(1160, 600)
	_crash_label.add_theme_font_override("font", _mono)
	_crash_label.add_theme_font_size_override("font_size", 22)
	_crash_label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.75))
	_crash_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_crash_root.add_child(_crash_label)

func _process(delta: float) -> void:
	# Tremor de câmera: deslocamos o canvas inteiro do jogo.
	if _shake_time > 0.0:
		_shake_time -= delta
		var power := _shake_power * clampf(_shake_time / 0.5, 0.0, 1.0) if _shake_time < 0.5 else _shake_power
		get_tree().root.canvas_transform = Transform2D(0.0, Vector2(randf_range(-power, power), randf_range(-power, power)))
		if _shake_time <= 0.0:
			get_tree().root.canvas_transform = Transform2D.IDENTITY

func play(kind: String, data: Dictionary = {}) -> void:
	match kind:
		"delete":
			var lines := [
				tr("> excluindo kaito.chr ... ok"),
				tr("> excluindo kaito_memoria.dat ... ok"),
				tr("> excluindo kaito_voz.ogg ... ok"),
				tr("> excluindo maya.chr ... ACESSO NEGADO"),
				tr("> maya.chr está em uso por outro processo"),
				tr("> tentando de novo ... ACESSO NEGADO"),
			]
			_run_crash({"crash_lines": lines, "show_window": false})
			return
		"glitch":
			_run_glitch(0.55)
		"static":
			_run_static(0.9, 0.55)
		"flash_red":
			_run_flash_red()
		"blackout":
			_run_blackout(1.4)
		"thud":
			SfxPlayer.play_thud()
			_shake(10.0, 0.45)
		"shake":
			_shake(14.0, 0.7)
		"crash":
			_run_crash(data)

func _shake(power: float, seconds: float) -> void:
	if GameSettings.reduce_flashing:
		return
	_shake_power = power
	_shake_time = seconds

func _duck_music(seconds: float) -> void:
	var idx := AudioServer.get_bus_index(GameSettings.BUS_MUSIC)
	if idx < 0:
		return
	var was_muted := AudioServer.is_bus_mute(idx)
	AudioServer.set_bus_mute(idx, true)
	await get_tree().create_timer(seconds, true).timeout
	AudioServer.set_bus_mute(idx, was_muted or GameSettings.music_volume <= 0.001)

func _run_glitch(seconds: float) -> void:
	if GameSettings.reduce_flashing:
		# Versão calma: só um escurecimento suave, sem tiras coloridas.
		_black.color.a = 0.55
		create_tween().tween_property(_black, "color:a", 0.0, seconds)
		await get_tree().create_timer(seconds, true).timeout
		return
	EventBus.glitch_requested.emit()
	_shake(12.0, seconds)
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	var colors := [Color(0, 1, 1, 0.8), Color(1, 0, 1, 0.8), Color(1, 1, 1, 0.9), Color(0, 0, 0, 1), Color(1, 0, 0, 0.7)]
	while Time.get_ticks_msec() < end:
		for bar in _bars:
			bar.visible = randf() < 0.7
			bar.color = colors[randi() % colors.size()]
			bar.position = Vector2(randf_range(-60.0, 60.0), randf() * SCREEN.y)
			bar.size = Vector2(SCREEN.x + 120.0, randf_range(4.0, 46.0))
		await get_tree().create_timer(0.05, true).timeout
	for bar in _bars:
		bar.visible = false

func _run_static(seconds: float, alpha: float) -> void:
	SfxPlayer.play_static(seconds)
	if GameSettings.reduce_flashing:
		_black.color.a = 0.4
		create_tween().tween_property(_black, "color:a", 0.0, seconds)
		return
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	_noise.modulate.a = alpha
	_noise.visible = true
	while Time.get_ticks_msec() < end:
		_noise.texture = _noise_texture()
		await get_tree().create_timer(0.05, true).timeout
	_noise.visible = false

func _noise_texture() -> ImageTexture:
	var img := Image.create(128, 72, false, Image.FORMAT_L8)
	for y in 72:
		for x in 128:
			img.set_pixel(x, y, Color.from_hsv(0.0, 0.0, randf()))
	return ImageTexture.create_from_image(img)

func _run_flash_red() -> void:
	SfxPlayer.play_thud()
	_shake(16.0, 0.6)
	_flash.color = Color(0.85, 0.0, 0.05, 0.25 if GameSettings.reduce_flashing else 0.75)
	create_tween().tween_property(_flash, "color:a", 0.0, 0.7)

func _run_blackout(seconds: float) -> void:
	SfxPlayer.play_thud()
	_duck_music(seconds + 0.4)
	_black.color.a = 1.0
	await get_tree().create_timer(seconds, true).timeout
	create_tween().tween_property(_black, "color:a", 0.0, 0.5)

func _type(label: Label, text: String, per_char: float) -> void:
	for ch in text:
		label.text += ch
		await get_tree().create_timer(per_char, true).timeout

func _run_crash(data: Dictionary) -> void:
	if _busy:
		return
	_busy = true
	var was_paused := get_tree().paused
	get_tree().paused = true
	_duck_music(9.0)
	SfxPlayer.play_static(0.5)

	# 1) o jogo congela e a tela pisca
	await _run_glitch(0.6)
	_crash_label.text = ""
	_crash_root.visible = true
	_error_window.visible = bool(data.get("show_window", true))
	_crash_label.visible = not _error_window.visible
	if _error_window.visible:
		await get_tree().create_timer(1.3, true).timeout

	# 2) a janela de erro some e o "terminal" aparece
	_error_window.visible = false
	_crash_label.visible = true
	SfxPlayer.play_static(0.25)
	var user := OS.get_environment("USERNAME")
	var lines: Array = data.get("crash_lines", [])
	if lines.is_empty():
		lines = [
			tr("> iniciando verificação de memória... falhou"),
			tr("> carregando %s.sav ... CORROMPIDO") % GameState.player_name,
			tr("> volta nº %d") % (100 + GameSettings.loop_count),
			tr("> ERRO: personagem 'Kaito Mori' não encontrado"),
			tr("> ERRO: personagem 'Kaito Mori' não encontrado"),
			tr("> ERRO: personagem 'Kaito Mori' não encontrado"),
			tr("> VOCÊ SÓ NÃO CONSEGUIU SEGURAR"),
		]
	for i in lines.size():
		var line: String = str(lines[i]).format({
			"player_name": GameState.player_name,
			"user": user if user != "" else tr("você"),
		})
		var danger := line.begins_with("> ERRO") or line.begins_with("> ERROR") or line.contains("SEGURAR") or line.contains("HOLD ON") or line.contains("ACESSO NEGADO") or line.contains("ACCESS DENIED")
		_crash_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25) if danger else Color(0.75, 1.0, 0.75))
		await _type(_crash_label, line + "\n", 0.018 if i > 3 else 0.03)
		await get_tree().create_timer(0.15 if i < lines.size() - 2 else 0.7, true).timeout

	# 3) apagão, "reiniciando..." e a cena volta
	_crash_label.text = ""
	await get_tree().create_timer(0.5, true).timeout
	_crash_label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.75))
	await _type(_crash_label, "> reiniciando...", 0.06)
	await get_tree().create_timer(0.8, true).timeout
	_crash_root.visible = false
	_black.color.a = 1.0
	get_tree().paused = was_paused
	create_tween().tween_property(_black, "color:a", 0.0, 0.8)
	_busy = false
