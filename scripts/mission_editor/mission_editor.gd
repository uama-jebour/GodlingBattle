extends Control

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")
const BATTLE_CONTENT := preload("res://autoload/battle_content.gd")

var _current_data
var _is_new_mission: bool = true

@onready var tab_container: TabContainer = $TabContainer
@onready var save_button: Button = $BottomBar/SaveButton
@onready var new_button: Button = $BottomBar/NewButton
@onready var back_button: Button = $BottomBar/BackButton

# Tab nodes (placeholders - actual nodes added in Task 8)
@onready var pre_battle_tab: Control = $TabContainer/PreBattleTab
@onready var battle_tab: Control = $TabContainer/BattleTab
@onready var post_battle_tab: Control = $TabContainer/PostBattleTab
@onready var mission_panel_tab: Control = $TabContainer/MissionPanelTab

# Mission Panel nodes (placeholders)
@onready var mission_name_edit: LineEdit = $TabContainer/MissionPanelTab/MissionNameEdit
@onready var mission_type_select: OptionButton = $TabContainer/MissionPanelTab/MissionTypeSelect
@onready var briefing_edit: TextEdit = $TabContainer/MissionPanelTab/BriefingEdit
@onready var hint_edit: TextEdit = $TabContainer/MissionPanelTab/HintEdit

# Plot line editors
@onready var pre_battle_lines_container: VBoxContainer = $TabContainer/PreBattleTab/LinesContainer
@onready var post_battle_lines_container: VBoxContainer = $TabContainer/PostBattleTab/LinesContainer

var _pre_battle_line_editors: Array[LineEdit] = []
var _post_battle_line_editors: Array[LineEdit] = []

# Rewards
@onready var rewards_container: VBoxContainer = $TabContainer/MissionPanelTab/RewardsContainer
@onready var add_reward_btn: Button = $TabContainer/MissionPanelTab/AddRewardButton

var _reward_editors: Array[HBoxContainer] = []

# Battle tab
@onready var enemy_list_container: VBoxContainer = $TabContainer/BattleTab/EnemyListContainer
@onready var battlefield_container: Control = $TabContainer/BattleTab/BattlefieldContainer
@onready var event_list_container: VBoxContainer = $TabContainer/BattleTab/EventListContainer

var _placed_enemies: Array[Dictionary] = []


func _ready() -> void:
	_bind_signals()
	_new_mission()


func _bind_signals() -> void:
	if save_button and not save_button.pressed.is_connected(_on_save_pressed):
		save_button.pressed.connect(_on_save_pressed)
	if new_button and not new_button.pressed.is_connected(_on_new_pressed):
		new_button.pressed.connect(_on_new_pressed)
	if back_button and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if mission_type_select and not mission_type_select.item_selected.is_connected(_on_mission_type_selected):
		mission_type_select.item_selected.connect(_on_mission_type_selected)
	if mission_name_edit and not mission_name_edit.text_changed.is_connected(_on_mission_name_changed):
		mission_name_edit.text_changed.connect(_on_mission_name_changed)


func _new_mission() -> void:
	_current_data = MISSION_DATA.new()
	_current_data.new_mission()
	_is_new_mission = true
	_apply_data_to_ui()


func _apply_data_to_ui() -> void:
	if mission_name_edit:
		mission_name_edit.text = _current_data.mission_name
	if mission_type_select:
		mission_type_select.clear()
		for mt in MISSION_DATA.MISSION_TYPES:
			mission_type_select.add_item(mt)
		var type_idx := MISSION_DATA.MISSION_TYPES.find(_current_data.mission_type)
		if type_idx >= 0:
			mission_type_select.selected = type_idx
	if briefing_edit:
		briefing_edit.text = _current_data.briefing
	if hint_edit:
		hint_edit.text = _current_data.hint
	# 剧情行
	_init_plot_tab(pre_battle_tab, _current_data.pre_battle_lines, _pre_battle_line_editors)
	_init_plot_tab(post_battle_tab, _current_data.post_battle_lines, _post_battle_line_editors)
	# 战斗配置
	_init_battle_tab()
	# 收益配置
	_init_rewards_section()


