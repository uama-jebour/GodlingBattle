extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = load("res://scripts/prep/preparation_screen.gd").new()
	var valid: Dictionary = screen.build_battle_setup({
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1001
	})
	assert(valid.get("hero_id", "") == "hero_angel")
	assert(valid.get("ally_ids", []).size() == 3)
	screen.free()
	quit(0)
