extends RefCounted

const RUNNER := preload("res://scripts/battle_runtime/battle_runner.gd")


func build_csv(rows: Array) -> String:
	var lines := ["battle_id,victory,elapsed_seconds"]
	for row in rows:
		lines.append("%s,%s,%s" % [
			str(row.get("battle_id", "")),
			"true" if bool(row.get("victory", false)) else "false",
			str(row.get("elapsed_seconds", 0.0))
		])
	return "\n".join(lines)


func run_test_packs(packs: Array) -> Array:
	var runner: RefCounted = RUNNER.new()
	var rows: Array = []
	for pack in packs:
		var setup: Dictionary = {
			"hero_id": str(pack.get("hero_id", "")),
			"ally_ids": pack.get("ally_ids", []).duplicate(),
			"strategy_ids": pack.get("strategy_ids", []).duplicate(),
			"battle_id": str(pack.get("battle_id", "")),
			"seed": int(pack.get("seed", 0))
		}
		var payload: Dictionary = runner.run(setup)
		var result: Dictionary = payload.get("result", {})
		rows.append({
			"pack_id": str(pack.get("pack_id", "")),
			"battle_id": str(pack.get("battle_id", "")),
			"victory": bool(result.get("victory", false)),
			"elapsed_seconds": float(result.get("elapsed_seconds", 0.0))
		})
	return rows