func _on_save_pressed() -> void:
	_pull_ui_to_data()
	if not _current_data.is_valid():
		push_error("Mission data is invalid")
		return

	var mkdir_err := DirAccess.make_dir_recursive_absolute("res://resources/missions/")
	if mkdir_err != OK:
		push_error("Failed to create directory: %s" % mkdir_err)
		return

	var dir := DirAccess.open("res://resources/missions/")
	if dir == null:
		push_error("Failed to open missions directory")
		return

	var path := "res://resources/missions/%s.tres" % _current_data.mission_id
	var err := ResourceSaver.save(_current_data, path)
	if err != OK:
		push_error("Failed to save mission: %s" % err)
		return

	print("Saved mission to: %s" % path)
	_is_new_mission = false


func _pull_ui_to_data() -> void:
	if mission_name_edit:
		_current_data.mission_name = mission_name_edit.text
	if mission_type_select and mission_type_select.selected >= 0:
		_current_data.mission_type = MISSION_DATA.MISSION_TYPES[mission_type_select.selected]
	if briefing_edit:
		_current_data.briefing = briefing_edit.text
	if hint_edit:
		_current_data.hint = hint_edit.text
	_sync_plot_lines()
	_sync_rewards_config()


# ========== 剧情行编辑器 ==========

func _init_plot_tab(tab: Control, lines: Array[String], editors_ref: Array) -> void:
	var container: VBoxContainer = tab.get_node_or_null("LinesContainer")
	if container == null:
		return

	for child in container.get_children():
		child.queue_free()
	editors_ref.clear()

	for i in range(lines.size()):
		_add_plot_line(container, lines[i], editors_ref)

	var add_btn := Button.new()
	add_btn.text = "+ 添加行"
	add_btn.pressed.connect(_make_add_line_callback(container, editors_ref))
	container.add_child(add_btn)


func _add_plot_line(container: VBoxContainer, text: String, editors_ref: Array) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var line_num := Label.new()
	line_num.text = "%d." % (editors_ref.size() + 1)
	line_num.custom_minimum_size.x = 30

	var edit := LineEdit.new()
	edit.text = text
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var up_btn := Button.new()
	up_btn.text = "↑"
	up_btn.custom_minimum_size.x = 30
	up_btn.pressed.connect(_make_move_line_callback(container, editors_ref, edit, -1))

	var down_btn := Button.new()
	down_btn.text = "↓"
	down_btn.custom_minimum_size.x = 30
	down_btn.pressed.connect(_make_move_line_callback(container, editors_ref, edit, 1))

	var del_btn := Button.new()
	del_btn.text = "×"
	del_btn.custom_minimum_size.x = 30
	del_btn.pressed.connect(_make_delete_line_callback(container, hbox, editors_ref, edit))

	hbox.add_child(line_num)
	hbox.add_child(edit)
	hbox.add_child(up_btn)
	hbox.add_child(down_btn)
	hbox.add_child(del_btn)

	container.add_child(hbox)
	editors_ref.append(edit)


func _make_add_line_callback(container: VBoxContainer, editors_ref: Array) -> Callable:
	return func():
		_add_plot_line(container, "", editors_ref)


func _make_move_line_callback(container: VBoxContainer, editors_ref: Array, edit: LineEdit, direction: int) -> Callable:
	return func():
		var index := editors_ref.find(edit)
		if index < 0:
			return
		var new_idx := index + direction
		if new_idx < 0 or new_idx >= editors_ref.size():
			return

		# Swap in array
		var temp = editors_ref[index]
		editors_ref[index] = editors_ref[new_idx]
		editors_ref[new_idx] = temp

		# Reorder container children
		var hbox := edit.get_parent() as HBoxContainer
		if hbox:
			container.move_child(hbox, new_idx)

		# Update all line numbers
		_refresh_line_numbers(container, editors_ref)


func _make_delete_line_callback(container: VBoxContainer, hbox: HBoxContainer, editors_ref: Array, edit: LineEdit) -> Callable:
	return func():
		var index := editors_ref.find(edit)
		if index >= 0:
			editors_ref.remove_at(index)
		hbox.queue_free()
		_refresh_line_numbers(container, editors_ref)


func _refresh_line_numbers(container: VBoxContainer, editors_ref: Array) -> void:
	var line_num := 1
	for edit in editors_ref:
		var hbox := edit.get_parent() as HBoxContainer
		if hbox and hbox.get_child_count() > 0:
			var label := hbox.get_child(0) as Label
			if label:
				label.text = "%d." % line_num
		line_num += 1


