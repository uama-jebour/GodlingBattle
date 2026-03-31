extends RefCounted

const DISPLAY_NAME_RESOLVER := preload("res://scripts/ui/display_name_resolver.gd")
const BATTLE_CONTENT := preload("res://autoload/battle_content.gd")

const EMPTY_BRIEF_TEXT := "本帧动态：暂无关键事件"
const EMPTY_DETAIL_TEXT := "暂无战术明细"

# Key event colored tag definitions
const TAG_HERO_DOWN := {"text": "[危急]", "bg": "#FF4444", "fg": "#FFFFFF"}
const TAG_ALLY_DOWN := {"text": "[损失]", "bg": "#FF8C00", "fg": "#FFFFFF"}
const TAG_ENEMY_DOWN := {"text": "[击杀]", "bg": "#00C853", "fg": "#FFFFFF"}
const TAG_UNRESOLVED := {"text": "[警报]", "bg": "#9C27B0", "fg": "#FFFFFF"}
const TAG_MISSED := {"text": "[错过]", "bg": "#FFD700", "fg": "#333333"}

var _resolver := DISPLAY_NAME_RESOLVER.new()
var _warning_seconds_by_event_id: Dictionary = {}
var _warning_seconds_cache_ready := false


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


func build_recent_detail(rows: Array, current_tick: int, filter_type: String = "all", limit: int = 12) -> Array[String]:
	var matched: Array = []
	for row in rows:
		var tick := int(row.get("tick", -1))
		if tick < 0 or tick > current_tick:
			continue
		var row_type := str(row.get("type", ""))
		if filter_type != "all" and row_type != filter_type:
			continue
		matched.append(row)
	if matched.is_empty():
		return [EMPTY_DETAIL_TEXT]
	var safe_limit := maxi(1, limit)
	var start_index := maxi(0, matched.size() - safe_limit)
	var lines: Array[String] = []
	for index in range(start_index, matched.size()):
		var row: Dictionary = matched[index]
		lines.append(_build_detail_line(row, int(row.get("tick", current_tick))))
	return lines


func build_key_event_lines(rows: Array, current_tick: int, limit: int = 8) -> Array[String]:
	var matched: Array[String] = []
	for row in rows:
		var tick := int(row.get("tick", -1))
		if tick < 0 or tick > current_tick:
			continue
		var row_type := str(row.get("type", ""))
		if row_type in ["hero_down", "ally_down", "enemy_down", "event_unresolved_effect"]:
			matched.append(_build_detail_line(row, tick))
			continue
		if row_type == "event_resolve" and not bool(row.get("responded", false)):
			matched.append(_build_detail_line(row, tick))
	if matched.is_empty():
		return ["暂无关键事件"]
	var safe_limit := maxi(1, limit)
	var start_index := maxi(0, matched.size() - safe_limit)
	var lines: Array[String] = []
	for index in range(start_index, matched.size()):
		lines.append(matched[index])
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
			return "第%d帧战技%s：%s" % [tick, _strategy_cast_mode_label(row), _resolver.strategy_name(str(row.get("strategy_id", "")))]
		"event_warning":
			return "第%d帧事件预警：%s（%s，%s）" % [tick, _resolver.event_name(str(row.get("event_id", ""))), _warning_countdown_text(row), _warning_response_text(row)]
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
			return "第%d帧释放战技：%s（%s）" % [tick, _resolver.strategy_name(str(row.get("strategy_id", ""))), _strategy_cast_mode_label(row)]
		"event_warning":
			return "第%d帧收到事件预警：%s（%s，%s）" % [tick, _resolver.event_name(str(row.get("event_id", ""))), _warning_countdown_text(row), _warning_response_text(row)]
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


func _warning_countdown_text(row: Dictionary) -> String:
	var seconds := _warning_seconds(row)
	if seconds <= 0:
		return "即将出现"
	return "%d秒后" % seconds


func _warning_response_text(row: Dictionary) -> String:
	if bool(row.get("response_ready", false)):
		var strategy_id := str(row.get("response_strategy_id", ""))
		if not strategy_id.is_empty():
			return "可响应：%s" % _resolver.strategy_name(strategy_id)
		return "可响应"
	var missing_reason := str(row.get("response_missing_reason", ""))
	if missing_reason.is_empty():
		missing_reason = "未携带对应对策"
	return "不可响应：%s" % missing_reason


func _warning_seconds(row: Dictionary) -> int:
	if row.has("warning_seconds"):
		return maxi(0, int(round(float(row.get("warning_seconds", 0.0)))))
	var event_id := str(row.get("event_id", ""))
	if event_id.is_empty():
		return 0
	_ensure_warning_seconds_cache()
	return maxi(0, int(_warning_seconds_by_event_id.get(event_id, 0)))


func _ensure_warning_seconds_cache() -> void:
	if _warning_seconds_cache_ready:
		return
	_warning_seconds_cache_ready = true
	var content := BATTLE_CONTENT.new()
	var raw_events = content.get("_events")
	if raw_events is Dictionary:
		for event_id in raw_events.keys():
			var event_def: Dictionary = raw_events[event_id]
			_warning_seconds_by_event_id[str(event_id)] = int(round(float(event_def.get("warning_seconds", 0.0))))
	content.free()


