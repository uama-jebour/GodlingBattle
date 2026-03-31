extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene: PackedScene = load("res://scenes/prep/preparation_screen.tscn")
	var screen: Control = packed_scene.instantiate()
	root.add_child(screen)
	await process_frame

	_expect_node(screen, "ScrollContainer/Layout")
	_expect_node(screen, "ScrollContainer/Layout/TitleLabel")
	_expect_node(screen, "ScrollContainer/Layout/SelectionSummary")
	_expect_node(screen, "ScrollContainer/Layout/BattleSummary")
	_expect_node(screen, "ScrollContainer/Layout/ErrorLabel")
	_expect_node(screen, "ScrollContainer/Layout/StartBattleButton")

	var title_label: Label = screen.get_node_or_null("ScrollContainer/Layout/TitleLabel") as Label
	if title_label == null:
		_failures.append("expected ScrollContainer/Layout/TitleLabel to be a Label")
	elif title_label.text != "出战前准备":
		_failures.append("expected TitleLabel text to be 出战前准备")

	var battle_summary: Label = screen.get_node_or_null("ScrollContainer/Layout/BattleSummary") as Label
	if battle_summary == null:
		_failures.append("expected ScrollContainer/Layout/BattleSummary to be a Label")

	var error_label: Label = screen.get_node_or_null("ScrollContainer/Layout/ErrorLabel") as Label
	if error_label == null:
		_failures.append("expected ScrollContainer/Layout/ErrorLabel to be a Label")

	screen.free()
	_finish()


func _expect_node(root: Node, path: String) -> void:
	if root.get_node_or_null(path) == null:
		_failures.append("expected node %s to exist" % path)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
