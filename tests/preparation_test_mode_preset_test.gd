extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var battle_select := screen.get_node_or_null("ScrollContainer/Layout/BattleSelect") as OptionButton
	var ally_count_select := screen.get_node_or_null("ScrollContainer/Layout/AllyCountSelect") as OptionButton
	var preset_select := screen.get_node_or_null("ScrollContainer/Layout/TestPresetSelect") as OptionButton
	var apply_preset_button := screen.get_node_or_null("ScrollContainer/Layout/ApplyPresetButton") as Button
	if battle_select == null:
		_failures.append("expected Layout/BattleSelect")
	if ally_count_select == null:
		_failures.append("expected Layout/AllyCountSelect")
	if preset_select == null:
		_failures.append("expected Layout/TestPresetSelect")
	if apply_preset_button == null:
		_failures.append("expected Layout/ApplyPresetButton")

	if _failures.is_empty():
		if not _option_has_metadata(battle_select, "battle_void_gate_test_baseline"):
			_failures.append("battle select should include battle_void_gate_test_baseline")

		if not _option_has_metadata(ally_count_select, "ally_count_0"):
			_failures.append("ally count should include ally_count_0")
		if not _option_has_metadata(ally_count_select, "ally_count_2"):
			_failures.append("ally count should include ally_count_2")
		if not _option_has_metadata(ally_count_select, "ally_count_3"):
			_failures.append("ally count should include ally_count_3")

		var preset_index := _find_metadata_index(preset_select, "preset_1_2_hero_only_active")
		if preset_index < 0:
			_failures.append("expected preset_1_2_hero_only_active")
		else:
			preset_select.select(preset_index)
			preset_select.item_selected.emit(preset_index)
			apply_preset_button.pressed.emit()
			await process_frame
			if not screen.has_method("get_current_selection"):
				_failures.append("expected get_current_selection")
			else:
				var current_selection: Dictionary = screen.call("get_current_selection")
				if (current_selection.get("ally_ids", []) as Array).size() != 0:
					_failures.append("hero-only preset should set ally count to 0")
				if str(current_selection.get("battle_id", "")) != "battle_void_gate_test_baseline":
					_failures.append("hero-only preset should use baseline battle")
				if not (current_selection.get("strategy_ids", []) as Array).has("strat_chill_wave"):
					_failures.append("hero-only preset should include strat_chill_wave")

		if _find_metadata_index(preset_select, "preset_a1_enemy_melee") < 0:
			_failures.append("expected preset_a1_enemy_melee")
		if _find_metadata_index(preset_select, "preset_a1_enemy_ranged") < 0:
			_failures.append("expected preset_a1_enemy_ranged")
		if _find_metadata_index(preset_select, "preset_a1_enemy_mixed") < 0:
			_failures.append("expected preset_a1_enemy_mixed")
		if _find_metadata_index(preset_select, "preset_a1_enemy_elite") < 0:
			_failures.append("expected preset_a1_enemy_elite")
		if _find_metadata_index(preset_select, "preset_a2_quantity_allies") < 0:
			_failures.append("expected preset_a2_quantity_allies")
		if _find_metadata_index(preset_select, "preset_a2_individual_allies") < 0:
			_failures.append("expected preset_a2_individual_allies")
		if _find_metadata_index(preset_select, "preset_a2_mixed_allies") < 0:
			_failures.append("expected preset_a2_mixed_allies")
		if _find_metadata_index(preset_select, "preset_a3_active_chill") < 0:
			_failures.append("expected preset_a3_active_chill")
		if _find_metadata_index(preset_select, "preset_a3_active_nuke") < 0:
			_failures.append("expected preset_a3_active_nuke")
		if _find_metadata_index(preset_select, "preset_a3_active_combo") < 0:
			_failures.append("expected preset_a3_active_combo")
		if _find_metadata_index(preset_select, "preset_a4_difficulty_tier1") < 0:
			_failures.append("expected preset_a4_difficulty_tier1")
		if _find_metadata_index(preset_select, "preset_a4_difficulty_tier2") < 0:
			_failures.append("expected preset_a4_difficulty_tier2")
		if _find_metadata_index(preset_select, "preset_a4_difficulty_tier3") < 0:
			_failures.append("expected preset_a4_difficulty_tier3")

		var a1_index := _find_metadata_index(preset_select, "preset_a1_enemy_elite")
		if a1_index >= 0:
			preset_select.select(a1_index)
			preset_select.item_selected.emit(a1_index)
			apply_preset_button.pressed.emit()
			await process_frame
			var a1_selection: Dictionary = screen.call("get_current_selection")
			if str(a1_selection.get("battle_id", "")) != "battle_test_enemy_elite":
				_failures.append("A1 elite preset should map to battle_test_enemy_elite")

		var a2_index := _find_metadata_index(preset_select, "preset_a2_mixed_allies")
		if a2_index >= 0:
			preset_select.select(a2_index)
			preset_select.item_selected.emit(a2_index)
			apply_preset_button.pressed.emit()
			await process_frame
			var a2_selection: Dictionary = screen.call("get_current_selection")
			var ally_entries: Array = a2_selection.get("ally_entries", [])
			if ally_entries.size() != 2:
				_failures.append("A2 mixed preset should define two ally_entries rows")
			else:
				var first := ally_entries[0] as Dictionary
				var second := ally_entries[1] as Dictionary
				if str(first.get("unit_id", "")) != "ally_hound_remnant" or int(first.get("count", 0)) != 2:
					_failures.append("A2 mixed preset first row should be ally_hound_remnant x2")
				if str(second.get("unit_id", "")) != "ally_arc_shooter" or int(second.get("count", 0)) != 1:
					_failures.append("A2 mixed preset second row should be ally_arc_shooter x1")
			if str(a2_selection.get("battle_id", "")) != "battle_void_gate_alpha":
				_failures.append("A2 mixed preset should use battle_void_gate_alpha")

		var a3_index := _find_metadata_index(preset_select, "preset_a3_active_combo")
		if a3_index >= 0:
			preset_select.select(a3_index)
			preset_select.item_selected.emit(a3_index)
			apply_preset_button.pressed.emit()
			await process_frame
			var a3_selection: Dictionary = screen.call("get_current_selection")
			var a3_strategies: Array = a3_selection.get("strategy_ids", [])
			if not a3_strategies.has("strat_chill_wave") or not a3_strategies.has("strat_nuclear_strike"):
				_failures.append("A3 combo preset should include chill+nuke strategies")
			if str(a3_selection.get("battle_id", "")) != "battle_void_gate_alpha":
				_failures.append("A3 combo preset should use battle_void_gate_alpha")

		var a4_index := _find_metadata_index(preset_select, "preset_a4_difficulty_tier3")
		if a4_index >= 0:
			preset_select.select(a4_index)
			preset_select.item_selected.emit(a4_index)
			apply_preset_button.pressed.emit()
			await process_frame
			var a4_selection: Dictionary = screen.call("get_current_selection")
			if str(a4_selection.get("battle_id", "")) != "battle_test_difficulty_tier3":
				_failures.append("A4 tier3 preset should map to battle_test_difficulty_tier3")
			var a4_strategies: Array = a4_selection.get("strategy_ids", [])
			if not a4_strategies.has("strat_nuclear_strike"):
				_failures.append("A4 tier3 preset should include strat_nuclear_strike")

	screen.queue_free()
	await process_frame
	_finish()


func _option_has_metadata(option: OptionButton, expected: String) -> bool:
	return _find_metadata_index(option, expected) >= 0


func _find_metadata_index(option: OptionButton, expected: String) -> int:
	for idx in range(option.item_count):
		if str(option.get_item_metadata(idx)) == expected:
			return idx
	return -1


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for msg in _failures:
		printerr(msg)
	quit(1)
