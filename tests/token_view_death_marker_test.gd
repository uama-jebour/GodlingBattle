extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var token: Control = load("res://scripts/observe/token_view.gd").new()
	if not token.has_method("set_visual_flags"):
		_failures.append("missing set_visual_flags")
		_finish(token)
		return

	token.call("set_visual_flags", {
		"is_dead": true,
		"show_death_marker_until_tick": 24
	})
	if not bool(token.get("is_dead")):
		_failures.append("token should hold is_dead=true")
	if not token.has_method("is_death_marker_visible"):
		_failures.append("missing is_death_marker_visible")
	else:
		if not bool(token.call("is_death_marker_visible", 12)):
			_failures.append("death marker should be visible before expiry")
		if bool(token.call("is_death_marker_visible", 30)):
			_failures.append("death marker should hide after expiry")

	_finish(token)


func _finish(token: Control) -> void:
	token.free()
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
