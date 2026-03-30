# GodlingBattle Phase 8 Observe Event Timeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add observe-side event timeline markers and event-type filtering to improve battle replay readability.

**Architecture:** Keep runtime contracts unchanged and extend observe UI/controller only. Add a lightweight event panel with filter select and timeline marker text built from `result.log_entries`, and apply the same filter to current tick event hint display.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `scenes/observe/observe_screen.tscn`: add event panel UI nodes
- `scripts/observe/observe_screen.gd`: event filter state + marker rendering + filtered HUD event text
- `tests/observe_playback_controls_test.gd`: assert event panel nodes exist
- `tests/observe_event_timeline_filter_test.gd`: verify filter behavior and marker rendering

## Task 1: Add Event Marker Timeline And Filter

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/observe/observe_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_playback_controls_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_event_timeline_filter_test.gd`

- [x] **Step 1: Write failing tests for event panel controls and filter behavior**
- [x] **Step 2: Add event panel nodes (`EventFilterSelect`, `EventTimelineLabel`)**
- [x] **Step 3: Implement filter state and timeline marker rendering**
- [x] **Step 4: Apply filter to per-tick HUD event hint**
- [x] **Step 5: Re-run targeted tests and full regression**

## Verification

- `tests/observe_playback_controls_test.gd` pass
- `tests/observe_event_timeline_filter_test.gd` pass
- full `tests/*.gd` pass
