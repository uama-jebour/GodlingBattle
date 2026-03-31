extends SceneTree

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var payload: Dictionary = RUNNER.new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 7
	})
	var result: Dictionary = payload.get("result", {})
	if str(result.get("defeat_reason", "")) == "timeout":
		_failures.append("pathing regression: battle should not stall to timeout under seed=7 without strategies")
	var casualties: Array = result.get("casualties", [])
	if casualties.is_empty():
		_failures.append("expected at least one casualty to confirm units can maintain engagement")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
