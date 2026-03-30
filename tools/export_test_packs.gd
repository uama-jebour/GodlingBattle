extends RefCounted


func build_csv(rows: Array) -> String:
	var lines := ["battle_id,victory,elapsed_seconds"]
	for row in rows:
		lines.append("%s,%s,%s" % [
			str(row.get("battle_id", "")),
			"true" if bool(row.get("victory", false)) else "false",
			str(row.get("elapsed_seconds", 0.0))
		])
	return "\n".join(lines)
