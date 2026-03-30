# GodlingBattle Phase 9 Result Setup Snapshot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a battle setup snapshot on result screen so replay/debug decisions can reference the exact inputs used for this run.

**Architecture:** Extend `result_screen` summary data with `setup_snapshot_lines` sourced from `SessionState.battle_setup`, and render through a dedicated label in the existing result layout.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `scenes/result/result_screen.tscn`: add setup snapshot label
- `scripts/result/result_screen.gd`: build + render setup snapshot lines
- `tests/result_summary_fields_test.gd`: require summary has setup snapshot field
- `tests/result_screen_ui_smoke_test.gd`: require setup snapshot label exists
- `tests/result_setup_snapshot_test.gd`: verify label text includes hero/ally/strategy/battle/seed

## Task 1: Add Result Battle Setup Snapshot

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/result/result_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/result/result_screen.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/result_summary_fields_test.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/result_screen_ui_smoke_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/result_setup_snapshot_test.gd`

- [x] **Step 1: Add failing tests for summary field, UI node, and snapshot content**
- [x] **Step 2: Add setup snapshot label in result scene**
- [x] **Step 3: Implement setup snapshot summary and rendering from `battle_setup`**
- [x] **Step 4: Run targeted tests and full regression**

## Verification

- `tests/result_summary_fields_test.gd` pass
- `tests/result_screen_ui_smoke_test.gd` pass
- `tests/result_setup_snapshot_test.gd` pass
- `tests/app_flow_smoke_test.gd` pass
- full `tests/*.gd` pass (`45/45`)