func _strategy_cast_mode_label(row: Dictionary) -> String:
	var cast_mode := str(row.get("cast_mode", ""))
	if cast_mode == "passive":
		return "被动生效"
	return "施放"


# Phase15+: Colored tags for key events
func build_key_event_lines_with_tags(rows: Array, current_tick: int, limit: int = 8) -> Array[String]:
	var tagged_lines: Array[String] = []
	for row in rows:
		var tick := int(row.get("tick", -1))
		if tick < 0 or tick > current_tick:
			continue
		var row_type := str(row.get("type", ""))
		var tag_dict := _get_tag_for_event_type(row_type, row)
		var detail_line := _build_detail_line(row, tick)
		if tag_dict != null and not tag_dict.is_empty():
			var tag_bb := "[color=%s][color=%s]%s[/color][/color]" % [tag_dict.bg, tag_dict.fg, tag_dict.text]
			tagged_lines.append("%s %s" % [tag_bb, detail_line])
		else:
			tagged_lines.append(detail_line)
	if tagged_lines.is_empty():
		return ["暂无关键事件"]
	var safe_limit := maxi(1, limit)
	var start_index := maxi(0, tagged_lines.size() - safe_limit)
	return tagged_lines.slice(start_index, tagged_lines.size())


func _get_tag_for_event_type(event_type: String, row: Dictionary) -> Dictionary:
	match event_type:
		"hero_down":
			return TAG_HERO_DOWN
		"ally_down":
			return TAG_ALLY_DOWN
		"enemy_down":
			return TAG_ENEMY_DOWN
		"event_unresolved_effect":
			return TAG_UNRESOLVED
		"event_resolve":
			if not bool(row.get("responded", false)):
				return TAG_MISSED
	return {}


# Phase15+: Phase summary cards
class PhaseData:
	var name: String
	var start_tick: int
	var end_tick: int
	var hero_down_count: int = 0
	var ally_down_count: int = 0
	var enemy_down_count: int = 0
	var unresolved_effect_count: int = 0
	var missed_event_count: int = 0
	var total_event_resolves: int = 0
	var responded_event_count: int = 0
	var strategy_cast_count: int = 0

	func get_response_rate() -> float:
		if total_event_resolves == 0:
			return 1.0
		return float(responded_event_count) / float(total_event_resolves)

	func get_summary() -> String:
		var net_kills := enemy_down_count - ally_down_count
		if net_kills >= 2:
			return "我方优势"
		elif net_kills <= -2:
			return "敌方压制"
		elif hero_down_count > 0:
			return "危机时刻"
		return "僵持中"


func build_phase_summary_cards(timeline: Array, event_rows: Array) -> Array[String]:
	if timeline.is_empty():
		return []

	var total_ticks := int((timeline[-1] as Dictionary).get("tick", 0))
	var final_tick := total_ticks

	# Define phase boundaries
	var phases := []
	phases.append(_create_phase_data("开局", 0, 60))
	if final_tick > 120:
		phases.append(_create_phase_data("中期", 61, mini(300, final_tick)))
	if final_tick > 180:
		phases.append(_create_phase_data("后期", 301, final_tick))

	# Collect stats for each phase
	for phase: PhaseData in phases:
		_collect_phase_stats(phase, event_rows)

	# Generate BBCode cards
	var cards: Array[String] = []
	for phase: PhaseData in phases:
		cards.append(_build_phase_card_bbcode(phase))

	return cards


func _create_phase_data(name: String, start: int, end: int) -> PhaseData:
	var phase := PhaseData.new()
	phase.name = name
	phase.start_tick = start
	phase.end_tick = end
	return phase


func _collect_phase_stats(phase: PhaseData, event_rows: Array) -> void:
	for row in event_rows:
		var tick := int(row.get("tick", -1))
		if tick < phase.start_tick or tick > phase.end_tick:
			continue

		var row_type := str(row.get("type", ""))
		match row_type:
			"hero_down":
				phase.hero_down_count += 1
			"ally_down":
				phase.ally_down_count += 1
			"enemy_down":
				phase.enemy_down_count += 1
			"event_unresolved_effect":
				phase.unresolved_effect_count += 1
			"event_resolve":
				phase.total_event_resolves += 1
				if bool(row.get("responded", false)):
					phase.responded_event_count += 1
				else:
					phase.missed_event_count += 1
			"strategy_cast":
				phase.strategy_cast_count += 1


func _build_phase_card_bbcode(phase: PhaseData) -> String:
	var response_rate := phase.get_response_rate()
	var response_percent := str(snapped(response_rate * 100, 0.1))
	var summary := phase.get_summary()

	var lines: PackedStringArray = []
	lines.append("[color=#E8EEF5]━ %s (Tick %d-%d) ━[/color]" % [phase.name, phase.start_tick, phase.end_tick])
	lines.append("[color=#5C6B7F]击杀 %d  损失 %d  %s %d[/color]" % [
		phase.enemy_down_count,
		phase.ally_down_count,
		"危急" if phase.hero_down_count > 0 else "危机",
		phase.hero_down_count
	])
	lines.append("[color=#5C6B7F]事件响应率 %s%%  策略施放 %d次[/color]" % [response_percent, phase.strategy_cast_count])
	lines.append("[color=#78C8FF]%s[/color]" % summary)
	lines.append("")

	return "\n".join(lines)
