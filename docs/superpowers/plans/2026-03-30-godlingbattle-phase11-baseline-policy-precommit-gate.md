# GodlingBattle Phase 11 Baseline Policy Precommit Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finalize benchmark baseline management and wire the gate into pre-commit workflow for local regression blocking.

**Architecture:** Extend benchmark exporter with baseline profile/write/require options, add a reusable gate shell script + git pre-commit hook, and introduce a versioned main baseline JSON policy file.

**Tech Stack:** Godot 4.6, GDScript, shell scripts, headless tests

---

## File Structure

Core files for this phase task:

- `tools/export_runtime_benchmark.gd`: baseline profile/write/require behavior
- `tests/runtime_benchmark_baseline_profile_test.gd`: verify baseline profile and missing-baseline gate behavior
- `tools/run_benchmark_gate.sh`: reusable local gate command
- `.githooks/pre-commit`: pre-commit integration entry
- `tools/install_git_hooks.sh`: one-click hook installation
- `data/benchmarks/runtime_benchmark_baseline_main.json`: versioned main baseline
- `docs/benchmark-baseline-policy.md`: policy and review workflow
- `README.md`: quick usage entry

## Task 1: Baseline Policy and Pre-Commit Gate

**Files:**
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tools/export_runtime_benchmark.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tests/runtime_benchmark_baseline_profile_test.gd`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tools/run_benchmark_gate.sh`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/.githooks/pre-commit`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/tools/install_git_hooks.sh`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/data/benchmarks/runtime_benchmark_baseline_main.json`
- Create: `/Users/zhangwei/Documents/Mycode/GodlingBattle/docs/benchmark-baseline-policy.md`
- Modify: `/Users/zhangwei/Documents/Mycode/GodlingBattle/README.md`

- [x] **Step 1: Add failing test for baseline profile/write/require behavior**
- [x] **Step 2: Implement export options and required-baseline gate semantics**
- [x] **Step 3: Add pre-commit gate scripts and baseline artifact**
- [x] **Step 4: Run targeted tests, gate smoke, and full regression**

## Verification

- `tests/runtime_benchmark_baseline_profile_test.gd` pass
- `tests/runtime_benchmark_cli_export_gate_test.gd` pass
- `tests/runtime_benchmark_csv_threshold_test.gd` pass
- `tests/runtime_benchmark_stability_test.gd` pass
- `./tools/run_benchmark_gate.sh` pass
- full `tests/*.gd` pass (`49/49`)
