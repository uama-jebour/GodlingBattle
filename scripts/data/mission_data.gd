class_name MissionData
extends Resource

const MISSION_TYPES := ["主线", "支线", "日常", "活动"]
const REWARD_TYPES := ["金币", "经验", "道具"]

const TRIGGER_PRESETS := {
    "elapsed_15": {"type": "elapsed_gte", "value": 15.0},
    "elapsed_30": {"type": "elapsed_gte", "value": 30.0},
    "elapsed_60": {"type": "elapsed_gte", "value": 60.0},
    "ally_hp_50": {"type": "ally_hp_ratio_lte", "value": 0.5},
    "ally_hp_25": {"type": "ally_hp_ratio_lte", "value": 0.25},
    "enemy_count_2": {"type": "enemy_count_lte", "value": 2},
    "any_elapsed_15_or_ally_hp_50": {"type": "any", "rules": [
        {"type": "elapsed_gte", "value": 15.0},
        {"type": "ally_hp_ratio_lte", "value": 0.5}
    ]}
}

const SPAWN_ANCHORS := ["right_flank", "right_top", "right_bottom", "left_flank", "left_top", "left_bottom"]

# 元数据
var mission_id: String = ""
var mission_name: String = ""
var mission_type: String = "主线"
var briefing: String = ""
var hint: String = ""

# 剧情（逐行）
var pre_battle_lines: Array[String] = []
var post_battle_lines: Array[String] = []

# 战斗配置
var battle_id: String = ""
var enemy_entries: Array[Dictionary] = []
var event_configs: Array[Dictionary] = []

# 收益
var rewards: Array[Dictionary] = []


func new_mission() -> void:
    mission_id = "mission_%d" % Time.get_unix_time_from_system()
    mission_name = "新任务"
    mission_type = "主线"
    briefing = ""
    hint = ""
    pre_battle_lines = []
    post_battle_lines = []
    battle_id = ""
    enemy_entries = []
    event_configs = []
    rewards = []


func get_enemy_count() -> int:
    return enemy_entries.size()


func add_enemy_entry(unit_id: String, spawn_anchor: String) -> void:
    enemy_entries.append({"unit_id": unit_id, "spawn_anchor": spawn_anchor})


func remove_enemy_entry(index: int) -> void:
    if index >= 0 and index < enemy_entries.size():
        enemy_entries.remove_at(index)


func add_event_config(event_id: String, trigger_preset: String, spawn_anchor: String) -> void:
    event_configs.append({"event_id": event_id, "trigger_preset": trigger_preset, "spawn_anchor": spawn_anchor})


func remove_event_config(index: int) -> void:
    if index >= 0 and index < event_configs.size():
        event_configs.remove_at(index)


func add_reward(reward_type: String, value: int) -> void:
    rewards.append({"type": reward_type, "value": value})


func remove_reward(index: int) -> void:
    if index >= 0 and index < rewards.size():
        rewards.remove_at(index)


func is_valid() -> bool:
    return mission_id != "" and mission_name != ""
