extends RefCounted

const TOKEN_SIZE := Vector2(115.2, 134.4)
const SLOT_GAP_Y := 10.0
const SLOT_GAP_X := 8.0
const SLOT_MARGIN_X := 24.0
const SLOT_MARGIN_Y := 16.0
const FALLBACK_BOUNDS := Rect2(0, 0, 640, 360)
const STABLE_ANCHOR_BLEND := 0.42
const MAX_FRAME_STEP_FROM_PREVIOUS := 36.0
const MAX_RUNTIME_OFFSET := 220.0
const MAX_COLLISION_ITERATIONS := 10
const COLLISION_EPSILON := 0.5
const CROSS_SIDE_PUSH_SCALE := 0.72

var _last_resolved_position_by_entity: Dictionary = {}


func resolve(rows: Array, bounds: Rect2) -> Array:
	var resolved: Array = rows.duplicate(true)
	var layout_bounds := _placement_bounds(_normalized_bounds(bounds))
	var items: Array = []
	for index in range(resolved.size()):
		var row = resolved[index]
		if row is not Dictionary:
			continue
		var side := _group_side(str(row.get("side", "")))
		var raw_position := _clamp_to_side_lane(_clamp_position(_row_position(row), layout_bounds), layout_bounds, side)
		var entity_id := str(row.get("entity_id", ""))
		items.append({
			"index": index,
			"entity_id": entity_id,
			"side": side,
			"raw_position": raw_position,
			"position": _initial_position_for_item(entity_id, raw_position, side, layout_bounds)
		})
	if items.is_empty():
		return resolved
	_resolve_collisions(items, layout_bounds)
	var next_last_resolved_position_by_entity: Dictionary = {}
	for item in items:
		var row_index := int(item.get("index", -1))
		if row_index < 0 or row_index >= resolved.size():
			continue
		var row: Dictionary = resolved[row_index]
		var side := str(item.get("side", "ally"))
		var entity_id := str(item.get("entity_id", ""))
		var position := _finalize_item_position(item, side, entity_id, layout_bounds)
		row["position"] = position
		resolved[row_index] = row
		if not entity_id.is_empty() and position is Vector2:
			next_last_resolved_position_by_entity[entity_id] = position
	_last_resolved_position_by_entity = next_last_resolved_position_by_entity
	return resolved


func _resolve_collisions(items: Array, bounds: Rect2) -> void:
	for index in range(items.size()):
		var item := items[index] as Dictionary
		var side := str(item.get("side", "ally"))
		var position := _item_position(item)
		item["position"] = _clamp_to_side_lane(_clamp_position(position, bounds), bounds, side)
		items[index] = item
	for _iteration in range(MAX_COLLISION_ITERATIONS):
		var moved := false
		for i in range(items.size()):
			for j in range(i + 1, items.size()):
				if _resolve_pair(items, i, j, bounds):
					moved = true
		if not moved:
			break
	if _count_side_items(items, "ally") >= 3 and _has_side_overlap(items, "ally"):
		_repack_side(items, bounds, "ally")
		_set_force_layout_for_side(items, "ally")
	if _count_side_items(items, "enemy") >= 3 and _has_side_overlap(items, "enemy"):
		_repack_side(items, bounds, "enemy")
		_set_force_layout_for_side(items, "enemy")
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var side := str(item.get("side", "ally"))
		var pos := _clamp_position(_item_position(item), bounds)
		pos = _clamp_to_side_lane(pos, bounds, side)
		pos = _limit_position_from_raw(item, pos)
		item["position"] = pos
		items[index] = item


func _repack_side(items: Array, bounds: Rect2, side: String) -> void:
	var target_indices: Array[int] = []
	for index in range(items.size()):
		var item := items[index] as Dictionary
		if str(item.get("side", "ally")) != side:
			continue
		target_indices.append(index)
	if target_indices.is_empty():
		return
	target_indices.sort_custom(func(a: int, b: int) -> bool:
		var item_a := items[a] as Dictionary
		var item_b := items[b] as Dictionary
		return str(item_a.get("entity_id", "")) < str(item_b.get("entity_id", ""))
	)
	var placed_rects: Array[Rect2] = []
	for item_index in target_indices:
		var item := items[item_index] as Dictionary
		var entity_id := str(item.get("entity_id", ""))
		var desired := _stable_desired_position(entity_id, _row_position(item))
		desired = _clamp_to_side_lane(desired, bounds, side)
		var resolved_pos := _find_free_position(desired, placed_rects, bounds, side == "enemy")
		item["position"] = resolved_pos
		items[item_index] = item
		placed_rects.append(Rect2(resolved_pos, TOKEN_SIZE))


