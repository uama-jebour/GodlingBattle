extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_entries": [
			{"unit_id": "ally_hound_remnant", "count": 2},
			{"unit_id": "ally_arc_shooter", "count": 1}
		],
		"ally_ids": [],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 26033202
	})
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return
	var has_melee_ally := false
	var has_ranged_ally := false
	for row in (timeline[0] as Dictionary).get("entities", []):
		var d := row as Dictionary
		if str(d.get("side", "")) != "ally":
			continue
		var uid := str(d.get("unit_id", ""))
		if uid == "ally_hound_remnant":
			has_melee_ally = true
		if uid == "ally_arc_shooter":
			has_ranged_ally = true
	if not has_melee_ally:
		_failures.append("expected melee ally in mixed role setup")
	if not has_ranged_ally:
		_failures.append("expected ranged ally in mixed role setup")
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
