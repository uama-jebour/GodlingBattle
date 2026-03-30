extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene: PackedScene = load("res://scenes/prep/preparation_screen.tscn")
	var screen: Control = packed_scene.instantiate()

	_expect_node(screen, "Layout")
	_expect_node(screen, "Layout/TitleLabel")
	_expect_node(screen, "Layout/SelectionSummary")
	_expect_node(screen, "Layout/StartBattleButton")

	var title_label: Label = screen.get_node_or_null("Layout/TitleLabel") as Label
	if title_label == null:
		_failures.append("expected Layout/TitleLabel to be a Label")
	elif title_label.text != "出战前准备":
		_failures.append("expected TitleLabel text to be 出战前准备")

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
