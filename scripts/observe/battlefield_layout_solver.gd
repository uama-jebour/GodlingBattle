extends RefCounted

const TOKEN_SIZE := Vector2(96, 112)
const TOKEN_GAP := 8.0
const MIN_SPACING := TOKEN_SIZE.y + TOKEN_GAP
const FALLBACK_BOUNDS := Rect2(0, 0, 640, 360)


func resolve(rows: Array, bounds: Rect2) -> Array:
	var resolved: Array = rows.duplicate(true)
	var layout_bounds := _normalized_bounds(bounds)
	var groups := {
		"ally_team": [],
		"enemy": []
	}
	for index in range(resolved.size()):
		var row = resolved[index]
		if row is not Dictionary:
			continue
		var side := str(row.get("side", ""))
		var group_key := "enemy" if side == "enemy" else "ally_team"
		groups[group_key].append({
			"index": index,
			"position": _row_position(row)
		})
	for group in groups.values():
		_resolve_group(resolved, group, layout_bounds)
	return resolved


func _resolve_group(resolved: Array, group: Array, bounds: Rect2) -> void:
	if group.is_empty():
		return
	var ordered: Array = group.duplicate(true)
	ordered.sort_custom(_sort_group_row)
	var spacing := _target_spacing(ordered.size(), bounds)
	var clamped_bounds := _footprint_bounds(bounds)
	var min_y := clamped_bounds.position.y
	var max_y := clamped_bounds.end.y
	var max_first_y := max_y - spacing * float(maxi(0, ordered.size() - 1))
	var first_item: Dictionary = ordered[0]
	var y_positions: Array[float] = [clampf(float((first_item.get("position", Vector2.ZERO) as Vector2).y), min_y, max_first_y)]
	for index in range(1, ordered.size()):
		var item: Dictionary = ordered[index]
		var position := item.get("position", Vector2.ZERO) as Vector2
		var min_allowed := y_positions[index - 1] + spacing
		var max_allowed := max_y - spacing * float(ordered.size() - 1 - index)
		y_positions.append(clampf(position.y, min_allowed, max_allowed))
	for index in range(ordered.size()):
		var item: Dictionary = ordered[index]
		var row_index := int(item.get("index", -1))
		if row_index < 0 or row_index >= resolved.size():
			continue
		var row: Dictionary = resolved[row_index]
		var position := _row_position(row)
		position.x = clampf(position.x, clamped_bounds.position.x, clamped_bounds.end.x)
		position.y = y_positions[index]
		row["position"] = position
		resolved[row_index] = row


func _target_spacing(count: int, bounds: Rect2) -> float:
	if count <= 1:
		return 0.0
	var available_height := maxf(_footprint_bounds(bounds).size.y, 0.0)
	var max_spacing := available_height / float(count - 1)
	return minf(MIN_SPACING, max_spacing)


func _normalized_bounds(bounds: Rect2) -> Rect2:
	if bounds.size.x > 0.0 and bounds.size.y > 0.0:
		return bounds
	return FALLBACK_BOUNDS


func _footprint_bounds(bounds: Rect2) -> Rect2:
	var footprint_size := Vector2(
		maxf(bounds.size.x - TOKEN_SIZE.x, 0.0),
		maxf(bounds.size.y - TOKEN_SIZE.y, 0.0)
	)
	return Rect2(bounds.position, footprint_size)


func _row_position(row: Dictionary) -> Vector2:
	var raw = row.get("position", Vector2.ZERO)
	if raw is Vector2:
		return raw
	return Vector2.ZERO


func _sort_group_row(a: Dictionary, b: Dictionary) -> bool:
	var a_position := a.get("position", Vector2.ZERO) as Vector2
	var b_position := b.get("position", Vector2.ZERO) as Vector2
	if not is_equal_approx(a_position.y, b_position.y):
		return a_position.y < b_position.y
	return a_position.x < b_position.x
