extends Control

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")
const BATTLE_CONTENT := preload("res://autoload/battle_content.gd")

var _current_data: MissionData
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
	up_btn.pressed.connect(_make_move_line_callback(editors_ref, editors_ref.size(), -1))

	var down_btn := Button.new()
	down_btn.text = "↓"
	down_btn.custom_minimum_size.x = 30
	down_btn.pressed.connect(_make_move_line_callback(editors_ref, editors_ref.size(), 1))

	var del_btn := Button.new()
	del_btn.text = "×"
	del_btn.custom_minimum_size.x = 30
	del_btn.pressed.connect(_make_delete_line_callback(container, hbox, editors_ref, editors_ref.size()))

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


func _make_move_line_callback(editors_ref: Array, index: int, direction: int) -> Callable:
	return func():
		var new_idx := index + direction
		if new_idx < 0 or new_idx >= editors_ref.size():
			return
		var temp = editors_ref[index]
		editors_ref[index] = editors_ref[new_idx]
		editors_ref[new_idx] = temp


func _make_delete_line_callback(container: VBoxContainer, hbox: HBoxContainer, editors_ref: Array, index: int) -> Callable:
	return func():
		if index < editors_ref.size():
			editors_ref.remove_at(index)
		hbox.queue_free()


func _sync_plot_lines() -> void:
	_current_data.pre_battle_lines.clear()
	for edit in _pre_battle_line_editors:
		_current_data.pre_battle_lines.append(edit.text)

	_current_data.post_battle_lines.clear()
	for edit in _post_battle_line_editors:
		_current_data.post_battle_lines.append(edit.text)


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
	if res is MissionData:
		_current_data = res
		_is_new_mission = false
		_apply_data_to_ui()
	else:
		push_error("Failed to load mission: %s" % path)