func _find_free_position(desired: Vector2, placed_rects: Array[Rect2], bounds: Rect2, prefer_left: bool) -> Vector2:
	var stride_x := TOKEN_SIZE.x + SLOT_GAP_X
	var stride_y := TOKEN_SIZE.y + SLOT_GAP_Y
	var y_offsets_near := _symmetric_offsets(1)
	for x_step in range(0, 8):
		var x_dir := -1.0 if prefer_left else 1.0
		var x_offset := float(x_step) * stride_x * x_dir
		for y_step in y_offsets_near:
			var candidate := _clamp_position(
				desired + Vector2(x_offset, float(y_step) * stride_y),
				bounds
			)
			if not _intersects_any(candidate, placed_rects):
				return candidate
	var y_offsets_far := _symmetric_offsets(8)
	for x_step in range(0, 8):
		var x_dir := -1.0 if prefer_left else 1.0
		var x_offset := float(x_step) * stride_x * x_dir
		for y_step in y_offsets_far:
			var candidate := _clamp_position(
				desired + Vector2(x_offset, float(y_step) * stride_y),
				bounds
			)
			if not _intersects_any(candidate, placed_rects):
				return candidate
	return _clamp_position(desired, bounds)


func _symmetric_offsets(max_abs: int) -> Array:
	var offsets: Array = [0]
	for step in range(1, max_abs + 1):
		offsets.append(step)
		offsets.append(-step)
	return offsets


func _stable_desired_position(entity_id: String, desired: Vector2) -> Vector2:
	if entity_id.is_empty():
		return desired
	var previous: Variant = _last_resolved_position_by_entity.get(entity_id, desired)
	if previous is not Vector2:
		return desired
	return (previous as Vector2).lerp(desired, STABLE_ANCHOR_BLEND)


func _intersects_any(position: Vector2, placed_rects: Array[Rect2]) -> bool:
	var rect := Rect2(position, TOKEN_SIZE)
	for placed in placed_rects:
		if rect.intersects(placed):
			return true
	return false


func _resolve_pair(items: Array, index_a: int, index_b: int, bounds: Rect2) -> bool:
	var item_a: Dictionary = items[index_a]
	var item_b: Dictionary = items[index_b]
	var side_a := str(item_a.get("side", "ally"))
	var side_b := str(item_b.get("side", "ally"))
	var same_side := side_a == side_b
	var pos_a: Vector2 = _item_position(item_a)
	var pos_b: Vector2 = _item_position(item_b)
	var before_a := pos_a
	var before_b := pos_b
	var center_a := pos_a + TOKEN_SIZE * 0.5
	var center_b := pos_b + TOKEN_SIZE * 0.5
	var dx := center_b.x - center_a.x
	var dy := center_b.y - center_a.y
	var min_dx := TOKEN_SIZE.x + SLOT_GAP_X
	var min_dy := TOKEN_SIZE.y + SLOT_GAP_Y
	var overlap_x := min_dx - absf(dx)
	var overlap_y := min_dy - absf(dy)
	if overlap_x <= 0.0 or overlap_y <= 0.0:
		return false
	var resolve_x := overlap_x < overlap_y
	if is_equal_approx(overlap_x, overlap_y):
		resolve_x = absf(dx) >= absf(dy)
	if resolve_x:
		var dir_x := signf(dx)
		if is_zero_approx(dir_x):
			dir_x = _horizontal_bias(item_a, item_b)
		var push_x := overlap_x * 0.5 + COLLISION_EPSILON
		if not same_side:
			push_x *= CROSS_SIDE_PUSH_SCALE
		pos_a.x -= dir_x * push_x
		pos_b.x += dir_x * push_x
	else:
		var dir_y := signf(dy)
		if is_zero_approx(dir_y):
			dir_y = _vertical_bias(item_a, item_b)
		var push_y := overlap_y * 0.5 + COLLISION_EPSILON
		if not same_side:
			push_y *= CROSS_SIDE_PUSH_SCALE
		pos_a.y -= dir_y * push_y
		pos_b.y += dir_y * push_y
	pos_a = _clamp_to_side_lane(_clamp_position(pos_a, bounds), bounds, side_a)
	pos_b = _clamp_to_side_lane(_clamp_position(pos_b, bounds), bounds, side_b)
	pos_a = _limit_position_from_raw(item_a, pos_a)
	pos_b = _limit_position_from_raw(item_b, pos_b)
	item_a["position"] = pos_a
	item_b["position"] = pos_b
	items[index_a] = item_a
	items[index_b] = item_b
	return pos_a.distance_to(before_a) > 0.001 or pos_b.distance_to(before_b) > 0.001


func _group_side(side: String) -> String:
	if side == "enemy":
		return "enemy"
	return "ally"


func _row_position(row: Dictionary) -> Vector2:
	var raw = row.get("position", Vector2.ZERO)
	if raw is Vector2:
		return raw
	return Vector2.ZERO


