extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_entries": [
			{"unit_id": "ally_guardian_sentinel", "count": 1}
		],
		"ally_ids": [],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 26033203
	})
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return
	var has_guardian := false
	for row in (timeline[0] as Dictionary).get("entities", []):
		var d := row as Dictionary
		if str(d.get("side", "")) != "ally":
			continue
		if str(d.get("unit_id", "")) == "ally_guardian_sentinel":
			has_guardian = true
			break
	if not has_guardian:
		_failures.append("expected ally_guardian_sentinel in first frame")
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
