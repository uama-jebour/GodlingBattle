# GodlingBattle Agent Memory

## Purpose

This file is the **project-level memory entrypoint** for new sessions.
Read this first to avoid re-indexing all docs and wasting tokens.

## Token-Efficient Read Order (Default)

1. Read this file (`AGENTS.MD`).
2. Read `docs/HANDOFF.md`:
   - `## 当前状态`
   - the latest `## 本次改动`
   - `## 下一阶段建议（Phase15）`
3. Read only the one spec/plan directly related to your current task.

Do **not** default to full-scan `docs/superpowers/specs/*.md` and `docs/superpowers/plans/*.md` every session.

## Project Snapshot (as of 2026-03-31)

- Project: standalone Godot auto-battle demo (`GodlingBattle`), isolated from old `Godling`.
- Completed phases: Phase1-Phase14 (including Phase14 Task1-Task5 closure patches).
- Current playable loop:
  - `出战前准备（可操作） -> 自动观战（四象限 UI / 暂停 / 倍速 / 时间线导航 / 战报中心） -> 结果结算（再战/返回）`
- Regression status in latest handoff:
  - `tests/observe_*.gd` passed
  - `tests/*.gd` total `67/67` passed
- Suggested next phase:
  - **Phase15**: Observe 战报中心可视化增强（关键事件彩色标签 + 阶段汇总卡片）

## Product Goals And Boundaries

- Goal: build a formal-feeling auto-battle product demo, not a debug panel.
- Core flow is fixed:
  - `出战前准备 -> 自动观战 -> 结果结算 -> 返回出战前准备`
- First-scope rules:
  - battle is fully auto-resolved
  - no mixed manual-in-battle interaction
  - deterministic runtime by seed (`10 tick/s`)
  - failure if hero dies or battle exceeds `600s`
- Naming convention:
  - always use `出战前准备` (do not rename to “远征前准备”).

## Architecture At A Glance

- `autoload/`
  - `app_router.gd`: screen routing
  - `session_state.gd`: setup/result/timeline session cache
  - `battle_content.gd`: content registry
- `scripts/`
  - `prep/`: setup UI and validation
  - `battle_runtime/`: AI/combat/event/tick runner
  - `observe/`: timeline playback + quadrant UI + report center
  - `result/`: result summary and replay/return flow
  - `ui/display_name_resolver.gd`: Chinese display-name and fallback normalization
- `scenes/`
  - `prep`, `observe`, `result` scene roots
- `tests/`
  - headless `.gd` tests for runtime/UI/flow/benchmark gates
- `tools/`
  - test-pack export, runtime benchmark export/CLI, benchmark gate scripts

## Runtime Contracts (Keep Stable)

- `battle_setup` (from preparation):
  - `hero_id`, `ally_ids`(3), `strategy_ids`, `battle_id`, `seed`
- `battle_result` (from runtime):
  - `status`, `victory`, `defeat_reason`, `elapsed_seconds`
  - `survivors`, `casualties`
  - `triggered_events`, `triggered_strategies`
  - `log_entries` (Observe/Result consume this)

## Key Workflow Commands

- Full regression:
  - `for t in $(rg --files tests -g '*.gd' | sort); do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script "res://$t" || break; done`
- App flow smoke:
  - `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/app_flow_smoke_test.gd`
- Benchmark gate:
  - `./tools/run_benchmark_gate.sh`
- Install pre-commit hooks:
  - `./tools/install_git_hooks.sh`

## Documentation Source Of Truth

- Session snapshot / progress / next-step:
  - `docs/HANDOFF.md`
- Deep history (only when needed):
  - `docs/archive/HANDOFF-*.md`
- Stable product goals/boundaries:
  - `docs/项目概览.md`
- Design intent (`Why/What`):
  - `docs/superpowers/specs/*.md`
- Implementation details (`How`):
  - `docs/superpowers/plans/*.md`
- Benchmark baseline policy:
  - `docs/benchmark-baseline-policy.md`
- Lightweight plan navigation:
  - `docs/实施计划导读.md`

## Documentation Update Rules

- Update progress or latest execution state:
  - edit `docs/HANDOFF.md` only.
- Update stable product scope/rules:
  - edit `docs/项目概览.md` only.
- Add or change design definition:
  - edit/add files in `docs/superpowers/specs/`.
- Add or change implementation plans:
  - edit/add files in `docs/superpowers/plans/`.
- Update onboarding/index strategy:
  - edit `AGENTS.MD` (and keep `docs/实施计划导读.md` minimal).

## Sub-Agent Execution Convention

- For sub-agents launched via superpowers workflows (for example `subagent-driven-development`):
  - do **not** run mandatory double-review / two-stage review by default.
  - use single-pass acceptance: implement -> basic verification -> integrate.
- Keep escalation only for high-risk changes:
  - destructive operations, data migration, security-sensitive logic, or benchmark-gate policy changes.

## Next-Session Prompt Template

`请先读 AGENTS.MD 与 docs/HANDOFF.md 的“当前状态+最新一次本次改动”，然后仅阅读与当前任务直接相关的 spec/plan 并继续执行。`
