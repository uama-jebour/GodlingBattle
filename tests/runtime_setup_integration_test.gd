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
		"seed": 42
	})
	var result: Dictionary = payload.get("result", {})
	assert(result.has("status"))
	assert(result.has("casualties"))
	assert(result.has("triggered_events"))
	assert(result.has("triggered_strategies"))
	quit(0)
