extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var content: Node = load("res://autoload/battle_content.gd").new()
	var packs_by_id: Dictionary = {}
	for row in content.get_test_packs():
		var pack := row as Dictionary
		packs_by_id[str(pack.get("pack_id", ""))] = pack
	_assert_pack(packs_by_id, "pack_a3_active_chill", ["strat_chill_wave"])
	_assert_pack(packs_by_id, "pack_a3_active_nuke", ["strat_nuclear_strike"])
	_assert_pack(packs_by_id, "pack_a3_active_combo", ["strat_chill_wave", "strat_nuclear_strike"])
	content.free()
	_finish()


func _assert_pack(packs_by_id: Dictionary, pack_id: String, expected_strategy_ids: Array) -> void:
	if not packs_by_id.has(pack_id):
		_failures.append("missing A3 active pack: %s" % pack_id)
		return
	var pack: Dictionary = packs_by_id[pack_id]
	if str(pack.get("battle_id", "")) != "battle_void_gate_alpha":
		_failures.append("%s should use battle_void_gate_alpha" % pack_id)
	var strategy_ids: Array = pack.get("strategy_ids", [])
	for strategy_id in expected_strategy_ids:
		if not strategy_ids.has(strategy_id):
			_failures.append("%s should include %s" % [pack_id, strategy_id])


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
