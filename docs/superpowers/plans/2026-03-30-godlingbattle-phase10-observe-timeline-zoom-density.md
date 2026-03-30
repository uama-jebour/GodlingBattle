# GodlingBattle Phase 10 Observe Timeline Zoom Density Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve observe readability in long battles by supporting timeline zoom and marker density control for event/strategy timeline.

**Architecture:** Add two timeline controls on `ObserveScreen` (`zoom` + `density`), then rebuild timeline markers as: filtered rows -> zoom bucket aggregation -> density sampling -> label/list rendering.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `scenes/observe/observe_screen.tscn`: add timeline zoom/density controls
- `scripts/observe/observe_screen.gd`: implement zoom+density marker pipeline
- `tests/observe_playback_controls_test.gd`: require new controls exist
- `tests/observe_timeline_zoom_density_test.gd`: verify zoom aggregation and density limit

## Task 1: Add Observe Timeline Zoom and Density Controls

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/observe/observe_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_playback_controls_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_timeline_zoom_density_test.gd`

- [x] **Step 1: Add failing tests for new controls and marker behavior**
- [x] **Step 2: Add zoom/density controls in observe scene**
- [x] **Step 3: Implement marker aggregation + density sampling + render pipeline**
- [x] **Step 4: Run targeted tests and full regression**

## Verification

- `tests/observe_playback_controls_test.gd` pass
- `tests/observe_event_timeline_filter_test.gd` pass
- `tests/observe_event_marker_jump_test.gd` pass
- `tests/observe_timeline_zoom_density_test.gd` pass
- `tests/app_flow_smoke_test.gd` pass
- full `tests/*.gd` pass (`46/46`)
