extends Control

const BATTLE_CONTENT := preload("res://autoload/battle_content.gd")
const DEFAULT_STRATEGY_BUDGET := 16
const DEFAULT_ALLY_IDS := ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"]
const DEFAULT_STRATEGY_SELECTED_COUNT := 4
const STRATEGY_CHECK_ICON_SIZE := 40

var _current_selection: Dictionary = {
	"hero_id": "hero_angel",
	"ally_ids": DEFAULT_ALLY_IDS.duplicate(),
	"strategy_ids": [],
	"battle_id": "battle_void_gate_alpha"
}
var _is_syncing_controls := false
var _strategy_checkboxes: Dictionary = {}

@onready var layout: VBoxContainer = $Layout
@onready var title_label: Label = $Layout/TitleLabel
@onready var hero_select: OptionButton = $Layout/HeroSelect
@onready var battle_select: OptionButton = $Layout/BattleSelect
@onready var strategy_list: VBoxContainer = $Layout/StrategyList
@onready var budget_label: Label = $Layout/BudgetLabel
@onready var selection_summary: Label = $Layout/SelectionSummary
@onready var battle_summary: Label = $Layout/BattleSummary
@onready var error_label: Label = $Layout/ErrorLabel
@onready var start_battle_button: Button = $Layout/StartBattleButton


func _ready() -> void:
	title_label.text = "出战前准备"
	_apply_control_visual_emphasis()
	_bind_content_options()
	_bind_control_events()
	_apply_selection_to_controls()
	if not start_battle_button.pressed.is_connected(_on_start_pressed):
		start_battle_button.pressed.connect(_on_start_pressed)
	_render_shell()


func set_selection(selection: Dictionary) -> void:
	_current_selection = selection.duplicate(true)
	if is_node_ready():
		_apply_selection_to_controls()
		_render_shell()


func _bind_content_options() -> void:
	var content: Node = BATTLE_CONTENT.new()
	hero_select.clear()
	var hero: Dictionary = content.get_unit("hero_angel")
	hero_select.add_item("英雄：%s" % String(hero.get("display_name", "天使")), 0)
	hero_select.set_item_metadata(0, "hero_angel")
	battle_select.clear()
	var battle: Dictionary = content.get_battle("battle_void_gate_alpha")
	battle_select.add_item("关卡：%s" % String(battle.get("display_name", "虚无裂隙·一层")), 0)
	battle_select.set_item_metadata(0, "battle_void_gate_alpha")
	_rebuild_strategy_options(content)
	_apply_default_strategy_selection_if_needed(content)
	content.free()


func _apply_default_strategy_selection_if_needed(content: Node) -> void:
	var selected_ids: Array[String] = []
	for strategy_id_raw in _current_selection.get("strategy_ids", []):
		var strategy_id := String(strategy_id_raw)
		if strategy_id.is_empty():
			continue
		if selected_ids.has(strategy_id):
			continue
		if content.get_strategy(strategy_id).is_empty():
			continue
		selected_ids.append(strategy_id)
	if selected_ids.is_empty():
		selected_ids = _default_strategy_ids(content)
	_current_selection["strategy_ids"] = selected_ids


func _default_strategy_ids(content: Node) -> Array[String]:
	var all_ids: Array[String] = content.get_all_strategy_ids()
	all_ids.sort()
	var defaults: Array[String] = []
	var limit := mini(DEFAULT_STRATEGY_SELECTED_COUNT, all_ids.size())
	for index in range(limit):
		defaults.append(all_ids[index])
	return defaults


func _bind_control_events() -> void:
	if not hero_select.item_selected.is_connected(_on_control_changed):
		hero_select.item_selected.connect(_on_control_changed)
	if not battle_select.item_selected.is_connected(_on_control_changed):
		battle_select.item_selected.connect(_on_control_changed)


