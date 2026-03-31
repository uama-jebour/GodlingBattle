extends SceneTree

const SOLVER := preload("res://scripts/observe/battlefield_layout_solver.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var solver = SOLVER.new()
	var bounds := Rect2(0, 0, 960, 520)
	var desired := Vector2(220, 240)
	var resolved: Array = solver.resolve([
		{
			"entity_id": "ally_a",
			"side": "ally",
			"position": desired
		}
	], bounds)
	if resolved.is_empty():
		_failures.append("solver should return one row")
		_finish()
		return
	var pos := (resolved[0] as Dictionary).get("position", Vector2.ZERO) as Vector2
	if absf(pos.y - desired.y) > 36.0:
		_failures.append("single entity should stay near desired y; got=%s desired=%s" % [pos, desired])

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
