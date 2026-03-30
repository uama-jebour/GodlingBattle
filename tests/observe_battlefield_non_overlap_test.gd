extends SceneTree

const SOLVER_PATH := "res://scripts/observe/battlefield_layout_solver.gd"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var solver_script: GDScript = load(SOLVER_PATH)
	if solver_script == null:
		_failures.append("failed to load battlefield layout solver")
		_finish()
		return
	var solver: RefCounted = solver_script.new()
	if not solver.has_method("resolve"):
		_failures.append("missing resolve")
		_finish()
		return
	var rows := [
		{
			"entity_id": "hero_angel_0",
			"display_name": "英雄：天使",
			"side": "hero",
			"position": Vector2(120, 220)
		},
		{
			"entity_id": "ally_hound_remnant_1",
			"display_name": "残迹猎犬",
			"side": "ally",
			"position": Vector2(135, 235)
		},
		{
			"entity_id": "enemy_wandering_demon_0",
			"display_name": "游荡魔",
			"side": "enemy",
			"position": Vector2(480, 210)
		},
		{
			"entity_id": "enemy_wandering_demon_1",
			"display_name": "游荡魔",
			"side": "enemy",
			"position": Vector2(495, 225)
		}
	]
	var resolved: Array = solver.resolve(rows, Rect2(0, 0, 640, 360))
	_assert_min_pair_distance(resolved, ["hero_angel_0", "ally_hound_remnant_1"], 90.0, "ally pair should keep 90 spacing")
	_assert_min_pair_distance(resolved, ["enemy_wandering_demon_0", "enemy_wandering_demon_1"], 90.0, "enemy pair should keep 90 spacing")
	_finish()


func _assert_min_pair_distance(rows: Array, entity_ids: Array[String], min_distance: float, message: String) -> void:
	var positions: Array[Vector2] = []
	for entity_id in entity_ids:
		var row := _find_row(rows, entity_id)
		if row.is_empty():
			_failures.append("missing row for %s" % entity_id)
			return
		positions.append(row.get("position", Vector2.ZERO))
	if positions.size() != 2:
		_failures.append("expected two positions for %s" % message)
		return
	if positions[0].distance_to(positions[1]) >= min_distance:
		return
	_failures.append("%s (distance=%.2f)" % [message, positions[0].distance_to(positions[1])])


func _find_row(rows: Array, entity_id: String) -> Dictionary:
	for row in rows:
		if str(row.get("entity_id", "")) == entity_id:
			return row
	return {}


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
