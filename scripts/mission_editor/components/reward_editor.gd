class_name RewardEditor
extends VBoxContainer

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")

signal rewards_changed(rewards: Array[Dictionary])

var _rewards: Array[Dictionary] = []
var _reward_rows: Array[HBoxContainer] = []

@onready var rewards_container: VBoxContainer = $RewardsContainer
@onready var add_button: Button = $AddButton


func _ready() -> void:
	if add_button:
		add_button.pressed.connect(_on_add_pressed)
	# Rebuild UI with any rewards set before _ready
	if _rewards.size() > 0:
		_rebuild_ui()


func set_rewards(rewards: Array[Dictionary]) -> void:
	_rewards = rewards.duplicate(true)
	if is_inside_tree():
		_rebuild_ui()


func get_rewards() -> Array[Dictionary]:
	# If UI is built, get from UI; otherwise return stored rewards
	if _reward_rows.size() > 0 and is_inside_tree():
		var result: Array[Dictionary] = []
		for row in _reward_rows:
			if row.get_child_count() < 2:
				continue
			var type_select := row.get_child(0) as OptionButton
			var value_edit := row.get_child(1) as LineEdit
			result.append({
				"type": MISSION_DATA.REWARD_TYPES[type_select.selected] if type_select.selected >= 0 else "金币",
				"value": value_edit.text.to_int() if value_edit.text.is_valid_int() else 0
			})
		return result
	return _rewards.duplicate(true)


func _rebuild_ui() -> void:
	if rewards_container == null:
		return

	for child in rewards_container.get_children():
		child.queue_free()
	_reward_rows.clear()

	for reward in _rewards:
		_add_reward_row(reward.get("type", "金币"), reward.get("value", 0))


func _add_reward_row(reward_type: String, value: int) -> void:
	if rewards_container == null:
		return

	var hbox := HBoxContainer.new()

	var type_select := OptionButton.new()
	for rtype in MISSION_DATA.REWARD_TYPES:
		type_select.add_item(rtype)
	var type_idx := MISSION_DATA.REWARD_TYPES.find(reward_type)
	if type_idx >= 0:
		type_select.selected = type_idx
	type_select.item_selected.connect(_on_type_selected)

	var value_edit := LineEdit.new()
	value_edit.text = str(value)
	value_edit.custom_minimum_size.x = 80
	value_edit.text_changed.connect(_on_value_changed)

	var del_btn := Button.new()
	del_btn.text = "×"
	del_btn.custom_minimum_size.x = 30
	del_btn.pressed.connect(_delete_row.bind(hbox))

	hbox.add_child(type_select)
	hbox.add_child(value_edit)
	hbox.add_child(del_btn)

	rewards_container.add_child(hbox)
	_reward_rows.append(hbox)


func _on_add_pressed() -> void:
	_add_reward_row("金币", 0)
	_emit_changed()


func _on_type_selected(_index: int) -> void:
	_emit_changed()


func _on_value_changed(_new_text: String) -> void:
	_emit_changed()


func _delete_row(hbox: HBoxContainer) -> void:
	var index := _reward_rows.find(hbox)
	if index >= 0:
		_reward_rows.remove_at(index)
	hbox.queue_free()
	_emit_changed()


func _emit_changed() -> void:
	rewards_changed.emit(get_rewards())
