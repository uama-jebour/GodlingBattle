extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var benchmark_script: GDScript = load("res://tools/runtime_benchmark.gd")
	if benchmark_script == null:
		_failures.append("missing runtime_benchmark.gd")
		_finish()
		return
	var benchmark: RefCounted = benchmark_script.new()
	if not benchmark.has_method("build_summary_csv"):
		_failures.append("missing build_summary_csv")
	if not benchmark.has_method("compare_with_baseline"):
		_failures.append("missing compare_with_baseline")
	if not _failures.is_empty():
		_finish()
		return

	var baseline_summary := {
		"avg_run_ms": 80.0,
		"max_run_ms": 120.0,
		"scenario_summaries": [
			{
				"scenario_id": "alpha_stack",
				"iterations": 6,
				"avg_ms": 70.0,
				"max_ms": 100.0,
				"deterministic_ok": true,
				"status_counts": {"completed": 6}
			}
		]
	}
	var current_summary := {
		"avg_run_ms": 110.0,
		"max_run_ms": 200.0,
		"scenario_summaries": [
			{
				"scenario_id": "alpha_stack",
				"iterations": 6,
				"avg_ms": 95.0,
				"max_ms": 160.0,
				"deterministic_ok": true,
				"status_counts": {"completed": 6}
			}
		]
	}

	var csv_text := str(benchmark.call("build_summary_csv", current_summary))
	if csv_text.find("scenario_id,iterations,avg_ms,max_ms,deterministic_ok,status_counts_json") == -1:
		_failures.append("csv should include header")
	if csv_text.find("alpha_stack,6,95.000,160.000,true") == -1:
		_failures.append("csv should include scenario row")

	var issues: Array = benchmark.call("compare_with_baseline", current_summary, baseline_summary, 1.2)
	if issues.is_empty():
		_failures.append("expected ratio threshold issues")

	var stable_issues: Array = benchmark.call("compare_with_baseline", current_summary, baseline_summary, 2.0)
	if not stable_issues.is_empty():
		_failures.append("expected no issues with loose ratio threshold")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
