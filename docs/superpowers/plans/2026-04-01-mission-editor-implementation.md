# 任务编辑器 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现任务编辑器，支持创建/编辑任务，包含剧情文本（逐行）、战斗配置（拖放敌人+事件）、任务元数据，保存为 `.tres` 资源文件。

**Architecture:** 单一场景 `mission_editor.tscn` + 单一脚本 `mission_editor.gd`，Tab 切换四个面板（战前剧情/战斗/战后剧情/任务面板），数据模型为 `MissionData` Resource 子类。

**Tech Stack:** Godot 4.6 GDScript, Resource (.tres) 持久化

---

## 文件结构

```
scripts/data/
  mission_data.gd              # [CREATE] MissionData Resource 类

scripts/mission_editor/
  mission_editor.gd            # [CREATE] 主编辑器逻辑

scenes/mission_editor/
  mission_editor.tscn           # [CREATE] 编辑器场景

autoload/
  app_router.gd                # [MODIFY] 新增 goto_mission_editor()

scenes/prep/
  preparation_screen.tscn       # [MODIFY] 新增"任务编辑器"按钮

resources/
  missions/                    # [AUTO] 保存的 .tres 文件
```

---

## Task 1: MissionData Resource 类

**Files:**
- Create: `scripts/data/mission_data.gd`
- Test: `tests/data/mission_data_test.gd`

- [ ] **Step 1: 创建 `resources/missions/` 目录**

Run: `mkdir -p resources/missions`

- [ ] **Step 2: 编写 MissionData Resource 类**

```gdscript
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
var enemy_entries: Array[Dictionary] = []  # [{unit_id: "", spawn_anchor: ""}]
var event_configs: Array[Dictionary] = []   # [{event_id: "", trigger_preset: "", spawn_anchor: ""}]

# 收益
var rewards: Array[Dictionary] = []  # [{type: "", value: 0}]


func _init():
    pass


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
```

- [ ] **Step 3: 编写单元测试**

```gdscript
extends SceneTree

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")

func _init():
    var data := MissionData.new()
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
    assert(data.enemy_entries[0].unit_id == "enemy_wandering_demon", "unit_id should match")

    # 测试 remove_enemy_entry
    data.remove_enemy_entry(0)
    assert(data.enemy_entries.size() == 0, "should have 0 enemy entries after removal")

    # 测试 add_reward
    data.add_reward("金币", 100)
    assert(data.rewards.size() == 1, "should have 1 reward")
    assert(data.rewards[0].type == "金币", "reward type should match")
    assert(data.rewards[0].value == 100, "reward value should match")

    # 测试 is_valid
    assert(data.is_valid() == true, "should be valid with mission_id and mission_name")
    var empty_data := MissionData.new()
    assert(empty_data.is_valid() == false, "should be invalid without mission_id")

    print("mission_data_test.gd: ALL PASSED")
    quit(0)
```

- [ ] **Step 4: 运行测试**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/data/mission_data_test.gd`
Expected: "mission_data_test.gd: ALL PASSED" and exit code 0

- [ ] **Step 5: 提交**

```bash
mkdir -p resources/missions
git add scripts/data/mission_data.gd tests/data/mission_data_test.gd resources/missions/.gitkeep
git commit -m "feat: add MissionData Resource class for mission editor"
```

---

## Task 2: Mission Editor 场景骨架

**Files:**
- Create: `scenes/mission_editor/mission_editor.tscn`
- Modify: `autoload/app_router.gd` (add scene constant)

- [ ] **Step 1: 创建目录**

Run: `mkdir -p scenes/mission_editor`

- [ ] **Step 2: 创建场景骨架**

Create `scenes/mission_editor/mission_editor.tscn` with:

```
[gd_scene load_steps=2 format=3 uid="uid://mission_editor"]

[ext_resource type="Script" path="res://scripts/mission_editor/mission_editor.gd" id="1"]

