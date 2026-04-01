extends SceneTree

const MissionData = preload("res://scripts/data/mission_data.gd")

var _failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    # Test new_mission() sets defaults
    _test_new_mission_defaults()

    # Test add_enemy_entry / remove_enemy_entry
    _test_add_remove_enemy_entry()

    # Test add_event_config / remove_event_config
    _test_add_remove_event_config()

    # Test add_reward / remove_reward
    _test_add_remove_reward()

    # Test is_valid() with valid and empty data
    _test_is_valid()

    _finish()


func _test_new_mission_defaults() -> void:
    var data := MissionData.new()
    data.new_mission()
    _assert_eq(data.mission_id, "", "new_mission: mission_id should be empty")
    _assert_eq(data.mission_name, "", "new_mission: mission_name should be empty")
    _assert_eq(data.mission_type, "主线", "new_mission: mission_type should be '主线'")
    _assert_eq(data.briefing, "", "new_mission: briefing should be empty")
    _assert_eq(data.hint, "", "new_mission: hint should be empty")
    _assert_eq(data.pre_battle_lines, [], "new_mission: pre_battle_lines should be empty")
    _assert_eq(data.post_battle_lines, [], "new_mission: post_battle_lines should be empty")
    _assert_eq(data.battle_id, "", "new_mission: battle_id should be empty")
    _assert_eq(data.enemy_entries, [], "new_mission: enemy_entries should be empty")
    _assert_eq(data.event_configs, [], "new_mission: event_configs should be empty")
    _assert_eq(data.rewards, [], "new_mission: rewards should be empty")


func _test_add_remove_enemy_entry() -> void:
    var data := MissionData.new()
    data.new_mission()

    # Test adding entries
    data.add_enemy_entry("enemy_slime", "right_flank")
    data.add_enemy_entry("enemy_wolf", "left_top")

    _assert_eq(data.get_enemy_count(), 2, "add_enemy_entry: count should be 2 after adding 2 entries")
    _assert_eq(data.enemy_entries[0]["unit_id"], "enemy_slime", "add_enemy_entry: first entry unit_id")
    _assert_eq(data.enemy_entries[0]["spawn_anchor"], "right_flank", "add_enemy_entry: first entry spawn_anchor")
    _assert_eq(data.enemy_entries[1]["unit_id"], "enemy_wolf", "add_enemy_entry: second entry unit_id")
    _assert_eq(data.enemy_entries[1]["spawn_anchor"], "left_top", "add_enemy_entry: second entry spawn_anchor")

    # Test remove by index
    data.remove_enemy_entry(0)
    _assert_eq(data.get_enemy_count(), 1, "remove_enemy_entry: count should be 1 after removing first")
    _assert_eq(data.enemy_entries[0]["unit_id"], "enemy_wolf", "remove_enemy_entry: remaining entry should be wolf")

    # Test remove out of bounds (should not crash)
    data.remove_enemy_entry(99)
    _assert_eq(data.get_enemy_count(), 1, "remove_enemy_entry: out of bounds should not crash")


func _test_add_remove_event_config() -> void:
    var data := MissionData.new()
    data.new_mission()

    # Test adding configs
    data.add_event_config("evt_fire_storm", "elapsed_30", "right_top")
    data.add_event_config("evt_heal_wave", "ally_hp_50", "left_flank")

    _assert_eq(data.event_configs.size(), 2, "add_event_config: size should be 2")
    _assert_eq(data.event_configs[0]["event_id"], "evt_fire_storm", "add_event_config: first event_id")
    _assert_eq(data.event_configs[0]["trigger_preset"], "elapsed_30", "add_event_config: first trigger_preset")
    _assert_eq(data.event_configs[0]["spawn_anchor"], "right_top", "add_event_config: first spawn_anchor")
    _assert_eq(data.event_configs[1]["event_id"], "evt_heal_wave", "add_event_config: second event_id")

    # Test remove by index
    data.remove_event_config(0)
    _assert_eq(data.event_configs.size(), 1, "remove_event_config: size should be 1 after removing first")
    _assert_eq(data.event_configs[0]["event_id"], "evt_heal_wave", "remove_event_config: remaining event")

    # Test remove out of bounds (should not crash)
    data.remove_event_config(99)
    _assert_eq(data.event_configs.size(), 1, "remove_event_config: out of bounds should not crash")


func _test_add_remove_reward() -> void:
    var data := MissionData.new()
    data.new_mission()

    # Test adding rewards
    data.add_reward("金币", 100)
    data.add_reward("经验", 50)
    data.add_reward("道具", 1)

    _assert_eq(data.rewards.size(), 3, "add_reward: size should be 3")
    _assert_eq(data.rewards[0]["type"], "金币", "add_reward: first type")
    _assert_eq(data.rewards[0]["value"], 100, "add_reward: first value")
    _assert_eq(data.rewards[1]["type"], "经验", "add_reward: second type")
    _assert_eq(data.rewards[1]["value"], 50, "add_reward: second value")

    # Test remove by index
    data.remove_reward(1)
    _assert_eq(data.rewards.size(), 2, "remove_reward: size should be 2 after removing middle")
    _assert_eq(data.rewards[0]["type"], "金币", "remove_reward: first should remain")
    _assert_eq(data.rewards[1]["type"], "道具", "remove_reward: last should remain")

    # Test remove out of bounds (should not crash)
    data.remove_reward(99)
    _assert_eq(data.rewards.size(), 2, "remove_reward: out of bounds should not crash")


func _test_is_valid() -> void:
    var data := MissionData.new()
    data.new_mission()

    # Empty mission should not be valid
    _assert_false(data.is_valid(), "is_valid: empty mission should be invalid")

    # Set only mission_id - still invalid
    data.mission_id = "mission_001"
    _assert_false(data.is_valid(), "is_valid: only mission_id should be invalid")

    # Set mission_name - still invalid (no battle_id)
    data.mission_name = "Test Mission"
    _assert_false(data.is_valid(), "is_valid: mission_id + mission_name without battle_id should be invalid")

    # Set battle_id - still invalid (no enemy_entries)
    data.battle_id = "battle_void_gate_alpha"
    _assert_false(data.is_valid(), "is_valid: with battle_id but no enemy_entries should be invalid")

    # Add enemy entry - now should be valid
    data.add_enemy_entry("enemy_slime", "right_flank")
    _assert_true(data.is_valid(), "is_valid: with all required fields should be valid")


func _assert_true(condition: bool, message: String) -> void:
    if condition:
        return
    _failures.append(message)


func _assert_false(condition: bool, message: String) -> void:
    if not condition:
        return
    _failures.append(message)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
    if actual == expected:
        return
    _failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _finish() -> void:
    if _failures.is_empty():
        print("ALL PASSED")
        quit(0)
        return
    for failure in _failures:
        printerr(failure)
    quit(1)
