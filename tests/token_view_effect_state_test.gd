extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var token: Control = load("res://scripts/observe/token_view.gd").new()
	token.call("set_visual_flags", {
		"is_hit": true,
		"is_affected": true,
		"is_dead": false
	})
	if not bool(token.get("is_hit")):
		_failures.append("is_hit should be true")
	if not bool(token.get("is_affected")):
		_failures.append("is_affected should be true")
	if bool(token.get("is_dead")):
		_failures.append("is_dead should be false")

	_finish(token)


func _finish(token: Control) -> void:
	token.free()
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
