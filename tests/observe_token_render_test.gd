extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/observe/observe_screen.gd").new()
	if not screen.has_method("sync_token_views"):
		_failures.append("missing sync_token_views")
		_finish(screen)
		return
	if not screen.has_method("get_token_view_count"):
		_failures.append("missing get_token_view_count")
		_finish(screen)
		return

	screen.apply_timeline_frame({
		"tick": 0,
		"entities": [{
			"entity_id": "hero_1",
			"display_name": "英雄",
			"side": "hero",
			"hp": 80.0,
			"max_hp": 100.0,
			"position": Vector2(120, 220)
		}]
	})
	var snapshot: Array = screen.build_token_snapshot()
	screen.sync_token_views(snapshot)

	if int(screen.get_token_view_count()) != 1:
		_failures.append("expected one token view")

	var token: Node = screen.get_token_view("hero_1")
	if token == null:
		_failures.append("expected token for hero_1")
	else:
		if absf(float(token.hp_ratio) - 0.8) > 0.001:
			_failures.append("expected hp_ratio=0.8")
		if token.position != Vector2(120, 220):
			_failures.append("expected token position updated")

	_finish(screen)


func _finish(screen: Control) -> void:
	screen.free()
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
