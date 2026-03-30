extends Control

const DISPLAY_NAME_RESOLVER := preload("res://scripts/ui/display_name_resolver.gd")

@onready var _headline: Label = $Layout/HeadlineLabel
@onready var _survivor: Label = $Layout/SurvivorLabel
@onready var _casualty: Label = $Layout/CasualtyLabel
@onready var _event: Label = $Layout/EventLabel
@onready var _strategy: Label = $Layout/StrategyLabel
@onready var _strategy_cast_summary: Label = $Layout/StrategyCastSummaryLabel
@onready var _setup_snapshot: Label = $Layout/SetupSnapshotLabel
@onready var _replay_button: Button = $Layout/ReplayButton
@onready var _return_button: Button = $Layout/ReturnButton


func build_summary(result: Dictionary, battle_setup: Dictionary = {}) -> Dictionary:
	var resolver = DISPLAY_NAME_RESOLVER.new()
	return {
		"headline": "胜利" if bool(result.get("victory", false)) else "失败",
		"survivor_lines": _map_unit_names(result.get("survivors", []), resolver),
		"casualty_lines": _map_unit_names(result.get("casualties", []), resolver),
		"event_lines": _map_event_names(result.get("triggered_events", []), resolver),
		"strategy_lines": _map_strategy_names(result.get("triggered_strategies", []), resolver),
		"strategy_cast_lines": _build_strategy_cast_lines(result.get("log_entries", []), resolver),
		"setup_snapshot_lines": _build_setup_snapshot_lines(battle_setup, resolver)
	}


func _ready() -> void:
	var session_state := _session_state()
	var summary := (
		build_summary({})
		if session_state == null
		else build_summary(session_state.last_battle_result, session_state.battle_setup)
	)
	_headline.text = String(summary.get("headline", "结果"))
	_survivor.text = "存活: %s" % ", ".join(summary.get("survivor_lines", []))
	_casualty.text = "阵亡: %s" % ", ".join(summary.get("casualty_lines", []))
	_event.text = "事件: %s" % ", ".join(summary.get("event_lines", []))
	_strategy.text = "策略: %s" % ", ".join(summary.get("strategy_lines", []))
	_strategy_cast_summary.text = "关键施放: %s" % ", ".join(summary.get("strategy_cast_lines", []))
	_setup_snapshot.text = "配置快照: %s" % " | ".join(summary.get("setup_snapshot_lines", []))
	_replay_button.disabled = session_state == null or session_state.battle_setup.is_empty()
	if not _replay_button.pressed.is_connected(replay_battle):
		_replay_button.pressed.connect(replay_battle)
	if not _return_button.pressed.is_connected(return_to_preparation):
		_return_button.pressed.connect(return_to_preparation)


func replay_battle() -> void:
	var session_state := _session_state()
	if session_state == null or session_state.battle_setup.is_empty():
		return_to_preparation()
		return
	session_state.clear_runtime()
	var app_router := _app_router()
	if app_router != null:
		app_router.goto_observe()


func return_to_preparation() -> void:
	var session_state := _session_state()
	if session_state != null:
		session_state.clear_runtime()
	var app_router := _app_router()
	if app_router != null:
		app_router.goto_preparation()


func _map_unit_names(rows: Array, resolver: RefCounted) -> Array:
	var result_rows: Array = []
	for row in rows:
		result_rows.append(resolver.unit_name_from_entity_id(str(row)))
	return result_rows


func _map_event_names(rows: Array, resolver: RefCounted) -> Array:
	var result_rows: Array = []
	for row in rows:
		result_rows.append(resolver.event_name(str(row.get("event_id", ""))))
	return result_rows


func _map_strategy_names(rows: Array, resolver: RefCounted) -> Array:
	var result_rows: Array = []
	for row in rows:
		result_rows.append(resolver.strategy_name(str(row.get("strategy_id", ""))))
	return result_rows


func _build_strategy_cast_lines(log_entries: Array, resolver: RefCounted) -> Array:
	var cast_counts: Dictionary = {}
	var cast_order: Array[String] = []
	for row in log_entries:
		if str(row.get("type", "")) != "strategy_cast":
			continue
		var strategy_id := str(row.get("strategy_id", ""))
		if strategy_id.is_empty():
			continue
		if not cast_counts.has(strategy_id):
			cast_counts[strategy_id] = 0
			cast_order.append(strategy_id)
		cast_counts[strategy_id] = int(cast_counts[strategy_id]) + 1
	var lines: Array = []
	for strategy_id in cast_order:
		lines.append("%s x%d" % [resolver.strategy_name(strategy_id), int(cast_counts[strategy_id])])
	return lines


func _build_setup_snapshot_lines(battle_setup: Dictionary, resolver: RefCounted) -> Array:
	if battle_setup.is_empty():
		return ["英雄：", "友军：", "战技：", "关卡：", "种子："]
	var hero_id := str(battle_setup.get("hero_id", ""))
	var hero_name: String = resolver.unit_name_from_unit_id(hero_id)
	var ally_ids := _to_display_unit_names(resolver, battle_setup.get("ally_ids", []))
	var strategy_ids := _to_display_strategy_names(resolver, battle_setup.get("strategy_ids", []))
	var battle_id := str(battle_setup.get("battle_id", ""))
	var battle_name: String = resolver.battle_name(battle_id)
	var seed := str(battle_setup.get("seed", ""))
	return [
		"英雄：%s" % hero_name,
		"友军：%s" % ", ".join(ally_ids),
		"战技：%s" % ", ".join(strategy_ids),
		"关卡：%s" % battle_name,
		"种子：%s" % seed
	]


func _to_display_unit_names(resolver: RefCounted, raw_value: Variant) -> Array:
	var values: Array = []
	if not (raw_value is Array):
		return values
	for item in raw_value:
		values.append(resolver.unit_name_from_unit_id(str(item)))
	return values


func _to_display_strategy_names(resolver: RefCounted, raw_value: Variant) -> Array:
	var values: Array = []
	if not (raw_value is Array):
		return values
	for item in raw_value:
		values.append(resolver.strategy_name(str(item)))
	return values


func _session_state() -> Node:
	return get_node_or_null("/root/SessionState")


func _app_router() -> Node:
	return get_node_or_null("/root/AppRouter")
