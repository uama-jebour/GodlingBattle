extends SceneTree


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
	var logs: Array = payload.get("result", {}).get("log_entries", [])
	var has_warning := false
	var has_resolve := false
	for row in logs:
		if row.get("type", "") == "event_warning":
			has_warning = true
		if row.get("type", "") == "event_resolve":
			has_resolve = true
	assert(has_warning)
	assert(has_resolve)
	quit(0)
