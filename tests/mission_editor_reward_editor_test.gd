extends SceneTree

const RewardEditor := preload("res://scripts/mission_editor/components/reward_editor.gd")


func _init():
	print("=== RewardEditor Tests ===")

	# Test 1: Instantiation
	var editor := RewardEditor.new()
	assert(editor != null, "RewardEditor should instantiate")
	editor.free()
	print("Test 1 PASSED: RewardEditor instantiation")

	# Test 2: Set and get rewards
	var editor2 := RewardEditor.new()
	var rewards: Array[Dictionary] = [
		{"type": "金币", "value": 100},
		{"type": "经验", "value": 50}
	]
	editor2.set_rewards(rewards)
	var result := editor2.get_rewards()
	assert(result.size() == 2, "Should have 2 rewards")
	assert(result[0]["type"] == "金币", "First reward type should be 金币")
	assert(result[0]["value"] == 100, "First reward value should be 100")
	assert(result[1]["type"] == "经验", "Second reward type should be 经验")
	assert(result[1]["value"] == 50, "Second reward value should be 50")
	editor2.free()
	print("Test 2 PASSED: Set and get rewards")

	# Test 3: Empty rewards
	var editor3 := RewardEditor.new()
	var empty_rewards: Array[Dictionary] = []
	editor3.set_rewards(empty_rewards)
	var empty_result := editor3.get_rewards()
	assert(empty_result.size() == 0, "Empty input should result in empty output")
	editor3.free()
	print("Test 3 PASSED: Empty rewards")

	print("")
	print("=== ALL 3 TESTS PASSED ===")
	quit(0)
