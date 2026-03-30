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
	})
	assert(summary.has("casualty_lines"))
	assert(summary.has("strategy_lines"))
	screen.free()
	quit(0)
