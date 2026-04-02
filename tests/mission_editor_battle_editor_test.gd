extends SceneTree

const BattleEditor := preload("res://scripts/mission_editor/components/battle_editor.gd")


func _init():
	print("=== BattleEditor Tests ===")

	# Test 1: Instantiation
	var editor: BattleEditor = BattleEditor.new()
	assert(editor != null, "BattleEditor should instantiate")
	editor.free()
	print("Test 1 PASSED: BattleEditor instantiation")

	# Test 2: Set and get config
	var editor2: BattleEditor = BattleEditor.new()
	var enemies: Array[Dictionary] = [
		{"unit_id": "enemy_wandering_demon", "spawn_anchor": "right_flank", "display_name": "游荡魔"}
	]
	var events: Array[Dictionary] = [
		{"event_id": "evt_custom", "trigger_preset": "elapsed_15", "spawn_anchor": "left_flank"}
	]
	editor2.set_config(enemies, events)
	var config: Dictionary = editor2.get_config()
	assert(config["enemy_entries"].size() == 1, "Should have 1 enemy")
	assert(config["event_configs"].size() == 1, "Should have 1 event")
	editor2.free()
	print("Test 2 PASSED: Set and get config")

	print("")
	print("=== ALL 2 TESTS PASSED ===")
	quit(0)
