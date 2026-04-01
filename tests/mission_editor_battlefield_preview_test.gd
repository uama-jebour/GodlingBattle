extends SceneTree

const BattlefieldPreview := preload("res://scripts/mission_editor/components/battlefield_preview.gd")


func _init():
	print("=== BattlefieldPreview Tests ===")

	# Test 1: Instantiation
	var preview := BattlefieldPreview.new()
	assert(preview != null, "BattlefieldPreview should instantiate")
	preview.free()
	print("Test 1 PASSED: BattlefieldPreview instantiation")

	# Test 2: Set and get enemies
	var preview2 := BattlefieldPreview.new()
	var enemies: Array[Dictionary] = [
		{"unit_id": "enemy_wandering_demon", "spawn_anchor": "right_flank", "display_name": "游荡魔"}
	]
	preview2.set_enemies(enemies)
	var result := preview2.get_enemies()
	assert(result.size() == 1, "Should have 1 enemy")
	assert(result[0]["unit_id"] == "enemy_wandering_demon", "Unit ID should match")
	assert(result[0]["spawn_anchor"] == "right_flank", "Spawn anchor should match")
	preview2.free()
	print("Test 2 PASSED: Set and get enemies")

	# Test 3: Empty enemies
	var preview3 := BattlefieldPreview.new()
	var empty_enemies: Array[Dictionary] = []
	preview3.set_enemies(empty_enemies)
	var empty_result := preview3.get_enemies()
	assert(empty_result.size() == 0, "Empty input should result in empty output")
	preview3.free()
	print("Test 3 PASSED: Empty enemies")

	print("")
	print("=== ALL 3 TESTS PASSED ===")
	quit(0)
