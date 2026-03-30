# GodlingBattle Phase 7 Active Strategy Runtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make active strategies (`strat_chill_wave`, `strat_nuclear_strike`) take effect in runtime with deterministic cooldown-driven triggering and observable logs.

**Architecture:** Extend combat system with cooldown strategy runtime state and effect dispatch (`enemy_group_slow`, `enemy_front_nuke`). AI consumes entity slow status to alter movement speed. Keep event-response strategy path unchanged and preserve deterministic timeline.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `scripts/battle_runtime/battle_combat_system.gd`: active strategy runtime + effect application + cast logs
- `scripts/battle_runtime/battle_ai_system.gd`: remove placeholder strategy trigger, consume slow status
- `scripts/battle_runtime/battle_state.gd`: add base move speed and status fields
- `tests/runtime_active_strategy_trigger_test.gd`: verify chill-wave cast/triggered strategy
- `tests/runtime_active_strategy_nuke_effect_test.gd`: verify nuclear strike damage + cooldown gating

## Task 1: Implement Active Strategy Effects In Runtime

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_combat_system.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_ai_system.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_state.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_active_strategy_trigger_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_active_strategy_nuke_effect_test.gd`

- [x] **Step 1: Add failing tests for active strategy trigger and nuke effect**
- [x] **Step 2: Add cooldown-based strategy runtime state in combat**
- [x] **Step 3: Implement `enemy_group_slow` and `enemy_front_nuke` effects**
- [x] **Step 4: Update AI movement to consume slow status and clean placeholder trigger path**
- [x] **Step 5: Re-run targeted tests and full regression**

## Verification

- `tests/runtime_active_strategy_trigger_test.gd` pass
- `tests/runtime_active_strategy_nuke_effect_test.gd` pass
- full `tests/*.gd` pass
