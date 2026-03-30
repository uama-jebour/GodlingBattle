# GodlingBattle Phase 6 Runtime Stability Regression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add regression coverage for long timeline ticking and complex event combinations to prevent runtime/event stage regressions.

**Architecture:** Keep battle runtime behavior unchanged. Add focused headless tests that stress `battle_event_response_system` with synthetic state dictionaries: one for multi-event combination staging and one for 6000-tick long-timeline stability.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `tests/runtime_event_combo_stability_test.gd`: complex multi-event combination regression
- `tests/runtime_event_long_timeline_stability_test.gd`: long-timeline (6000 tick) stability regression
- `docs/HANDOFF.md`: global status update

## Task 1: Add Runtime Stability Regression Tests

**Files:**
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_event_combo_stability_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_event_long_timeline_stability_test.gd`

- [x] **Step 1: Create complex-event regression test**
- [x] **Step 2: Create long-timeline regression test**
- [x] **Step 3: Run both tests and fix script type issues**
- [x] **Step 4: Re-run targeted tests to PASS**
- [x] **Step 5: Run app flow smoke and full `tests/*.gd` regression**

## Verification

- `tests/runtime_event_combo_stability_test.gd` pass
- `tests/runtime_event_long_timeline_stability_test.gd` pass
- `tests/app_flow_smoke_test.gd` pass
- full `tests/*.gd` pass