func _sync_plot_lines() -> void:
	_current_data.pre_battle_lines.clear()
	for edit in _pre_battle_line_editors:
		_current_data.pre_battle_lines.append(edit.text)

	_current_data.post_battle_lines.clear()
	for edit in _post_battle_line_editors:
		_current_data.post_battle_lines.append(edit.text)


# ========== 战斗配置 ==========

func _init_battle_tab() -> void:
	_populate_enemy_list()
	_init_battlefield()
	_init_event_list()


func _populate_enemy_list() -> void:
	if enemy_list_container == null:
		return

	for child in enemy_list_container.get_children():
		child.queue_free()

	# Known enemy unit IDs (MVP - hardcoded from battle_content.gd)
	var enemy_ids := ["enemy_wandering_demon", "enemy_animated_machine", "enemy_hunter_fiend"]

	for enemy_id in enemy_ids:
		var content := BATTLE_CONTENT.new()
		var enemy: Dictionary = content.get_unit(enemy_id)
		content.free()
		if enemy.is_empty():
			continue

		var hbox := HBoxContainer.new()

		var label := Label.new()
		label.text = "%s (%s)" % [enemy.get("display_name", enemy_id), enemy.get("attack_mode", "melee")]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size.x = 30
		add_btn.pressed.connect(_make_add_enemy_callback(enemy_id))

		hbox.add_child(label)
		hbox.add_child(add_btn)
		enemy_list_container.add_child(hbox)


func _make_add_enemy_callback(enemy_id: String) -> Callable:
	return func():
		if _current_data == null:
			return
		_current_data.add_enemy_entry(enemy_id, "right_flank")
		_refresh_placed_enemies()


func _init_battlefield() -> void:
	_placed_enemies.clear()
	if battlefield_container:
		_refresh_placed_enemies()


func _init_event_list() -> void:
	if event_list_container == null:
		return

	for child in event_list_container.get_children():
		child.queue_free()

	var add_btn := Button.new()
	add_btn.text = "+ 添加事件"
	add_btn.pressed.connect(_on_add_event)
	event_list_container.add_child(add_btn)

	if _current_data:
		for i in range(_current_data.event_configs.size()):
			_add_event_entry(i)


func _add_event_entry(config_index: int) -> void:
	if _current_data == null or event_list_container == null:
		return

	var config: Dictionary = _current_data.event_configs[config_index]

	var hbox := HBoxContainer.new()

	# Trigger preset dropdown
	var trigger_select := OptionButton.new()
	var presets := MISSION_DATA.TRIGGER_PRESETS.keys()
	for preset in presets:
		trigger_select.add_item(preset)
	var current_preset: String = config.get("trigger_preset", "elapsed_15")
	var idx := presets.find(current_preset)
	if idx >= 0:
		trigger_select.selected = idx
	trigger_select.item_selected.connect(_make_event_trigger_callback(config_index))

	# Spawn anchor dropdown
	var anchor_select := OptionButton.new()
	for anchor in MISSION_DATA.SPAWN_ANCHORS:
		anchor_select.add_item(anchor)
	var current_anchor: String = config.get("spawn_anchor", "right_flank")
	idx = MISSION_DATA.SPAWN_ANCHORS.find(current_anchor)
	if idx >= 0:
		anchor_select.selected = idx
	anchor_select.item_selected.connect(_make_event_anchor_callback(config_index))

	# Delete button
	var del_btn := Button.new()
	del_btn.text = "×"
	del_btn.custom_minimum_size.x = 30
	del_btn.pressed.connect(_make_delete_event_callback(config_index))

	hbox.add_child(trigger_select)
	hbox.add_child(anchor_select)
	hbox.add_child(del_btn)
	event_list_container.add_child(hbox)


func _make_event_trigger_callback(config_index: int) -> Callable:
	return func(index: int):
		if _current_data and config_index < _current_data.event_configs.size():
			var presets := MISSION_DATA.TRIGGER_PRESETS.keys()
			if index >= 0 and index < presets.size():
				_current_data.event_configs[config_index]["trigger_preset"] = presets[index]


func _make_event_anchor_callback(config_index: int) -> Callable:
	return func(index: int):
		if _current_data and config_index < _current_data.event_configs.size():
			if index >= 0 and index < MISSION_DATA.SPAWN_ANCHORS.size():
				_current_data.event_configs[config_index]["spawn_anchor"] = MISSION_DATA.SPAWN_ANCHORS[index]


