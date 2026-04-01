# 任务编辑器重制实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 全新重制任务编辑器，采用组件化架构，通过复选框控制模块启用，支持拖拽放置敌人。

**Architecture:** 组件化架构，主场景组合 TaskPanel、StoryEditor（复用两次）、BattleEditor（内含 BattlefieldPreview 和 EventList）、RewardEditor。

**Tech Stack:** Godot 4.x, GDScript, Resource 持久化

---

## 文件结构

```
scripts/mission_editor/
├── mission_editor.gd              # 主控制器（重写）
└── components/
    ├── task_panel.gd              # 任务面板逻辑
    ├── story_editor.gd            # 剧情编辑器逻辑
    ├── battle_editor.gd           # 战斗编辑器主逻辑
    ├── battlefield_preview.gd     # 战场预览（拖拽目标区）
    ├── enemy_drag_item.gd         # 可拖拽敌人项
    ├── placed_enemy_icon.gd       # 已放置敌人图标
    ├── event_list.gd              # 事件列表逻辑
    └── reward_editor.gd           # 收益编辑器逻辑

scenes/mission_editor/
├── mission_editor.tscn            # 主场景（重写）
└── components/
    ├── task_panel.tscn
    ├── story_editor.tscn
    ├── battle_editor.tscn
    ├── battlefield_preview.tscn
    ├── enemy_drag_item.tscn
    ├── placed_enemy_icon.tscn
    ├── event_list.tscn
    └── reward_editor.tscn
```

---

## Task 1: 更新 MissionData 数据结构

**Files:**
- Modify: `scripts/data/mission_data.gd`
- Test: `tests/mission_editor_data_test.gd`

- [ ] **Step 1: 添加模块启用状态字段**

在 `scripts/data/mission_data.gd` 的 `@export` 区域添加三个新字段：

```gdscript
# 模块启用状态
@export var has_pre_battle: bool = false
@export var has_battle: bool = true
@export var has_post_battle: bool = false
```

位置在 `@export var hint: String = ""` 之后，`@export var pre_battle_lines` 之前。

- [ ] **Step 2: 更新 new_mission 方法**

在 `new_mission()` 方法中添加默认值初始化：

```gdscript
func new_mission() -> void:
    mission_id = "mission_%d" % Time.get_unix_time_from_system()
    mission_name = "新任务"
    mission_type = "主线"
    briefing = ""
    hint = ""
    has_pre_battle = false
    has_battle = true
    has_post_battle = false
    pre_battle_lines = []
    post_battle_lines = []
    battle_id = ""
    enemy_entries = []
    event_configs = []
    rewards = []
```

- [ ] **Step 3: 更新测试文件**

更新 `tests/mission_editor_data_test.gd`，添加新字段测试：

```gdscript
# 在 test_new_mission_defaults 方法中添加断言
assert(data.has_pre_battle == false, "has_pre_battle should default to false")
assert(data.has_battle == true, "has_battle should default to true")
assert(data.has_post_battle == false, "has_post_battle should default to false")

# 添加新测试方法
func test_module_flags_persistence():
    var data := MissionData.new()
    data.new_mission()
    data.has_pre_battle = true
    data.has_post_battle = true
    assert(data.has_pre_battle == true, "has_pre_battle should be true")
    assert(data.has_battle == true, "has_battle should remain true")
    assert(data.has_post_battle == true, "has_post_battle should be true")
    print("test_module_flags_persistence passed")
```

- [ ] **Step 4: 运行测试验证**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/mission_editor_data_test.gd`
Expected: 所有测试通过

- [ ] **Step 5: 提交**

```bash
git add scripts/data/mission_data.gd tests/mission_editor_data_test.gd
git commit -m "feat: add module enable flags to MissionData"
```

---

## Task 2: 创建 StoryEditor 组件

**Files:**
- Create: `scripts/mission_editor/components/story_editor.gd`
- Create: `scenes/mission_editor/components/story_editor.tscn`
- Test: `tests/mission_editor_story_editor_test.gd`

- [ ] **Step 1: 创建组件目录**

```bash
mkdir -p scripts/mission_editor/components
mkdir -p scenes/mission_editor/components
```

- [ ] **Step 2: 编写 story_editor.gd**

```gdscript
class_name StoryEditor
extends VBoxContainer

signal lines_changed(lines: Array[String])

var _line_editors: Array[LineEdit] = []
var _lines: Array[String] = []

@onready var lines_container: VBoxContainer = $LinesContainer
@onready var add_line_button: Button = $AddLineButton


func _ready() -> void:
    if add_line_button:
        add_line_button.pressed.connect(_on_add_line_pressed)


func set_lines(lines: Array[String]) -> void:
    _lines = lines.duplicate()
    _rebuild_ui()


func get_lines() -> Array[String]:
    var result: Array[String] = []
    for edit in _line_editors:
        result.append(edit.text)
    return result


func _rebuild_ui() -> void:
    if lines_container == null:
        return

    for child in lines_container.get_children():
        child.queue_free()
    _line_editors.clear()

    for i in range(_lines.size()):
        _add_line_editor(_lines[i])

    _add_line_editor("")


func _add_line_editor(text: String) -> void:
    if lines_container == null:
        return

    var hbox := HBoxContainer.new()
    hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var line_num := Label.new()
    line_num.text = "%d." % (_line_editors.size() + 1)
    line_num.custom_minimum_size.x = 30

    var edit := LineEdit.new()
    edit.text = text
    edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    edit.text_changed.connect(_on_line_text_changed.bind(edit))

    var up_btn := Button.new()
    up_btn.text = "↑"
    up_btn.custom_minimum_size.x = 30
    up_btn.pressed.connect(_move_line_up.bind(edit))

    var down_btn := Button.new()
    down_btn.text = "↓"
    down_btn.custom_minimum_size.x = 30
    down_btn.pressed.connect(_move_line_down.bind(edit))

    var del_btn := Button.new()
    del_btn.text = "×"
    del_btn.custom_minimum_size.x = 30
    del_btn.pressed.connect(_delete_line.bind(edit, hbox))

    hbox.add_child(line_num)
    hbox.add_child(edit)
    hbox.add_child(up_btn)
    hbox.add_child(down_btn)
    hbox.add_child(del_btn)

    lines_container.add_child(hbox)
    _line_editors.append(edit)


func _on_add_line_pressed() -> void:
    _add_line_editor("")
    _emit_changed()


func _on_line_text_changed(_new_text: String, _edit: LineEdit) -> void:
    _emit_changed()


func _move_line_up(edit: LineEdit) -> void:
    var index := _line_editors.find(edit)
    if index <= 0:
        return

    var hbox := edit.get_parent() as HBoxContainer
    if hbox == null:
        return

    lines_container.move_child(hbox, index - 1)
    _line_editors[index] = _line_editors[index - 1]
    _line_editors[index - 1] = edit
    _refresh_line_numbers()
    _emit_changed()


func _move_line_down(edit: LineEdit) -> void:
    var index := _line_editors.find(edit)
    if index < 0 or index >= _line_editors.size() - 1:
        return

    var hbox := edit.get_parent() as HBoxContainer
    if hbox == null:
        return

    lines_container.move_child(hbox, index + 1)
    _line_editors[index] = _line_editors[index + 1]
    _line_editors[index + 1] = edit
    _refresh_line_numbers()
    _emit_changed()


func _delete_line(edit: LineEdit, hbox: HBoxContainer) -> void:
    var index := _line_editors.find(edit)
    if index >= 0:
        _line_editors.remove_at(index)
    hbox.queue_free()
    _refresh_line_numbers()
    _emit_changed()


func _refresh_line_numbers() -> void:
    for i in range(_line_editors.size()):
        var edit := _line_editors[i]
        var hbox := edit.get_parent() as HBoxContainer
        if hbox and hbox.get_child_count() > 0:
            var label := hbox.get_child(0) as Label
            if label:
                label.text = "%d." % (i + 1)


