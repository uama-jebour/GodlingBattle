extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root: Control = load("res://scripts/observe/observe_screen.gd").new()
	assert(root.has_method("play_battle"))
	root.free()
	quit(0)
