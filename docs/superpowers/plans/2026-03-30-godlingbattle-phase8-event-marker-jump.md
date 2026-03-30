# GodlingBattle Phase 8 Event Marker Jump Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Link observe event markers to timeline navigation so clicking a marker jumps playback to the corresponding tick.

**Architecture:** Extend observe event panel with a marker list derived from filtered `log_entries`. Reuse existing `_seek_to_frame`/progress seek path by mapping marker tick to nearest timeline frame.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `scenes/observe/observe_screen.tscn`: add event marker list node
- `scripts/observe/observe_screen.gd`: marker list data binding and tick jump handler
- `tests/observe_event_marker_jump_test.gd`: verify marker click jumps to target tick
- `tests/observe_playback_controls_test.gd`: verify marker list node existence

## Task 1: Add Click-To-Jump Event Marker List

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/observe/observe_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_event_marker_jump_test.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_playback_controls_test.gd`

- [x] **Step 1: Add failing tests for marker node and jump behavior**
- [x] **Step 2: Add `EventMarkerList` node**
- [x] **Step 3: Build filtered marker ticks and bind item-selected handler**
- [x] **Step 4: Reuse seek path to jump to clicked marker tick**
- [x] **Step 5: Run targeted and full regression tests**

## Verification

- `tests/observe_event_marker_jump_test.gd` pass
- full `tests/*.gd` pass
