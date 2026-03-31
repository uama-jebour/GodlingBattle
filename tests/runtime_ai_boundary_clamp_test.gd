extends SceneTree

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")

var _failures: Array[String] = []
const BOUNDS := Rect2(120.0, 200.0, 620.0, 620.0)


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
	for frame_index in range(timeline.size()):
		var entities: Array = (timeline[frame_index] as Dictionary).get("entities", [])
		for row in entities:
			var pos: Variant = row.get("position", Vector2.ZERO)
			if pos is not Vector2:
				continue
			if not BOUNDS.has_point(pos as Vector2):
				_failures.append("out-of-bounds: %s pos=%s frame=%d" % [str(row.get("entity_id", "")), pos, frame_index])
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