[node name="MissionEditor" type="Control"]
script = ExtResource("1")
```

- [ ] **Step 3: 在 AppRouter 中添加场景常量**

Modify `autoload/app_router.gd`:

```gdscript
const MISSION_EDITOR_SCENE := preload("res://scenes/mission_editor/mission_editor.tscn")
```

- [ ] **Step 4: 提交**

```bash
git add scenes/mission_editor/mission_editor.tscn autoload/app_router.gd
git commit -m "feat: add mission editor scene skeleton to app_router"
```

---

## Task 3: Mission Editor 脚本主逻辑

**Files:**
- Create: `scripts/mission_editor/mission_editor.gd`
- Modify: `autoload/app_router.gd` (add goto_mission_editor function)

- [ ] **Step 1: 编写 mission_editor.gd 框架**

```gdscript
extends Control

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")
const BATTLE_CONTENT := preload("res://autoload/battle_content.gd")

var _current_data: MissionData
var _is_new_mission: bool = true
var _selected_tab: int = 0

@onready var tab_container: TabContainer = $TabContainer
@onready var save_button: Button = $BottomBar/SaveButton
@onready var load_select: OptionButton = $BottomBar/LoadSelect
@onready var new_button: Button = $BottomBar/NewButton
@onready var back_button: Button = $BottomBar/BackButton

# Tab 节点
@onready var pre_battle_tab: Control = $TabContainer/PreBattleTab
@onready var battle_tab: Control = $TabContainer/BattleTab
@onready var post_battle_tab: Control = $TabContainer/PostBattleTab
@onready var mission_panel_tab: Control = $TabContainer/MissionPanelTab

# Mission Panel 节点
@onready var mission_name_edit: LineEdit = $TabContainer/MissionPanelTab/MissionNameEdit
@onready var mission_type_select: OptionButton = $TabContainer/MissionPanelTab/MissionTypeSelect
@onready var briefing_edit: TextEdit = $TabContainer/MissionPanelTab/BriefingEdit
@onready var hint_edit: TextEdit = $TabContainer/MissionPanelTab/HintEdit
@onready var rewards_container: VBoxContainer = $TabContainer/MissionPanelTab/RewardsContainer


func _ready() -> void:
    _init_tabs()
    _bind_signals()
    _new_mission()


func _init_tabs() -> void:
    # 初始化 TabContainer
    tab_container.set_tab_title(0, "战前剧情")
    tab_container.set_tab_title(1, "战斗")
    tab_container.set_tab_title(2, "战后剧情")
    tab_container.set_tab_title(3, "任务面板")

    # 初始化任务类型下拉
    mission_type_select.clear()
    for mission_type in MissionData.MISSION_TYPES:
        mission_type_select.add_item(mission_type)


func _bind_signals() -> void:
    save_button.pressed.connect(_on_save_pressed)
    new_button.pressed.connect(_on_new_pressed)
    back_button.pressed.connect(_on_back_pressed)
    mission_type_select.item_selected.connect(_on_mission_type_selected)

    # Mission name edit
    if mission_name_edit:
        mission_name_edit.text_changed.connect(_on_mission_name_changed)


func _new_mission() -> void:
    _current_data = MissionData.new()
    _current_data.new_mission()
    _is_new_mission = true
    _apply_data_to_ui()


func _apply_data_to_ui() -> void:
    # Mission metadata
    if mission_name_edit:
        mission_name_edit.text = _current_data.mission_name
    var type_idx := MissionData.MISSION_TYPES.find(_current_data.mission_type)
    if type_idx >= 0:
        mission_type_select.selected = type_idx
    if briefing_edit:
        briefing_edit.text = _current_data.briefing
    if hint_edit:
        hint_edit.text = _current_data.hint

    # TODO: 剧情行、战斗配置、收益 等后续任务填充


func _on_save_pressed() -> void:
    _pull_ui_to_data()
    if not _current_data.is_valid():
        push_error("Mission data is invalid")
        return

    var dir := DirAccess.open("res://resources/missions/")
    if dir == null:
        DirAccess.make_dir_recursive_absolute("res://resources/missions/")
        dir = DirAccess.open("res://resources/missions/")

    var path := "res://resources/missions/%s.tres" % _current_data.mission_id
    var err := ResourceSaver.save(_current_data, path)
    if err != OK:
        push_error("Failed to save mission: %s" % err)
        return

    print("Saved mission to: %s" % path)
    _is_new_mission = false


