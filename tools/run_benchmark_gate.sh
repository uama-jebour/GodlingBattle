#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

if [[ ! -x "${GODOT_BIN}" ]]; then
  echo "benchmark gate failed: GODOT_BIN not executable: ${GODOT_BIN}" >&2
  exit 2
fi

BENCH_OUTPUT="${BENCH_OUTPUT:-user://artifacts/benchmarks/benchmark_gate.csv}"
BENCH_SUMMARY="${BENCH_SUMMARY:-user://artifacts/benchmarks/benchmark_gate.json}"
BENCH_BASELINE="${BENCH_BASELINE:-res://data/benchmarks/runtime_benchmark_baseline_main.json}"
BENCH_MAX_MS="${BENCH_MAX_MS:-500}"
BENCH_RATIO="${BENCH_RATIO:-2.0}"
BENCH_WRITE_BASELINE="${BENCH_WRITE_BASELINE:-0}"

ARGS=(
  "--output=${BENCH_OUTPUT}"
  "--summary-json=${BENCH_SUMMARY}"
  "--baseline=${BENCH_BASELINE}"
  "--max-ms=${BENCH_MAX_MS}"
  "--ratio=${BENCH_RATIO}"
  "--require-baseline"
)

if [[ "${BENCH_WRITE_BASELINE}" == "1" ]]; then
  ARGS+=("--write-baseline")
fi

cd "${ROOT_DIR}"
"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --script res://tools/export_runtime_benchmark_cli.gd -- "${ARGS[@]}"
