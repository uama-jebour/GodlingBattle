extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var exporter: RefCounted = load("res://tools/export_test_packs.gd").new()
	var rows: Array = exporter.run_test_packs([{
		"pack_id": "pack_void_echo",
		"battle_id": "battle_void_gate_alpha",
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"seed": 1001
	}])
	assert(rows.size() == 1)
	assert(rows[0].has("pack_id"))
	assert(rows[0].has("victory"))
	assert(rows[0].has("elapsed_seconds"))
	quit(0)
