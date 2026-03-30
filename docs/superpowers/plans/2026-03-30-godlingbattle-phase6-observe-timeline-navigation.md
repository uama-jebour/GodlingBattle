# GodlingBattle Phase 6 Observe Timeline Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add observe timeline progress bar and jump-frame controls so replay has direct timeline navigation.

**Architecture:** Extend existing playback panel (`pause + speed`) with timeline navigation controls (`progress slider + jump buttons`). Keep runtime contracts unchanged and operate only on observe-layer timeline consumption (`session_state.last_timeline`).

**Tech Stack:** Godot 4.6, GDScript, headless Godot tests

---

## File Structure

Core files for this phase task:

- `scenes/observe/observe_screen.tscn`: playback panel adds progress/jump controls
- `scripts/observe/observe_screen.gd`: timeline seek and jump behavior, slider sync
- `tests/observe_playback_controls_test.gd`: assert new controls exist with legacy pause/speed behavior
- `tests/observe_playback_seek_test.gd`: assert jump/seek updates displayed tick correctly
- `docs/HANDOFF.md`: global status update

## Task 1: Add Progress Slider And Jump Controls

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/observe/observe_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_playback_controls_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_playback_seek_test.gd`

- [x] **Step 1: Extend tests for controls and seek behavior (RED)**
- [x] **Step 2: Run tests to confirm failures before implementation**
- [x] **Step 3: Add `StepBackButton` / `ProgressSlider` / `StepForwardButton` in observe scene**
- [x] **Step 4: Implement `_seek_to_frame` + `_jump_frames` + slider sync logic**
- [x] **Step 5: Re-run related tests and app flow smoke to confirm GREEN**
- [x] **Step 6: Run full `tests/*.gd` regression**

## Verification

- `tests/observe_playback_controls_test.gd` pass
- `tests/observe_playback_seek_test.gd` pass
- `tests/app_flow_smoke_test.gd` pass
- full `tests/*.gd` pass