func _item_position(item: Dictionary) -> Vector2:
	var value: Variant = item.get("position", Vector2.ZERO)
	if value is Vector2:
		return value
	return _row_position(item)


func _normalized_bounds(bounds: Rect2) -> Rect2:
	if bounds.size.x > 0.0 and bounds.size.y > 0.0:
		return bounds
	return FALLBACK_BOUNDS


func _placement_bounds(bounds: Rect2) -> Rect2:
	return Rect2(
		bounds.position + Vector2(SLOT_MARGIN_X, SLOT_MARGIN_Y),
		Vector2(
			maxf(bounds.size.x - TOKEN_SIZE.x - SLOT_MARGIN_X * 2.0, 0.0),
			maxf(bounds.size.y - TOKEN_SIZE.y - SLOT_MARGIN_Y * 2.0, 0.0)
		)
	)


func _clamp_position(position: Vector2, bounds: Rect2) -> Vector2:
	return Vector2(
		clampf(position.x, bounds.position.x, bounds.end.x),
		clampf(position.y, bounds.position.y, bounds.end.y)
	)


func _clamp_to_side_lane(position: Vector2, bounds: Rect2, side: String) -> Vector2:
	return _clamp_position(position, bounds)


func _horizontal_bias(item_a: Dictionary, item_b: Dictionary) -> float:
	var side_a := str(item_a.get("side", "ally"))
	var side_b := str(item_b.get("side", "ally"))
	if side_a != side_b:
		if side_a == "enemy":
			return 1.0
		if side_b == "enemy":
			return -1.0
	return _id_bias(item_a, item_b)


func _vertical_bias(item_a: Dictionary, item_b: Dictionary) -> float:
	return _id_bias(item_a, item_b)


func _id_bias(item_a: Dictionary, item_b: Dictionary) -> float:
	var id_a := str(item_a.get("entity_id", ""))
	var id_b := str(item_b.get("entity_id", ""))
	if id_a <= id_b:
		return -1.0
	return 1.0


func _initial_position_for_item(entity_id: String, raw_position: Vector2, side: String, bounds: Rect2) -> Vector2:
	var previous: Variant = _last_resolved_position_by_entity.get(entity_id, raw_position)
	if previous is not Vector2:
		return raw_position
	var previous_position := _clamp_to_side_lane(_clamp_position(previous as Vector2, bounds), bounds, side)
	return previous_position.move_toward(raw_position, MAX_FRAME_STEP_FROM_PREVIOUS)


func _finalize_item_position(item: Dictionary, side: String, entity_id: String, bounds: Rect2) -> Vector2:
	var position := _item_position(item)
	position = _clamp_to_side_lane(_clamp_position(position, bounds), bounds, side)
	position = _limit_position_from_raw(item, position)
	position = _limit_position_from_previous(entity_id, position)
	return Vector2(round(position.x), round(position.y))


func _limit_position_from_raw(item: Dictionary, position: Vector2) -> Vector2:
	if bool(item.get("force_layout", false)):
		return position
	var raw_value: Variant = item.get("raw_position", position)
	if raw_value is not Vector2:
		return position
	var raw_position := raw_value as Vector2
	if raw_position.distance_to(position) <= MAX_RUNTIME_OFFSET:
		return position
	return raw_position.move_toward(position, MAX_RUNTIME_OFFSET)


func _limit_position_from_previous(entity_id: String, position: Vector2) -> Vector2:
	if entity_id.is_empty():
		return position
	var previous: Variant = _last_resolved_position_by_entity.get(entity_id, position)
	if previous is not Vector2:
		return position
	var previous_position := previous as Vector2
	if previous_position.distance_to(position) <= MAX_FRAME_STEP_FROM_PREVIOUS:
		return position
	return previous_position.move_toward(position, MAX_FRAME_STEP_FROM_PREVIOUS)


func _count_side_items(items: Array, side: String) -> int:
	var count := 0
	for item_variant in items:
		if str((item_variant as Dictionary).get("side", "ally")) == side:
			count += 1
	return count


func _has_side_overlap(items: Array, side: String) -> bool:
	var rects: Array[Rect2] = []
	for item_variant in items:
		var item := item_variant as Dictionary
		if str(item.get("side", "ally")) != side:
			continue
		rects.append(Rect2(_item_position(item), TOKEN_SIZE))
	for i in range(rects.size()):
		for j in range(i + 1, rects.size()):
			if rects[i].intersects(rects[j]):
				return true
	return false


func _set_force_layout_for_side(items: Array, side: String) -> void:
	for index in range(items.size()):
		var item := items[index] as Dictionary
		if str(item.get("side", "ally")) != side:
			continue
		item["force_layout"] = true
		items[index] = item
