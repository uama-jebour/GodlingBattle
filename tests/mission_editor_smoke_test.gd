extends SceneTree

func _init():
    print("=== Mission Editor Smoke Test ===")

    # Test 1: Can instantiate MissionData
    var MissionData = preload("res://scripts/data/mission_data.gd")
    var data := MissionData.new()
    data.new_mission()
    assert(data.mission_id != "", "MissionData should create with id")
    print("Test 1 PASSED: MissionData instantiation")

    # Test 2: Can create enemy entries
    data.add_enemy_entry("enemy_wandering_demon", "right_flank")
    assert(data.enemy_entries.size() == 1, "Should add enemy entry")
    print("Test 2 PASSED: Enemy entry creation")

    # Test 3: Can create event configs
    data.add_event_config("evt_hunter_fiend_arrival", "elapsed_15", "right_bottom")
    assert(data.event_configs.size() == 1, "Should add event config")
    print("Test 3 PASSED: Event config creation")

    # Test 4: Can create rewards
    data.add_reward("金币", 100)
    data.add_reward("经验", 50)
    assert(data.rewards.size() == 2, "Should have 2 rewards")
    print("Test 4 PASSED: Reward creation")

    # Test 5: Can save mission to resources/missions/
    var dir := DirAccess.open("res://resources/missions/")
    if dir == null:
        DirAccess.make_dir_recursive_absolute("res://resources/missions/")

    var save_path := "res://resources/missions/test_mission.tres"
    var err := ResourceSaver.save(data, save_path)
    assert(err == OK, "Should save without error, got: %d" % err)
    print("Test 5 PASSED: Mission save")

    # Test 6: Can load mission from file
    var loaded := load(save_path)
    assert(loaded != null, "Should load mission")
    assert(loaded.mission_id == data.mission_id, "Loaded mission should match")
    print("Test 6 PASSED: Mission load")

    # Cleanup
    DirAccess.remove_absolute(save_path)

    print("")
    print("=== ALL 6 SMOKE TESTS PASSED ===")
    quit(0)
