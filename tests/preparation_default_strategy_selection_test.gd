extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	var strategy_list := screen.get_node_or_null("Layout/StrategyList") as VBoxContainer
	if strategy_list == null:
		_failures.append("missing strategy list")
	else:
		var selected := 0
		for child in strategy_list.get_children():
			var checkbox := child as CheckBox
			if checkbox != null and checkbox.button_pressed:
				selected += 1
		if selected != 4:
			_failures.append("expected 4 strategies selected by default, got %d" % selected)

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
