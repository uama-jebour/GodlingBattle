extends SceneTree

const SOLVER_PATH := "res://scripts/observe/battlefield_layout_solver.gd"
const TOKEN_SIZE := Vector2(96, 112)

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
	_assert_pair_non_overlap(resolved, ["hero_angel_0", "ally_hound_remnant_1"], "ally pair should not overlap token rectangles")
	_assert_pair_non_overlap(resolved, ["enemy_wandering_demon_0", "enemy_wandering_demon_1"], "enemy pair should not overlap token rectangles")
	_assert_rows_within_bounds(resolved, Rect2(0, 0, 640, 360), "resolved tokens should stay within battlefield bounds")
	_finish()


func _assert_pair_non_overlap(rows: Array, entity_ids: Array[String], message: String) -> void:
	var rects: Array[Rect2] = []
	for entity_id in entity_ids:
		var row := _find_row(rows, entity_id)
		if row.is_empty():
			_failures.append("missing row for %s" % entity_id)
			return
		rects.append(Rect2(row.get("position", Vector2.ZERO), TOKEN_SIZE))
	if rects.size() != 2:
		_failures.append("expected two token rects for %s" % message)
		return
	if not rects[0].intersects(rects[1]):
		return
	_failures.append("%s (rect_a=%s, rect_b=%s)" % [message, rects[0], rects[1]])


func _assert_rows_within_bounds(rows: Array, bounds: Rect2, message: String) -> void:
	for row in rows:
		var rect := Rect2(row.get("position", Vector2.ZERO), TOKEN_SIZE)
		if rect.position.x < bounds.position.x or rect.position.y < bounds.position.y:
			_failures.append("%s (rect starts outside bounds: %s)" % [message, rect])
			return
		if rect.end.x > bounds.end.x or rect.end.y > bounds.end.y:
			_failures.append("%s (rect exceeds bounds: %s)" % [message, rect])
			return


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
