extends SceneTree

const EventList := preload("res://scripts/mission_editor/components/event_list.gd")


func _init():
	print("=== EventList Tests ===")

	# Test 1: Instantiation
	var lst := EventList.new()
	assert(lst != null, "EventList should instantiate")
	lst.free()
	print("Test 1 PASSED: EventList instantiation")

	# Test 2: Set and get events
	var lst2 := EventList.new()
	var events: Array[Dictionary] = [
		{"event_id": "evt_custom", "trigger_preset": "elapsed_30", "spawn_anchor": "left_flank"}
	]
	lst2.set_events(events)
	var result := lst2.get_events()
	assert(result.size() == 1, "Should have 1 event")
	assert(result[0]["trigger_preset"] == "elapsed_30", "Trigger preset should match")
	assert(result[0]["spawn_anchor"] == "left_flank", "Spawn anchor should match")
	lst2.free()
	print("Test 2 PASSED: Set and get events")

	# Test 3: Empty events
	var lst3 := EventList.new()
	var empty_events: Array[Dictionary] = []
	lst3.set_events(empty_events)
	var empty_result := lst3.get_events()
	assert(empty_result.size() == 0, "Empty input should result in empty output")
	lst3.free()
	print("Test 3 PASSED: Empty events")

	print("")
	print("=== ALL 3 TESTS PASSED ===")
	quit(0)
