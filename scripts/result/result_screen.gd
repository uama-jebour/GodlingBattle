extends Control

@onready var _headline: Label = $Layout/HeadlineLabel
@onready var _survivor: Label = $Layout/SurvivorLabel
@onready var _casualty: Label = $Layout/CasualtyLabel
@onready var _event: Label = $Layout/EventLabel
@onready var _strategy: Label = $Layout/StrategyLabel
@onready var _return_button: Button = $Layout/ReturnButton


func build_summary(result: Dictionary) -> Dictionary:
	return {
		"headline": "胜利" if bool(result.get("victory", false)) else "失败",
		"survivor_lines": result.get("survivors", []).duplicate(),
		"casualty_lines": result.get("casualties", []).duplicate(),
		"event_lines": _map_ids(result.get("triggered_events", []), "event_id"),
		"strategy_lines": _map_ids(result.get("triggered_strategies", []), "strategy_id")
	}


func _ready() -> void:
	var session_state := _session_state()
	var summary := build_summary({}) if session_state == null else build_summary(session_state.last_battle_result)
	_headline.text = String(summary.get("headline", "结果"))
	_survivor.text = "存活: %s" % ", ".join(summary.get("survivor_lines", []))
	_casualty.text = "阵亡: %s" % ", ".join(summary.get("casualty_lines", []))
	_event.text = "事件: %s" % ", ".join(summary.get("event_lines", []))
	_strategy.text = "策略: %s" % ", ".join(summary.get("strategy_lines", []))
	if not _return_button.pressed.is_connected(return_to_preparation):
		_return_button.pressed.connect(return_to_preparation)


func return_to_preparation() -> void:
	var session_state := _session_state()
	if session_state != null:
		session_state.clear_runtime()
	var app_router := _app_router()
	if app_router != null:
		app_router.goto_preparation()


func _map_ids(rows: Array, key: String) -> Array:
	var result_rows: Array = []
	for row in rows:
		result_rows.append(str(row.get(key, "")))
	return result_rows


func _session_state() -> Node:
	return get_node_or_null("/root/SessionState")


func _app_router() -> Node:
	return get_node_or_null("/root/AppRouter")
