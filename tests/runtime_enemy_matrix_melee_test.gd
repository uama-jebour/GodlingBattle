extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var payload: Dictionary = load("res://scripts/battle_runtime/battle_runner.gd").new().run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_test_enemy_melee",
		"seed": 26033111
	})
	_assert_first_frame_enemy_units(payload.get("timeline", []), ["enemy_wandering_demon"])
	_finish()


func _assert_first_frame_enemy_units(timeline: Array, allowed_units: Array[String]) -> void:
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		return
	for row in (timeline[0] as Dictionary).get("entities", []):
		var entity := row as Dictionary
		if str(entity.get("side", "")) != "enemy":
			continue
		if not allowed_units.has(str(entity.get("unit_id", ""))):
			_failures.append("unexpected enemy unit in melee battle: %s" % str(entity.get("unit_id", "")))


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
