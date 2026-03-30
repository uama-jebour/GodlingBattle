extends RefCounted

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")


func run_scenarios(
	scenarios: Array,
	max_ms_threshold: float = 250.0,
	baseline_summary: Dictionary = {},
	allowed_ratio_threshold: float = 1.2
) -> Dictionary:
	var runner: RefCounted = RUNNER.new()
	var scenario_summaries: Array = []
	var issues: Array = []
	var total_runs := 0
	var total_ms := 0.0
	var max_run_ms := 0.0

	for scenario in scenarios:
		var scenario_id: String = str(scenario.get("scenario_id", ""))
		var setup: Dictionary = scenario.get("setup", {}).duplicate(true)
		var iterations: int = maxi(int(scenario.get("iterations", 1)), 1)
		var expect_deterministic: bool = bool(scenario.get("expect_deterministic", false))
		var status_counts := {}
		var run_samples_ms: Array = []
		var baseline_result_json := ""
		var deterministic_ok := true

		for _index in range(iterations):
			var t0: int = Time.get_ticks_usec()
			var payload: Dictionary = runner.run(setup)
			var run_ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
			var result: Dictionary = payload.get("result", {})
			var status: String = str(result.get("status", ""))
			if not status_counts.has(status):
				status_counts[status] = 0
			status_counts[status] = int(status_counts[status]) + 1

			run_samples_ms.append(run_ms)
			total_runs += 1
			total_ms += run_ms
			if run_ms > max_run_ms:
				max_run_ms = run_ms
			if status != "completed":
				issues.append("scenario %s has non-completed status: %s" % [scenario_id, status])

			if expect_deterministic:
				var result_json := JSON.stringify(result)
				if baseline_result_json.is_empty():
					baseline_result_json = result_json
				elif baseline_result_json != result_json:
					deterministic_ok = false
		if expect_deterministic and not deterministic_ok:
			issues.append("scenario %s deterministic check failed" % scenario_id)

		scenario_summaries.append({
			"scenario_id": scenario_id,
			"iterations": iterations,
			"status_counts": status_counts,
			"avg_ms": _average(run_samples_ms),
			"max_ms": _maximum(run_samples_ms),
			"deterministic_ok": deterministic_ok
		})

	if max_run_ms > max_ms_threshold:
		issues.append("max_run_ms %.3f exceeds threshold %.3f" % [max_run_ms, max_ms_threshold])

	var summary := {
		"total_runs": total_runs,
		"avg_run_ms": 0.0 if total_runs <= 0 else total_ms / float(total_runs),
		"max_run_ms": max_run_ms,
		"scenario_summaries": scenario_summaries,
		"issues": issues
	}
	if not baseline_summary.is_empty():
		issues.append_array(compare_with_baseline(summary, baseline_summary, allowed_ratio_threshold))
	return summary


func build_summary_csv(summary: Dictionary) -> String:
	var lines: Array[String] = ["scenario_id,iterations,avg_ms,max_ms,deterministic_ok,status_counts_json"]
	for scenario in summary.get("scenario_summaries", []):
		var scenario_id := _csv_escape(str(scenario.get("scenario_id", "")))
		var iterations := int(scenario.get("iterations", 0))
		var avg_ms := float(scenario.get("avg_ms", 0.0))
		var max_ms := float(scenario.get("max_ms", 0.0))
		var deterministic_ok := "true" if bool(scenario.get("deterministic_ok", false)) else "false"
		var status_counts_json := _csv_escape(JSON.stringify(scenario.get("status_counts", {})))
		lines.append("%s,%d,%.3f,%.3f,%s,%s" % [
			scenario_id,
			iterations,
			avg_ms,
			max_ms,
			deterministic_ok,
			status_counts_json
		])
	return "\n".join(lines)


func compare_with_baseline(
	current_summary: Dictionary,
	baseline_summary: Dictionary,
	allowed_ratio_threshold: float = 1.2
) -> Array:
	var issues: Array = []
	var ratio := maxf(allowed_ratio_threshold, 1.0)

	var current_avg := float(current_summary.get("avg_run_ms", 0.0))
	var baseline_avg := float(baseline_summary.get("avg_run_ms", 0.0))
	if _metric_exceeds_ratio(current_avg, baseline_avg, ratio):
		issues.append(
			"avg_run_ms %.3f exceeds baseline %.3f with ratio %.2f"
			% [current_avg, baseline_avg, ratio]
		)

	var current_max := float(current_summary.get("max_run_ms", 0.0))
	var baseline_max := float(baseline_summary.get("max_run_ms", 0.0))
	if _metric_exceeds_ratio(current_max, baseline_max, ratio):
		issues.append(
			"max_run_ms %.3f exceeds baseline %.3f with ratio %.2f"
			% [current_max, baseline_max, ratio]
		)

	var baseline_scenarios_by_id := {}
	for baseline_row in baseline_summary.get("scenario_summaries", []):
		baseline_scenarios_by_id[str(baseline_row.get("scenario_id", ""))] = baseline_row

	for current_row in current_summary.get("scenario_summaries", []):
		var scenario_id := str(current_row.get("scenario_id", ""))
		if not baseline_scenarios_by_id.has(scenario_id):
			continue
		var baseline_row: Dictionary = baseline_scenarios_by_id[scenario_id]
		var current_row_avg := float(current_row.get("avg_ms", 0.0))
		var baseline_row_avg := float(baseline_row.get("avg_ms", 0.0))
		if _metric_exceeds_ratio(current_row_avg, baseline_row_avg, ratio):
			issues.append(
				"scenario %s avg_ms %.3f exceeds baseline %.3f with ratio %.2f"
				% [scenario_id, current_row_avg, baseline_row_avg, ratio]
			)
		var current_row_max := float(current_row.get("max_ms", 0.0))
		var baseline_row_max := float(baseline_row.get("max_ms", 0.0))
		if _metric_exceeds_ratio(current_row_max, baseline_row_max, ratio):
			issues.append(
				"scenario %s max_ms %.3f exceeds baseline %.3f with ratio %.2f"
				% [scenario_id, current_row_max, baseline_row_max, ratio]
			)
		if bool(baseline_row.get("deterministic_ok", false)) and not bool(current_row.get("deterministic_ok", false)):
			issues.append("scenario %s deterministic regression detected" % scenario_id)
	return issues


func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())


func _maximum(values: Array) -> float:
	var max_value := 0.0
	for value in values:
		var as_float := float(value)
		if as_float > max_value:
			max_value = as_float
	return max_value


func _metric_exceeds_ratio(current_value: float, baseline_value: float, ratio: float) -> bool:
	if baseline_value <= 0.0:
		return false
	return current_value > baseline_value * ratio


func _csv_escape(value: String) -> String:
	if value.find(",") == -1 and value.find("\"") == -1 and value.find("\n") == -1:
		return value
	return "\"%s\"" % value.replace("\"", "\"\"")
