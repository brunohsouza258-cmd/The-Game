extends Node2D

const DEFAULT_BACKGROUND := "res://assets/backgrounds/hallway_dusk.png"
const SCREEN_SIZE := Vector2(1280, 720)
const SPRITE_HEIGHT := 640.0
const DREAD_TINT := Color(0.78, 0.6, 0.66)
const POSE_SECONDS := 0.25
const SIDE_X := {"left": 0.27, "right": 0.73}
const PARTNER_TINT := Color(0.5, 0.5, 0.58)

# Each pose moves/tints the sprite. If assets/characters/<name>_<pose>.png exists,
# that image is used instead of the base sprite (drop new pose art in and it just works).
const POSES := {
	"neutral": {"offset": Vector2(0, 0), "scale": 1.0, "rotation": 0.0, "tint": Color(1, 1, 1), "hop": 0.0, "shake": 0.0},
	"happy": {"offset": Vector2(0, -8), "scale": 1.02, "rotation": 0.0, "tint": Color(1, 1, 1), "hop": 28.0, "shake": 0.0},
	"sad": {"offset": Vector2(0, 24), "scale": 0.98, "rotation": 0.0, "tint": Color(0.84, 0.87, 1.0), "hop": 0.0, "shake": 0.0},
	"surprised": {"offset": Vector2(0, -12), "scale": 1.04, "rotation": 0.0, "tint": Color(1, 1, 1), "hop": 18.0, "shake": 0.0},
	"scared": {"offset": Vector2(-12, 14), "scale": 0.97, "rotation": 0.0, "tint": Color(0.88, 0.9, 1.0), "hop": 0.0, "shake": 9.0},
	"angry": {"offset": Vector2(0, -4), "scale": 1.06, "rotation": 0.0, "tint": Color(1.0, 0.86, 0.86), "hop": 0.0, "shake": 5.0},
	"thinking": {"offset": Vector2(28, 0), "scale": 1.0, "rotation": -0.035, "tint": Color(1, 1, 1), "hop": 0.0, "shake": 0.0},
	"close": {"offset": Vector2(0, 80), "scale": 1.2, "rotation": 0.0, "tint": Color(1, 1, 1), "hop": 0.0, "shake": 0.0},
	"corrupted": {"offset": Vector2(0, 0), "scale": 1.0, "rotation": 0.0, "tint": Color(1.0, 0.55, 0.72), "hop": 0.0, "shake": 22.0},
}

@onready var background: TextureRect = $Background
@onready var character_sprite: Sprite2D = $CharacterSprite

var pose_offset: Vector2 = Vector2.ZERO
var pose_scale: float = 1.0
var pose_rotation: float = 0.0
var hop_offset: float = 0.0
var shake: float = 0.0

var _base_sprite_path: String = ""
var _base_scale: float = 1.0
var _time: float = 0.0
var _pose_tween: Tween
var _partner_sprite: Sprite2D
var _stage_x: float = SCREEN_SIZE.x / 2.0
var _partner_scale: float = 1.0
var _next_screen: String = "res://scenes/main/Hub.tscn"
var _glitch_pulse: float = 0.0
const INSERT_CENTER := Vector2(640, 218)
const INSERT_MAX := Vector2(640, 350)
var _insert_dim: ColorRect
var _insert: Sprite2D
var _insert_tween: Tween
var _sprite_material: ShaderMaterial
var _partner_material: ShaderMaterial

func _ready() -> void:
	# A segunda personagem em cena fica atrás da que fala, escurecida.
	_partner_sprite = Sprite2D.new()
	_partner_sprite.visible = false
	_partner_sprite.modulate = PARTNER_TINT
	add_child(_partner_sprite)
	move_child(_partner_sprite, character_sprite.get_index())
	# Objetos mostrados em cena (foto, caderno, relógio...): "image" no nó do diálogo.
	_insert_dim = ColorRect.new()
	_insert_dim.color = Color(0, 0, 0, 0.5)
	_insert_dim.size = SCREEN_SIZE
	_insert_dim.modulate.a = 0.0
	_insert_dim.visible = false
	add_child(_insert_dim)
	_insert = Sprite2D.new()
	_insert.position = INSERT_CENTER
	_insert.modulate.a = 0.0
	_insert.visible = false
	add_child(_insert)
	var shader: Shader = load("res://assets/shaders/sprite_glitch.gdshader")
	_sprite_material = ShaderMaterial.new()
	_sprite_material.shader = shader
	character_sprite.material = _sprite_material
	_partner_material = ShaderMaterial.new()
	_partner_material.shader = shader
	_partner_sprite.material = _partner_material
	EventBus.glitch_requested.connect(func(): _glitch_pulse = 1.0)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_node_shown.connect(_on_node_shown)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)

