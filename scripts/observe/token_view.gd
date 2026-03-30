extends Control

var entity_id := ""
var display_name := ""
var hp_ratio := 1.0
var side := ""
var world_position := Vector2.ZERO


func apply_snapshot(snapshot: Dictionary) -> void:
	entity_id = str(snapshot.get("entity_id", ""))
	display_name = str(snapshot.get("display_name", ""))
	hp_ratio = float(snapshot.get("hp_ratio", 1.0))
	side = str(snapshot.get("side", ""))
	world_position = _as_vector2(snapshot.get("position", Vector2.ZERO))
	position = world_position


func _as_vector2(raw_value) -> Vector2:
	if raw_value is Vector2:
		return raw_value
	return Vector2.ZERO
