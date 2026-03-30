# GodlingBattle Phase 9 Runtime Benchmark Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add reproducible runtime performance and stability benchmarks for stacked strategy/event scenarios.

**Architecture:** Add a dedicated benchmark helper (`tools/runtime_benchmark.gd`) that runs predefined scenarios repeatedly, collects latency stats, validates completed status and deterministic outputs, and reports issues in a structured summary consumed by tests.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `tools/runtime_benchmark.gd`: benchmark runner and summary aggregation
- `tests/runtime_benchmark_stability_test.gd`: benchmark regression assertions

## Task 1: Add Runtime Benchmark Baseline

**Files:**
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tools/runtime_benchmark.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_benchmark_stability_test.gd`

- [x] **Step 1: Add failing benchmark test with stacked scenarios**
- [x] **Step 2: Implement benchmark helper and structured summary**
- [x] **Step 3: Validate max latency threshold and deterministic stability**
- [x] **Step 4: Run targeted and full regression tests**

## Verification

- `tests/runtime_benchmark_stability_test.gd` pass
- full `tests/*.gd` pass
