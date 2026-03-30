# GodlingBattle Phase 11 Benchmark CLI Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide a runnable benchmark export CLI that writes CSV/JSON artifacts and enforces baseline threshold gating via process exit code.

**Architecture:** Add a reusable benchmark export service (`export_runtime_benchmark.gd`) and a thin SceneTree CLI wrapper (`export_runtime_benchmark_cli.gd`) that parses user args and exits non-zero on regression issues.

**Tech Stack:** Godot 4.6, GDScript, headless tests

---

## File Structure

Core files for this phase task:

- `tools/export_runtime_benchmark.gd`: export service + arg parsing + baseline loading
- `tools/export_runtime_benchmark_cli.gd`: command-line entry wrapper
- `tests/runtime_benchmark_cli_export_gate_test.gd`: verify CSV output and baseline gate behavior

## Task 1: Add Benchmark CSV CLI Export and Gate

**Files:**
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tools/export_runtime_benchmark.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tools/export_runtime_benchmark_cli.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_benchmark_cli_export_gate_test.gd`

- [x] **Step 1: Add failing CLI export/gate test**
- [x] **Step 2: Implement export service with default scenarios and baseline JSON loading**
- [x] **Step 3: Implement CLI wrapper with process exit gate behavior**
- [x] **Step 4: Run targeted tests, CLI smoke run, and full regression**

## Verification

- `tests/runtime_benchmark_cli_export_gate_test.gd` pass
- `tests/runtime_benchmark_csv_threshold_test.gd` pass
- `tests/runtime_benchmark_stability_test.gd` pass
- `tests/app_flow_smoke_test.gd` pass
- `tools/export_runtime_benchmark_cli.gd` CLI smoke run pass
- full `tests/*.gd` pass (`48/48`)
