extends RefCounted


func tick(state: Dictionary) -> void:
	if int(state.get("elapsed_ticks", 0)) == 0 and not state.get("strategies", []).is_empty():
		var first_strategy: Dictionary = state.get("strategies", [])[0]
		state["triggered_strategies"].append({
			"strategy_id": str(first_strategy.get("strategy_id", "")),
			"tick": 0
		})
