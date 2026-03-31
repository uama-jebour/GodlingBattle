extends SceneTree

const PREP_SCENE := preload("res://scenes/prep/preparation_screen.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var screen: Control = PREP_SCENE.instantiate()
	root.add_child(screen)
	await process_frame

	_expect_node(screen, "Layout/HeroSelect")
	_expect_node(screen, "Layout/BattleSelect")
	_expect_node_absent(screen, "Layout/SeedInput")
	_expect_node(screen, "Layout/StrategyList")

	screen.queue_free()
	await process_frame
	_finish()


func _expect_node(root_node: Node, path: String) -> void:
	if root_node.get_node_or_null(path) == null:
		_failures.append("expected node %s to exist" % path)


func _expect_node_absent(root_node: Node, path: String) -> void:
	if root_node.get_node_or_null(path) != null:
		_failures.append("expected node %s to be absent" % path)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