func _apply_selection_to_controls() -> void:
	_is_syncing_controls = true
	_select_option_by_metadata(hero_select, String(_current_selection.get("hero_id", "")))
	_select_option_by_metadata(battle_select, String(_current_selection.get("battle_id", "")))
	var strategy_ids: Array = _current_selection.get("strategy_ids", [])
	for strategy_id in _strategy_checkboxes.keys():
		var checkbox := _strategy_checkboxes[strategy_id] as CheckBox
		if checkbox == null:
			continue
		checkbox.button_pressed = strategy_ids.has(strategy_id)
	_is_syncing_controls = false


func _pull_selection_from_controls() -> void:
	var strategy_ids: Array[String] = []
	for strategy_id in _sorted_strategy_checkbox_ids():
		var checkbox := _strategy_checkboxes.get(strategy_id, null) as CheckBox
		if checkbox == null:
			continue
		if checkbox.button_pressed:
			strategy_ids.append(strategy_id)
	var ally_ids: Array = _current_selection.get("ally_ids", [])
	if ally_ids.size() != DEFAULT_ALLY_IDS.size():
		ally_ids = DEFAULT_ALLY_IDS.duplicate()
	_current_selection = {
		"hero_id": _selected_metadata(hero_select, "hero_angel"),
		"ally_ids": ally_ids.duplicate(),
		"strategy_ids": strategy_ids,
		"battle_id": _selected_metadata(battle_select, "battle_void_gate_alpha")
	}


func _rebuild_strategy_options(content: Node) -> void:
	for child in strategy_list.get_children():
		child.queue_free()
	_strategy_checkboxes.clear()
	var strategy_ids: Array[String] = content.get_all_strategy_ids()
	for strategy_id in strategy_ids:
		var strategy: Dictionary = content.get_strategy(strategy_id)
		var checkbox := CheckBox.new()
		checkbox.name = "Strategy_%s" % strategy_id
		checkbox.text = "携带：%s（%d）" % [String(strategy.get("name", strategy_id)), int(strategy.get("cost", 0))]
		checkbox.custom_minimum_size = Vector2(0, 80)
		checkbox.add_theme_font_size_override("font_size", 40)
		var checked_icon := _build_strategy_checkbox_icon(true)
		var unchecked_icon := _build_strategy_checkbox_icon(false)
		checkbox.add_theme_icon_override("checked", checked_icon)
		checkbox.add_theme_icon_override("unchecked", unchecked_icon)
		checkbox.add_theme_icon_override("checked_disabled", checked_icon)
		checkbox.add_theme_icon_override("unchecked_disabled", unchecked_icon)
		checkbox.add_theme_stylebox_override("normal", _build_block_style(Color(0.16, 0.2, 0.3, 0.9), Color(0.48, 0.59, 0.78), 2))
		checkbox.add_theme_stylebox_override("hover", _build_block_style(Color(0.2, 0.26, 0.38, 0.95), Color(0.66, 0.79, 0.95), 2))
		checkbox.add_theme_stylebox_override("pressed", _build_block_style(Color(0.24, 0.33, 0.5, 0.98), Color(0.79, 0.89, 1.0), 2))
		checkbox.add_theme_stylebox_override("focus", _build_block_style(Color(0.21, 0.29, 0.46, 0.98), Color(0.95, 0.95, 0.95), 3))
		checkbox.add_theme_color_override("font_color", Color(0.97, 0.97, 0.95))
		checkbox.button_pressed = false
		checkbox.toggled.connect(_on_strategy_toggled)
		strategy_list.add_child(checkbox)
		_strategy_checkboxes[strategy_id] = checkbox


func _sorted_strategy_checkbox_ids() -> Array[String]:
	var strategy_ids: Array[String] = []
	for strategy_id in _strategy_checkboxes.keys():
		strategy_ids.append(String(strategy_id))
	strategy_ids.sort()
	return strategy_ids


func _select_option_by_metadata(option: OptionButton, value: String) -> void:
	for index in option.item_count:
		if String(option.get_item_metadata(index)) == value:
			option.select(index)
			return
	if option.item_count > 0:
		option.select(0)


