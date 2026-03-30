extends RefCounted


func tick(state: Dictionary) -> void:
	if int(state.get("elapsed_ticks", 0)) == 5:
		state["log_entries"].append({"tick": 5, "type": "event_warning", "event_id": "evt_hunter_fiend_arrival"})
