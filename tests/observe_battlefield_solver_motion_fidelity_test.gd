extends SceneTree

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")
const SOLVER := preload("res://scripts/observe/battlefield_layout_solver.gd")

const MAX_SOLVER_JUMP := 40.0
const MAX_AVG_RAW_DISPLACEMENT := 130.0
const RUNTIME_ARENA_BOUNDS := Rect2(120.0, 200.0, 620.0, 620.0)

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

	var solver = SOLVER.new()
	var bounds := Rect2(0, 0, 640, 360)
	var enemy_ids := _enemy_ids_from_first_frame(timeline)
	var prev_pos_by_id: Dictionary = {}
	var max_jump_by_id: Dictionary = {}
	var displacement_sum_by_id: Dictionary = {}
	var displacement_count_by_id: Dictionary = {}

	for frame in timeline:
		var entities: Array = (frame as Dictionary).get("entities", [])
		var rows: Array = []
		for entity in entities:
			rows.append({
				"entity_id": str(entity.get("entity_id", "")),
				"side": str(entity.get("side", "")),
				"position": _map_runtime_position(entity.get("position", Vector2.ZERO), bounds)
			})
		var resolved: Array = solver.resolve(rows, bounds)
		var raw_by_id := _position_lookup(rows)
		var resolved_by_id := _position_lookup(resolved)
		for enemy_id in enemy_ids:
			if not resolved_by_id.has(enemy_id):
				continue
			var resolved_pos := resolved_by_id[enemy_id] as Vector2
			if prev_pos_by_id.has(enemy_id):
				var jump := resolved_pos.distance_to(prev_pos_by_id[enemy_id] as Vector2)
				var previous_jump := float(max_jump_by_id.get(enemy_id, 0.0))
				max_jump_by_id[enemy_id] = maxf(previous_jump, jump)
			prev_pos_by_id[enemy_id] = resolved_pos

			if raw_by_id.has(enemy_id):
				var raw_pos := raw_by_id[enemy_id] as Vector2
				displacement_sum_by_id[enemy_id] = float(displacement_sum_by_id.get(enemy_id, 0.0)) + resolved_pos.distance_to(raw_pos)
				displacement_count_by_id[enemy_id] = int(displacement_count_by_id.get(enemy_id, 0)) + 1

	for enemy_id in enemy_ids:
		var max_jump := float(max_jump_by_id.get(enemy_id, 0.0))
		if max_jump > MAX_SOLVER_JUMP:
			_failures.append("solver jump too large for %s: %.3f > %.3f" % [enemy_id, max_jump, MAX_SOLVER_JUMP])
		var count := int(displacement_count_by_id.get(enemy_id, 0))
		if count <= 0:
			continue
		var avg_disp := float(displacement_sum_by_id.get(enemy_id, 0.0)) / float(count)
		if avg_disp > MAX_AVG_RAW_DISPLACEMENT:
			_failures.append("solver drifts too far from runtime for %s: %.3f > %.3f" % [enemy_id, avg_disp, MAX_AVG_RAW_DISPLACEMENT])

	_finish()


func _enemy_ids_from_first_frame(timeline: Array) -> Array[String]:
	var ids: Array[String] = []
	var first_entities: Array = (timeline[0] as Dictionary).get("entities", [])
	for row in first_entities:
		if str(row.get("side", "")) != "enemy":
			continue
		var entity_id := str(row.get("entity_id", ""))
		if not entity_id.is_empty():
			ids.append(entity_id)
	return ids


func _position_lookup(rows: Array) -> Dictionary:
	var lookup: Dictionary = {}
	for row in rows:
		var entity_id := str((row as Dictionary).get("entity_id", ""))
		if entity_id.is_empty():
			continue
		var raw_position: Variant = (row as Dictionary).get("position", Vector2.ZERO)
		if raw_position is Vector2:
			lookup[entity_id] = raw_position
	return lookup


func _map_runtime_position(raw_position_value: Variant, battlefield_bounds: Rect2) -> Vector2:
	if raw_position_value is not Vector2:
		return Vector2.ZERO
	var runtime_position := raw_position_value as Vector2
	var ratio_x := clampf(
		(runtime_position.x - RUNTIME_ARENA_BOUNDS.position.x) / RUNTIME_ARENA_BOUNDS.size.x,
		0.0,
		1.0
	)
	var ratio_y := clampf(
		(runtime_position.y - RUNTIME_ARENA_BOUNDS.position.y) / RUNTIME_ARENA_BOUNDS.size.y,
		0.0,
		1.0
	)
	return Vector2(
		battlefield_bounds.position.x + battlefield_bounds.size.x * ratio_x,
		battlefield_bounds.position.y + battlefield_bounds.size.y * ratio_y
	)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
