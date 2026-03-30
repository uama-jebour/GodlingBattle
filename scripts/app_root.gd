extends Control

@onready var screen_host := Control.new()


func _ready() -> void:
	screen_host.name = "ScreenHost"
	screen_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_host)
	AppRouter.bind_host(screen_host)
	AppRouter.goto_preparation()