func _make_delete_event_callback(config_index: int) -> Callable:
	return func():
		if _current_data:
			_current_data.remove_event_config(config_index)
			_init_event_list()


func _on_add_event() -> void:
	if _current_data:
		_current_data.add_event_config("evt_hunter_fiend_arrival", "elapsed_15", "right_flank")
		_init_event_list()


func _refresh_placed_enemies() -> void:
	# Placeholder - in full implementation would update battlefield visual
	# For now, just refresh the count display
	pass


func _sync_battle_config() -> void:
	# Battle config syncs through _current_data direct manipulation
	# No additional sync needed as edits go directly to _current_data
	pass


# ========== 收益配置 ==========

func _init_rewards_section() -> void:
	if rewards_container == null:
		return

	for child in rewards_container.get_children():
		child.queue_free()
	_reward_editors.clear()

	if _current_data:
		for i in range(_current_data.rewards.size()):
			_add_reward_entry(i)

	if add_reward_btn and not add_reward_btn.pressed.is_connected(_on_add_reward):
		add_reward_btn.pressed.connect(_on_add_reward)


func _add_reward_entry(reward_index: int) -> void:
	if _current_data == null or rewards_container == null:
		return

	var reward: Dictionary = _current_data.rewards[reward_index]

	var hbox := HBoxContainer.new()

	var type_select := OptionButton.new()
	for rtype in MISSION_DATA.REWARD_TYPES:
		type_select.add_item(rtype)
	var type_idx := MISSION_DATA.REWARD_TYPES.find(reward.get("type", "金币"))
	if type_idx >= 0:
		type_select.selected = type_idx
	type_select.item_selected.connect(_make_reward_type_callback(reward_index))

	var value_edit := LineEdit.new()
	value_edit.text = str(reward.get("value", 0))
	value_edit.custom_minimum_size.x = 80
	value_edit.text_changed.connect(_make_reward_value_callback(reward_index))

	var del_btn := Button.new()
	del_btn.text = "×"
	del_btn.custom_minimum_size.x = 30
	del_btn.pressed.connect(_make_delete_reward_callback(reward_index))

	hbox.add_child(type_select)
	hbox.add_child(value_edit)
	hbox.add_child(del_btn)

	rewards_container.add_child(hbox)
	_reward_editors.append(hbox)


func _make_reward_type_callback(reward_index: int) -> Callable:
	return func(index: int):
		if _current_data and reward_index < _current_data.rewards.size():
			if index >= 0 and index < MISSION_DATA.REWARD_TYPES.size():
				_current_data.rewards[reward_index]["type"] = MISSION_DATA.REWARD_TYPES[index]


func _make_reward_value_callback(reward_index: int) -> Callable:
	return func(new_text: String):
		if _current_data and reward_index < _current_data.rewards.size():
			var value := 0
			if new_text.is_valid_int():
				value = new_text.to_int()
			_current_data.rewards[reward_index]["value"] = value


func _make_delete_reward_callback(reward_index: int) -> Callable:
	return func():
		if _current_data:
			_current_data.remove_reward(reward_index)
			_init_rewards_section()


func _on_add_reward() -> void:
	if _current_data:
		_current_data.add_reward("金币", 0)
		_init_rewards_section()


func _sync_rewards_config() -> void:
	# Rewards are edited directly through _current_data.rewards
	# No additional sync needed
	pass


func _on_new_pressed() -> void:
	_new_mission()


func _on_back_pressed() -> void:
	var router := get_node_or_null("/root/AppRouter")
	if router:
		router.goto_preparation()


func _on_mission_type_selected(index: int) -> void:
	if _current_data and index >= 0:
		_current_data.mission_type = MISSION_DATA.MISSION_TYPES[index]


func _on_mission_name_changed(new_text: String) -> void:
	if _current_data:
		_current_data.mission_name = new_text


func load_mission(mission_id: String) -> void:
	var path := "res://resources/missions/%s.tres" % mission_id
	var res := load(path)
	if res != null and res.has_method("is_valid"):
		_current_data = res
		_is_new_mission = false
		_apply_data_to_ui()
	else:
		push_error("Failed to load mission: %s" % path)
