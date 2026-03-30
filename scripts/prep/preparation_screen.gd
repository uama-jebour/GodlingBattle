extends Control

const DEFAULT_STRATEGY_BUDGET := 16

var _current_selection: Dictionary = {
	"hero_id": "hero_angel",
	"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
	"strategy_ids": ["strat_void_echo"],
	"battle_id": "battle_void_gate_alpha",
	"seed": 1001
}

@onready var layout: VBoxContainer = $Layout
@onready var title_label: Label = $Layout/TitleLabel
@onready var selection_summary: Label = $Layout/SelectionSummary
@onready var battle_summary: Label = $Layout/BattleSummary
@onready var error_label: Label = $Layout/ErrorLabel
@onready var start_battle_button: Button = $Layout/StartBattleButton


func _ready() -> void:
	title_label.text = "出战前准备"
	if not start_battle_button.pressed.is_connected(_on_start_pressed):
		start_battle_button.pressed.connect(_on_start_pressed)
	_render_shell()


func set_selection(selection: Dictionary) -> void:
	_current_selection = selection.duplicate(true)
	if is_node_ready():
		_render_shell()


func build_battle_setup(selection: Dictionary) -> Dictionary:
	var hero_id := String(selection.get("hero_id", ""))
	var ally_ids: Array = selection.get("ally_ids", [])
	var strategy_ids: Array = selection.get("strategy_ids", [])
	var battle_id := String(selection.get("battle_id", ""))
	if hero_id.is_empty():
		return {"invalid_reason": "missing_hero"}
	if ally_ids.size() != 3:
		return {"invalid_reason": "invalid_ally_count"}
	if not _is_known_battle(battle_id):
		return {"invalid_reason": "missing_battle"}
	var total_cost := 0
	for strategy_id in strategy_ids:
		total_cost += _strategy_cost(String(strategy_id))
	if total_cost > DEFAULT_STRATEGY_BUDGET:
		return {"invalid_reason": "strategy_budget_exceeded"}
	return {
		"hero_id": hero_id,
		"ally_ids": ally_ids.duplicate(),
		"strategy_ids": strategy_ids.duplicate(),
		"battle_id": battle_id,
		"seed": int(selection.get("seed", 0))
	}


func start_battle(selection: Dictionary) -> void:
	var setup := build_battle_setup(selection)
	if setup.has("invalid_reason"):
		error_label.text = "无法开始出战: %s" % String(setup.get("invalid_reason", "unknown"))
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
	selection_summary.text = _format_selection_summary(current_selection)
	if setup.has("invalid_reason"):
		var invalid_reason := _describe_invalid_reason(String(setup.get("invalid_reason", "")))
		battle_summary.text = "战斗信息\n%s" % invalid_reason
		error_label.text = invalid_reason
		start_battle_button.disabled = true
		return
	battle_summary.text = _format_battle_summary(setup)
	error_label.text = ""
	start_battle_button.disabled = false


func _format_selection_summary(current_selection: Dictionary) -> String:
	var hero_id := _format_value(current_selection.get("hero_id", "未选择"))
	var ally_ids := _format_array(current_selection.get("ally_ids", []))
	var strategy_ids := _format_array(current_selection.get("strategy_ids", []))
	var battle_id := _format_value(current_selection.get("battle_id", "未选择"))
	return "英雄：%s\n队友：%s\n战技：%s\n关卡：%s" % [hero_id, ally_ids, strategy_ids, battle_id]


func _format_battle_summary(setup: Dictionary) -> String:
	var battle_id := _format_value(setup.get("battle_id", ""))
	var seed := int(setup.get("seed", 0))
	return "战斗准备完成\n关卡：%s\n种子：%d" % [battle_id, seed]


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
		"missing_battle":
			return "请选择关卡"
		"strategy_budget_exceeded":
			return "战技预算超出上限"
		_:
			return invalid_reason


func _on_start_pressed() -> void:
	start_battle(_current_selection)


func _session_state() -> Node:
	return get_node_or_null("/root/SessionState")


func _app_router() -> Node:
	return get_node_or_null("/root/AppRouter")


func _is_known_battle(battle_id: String) -> bool:
	return battle_id == "battle_void_gate_alpha"


func _strategy_cost(strategy_id: String) -> int:
	match strategy_id:
		"strat_void_echo":
			return 1
		"strat_chill_wave":
			return 3
		"strat_counter_demon_summon":
			return 2
		"strat_nuclear_strike":
			return 6
		_:
			return 0
