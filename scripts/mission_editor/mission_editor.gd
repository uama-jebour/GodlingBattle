extends Control

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")
const TaskPanelScene := preload("res://scenes/mission_editor/components/task_panel.tscn")
const StoryEditorScene := preload("res://scenes/mission_editor/components/story_editor.tscn")
const BattleEditorScene := preload("res://scenes/mission_editor/components/battle_editor.tscn")

var _current_data: MISSION_DATA
var _is_new_mission: bool = true


func _ready() -> void:
	_connect_signals()
	_new_mission()


func _connect_signals() -> void:
	var pre_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PreBattleCheck")
	var battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/BattleCheck")
	var post_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PostBattleCheck")
	var save_button: Button = get_node_or_null("BottomBar/SaveButton")
	var new_button: Button = get_node_or_null("BottomBar/NewButton")
	var back_button: Button = get_node_or_null("BottomBar/BackButton")

	if pre_battle_check:
		pre_battle_check.toggled.connect(_on_pre_battle_toggled)
	if battle_check:
		battle_check.toggled.connect(_on_battle_toggled)
	if post_battle_check:
		post_battle_check.toggled.connect(_on_post_battle_toggled)
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if new_button:
		new_button.pressed.connect(_on_new_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)


func _new_mission() -> void:
	_current_data = MISSION_DATA.new()
	_current_data.new_mission()
	_is_new_mission = true
	_apply_data_to_ui()


func _apply_data_to_ui() -> void:
	var task_panel: Control = get_node_or_null("ScrollContainer/VBoxContainer/TaskPanel")
	var pre_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PreBattleCheck")
	var battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/BattleCheck")
	var post_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PostBattleCheck")
	var pre_battle_editor: Control = get_node_or_null("ScrollContainer/VBoxContainer/PreBattleSection/PreBattleEditor")
	var post_battle_editor: Control = get_node_or_null("ScrollContainer/VBoxContainer/PostBattleSection/PostBattleEditor")
	var battle_editor: Control = get_node_or_null("ScrollContainer/VBoxContainer/BattleSection/BattleEditor")

	if task_panel and task_panel.has_method("set_data"):
		task_panel.set_data(_current_data)

	if pre_battle_check:
		pre_battle_check.button_pressed = _current_data.has_pre_battle
	if battle_check:
		battle_check.button_pressed = _current_data.has_battle
	if post_battle_check:
		post_battle_check.button_pressed = _current_data.has_post_battle

	if pre_battle_editor and pre_battle_editor.has_method("set_lines"):
		pre_battle_editor.set_lines(_current_data.pre_battle_lines)
	if post_battle_editor and post_battle_editor.has_method("set_lines"):
		post_battle_editor.set_lines(_current_data.post_battle_lines)
	if battle_editor and battle_editor.has_method("set_config"):
		battle_editor.set_config(_current_data.enemy_entries, _current_data.event_configs)

	_update_section_visibility()


func _update_section_visibility() -> void:
	var pre_battle_section: VBoxContainer = get_node_or_null("ScrollContainer/VBoxContainer/PreBattleSection")
	var battle_section: VBoxContainer = get_node_or_null("ScrollContainer/VBoxContainer/BattleSection")
	var post_battle_section: VBoxContainer = get_node_or_null("ScrollContainer/VBoxContainer/PostBattleSection")
	var pre_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PreBattleCheck")
	var battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/BattleCheck")
	var post_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PostBattleCheck")

	if pre_battle_section:
		pre_battle_section.visible = pre_battle_check.button_pressed if pre_battle_check else false
	if battle_section:
		battle_section.visible = battle_check.button_pressed if battle_check else false
	if post_battle_section:
		post_battle_section.visible = post_battle_check.button_pressed if post_battle_check else false


func _on_pre_battle_toggled(pressed: bool) -> void:
	var pre_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PreBattleCheck")
	if pressed and not _can_enable_story(pre_battle_check):
		if pre_battle_check:
			pre_battle_check.button_pressed = false
		return
	_current_data.has_pre_battle = pressed
	_update_section_visibility()


func _on_battle_toggled(pressed: bool) -> void:
	var pre_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PreBattleCheck")
	var post_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PostBattleCheck")

	if not pressed:
		if pre_battle_check:
			pre_battle_check.button_pressed = false
		if post_battle_check:
			post_battle_check.button_pressed = false
		_current_data.has_pre_battle = false
		_current_data.has_post_battle = false
	_current_data.has_battle = pressed
	_update_section_visibility()


func _on_post_battle_toggled(pressed: bool) -> void:
	var post_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PostBattleCheck")
	if pressed and not _can_enable_story(post_battle_check):
		if post_battle_check:
			post_battle_check.button_pressed = false
		return
	_current_data.has_post_battle = pressed
	_update_section_visibility()


func _can_enable_story(check_box: CheckBox) -> bool:
	var battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/BattleCheck")
	var pre_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PreBattleCheck")
	var post_battle_check: CheckBox = get_node_or_null("ScrollContainer/VBoxContainer/ModuleControls/PostBattleCheck")

	if battle_check and not battle_check.button_pressed:
		if check_box == pre_battle_check and post_battle_check and post_battle_check.button_pressed:
			return false
		if check_box == post_battle_check and pre_battle_check and pre_battle_check.button_pressed:
			return false
	return true


func _on_save_pressed() -> void:
	_sync_ui_to_data()

	if not _current_data.is_valid():
		push_error("Mission data is invalid")
		return

	var mkdir_err := DirAccess.make_dir_recursive_absolute("res://resources/missions/")
	if mkdir_err != OK:
		push_error("Failed to create directory: %s" % mkdir_err)
		return

	var path := "res://resources/missions/%s.tres" % _current_data.mission_id
	var err := ResourceSaver.save(_current_data, path)
	if err != OK:
		push_error("Failed to save mission: %s" % err)
		return

	print("Saved mission to: %s" % path)
	_is_new_mission = false


func _sync_ui_to_data() -> void:
	var task_panel: Control = get_node_or_null("ScrollContainer/VBoxContainer/TaskPanel")
	var pre_battle_editor: Control = get_node_or_null("ScrollContainer/VBoxContainer/PreBattleSection/PreBattleEditor")
	var post_battle_editor: Control = get_node_or_null("ScrollContainer/VBoxContainer/PostBattleSection/PostBattleEditor")
	var battle_editor: Control = get_node_or_null("ScrollContainer/VBoxContainer/BattleSection/BattleEditor")

	if task_panel and task_panel.has_method("apply_to_data"):
		task_panel.apply_to_data(_current_data)

	if pre_battle_editor and pre_battle_editor.has_method("get_lines"):
		_current_data.pre_battle_lines = pre_battle_editor.get_lines()
	if post_battle_editor and post_battle_editor.has_method("get_lines"):
		_current_data.post_battle_lines = post_battle_editor.get_lines()

	if battle_editor and battle_editor.has_method("get_config"):
		var config: Dictionary = battle_editor.get_config()
		_current_data.enemy_entries = config.get("enemy_entries", [])
		_current_data.event_configs = config.get("event_configs", [])


func _on_new_pressed() -> void:
	_new_mission()


func _on_back_pressed() -> void:
	var router := get_node_or_null("/root/AppRouter")
	if router:
		router.goto_preparation()


func load_mission(mission_id: String) -> void:
	var path := "res://resources/missions/%s.tres" % mission_id
	var res := load(path)
	if res != null and res is MISSION_DATA:
		_current_data = res
		_is_new_mission = false
		_apply_data_to_ui()
	else:
		push_error("Failed to load mission: %s" % path)
