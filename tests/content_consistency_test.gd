extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var content: Node = load("res://autoload/battle_content.gd").new()
	for pack in content.get_test_packs():
		var pack_id := str(pack.get("pack_id", ""))
		var battle_id := str(pack.get("battle_id", ""))
		var has_ally_ids: bool = pack.has("ally_ids")
		var has_ally_entries: bool = pack.has("ally_entries")
		var ally_ids: Array = pack.get("ally_ids", [])
		var ally_entries: Array = pack.get("ally_entries", [])
		if not has_ally_ids and not has_ally_entries:
			_failures.append("pack should define ally_ids or ally_entries: %s" % pack_id)
		for ally_id in ally_ids:
			if content.get_unit(str(ally_id)).is_empty():
				_failures.append("missing ally unit: %s in %s" % [ally_id, pack_id])
		for raw in ally_entries:
			var entry := raw as Dictionary
			var unit_id := str(entry.get("unit_id", ""))
			var count := int(entry.get("count", 0))
			if unit_id.is_empty() or count <= 0:
				_failures.append("invalid ally_entries row in %s" % pack_id)
				continue
			if content.get_unit(unit_id).is_empty():
				_failures.append("missing ally_entries unit: %s in %s" % [unit_id, pack_id])
		if content.get_battle(battle_id).is_empty():
			_failures.append("missing battle: %s" % battle_id)
		for strategy_id in pack.get("strategy_ids", []):
			if content.get_strategy(str(strategy_id)).is_empty():
				_failures.append("missing strategy: %s" % strategy_id)
	var battle_ids := [
		"battle_void_gate_alpha",
		"battle_void_gate_beta",
		"battle_void_gate_test_baseline",
		"battle_test_enemy_melee",
		"battle_test_enemy_ranged",
		"battle_test_enemy_mixed",
		"battle_test_enemy_elite"
	]
	for battle_id in battle_ids:
		var battle: Dictionary = content.get_battle(battle_id)
		if battle.is_empty():
			_failures.append("missing battle definition: %s" % battle_id)
			continue
		for event_id in battle.get("event_ids", []):
			if content.get_event(str(event_id)).is_empty():
				_failures.append("missing event for battle %s: %s" % [battle_id, event_id])
	content.free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for msg in _failures:
		printerr(msg)
	quit(1)
