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

	var from_a := Vector2(120, 220)
	var to_a := Vector2(520, 220)
	var from_b := Vector2(520, 220)
	var to_b := Vector2(120, 220)
	var sign_a := float(overlay.call("_curve_sign", from_a, to_a))
	var sign_b := float(overlay.call("_curve_sign", from_b, to_b))
	if sign_a * sign_b >= 0.0:
		_failures.append("opposite directions should have opposite curve signs")

	var control_a: Vector2 = overlay.call("_curve_control_point", from_a, to_a, sign_a)
	var control_b: Vector2 = overlay.call("_curve_control_point", from_b, to_b, sign_b)
	if absf(control_a.y - control_b.y) < 8.0:
		_failures.append("dual-direction arcs should separate vertically (a=%s b=%s)" % [control_a, control_b])

	overlay.free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
