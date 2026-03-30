extends Control

var entity_id := ""
var display_name := ""
var hp_ratio := 1.0
var side := ""


func apply_snapshot(snapshot: Dictionary) -> void:
	entity_id = str(snapshot.get("entity_id", ""))
	display_name = str(snapshot.get("display_name", ""))
	hp_ratio = float(snapshot.get("hp_ratio", 1.0))
	side = str(snapshot.get("side", ""))
