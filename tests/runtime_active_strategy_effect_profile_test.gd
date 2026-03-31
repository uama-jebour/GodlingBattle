extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var seed := 26033177
	var baseline: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": seed
	})
	var chill: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_chill_wave"],
		"battle_id": "battle_void_gate_alpha",
		"seed": seed
	})
	var nuke: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_nuclear_strike"],
		"battle_id": "battle_void_gate_alpha",
		"seed": seed
	})

	var chill_timeline: Array = chill.get("timeline", [])
	var baseline_timeline: Array = baseline.get("timeline", [])
	var slow_tick := _first_enemy_slow_tick(chill_timeline)
	if slow_tick < 0:
		_failures.append("expected chill wave to produce enemy slow state in timeline")
	elif _has_enemy_slow_at_tick(baseline_timeline, slow_tick):
		_failures.append("baseline should not produce enemy slow state at matching tick")

	var baseline_front_hp := _front_enemy_hp_at_tick(baseline_timeline, 0)
	var nuke_front_hp := _front_enemy_hp_at_tick(nuke.get("timeline", []), 0)
	if nuke_front_hp < 0.0 or baseline_front_hp < 0.0:
		_failures.append("expected valid front enemy hp in frame 0")
	elif nuke_front_hp >= baseline_front_hp:
		_failures.append("expected nuclear strike to reduce front enemy hp in frame 0")

	if not _has_strategy_cast(nuke.get("result", {}).get("log_entries", []), "strat_nuclear_strike"):
		_failures.append("expected strat_nuclear_strike strategy_cast log")

	_finish()


func _first_enemy_slow_tick(timeline: Array) -> int:
	for row in timeline:
		var frame := row as Dictionary
		var tick := int(frame.get("tick", -1))
		for entity_raw in frame.get("entities", []):
			var entity := entity_raw as Dictionary
			if str(entity.get("side", "")) != "enemy":
				continue
			if int(entity.get("slow_ticks_remaining", 0)) > 0 and float(entity.get("slow_ratio", 0.0)) > 0.0:
				return tick
	return -1


func _has_enemy_slow_at_tick(timeline: Array, tick: int) -> bool:
	for row in timeline:
		var frame := row as Dictionary
		if int(frame.get("tick", -1)) != tick:
			continue
		for entity_raw in frame.get("entities", []):
			var entity := entity_raw as Dictionary
			if str(entity.get("side", "")) != "enemy":
				continue
			if int(entity.get("slow_ticks_remaining", 0)) > 0 and float(entity.get("slow_ratio", 0.0)) > 0.0:
				return true
	return false


func _front_enemy_hp_at_tick(timeline: Array, tick: int) -> float:
	for row in timeline:
		var frame := row as Dictionary
		if int(frame.get("tick", -1)) != tick:
			continue
		var best_x := INF
		var best_hp := -1.0
		for entity_raw in frame.get("entities", []):
			var entity := entity_raw as Dictionary
			if str(entity.get("side", "")) != "enemy":
				continue
			if not bool(entity.get("alive", false)):
				continue
			var position = entity.get("position", Vector2.ZERO)
			var x := float((position as Vector2).x)
			if x < best_x:
				best_x = x
				best_hp = float(entity.get("hp", -1.0))
		return best_hp
	return -1.0


func _has_strategy_cast(log_entries: Array, strategy_id: String) -> bool:
	for row_raw in log_entries:
		var row := row_raw as Dictionary
		if str(row.get("type", "")) != "strategy_cast":
			continue
		if str(row.get("strategy_id", "")) == strategy_id:
			return true
	return false


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
