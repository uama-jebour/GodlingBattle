# Benchmark Baseline 管理策略

## 1. 目的

为 `runtime benchmark` 提供可审阅、可追踪、可复现的性能基线，避免性能回退在合并后才被发现。

## 2. 基线文件位置

- 主基线（main）：`data/benchmarks/runtime_benchmark_baseline_main.json`
- 约定格式：`runtime_benchmark_baseline_<profile>.json`

说明：

- `profile` 推荐使用 `main` 或长期维护分支名（例如 `release_1_0`）。
- 临时分支不建议长期保存基线文件，避免仓库噪音。

## 3. 更新流程

1. 在性能变更已验证稳定后，执行：
   - `BENCH_WRITE_BASELINE=1 ./tools/run_benchmark_gate.sh`
2. 检查变更文件：
   - `data/benchmarks/runtime_benchmark_baseline_main.json`
3. 在 PR 描述说明：
   - 为什么更新基线
   - 预期提升/回退区间
   - 对应功能变更范围
4. 评审通过后合入。

## 4. 审阅规则

- 不接受“无功能变化”的大幅基线上浮。
- 若基线明显变慢，必须给出原因（算法复杂度、场景规模、内容变更等）。
- 若仅偶发波动，优先调整阈值策略而不是频繁改基线文件。

## 5. 门禁策略

- 预提交门禁：`.githooks/pre-commit` 调用 `tools/run_benchmark_gate.sh`
- 默认参数（可按需覆盖）：
  - `BENCH_MAX_MS=500`
  - `BENCH_RATIO=2.0`
  - `BENCH_BASELINE=res://data/benchmarks/runtime_benchmark_baseline_main.json`

可选环境变量：

- `SKIP_BENCHMARK_GATE=1`：临时跳过预提交门禁
- `GODOT_BIN=/path/to/Godot`：指定 Godot 可执行文件

## 6. 快速命令

- 安装 git hooks：
  - `./tools/install_git_hooks.sh`
- 手动执行门禁：
  - `./tools/run_benchmark_gate.sh`
