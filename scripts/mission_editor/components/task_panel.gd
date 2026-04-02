class_name TaskPanel
extends VBoxContainer

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")

signal data_changed(field: String, value: Variant)

@onready var mission_name_edit: LineEdit = $MissionNameRow/MissionNameEdit
@onready var mission_type_select: OptionButton = $MissionTypeRow/MissionTypeSelect
@onready var briefing_edit: TextEdit = $BriefingEdit
@onready var hint_edit: TextEdit = $HintEdit
@onready var reward_editor: VBoxContainer = $RewardSection/RewardEditor


func _ready() -> void:
	_populate_type_select()
	_connect_signals()


func _populate_type_select() -> void:
	if mission_type_select == null:
		return
	mission_type_select.clear()
	for mtype in MISSION_DATA.MISSION_TYPES:
		mission_type_select.add_item(mtype)


func set_data(data: MISSION_DATA) -> void:
	if mission_name_edit:
		mission_name_edit.text = data.mission_name
	if mission_type_select:
		var idx := MISSION_DATA.MISSION_TYPES.find(data.mission_type)
		if idx >= 0:
			mission_type_select.selected = idx
	if briefing_edit:
		briefing_edit.text = data.briefing
	if hint_edit:
		hint_edit.text = data.hint
	if reward_editor and reward_editor.has_method("set_rewards"):
		reward_editor.set_rewards(data.rewards)


func apply_to_data(data: MISSION_DATA) -> void:
	if mission_name_edit:
		data.mission_name = mission_name_edit.text
	if mission_type_select and mission_type_select.selected >= 0:
		data.mission_type = MISSION_DATA.MISSION_TYPES[mission_type_select.selected]
	if briefing_edit:
		data.briefing = briefing_edit.text
	if hint_edit:
		data.hint = hint_edit.text
	if reward_editor:
		data.rewards = reward_editor.get_rewards()


func _connect_signals() -> void:
	if mission_name_edit:
		mission_name_edit.text_changed.connect(_on_name_changed)
	if mission_type_select:
		mission_type_select.item_selected.connect(_on_type_selected)
	if briefing_edit:
		briefing_edit.text_changed.connect(_on_briefing_changed)
	if hint_edit:
		hint_edit.text_changed.connect(_on_hint_changed)


func _on_name_changed(new_text: String) -> void:
	data_changed.emit("mission_name", new_text)


func _on_type_selected(index: int) -> void:
	data_changed.emit("mission_type", MISSION_DATA.MISSION_TYPES[index])


func _on_briefing_changed() -> void:
	data_changed.emit("briefing", briefing_edit.text)


func _on_hint_changed() -> void:
	data_changed.emit("hint", hint_edit.text)