func _pull_ui_to_data() -> void:
    if mission_name_edit:
        _current_data.mission_name = mission_name_edit.text
    if mission_type_select.selected >= 0:
        _current_data.mission_type = MissionData.MISSION_TYPES[mission_type_select.selected]
    if briefing_edit:
        _current_data.briefing = briefing_edit.text
    if hint_edit:
        _current_data.hint = hint_edit.text


func _on_new_pressed() -> void:
    _new_mission()


func _on_back_pressed() -> void:
    var router := get_node_or_null("/root/AppRouter")
    if router:
        router.goto_preparation()


func _on_mission_type_selected(index: int) -> void:
    if _current_data:
        _current_data.mission_type = MissionData.MISSION_TYPES[index]


func _on_mission_name_changed(new_text: String) -> void:
    if _current_data:
        _current_data.mission_name = new_text
```

- [ ] **Step 2: 添加 goto_mission_editor 到 AppRouter**

Modify `autoload/app_router.gd`, add:

```gdscript
func goto_mission_editor(mission_id: String = "") -> void:
    _switch_to(MISSION_EDITOR_SCENE)
    if mission_id != "":
        var node := _host.get_node_or_null("MissionEditor")
        if node and node.has_method("load_mission"):
            node.load_mission(mission_id)
```

- [ ] **Step 3: 提交**

```bash
git add scripts/mission_editor/mission_editor.gd autoload/app_router.gd
git commit -m "feat: add mission editor main script and router integration"
```

---

## Task 4: 剧情行编辑器（Tab 1 & 3）

**Files:**
- Modify: `scripts/mission_editor/mission_editor.gd`
- Modify: `scenes/mission_editor/mission_editor.tscn`

- [ ] **Step 1: 创建剧情行编辑辅助函数**

Add to `mission_editor.gd`:

```gdscript
# ========== 剧情行编辑器 ==========

@onready var pre_battle_lines_container: VBoxContainer = $TabContainer/PreBattleTab/LinesContainer
@onready var post_battle_lines_container: VBoxContainer = $TabContainer/PostBattleTab/LinesContainer

var _pre_battle_line_editors: Array[LineEdit] = []
var _post_battle_line_editors: Array[LineEdit] = []


func _init_plot_tab(tab: Control, lines: Array[String], editors_ref: Array) -> void:
    var container: VBoxContainer = tab.get_node_or_null("LinesContainer")
    if container == null:
        return

    # 清空现有
    for child in container.get_children():
        child.queue_free()
    editors_ref.clear()

    # 添加行
    for i in range(lines.size()):
        _add_plot_line(container, lines[i], editors_ref)

    # 添加"添加行"按钮
    var add_btn := Button.new()
    add_btn.text = "+ 添加行"
    add_btn.pressed.connect(_make_add_line_callback(container, editors_ref))
    container.add_child(add_btn)


func _add_plot_line(container: VBoxContainer, text: String, editors_ref: Array) -> void:
    var hbox := HBoxContainer.new()
    hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var line_num := Label.new()
    line_num.text = "%d." % (editors_ref.size() + 1)
    line_num.custom_minimum_size.x = 30

    var edit := LineEdit.new()
    edit.text = text
    edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    edit.text_submitted.connect(_make_line_edit_callback(editors_ref, editors_ref.size()))

    var up_btn := Button.new()
    up_btn.text = "↑"
    up_btn.custom_minimum_size.x = 30
    up_btn.pressed.connect(_make_move_line_callback(editors_ref, editors_ref.size(), -1))

    var down_btn := Button.new()
    down_btn.text = "↓"
    down_btn.custom_minimum_size.x = 30
    down_btn.pressed.connect(_make_move_line_callback(editors_ref, editors_ref.size(), 1))

    var del_btn := Button.new()
    del_btn.text = "×"
    del_btn.custom_minimum_size.x = 30
    del_btn.pressed.connect(_make_delete_line_callback(container, hbox, editors_ref, editors_ref.size()))

    hbox.add_child(line_num)
    hbox.add_child(edit)
    hbox.add_child(up_btn)
    hbox.add_child(down_btn)
    hbox.add_child(del_btn)

    container.add_child(hbox)
    editors_ref.append(edit)