func start(dialogue_path: String) -> void:
	DialogueManager.start_dialogue(dialogue_path)

func _ambience_for(background_path: String) -> String:
	if background_path.contains("rooftop_rain"):
		return "rain"
	if background_path.contains("school_night") or background_path.contains("bedroom_night") or background_path.contains("festival_night"):
		return "night"
	if background_path.contains("courtyard") or background_path.contains("rooftop_dusk"):
		return "wind"
	return ""

func _on_dialogue_started(meta: Dictionary) -> void:
	SfxPlayer.set_ambience(_ambience_for(meta.get("background", DEFAULT_BACKGROUND)))
	_next_screen = meta.get("next_screen", "res://scenes/main/Hub.tscn")
	background.texture = load(meta.get("background", DEFAULT_BACKGROUND))
	# The scene's own tint (night, decay...) combined with a drift toward red as dread rises.
	var dread_tint := Color(1, 1, 1).lerp(DREAD_TINT, GameState.dread / 100.0)
	background.modulate = Color(meta.get("tint", "#ffffff")) * dread_tint
	_base_sprite_path = meta.get("sprite", "")
	character_sprite.visible = _base_sprite_path != ""
	if _base_sprite_path != "":
		_set_texture(_base_sprite_path)
	MusicPlayer.play_mood(meta.get("music", "menu"))

func _on_node_shown(node_data: Dictionary) -> void:
	_apply_node_scene(node_data)
	if _base_sprite_path == "":
		return
	var pose: String = node_data.get("pose", "")
	if pose == "":
		pose = "corrupted" if node_data.get("effect", "") == "glitch" else "neutral"
	_apply_pose(pose)

# Cenas com várias personagens trocam sprite, cenário e tom por fala:
# "sprite": "res://...png" (ou "" para esconder), "background", "tint".
func _show_insert(path: String) -> void:
	if _insert_tween:
		_insert_tween.kill()
	if path == "":
		if _insert.visible:
			_insert_tween = create_tween().set_parallel(true)
			_insert_tween.tween_property(_insert, "modulate:a", 0.0, 0.25)
			_insert_tween.tween_property(_insert_dim, "modulate:a", 0.0, 0.25)
			_insert_tween.chain().tween_callback(func():
				_insert.visible = false
				_insert_dim.visible = false)
		return
	var texture: Texture2D = load(path)
	if texture == null:
		return
	_insert.texture = texture
	var fit := minf(INSERT_MAX.x / texture.get_size().x, INSERT_MAX.y / texture.get_size().y)
	_insert.scale = Vector2.ONE * fit * 0.94
	_insert.visible = true
	_insert_dim.visible = true
	_insert_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_insert_tween.tween_property(_insert, "modulate:a", 1.0, 0.35)
	_insert_tween.tween_property(_insert_dim, "modulate:a", 1.0, 0.35)
	_insert_tween.tween_property(_insert, "scale", Vector2.ONE * fit, 0.35)

