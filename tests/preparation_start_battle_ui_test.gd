extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	screen.call("start_battle", {
		"hero_id": "",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_void_echo"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 7
	})

	await process_frame

	var error_label := screen.get_node("Layout/ErrorLabel") as Label
	assert(error_label != null)
	assert(not error_label.text.is_empty())

	screen.queue_free()
	await process_frame
	quit(0)