func _make_add_line_callback(container: VBoxContainer, editors_ref: Array) -> Callable:
    return func():
        _add_plot_line(container, "", editors_ref)


func _make_line_edit_callback(editors_ref: Array, index: int) -> Callable:
    return func(new_text: String):
        if index < editors_ref.size():
            editors_ref[index] = new_text


func _make_move_line_callback(editors_ref: Array, index: int, direction: int) -> Callable:
    return func():
        var new_idx := index + direction
        if new_idx < 0 or new_idx >= editors_ref.size():
            return
        editors_ref[index] = editors_ref[new_idx]


func _make_delete_line_callback(container: VBoxContainer, hbox: HBoxContainer, editors_ref: Array, index: int) -> Callable:
    return func():
        if index < editors_ref.size():
            editors_ref.remove_at(index)
        hbox.queue_free()


func _sync_plot_lines() -> void:
    # 从 UI 同步到数据
    _current_data.pre_battle_lines.clear()
    for edit in _pre_battle_line_editors:
        _current_data.pre_battle_lines.append(edit.text)

    _current_data.post_battle_lines.clear()
    for edit in _post_battle_line_editors:
        _current_data.post_battle_lines.append(edit.text)
```

- [ ] **Step 2: 修改 `_apply_data_to_ui` 调用剧情初始化**

Update `_apply_data_to_ui` in mission_editor.gd to call:

```gdscript
    # 剧情行
    _init_plot_tab(pre_battle_tab, _current_data.pre_battle_lines, _pre_battle_line_editors)
    _init_plot_tab(post_battle_tab, _current_data.post_battle_lines, _post_battle_line_editors)
```

- [ ] **Step 3: 更新 `_pull_ui_to_data` 同步剧情行**

Add to `_pull_ui_to_data`:

```gdscript
    _sync_plot_lines()
```

- [ ] **Step 4: 提交**

```bash
git add scripts/mission_editor/mission_editor.gd
git commit -m "feat: add plot line editor for pre/post battle tabs"
```

---

## Task 5: 战斗配置 UI（Tab 2）

**Files:**
- Modify: `scripts/mission_editor/mission_editor.gd`
- Modify: `scenes/mission_editor/mission_editor.tscn`

- [ ] **Step 1: 添加战斗配置节点和辅助函数**

Add to `mission_editor.gd`:

```gdscript
# ========== 战斗配置 ==========

@onready var enemy_list_container: VBoxContainer = $TabContainer/BattleTab/EnemyListContainer
@onready var battlefield_container: Control = $TabContainer/BattleTab/BattlefieldContainer
@onready var event_list_container: VBoxContainer = $TabContainer/BattleTab/EventListContainer

var _placed_enemies: Array[Dictionary] = []  # [{unit_id, anchor_control}]
var _enemy_item_scene: PackedScene = null


func _init_battle_tab() -> void:
    _populate_enemy_list()
    _init_battlefield()
    _init_event_list()


func _populate_enemy_list() -> void:
    var content := BATTLE_CONTENT.new()
    var enemy_ids: Array[String] = content.get_all_enemy_ids()

    for child in enemy_list_container.get_children():
        child.queue_free()

    for enemy_id in enemy_ids:
        var enemy: Dictionary = content.get_unit(enemy_id)
        if enemy.is_empty():
            continue

        var hbox := HBoxContainer.new()

        var label := Label.new()
        label.text = "%s (%s)" % [enemy.get("display_name", enemy_id), enemy.get("attack_mode", "melee")]
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

        var drag_btn := Button.new()
        drag_btn.text = "拖放"
        drag_btn.draggable = 1  # 启用拖拽

        hbox.add_child(label)
        hbox.add_child(drag_btn)
        enemy_list_container.add_child(hbox)

    content.free()


func _init_battlefield() -> void:
    # 战场缩略图区域初始化
    # 预设锚点：right_flank, right_top, right_bottom, left_flank, left_top, left_bottom
    _placed_enemies.clear()


func _init_event_list() -> void:
    for child in event_list_container.get_children():
        child.queue_free()

    # 添加"添加事件"按钮
    var add_btn := Button.new()
    add_btn.text = "+ 添加事件"
    add_btn.pressed.connect(_on_add_event)
    event_list_container.add_child(add_btn)

    # 已有事件条目
    for i in range(_current_data.event_configs.size()):
        _add_event_entry(i)


