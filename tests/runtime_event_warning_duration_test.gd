extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 77
	})
	var warning_tick := -1
	var resolve_tick := -1
	for row in payload.get("result", {}).get("log_entries", []):
		if str(row.get("type", "")) == "event_warning":
			warning_tick = int(row.get("tick", -1))
		elif str(row.get("type", "")) == "event_resolve":
			resolve_tick = int(row.get("tick", -1))
	if warning_tick < 0:
		_failures.append("missing warning tick")
	if resolve_tick <= warning_tick:
		_failures.append("missing resolve tick")
	if warning_tick >= 0 and resolve_tick > warning_tick and (resolve_tick - warning_tick) != 50:
		_failures.append("warning duration should be 50 ticks")
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
