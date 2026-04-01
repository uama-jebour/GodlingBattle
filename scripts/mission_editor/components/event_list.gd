class_name EventList
extends VBoxContainer

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")

signal events_changed(events: Array[Dictionary])

var _events: Array[Dictionary] = []
var _event_rows: Array[HBoxContainer] = []

@onready var events_container: VBoxContainer = $EventsContainer
@onready var add_button: Button = $AddButton


func _ready() -> void:
	if add_button:
		add_button.pressed.connect(_on_add_pressed)
	# Rebuild UI with any events set before _ready
	if _events.size() > 0:
		_rebuild_ui()


func set_events(events: Array[Dictionary]) -> void:
	_events = events.duplicate(true)
	if is_inside_tree():
		_rebuild_ui()


func get_events() -> Array[Dictionary]:
	# If UI is built, get from UI; otherwise return stored events
	if _event_rows.size() > 0 and is_inside_tree():
		var result: Array[Dictionary] = []
		var presets := MISSION_DATA.TRIGGER_PRESETS.keys()
		for row in _event_rows:
			if row.get_child_count() < 2:
				continue
			var trigger_select := row.get_child(0) as OptionButton
			var anchor_select := row.get_child(1) as OptionButton
			result.append({
				"event_id": "evt_custom",
				"trigger_preset": presets[trigger_select.selected] if trigger_select.selected >= 0 else "elapsed_15",
				"spawn_anchor": MISSION_DATA.SPAWN_ANCHORS[anchor_select.selected] if anchor_select.selected >= 0 else "right_flank"
			})
		return result
	return _events.duplicate(true)


func _rebuild_ui() -> void:
	if events_container == null:
		return

	for child in events_container.get_children():
		child.queue_free()
	_event_rows.clear()

	for evt in _events:
		_add_event_row(evt.get("trigger_preset", "elapsed_15"), evt.get("spawn_anchor", "right_flank"))


func _add_event_row(trigger_preset: String, spawn_anchor: String) -> void:
	if events_container == null:
		return

	var presets := MISSION_DATA.TRIGGER_PRESETS.keys()

	var hbox := HBoxContainer.new()

	var trigger_select := OptionButton.new()
	for preset in presets:
		trigger_select.add_item(preset)
	var trigger_idx := presets.find(trigger_preset)
	if trigger_idx >= 0:
		trigger_select.selected = trigger_idx
	trigger_select.item_selected.connect(_on_selection_changed)

	var anchor_select := OptionButton.new()
	for anchor in MISSION_DATA.SPAWN_ANCHORS:
		anchor_select.add_item(anchor)
	var anchor_idx := MISSION_DATA.SPAWN_ANCHORS.find(spawn_anchor)
	if anchor_idx >= 0:
		anchor_select.selected = anchor_idx
	anchor_select.item_selected.connect(_on_selection_changed)

	var del_btn := Button.new()
	del_btn.text = "×"
	del_btn.custom_minimum_size.x = 30
	del_btn.pressed.connect(_delete_row.bind(hbox))

	hbox.add_child(trigger_select)
	hbox.add_child(anchor_select)
	hbox.add_child(del_btn)

	events_container.add_child(hbox)
	_event_rows.append(hbox)


func _on_add_pressed() -> void:
	_add_event_row("elapsed_15", "right_flank")
	_emit_changed()


func _on_selection_changed(_index: int) -> void:
	_emit_changed()


func _delete_row(hbox: HBoxContainer) -> void:
	var index := _event_rows.find(hbox)
	if index >= 0:
		_event_rows.remove_at(index)
	hbox.queue_free()
	_emit_changed()


func _emit_changed() -> void:
	events_changed.emit(get_events())
