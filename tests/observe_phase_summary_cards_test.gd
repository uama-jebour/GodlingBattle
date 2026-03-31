extends SceneTree

const BATTLE_REPORT_FORMATTER := preload("res://scripts/observe/battle_report_formatter.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var formatter := BATTLE_REPORT_FORMATTER.new()

	# Test 1: 3-phase battle generates 3 cards
	var timeline_3phases := [
		{"tick": 0, "entities": []},
		{"tick": 60, "entities": []},
		{"tick": 300, "entities": []},
		{"tick": 360, "entities": []}
	]
	var event_rows_3phases := [
		{"tick": 10, "type": "enemy_down", "entity_id": "enemy_0"},
		{"tick": 20, "type": "ally_down", "entity_id": "ally_0"},
		{"tick": 100, "type": "enemy_down", "entity_id": "enemy_1"},
		{"tick": 200, "type": "ally_down", "entity_id": "ally_1"},
		{"tick": 320, "type": "enemy_down", "entity_id": "enemy_2"}
	]
	var cards_3phases := formatter.build_phase_summary_cards(timeline_3phases, event_rows_3phases)
	if cards_3phases.size() != 3:
		_failures.append("3-phase battle should generate 3 cards, got %d" % cards_3phases.size())

	# Test 2: Opening phase (0-60) counts correctly
	if cards_3phases.size() >= 1:
		var opening_card := cards_3phases[0] as String
		if opening_card.find("开局") == -1:
			_failures.append("First card should mention '开局': %s" % opening_card)
		if opening_card.find("Tick 0-60") == -1:
			_failures.append("Opening card should have Tick 0-60 range: %s" % opening_card)

	# Test 3: Mid phase (61-300) counts correctly
	if cards_3phases.size() >= 2:
		var mid_card := cards_3phases[1] as String
		if mid_card.find("中期") == -1:
			_failures.append("Second card should mention '中期': %s" % mid_card)

	# Test 4: Late phase (301+) counts correctly
	if cards_3phases.size() >= 3:
		var late_card := cards_3phases[2] as String
		if late_card.find("后期") == -1:
			_failures.append("Third card should mention '后期': %s" % late_card)

	# Test 5: Event counts are accurate
	if cards_3phases.size() >= 1:
		var opening_card := cards_3phases[0] as String
		# Opening phase should have 1 kill and 1 loss
		if opening_card.find("击杀 1") == -1:
			_failures.append("Opening phase should have 1 kill: %s" % opening_card)
		if opening_card.find("损失 1") == -1:
			_failures.append("Opening phase should have 1 loss: %s" % opening_card)

	# Test 6: Response rate calculation
	var timeline_with_responses := [
		{"tick": 0, "entities": []},
		{"tick": 60, "entities": []}
	]
	var event_rows_with_responses := [
		{"tick": 10, "type": "event_resolve", "event_id": "evt_1", "responded": true},
		{"tick": 20, "type": "event_resolve", "event_id": "evt_2", "responded": true},
		{"tick": 30, "type": "event_resolve", "event_id": "evt_3", "responded": false}
	]
	var cards_response := formatter.build_phase_summary_cards(timeline_with_responses, event_rows_with_responses)
	if cards_response.size() >= 1:
		var response_card := cards_response[0] as String
		# Should have 66.7% response rate (2/3)
		if response_card.find("66.7%") == -1 and response_card.find("67%") == -1 and response_card.find("66%") == -1:
			_failures.append("Response rate should be approximately 66.7%%: %s" % response_card)

	# Test 7: Summary logic - advantage
	var timeline_advantage := [
		{"tick": 0, "entities": []},
		{"tick": 60, "entities": []}
	]
	var event_rows_advantage := [
		{"tick": 10, "type": "enemy_down", "entity_id": "enemy_0"},
		{"tick": 20, "type": "enemy_down", "entity_id": "enemy_1"},
		{"tick": 30, "type": "enemy_down", "entity_id": "enemy_2"},
		{"tick": 40, "type": "ally_down", "entity_id": "ally_0"}
	]
	var cards_advantage := formatter.build_phase_summary_cards(timeline_advantage, event_rows_advantage)
	if cards_advantage.size() >= 1:
		var advantage_card := cards_advantage[0] as String
		if advantage_card.find("我方优势") == -1:
			_failures.append("3 kills vs 1 loss should show '我方优势': %s" % advantage_card)

	# Test 8: Summary logic - suppression
	var timeline_suppression := [
		{"tick": 0, "entities": []},
		{"tick": 60, "entities": []}
	]
	var event_rows_suppression := [
		{"tick": 10, "type": "enemy_down", "entity_id": "enemy_0"},
		{"tick": 20, "type": "ally_down", "entity_id": "ally_0"},
		{"tick": 30, "type": "ally_down", "entity_id": "ally_1"},
		{"tick": 40, "type": "ally_down", "entity_id": "ally_2"}
	]
	var cards_suppression := formatter.build_phase_summary_cards(timeline_suppression, event_rows_suppression)
	if cards_suppression.size() >= 1:
		var suppression_card := cards_suppression[0] as String
		if suppression_card.find("敌方压制") == -1:
			_failures.append("1 kill vs 3 losses should show '敌方压制': %s" % suppression_card)

	# Test 9: Summary logic - stalemate
	var timeline_stalemate := [
		{"tick": 0, "entities": []},
		{"tick": 60, "entities": []}
	]
	var event_rows_stalemate := [
		{"tick": 10, "type": "enemy_down", "entity_id": "enemy_0"},
		{"tick": 20, "type": "ally_down", "entity_id": "ally_0"}
	]
	var cards_stalemate := formatter.build_phase_summary_cards(timeline_stalemate, event_rows_stalemate)
	if cards_stalemate.size() >= 1:
		var stalemate_card := cards_stalemate[0] as String
		if stalemate_card.find("僵持中") == -1:
			_failures.append("1 kill vs 1 loss should show '僵持中': %s" % stalemate_card)

	# Test 10: Summary logic - crisis
	var timeline_crisis := [
		{"tick": 0, "entities": []},
		{"tick": 60, "entities": []}
	]
	var event_rows_crisis := [
		{"tick": 10, "type": "hero_down", "entity_id": "hero_angel_0"},
		{"tick": 20, "type": "enemy_down", "entity_id": "enemy_0"},
		{"tick": 30, "type": "ally_down", "entity_id": "ally_0"}
	]
	var cards_crisis := formatter.build_phase_summary_cards(timeline_crisis, event_rows_crisis)
	if cards_crisis.size() >= 1:
		var crisis_card := cards_crisis[0] as String
		if crisis_card.find("危机时刻") == -1:
			_failures.append("Hero down should show '危机时刻': %s" % crisis_card)

	# Test 11: Empty timeline returns empty cards
	var empty_cards := formatter.build_phase_summary_cards([], [])
	if not empty_cards.is_empty():
		_failures.append("Empty timeline should return empty cards, got %d" % empty_cards.size())

	# Test 12: Short battle (under 120 ticks) generates only opening phase
	var timeline_short := [
		{"tick": 0, "entities": []},
		{"tick": 100, "entities": []}
	]
	var event_rows_short := [
		{"tick": 10, "type": "enemy_down", "entity_id": "enemy_0"}
	]
	var cards_short := formatter.build_phase_summary_cards(timeline_short, event_rows_short)
	if cards_short.size() != 1:
		_failures.append("Short battle (<120 ticks) should generate 1 card, got %d" % cards_short.size())

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for f in _failures:
		printerr(f)
	quit(1)
