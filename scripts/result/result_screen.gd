extends Control


func build_summary(result: Dictionary) -> Dictionary:
	return {
		"headline": "胜利" if bool(result.get("victory", false)) else "失败",
		"survivor_lines": result.get("survivors", []).duplicate(),
		"event_lines": result.get("log_entries", []).duplicate()
	}


func _ready() -> void:
	var _summary := build_summary(SessionState.last_battle_result)


func return_to_preparation() -> void:
	SessionState.clear_runtime()
	AppRouter.goto_preparation()