func _emit_changed() -> void:
    lines_changed.emit(get_lines())
```

- [ ] **Step 3: 创建 story_editor.tscn**

```gdscript
[gd_scene load_steps=2 format=3 uid="uid://story_editor_comp"]

[ext_resource type="Script" path="res://scripts/mission_editor/components/story_editor.gd" id="1"]

[node name="StoryEditor" type="VBoxContainer"]
script = ExtResource("1")

[node name="LinesContainer" type="VBoxContainer" parent="."]
layout_mode = 2

[node name="AddLineButton" type="Button" parent="."]
layout_mode = 2
text = "+ 添加行"
```

- [ ] **Step 4: 编写测试**

创建 `tests/mission_editor_story_editor_test.gd`:

```gdscript
extends "res://tests/test_base.gd"

const StoryEditor := preload("res://scripts/mission_editor/components/story_editor.gd")


func test_story_editor_instantiation():
    var editor := StoryEditor.new()
    assert(editor != null, "StoryEditor should instantiate")
    editor.free()
    print("test_story_editor_instantiation passed")


func test_set_and_get_lines():
    var editor := StoryEditor.new()
    var lines: Array[String] = ["第一行", "第二行", "第三行"]
    editor.set_lines(lines)
    var result := editor.get_lines()
    assert(result.size() == 3, "Should have 3 lines")
    assert(result[0] == "第一行", "First line should match")
    assert(result[1] == "第二行", "Second line should match")
    assert(result[2] == "第三行", "Third line should match")
    editor.free()
    print("test_set_and_get_lines passed")


func test_empty_lines():
    var editor := StoryEditor.new()
    var lines: Array[String] = []
    editor.set_lines(lines)
    var result := editor.get_lines()
    assert(result.size() == 0, "Empty input should result in empty output")
    editor.free()
    print("test_empty_lines passed")
```

- [ ] **Step 5: 运行测试验证**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/mission_editor_story_editor_test.gd`
Expected: 所有测试通过

- [ ] **Step 6: 提交**

```bash
git add scripts/mission_editor/components/story_editor.gd scenes/mission_editor/components/story_editor.tscn tests/mission_editor_story_editor_test.gd
git commit -m "feat: add StoryEditor component"
```

---

## Task 3: 创建 RewardEditor 组件

**Files:**
- Create: `scripts/mission_editor/components/reward_editor.gd`
- Create: `scenes/mission_editor/components/reward_editor.tscn`
- Test: `tests/mission_editor_reward_editor_test.gd`

- [ ] **Step 1: 编写 reward_editor.gd**

```gdscript
class_name RewardEditor
extends VBoxContainer

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")

signal rewards_changed(rewards: Array[Dictionary])

var _rewards: Array[Dictionary] = []
var _reward_rows: Array[HBoxContainer] = []

@onready var rewards_container: VBoxContainer = $RewardsContainer
@onready var add_button: Button = $AddButton


func _ready() -> void:
    if add_button:
        add_button.pressed.connect(_on_add_pressed)


func set_rewards(rewards: Array[Dictionary]) -> void:
    _rewards = rewards.duplicate(true)
    _rebuild_ui()


func get_rewards() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for row in _reward_rows:
        if row.get_child_count() < 2:
            continue
        var type_select := row.get_child(0) as OptionButton
        var value_edit := row.get_child(1) as LineEdit
        result.append({
            "type": MISSION_DATA.REWARD_TYPES[type_select.selected] if type_select.selected >= 0 else "金币",
            "value": value_edit.text.to_int() if value_edit.text.is_valid_int() else 0
        })
    return result


func _rebuild_ui() -> void:
    if rewards_container == null:
        return

    for child in rewards_container.get_children():
        child.queue_free()
    _reward_rows.clear()

    for reward in _rewards:
        _add_reward_row(reward.get("type", "金币"), reward.get("value", 0))


func _add_reward_row(reward_type: String, value: int) -> void:
    if rewards_container == null:
        return

    var hbox := HBoxContainer.new()

    var type_select := OptionButton.new()
    for rtype in MISSION_DATA.REWARD_TYPES:
        type_select.add_item(rtype)
    var type_idx := MISSION_DATA.REWARD_TYPES.find(reward_type)
    if type_idx >= 0:
        type_select.selected = type_idx
    type_select.item_selected.connect(_on_type_selected)

    var value_edit := LineEdit.new()
    value_edit.text = str(value)
    value_edit.custom_minimum_size.x = 80
    value_edit.text_changed.connect(_on_value_changed)

    var del_btn := Button.new()
    del_btn.text = "×"
    del_btn.custom_minimum_size.x = 30
    del_btn.pressed.connect(_delete_row.bind(hbox))

    hbox.add_child(type_select)
    hbox.add_child(value_edit)
    hbox.add_child(del_btn)

    rewards_container.add_child(hbox)
    _reward_rows.append(hbox)


func _on_add_pressed() -> void:
    _add_reward_row("金币", 0)
    _emit_changed()


func _on_type_selected(_index: int) -> void:
    _emit_changed()


func _on_value_changed(_new_text: String) -> void:
    _emit_changed()


func _delete_row(hbox: HBoxContainer) -> void:
    var index := _reward_rows.find(hbox)
    if index >= 0:
        _reward_rows.remove_at(index)
    hbox.queue_free()
    _emit_changed()


func _emit_changed() -> void:
    rewards_changed.emit(get_rewards())
```

- [ ] **Step 2: 创建 reward_editor.tscn**

```gdscript
[gd_scene load_steps=2 format=3 uid="uid://reward_editor_comp"]

[ext_resource type="Script" path="res://scripts/mission_editor/components/reward_editor.gd" id="1"]

[node name="RewardEditor" type="VBoxContainer"]
script = ExtResource("1")

[node name="RewardsContainer" type="VBoxContainer" parent="."]
layout_mode = 2

[node name="AddButton" type="Button" parent="."]
layout_mode = 2
text = "+ 添加收益"
```

- [ ] **Step 3: 编写测试**

创建 `tests/mission_editor_reward_editor_test.gd`:

```gdscript
extends "res://tests/test_base.gd"

const RewardEditor := preload("res://scripts/mission_editor/components/reward_editor.gd")


func test_reward_editor_instantiation():
    var editor := RewardEditor.new()
    assert(editor != null, "RewardEditor should instantiate")
    editor.free()
    print("test_reward_editor_instantiation passed")


func test_set_and_get_rewards():
    var editor := RewardEditor.new()
    var rewards: Array[Dictionary] = [
        {"type": "金币", "value": 100},
        {"type": "经验", "value": 50}
    ]
    editor.set_rewards(rewards)
    var result := editor.get_rewards()
    assert(result.size() == 2, "Should have 2 rewards")
    assert(result[0]["type"] == "金币", "First reward type should be 金币")
    assert(result[0]["value"] == 100, "First reward value should be 100")
    assert(result[1]["type"] == "经验", "Second reward type should be 经验")
    assert(result[1]["value"] == 50, "Second reward value should be 50")
    editor.free()
    print("test_set_and_get_rewards passed")


func test_empty_rewards():
    var editor := RewardEditor.new()
    var rewards: Array[Dictionary] = []
    editor.set_rewards(rewards)
    var result := editor.get_rewards()
    assert(result.size() == 0, "Empty input should result in empty output")
    editor.free()
    print("test_empty_rewards passed")
```

