extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var setup: Dictionary = {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 101
	}
	var a: Dictionary = runner.run(setup)
	var b: Dictionary = runner.run(setup)
	assert(JSON.stringify(a.get("result", {})) == JSON.stringify(b.get("result", {})))
	quit(0)
