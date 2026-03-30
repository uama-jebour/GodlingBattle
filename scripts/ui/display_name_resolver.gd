extends RefCounted

const BATTLE_CONTENT := preload("res://autoload/battle_content.gd")


func unit_name_from_unit_id(unit_id: String) -> String:
	if unit_id.is_empty():
		return "未知单位"
	var content := BATTLE_CONTENT.new()
	var unit_def: Dictionary = content.get_unit(unit_id)
	content.free()
	if unit_def.is_empty():
		return _unknown_unit_name(unit_id)
	return String(unit_def.get("display_name", _unknown_unit_name(unit_id)))


func unit_name_from_entity_id(entity_id: String) -> String:
	if entity_id.is_empty():
		return "未知单位"
	return unit_name_from_unit_id(_entity_id_to_unit_id(entity_id))


func strategy_name(strategy_id: String) -> String:
	if strategy_id.is_empty():
		return "未知战技"
	var content := BATTLE_CONTENT.new()
	var strategy_def: Dictionary = content.get_strategy(strategy_id)
	content.free()
	if strategy_def.is_empty():
		return "未知战技"
	return String(strategy_def.get("name", "未知战技"))


func event_name(event_id: String) -> String:
	if event_id.is_empty():
		return "未知事件"
	var content := BATTLE_CONTENT.new()
	var event_def: Dictionary = content.get_event(event_id)
	content.free()
	if event_def.is_empty():
		return "未知事件"
	return String(event_def.get("name", "未知事件"))


func battle_name(battle_id: String) -> String:
	if battle_id.is_empty():
		return "未知关卡"
	var content := BATTLE_CONTENT.new()
	var battle_def: Dictionary = content.get_battle(battle_id)
	content.free()
	if battle_def.is_empty():
		return "未知关卡"
	return String(battle_def.get("display_name", "未知关卡"))


func _entity_id_to_unit_id(entity_id: String) -> String:
	var split_index := entity_id.rfind("_")
	if split_index <= 0:
		return entity_id
	var suffix := entity_id.substr(split_index + 1)
	if not suffix.is_valid_int():
		return entity_id
	return entity_id.substr(0, split_index)


func _unknown_unit_name(raw_unit_id: String) -> String:
	if raw_unit_id.begins_with("enemy_"):
		return "未知敌方单位"
	if raw_unit_id.begins_with("ally_"):
		return "未知友军单位"
	if raw_unit_id.begins_with("hero_"):
		return "未知英雄单位"
	return "未知单位"
