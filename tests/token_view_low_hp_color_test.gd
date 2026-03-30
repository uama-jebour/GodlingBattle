extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var token: Control = load("res://scripts/observe/token_view.gd").new()
	if not token.has_method("get_hp_fill_color"):
		_failures.append("missing get_hp_fill_color")
		_finish(token)
		return

	token.apply_snapshot({
		"entity_id": "ally_1",
		"display_name": "友军",
		"hp_ratio": 0.9,
		"side": "ally",
		"position": Vector2(100, 100)
	})
	var high_color: Color = token.get_hp_fill_color()

	token.apply_snapshot({
		"entity_id": "ally_1",
		"display_name": "友军",
		"hp_ratio": 0.2,
		"side": "ally",
		"position": Vector2(100, 100)
	})
	var low_color: Color = token.get_hp_fill_color()

	if high_color == low_color:
		_failures.append("high hp and low hp color should differ")

	_finish(token)


func _finish(token: Control) -> void:
	token.free()
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
