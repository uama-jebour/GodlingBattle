extends Control

@onready var screen_host := Control.new()


func _ready() -> void:
	screen_host.name = "ScreenHost"
	screen_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_host)
	var app_router := get_node_or_null("/root/AppRouter")
	if app_router == null:
		return
	app_router.bind_host(screen_host)
	app_router.goto_preparation()
