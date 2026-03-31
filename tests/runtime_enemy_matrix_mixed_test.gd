extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_test_enemy_mixed",
		"seed": 26033113
	})
	var has_melee := false
	var has_ranged := false
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return
	for row in (timeline[0] as Dictionary).get("entities", []):
		var entity := row as Dictionary
		if str(entity.get("side", "")) != "enemy":
			continue
		var uid := str(entity.get("unit_id", ""))
		if uid == "enemy_wandering_demon":
			has_melee = true
		if uid == "enemy_animated_machine":
			has_ranged = true
	if not has_melee:
		_failures.append("mixed battle should include enemy_wandering_demon")
	if not has_ranged:
		_failures.append("mixed battle should include enemy_animated_machine")
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
