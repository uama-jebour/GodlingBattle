# 任务编辑器设计文档

## 概述

**功能：** 任务编辑器 — 创建/编辑任务，包含剧情文本、战斗配置、任务元数据。

**MVP 范围：** 核心循环 + 战斗事件，暂不包含存档加载、剧情分支、多关卡链式任务。

---

## 1. 整体架构

### 文件结构

```
scenes/mission_editor/
  mission_editor.tscn       # 编辑器场景

scripts/mission_editor/
  mission_editor.gd        # 主编辑器逻辑

scripts/data/
  mission_data.gd          # MissionData Resource 子类
```

### 技术方案

- **单一场景 + 单一脚本**，Tab 切换四个面板
- 持久化为 `.tres` 资源文件，保存到 `resources/missions/`
- 与 AppRouter 集成，支持从准备页进入编辑器

### 数据模型

```gdscript
class_name MissionData
extends Resource

# 元数据
var mission_id: String
var mission_name: String
var mission_type: String       # 主线/支线/日常/活动
var briefing: String           # 简报
var hint: String               # 提示

# 剧情（逐行）
var pre_battle_lines: Array[String]
var post_battle_lines: Array[String]

# 战斗配置
var battle_id: String
var enemy_entries: Array[Dictionary]   # [{unit_id, spawn_anchor}]
var event_configs: Array[Dictionary]    # [{event_id, trigger_preset, spawn_anchor}]

# 收益
var rewards: Array[Dictionary]          # [{type, value}]
```

---

## 2. UI 布局

### 横向 Tab 布局

```
┌──────────────────────────────────────────────────────┐
│  [战前剧情]  [战斗]  [战后剧情]  [任务面板]            │
├──────────────────────────────────────────────────────┤
│                                                      │
│                   当前 Tab 内容                       │
│                                                      │
├──────────────────────────────────────────────────────┤
│  [保存]  [加载下拉]  [新建]          [返回准备页]      │
└──────────────────────────────────────────────────────┘
```

### Tab 1: 战前剧情

- 逐行文本编辑器
- 每行：`[行号] [LineEdit] [↑] [↓] [×]`
- "添加行" 按钮
- 行数无限制

### Tab 2: 战斗

```
┌────────────────────────────────────────────────────┐
│  左侧：敌人列表              │  右侧：战场缩略图    │
│  ┌──────────────────────┐   │  ┌────────────────┐  │
│  │ 游荡魔 [拖拽]         │   │  │ ●红 ●红       │  │
│  │ 活化机械 [拖拽]       │   │  │    [拖放区]   │  │
│  │ 追猎魔 [拖拽]         │   │  │ ●青 ●青 ●青  │  │
│  └──────────────────────┘   │  └────────────────┘  │
├────────────────────────────────────────────────────┤
│  事件配置列表                                      │
│  [+ 添加事件]                                     │
│  [事件条目1: 触发条件▼ + 生成位置▼]                │
│  [事件条目2: ...]                                 │
└────────────────────────────────────────────────────┘
```

- **敌人列表**：从 `battle_content.gd` 读取所有 `enemy_*` 单位
- **战场缩略图**：预设锚点吸附布局，拖放敌人到锚点
- **事件配置**：预设触发条件 + 锚点选择

### Tab 3: 战后剧情

- 同 Tab 1，每行独立编辑

### Tab 4: 任务面板

```
┌─────────────────────────────────────────────┐
│  任务名称: [________________________]        │
│  任务类型: [主线 ▼]                         │
│  简报内容: [多行文本框_____________]         │
│  提示内容: [多行文本框_____________]         │
│  收益配置:                                  │
│    [+ 添加收益]                            │
│    [金币: 100] [经验: 50] [道具: xxx]       │
└─────────────────────────────────────────────┘
```

- **任务类型**：固定下拉（主线/支线/日常/活动）
- **收益类型**：固定下拉（金币/经验/道具）+ 数值输入

---

## 3. 战斗配置细节

### 预设触发条件

| 预设名称 | 条件描述 |
|---------|---------|
| `elapsed_15` | 战斗开始 15 秒后 |
| `elapsed_30` | 战斗开始 30 秒后 |
| `elapsed_60` | 战斗开始 60 秒后 |
| `ally_hp_50` | 友军血量 ≤ 50% |
| `ally_hp_25` | 友军血量 ≤ 25% |
| `enemy_count_2` | 敌方存活数 ≤ 2 |
| `any_elapsed_15_or_ally_hp_50` | elapsed_15 OR ally_hp_50 |

### 预设锚点位置

| 锚点 | 位置描述 |
|-----|---------|
| `right_flank` | 右翼 |
| `right_top` | 右上 |
| `right_bottom` | 右下 |
| `left_flank` | 左翼 |
| `left_top` | 左上 |
| `left_bottom` | 左下 |

---

## 4. 数据持久化

- **保存路径**：`resources/missions/{mission_id}.tres`
- **加载**：启动时扫描 `resources/missions/` 下所有 `.tres`
- **格式**：Godot Resource（`.tres`），可版本控制

---

## 5. AppRouter 集成

```gdscript
# autoload/app_router.gd 新增
func goto_mission_editor(mission_id: String = "") -> void:
    # 传入空字符串 → 新建任务
    # 传入 ID → 加载现有任务编辑
```

**导航流程**
```
准备页 → [任务编辑器按钮] → 任务编辑器
                            ↓ 保存
                      准备页（刷新任务列表）
```

---

## 6. 暂不包含

- 剧情分支/选项（future）
- 存档/加载到外部文件（不在 MVP）
- 任务预览/测试跑一次（future）
- 多关卡链式任务（future）
- 剧情选项对话（future）

---

## 7. 依赖

- `autoload/battle_content.gd`（读取敌方单位列表）
- `scripts/data/mission_data.gd`（数据类）
- `autoload/app_router.gd`（导航）
