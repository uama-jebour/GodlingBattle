# GodlingBattle Phase 12 CI Benchmark Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect benchmark gate to CI so remote pull request/push checks enforce the same performance baseline policy as local pre-commit.

**Architecture:** Add a GitHub Actions workflow that installs Godot on Linux, resolves `GODOT_BIN`, and runs `tools/run_benchmark_gate.sh`. Add one headless test to guard workflow presence and key command wiring.

**Tech Stack:** GitHub Actions, Godot 4.6, GDScript, shell

---

## File Structure

Core files for this phase task:

- `.github/workflows/benchmark-gate.yml`: remote CI benchmark gate workflow
- `tests/ci_benchmark_gate_workflow_test.gd`: verifies workflow exists and calls gate script
- `docs/HANDOFF.md`: global status update after phase completion

## Task 1: CI Benchmark Gate Wiring

**Files:**
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/tests/ci_benchmark_gate_workflow_test.gd`
- Create: `/Users/uama/Documents/Mycode/GodlingBattle/.github/workflows/benchmark-gate.yml`
- Modify: `/Users/uama/Documents/Mycode/GodlingBattle/docs/HANDOFF.md`

- [x] **Step 1: Add failing workflow-config test (RED)**
- [x] **Step 2: Implement GitHub Actions benchmark gate workflow (GREEN)**
- [x] **Step 3: Run targeted + full regression and update HANDOFF**

## Verification

- `tests/ci_benchmark_gate_workflow_test.gd` pass
- benchmark-related tests pass:
  - `tests/runtime_benchmark_stability_test.gd`
  - `tests/runtime_benchmark_csv_threshold_test.gd`
  - `tests/runtime_benchmark_cli_export_gate_test.gd`
  - `tests/runtime_benchmark_baseline_profile_test.gd`
- full `tests/*.gd` pass
