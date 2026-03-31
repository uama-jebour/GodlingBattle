extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_test_enemy_elite",
		"seed": 26033114
	})
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return
	var has_elite := false
	for row in (timeline[0] as Dictionary).get("entities", []):
		var entity := row as Dictionary
		if str(entity.get("side", "")) != "enemy":
			continue
		if str(entity.get("unit_id", "")) == "enemy_hunter_fiend":
			has_elite = true
			break
	if not has_elite:
		_failures.append("elite battle should include enemy_hunter_fiend")
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
