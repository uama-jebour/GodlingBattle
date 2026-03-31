extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	screen.call("set_selection", {
		"hero_id": "hero_angel",
		"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
		"strategy_ids": ["strat_nuclear_strike", "strat_nuclear_strike", "strat_nuclear_strike"],
		"battle_id": "battle_void_gate_alpha",
		"seed": 1001
	})
	await process_frame

	var budget_label := screen.get_node("ScrollContainer/Layout/BudgetLabel") as Label
	assert(budget_label != null)
	assert(budget_label.text == "预算: 18 / 16")

	var start_btn := screen.get_node("ScrollContainer/Layout/StartBattleButton") as Button
	assert(start_btn != null)
	assert(start_btn.disabled)

	var error_label := screen.get_node("ScrollContainer/Layout/ErrorLabel") as Label
	assert(error_label != null)
	assert(error_label.text == "战技预算超出上限")

	screen.queue_free()
	await process_frame
	quit(0)
