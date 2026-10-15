extends CanvasLayer

@onready var flash_rect: ColorRect = $FlashRect

func _ready() -> void:
	flash_rect.visible = false
	EventBus.glitch_requested.connect(play)

func play() -> void:
	flash_rect.visible = true
	for i in 6:
		flash_rect.color = Color(randf(), randf(), randf(), 0.35)
		await get_tree().create_timer(0.05).timeout
	flash_rect.visible = false
