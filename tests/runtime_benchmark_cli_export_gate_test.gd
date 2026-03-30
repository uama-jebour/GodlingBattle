extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cli_script: GDScript = load("res://tools/export_runtime_benchmark.gd")
	if cli_script == null:
		_failures.append("missing export_runtime_benchmark.gd")
		_finish()
		return
	var cli_runner: Object = cli_script.new()
	if not cli_runner.has_method("run_with_options"):
		_failures.append("missing run_with_options")
		_finish()
		return

	var output_csv_path := "user://runtime_benchmark_cli_test.csv"
	var baseline_json_path := "user://runtime_benchmark_cli_baseline.json"
	_remove_file_if_exists(output_csv_path)
	_remove_file_if_exists(baseline_json_path)

	var scenarios := [
		{
			"scenario_id": "cli_alpha",
			"setup": {
				"hero_id": "hero_angel",
				"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
				"strategy_ids": ["strat_void_echo", "strat_chill_wave"],
				"battle_id": "battle_void_gate_alpha",
				"seed": 20260330
			},
			"iterations": 1,
			"expect_deterministic": false
		}
	]

	var ok_result: Dictionary = cli_runner.call("run_with_options", {
		"scenarios": scenarios,
		"output_csv_path": output_csv_path,
		"max_ms_threshold": 5000.0,
		"ratio_threshold": 10.0
	})
	if int(ok_result.get("exit_code", -1)) != 0:
		_failures.append("expected successful cli export run")

	var output_csv_abs := ProjectSettings.globalize_path(output_csv_path)
	if not FileAccess.file_exists(output_csv_abs):
		_failures.append("expected output csv to be written")
	else:
		var file := FileAccess.open(output_csv_abs, FileAccess.READ)
		if file == null:
			_failures.append("failed to open output csv")
		else:
			var csv_text := file.get_as_text()
			if csv_text.find("scenario_id,iterations,avg_ms,max_ms,deterministic_ok,status_counts_json") == -1:
				_failures.append("csv header mismatch")
			if csv_text.find("cli_alpha") == -1:
				_failures.append("csv missing scenario row")

	var baseline_json := {
		"avg_run_ms": 0.001,
		"max_run_ms": 0.001,
		"scenario_summaries": [
			{
				"scenario_id": "cli_alpha",
				"avg_ms": 0.001,
				"max_ms": 0.001,
				"deterministic_ok": true
			}
		]
	}
	var baseline_abs := ProjectSettings.globalize_path(baseline_json_path)
	var baseline_file := FileAccess.open(baseline_abs, FileAccess.WRITE)
	if baseline_file == null:
		_failures.append("failed to write baseline json")
	else:
		baseline_file.store_string(JSON.stringify(baseline_json))
		baseline_file.flush()
		baseline_file.close()

	var gate_result: Dictionary = cli_runner.call("run_with_options", {
		"scenarios": scenarios,
		"output_csv_path": output_csv_path,
		"baseline_json_path": baseline_json_path,
		"max_ms_threshold": 5000.0,
		"ratio_threshold": 1.1
	})
	if int(gate_result.get("exit_code", 0)) != 1:
		_failures.append("expected gate failure when baseline ratio exceeded")
	var gate_issues: Array = gate_result.get("issues", [])
	if gate_issues.is_empty():
		_failures.append("expected gate issues for baseline regression")

	_remove_file_if_exists(output_csv_path)
	_remove_file_if_exists(baseline_json_path)
	_finish()


func _remove_file_if_exists(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute):
		return
	DirAccess.remove_absolute(absolute)


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
