extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var token: Control = load("res://scripts/observe/token_view.gd").new()
	if not token.has_method("get_side_color"):
		_failures.append("missing get_side_color")
		_finish(token)
		return

	token.apply_snapshot({
		"entity_id": "enemy_1",
		"display_name": "敌方单位",
		"hp_ratio": 1.5,
		"side": "enemy",
		"position": Vector2(300, 200)
	})

	if absf(float(token.hp_ratio) - 1.0) > 0.001:
		_failures.append("hp_ratio should be clamped to 1.0")
	if token.position != Vector2(300, 200):
		_failures.append("position should follow snapshot")
	var side_color: Color = token.get_side_color()
	if side_color == Color.WHITE:
		_failures.append("side color should not be default white")
	if not token.has_method("get_title_bar_color"):
		_failures.append("missing get_title_bar_color")
	else:
		var title_bar_color: Color = token.call("get_title_bar_color")
		if title_bar_color == token.get_fill_color():
			_failures.append("title bar color should contrast with fill color")

	_finish(token)


func _finish(token: Control) -> void:
	token.free()
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
