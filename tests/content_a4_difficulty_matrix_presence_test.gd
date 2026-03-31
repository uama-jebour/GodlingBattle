extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var content: Node = load("res://autoload/battle_content.gd").new()
	var battle_ids := [
		"battle_test_difficulty_tier1",
		"battle_test_difficulty_tier2",
		"battle_test_difficulty_tier3"
	]
	for battle_id in battle_ids:
		var battle: Dictionary = content.get_battle(battle_id)
		if battle.is_empty():
			_failures.append("missing A4 battle: %s" % battle_id)
			continue
		var enemy_units: Array = battle.get("enemy_units", [])
		if enemy_units.is_empty():
			_failures.append("A4 battle should not have empty enemy_units: %s" % battle_id)
	var packs := _pack_map(content.get_test_packs())
	_assert_pack_exists(packs, "pack_a4_difficulty_tier1", "battle_test_difficulty_tier1")
	_assert_pack_exists(packs, "pack_a4_difficulty_tier2", "battle_test_difficulty_tier2")
	_assert_pack_exists(packs, "pack_a4_difficulty_tier3", "battle_test_difficulty_tier3")
	content.free()
	_finish()


func _pack_map(rows: Array) -> Dictionary:
	var out := {}
	for row in rows:
		var pack := row as Dictionary
		out[str(pack.get("pack_id", ""))] = pack
	return out


func _assert_pack_exists(packs: Dictionary, pack_id: String, expected_battle_id: String) -> void:
	if not packs.has(pack_id):
		_failures.append("missing A4 test pack: %s" % pack_id)
		return
	var pack: Dictionary = packs[pack_id]
	if str(pack.get("battle_id", "")) != expected_battle_id:
		_failures.append("%s should target %s" % [pack_id, expected_battle_id])


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
