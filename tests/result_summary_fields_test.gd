extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/result/result_screen.gd").new()
	var summary: Dictionary = screen.build_summary({
		"victory": false,
		"defeat_reason": "hero_dead",
		"survivors": ["hero_1"],
		"casualties": ["ally_1"],
		"triggered_events": [{"event_id": "evt_hunter_fiend_arrival"}],
		"triggered_strategies": [{"strategy_id": "strat_void_echo"}],
		"log_entries": []
	}, {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo", "strat_chill_wave"],
		"battle_id": "battle_void_gate_beta",
		"seed": 20260330
	})
	assert(summary.has("casualty_lines"))
	assert(summary.has("strategy_lines"))
	assert(summary.has("strategy_cast_lines"))
	assert(summary.has("setup_snapshot_lines"))
	screen.free()
	quit(0)
