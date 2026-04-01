extends SceneTree

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")

func _init():
    var data := MISSION_DATA.new()
    data.new_mission()

    # 测试默认值
    assert(data.mission_id != "", "mission_id should be set")
    assert(data.mission_type == "主线", "default mission_type should be 主线")
    assert(data.pre_battle_lines.size() == 0, "pre_battle_lines should be empty")
    assert(data.enemy_entries.size() == 0, "enemy_entries should be empty")
    assert(data.event_configs.size() == 0, "event_configs should be empty")
    assert(data.rewards.size() == 0, "rewards should be empty")

    # 测试 add_enemy_entry
    data.add_enemy_entry("enemy_wandering_demon", "right_flank")
    assert(data.enemy_entries.size() == 1, "should have 1 enemy entry")
    assert(data.enemy_entries[0]["unit_id"] == "enemy_wandering_demon", "unit_id should match")

    # 测试 remove_enemy_entry
    data.remove_enemy_entry(0)
    assert(data.enemy_entries.size() == 0, "should have 0 enemy entries after removal")

    # 测试 add_event_config
    data.add_event_config("evt_hunter_fiend_arrival", "elapsed_15", "right_flank")
    assert(data.event_configs.size() == 1, "should have 1 event config")
    assert(data.event_configs[0]["trigger_preset"] == "elapsed_15", "trigger_preset should match")

    # 测试 remove_event_config
    data.remove_event_config(0)
    assert(data.event_configs.size() == 0, "should have 0 event configs after removal")

    # 测试 add_reward
    data.add_reward("金币", 100)
    assert(data.rewards.size() == 1, "should have 1 reward")
    assert(data.rewards[0]["type"] == "金币", "reward type should match")
    assert(data.rewards[0]["value"] == 100, "reward value should match")

    # 测试 remove_reward
    data.remove_reward(0)
    assert(data.rewards.size() == 0, "should have 0 rewards after removal")

    # 测试 is_valid
    assert(data.is_valid() == true, "should be valid with mission_id and mission_name")
    var empty_data := MISSION_DATA.new()
    assert(empty_data.is_valid() == false, "should be invalid without mission_id")

    print("mission_data_test.gd: ALL PASSED")
    quit(0)