- [ ] **Step 4: 运行测试验证**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/mission_editor_reward_editor_test.gd`
Expected: 所有测试通过

- [ ] **Step 5: 提交**

```bash
git add scripts/mission_editor/components/reward_editor.gd scenes/mission_editor/components/reward_editor.tscn tests/mission_editor_reward_editor_test.gd
git commit -m "feat: add RewardEditor component"
```

---

## Task 4: 创建 EventList 组件

**Files:**
- Create: `scripts/mission_editor/components/event_list.gd`
- Create: `scenes/mission_editor/components/event_list.tscn`
- Test: `tests/mission_editor_event_list_test.gd`

- [ ] **Step 1: 编写 event_list.gd**

```gdscript
class_name EventList
extends VBoxContainer

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")

signal events_changed(events: Array[Dictionary])

var _events: Array[Dictionary] = []
var _event_rows: Array[HBoxContainer] = []

@onready var events_container: VBoxContainer = $EventsContainer
@onready var add_button: Button = $AddButton


func _ready() -> void:
    if add_button:
        add_button.pressed.connect(_on_add_pressed)


func set_events(events: Array[Dictionary]) -> void:
    _events = events.duplicate(true)
    _rebuild_ui()


func get_events() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for row in _event_rows:
        if row.get_child_count() < 2:
            continue
        var trigger_select := row.get_child(0) as OptionButton
        var anchor_select := row.get_child(1) as OptionButton
        var presets := MISSION_DATA.TRIGGER_PRESETS.keys()
        result.append({
            "event_id": "evt_custom",
            "trigger_preset": presets[trigger_select.selected] if trigger_select.selected >= 0 else "elapsed_15",
            "spawn_anchor": MISSION_DATA.SPAWN_ANCHORS[anchor_select.selected] if anchor_select.selected >= 0 else "right_flank"
        })
    return result


func _rebuild_ui() -> void:
    if events_container == null:
        return

    for child in events_container.get_children():
        child.queue_free()
    _event_rows.clear()

    for evt in _events:
        _add_event_row(evt.get("trigger_preset", "elapsed_15"), evt.get("spawn_anchor", "right_flank"))


func _add_event_row(trigger_preset: String, spawn_anchor: String) -> void:
    if events_container == null:
        return

    var presets := MISSION_DATA.TRIGGER_PRESETS.keys()

    var hbox := HBoxContainer.new()

    var trigger_select := OptionButton.new()
    for preset in presets:
        trigger_select.add_item(preset)
    var trigger_idx := presets.find(trigger_preset)
    if trigger_idx >= 0:
        trigger_select.selected = trigger_idx
    trigger_select.item_selected.connect(_on_selection_changed)

    var anchor_select := OptionButton.new()
    for anchor in MISSION_DATA.SPAWN_ANCHORS:
        anchor_select.add_item(anchor)
    var anchor_idx := MISSION_DATA.SPAWN_ANCHORS.find(spawn_anchor)
    if anchor_idx >= 0:
        anchor_select.selected = anchor_idx
    anchor_select.item_selected.connect(_on_selection_changed)

    var del_btn := Button.new()
    del_btn.text = "×"
    del_btn.custom_minimum_size.x = 30
    del_btn.pressed.connect(_delete_row.bind(hbox))

    hbox.add_child(trigger_select)
    hbox.add_child(anchor_select)
    hbox.add_child(del_btn)

    events_container.add_child(hbox)
    _event_rows.append(hbox)


func _on_add_pressed() -> void:
    _add_event_row("elapsed_15", "right_flank")
    _emit_changed()


func _on_selection_changed(_index: int) -> void:
    _emit_changed()


func _delete_row(hbox: HBoxContainer) -> void:
    var index := _event_rows.find(hbox)
    if index >= 0:
        _event_rows.remove_at(index)
    hbox.queue_free()
    _emit_changed()


func _emit_changed() -> void:
    events_changed.emit(get_events())
```

- [ ] **Step 2: 创建 event_list.tscn**

```gdscript
[gd_scene load_steps=2 format=3 uid="uid://event_list_comp"]

[ext_resource type="Script" path="res://scripts/mission_editor/components/event_list.gd" id="1"]

[node name="EventList" type="VBoxContainer"]
script = ExtResource("1")

[node name="EventsContainer" type="VBoxContainer" parent="."]
layout_mode = 2

[node name="AddButton" type="Button" parent="."]
layout_mode = 2
text = "+ 添加事件"
```

- [ ] **Step 3: 编写测试**

创建 `tests/mission_editor_event_list_test.gd`:

```gdscript
extends "res://tests/test_base.gd"

const EventList := preload("res://scripts/mission_editor/components/event_list.gd")


func test_event_list_instantiation():
    var lst := EventList.new()
    assert(lst != null, "EventList should instantiate")
    lst.free()
    print("test_event_list_instantiation passed")


func test_set_and_get_events():
    var lst := EventList.new()
    var events: Array[Dictionary] = [
        {"event_id": "evt_custom", "trigger_preset": "elapsed_30", "spawn_anchor": "left_flank"}
    ]
    lst.set_events(events)
    var result := lst.get_events()
    assert(result.size() == 1, "Should have 1 event")
    assert(result[0]["trigger_preset"] == "elapsed_30", "Trigger preset should match")
    assert(result[0]["spawn_anchor"] == "left_flank", "Spawn anchor should match")
    lst.free()
    print("test_set_and_get_events passed")


func test_empty_events():
    var lst := EventList.new()
    var events: Array[Dictionary] = []
    lst.set_events(events)
    var result := lst.get_events()
    assert(result.size() == 0, "Empty input should result in empty output")
    lst.free()
    print("test_empty_events passed")
```

- [ ] **Step 4: 运行测试验证**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/mission_editor_event_list_test.gd`
Expected: 所有测试通过

- [ ] **Step 5: 提交**

```bash
git add scripts/mission_editor/components/event_list.gd scenes/mission_editor/components/event_list.tscn tests/mission_editor_event_list_test.gd
git commit -m "feat: add EventList component"
```

---

## Task 5: 创建 BattlefieldPreview 组件（拖拽目标区）

**Files:**
- Create: `scripts/mission_editor/components/battlefield_preview.gd`
- Create: `scripts/mission_editor/components/enemy_drag_item.gd`
- Create: `scripts/mission_editor/components/placed_enemy_icon.gd`
- Create: `scenes/mission_editor/components/battlefield_preview.tscn`
- Create: `scenes/mission_editor/components/enemy_drag_item.tscn`
- Create: `scenes/mission_editor/components/placed_enemy_icon.tscn`
- Test: `tests/mission_editor_battlefield_preview_test.gd`

- [ ] **Step 1: 编写 placed_enemy_icon.gd**

```gdscript
class_name PlacedEnemyIcon
extends Control

signal delete_requested(icon: PlacedEnemyIcon)

var unit_id: String = ""
var spawn_anchor: String = ""

@onready var icon_label: Label = $IconLabel
@onready var delete_btn: Button = $DeleteButton


func _ready() -> void:
    if delete_btn:
        delete_btn.pressed.connect(_on_delete_pressed)


func setup(p_unit_id: String, p_spawn_anchor: String, display_name: String) -> void:
    unit_id = p_unit_id
    spawn_anchor = p_spawn_anchor
    if icon_label:
        icon_label.text = display_name


func _on_delete_pressed() -> void:
    delete_requested.emit(self)
```

- [ ] **Step 2: 创建 placed_enemy_icon.tscn**

```gdscript
[gd_scene load_steps=2 format=3 uid="uid://placed_enemy_icon_comp"]

[ext_resource type="Script" path="res://scripts/mission_editor/components/placed_enemy_icon.gd" id="1"]

[node name="PlacedEnemyIcon" type="Control"]
custom_minimum_size = Vector2(60, 60)
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.3, 0.3, 0.5, 0.8)

[node name="IconLabel" type="Label" parent="."]
layout_mode = 1
anchors_preset = 14
anchor_top = 0.5
anchor_right = 1.0
anchor_bottom = 0.5
grow_horizontal = 2
grow_vertical = 2
horizontal_alignment = 1
vertical_alignment = 1

[node name="DeleteButton" type="Button" parent="."]
layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -20
offset_top = -5
offset_right = -5
offset_bottom = 10
text = "×"
```

