# GodlingBattle Phase 7 Content Multi-Event Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add content-layer battle entries that define multiple events directly in `battle_content` so runtime can consume multi-event setups without synthetic test assembly.

**Architecture:** Extend content registry with additional event definitions and a multi-event battle (`battle_void_gate_beta`). Keep runtime/event logic unchanged and validate via `battle_runner` integration tests.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `autoload/battle_content.gd`: add events + multi-event battle + test pack
- `tests/runtime_multi_event_content_battle_test.gd`: verify battle-level multi-event chain via runner
- `tests/content_consistency_test.gd`: verify battle/event/pack references are consistent

## Task 1: Add Multi-Event Battle Content

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/autoload/battle_content.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_multi_event_content_battle_test.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/content_consistency_test.gd`

- [x] **Step 1: Add failing integration test for `battle_void_gate_beta` (RED)**
- [x] **Step 2: Add `evt_demon_ambush` and `evt_void_collapse` plus `battle_void_gate_beta`**
- [x] **Step 3: Add `pack_multi_event_beta` as content entry example**
- [x] **Step 4: Expand consistency test for pack battle IDs and battle event IDs**
- [x] **Step 5: Run targeted tests and full `tests/*.gd` regression**

## Verification

- `tests/runtime_multi_event_content_battle_test.gd` pass
- `tests/content_consistency_test.gd` pass
- full `tests/*.gd` pass