func _apply_node_scene(node_data: Dictionary) -> void:
	if node_data.has("image"):
		_show_insert(str(node_data["image"]))
	if node_data.has("background"):
		SfxPlayer.set_ambience(_ambience_for(node_data["background"]))
		background.texture = load(node_data["background"])
		var tint := Color(node_data.get("tint", "#ffffff"))
		background.modulate = tint * Color(1, 1, 1).lerp(DREAD_TINT, GameState.dread / 100.0)
	if node_data.has("sprite"):
		_base_sprite_path = node_data["sprite"]
		character_sprite.visible = _base_sprite_path != ""
		if _base_sprite_path != "":
			_set_texture(_base_sprite_path)
		# "side" põe quem fala à esquerda/direita; sem ele, centralizada.
		_stage_x = SCREEN_SIZE.x * float(SIDE_X.get(node_data.get("side", ""), 0.5))
	if node_data.has("sprite") or node_data.has("partner"):
		var partner_path: String = node_data.get("partner", "")
		_partner_sprite.visible = partner_path != "" and _base_sprite_path != ""
		if _partner_sprite.visible:
			var texture: Texture2D = load(partner_path)
			_partner_sprite.texture = texture
			_partner_scale = SPRITE_HEIGHT * 0.94 / texture.get_size().y

func _apply_pose(pose_name: String) -> void:
	var pose: Dictionary = POSES.get(pose_name, POSES["neutral"])
	var variant := "%s_%s.png" % [_base_sprite_path.get_basename(), pose_name]
	_set_texture(variant if ResourceLoader.exists(variant) else _base_sprite_path)

	if _pose_tween:
		_pose_tween.kill()
	_pose_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_pose_tween.tween_property(self, "pose_offset", pose["offset"], POSE_SECONDS)
	_pose_tween.tween_property(self, "pose_scale", pose["scale"], POSE_SECONDS)
	_pose_tween.tween_property(self, "pose_rotation", pose["rotation"], POSE_SECONDS)
	_pose_tween.tween_property(character_sprite, "modulate", pose["tint"], POSE_SECONDS)
	if pose["hop"] > 0.0:
		hop_offset = -pose["hop"]
		_pose_tween.tween_property(self, "hop_offset", 0.0, 0.45).set_trans(Tween.TRANS_BOUNCE)
	if pose["shake"] > 0.0:
		shake = pose["shake"]
		_pose_tween.tween_property(self, "shake", 0.0, 0.6)

func _set_texture(path: String) -> void:
	var texture: Texture2D = load(path)
	if character_sprite.texture == texture:
		return
	character_sprite.texture = texture
	_base_scale = SPRITE_HEIGHT / texture.get_size().y

# Composes base placement + pose + hop + shake + a slow breathing motion every frame.
# Rosto "errado": fatias deslocadas conforme o pavor, a pose corrompida e os glitches.
func _update_glitch_shader(delta: float) -> void:
	_glitch_pulse = maxf(0.0, _glitch_pulse - delta * 2.0)
	var calm := GameSettings.reduce_flashing
	var intensity := _glitch_pulse * 0.9
	if _base_sprite_path != "" and character_sprite.modulate.g < 0.7:
		intensity = maxf(intensity, 0.5)
	if calm:
		intensity = minf(intensity, 0.12)
	var invert := 1.0 if (not calm and _glitch_pulse > 0.6 and fmod(_time * 20.0, 2.0) < 1.0) else 0.0
	var seed_value := floorf(_time * 12.0)
	for material in [_sprite_material, _partner_material]:
		material.set_shader_parameter("intensity", intensity)
		material.set_shader_parameter("invert", invert)
		material.set_shader_parameter("seed", seed_value)

func _process(delta: float) -> void:
	_time += delta
	if not character_sprite.visible:
		return
	var breath := 1.0 + sin(_time * 2.0) * 0.006
	var base_position := Vector2(SCREEN_SIZE.x / 2.0, SCREEN_SIZE.y - SPRITE_HEIGHT / 2.0)
	base_position.x = _stage_x
	_update_glitch_shader(delta)
	if _partner_sprite.visible:
		_partner_sprite.position = Vector2(SCREEN_SIZE.x - _stage_x, SCREEN_SIZE.y - SPRITE_HEIGHT * 0.94 / 2.0)
		_partner_sprite.scale = Vector2.ONE * _partner_scale * breath
	character_sprite.position = base_position + pose_offset + Vector2(sin(_time * 70.0) * shake, hop_offset)
	character_sprite.scale = Vector2.ONE * _base_scale * pose_scale * breath
	character_sprite.rotation = pose_rotation

func _on_dialogue_ended(_dialogue_id: String) -> void:
	get_tree().current_scene.show_screen(_next_screen)