- [ ] **Step 3: 编写 enemy_drag_item.gd**

```gdscript
class_name EnemyDragItem
extends HBoxContainer

var unit_id: String = ""
var display_name: String = ""

@onready var name_label: Label = $NameLabel
@onready var drag_button: Button = $DragButton


func _ready() -> void:
    drag_button.gui_input.connect(_on_drag_input)


func setup(p_unit_id: String, p_display_name: String) -> void:
    unit_id = p_unit_id
    display_name = p_display_name
    if name_label:
        name_label.text = p_display_name


func _on_drag_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var drag_data := {"unit_id": unit_id, "display_name": display_name}
        drag_button.set_drag_forwarding(_get_drag_data, Callable(), Callable())


func _get_drag_data(at_position: Vector2) -> Variant:
    var preview := Label.new()
    preview.text = display_name
    preview.add_theme_color_override("font_color", Color.WHITE)
    preview.add_theme_stylebox_override("normal", _create_preview_style())
    drag_button.set_drag_preview(preview)
    return {"unit_id": unit_id, "display_name": display_name}


func _create_preview_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.2, 0.2, 0.6, 0.9)
    style.border_color = Color(0.4, 0.4, 0.8)
    style.set_border_width_all(2)
    style.set_content_margin_all(4)
    return style
```

- [ ] **Step 4: 创建 enemy_drag_item.tscn**

```gdscript
[gd_scene load_steps=2 format=3 uid="uid://enemy_drag_item_comp"]

[ext_resource type="Script" path="res://scripts/mission_editor/components/enemy_drag_item.gd" id="1"]

[node name="EnemyDragItem" type="HBoxContainer"]
script = ExtResource("1")

[node name="NameLabel" type="Label" parent="."]
layout_mode = 2
size_flags_horizontal = 3

[node name="DragButton" type="Button" parent="."]
layout_mode = 2
text = "⋮⋮"
```

- [ ] **Step 5: 编写 battlefield_preview.gd**

```gdscript
class_name BattlefieldPreview
extends Control

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")
const PLACED_ENEMY_ICON := preload("res://scenes/mission_editor/components/placed_enemy_icon.tscn")

signal enemies_changed(enemies: Array[Dictionary])

var _placed_enemies: Array[Dictionary] = []
var _anchor_positions: Dictionary = {}

@onready var preview_area: Control = $PreviewArea


func _ready() -> void:
    _calculate_anchor_positions()


func _calculate_anchor_positions() -> void:
    if preview_area == null:
        return
    var rect := preview_area.get_rect()
    var w := rect.size.x
    var h := rect.size.y

    # 左侧锚点（敌人出生区域）
    _anchor_positions = {
        "right_flank": Vector2(w * 0.85, h * 0.5),
        "right_top": Vector2(w * 0.85, h * 0.25),
        "right_bottom": Vector2(w * 0.85, h * 0.75),
        "left_flank": Vector2(w * 0.15, h * 0.5),
        "left_top": Vector2(w * 0.15, h * 0.25),
        "left_bottom": Vector2(w * 0.15, h * 0.75)
    }


func set_enemies(enemies: Array[Dictionary]) -> void:
    _placed_enemies = enemies.duplicate(true)
    _rebuild_icons()


func get_enemies() -> Array[Dictionary]:
    return _placed_enemies.duplicate(true)


func _rebuild_icons() -> void:
    if preview_area == null:
        return

    for child in preview_area.get_children():
        if child is PlacedEnemyIcon:
            child.queue_free()

    for enemy in _placed_enemies:
        _create_icon(enemy)


func _create_icon(enemy: Dictionary) -> void:
    var icon := PLACED_ENEMY_ICON.instantiate() as PlacedEnemyIcon
    icon.setup(enemy.get("unit_id", ""), enemy.get("spawn_anchor", "right_flank"), enemy.get("display_name", enemy.get("unit_id", "")))
    icon.delete_requested.connect(_on_delete_requested)

    var anchor := enemy.get("spawn_anchor", "right_flank")
    var pos := _anchor_positions.get(anchor, Vector2(100, 100))
    icon.position = pos - Vector2(30, 30)

    preview_area.add_child(icon)


func _on_delete_requested(icon: PlacedEnemyIcon) -> void:
    var index := -1
    for i in range(_placed_enemies.size()):
        if _placed_enemies[i].get("unit_id") == icon.unit_id and _placed_enemies[i].get("spawn_anchor") == icon.spawn_anchor:
            index = i
            break
    if index >= 0:
        _placed_enemies.remove_at(index)
        icon.queue_free()
        _emit_changed()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    return data is Dictionary and data.has("unit_id")


func _drop_data(at_position: Vector2, data: Variant) -> void:
    if not data is Dictionary:
        return

    var unit_id: String = data.get("unit_id", "")
    var display_name: String = data.get("display_name", unit_id)

    if unit_id.is_empty():
        return

    var anchor := _find_nearest_anchor(at_position)
    _placed_enemies.append({
        "unit_id": unit_id,
        "spawn_anchor": anchor,
        "display_name": display_name
    })
    _create_icon(_placed_enemies.back())
    _emit_changed()


func _find_nearest_anchor(pos: Vector2) -> String:
    var nearest := "right_flank"
    var min_dist := 999999.0

    for anchor in _anchor_positions.keys():
        var anchor_pos := _anchor_positions[anchor] as Vector2
        var dist := pos.distance_to(anchor_pos)
        if dist < min_dist:
            min_dist = dist
            nearest = anchor

    return nearest


func _emit_changed() -> void:
    enemies_changed.emit(_placed_enemies.duplicate(true))
```

- [ ] **Step 6: 创建 battlefield_preview.tscn**

```gdscript
[gd_scene load_steps=2 format=3 uid="uid://battlefield_preview_comp"]

[ext_resource type="Script" path="res://scripts/mission_editor/components/battlefield_preview.gd" id="1"]

[node name="BattlefieldPreview" type="Control"]
custom_minimum_size = Vector2(300, 200)
script = ExtResource("1")

[node name="PreviewArea" type="ColorRect" parent="."]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.15, 0.15, 0.2, 1)
```

- [ ] **Step 7: 编写测试**

创建 `tests/mission_editor_battlefield_preview_test.gd`:

```gdscript
extends "res://tests/test_base.gd"

const BattlefieldPreview := preload("res://scripts/mission_editor/components/battlefield_preview.gd")


func test_battlefield_preview_instantiation():
    var preview := BattlefieldPreview.new()
    assert(preview != null, "BattlefieldPreview should instantiate")
    preview.free()
    print("test_battlefield_preview_instantiation passed")


func test_set_and_get_enemies():
    var preview := BattlefieldPreview.new()
    var enemies: Array[Dictionary] = [
        {"unit_id": "enemy_wandering_demon", "spawn_anchor": "right_flank", "display_name": "游荡魔"}
    ]
    preview.set_enemies(enemies)
    var result := preview.get_enemies()
    assert(result.size() == 1, "Should have 1 enemy")
    assert(result[0]["unit_id"] == "enemy_wandering_demon", "Unit ID should match")
    assert(result[0]["spawn_anchor"] == "right_flank", "Spawn anchor should match")
    preview.free()
    print("test_set_and_get_enemies passed")


func test_empty_enemies():
    var preview := BattlefieldPreview.new()
    var enemies: Array[Dictionary] = []
    preview.set_enemies(enemies)
    var result := preview.get_enemies()
    assert(result.size() == 0, "Empty input should result in empty output")
    preview.free()
    print("test_empty_enemies passed")
```

