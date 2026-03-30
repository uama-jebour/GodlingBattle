# GodlingBattle Phase 9 Result Strategy Summary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add key strategy-cast summary on result screen using the same `strategy_cast` runtime signal shown in observe HUD.

**Architecture:** Extend `result_screen` summary builder with aggregated cast counts from `log_entries` where `type = strategy_cast`, and render them in a dedicated label to keep existing fields stable.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `scenes/result/result_screen.tscn`: add strategy cast summary label
- `scripts/result/result_screen.gd`: aggregate cast counts and render text
- `tests/result_summary_fields_test.gd`: require summary has cast lines
- `tests/result_screen_ui_smoke_test.gd`: require cast summary label exists
- `tests/result_strategy_cast_summary_test.gd`: verify cast summary count formatting

## Task 1: Add Result Strategy-Cast Summary

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scenes/result/result_screen.tscn`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/result/result_screen.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/result_summary_fields_test.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/result_screen_ui_smoke_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/result_strategy_cast_summary_test.gd`

- [x] **Step 1: Add failing tests for new summary field and UI node**
- [x] **Step 2: Add cast summary label in result scene**
- [x] **Step 3: Implement cast aggregation (`strategy_id xN`) from `log_entries`**
- [x] **Step 4: Run targeted tests and full regression**

## Verification

- `tests/result_strategy_cast_summary_test.gd` pass
- full `tests/*.gd` pass
