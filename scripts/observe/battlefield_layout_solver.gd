extends RefCounted

const TOKEN_SIZE := Vector2(96, 112)
const SLOT_GAP_Y := 10.0
const SLOT_GAP_X := 8.0
const SLOT_MARGIN_X := 24.0
const SLOT_MARGIN_Y := 16.0
const FALLBACK_BOUNDS := Rect2(0, 0, 640, 360)


func resolve(rows: Array, bounds: Rect2) -> Array:
	var resolved: Array = rows.duplicate(true)
	var layout_bounds := _normalized_bounds(bounds)
	var groups := {
		"ally": [],
		"enemy": []
	}
	for index in range(resolved.size()):
		var row = resolved[index]
		if row is not Dictionary:
			continue
		var side := _group_side(str(row.get("side", "")))
		groups[side].append({
			"index": index,
			"position": _row_position(row)
		})
	_layout_side(resolved, groups.get("ally", []), layout_bounds, false)
	_layout_side(resolved, groups.get("enemy", []), layout_bounds, true)
	return resolved


func _layout_side(resolved: Array, group: Array, bounds: Rect2, right_side: bool) -> void:
	if group.is_empty():
		return
	var ordered := group.duplicate(true)
	ordered.sort_custom(_sort_group_item)
	var footprint := _footprint_bounds(bounds)
	var rows_per_column := _max_rows_per_column(footprint)
	var column_count := int(ceili(float(ordered.size()) / float(rows_per_column)))
	for column_index in range(column_count):
		var start_index := column_index * rows_per_column
		var end_index := mini(start_index + rows_per_column, ordered.size())
		var count_in_column := end_index - start_index
		if count_in_column <= 0:
			continue
		var y_values := _slot_y_values(count_in_column, footprint)
		var x := _column_x(footprint, right_side, column_index)
		for local_index in range(count_in_column):
			var item: Dictionary = ordered[start_index + local_index]
			var row_index := int(item.get("index", -1))
			if row_index < 0 or row_index >= resolved.size():
				continue
			var row: Dictionary = resolved[row_index]
			row["position"] = Vector2(x, y_values[local_index])
			resolved[row_index] = row


func _slot_y_values(count: int, footprint: Rect2) -> Array[float]:
	if count <= 0:
		return []
	if count == 1:
		return [clampf(
			footprint.position.y + footprint.size.y * 0.5,
			footprint.position.y,
			footprint.end.y
		)]
	var max_spacing := 0.0
	if count > 1:
		max_spacing = maxf(0.0, footprint.size.y / float(count - 1))
	var spacing := minf(TOKEN_SIZE.y + SLOT_GAP_Y, max_spacing)
	var used_height := spacing * float(count - 1)
	var first_y := footprint.position.y + maxf(0.0, (footprint.size.y - used_height) * 0.5)
	var ys: Array[float] = []
	for i in range(count):
		ys.append(clampf(first_y + float(i) * spacing, footprint.position.y, footprint.end.y))
	return ys


func _max_rows_per_column(footprint: Rect2) -> int:
	if footprint.size.y <= 0.0:
		return 1
	return maxi(1, int(floor(footprint.size.y / (TOKEN_SIZE.y + SLOT_GAP_Y))) + 1)


func _column_x(footprint: Rect2, right_side: bool, column_index: int) -> float:
	var stride := TOKEN_SIZE.x + SLOT_GAP_X
	if right_side:
		return clampf(
			footprint.end.x - float(column_index) * stride,
			footprint.position.x,
			footprint.end.x
		)
	return clampf(
		footprint.position.x + float(column_index) * stride,
		footprint.position.x,
		footprint.end.x
	)


func _group_side(side: String) -> String:
	if side == "enemy":
		return "enemy"
	return "ally"


func _sort_group_item(a: Dictionary, b: Dictionary) -> bool:
	var a_position := a.get("position", Vector2.ZERO) as Vector2
	var b_position := b.get("position", Vector2.ZERO) as Vector2
	if not is_equal_approx(a_position.y, b_position.y):
		return a_position.y < b_position.y
	return a_position.x < b_position.x


func _row_position(row: Dictionary) -> Vector2:
	var raw = row.get("position", Vector2.ZERO)
	if raw is Vector2:
		return raw
	return Vector2.ZERO


func _normalized_bounds(bounds: Rect2) -> Rect2:
	if bounds.size.x > 0.0 and bounds.size.y > 0.0:
		return bounds
	return FALLBACK_BOUNDS


func _footprint_bounds(bounds: Rect2) -> Rect2:
	return Rect2(
		bounds.position + Vector2(SLOT_MARGIN_X, SLOT_MARGIN_Y),
		Vector2(
			maxf(bounds.size.x - TOKEN_SIZE.x - SLOT_MARGIN_X * 2.0, 0.0),
			maxf(bounds.size.y - TOKEN_SIZE.y - SLOT_MARGIN_Y * 2.0, 0.0)
		)
	)
