extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var preset_select := screen.get_node_or_null("ScrollContainer/Layout/TestPresetSelect") as OptionButton
	var apply_preset_button := screen.get_node_or_null("ScrollContainer/Layout/ApplyPresetButton") as Button
	if preset_select == null:
		_failures.append("expected Layout/TestPresetSelect")
		_finish_with_cleanup(screen)
		return
	if apply_preset_button == null:
		_failures.append("expected Layout/ApplyPresetButton")
		_finish_with_cleanup(screen)
		return

	if _find_metadata_index(preset_select, "preset_a3_active_chill") < 0:
		_failures.append("expected preset_a3_active_chill")
	if _find_metadata_index(preset_select, "preset_a3_active_nuke") < 0:
		_failures.append("expected preset_a3_active_nuke")
	if _find_metadata_index(preset_select, "preset_a3_active_combo") < 0:
		_failures.append("expected preset_a3_active_combo")

	var combo_index := _find_metadata_index(preset_select, "preset_a3_active_combo")
	if combo_index >= 0:
		preset_select.select(combo_index)
		preset_select.item_selected.emit(combo_index)
		apply_preset_button.pressed.emit()
		await process_frame
		var current_selection: Dictionary = screen.call("get_current_selection")
		var strategy_ids: Array = current_selection.get("strategy_ids", [])
		if not strategy_ids.has("strat_chill_wave"):
			_failures.append("A3 combo preset should include strat_chill_wave")
		if not strategy_ids.has("strat_nuclear_strike"):
			_failures.append("A3 combo preset should include strat_nuclear_strike")
		if str(current_selection.get("battle_id", "")) != "battle_void_gate_alpha":
			_failures.append("A3 combo preset should use battle_void_gate_alpha")

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
	for message in _failures:
		printerr(message)
	quit(1)
