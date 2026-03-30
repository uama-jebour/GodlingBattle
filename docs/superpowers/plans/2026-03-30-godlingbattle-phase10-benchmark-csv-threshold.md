# GodlingBattle Phase 10 Benchmark CSV Threshold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add benchmark summary CSV export and historical baseline threshold comparison so runtime regressions are visible and can be gated.

**Architecture:** Extend `runtime_benchmark` with two explicit APIs: one for summary CSV building and one for baseline-ratio comparison, and optionally wire baseline comparison into benchmark run flow.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `tools/runtime_benchmark.gd`: add CSV export and baseline threshold comparison
- `tests/runtime_benchmark_stability_test.gd`: validate benchmark CSV output on real summary
- `tests/runtime_benchmark_csv_threshold_test.gd`: verify CSV schema and ratio-threshold comparison behavior

## Task 1: Add Benchmark CSV Export and Baseline Threshold

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tools/runtime_benchmark.gd`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_benchmark_stability_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_benchmark_csv_threshold_test.gd`

- [x] **Step 1: Add failing tests for CSV API and threshold compare API**
- [x] **Step 2: Implement `build_summary_csv` and CSV escaping**
- [x] **Step 3: Implement `compare_with_baseline` and optional run integration**
- [x] **Step 4: Run targeted tests and full regression**

## Verification

- `tests/runtime_benchmark_stability_test.gd` pass
- `tests/runtime_benchmark_csv_threshold_test.gd` pass
- `tests/app_flow_smoke_test.gd` pass
- full `tests/*.gd` pass (`47/47`)