func _add_event_entry(config_index: int) -> void:
    var config: Dictionary = _current_data.event_configs[config_index]

    var hbox := HBoxContainer.new()

    var trigger_select := OptionButton.new()
    for preset in MissionData.TRIGGER_PRESETS.keys():
        trigger_select.add_item(preset)
    trigger_select.selected = trigger_select.get_item_index(config.get("trigger_preset", "elapsed_15"))

    var anchor_select := OptionButton.new()
    for anchor in MissionData.SPAWN_ANCHORS:
        anchor_select.add_item(anchor)
    anchor_select.selected = anchor_select.get_item_index(config.get("spawn_anchor", "right_flank"))

    var del_btn := Button.new()
    del_btn.text = "×"
    del_btn.pressed.connect(_make_delete_event_callback(config_index))

    hbox.add_child(trigger_select)
    hbox.add_child(anchor_select)
    hbox.add_child(del_btn)
    event_list_container.add_child(hbox)


func _make_delete_event_callback(index: int) -> Callable:
    return func():
        _current_data.remove_event_config(index)
        _init_event_list()


func _on_add_event() -> void:
    _current_data.add_event_config("evt_hunter_fiend_arrival", "elapsed_15", "right_flank")
    _init_event_list()


func _sync_battle_config() -> void:
    # 从 UI 同步到数据
    _current_data.enemy_entries.clear()
    for enemy_data in _placed_enemies:
        _current_data.enemy_entries.append({
            "unit_id": enemy_data.unit_id,
            "spawn_anchor": enemy_data.anchor
        })
```

- [ ] **Step 2: 更新 `_apply_data_to_ui` 调用战斗初始化**

Add to `_apply_data_to_ui`:

```gdscript
    # 战斗配置
    _init_battle_tab()
```

- [ ] **Step 3: 更新 `_pull_ui_to_data` 同步战斗配置**

Add to `_pull_ui_to_data`:

```gdscript
    _sync_battle_config()
```

- [ ] **Step 4: 提交**

```bash
git add scripts/mission_editor/mission_editor.gd
git commit -m "feat: add battle config UI with enemy list and event list"
```

---

## Task 6: 收益配置 UI（Tab 4）

**Files:**
- Modify: `scripts/mission_editor/mission_editor.gd`

- [ ] **Step 1: 添加收益配置函数**

Add to `mission_editor.gd`:

```gdscript
# ========== 收益配置 ==========

@onready var rewards_add_btn: Button = $TabContainer/MissionPanelTab/AddRewardButton

var _reward_editors: Array[HBoxContainer] = []


func _init_rewards_section() -> void:
    for child in rewards_container.get_children():
        child.queue_free()
    _reward_editors.clear()

    for i in range(_current_data.rewards.size()):
        _add_reward_entry(i)

    # 添加"添加收益"按钮
    rewards_add_btn.pressed.connect(_on_add_reward)


func _add_reward_entry(reward_index: int) -> void:
    var reward: Dictionary = _current_data.rewards[reward_index]

    var hbox := HBoxContainer.new()

    var type_select := OptionButton.new()
    for rtype in MissionData.REWARD_TYPES:
        type_select.add_item(rtype)
    type_select.selected = type_select.get_item_index(reward.get("type", "金币"))

    var value_edit := LineEdit.new()
    value_edit.text = str(reward.get("value", 0))
    value_edit.custom_minimum_size.x = 80

    var del_btn := Button.new()
    del_btn.text = "×"
    del_btn.pressed.connect(_make_delete_reward_callback(reward_index))

    hbox.add_child(type_select)
    hbox.add_child(value_edit)
    hbox.add_child(del_btn)

    rewards_container.add_child(hbox)
    _reward_editors.append(hbox)


func _make_delete_reward_callback(index: int) -> Callable:
    return func():
        _current_data.remove_reward(index)
        _init_rewards_section()


func _on_add_reward() -> void:
    _current_data.add_reward("金币", 0)
    _init_rewards_section()


