extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 20260330
	})
	var result: Dictionary = payload.get("result", {})
	var logs: Array = result.get("log_entries", [])
	var unresolved_logged := false
	for row in logs:
		if str(row.get("type", "")) != "event_unresolved_effect":
			continue
		if str(row.get("event_id", "")) != "evt_hunter_fiend_arrival":
			continue
		unresolved_logged = true
		break
	if not unresolved_logged:
		_failures.append("expected unresolved effect log for evt_hunter_fiend_arrival")

	var timeline: Array = payload.get("timeline", [])
	var saw_hunter_fiend := false
	for frame in timeline:
		for entity in (frame as Dictionary).get("entities", []):
			if str((entity as Dictionary).get("unit_id", "")) == "enemy_hunter_fiend":
				saw_hunter_fiend = true
				break
		if saw_hunter_fiend:
			break
	if not saw_hunter_fiend:
		_failures.append("expected enemy_hunter_fiend to spawn into timeline when unresolved event summon triggers")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
