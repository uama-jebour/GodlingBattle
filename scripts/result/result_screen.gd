extends Control


func build_summary(result: Dictionary) -> Dictionary:
	return {
		"headline": "胜利" if bool(result.get("victory", false)) else "失败",
		"survivor_lines": result.get("survivors", []).duplicate(),
		"casualty_lines": result.get("casualties", []).duplicate(),
		"event_lines": _map_ids(result.get("triggered_events", []), "event_id"),
		"strategy_lines": _map_ids(result.get("triggered_strategies", []), "strategy_id")
	}


func _ready() -> void:
	var _summary := build_summary(SessionState.last_battle_result)


func return_to_preparation() -> void:
	SessionState.clear_runtime()
	AppRouter.goto_preparation()


func _map_ids(rows: Array, key: String) -> Array:
	var result_rows: Array = []
	for row in rows:
		result_rows.append(str(row.get(key, "")))
	return result_rows
