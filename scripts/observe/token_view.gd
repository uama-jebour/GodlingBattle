extends Control

const COLOR_HERO := Color(0.95, 0.87, 0.36, 1.0)
const COLOR_ALLY := Color(0.35, 0.75, 0.98, 1.0)
const COLOR_ENEMY := Color(0.95, 0.36, 0.36, 1.0)
const COLOR_BG := Color(0.08, 0.1, 0.14, 0.86)
const COLOR_HP_BG := Color(0.17, 0.2, 0.24, 0.95)
const COLOR_HP_FILL := Color(0.42, 0.89, 0.52, 0.95)
const COLOR_HP_LOW := Color(0.92, 0.3, 0.24, 0.95)

var entity_id := ""
var display_name := ""
var hp_ratio := 1.0
var side := ""
var world_position := Vector2.ZERO


func apply_snapshot(snapshot: Dictionary) -> void:
	entity_id = str(snapshot.get("entity_id", ""))
	display_name = str(snapshot.get("display_name", ""))
	hp_ratio = clampf(float(snapshot.get("hp_ratio", 1.0)), 0.0, 1.0)
	side = str(snapshot.get("side", ""))
	world_position = _as_vector2(snapshot.get("position", Vector2.ZERO))
	position = world_position
	size = custom_minimum_size
	queue_redraw()


func _as_vector2(raw_value) -> Vector2:
	if raw_value is Vector2:
		return raw_value
	return Vector2.ZERO


func get_side_color() -> Color:
	if side == "hero":
		return COLOR_HERO
	if side == "enemy":
		return COLOR_ENEMY
	return COLOR_ALLY


func get_hp_fill_color() -> Color:
	if hp_ratio <= 0.3:
		return COLOR_HP_LOW
	return COLOR_HP_FILL


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		rect = Rect2(Vector2.ZERO, custom_minimum_size)
	draw_rect(rect, COLOR_BG, true)
	draw_rect(rect, get_side_color(), false, 2.0)

	var hp_bg := Rect2(Vector2(8, rect.size.y - 16), Vector2(rect.size.x - 16, 8))
	draw_rect(hp_bg, COLOR_HP_BG, true)
	var hp_fill := Rect2(hp_bg.position, Vector2(hp_bg.size.x * hp_ratio, hp_bg.size.y))
	draw_rect(hp_fill, get_hp_fill_color(), true)

	var title := display_name if not display_name.is_empty() else entity_id
	draw_string(
		ThemeDB.fallback_font,
		Vector2(8, 20),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		rect.size.x - 16,
		14,
		get_side_color()
	)
