extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var token: Control = load("res://scripts/observe/token_view.gd").new()
	root.add_child(token)
	token.apply_snapshot({
		"entity_id": "u1",
		"display_name": "单位",
		"side": "ally",
		"hp_ratio": 1.0,
		"position": Vector2(100.0, 100.0)
	})
	token.apply_snapshot({
		"entity_id": "u1",
		"display_name": "单位",
		"side": "ally",
		"hp_ratio": 1.0,
		"position": Vector2(150.0, 100.0)
	})
	var p0 := token.position
	token.call("_process", 1.0 / 60.0)
	var p1 := token.position
	if p1 == p0:
		_failures.append("expected interpolated motion after snapshot update")
	for _i in range(4):
		token.call("_process", 1.0 / 60.0)
	if token.position.x <= p0.x:
		_failures.append("token should continue moving toward target")

	token.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
