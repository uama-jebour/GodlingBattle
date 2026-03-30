extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 2026
	})
	var entries: Array = payload.get("result", {}).get("log_entries", [])
	var has_event_warning := false
	for entry in entries:
		if String(entry.get("type", "")) == "event_warning":
			has_event_warning = true
			break
	assert(has_event_warning)
	quit(0)
