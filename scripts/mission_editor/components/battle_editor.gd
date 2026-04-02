class_name BattleEditor
extends VBoxContainer

const BATTLE_CONTENT := preload("res://autoload/battle_content.gd")
const BattlefieldPreviewScene := preload("res://scenes/mission_editor/components/battlefield_preview.tscn")
const EventListScene := preload("res://scenes/mission_editor/components/event_list.tscn")
const EnemyDragItemScene := preload("res://scenes/mission_editor/components/enemy_drag_item.tscn")

signal config_changed(enemy_entries: Array[Dictionary], event_configs: Array[Dictionary])

var _enemy_entries: Array[Dictionary] = []
var _event_configs: Array[Dictionary] = []

@onready var enemy_list_container: VBoxContainer = $HBoxContainer/LeftPanel/EnemyListContainer
@onready var battlefield_preview: Control = $HBoxContainer/BattlefieldPreview
@onready var event_list: Control = $EventListSection/EventList


func _ready() -> void:
	_populate_enemy_list()
	_connect_signals()


func set_config(p_enemy_entries: Array[Dictionary], p_event_configs: Array[Dictionary]) -> void:
	_enemy_entries = p_enemy_entries.duplicate(true)
	_event_configs = p_event_configs.duplicate(true)

	if battlefield_preview and battlefield_preview.has_method("set_enemies"):
		battlefield_preview.set_enemies(_enemy_entries)
	if event_list and event_list.has_method("set_events"):
		event_list.set_events(_event_configs)


func get_config() -> Dictionary:
	var result_enemy: Array[Dictionary] = []
	if battlefield_preview and battlefield_preview.has_method("get_enemies"):
		result_enemy = battlefield_preview.get_enemies()
	var result_events: Array[Dictionary] = []
	if event_list and event_list.has_method("get_events"):
		result_events = event_list.get_events()
	return {
		"enemy_entries": result_enemy,
		"event_configs": result_events
	}


func _populate_enemy_list() -> void:
	if enemy_list_container == null:
		return

	for child in enemy_list_container.get_children():
		child.queue_free()

	var content := BATTLE_CONTENT.new()
	var enemy_ids := ["enemy_wandering_demon", "enemy_animated_machine", "enemy_hunter_fiend"]

	for enemy_id in enemy_ids:
		var enemy: Dictionary = content.get_unit(enemy_id)
		if enemy.is_empty():
			continue

		var item: Control = EnemyDragItemScene.instantiate()
		if item.has_method("setup"):
			item.setup(enemy_id, enemy.get("display_name", enemy_id))
		enemy_list_container.add_child(item)

	content.free()


func _connect_signals() -> void:
	if battlefield_preview and battlefield_preview.has_signal("enemies_changed"):
		battlefield_preview.enemies_changed.connect(_on_enemies_changed)
	if event_list and event_list.has_signal("events_changed"):
		event_list.events_changed.connect(_on_events_changed)


func _on_enemies_changed(enemies: Array[Dictionary]) -> void:
	_enemy_entries = enemies
	_emit_changed()


func _on_events_changed(events: Array[Dictionary]) -> void:
	_event_configs = events
	_emit_changed()


func _emit_changed() -> void:
	config_changed.emit(_enemy_entries, _event_configs)
