extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()

	var hero_only: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": [],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 31
	})
	if str(hero_only.get("result", {}).get("status", "")) != "completed":
		_failures.append("hero-only runtime should be completed")

	var two_allies: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 32
	})
	if str(two_allies.get("result", {}).get("status", "")) != "completed":
		_failures.append("2-ally runtime should be completed")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for msg in _failures:
		printerr(msg)
	quit(1)
