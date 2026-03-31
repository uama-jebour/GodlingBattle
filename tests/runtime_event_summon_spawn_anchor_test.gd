extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner: RefCounted = load("res://scripts/battle_runtime/battle_runner.gd").new()
	var payload: Dictionary = runner.run({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 20260330
	})
	var timeline: Array = payload.get("timeline", [])
	var first_spawn_pos_by_entity: Dictionary = {}
	for frame in timeline:
		for row in (frame as Dictionary).get("entities", []):
			var d := row as Dictionary
			if str(d.get("unit_id", "")) == "enemy_hunter_fiend" and str(d.get("entity_id", "")).find("_spawn_") != -1:
				var entity_id := str(d.get("entity_id", ""))
				if first_spawn_pos_by_entity.has(entity_id):
					continue
				first_spawn_pos_by_entity[entity_id] = d.get("position", Vector2.ZERO) as Vector2
	if first_spawn_pos_by_entity.is_empty():
		_failures.append("expected summoned hunter fiend")
		_finish()
		return
	for p in first_spawn_pos_by_entity.values():
		if p.x < 640.0:
			_failures.append("expected summon at right flank, got x=%f" % p.x)
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for msg in _failures:
		printerr(msg)
	quit(1)
