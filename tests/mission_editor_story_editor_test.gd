extends SceneTree

const StoryEditor := preload("res://scripts/mission_editor/components/story_editor.gd")


func _init():
	print("=== StoryEditor Tests ===")

	# Test 1: Instantiation
	var editor := StoryEditor.new()
	assert(editor != null, "StoryEditor should instantiate")
	editor.free()
	print("Test 1 PASSED: StoryEditor instantiation")

	# Test 2: Set and get lines
	var editor2 := StoryEditor.new()
	var lines: Array[String] = ["第一行", "第二行", "第三行"]
	editor2.set_lines(lines)
	var result := editor2.get_lines()
	assert(result.size() == 3, "Should have 3 lines")
	assert(result[0] == "第一行", "First line should match")
	assert(result[1] == "第二行", "Second line should match")
	assert(result[2] == "第三行", "Third line should match")
	editor2.free()
	print("Test 2 PASSED: Set and get lines")

	# Test 3: Empty lines
	var editor3 := StoryEditor.new()
	var empty_lines: Array[String] = []
	editor3.set_lines(empty_lines)
	var empty_result := editor3.get_lines()
	assert(empty_result.size() == 0, "Empty input should result in empty output")
	editor3.free()
	print("Test 3 PASSED: Empty lines")

	print("")
	print("=== ALL 3 TESTS PASSED ===")
	quit(0)