func _selected_metadata(option: OptionButton, fallback: String) -> String:
	var selected_index := option.selected
	if selected_index < 0 or selected_index >= option.item_count:
		return fallback
	return String(option.get_item_metadata(selected_index))


func _on_control_changed(_index: int) -> void:
	if _is_syncing_controls:
		return
	_pull_selection_from_controls()
	_render_shell()


func _on_strategy_toggled(_enabled: bool) -> void:
	if _is_syncing_controls:
		return
	_pull_selection_from_controls()
	_render_shell()


func build_battle_setup(selection: Dictionary) -> Dictionary:
	var content: Node = BATTLE_CONTENT.new()
	var hero_id := String(selection.get("hero_id", ""))
	var ally_ids: Array = selection.get("ally_ids", [])
	var strategy_ids: Array = selection.get("strategy_ids", [])
	var battle_id := String(selection.get("battle_id", ""))
	if hero_id.is_empty() or content.get_unit(hero_id).is_empty():
		content.free()
		return {"invalid_reason": "missing_hero"}
	if ally_ids.size() != 3:
		content.free()
		return {"invalid_reason": "invalid_ally_count"}
	for ally_id in ally_ids:
		if content.get_unit(String(ally_id)).is_empty():
			content.free()
			return {"invalid_reason": "missing_ally"}
	for strategy_id in strategy_ids:
		if content.get_strategy(String(strategy_id)).is_empty():
			content.free()
			return {"invalid_reason": "missing_strategy"}
	if battle_id.is_empty() or content.get_battle(battle_id).is_empty():
		content.free()
		return {"invalid_reason": "missing_battle"}
	var total_cost := 0
	for strategy_id in strategy_ids:
		total_cost += int(content.get_strategy(String(strategy_id)).get("cost", 0))
	if total_cost > DEFAULT_STRATEGY_BUDGET:
		content.free()
		return {"invalid_reason": "strategy_budget_exceeded"}
	content.free()
	return {
		"hero_id": hero_id,
		"ally_ids": ally_ids.duplicate(),
		"strategy_ids": strategy_ids.duplicate(),
		"battle_id": battle_id,
		"seed": int(selection.get("seed", 0)),
		"randomized_spawn": bool(selection.get("randomized_spawn", false))
	}


func start_battle(selection: Dictionary) -> void:
	var seeded_selection := selection.duplicate(true)
	var explicit_seed := int(seeded_selection.get("seed", 0))
	var using_auto_seed := explicit_seed == 0
	seeded_selection["seed"] = explicit_seed if not using_auto_seed else _auto_battle_seed()
	seeded_selection["randomized_spawn"] = using_auto_seed
	var setup := build_battle_setup(seeded_selection)
	if setup.has("invalid_reason"):
		var invalid_reason := String(setup.get("invalid_reason", "unknown"))
		error_label.text = "无法开始出战: %s" % _describe_invalid_reason(invalid_reason)
		return
	error_label.text = ""
	var session_state := _session_state()
	if session_state != null:
		session_state.battle_setup = setup
	var app_router := _app_router()
	if app_router != null:
		app_router.goto_observe()


func _render_shell() -> void:
	var current_selection := _current_selection.duplicate(true)
	var setup := build_battle_setup(current_selection)
	budget_label.text = "预算: %d / %d" % [_strategy_total_cost(current_selection), DEFAULT_STRATEGY_BUDGET]
	if setup.has("invalid_reason"):
		budget_label.modulate = Color(0.96, 0.39, 0.33)
	else:
		budget_label.modulate = Color(0.95, 0.94, 0.88)
	selection_summary.text = _format_selection_summary(current_selection)
	if setup.has("invalid_reason"):
		var invalid_reason := _describe_invalid_reason(String(setup.get("invalid_reason", "")))
		battle_summary.text = "出战信息\n%s" % invalid_reason
		error_label.text = invalid_reason
		start_battle_button.disabled = true
		return
	battle_summary.text = _format_battle_summary(setup)
	error_label.text = ""
	start_battle_button.disabled = false


