extends SceneTree

const BATTLE_REPORT_FORMATTER := preload("res://scripts/observe/battle_report_formatter.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var formatter := BATTLE_REPORT_FORMATTER.new()

	# Test hero_down has [危急] tag
	var hero_down_event := {"tick": 10, "type": "hero_down", "entity_id": "hero_angel_0"}
	var hero_lines := formatter.build_key_event_lines_with_tags([hero_down_event], 100, 8)
	if hero_lines.is_empty():
		_failures.append("hero_down should produce a tagged line")
	else:
		var hero_line := hero_lines[0] as String
		if hero_line.find("[危急]") == -1:
			_failures.append("hero_down line should have [危急] tag: %s" % hero_line)
		if hero_line.find("#FF4444") == -1:
			_failures.append("hero_down tag should have #FF4444 (red) background: %s" % hero_line)

	# Test ally_down has [损失] tag
	var ally_down_event := {"tick": 20, "type": "ally_down", "entity_id": "ally_hound_0"}
	var ally_lines := formatter.build_key_event_lines_with_tags([ally_down_event], 100, 8)
	if ally_lines.is_empty():
		_failures.append("ally_down should produce a tagged line")
	else:
		var ally_line := ally_lines[0] as String
		if ally_line.find("[损失]") == -1:
			_failures.append("ally_down line should have [损失] tag: %s" % ally_line)
		if ally_line.find("#FF8C00") == -1:
			_failures.append("ally_down tag should have #FF8C00 (orange) background: %s" % ally_line)

	# Test enemy_down has [击杀] tag
	var enemy_down_event := {"tick": 30, "type": "enemy_down", "entity_id": "enemy_0"}
	var enemy_lines := formatter.build_key_event_lines_with_tags([enemy_down_event], 100, 8)
	if enemy_lines.is_empty():
		_failures.append("enemy_down should produce a tagged line")
	else:
		var enemy_line := enemy_lines[0] as String
		if enemy_line.find("[击杀]") == -1:
			_failures.append("enemy_down line should have [击杀] tag: %s" % enemy_line)
		if enemy_line.find("#00C853") == -1:
			_failures.append("enemy_down tag should have #00C853 (green) background: %s" % enemy_line)

	# Test event_unresolved_effect has [警报] tag
	var unresolved_event := {"tick": 40, "type": "event_unresolved_effect", "event_id": "evt_hunter_fiend_arrival"}
	var unresolved_lines := formatter.build_key_event_lines_with_tags([unresolved_event], 100, 8)
	if unresolved_lines.is_empty():
		_failures.append("event_unresolved_effect should produce a tagged line")
	else:
		var unresolved_line := unresolved_lines[0] as String
		if unresolved_line.find("[警报]") == -1:
			_failures.append("event_unresolved_effect line should have [警报] tag: %s" % unresolved_line)
		if unresolved_line.find("#9C27B0") == -1:
			_failures.append("event_unresolved_effect tag should have #9C27B0 (purple) background: %s" % unresolved_line)

	# Test unresponded event_resolve has [错过] tag
	var missed_event := {"tick": 50, "type": "event_resolve", "event_id": "evt_test", "responded": false}
	var missed_lines := formatter.build_key_event_lines_with_tags([missed_event], 100, 8)
	if missed_lines.is_empty():
		_failures.append("unresponded event_resolve should produce a tagged line")
	else:
		var missed_line := missed_lines[0] as String
		if missed_line.find("[错过]") == -1:
			_failures.append("unresponded event_resolve line should have [错过] tag: %s" % missed_line)
		if missed_line.find("#FFD700") == -1:
			_failures.append("unresponded event_resolve tag should have #FFD700 (gold) background: %s" % missed_line)

	# Test responded event_resolve has no tag
	var responded_event := {"tick": 60, "type": "event_resolve", "event_id": "evt_test", "responded": true}
	var responded_lines := formatter.build_key_event_lines_with_tags([responded_event], 100, 8)
	if responded_lines.is_empty():
		_failures.append("responded event_resolve should produce a line (but no tag expected)")
	else:
		var responded_line := responded_lines[0] as String
		if responded_line.find("[") != -1:
			_failures.append("responded event_resolve should not have a tag: %s" % responded_line)

	# Test limit parameter works correctly
	var all_events := [hero_down_event, ally_down_event, enemy_down_event]
	var limited_lines := formatter.build_key_event_lines_with_tags(all_events, 100, 2)
	if limited_lines.size() != 2:
		_failures.append("limit=2 should return exactly 2 lines, got %d" % limited_lines.size())

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for f in _failures:
		printerr(f)
	quit(1)
