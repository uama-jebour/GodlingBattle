extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/prep/preparation_screen.gd").new()

	var hero_only: Dictionary = screen.build_battle_setup({
		"hero_id": "hero_angel",
		"ally_ids": [],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 11
	})
	if hero_only.has("invalid_reason"):
		_failures.append("hero-only setup should be valid")

	var two_allies: Dictionary = screen.build_battle_setup({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 12
	})
	if two_allies.has("invalid_reason"):
		_failures.append("2-ally setup should be valid")

	var too_many: Dictionary = screen.build_battle_setup({
		"hero_id": "hero_angel",
		"ally_ids": [
			"ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant",
			"ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant",
			"ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"
		],
		"strategy_ids": [],
		"battle_id": "battle_void_gate_alpha",
		"seed": 13
	})
	if str(too_many.get("invalid_reason", "")) != "invalid_ally_count":
		_failures.append("expected invalid_ally_count for oversized ally_ids")

	screen.free()
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for msg in _failures:
		printerr(msg)
	quit(1)