func _strategy_total_cost(selection: Dictionary) -> int:
	var content: Node = BATTLE_CONTENT.new()
	var total := 0
	for strategy_id in selection.get("strategy_ids", []):
		total += int(content.get_strategy(String(strategy_id)).get("cost", 0))
	content.free()
	return total


func _format_selection_summary(current_selection: Dictionary) -> String:
	var content: Node = BATTLE_CONTENT.new()
	var hero_name := _resolve_unit_name(content, String(current_selection.get("hero_id", "")))
	var ally_names := _resolve_unit_names(content, current_selection.get("ally_ids", []))
	var strategy_names := _resolve_strategy_names(content, current_selection.get("strategy_ids", []))
	var battle_name := _resolve_battle_name(content, String(current_selection.get("battle_id", "")))
	content.free()
	return "构筑信息\n英雄：%s\n友军：%s\n战技：%s\n关卡：%s" % [
		hero_name,
		_format_array(ally_names),
		_format_array(strategy_names),
		battle_name
	]


func _format_battle_summary(setup: Dictionary) -> String:
	var content: Node = BATTLE_CONTENT.new()
	var battle_name := _resolve_battle_name(content, String(setup.get("battle_id", "")))
	content.free()
	return "出战信息\n关卡：%s\n随机战局：每次开战自动生成" % battle_name


func _auto_battle_seed() -> int:
	var unix_seconds := int(Time.get_unix_time_from_system())
	var ticks_usec := int(Time.get_ticks_usec() & 0x7fffffff)
	return max(1, unix_seconds ^ ticks_usec)


func _resolve_unit_name(content: Node, unit_id: String) -> String:
	if unit_id.is_empty():
		return "未选择"
	var unit: Dictionary = content.get_unit(unit_id)
	if unit.is_empty():
		return unit_id
	return String(unit.get("display_name", unit_id))


func _resolve_unit_names(content: Node, unit_ids: Array) -> Array:
	var names: Array = []
	for unit_id in unit_ids:
		names.append(_resolve_unit_name(content, String(unit_id)))
	return names


func _resolve_strategy_name(content: Node, strategy_id: String) -> String:
	if strategy_id.is_empty():
		return "未选择"
	var strategy: Dictionary = content.get_strategy(strategy_id)
	if strategy.is_empty():
		return strategy_id
	return String(strategy.get("name", strategy_id))


func _resolve_strategy_names(content: Node, strategy_ids: Array) -> Array:
	var names: Array = []
	for strategy_id in strategy_ids:
		names.append(_resolve_strategy_name(content, String(strategy_id)))
	return names


func _resolve_battle_name(content: Node, battle_id: String) -> String:
	if battle_id.is_empty():
		return "未选择"
	var battle: Dictionary = content.get_battle(battle_id)
	if battle.is_empty():
		return battle_id
	return String(battle.get("display_name", battle_id))


func _apply_control_visual_emphasis() -> void:
	var normal_style := _build_block_style(Color(0.16, 0.2, 0.29, 0.95), Color(0.43, 0.52, 0.66), 2)
	var hover_style := _build_block_style(Color(0.2, 0.25, 0.37, 0.98), Color(0.58, 0.71, 0.9), 2)
	var press_style := _build_block_style(Color(0.24, 0.31, 0.45, 1.0), Color(0.78, 0.89, 1.0), 2)
	var focus_style := _build_block_style(Color(0.23, 0.31, 0.47, 1.0), Color(0.95, 0.95, 0.95), 3)

	_apply_option_button_style(hero_select, normal_style, hover_style, press_style, focus_style)
	_apply_option_button_style(battle_select, normal_style, hover_style, press_style, focus_style)

