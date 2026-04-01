extends SceneTree

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")

func _init():
    print("=== Mission Editor Integration Tests ===")

    # Test 1: MissionData creation and new_mission
    var data := MISSION_DATA.new()
    data.new_mission()
    assert(data.mission_id != "", "mission_id should be set after new_mission")
    assert(data.mission_type == "主线", "default mission_type should be 主线")
    assert(data.has_pre_battle == false, "has_pre_battle should default to false")
    assert(data.has_battle == true, "has_battle should default to true")
    assert(data.has_post_battle == false, "has_post_battle should default to false")
    print("Test 1 PASSED: MissionData.new_mission()")

    # Test 2: Enemy entries
    data.add_enemy_entry("enemy_wandering_demon", "right_flank")
    assert(data.enemy_entries.size() == 1, "should have 1 enemy entry")
    assert(data.enemy_entries[0]["unit_id"] == "enemy_wandering_demon", "unit_id should match")
    data.add_enemy_entry("enemy_hunter_fiend", "right_top")
    assert(data.enemy_entries.size() == 2, "should have 2 enemy entries")
    data.remove_enemy_entry(0)
    assert(data.enemy_entries.size() == 1, "should have 1 enemy after removal")
    assert(data.enemy_entries[0]["unit_id"] == "enemy_hunter_fiend", "remaining enemy should be hunter_fiend")
    print("Test 2 PASSED: Enemy entries add/remove")

    # Test 3: Event configs
    data.add_event_config("evt_hunter_fiend_arrival", "elapsed_15", "right_flank")
    assert(data.event_configs.size() == 1, "should have 1 event config")
    assert(data.event_configs[0]["trigger_preset"] == "elapsed_15", "trigger preset should match")
    data.remove_event_config(0)
    assert(data.event_configs.size() == 0, "should have 0 event configs after removal")
    print("Test 3 PASSED: Event configs add/remove")

    # Test 4: Rewards
    data.add_reward("金币", 100)
    data.add_reward("经验", 50)
    assert(data.rewards.size() == 2, "should have 2 rewards")
    assert(data.rewards[0]["type"] == "金币", "first reward type should be 金币")
    assert(data.rewards[0]["value"] == 100, "first reward value should be 100")
    data.remove_reward(0)
    assert(data.rewards.size() == 1, "should have 1 reward after removal")
    print("Test 4 PASSED: Rewards add/remove")

    # Test 5: is_valid
    assert(data.is_valid() == true, "should be valid with mission_id and mission_name")
    var empty_data := MISSION_DATA.new()
    assert(empty_data.is_valid() == false, "should be invalid without mission_id")
    print("Test 5 PASSED: is_valid")

    # Test 6: Constants
    assert(MISSION_DATA.MISSION_TYPES.size() == 4, "should have 4 mission types")
    assert(MISSION_DATA.REWARD_TYPES.size() == 3, "should have 3 reward types")
    assert(MISSION_DATA.TRIGGER_PRESETS.size() == 7, "should have 7 trigger presets")
    assert(MISSION_DATA.SPAWN_ANCHORS.size() == 6, "should have 6 spawn anchors")
    print("Test 6 PASSED: Constants")

    # Test 7: Invalid spawn_anchor is rejected
    var data2 := MISSION_DATA.new()
    data2.new_mission()
    data2.add_enemy_entry("enemy_wandering_demon", "invalid_anchor")
    assert(data2.enemy_entries.size() == 0, "invalid spawn_anchor should be rejected")
    print("Test 7 PASSED: Invalid spawn_anchor rejection")

    # Test 8: Invalid trigger_preset is rejected
    data2.add_event_config("evt_hunter_fiend_arrival", "invalid_trigger", "right_flank")
    assert(data2.event_configs.size() == 0, "invalid trigger_preset should be rejected")
    print("Test 8 PASSED: Invalid trigger_preset rejection")

    # Test 9: Module flags persistence
    var data3 := MISSION_DATA.new()
    data3.new_mission()
    data3.has_pre_battle = true
    data3.has_post_battle = true
    assert(data3.has_pre_battle == true, "has_pre_battle should be true")
    assert(data3.has_battle == true, "has_battle should remain true")
    assert(data3.has_post_battle == true, "has_post_battle should be true")
    print("Test 9 PASSED: Module flags persistence")

    print("")
    print("=== ALL 9 TESTS PASSED ===")
    quit(0)
