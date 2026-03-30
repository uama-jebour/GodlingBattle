extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/observe/observe_screen.gd").new()
	assert(screen.has_method("apply_timeline_frame"))
	assert(screen.has_method("build_token_snapshot"))
	screen.free()
	quit(0)
