extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/prep/preparation_screen.gd").new()
	var setup: Dictionary = screen.build_battle_setup({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_not_exist",
		"seed": 1001
	})
	if setup.get("invalid_reason", "") != "missing_battle":
		_failures.append("expected missing_battle")

	var missing_strategy_setup: Dictionary = screen.build_battle_setup({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_not_exist"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1001
	})
	if missing_strategy_setup.get("invalid_reason", "") != "missing_strategy":
		_failures.append("expected missing_strategy")

	var missing_ally_setup: Dictionary = screen.build_battle_setup({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_not_exist", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1001
	})
	if missing_ally_setup.get("invalid_reason", "") != "missing_ally":
		_failures.append("expected missing_ally")

	screen.free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
