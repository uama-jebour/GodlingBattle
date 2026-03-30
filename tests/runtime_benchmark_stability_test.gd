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
	var summary: Dictionary = benchmark.run_scenarios([
		{
			"scenario_id": "alpha_stack",
			"setup": {
				"hero_id": "hero_angel",
				"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
				"strategy_ids": ["strat_void_echo", "strat_chill_wave", "strat_nuclear_strike"],
				"battle_id": "battle_void_gate_alpha",
				"seed": 20260330
			},
			"iterations": 6,
			"expect_deterministic": true
		},
		{
			"scenario_id": "beta_multi_event",
			"setup": {
				"hero_id": "hero_angel",
				"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
				"strategy_ids": ["strat_void_echo", "strat_chill_wave", "strat_counter_demon_summon", "strat_nuclear_strike"],
				"battle_id": "battle_void_gate_beta",
				"seed": 20260330
			},
			"iterations": 6,
			"expect_deterministic": true
		}
	], 250.0)

	var total_runs := int(summary.get("total_runs", 0))
	if total_runs != 12:
		_failures.append("expected total_runs = 12, got %d" % total_runs)
	if not summary.has("scenario_summaries"):
		_failures.append("missing scenario_summaries")
	if float(summary.get("max_run_ms", 9999.0)) > 250.0:
		_failures.append("max_run_ms exceeds 250ms")

	var issues: Array = summary.get("issues", [])
	if not issues.is_empty():
		_failures.append("expected no benchmark issues, got %d" % issues.size())
	if not benchmark.has_method("build_summary_csv"):
		_failures.append("missing build_summary_csv")
	else:
		var csv_text := str(benchmark.call("build_summary_csv", summary))
		if csv_text.find("scenario_id,iterations,avg_ms,max_ms,deterministic_ok,status_counts_json") == -1:
			_failures.append("benchmark csv missing expected header")
		if csv_text.find("alpha_stack") == -1:
			_failures.append("benchmark csv missing alpha_stack row")

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		printerr(message)
	quit(1)
