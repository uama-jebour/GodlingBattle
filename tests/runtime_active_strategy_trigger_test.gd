extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_chill_wave"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 20260330
	})
	var result: Dictionary = payload.get("result", {})
	var triggered: Array = result.get("triggered_strategies", [])
	var has_chill_wave := false
	for row in triggered:
		if str(row.get("strategy_id", "")) == "strat_chill_wave":
			has_chill_wave = true
			break
	if not has_chill_wave:
		_failures.append("expected strat_chill_wave in triggered_strategies")

	var logs: Array = result.get("log_entries", [])
	var has_strategy_cast := false
	for row in logs:
		if str(row.get("type", "")) == "strategy_cast" and str(row.get("strategy_id", "")) == "strat_chill_wave":
			has_strategy_cast = true
			break
	if not has_strategy_cast:
		_failures.append("expected strategy_cast log for strat_chill_wave")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
