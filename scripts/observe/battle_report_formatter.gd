extends RefCounted

const DISPLAY_NAME_RESOLVER := preload("res://scripts/ui/display_name_resolver.gd")

const EMPTY_BRIEF_TEXT := "本帧动态：暂无关键事件"
const EMPTY_DETAIL_TEXT := "暂无战术明细"

var _resolver := DISPLAY_NAME_RESOLVER.new()


func build_tick_brief(rows: Array, tick: int, filter_type: String = "all") -> String:
	var lines: Array[String] = []
	for row in _rows_for_tick(rows, tick, filter_type):
		lines.append(_build_brief_line(row, tick))
	if lines.is_empty():
		return EMPTY_BRIEF_TEXT
	return "本帧动态：%s" % " | ".join(lines)


func build_tick_detail(rows: Array, tick: int, filter_type: String = "all") -> Array[String]:
	var lines: Array[String] = []
	for row in _rows_for_tick(rows, tick, filter_type):
		lines.append(_build_detail_line(row, tick))
	if lines.is_empty():
		return [EMPTY_DETAIL_TEXT]
	return lines


func _rows_for_tick(rows: Array, tick: int, filter_type: String) -> Array:
	var filtered: Array = []
	for row in rows:
		if int(row.get("tick", -1)) != tick:
			continue
		var row_type := str(row.get("type", ""))
		if filter_type != "all" and row_type != filter_type:
			continue
		filtered.append(row)
	return filtered


func _build_brief_line(row: Dictionary, tick: int) -> String:
	var event_type := str(row.get("type", ""))
	match event_type:
		"strategy_cast":
			return "第%d帧战技施放：%s" % [tick, _resolver.strategy_name(str(row.get("strategy_id", "")))]
		"event_warning":
			return "第%d帧事件预警：%s" % [tick, _resolver.event_name(str(row.get("event_id", "")))]
		"event_resolve":
			return "第%d帧事件结算：%s（%s）" % [tick, _resolver.event_name(str(row.get("event_id", ""))), _responded_text(row)]
		"event_unresolved_effect":
			return "第%d帧未响应后果：%s" % [tick, _resolver.event_name(str(row.get("event_id", "")))]
		"ally_down":
			return "第%d帧友军%s倒下" % [tick, _resolver.unit_name_from_entity_id(str(row.get("entity_id", "")))]
		"hero_down":
			return "第%d帧%s倒下" % [tick, _resolver.unit_name_from_entity_id(str(row.get("entity_id", "")))]
		"enemy_down":
			return "第%d帧敌方%s倒下" % [tick, _resolver.unit_name_from_entity_id(str(row.get("entity_id", "")))]
		_:
			if row.has("event_id"):
				return "第%d帧发生事件：%s" % [tick, _resolver.event_name(str(row.get("event_id", "")))]
			if row.has("entity_id"):
				return "第%d帧发生单位变化：%s" % [tick, _resolver.unit_name_from_entity_id(str(row.get("entity_id", "")))]
			return "第%d帧发生其他事件" % tick


func _build_detail_line(row: Dictionary, tick: int) -> String:
	var event_type := str(row.get("type", ""))
	match event_type:
		"strategy_cast":
			return "第%d帧释放战技：%s" % [tick, _resolver.strategy_name(str(row.get("strategy_id", "")))]
		"event_warning":
			return "第%d帧收到事件预警：%s" % [tick, _resolver.event_name(str(row.get("event_id", "")))]
		"event_resolve":
			return "第%d帧结算事件：%s（%s）" % [tick, _resolver.event_name(str(row.get("event_id", ""))), _responded_text(row)]
		"event_unresolved_effect":
			return "第%d帧承受未响应后果：%s" % [tick, _resolver.event_name(str(row.get("event_id", "")))]
		"ally_down":
			return "第%d帧友军倒下：%s" % [tick, _resolver.unit_name_from_entity_id(str(row.get("entity_id", "")))]
		"hero_down":
			return "第%d帧英雄倒下：%s" % [tick, _resolver.unit_name_from_entity_id(str(row.get("entity_id", "")))]
		"enemy_down":
			return "第%d帧敌方倒下：%s" % [tick, _resolver.unit_name_from_entity_id(str(row.get("entity_id", "")))]
		_:
			if row.has("event_id"):
				return "第%d帧记录事件：%s" % [tick, _resolver.event_name(str(row.get("event_id", "")))]
			if row.has("entity_id"):
				return "第%d帧记录单位变化：%s" % [tick, _resolver.unit_name_from_entity_id(str(row.get("entity_id", "")))]
			return "第%d帧记录其他事件" % tick


func _responded_text(row: Dictionary) -> String:
	return "已响应" if bool(row.get("responded", false)) else "未响应"
