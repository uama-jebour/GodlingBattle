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
		"battle_id": "battle_not_exist",
		"seed": 1
	})
	var result: Dictionary = payload.get("result", {})
	if result.get("status", "") != "invalid_setup":
		_failures.append("expected status invalid_setup")
	if result.get("defeat_reason", "") != "missing_battle":
		_failures.append("expected defeat_reason missing_battle")
	if bool(result.get("victory", true)):
		_failures.append("expected non-victory for invalid setup")
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
