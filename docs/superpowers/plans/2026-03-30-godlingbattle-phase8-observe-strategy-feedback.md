# GodlingBattle Phase 8 Observe Strategy Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Link runtime active strategy casts to observe HUD so players can see strategy execution feedback during replay.

**Architecture:** Extend observe HUD only. Add a dedicated strategy-cast label fed by `result.log_entries` rows where `type = strategy_cast`, and keep event filter behavior independent from strategy-cast display.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `scripts/observe/observe_screen.gd`: strategy-cast HUD text generation and getter
- `tests/observe_strategy_cast_hud_test.gd`: verify strategy-cast HUD behavior

## Task 1: Add Strategy Cast HUD Feedback

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/observe_strategy_cast_hud_test.gd`

- [x] **Step 1: Add failing test for strategy-cast HUD text**
- [x] **Step 2: Add HUD label and per-tick strategy-cast text rendering**
- [x] **Step 3: Expose getter for testability and UI assertions**
- [x] **Step 4: Run targeted and full regression tests**

## Verification

- `tests/observe_strategy_cast_hud_test.gd` pass
- full `tests/*.gd` pass
