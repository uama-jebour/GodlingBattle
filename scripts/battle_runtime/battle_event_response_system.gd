extends RefCounted


func tick(state: Dictionary) -> void:
	var events: Array = state.get("events", [])
	if events.is_empty():
		return
	var tick_now := int(state.get("elapsed_ticks", 0))
	if not state.has("event_runtime"):
		var runtime_state := {}
		for event_def in events:
			runtime_state[str(event_def.get("event_id", ""))] = {"stage": "idle", "warning_tick": -1}
		state["event_runtime"] = runtime_state
	var event_runtime: Dictionary = state.get("event_runtime", {})

	for event_def in events:
		var event_id := str(event_def.get("event_id", ""))
		if event_id.is_empty():
			continue
		var runtime: Dictionary = event_runtime.get(event_id, {"stage": "idle", "warning_tick": -1})
		var stage := str(runtime.get("stage", "idle"))
		if stage == "done":
			continue
		if stage == "idle" and _should_warn(event_def, state, tick_now):
			runtime["stage"] = "warning"
			runtime["warning_tick"] = tick_now
			state["log_entries"].append({
				"tick": tick_now,
				"type": "event_warning",
				"event_id": event_id
			})
		elif stage == "warning":
			var warning_tick := int(runtime.get("warning_tick", tick_now))
			var warning_duration_ticks := _warning_duration_ticks(event_def, state)
			if tick_now >= warning_tick + warning_duration_ticks:
				var responded := _check_response(event_def, state, tick_now)
				state["log_entries"].append({
					"tick": tick_now,
					"type": "event_resolve",
					"event_id": event_id,
					"responded": responded
				})
				state["triggered_events"].append({
					"event_id": event_id,
					"tick": tick_now,
					"responded": responded
				})
				if not responded:
					state["log_entries"].append({
						"tick": tick_now,
						"type": "event_unresolved_effect",
						"event_id": event_id
					})
				runtime["stage"] = "done"
		event_runtime[event_id] = runtime
	state["event_runtime"] = event_runtime


func _should_warn(event_def: Dictionary, state: Dictionary, tick_now: int) -> bool:
	var trigger_def: Dictionary = event_def.get("trigger_def", {})
	return _trigger_matches(trigger_def, state, tick_now)


func _warning_duration_ticks(event_def: Dictionary, state: Dictionary) -> int:
	var warning_seconds := float(event_def.get("warning_seconds", 0.0))
	var tick_rate := int(state.get("tick_rate", 10))
	return max(1, int(round(warning_seconds * float(tick_rate))))


func _check_response(event_def: Dictionary, state: Dictionary, tick_now: int) -> bool:
	var response_tag := str(event_def.get("response_tag", ""))
	var response_level := int(event_def.get("response_level", -1))
	for strategy_def in state.get("strategies", []):
		var trigger_def: Dictionary = strategy_def.get("trigger_def", {})
		if str(trigger_def.get("type", "")) != "event_response":
			continue
		if str(trigger_def.get("response_tag", "")) != response_tag:
			continue
		if int(trigger_def.get("response_level", -1)) != response_level:
			continue
		state["triggered_strategies"].append({
			"strategy_id": str(strategy_def.get("strategy_id", "")),
			"tick": tick_now
		})
		return true
	return false


func _trigger_matches(trigger_def: Dictionary, state: Dictionary, tick_now: int) -> bool:
	var trigger_type := str(trigger_def.get("type", ""))
	if trigger_type == "any":
		for rule in trigger_def.get("rules", []):
			if _rule_matches(rule, state, tick_now):
				return true
		return false
	return _rule_matches(trigger_def, state, tick_now)


func _rule_matches(rule: Dictionary, state: Dictionary, tick_now: int) -> bool:
	var rule_type := str(rule.get("type", ""))
	if rule_type == "elapsed_gte":
		var threshold_seconds := float(rule.get("value", 0.0))
		var tick_rate := int(state.get("tick_rate", 10))
		var elapsed_seconds := float(tick_now) / float(tick_rate)
		return elapsed_seconds >= threshold_seconds
	if rule_type == "ally_hp_ratio_lte":
		var threshold := float(rule.get("value", 0.0))
		for entity in state.get("entities", []):
			if str(entity.get("side", "")) != "ally":
				continue
			var max_hp := maxf(float(entity.get("max_hp", 1.0)), 1.0)
			var hp_ratio := float(entity.get("hp", 0.0)) / max_hp
			if hp_ratio <= threshold:
				return true
		return false
	return false