- [ ] **Step 8: 运行测试验证**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/mission_editor_battlefield_preview_test.gd`
Expected: 所有测试通过

- [ ] **Step 9: 提交**

```bash
git add scripts/mission_editor/components/battlefield_preview.gd scripts/mission_editor/components/enemy_drag_item.gd scripts/mission_editor/components/placed_enemy_icon.gd scenes/mission_editor/components/battlefield_preview.tscn scenes/mission_editor/components/enemy_drag_item.tscn scenes/mission_editor/components/placed_enemy_icon.tscn tests/mission_editor_battlefield_preview_test.gd
git commit -m "feat: add BattlefieldPreview with drag-drop support"
```

---

## Task 6: 创建 BattleEditor 组件

**Files:**
- Create: `scripts/mission_editor/components/battle_editor.gd`
- Create: `scenes/mission_editor/components/battle_editor.tscn`
- Test: `tests/mission_editor_battle_editor_test.gd`

- [ ] **Step 1: 编写 battle_editor.gd**

```gdscript
class_name BattleEditor
extends VBoxContainer

const BATTLE_CONTENT := preload("res://autoload/battle_content.gd")
const BattlefieldPreview := preload("res://scenes/mission_editor/components/battlefield_preview.tscn")
const EventList := preload("res://scenes/mission_editor/components/event_list.tscn")
const EnemyDragItem := preload("res://scenes/mission_editor/components/enemy_drag_item.tscn")

signal config_changed(enemy_entries: Array[Dictionary], event_configs: Array[Dictionary])

var _enemy_entries: Array[Dictionary] = []
var _event_configs: Array[Dictionary] = []

@onready var enemy_list_container: VBoxContainer = $HBoxContainer/LeftPanel/EnemyListContainer
@onready var battlefield_preview: BattlefieldPreview = $HBoxContainer/BattlefieldPreview
@onready var event_list: EventList = $EventListSection/EventList


func _ready() -> void:
    _populate_enemy_list()
    _connect_signals()


func set_config(enemy_entries: Array[Dictionary], event_configs: Array[Dictionary]) -> void:
    _enemy_entries = enemy_entries.duplicate(true)
    _event_configs = event_configs.duplicate(true)

    if battlefield_preview:
        battlefield_preview.set_enemies(_enemy_entries)
    if event_list:
        event_list.set_events(_event_configs)


func get_config() -> Dictionary:
    return {
        "enemy_entries": battlefield_preview.get_enemies() if battlefield_preview else [],
        "event_configs": event_list.get_events() if event_list else []
    }


func _populate_enemy_list() -> void:
    if enemy_list_container == null:
        return

    for child in enemy_list_container.get_children():
        child.queue_free()

    var content := BATTLE_CONTENT.new()
    var enemy_ids := ["enemy_wandering_demon", "enemy_animated_machine", "enemy_hunter_fiend"]

    for enemy_id in enemy_ids:
        var enemy: Dictionary = content.get_unit(enemy_id)
        if enemy.is_empty():
            continue

        var item := EnemyDragItem.instantiate() as EnemyDragItem
        item.setup(enemy_id, enemy.get("display_name", enemy_id))
        enemy_list_container.add_child(item)

    content.free()


func _connect_signals() -> void:
    if battlefield_preview:
        battlefield_preview.enemies_changed.connect(_on_enemies_changed)
    if event_list:
        event_list.events_changed.connect(_on_events_changed)


func _on_enemies_changed(enemies: Array[Dictionary]) -> void:
    _enemy_entries = enemies
    _emit_changed()


func _on_events_changed(events: Array[Dictionary]) -> void:
    _event_configs = events
    _emit_changed()


func _emit_changed() -> void:
    var config := get_config()
    config_changed.emit(config.enemy_entries, config.event_configs)
```

- [ ] **Step 2: 创建 battle_editor.tscn**

```gdscript
[gd_scene load_steps=3 format=3 uid="uid://battle_editor_comp"]

[ext_resource type="Script" path="res://scripts/mission_editor/components/battle_editor.gd" id="1"]
[ext_resource type="PackedScene" uid="uid://battlefield_preview_comp" path="res://scenes/mission_editor/components/battlefield_preview.tscn" id="2"]

[node name="BattleEditor" type="VBoxContainer"]
script = ExtResource("1")

[node name="HBoxContainer" type="HBoxContainer" parent="."]
layout_mode = 2

