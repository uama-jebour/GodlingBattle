extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var preset_select := screen.get_node_or_null("Layout/TestPresetSelect") as OptionButton
	var apply_preset_button := screen.get_node_or_null("Layout/ApplyPresetButton") as Button
	if preset_select == null or apply_preset_button == null:
		_failures.append("missing preset controls")
		_finish_with_cleanup(screen)
		return

	if _find_metadata_index(preset_select, "preset_a4_difficulty_tier1") < 0:
		_failures.append("expected preset_a4_difficulty_tier1")
	if _find_metadata_index(preset_select, "preset_a4_difficulty_tier2") < 0:
		_failures.append("expected preset_a4_difficulty_tier2")
	if _find_metadata_index(preset_select, "preset_a4_difficulty_tier3") < 0:
		_failures.append("expected preset_a4_difficulty_tier3")

	var tier3_index := _find_metadata_index(preset_select, "preset_a4_difficulty_tier3")
	if tier3_index >= 0:
		preset_select.select(tier3_index)
		preset_select.item_selected.emit(tier3_index)
		apply_preset_button.pressed.emit()
		await process_frame
		var selection: Dictionary = screen.call("get_current_selection")
		if str(selection.get("battle_id", "")) != "battle_test_difficulty_tier3":
			_failures.append("A4 tier3 preset should map battle_test_difficulty_tier3")
		var strategy_ids: Array = selection.get("strategy_ids", [])
		if not strategy_ids.has("strat_nuclear_strike"):
			_failures.append("A4 tier3 preset should include strat_nuclear_strike")
		if not strategy_ids.has("strat_counter_demon_summon"):
			_failures.append("A4 tier3 preset should include strat_counter_demon_summon")

	_finish_with_cleanup(screen)


func _find_metadata_index(option: OptionButton, expected: String) -> int:
	for idx in range(option.item_count):
		if str(option.get_item_metadata(idx)) == expected:
			return idx
	return -1


func _finish_with_cleanup(screen: Control) -> void:
	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for m in _failures:
		printerr(m)
	quit(1)
