# GodlingBattle Phase 7 Runtime Combat Attr Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace fixed scripted combat completion with attribute-driven combat resolution and strategy-influenced damage.

**Architecture:** Keep runtime loop shape unchanged (`ai -> combat -> event`). Upgrade combat to evaluate live entities by side, range, cooldown, and attack power; keep event system intact. Add passive strategy effect application for `ally_tag_attack_shift` so combat output reflects selected strategy build.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `scripts/battle_runtime/battle_combat_system.gd`: attribute-driven target selection, cooldown, damage, casualty logs
- `scripts/battle_runtime/battle_state.gd`: include entity tags/cooldown fields and adjusted spawn spacing
- `scripts/battle_runtime/battle_ai_system.gd`: chase-nearest movement to support sustained engagement
- `scripts/observe/observe_screen.gd`: frame accumulator loop for stable playback on longer timelines
- `tests/runtime_combat_attr_driven_test.gd`: verify range + cooldown behavior
- `tests/runtime_combat_strategy_effect_test.gd`: verify passive strategy bonus behavior

## Task 1: Upgrade Runtime Combat Resolution

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_combat_system.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_state.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/battle_runtime/battle_ai_system.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/scripts/observe/observe_screen.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_combat_attr_driven_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_combat_strategy_effect_test.gd`

- [x] **Step 1: Add failing tests for attribute-driven combat and strategy effect**
- [x] **Step 2: Run tests to confirm RED**
- [x] **Step 3: Implement cooldown/range/target-based combat and passive strategy damage shift**
- [x] **Step 4: Align runtime movement/spacing to avoid timeout-only regressions**
- [x] **Step 5: Re-run targeted tests and app flow smoke**
- [x] **Step 6: Run full `tests/*.gd` regression**

## Verification

- `tests/runtime_combat_attr_driven_test.gd` pass
- `tests/runtime_combat_strategy_effect_test.gd` pass
- `tests/app_flow_smoke_test.gd` pass
- full `tests/*.gd` pass
