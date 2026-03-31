extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var tier1 := _run_pack(runner, "battle_test_difficulty_tier1")
	var tier2 := _run_pack(runner, "battle_test_difficulty_tier2")
	var tier3 := _run_pack(runner, "battle_test_difficulty_tier3")

	var enemy_count_1 := _opening_enemy_count(tier1)
	var enemy_count_2 := _opening_enemy_count(tier2)
	var enemy_count_3 := _opening_enemy_count(tier3)
	if not (enemy_count_1 < enemy_count_2 and enemy_count_2 < enemy_count_3):
		_failures.append("expected opening enemy count curve tier1<tier2<tier3, got %d,%d,%d" % [enemy_count_1, enemy_count_2, enemy_count_3])

	var elite_count_1 := _opening_elite_enemy_count(tier1)
	var elite_count_3 := _opening_elite_enemy_count(tier3)
	if elite_count_3 <= elite_count_1:
		_failures.append("expected tier3 elite pressure higher than tier1")

	_finish()


func _run_pack(runner: RefCounted, battle_id: String) -> Dictionary:
	return runner.run({
		"hero_id": "hero_angel",
		"ally_entries": [
			{"unit_id": "ally_hound_remnant", "count": 2},
			{"unit_id": "ally_arc_shooter", "count": 1}
		],
		"ally_ids": [],
		"strategy_ids": ["strat_chill_wave"],
		"battle_id": battle_id,
		"seed": 26033191
	})


func _opening_enemy_count(payload: Dictionary) -> int:
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		return -1
	var count := 0
	for row in (timeline[0] as Dictionary).get("entities", []):
		var entity := row as Dictionary
		if str(entity.get("side", "")) == "enemy":
			count += 1
	return count


func _opening_elite_enemy_count(payload: Dictionary) -> int:
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		return -1
	var count := 0
	for row in (timeline[0] as Dictionary).get("entities", []):
		var entity := row as Dictionary
		if str(entity.get("side", "")) != "enemy":
			continue
		if str(entity.get("unit_id", "")) == "enemy_hunter_fiend":
			count += 1
	return count


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