func _sync_rewards_config() -> void:
    _current_data.rewards.clear()
    for hbox in _reward_editors:
        var type_select: OptionButton = hbox.get_child(0)
        var value_edit: LineEdit = hbox.get_child(1)
        var reward_type: String = type_select.get_item_text(type_select.selected)
        var reward_value: int = int(value_edit.text) if value_edit.text.is_valid_int() else 0
        _current_data.rewards.append({"type": reward_type, "value": reward_value})
```

- [ ] **Step 2: 更新 `_apply_data_to_ui` 调用收益初始化**

Add to `_apply_data_to_ui`:

```gdscript
    # 收益配置
    _init_rewards_section()
```

- [ ] **Step 3: 更新 `_pull_ui_to_data` 同步收益配置**

Add to `_pull_ui_to_data`:

```gdscript
    _sync_rewards_config()
```

- [ ] **Step 4: 提交**

```bash
git add scripts/mission_editor/mission_editor.gd
git commit -m "feat: add rewards configuration UI to mission panel"
```

---

## Task 7: 准备页添加"任务编辑器"按钮

**Files:**
- Modify: `scenes/prep/preparation_screen.tscn`
- Modify: `scripts/prep/preparation_screen.gd`

- [ ] **Step 1: 在准备页场景添加按钮**

在 `preparation_screen.tscn` 的 `BottomBar` 或类似位置添加按钮：
```
[Node name="MissionEditorButton" type="Button"]
text = "任务编辑器"
```

- [ ] **Step 2: 在 `preparation_screen.gd` 添加按钮处理**

Add:

```gdscript
@onready var mission_editor_button: Button = $MissionEditorButton

func _ready() -> void:
    ...
    if not mission_editor_button.pressed.is_connected(_on_mission_editor_pressed):
        mission_editor_button.pressed.connect(_on_mission_editor_pressed)

func _on_mission_editor_pressed() -> void:
    var router := get_node_or_null("/root/AppRouter")
    if router:
        router.goto_mission_editor()
```

- [ ] **Step 3: 提交**

```bash
git add scenes/prep/preparation_screen.tscn scripts/prep/preparation_screen.gd
git commit -m "feat: add mission editor button to preparation screen"
```

---

## Task 8: 完整场景节点骨架

**Files:**
- Modify: `scenes/mission_editor/mission_editor.tscn`

- [ ] **Step 1: 创建完整场景结构**

创建 `mission_editor.tscn` 包含所有节点：

```
[gd_scene load_steps=2 format=3 uid="uid://mission_editor_scene"]

[ext_resource type="Script" path="res://scripts/mission_editor/mission_editor.gd" id="1"]

[node name="MissionEditor" type="Control"]
script = ExtResource("1")

