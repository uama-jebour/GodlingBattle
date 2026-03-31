extends SceneTree

var _failures: Array[String] = []
const OBSERVE_SCENE := preload("res://scenes/observe/observe_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session_state := root.get_node_or_null("SessionState")
	if session_state == null:
		_failures.append("missing SessionState")
		_finish()
		return
	session_state.battle_setup = {}
	session_state.last_timeline = []
	session_state.last_battle_result = {}

	var screen: Control = OBSERVE_SCENE.instantiate()
	screen.size = Vector2(1280, 720)
	root.add_child(screen)

	await process_frame

	var bounds: Rect2 = screen.call("_battlefield_bounds")
	var screen_bounds := screen.get_rect()
	if bounds.size.x >= screen_bounds.size.x:
		_failures.append("battlefield bounds should be narrower than full screen when BattlefieldPanel host exists (bounds=%s screen=%s)" % [bounds, screen_bounds])

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
