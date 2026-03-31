extends SceneTree

const SOLVER := preload("res://scripts/observe/battlefield_layout_solver.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var solver = SOLVER.new()
	var bounds := Rect2(0, 0, 640, 360)
	var previous_by_id: Dictionary = {}
	var max_jump_by_id: Dictionary = {}

	for t in range(18):
		var rows := [
			{"entity_id": "enemy_a", "side": "enemy", "position": Vector2(470.0 + sin(float(t)) * 20.0, 210.0 + cos(float(t)) * 10.0)},
			{"entity_id": "enemy_b", "side": "enemy", "position": Vector2(490.0 + cos(float(t)) * 20.0, 220.0 + sin(float(t)) * 10.0)}
		]
		var resolved: Array = solver.resolve(rows, bounds)
		for row in resolved:
			var entity_id := str(row.get("entity_id", ""))
			var pos := row.get("position", Vector2.ZERO) as Vector2
			if previous_by_id.has(entity_id):
				var jump := pos.distance_to(previous_by_id[entity_id] as Vector2)
				var current_max := float(max_jump_by_id.get(entity_id, 0.0))
				max_jump_by_id[entity_id] = maxf(current_max, jump)
			previous_by_id[entity_id] = pos

	for entity_id in max_jump_by_id.keys():
		var max_jump := float(max_jump_by_id[entity_id])
		if max_jump > 90.0:
			_failures.append("layout jump too large for %s: %f" % [entity_id, max_jump])

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
