extends Control

# Text speed slider (1-10) maps to seconds per character: 0.12 / (value + 1).
const SPEED_FACTOR := 0.12

@onready var rows: VBoxContainer = $Panel/Rows
@onready var reset_button: Button = $Panel/ResetButton
@onready var back_button: Button = $Panel/BackButton

func _ready() -> void:
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_build_rows()

func _build_rows() -> void:
	for child in rows.get_children():
		child.queue_free()
	_add_percent_slider("Volume geral", GameSettings.master_volume, GameSettings.set_master_volume)
	_add_percent_slider("Música", GameSettings.music_volume, GameSettings.set_music_volume)
	_add_percent_slider("Efeitos sonoros", GameSettings.sfx_volume, _on_sfx_volume_changed)
	_add_speed_slider()
	_add_auto_rows()
	_add_access_rows()
	_add_fullscreen_toggle()

func _add_percent_slider(title: String, value: float, on_change: Callable) -> void:
	var label := Label.new()
	label.text = "%s: %d%%" % [title, roundi(value * 100.0)]
	rows.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.custom_minimum_size = Vector2(0, 28)
	slider.value = roundi(value * 100.0)
	var on_value := func(v: float) -> void:
		label.text = "%s: %d%%" % [title, int(v)]
		on_change.call(v / 100.0)
	slider.value_changed.connect(on_value)
	rows.add_child(slider)

func _add_speed_slider() -> void:
	var label := Label.new()
	rows.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 1
	slider.max_value = 10
	slider.step = 1
	slider.custom_minimum_size = Vector2(0, 28)
	slider.value = clampi(roundi(SPEED_FACTOR / GameSettings.text_speed - 1.0), 1, 10)
	label.text = "Velocidade do texto: %d/10" % int(slider.value)
	var on_value := func(v: float) -> void:
		label.text = "Velocidade do texto: %d/10" % int(v)
		GameSettings.set_text_speed(SPEED_FACTOR / (v + 1.0))
	slider.value_changed.connect(on_value)
	rows.add_child(slider)

func _add_auto_rows() -> void:
	var toggle := CheckButton.new()
	toggle.text = "Avanço automático do texto"
	toggle.button_pressed = GameSettings.auto_advance
	toggle.toggled.connect(GameSettings.set_auto_advance)
	rows.add_child(toggle)

	var label := Label.new()
	rows.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 1
	slider.max_value = 10
	slider.step = 1
	slider.custom_minimum_size = Vector2(0, 28)
	slider.value = clampi(roundi(GameSettings.auto_seconds), 1, 10)
	label.text = "Tempo de leitura automática: %d s" % int(slider.value)
	var on_value := func(v: float) -> void:
		label.text = "Tempo de leitura automática: %d s" % int(v)
		GameSettings.set_auto_seconds(v)
	slider.value_changed.connect(on_value)
	rows.add_child(slider)

func _add_access_rows() -> void:
	var toggle := CheckButton.new()
	toggle.text = "Reduzir luzes piscantes e tremores"
	toggle.button_pressed = GameSettings.reduce_flashing
	toggle.toggled.connect(GameSettings.set_reduce_flashing)
	rows.add_child(toggle)

	var label := Label.new()
	rows.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 1
	slider.max_value = 3
	slider.step = 1
	slider.custom_minimum_size = Vector2(0, 28)
	var sizes := [1.0, 1.15, 1.3]
	slider.value = clampi(sizes.find(GameSettings.font_scale) + 1, 1, 3) if sizes.has(GameSettings.font_scale) else 1
	label.text = "Tamanho do texto: %d/3" % int(slider.value)
	var on_value := func(v: float) -> void:
		label.text = "Tamanho do texto: %d/3" % int(v)
		GameSettings.set_font_scale(sizes[int(v) - 1])
	slider.value_changed.connect(on_value)
	rows.add_child(slider)

	var review := Button.new()
	review.text = "Rever aviso de saúde e bem-estar"
	review.pressed.connect(func():
		SfxPlayer.play_click()
		get_tree().current_scene.show_health_warning())
	rows.add_child(review)

func _add_fullscreen_toggle() -> void:
	var toggle := CheckButton.new()
	toggle.text = "Tela cheia"
	toggle.button_pressed = GameSettings.fullscreen
	toggle.toggled.connect(GameSettings.set_fullscreen)
	rows.add_child(toggle)

func _on_sfx_volume_changed(value: float) -> void:
	GameSettings.set_sfx_volume(value)
	SfxPlayer.play_click()

func _on_reset_pressed() -> void:
	SfxPlayer.play_click()
	GameSettings.reset_to_defaults()
	_build_rows()

func _on_back_pressed() -> void:
	SfxPlayer.play_click()
	get_tree().current_scene.return_from_menu()
