extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var overlay_script := load("res://scripts/observe/combat_line_overlay.gd")
	if overlay_script == null:
		_failures.append("missing combat_line_overlay.gd")
		_finish()
		return
	var overlay: Control = overlay_script.new()
	if overlay == null:
		_failures.append("failed to instantiate combat line overlay")
		_finish()
		return

	var window_start: Vector2 = overlay.call("_sweep_window", 0.0)
	if window_start.x != 0.0 or window_start.y != 0.0:
		_failures.append("sweep should start from empty segment at t=0")

	var window_build: Vector2 = overlay.call("_sweep_window", 0.25)
	if window_build.x > 0.01:
		_failures.append("build phase should keep segment start near 0")
	if window_build.y <= 0.2:
		_failures.append("build phase should reveal visible segment length")

	var window_switch: Vector2 = overlay.call("_sweep_window", 0.5)
	if window_switch.y < 0.99:
		_failures.append("switch point should fully reveal line")

	var window_fade: Vector2 = overlay.call("_sweep_window", 0.75)
	if window_fade.x <= 0.2:
		_failures.append("fade phase should trim line from start")
	if window_fade.y < 0.99:
		_failures.append("fade phase should keep head near end")

	var window_end: Vector2 = overlay.call("_sweep_window", 1.0)
	if window_end.x < 0.99 or window_end.y < 0.99:
		_failures.append("sweep should end near line tail at t=1")

	overlay.free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for failure in _failures:
		printerr(failure)
	quit(1)
