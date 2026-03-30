extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var workflow_path := ProjectSettings.globalize_path("res://.github/workflows/benchmark-gate.yml")
	if not FileAccess.file_exists(workflow_path):
		_failures.append("missing .github/workflows/benchmark-gate.yml")
		_finish()
		return

	var workflow_file := FileAccess.open(workflow_path, FileAccess.READ)
	if workflow_file == null:
		_failures.append("failed to open benchmark-gate.yml")
		_finish()
		return
	var workflow_text := workflow_file.get_as_text()

	_assert_contains(workflow_text, "name: benchmark-gate", "workflow name should be benchmark-gate")
	_assert_contains(workflow_text, "pull_request:", "workflow should run on pull_request")
	_assert_contains(workflow_text, "push:", "workflow should run on push")
	_assert_contains(workflow_text, "tools/run_benchmark_gate.sh", "workflow should call benchmark gate script")
	_assert_contains(workflow_text, "GODOT_BIN", "workflow should set GODOT_BIN for gate script")
	_assert_contains(workflow_text, "actions/checkout", "workflow should checkout repository")

	_finish()


func _assert_contains(text: String, expected: String, message: String) -> void:
	if text.find(expected) != -1:
		return
	_failures.append(message + " (missing: " + expected + ")")


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
