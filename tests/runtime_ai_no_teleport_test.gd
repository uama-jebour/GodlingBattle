extends SceneTree

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")

var _failures: Array[String] = []
const MAX_DELTA_PER_TICK := 20.0


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
	for i in range(1, timeline.size()):
		var previous_by_id: Dictionary = {}
		var previous_entities: Array = (timeline[i - 1] as Dictionary).get("entities", [])
		for row in previous_entities:
			previous_by_id[str(row.get("entity_id", ""))] = row.get("position", Vector2.ZERO)
		var current_entities: Array = (timeline[i] as Dictionary).get("entities", [])
		for row in current_entities:
			var entity_id := str(row.get("entity_id", ""))
			if not previous_by_id.has(entity_id):
				continue
			var current_pos: Variant = row.get("position", Vector2.ZERO)
			var previous_pos: Variant = previous_by_id[entity_id]
			if current_pos is not Vector2 or previous_pos is not Vector2:
				continue
			var delta := (current_pos as Vector2).distance_to(previous_pos as Vector2)
			if delta > MAX_DELTA_PER_TICK:
				_failures.append("teleport-like movement: %s delta=%f tick=%d" % [entity_id, delta, i])
				_finish()
				return
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
