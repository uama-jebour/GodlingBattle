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
	var timeline: Array = payload.get("timeline", [])
	if timeline.is_empty():
		_failures.append("timeline should not be empty")
		_finish()
		return

	var min_distance := INF
	for frame in timeline:
		var entities: Array = (frame as Dictionary).get("entities", [])
		var hero_or_ally: Array[Vector2] = []
		var enemies: Array[Vector2] = []
		for row in entities:
			if not bool(row.get("alive", false)):
				continue
			var side := str(row.get("side", ""))
			var pos: Variant = row.get("position", Vector2.ZERO)
			if pos is not Vector2:
				continue
			if side == "enemy":
				enemies.append(pos as Vector2)
			else:
				hero_or_ally.append(pos as Vector2)
		for a in hero_or_ally:
			for b in enemies:
				min_distance = minf(min_distance, a.distance_to(b))

	if min_distance > 78.0:
		_failures.append("pathing should enter practical engage range; min distance=%f" % min_distance)

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
