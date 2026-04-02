extends SceneTree

const TaskPanel := preload("res://scripts/mission_editor/components/task_panel.gd")
const MissionData := preload("res://scripts/data/mission_data.gd")


func _init():
	print("=== TaskPanel Tests ===")

	# Test 1: Instantiation
	var panel := TaskPanel.new()
	assert(panel != null, "TaskPanel should instantiate")
	panel.free()
	print("Test 1 PASSED: TaskPanel instantiation")

	# Test 2: Set and apply data
	var panel2 := TaskPanel.new()
	var data := MissionData.new()
	data.new_mission()
	data.mission_name = "测试任务"
	data.mission_type = "支线"
	data.briefing = "简报内容"
	data.hint = "提示内容"
	data.rewards = [{"type": "金币", "value": 100}]

	panel2.set_data(data)
	panel2.apply_to_data(data)

	assert(data.mission_name == "测试任务", "Mission name should be preserved")
	assert(data.mission_type == "支线", "Mission type should be preserved")
	assert(data.briefing == "简报内容", "Briefing should be preserved")
	assert(data.hint == "提示内容", "Hint should be preserved")
	panel2.free()
	print("Test 2 PASSED: Set and apply data")

	print("")
	print("=== ALL 2 TESTS PASSED ===")
	quit(0)
