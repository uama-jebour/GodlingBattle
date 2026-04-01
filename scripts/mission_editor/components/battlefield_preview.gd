class_name BattlefieldPreview
extends Control

const PLACED_ENEMY_ICON := preload("res://scenes/mission_editor/components/placed_enemy_icon.tscn")

signal enemies_changed(enemies: Array[Dictionary])

var _placed_enemies: Array[Dictionary] = []
var _anchor_positions: Dictionary = {}

@onready var preview_area: Control = $PreviewArea


func _ready() -> void:
	# Defer anchor calculation until after the node is in the tree
	call_deferred("_calculate_anchor_positions")


func _calculate_anchor_positions() -> void:
	if preview_area == null:
		return
	var rect := preview_area.get_rect()
	var w := rect.size.x
	var h := rect.size.y

	# Enemy spawn anchors (right side for enemies, left side for allies)
	_anchor_positions = {
		"right_flank": Vector2(w * 0.85, h * 0.5),
		"right_top": Vector2(w * 0.85, h * 0.25),
		"right_bottom": Vector2(w * 0.85, h * 0.75),
		"left_flank": Vector2(w * 0.15, h * 0.5),
		"left_top": Vector2(w * 0.15, h * 0.25),
		"left_bottom": Vector2(w * 0.15, h * 0.75)
	}

	# Rebuild icons after calculating positions
	_rebuild_icons()


func set_enemies(enemies: Array[Dictionary]) -> void:
	_placed_enemies = enemies.duplicate(true)
	if is_inside_tree():
		_rebuild_icons()


func get_enemies() -> Array[Dictionary]:
	return _placed_enemies.duplicate(true)


func _rebuild_icons() -> void:
	if preview_area == null:
		return

	for child in preview_area.get_children():
		if child is PlacedEnemyIcon:
			child.queue_free()

	for enemy in _placed_enemies:
		_create_icon(enemy)


func _create_icon(enemy: Dictionary) -> void:
	if preview_area == null:
		return

	var icon: PlacedEnemyIcon = PLACED_ENEMY_ICON.instantiate()
	var unit_id: String = enemy.get("unit_id", "")
	var spawn_anchor: String = enemy.get("spawn_anchor", "right_flank")
	var display_name: String = enemy.get("display_name", unit_id)
	icon.setup(unit_id, spawn_anchor, display_name)
	icon.delete_requested.connect(_on_delete_requested)

	var anchor: String = enemy.get("spawn_anchor", "right_flank")
	var pos: Vector2 = _anchor_positions.get(anchor, Vector2(100, 100))
	icon.position = pos - Vector2(30, 30)

	preview_area.add_child(icon)


func _on_delete_requested(icon: PlacedEnemyIcon) -> void:
	var index := -1
	for i in range(_placed_enemies.size()):
		if _placed_enemies[i].get("unit_id") == icon.unit_id and _placed_enemies[i].get("spawn_anchor") == icon.spawn_anchor:
			index = i
			break
	if index >= 0:
		_placed_enemies.remove_at(index)
		icon.queue_free()
		_emit_changed()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("unit_id")


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return

	var p_unit_id: String = data.get("unit_id", "")
	var p_display_name: String = data.get("display_name", p_unit_id)

	if p_unit_id.is_empty():
		return

	var anchor := _find_nearest_anchor(at_position)
	_placed_enemies.append({
		"unit_id": p_unit_id,
		"spawn_anchor": anchor,
		"display_name": p_display_name
	})
	_create_icon(_placed_enemies.back())
	_emit_changed()


func _find_nearest_anchor(pos: Vector2) -> String:
	var nearest: String = "right_flank"
	var min_dist: float = 999999.0

	for anchor in _anchor_positions.keys():
		var anchor_pos: Vector2 = _anchor_positions[anchor]
		var dist: float = pos.distance_to(anchor_pos)
		if dist < min_dist:
			min_dist = dist
			nearest = anchor

	return nearest


func _emit_changed() -> void:
	enemies_changed.emit(_placed_enemies.duplicate(true))
