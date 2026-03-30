extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/observe/observe_screen.gd").new()
	if not screen.has_method("advance_playback_step"):
		_failures.append("missing advance_playback_step")
		screen.free()
		_finish()
		return
	screen._timeline = [
		{"tick": 0, "entities": []},
		{"tick": 1, "entities": []}
	]
	screen._frame_index = 0
	var finished_first: bool = screen.advance_playback_step()
	if finished_first:
		_failures.append("first step should not finish")
	if int(screen._frame_index) != 1:
		_failures.append("frame index should be 1 after first step")
	var finished_second: bool = screen.advance_playback_step()
	if not finished_second:
		_failures.append("second step should finish")
	if int(screen._frame_index) != 2:
		_failures.append("frame index should be 2 after second step")
	screen.free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
