extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	_expect_node(screen, "Layout/StrategyList")
	_expect_node(screen, "Layout/StrategyList/Strategy_strat_void_echo")
	_expect_node(screen, "Layout/StrategyList/Strategy_strat_chill_wave")
	_expect_node(screen, "Layout/StrategyList/Strategy_strat_counter_demon_summon")

	if _failures.is_empty():
		var strategy_void := screen.get_node("Layout/StrategyList/Strategy_strat_void_echo") as CheckBox
		var strategy_chill := screen.get_node("Layout/StrategyList/Strategy_strat_chill_wave") as CheckBox
		if strategy_void == null:
			_failures.append("expected strat_void_echo checkbox")
		if strategy_chill == null:
			_failures.append("expected strat_chill_wave checkbox")
		if _failures.is_empty():
			for child in (screen.get_node("Layout/StrategyList") as VBoxContainer).get_children():
				var checkbox := child as CheckBox
				if checkbox != null:
					checkbox.button_pressed = false
			await process_frame
			strategy_void.button_pressed = true
			strategy_chill.button_pressed = true
			await process_frame
			var setup: Dictionary = screen.call("build_battle_setup", {
				"hero_id": "hero_angel",
				"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
				"strategy_ids": ["strat_void_echo", "strat_chill_wave"],
				"battle_id": "battle_void_gate_alpha",
				"seed": 1001
			})
			if setup.has("invalid_reason"):
				_failures.append("expected valid setup for multi strategies")
			var budget_label := screen.get_node("Layout/BudgetLabel") as Label
			if budget_label == null:
				_failures.append("expected budget label")
			elif budget_label.text != "预算: 4 / 16":
				_failures.append("expected budget 4 / 16, got %s" % budget_label.text)

	screen.queue_free()
	await process_frame
	_finish()


func _expect_node(root_node: Node, path: String) -> void:
	if root_node.get_node_or_null(path) == null:
		_failures.append("expected node %s to exist" % path)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