func _apply_option_button_style(option_button: OptionButton, normal_style: StyleBoxFlat, hover_style: StyleBoxFlat, press_style: StyleBoxFlat, focus_style: StyleBoxFlat) -> void:
	option_button.add_theme_font_size_override("font_size", 42)
	option_button.add_theme_color_override("font_color", Color(0.98, 0.98, 0.96))
	option_button.add_theme_stylebox_override("normal", normal_style.duplicate())
	option_button.add_theme_stylebox_override("hover", hover_style.duplicate())
	option_button.add_theme_stylebox_override("pressed", press_style.duplicate())
	option_button.add_theme_stylebox_override("focus", focus_style.duplicate())
	var popup := option_button.get_popup()
	if popup != null:
		popup.add_theme_font_size_override("font_size", 38)
		popup.add_theme_color_override("font_color", Color(0.98, 0.98, 0.96))
		popup.add_theme_stylebox_override("panel", _build_block_style(Color(0.13, 0.17, 0.24, 0.98), Color(0.62, 0.75, 0.95), 2))
		popup.add_theme_stylebox_override("hover", _build_block_style(Color(0.24, 0.32, 0.46, 1.0), Color(0.82, 0.9, 0.98), 1))
		popup.add_theme_stylebox_override("separator", _build_block_style(Color(0.35, 0.44, 0.57, 0.9), Color(0.35, 0.44, 0.57), 0))


func _build_block_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 16.0
	style.content_margin_top = 10.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 10.0
	return style


func _build_strategy_checkbox_icon(checked: bool) -> Texture2D:
	var image := Image.create(STRATEGY_CHECK_ICON_SIZE, STRATEGY_CHECK_ICON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var bg_color := Color(0.15, 0.18, 0.24, 1.0)
	if checked:
		bg_color = Color(0.22, 0.45, 0.78, 1.0)
	var border_color := Color(0.93, 0.95, 1.0, 1.0)
	for y in range(STRATEGY_CHECK_ICON_SIZE):
		for x in range(STRATEGY_CHECK_ICON_SIZE):
			var is_border := x < 3 or y < 3 or x >= STRATEGY_CHECK_ICON_SIZE - 3 or y >= STRATEGY_CHECK_ICON_SIZE - 3
			image.set_pixel(x, y, border_color if is_border else bg_color)
	if checked:
		var mark_color := Color(0.98, 0.99, 1.0, 1.0)
		for offset in range(10):
			_stamp_icon_pixel(image, 9 + offset, 20 + int(offset * 0.65), mark_color, 2)
		for offset in range(17):
			_stamp_icon_pixel(image, 18 + offset, 26 - int(offset * 0.82), mark_color, 2)
	return ImageTexture.create_from_image(image)


func _stamp_icon_pixel(image: Image, x: int, y: int, color: Color, radius: int) -> void:
	for py in range(-radius, radius + 1):
		for px in range(-radius, radius + 1):
			var xx := x + px
			var yy := y + py
			if xx < 0 or yy < 0 or xx >= STRATEGY_CHECK_ICON_SIZE or yy >= STRATEGY_CHECK_ICON_SIZE:
				continue
			image.set_pixel(xx, yy, color)


func _format_array(values: Array) -> String:
	if values.is_empty():
		return "无"
	var text_values: PackedStringArray = []
	for value in values:
		text_values.append(String(value))
	return ", ".join(text_values)


func _format_value(value: Variant) -> String:
	var text := String(value)
	if text.is_empty():
		return "未选择"
	return text


func _describe_invalid_reason(invalid_reason: String) -> String:
	match invalid_reason:
		"missing_hero":
			return "请选择英雄"
		"invalid_ally_count":
			return "队友数量需要为 3"
		"missing_ally":
			return "存在无效队友"
		"missing_strategy":
			return "存在无效战技"
		"missing_battle":
			return "请选择关卡"
		"strategy_budget_exceeded":
			return "战技预算超出上限"
		_:
			return invalid_reason


func _on_start_pressed() -> void:
	start_battle(_current_selection)


func _session_state() -> Node:
	var root := _root_node()
	if root == null:
		return null
	return root.get_node_or_null("SessionState")


func _app_router() -> Node:
	var root := _root_node()
	if root == null:
		return null
	return root.get_node_or_null("AppRouter")


func _root_node() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return (main_loop as SceneTree).root
	return null
