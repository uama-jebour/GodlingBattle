extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_test_baseline",
		"seed": 101
	})
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return
	var frame0 := timeline[0] as Dictionary
	var enemy_count := 0
	for row in frame0.get("entities", []):
		if str((row as Dictionary).get("side", "")) == "enemy":
			enemy_count += 1
	if enemy_count != 3:
		_failures.append("expected 3 opening enemies, got %d" % enemy_count)
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for msg in _failures:
		printerr(msg)
	quit(1)
