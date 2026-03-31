extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_entries": [
			{"unit_id": "ally_hound_remnant", "count": 3}
		],
		"ally_ids": [],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 26033201
	})
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return
	var ally_count := 0
	for row in (timeline[0] as Dictionary).get("entities", []):
		var side := str((row as Dictionary).get("side", ""))
		if side == "ally":
			ally_count += 1
	if ally_count != 3:
		_failures.append("expected 3 ally entities from ally_entries, got %d" % ally_count)
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