[node name="LeftPanel" type="VBoxContainer" parent="HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="EnemyListLabel" type="Label" parent="HBoxContainer/LeftPanel"]
layout_mode = 2
text = "敌人列表（拖拽到右侧战场）"

[node name="EnemyListContainer" type="VBoxContainer" parent="HBoxContainer/LeftPanel"]
layout_mode = 2

[node name="BattlefieldPreview" parent="HBoxContainer" instance=ExtResource("2")]
layout_mode = 2
size_flags_horizontal = 3

[node name="EventListSection" type="VBoxContainer" parent="."]
layout_mode = 2

[node name="EventListLabel" type="Label" parent="EventListSection"]
layout_mode = 2
text = "事件配置"

[node name="EventList" type="VBoxContainer" parent="EventListSection"]
layout_mode = 2
```

- [ ] **Step 3: 编写测试**

创建 `tests/mission_editor_battle_editor_test.gd`:

```gdscript
extends "res://tests/test_base.gd"

const BattleEditor := preload("res://scripts/mission_editor/components/battle_editor.gd")


func test_battle_editor_instantiation():
    var editor := BattleEditor.new()
    assert(editor != null, "BattleEditor should instantiate")
    editor.free()
    print("test_battle_editor_instantiation passed")


func test_set_and_get_config():
    var editor := BattleEditor.new()
    var enemies: Array[Dictionary] = [
        {"unit_id": "enemy_wandering_demon", "spawn_anchor": "right_flank", "display_name": "游荡魔"}
    ]
    var events: Array[Dictionary] = [
        {"event_id": "evt_custom", "trigger_preset": "elapsed_15", "spawn_anchor": "left_flank"}
    ]
    editor.set_config(enemies, events)
    var config := editor.get_config()
    assert(config["enemy_entries"].size() == 1, "Should have 1 enemy")
    assert(config["event_configs"].size() == 1, "Should have 1 event")
    editor.free()
    print("test_set_and_get_config passed")
```

- [ ] **Step 4: 运行测试验证**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/mission_editor_battle_editor_test.gd`
Expected: 所有测试通过

- [ ] **Step 5: 提交**

```bash
git add scripts/mission_editor/components/battle_editor.gd scenes/mission_editor/components/battle_editor.tscn tests/mission_editor_battle_editor_test.gd
git commit -m "feat: add BattleEditor component"
```

---

## Task 7: 创建 TaskPanel 组件

**Files:**
- Create: `scripts/mission_editor/components/task_panel.gd`
- Create: `scenes/mission_editor/components/task_panel.tscn`
- Test: `tests/mission_editor_task_panel_test.gd`

- [ ] **Step 1: 编写 task_panel.gd**

```gdscript
class_name TaskPanel
extends VBoxContainer

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")
const RewardEditorScene := preload("res://scenes/mission_editor/components/reward_editor.tscn")

signal data_changed(field: String, value: Variant)

@onready var mission_name_edit: LineEdit = $MissionNameRow/MissionNameEdit
@onready var mission_type_select: OptionButton = $MissionTypeRow/MissionTypeSelect
@onready var briefing_edit: TextEdit = $BriefingEdit
@onready var hint_edit: TextEdit = $HintEdit
@onready var reward_editor: RewardEditor = $RewardSection/RewardEditor


func _ready() -> void:
    _populate_type_select()
    _connect_signals()


func _populate_type_select() -> void:
    if mission_type_select == null:
        return
    mission_type_select.clear()
    for mtype in MISSION_DATA.MISSION_TYPES:
        mission_type_select.add_item(mtype)


func set_data(data: MISSION_DATA) -> void:
    if mission_name_edit:
        mission_name_edit.text = data.mission_name
    if mission_type_select:
        var idx := MISSION_DATA.MISSION_TYPES.find(data.mission_type)
        if idx >= 0:
            mission_type_select.selected = idx
    if briefing_edit:
        briefing_edit.text = data.briefing
    if hint_edit:
        hint_edit.text = data.hint
    if reward_editor:
        reward_editor.set_rewards(data.rewards)


func apply_to_data(data: MISSION_DATA) -> void:
    if mission_name_edit:
        data.mission_name = mission_name_edit.text
    if mission_type_select and mission_type_select.selected >= 0:
        data.mission_type = MISSION_DATA.MISSION_TYPES[mission_type_select.selected]
    if briefing_edit:
        data.briefing = briefing_edit.text
    if hint_edit:
        data.hint = hint_edit.text
    if reward_editor:
        data.rewards = reward_editor.get_rewards()


func _connect_signals() -> void:
    if mission_name_edit:
        mission_name_edit.text_changed.connect(_on_name_changed)
    if mission_type_select:
        mission_type_select.item_selected.connect(_on_type_selected)
    if briefing_edit:
        briefing_edit.text_changed.connect(_on_briefing_changed)
    if hint_edit:
        hint_edit.text_changed.connect(_on_hint_changed)


func _on_name_changed(new_text: String) -> void:
    data_changed.emit("mission_name", new_text)


func _on_type_selected(index: int) -> void:
    data_changed.emit("mission_type", MISSION_DATA.MISSION_TYPES[index])


func _on_briefing_changed() -> void:
    data_changed.emit("briefing", briefing_edit.text)


func _on_hint_changed() -> void:
    data_changed.emit("hint", hint_edit.text)
```

- [ ] **Step 2: 创建 task_panel.tscn**

```gdscript
[gd_scene load_steps=3 format=3 uid="uid://task_panel_comp"]

[ext_resource type="Script" path="res://scripts/mission_editor/components/task_panel.gd" id="1"]
[ext_resource type="PackedScene" uid="uid://reward_editor_comp" path="res://scenes/mission_editor/components/reward_editor.tscn" id="2"]

[node name="TaskPanel" type="VBoxContainer"]
script = ExtResource("1")

[node name="MissionNameRow" type="HBoxContainer" parent="."]
layout_mode = 2

[node name="MissionNameLabel" type="Label" parent="MissionNameRow"]
layout_mode = 2
text = "名称："

[node name="MissionNameEdit" type="LineEdit" parent="MissionNameRow"]
layout_mode = 2
size_flags_horizontal = 3

[node name="MissionTypeRow" type="HBoxContainer" parent="."]
layout_mode = 2

[node name="MissionTypeLabel" type="Label" parent="MissionTypeRow"]
layout_mode = 2
text = "类型："

[node name="MissionTypeSelect" type="OptionButton" parent="MissionTypeRow"]
layout_mode = 2

[node name="BriefingLabel" type="Label" parent="."]
layout_mode = 2
text = "简报："

[node name="BriefingEdit" type="TextEdit" parent="."]
layout_mode = 2
custom_minimum_size = Vector2(0, 80)

[node name="HintLabel" type="Label" parent="."]
layout_mode = 2
text = "提示："

[node name="HintEdit" type="TextEdit" parent="."]
layout_mode = 2
custom_minimum_size = Vector2(0, 60)

[node name="RewardSection" type="VBoxContainer" parent="."]
layout_mode = 2

[node name="RewardLabel" type="Label" parent="RewardSection"]
layout_mode = 2
text = "收益："

[node name="RewardEditor" parent="RewardSection" instance=ExtResource("2")]
layout_mode = 2
```

- [ ] **Step 3: 编写测试**

创建 `tests/mission_editor_task_panel_test.gd`:

```gdscript
extends "res://tests/test_base.gd"

const TaskPanel := preload("res://scripts/mission_editor/components/task_panel.gd")
const MissionData := preload("res://scripts/data/mission_data.gd")


func test_task_panel_instantiation():
    var panel := TaskPanel.new()
    assert(panel != null, "TaskPanel should instantiate")
    panel.free()
    print("test_task_panel_instantiation passed")


func test_set_and_apply_data():
    var panel := TaskPanel.new()
    var data := MissionData.new()
    data.new_mission()
    data.mission_name = "测试任务"
    data.mission_type = "支线"
    data.briefing = "简报内容"
    data.hint = "提示内容"
    data.rewards = [{"type": "金币", "value": 100}]

    panel.set_data(data)
    panel.apply_to_data(data)

    assert(data.mission_name == "测试任务", "Mission name should be preserved")
    assert(data.mission_type == "支线", "Mission type should be preserved")
    assert(data.briefing == "简报内容", "Briefing should be preserved")
    assert(data.hint == "提示内容", "Hint should be preserved")
    panel.free()
    print("test_set_and_apply_data passed")
```

- [ ] **Step 4: 运行测试验证**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/mission_editor_task_panel_test.gd`
Expected: 所有测试通过

- [ ] **Step 5: 提交**

```bash
git add scripts/mission_editor/components/task_panel.gd scenes/mission_editor/components/task_panel.tscn tests/mission_editor_task_panel_test.gd
git commit -m "feat: add TaskPanel component"
```

---

## Task 8: 创建主控制器 MissionEditor

**Files:**
- Create: `scripts/mission_editor/mission_editor.gd`（重写）
- Create: `scenes/mission_editor/mission_editor.tscn`（重写）
- Test: `tests/mission_editor_smoke_test.gd`（更新）

- [ ] **Step 1: 编写新的 mission_editor.gd**

```gdscript
extends Control

const MISSION_DATA := preload("res://scripts/data/mission_data.gd")
const TaskPanelScene := preload("res://scenes/mission_editor/components/task_panel.tscn")
const StoryEditorScene := preload("res://scenes/mission_editor/components/story_editor.tscn")
const BattleEditorScene := preload("res://scenes/mission_editor/components/battle_editor.tscn")

var _current_data: MISSION_DATA
var _is_new_mission: bool = true

@onready var task_panel: TaskPanel = $ScrollContainer/VBoxContainer/TaskPanel
@onready var pre_battle_check: CheckBox = $ScrollContainer/VBoxContainer/ModuleControls/PreBattleCheck
@onready var battle_check: CheckBox = $ScrollContainer/VBoxContainer/ModuleControls/BattleCheck
@onready var post_battle_check: CheckBox = $ScrollContainer/VBoxContainer/ModuleControls/PostBattleCheck
@onready var pre_battle_editor: StoryEditor = $ScrollContainer/VBoxContainer/PreBattleSection/PreBattleEditor
@onready var battle_editor: BattleEditor = $ScrollContainer/VBoxContainer/BattleSection/BattleEditor
@onready var post_battle_editor: StoryEditor = $ScrollContainer/VBoxContainer/PostBattleSection/PostBattleEditor
@onready var pre_battle_section: VBoxContainer = $ScrollContainer/VBoxContainer/PreBattleSection
@onready var battle_section: VBoxContainer = $ScrollContainer/VBoxContainer/BattleSection
@onready var post_battle_section: VBoxContainer = $ScrollContainer/VBoxContainer/PostBattleSection
@onready var save_button: Button = $BottomBar/SaveButton
@onready var new_button: Button = $BottomBar/NewButton
@onready var back_button: Button = $BottomBar/BackButton


func _ready() -> void:
    _connect_signals()
    _new_mission()


func _connect_signals() -> void:
    if pre_battle_check:
        pre_battle_check.toggled.connect(_on_pre_battle_toggled)
    if battle_check:
        battle_check.toggled.connect(_on_battle_toggled)
    if post_battle_check:
        post_battle_check.toggled.connect(_on_post_battle_toggled)
    if save_button:
        save_button.pressed.connect(_on_save_pressed)
    if new_button:
        new_button.pressed.connect(_on_new_pressed)
    if back_button:
        back_button.pressed.connect(_on_back_pressed)


func _new_mission() -> void:
    _current_data = MISSION_DATA.new()
    _current_data.new_mission()
    _is_new_mission = true
    _apply_data_to_ui()


func _apply_data_to_ui() -> void:
    if task_panel:
        task_panel.set_data(_current_data)

    if pre_battle_check:
        pre_battle_check.button_pressed = _current_data.has_pre_battle
    if battle_check:
        battle_check.button_pressed = _current_data.has_battle
    if post_battle_check:
        post_battle_check.button_pressed = _current_data.has_post_battle

    if pre_battle_editor:
        pre_battle_editor.set_lines(_current_data.pre_battle_lines)
    if post_battle_editor:
        post_battle_editor.set_lines(_current_data.post_battle_lines)
    if battle_editor:
        battle_editor.set_config(_current_data.enemy_entries, _current_data.event_configs)

    _update_section_visibility()


func _update_section_visibility() -> void:
    if pre_battle_section:
        pre_battle_section.visible = pre_battle_check.button_pressed if pre_battle_check else false
    if battle_section:
        battle_section.visible = battle_check.button_pressed if battle_check else false
    if post_battle_section:
        post_battle_section.visible = post_battle_check.button_pressed if post_battle_check else false


func _on_pre_battle_toggled(pressed: bool) -> void:
    if pressed and not _can_enable_story(pre_battle_check):
        pre_battle_check.button_pressed = false
        return
    _current_data.has_pre_battle = pressed
    _update_section_visibility()


func _on_battle_toggled(pressed: bool) -> void:
    if not pressed:
        # 取消战斗时，自动取消两个剧情
        pre_battle_check.button_pressed = false
        post_battle_check.button_pressed = false
        _current_data.has_pre_battle = false
        _current_data.has_post_battle = false
    _current_data.has_battle = pressed
    _update_section_visibility()


func _on_post_battle_toggled(pressed: bool) -> void:
    if pressed and not _can_enable_story(post_battle_check):
        post_battle_check.button_pressed = false
        return
    _current_data.has_post_battle = pressed
    _update_section_visibility()


func _can_enable_story(check_box: CheckBox) -> bool:
    # 如果战斗未勾选，且另一个剧情已勾选，则禁止
    if not battle_check.button_pressed:
        if check_box == pre_battle_check and post_battle_check.button_pressed:
            return false
        if check_box == post_battle_check and pre_battle_check.button_pressed:
            return false
    return true


func _on_save_pressed() -> void:
    _sync_ui_to_data()

    if not _current_data.is_valid():
        push_error("Mission data is invalid")
        return

    var mkdir_err := DirAccess.make_dir_recursive_absolute("res://resources/missions/")
    if mkdir_err != OK:
        push_error("Failed to create directory: %s" % mkdir_err)
        return

    var path := "res://resources/missions/%s.tres" % _current_data.mission_id
    var err := ResourceSaver.save(_current_data, path)
    if err != OK:
        push_error("Failed to save mission: %s" % err)
        return

    print("Saved mission to: %s" % path)
    _is_new_mission = false


func _sync_ui_to_data() -> void:
    if task_panel:
        task_panel.apply_to_data(_current_data)

    _current_data.pre_battle_lines = pre_battle_editor.get_lines() if pre_battle_editor else []
    _current_data.post_battle_lines = post_battle_editor.get_lines() if post_battle_editor else []

    if battle_editor:
        var config := battle_editor.get_config()
        _current_data.enemy_entries = config.enemy_entries
        _current_data.event_configs = config.event_configs


func _on_new_pressed() -> void:
    _new_mission()


func _on_back_pressed() -> void:
    var router := get_node_or_null("/root/AppRouter")
    if router:
        router.goto_preparation()


func load_mission(mission_id: String) -> void:
    var path := "res://resources/missions/%s.tres" % mission_id
    var res := load(path)
    if res != null and res is MISSION_DATA:
        _current_data = res
        _is_new_mission = false
        _apply_data_to_ui()
    else:
        push_error("Failed to load mission: %s" % path)
```

- [ ] **Step 2: 创建新的 mission_editor.tscn**

```gdscript
[gd_scene load_steps=5 format=3 uid="uid://mission_editor_scene"]

[ext_resource type="Script" path="res://scripts/mission_editor/mission_editor.gd" id="1"]
[ext_resource type="PackedScene" uid="uid://task_panel_comp" path="res://scenes/mission_editor/components/task_panel.tscn" id="2"]
[ext_resource type="PackedScene" uid="uid://story_editor_comp" path="res://scenes/mission_editor/components/story_editor.tscn" id="3"]
[ext_resource type="PackedScene" uid="uid://battle_editor_comp" path="res://scenes/mission_editor/components/battle_editor.tscn" id="4"]

[node name="MissionEditor" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="ScrollContainer" type="ScrollContainer" parent="."]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_bottom = -50.0

[node name="VBoxContainer" type="VBoxContainer" parent="ScrollContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="TaskPanel" parent="ScrollContainer/VBoxContainer" instance=ExtResource("2")]
layout_mode = 2

[node name="ModuleControls" type="HBoxContainer" parent="ScrollContainer/VBoxContainer"]
layout_mode = 2

[node name="Label" type="Label" parent="ScrollContainer/VBoxContainer/ModuleControls"]
layout_mode = 2
text = "模块控制："

[node name="PreBattleCheck" type="CheckBox" parent="ScrollContainer/VBoxContainer/ModuleControls"]
layout_mode = 2
text = "战前剧情"

[node name="BattleCheck" type="CheckBox" parent="ScrollContainer/VBoxContainer/ModuleControls"]
layout_mode = 2
text = "战斗"

[node name="PostBattleCheck" type="CheckBox" parent="ScrollContainer/VBoxContainer/ModuleControls"]
layout_mode = 2
text = "战后剧情"

[node name="PreBattleSection" type="VBoxContainer" parent="ScrollContainer/VBoxContainer"]
layout_mode = 2

[node name="SectionLabel" type="Label" parent="ScrollContainer/VBoxContainer/PreBattleSection"]
layout_mode = 2
text = "战前剧情"

[node name="PreBattleEditor" parent="ScrollContainer/VBoxContainer/PreBattleSection" instance=ExtResource("3")]
layout_mode = 2

[node name="BattleSection" type="VBoxContainer" parent="ScrollContainer/VBoxContainer"]
layout_mode = 2

[node name="SectionLabel" type="Label" parent="ScrollContainer/VBoxContainer/BattleSection"]
layout_mode = 2
text = "战斗配置"

[node name="BattleEditor" parent="ScrollContainer/VBoxContainer/BattleSection" instance=ExtResource("4")]
layout_mode = 2

[node name="PostBattleSection" type="VBoxContainer" parent="ScrollContainer/VBoxContainer"]
layout_mode = 2

[node name="SectionLabel" type="Label" parent="ScrollContainer/VBoxContainer/PostBattleSection"]
layout_mode = 2
text = "战后剧情"

[node name="PostBattleEditor" parent="ScrollContainer/VBoxContainer/PostBattleSection" instance=ExtResource("3")]
layout_mode = 2

[node name="BottomBar" type="HBoxContainer" parent="."]
layout_mode = 3
anchors_preset = 12
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -50.0

[node name="SaveButton" type="Button" parent="BottomBar"]
layout_mode = 2
text = "保存"

[node name="NewButton" type="Button" parent="BottomBar"]
layout_mode = 2
text = "新建"

[node name="BackButton" type="Button" parent="BottomBar"]
layout_mode = 2
text = "返回准备页"
```

- [ ] **Step 3: 更新 smoke test**

更新 `tests/mission_editor_smoke_test.gd`:

```gdscript
extends "res://tests/test_base.gd"

const MissionEditorScene := preload("res://scenes/mission_editor/mission_editor.tscn")


func test_mission_editor_instantiation():
    var editor := MissionEditorScene.instantiate()
    assert(editor != null, "MissionEditor should instantiate from scene")
    editor.free()
    print("test_mission_editor_instantiation passed")


func test_mission_editor_has_required_nodes():
    var editor := MissionEditorScene.instantiate()
    add_child(editor)

    assert(editor.has_node("ScrollContainer/VBoxContainer/TaskPanel"), "Should have TaskPanel")
    assert(editor.has_node("ScrollContainer/VBoxContainer/ModuleControls/PreBattleCheck"), "Should have PreBattleCheck")
    assert(editor.has_node("ScrollContainer/VBoxContainer/ModuleControls/BattleCheck"), "Should have BattleCheck")
    assert(editor.has_node("ScrollContainer/VBoxContainer/ModuleControls/PostBattleCheck"), "Should have PostBattleCheck")
    assert(editor.has_node("ScrollContainer/VBoxContainer/PreBattleSection"), "Should have PreBattleSection")
    assert(editor.has_node("ScrollContainer/VBoxContainer/BattleSection"), "Should have BattleSection")
    assert(editor.has_node("ScrollContainer/VBoxContainer/PostBattleSection"), "Should have PostBattleSection")
    assert(editor.has_node("BottomBar/SaveButton"), "Should have SaveButton")
    assert(editor.has_node("BottomBar/NewButton"), "Should have NewButton")
    assert(editor.has_node("BottomBar/BackButton"), "Should have BackButton")

    editor.queue_free()
    print("test_mission_editor_has_required_nodes passed")


func test_checkbox_validation():
    var editor := MissionEditorScene.instantiate()
    add_child(editor)

    var pre_check: CheckBox = editor.get_node("ScrollContainer/VBoxContainer/ModuleControls/PreBattleCheck")
    var battle_check: CheckBox = editor.get_node("ScrollContainer/VBoxContainer/ModuleControls/BattleCheck")
    var post_check: CheckBox = editor.get_node("ScrollContainer/VBoxContainer/ModuleControls/PostBattleCheck")

    # 默认状态：战斗勾选，剧情不勾选
    assert(battle_check.button_pressed == true, "Battle should be checked by default")
    assert(pre_check.button_pressed == false, "Pre-battle should be unchecked by default")
    assert(post_check.button_pressed == false, "Post-battle should be unchecked by default")

    # 取消战斗
    battle_check.button_pressed = false
    assert(pre_check.button_pressed == false, "Pre-battle should be auto-unchecked when battle is unchecked")
    assert(post_check.button_pressed == false, "Post-battle should be auto-unchecked when battle is unchecked")

    # 尝试勾选两个剧情（应被禁止）
    pre_check.button_pressed = true
    post_check.button_pressed = true
    # 战斗未勾选时，两个剧情不应同时被勾选
    var both_stories := pre_check.button_pressed and post_check.button_pressed
    assert(not both_stories or battle_check.button_pressed, "Cannot have both stories without battle")

    editor.queue_free()
    print("test_checkbox_validation passed")
```

- [ ] **Step 4: 运行测试验证**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/mission_editor_smoke_test.gd`
Expected: 所有测试通过

- [ ] **Step 5: 删除旧文件**

```bash
rm -f scripts/mission_editor/mission_editor.gd
rm -f scenes/mission_editor/mission_editor.tscn
```

- [ ] **Step 6: 提交**

```bash
git add scripts/mission_editor/mission_editor.gd scenes/mission_editor/mission_editor.tscn tests/mission_editor_smoke_test.gd
git add -u  # 记录删除的文件
git commit -m "feat: rewrite MissionEditor with component architecture"
```

---

## Task 9: 更新 AppRouter 和 PreparationScreen 入口

**Files:**
- Modify: `autoload/app_router.gd`
- Modify: `scripts/prep/preparation_screen.gd`
- Modify: `scenes/prep/preparation_screen.tscn`

- [ ] **Step 1: 确认 AppRouter 已有 goto_mission_editor 方法**

检查 `autoload/app_router.gd` 是否已有 `goto_mission_editor` 方法。如有，跳过此步骤。

如无，添加：

```gdscript
func goto_mission_editor(mission_id: String = "") -> void:
    var editor_scene := preload("res://scenes/mission_editor/mission_editor.tscn")
    var editor := editor_scene.instantiate()

    var root := get_tree().root
    for child in root.get_children():
        if child.name != "AppRouter":
            child.queue_free()

    root.add_child(editor)

    if not mission_id.is_empty() and editor.has_method("load_mission"):
        editor.load_mission(mission_id)
```

- [ ] **Step 2: 确认 PreparationScreen 已有任务编辑器入口按钮**

检查 `scenes/prep/preparation_screen.tscn` 是否已有任务编辑器按钮。如有，跳过此步骤。

如无，在适当位置添加按钮，并在 `scripts/prep/preparation_screen.gd` 中添加响应：

```gdscript
func _on_mission_editor_pressed() -> void:
    var router := get_node_or_null("/root/AppRouter")
    if router:
        router.goto_mission_editor()
```

- [ ] **Step 3: 运行回归测试**

Run: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/app_flow_smoke_test.gd`
Expected: 测试通过

- [ ] **Step 4: 提交**

```bash
git add autoload/app_router.gd scripts/prep/preparation_screen.gd scenes/prep/preparation_screen.tscn
git commit -m "fix: ensure MissionEditor entry points are wired"
```

---

## Task 10: 全量回归测试与收尾

**Files:**
- 修改: `docs/HANDOFF.md`

- [ ] **Step 1: 运行全量回归测试**

Run: `for t in $(rg --files tests -g '*.gd' | sort); do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "res://$t" || break; done`
Expected: 所有测试通过

- [ ] **Step 2: 更新 HANDOFF.md**

在 `docs/HANDOFF.md` 中添加本次改动记录：

```markdown
## 本次改动（2026-04-02，任务编辑器重制，合并到 main）

全新重制任务编辑器，采用组件化架构：

- 组件拆分：
  - TaskPanel：任务面板（类型/名称/简报/提示/收益）
  - StoryEditor：剧情编辑器（复用于战前/战后）
  - BattleEditor：战斗编辑器（含 BattlefieldPreview + EventList）
  - BattlefieldPreview：战场预览（拖拽放置敌人）
  - EventList：事件列表配置
  - RewardEditor：收益编辑器
- 复选框控制模块启用：
  - 战前剧情、战斗、战后剧情三个复选框
  - 验证规则：禁止只勾选两个剧情不勾选战斗
  - 取消战斗时自动取消两个剧情
- 数据结构增强：
  - MissionData 新增 has_pre_battle/has_battle/has_post_battle 字段
- 垂直堆叠布局：未启用模块完全隐藏

涉及文件：

- scripts/data/mission_data.gd（修改）
- scripts/mission_editor/mission_editor.gd（重写）
- scripts/mission_editor/components/*.gd（新增）
- scenes/mission_editor/mission_editor.tscn（重写）
- scenes/mission_editor/components/*.tscn（新增）
- tests/mission_editor_*.gd（更新/新增）

验证结果：

- 全量回归测试通过
```

- [ ] **Step 3: 最终提交**

```bash
git add docs/HANDOFF.md
git commit -m "docs: update HANDOFF.md for mission editor redesign"
```

---

## 自检清单

- [x] Spec 覆盖：每个设计部分都有对应 Task
- [x] 无占位符：所有代码完整，无 TBD/TODO
- [x] 类型一致：方法签名和属性名称在各 Task 中保持一致
