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
	assert(error_label.text.find("无法开始出战") != -1)
	assert(error_label.text.find("请选择英雄") != -1)

	var formation_slot: Node = load("res://scripts/prep/formation_slot.gd").new()
	formation_slot.call("render", "英雄", "灰烬天使")
	assert(formation_slot.slot_title == "英雄")
	assert(formation_slot.value_text == "灰烬天使")
	formation_slot.free()

	var strategy_slot: Node = load("res://scripts/prep/strategy_slot.gd").new()
	strategy_slot.call("render", "strat_void_echo", 1)
	assert(strategy_slot.strategy_id == "strat_void_echo")
	assert(strategy_slot.strategy_cost == 1)
	strategy_slot.free()

	var battle_picker: Node = load("res://scripts/prep/battle_picker.gd").new()
	battle_picker.call("set_selected_battle_id", "battle_void_gate_alpha")
	assert(battle_picker.selected_battle_id == "battle_void_gate_alpha")
	battle_picker.free()

	screen.queue_free()
	await process_frame
	quit(0)