[node name="TabContainer" type="TabContainer" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = 32.0

[node name="PreBattleTab" type="Control" parent="TabContainer"]
name = "PreBattleTab"
tab_index = 0

[node name="LinesContainer" type="VBoxContainer" parent="TabContainer/PreBattleTab"]

[node name="BattleTab" type="Control" parent="TabContainer"]
name = "BattleTab"
tab_index = 1

[node name="EnemyListContainer" type="VBoxContainer" parent="TabContainer/BattleTab"]

[node name="BattlefieldContainer" type="Control" parent="TabContainer/BattleTab"]

[node name="EventListContainer" type="VBoxContainer" parent="TabContainer/BattleTab"]

[node name="PostBattleTab" type="Control" parent="TabContainer"]
name = "PostBattleTab"
tab_index = 2

[node name="LinesContainer" type="VBoxContainer" parent="TabContainer/PostBattleTab"]

[node name="MissionPanelTab" type="Control" parent="TabContainer"]
name = "MissionPanelTab"
tab_index = 3

[node name="MissionNameEdit" type="LineEdit" parent="TabContainer/MissionPanelTab"]
offset_top = 10.0
offset_right = 300.0

[node name="MissionTypeSelect" type="OptionButton" parent="TabContainer/MissionPanelTab"]
offset_top = 50.0
offset_right = 150.0

[node name="BriefingEdit" type="TextEdit" parent="TabContainer/MissionPanelTab"]
offset_top = 90.0
offset_right = 400.0
offset_bottom = 200.0

[node name="HintEdit" type="TextEdit" parent="TabContainer/MissionPanelTab"]
offset_top = 210.0
offset_right = 400.0
offset_bottom = 320.0

[node name="RewardsContainer" type="VBoxContainer" parent="TabContainer/MissionPanelTab"]
offset_top = 330.0

[node name="AddRewardButton" type="Button" parent="TabContainer/MissionPanelTab"]
offset_top = 330.0
offset_right = 100.0
text = "+ 添加收益"

[node name="BottomBar" type="HBoxContainer" parent="."]
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -50.0

[node name="SaveButton" type="Button" parent="BottomBar"]
text = "保存"

[node name="LoadSelect" type="OptionButton" parent="BottomBar"]
text = "加载..."

[node name="NewButton" type="Button" parent="BottomBar"]
text = "新建"

[node name="BackButton" type="Button" parent="BottomBar"]
text = "返回准备页"
```

- [ ] **Step 2: 提交**

```bash
git add scenes/mission_editor/mission_editor.tscn
git commit -m "feat: add complete mission editor scene node structure"
```

---

## Task 9: 集成测试

**Files:**
- Create: `tests/mission_editor_test.gd`

- [ ] **Step 1: 编写集成测试**

```gdscript
extends SceneTree

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")

func _init():
    # 测试 MissionData 序列化
    var data := MissionData.new()
    data.new_mission()
    data.mission_name = "测试任务"
    data.mission_type = "支线"
    data.briefing = "这是测试简报"
    data.add_enemy_entry("enemy_wandering_demon", "right_flank")
    data.add_event_config("evt_hunter_fiend_arrival", "elapsed_15", "right_bottom")
    data.add_reward("金币", 100)

    # 测试 is_valid
    assert(data.is_valid() == true, "mission with all fields set should be valid")

    # 测试 enemy_entries
    assert(data.enemy_entries.size() == 1, "should have 1 enemy entry")
    assert(data.enemy_entries[0].unit_id == "enemy_wandering_demon", "unit_id should match")

    # 测试 event_configs
    assert(data.event_configs.size() == 1, "should have 1 event config")

    # 测试 rewards
    assert(data.rewards.size() == 1, "should have 1 reward")
    assert(data.rewards[0].type == "金币", "reward type should match")

    print("mission_editor_test.gd: ALL PASSED")
    quit(0)
```

- [ ] **Step 2: 运行测试**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/mission_editor_test.gd`
Expected: "mission_editor_test.gd: ALL PASSED" and exit code 0

- [ ] **Step 3: 提交**

```bash
git add tests/mission_editor_test.gd
git commit -m "test: add mission editor integration tests"
```

---

## Task 10: 验收测试

- [ ] **Step 1: 手动验收检查清单**

- [ ] 从准备页点击"任务编辑器"按钮能正常打开编辑器
- [ ] 四个 Tab 切换正常
- [ ] 战前剧情可以添加/删除/编辑行
- [ ] 战后剧情可以添加/删除/编辑行
- [ ] 战斗 Tab 显示敌方单位列表
- [ ] 战斗 Tab 显示事件配置列表
- [ ] 任务面板可填写名称、类型、简报、提示
- [ ] 收益配置可以添加/删除收益条目
- [ ] 保存按钮能成功保存 `.tres` 文件
- [ ] 返回按钮能返回准备页

- [ ] **Step 2: 提交最终状态**

```bash
git status
git log --oneline -12
```

---

## 依赖关系

```
Task 1 (MissionData) ─┬─> Task 2 (场景骨架)
                      └─> Task 3 (主脚本)
                      └─> Task 9 (集成测试)

Task 3 (主脚本) ────────> Task 4 (剧情编辑器)
                      └─> Task 5 (战斗配置)
                      └─> Task 6 (收益配置)
                      └─> Task 7 (准备页按钮)
                      └─> Task 8 (场景节点)

Task 2 ────────────────> Task 8 (场景节点)
```

---

## 自检清单

- [ ] 所有文件路径正确
- [ ] 所有函数名不重复
- [ ] 所有信号连接正确
- [ ] MissionData 常量（TRIGGER_PRESETS, SPAWN_ANCHORS, MISSION_TYPES, REWARD_TYPES）在各任务间一致
- [ ] Tab 节点路径与 `@onready` 一致
