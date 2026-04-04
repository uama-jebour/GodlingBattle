# GodlingBattle

`GodlingBattle` 是一个全新的独立 Godot 项目，用来实现新的自动战斗系统。

这个项目与旧的 `Godling` 并列存在，目标是避免新旧战斗系统继续混在一起。旧项目只作为参考来源，不作为本项目的运行依赖。

## 当前目标

首期先做一个正式游戏风格的可玩 Demo，打通这条主流程：

`出战前准备 -> 自动观战 -> 结果结算 -> 返回出战前准备`

其中：

- 出战前准备：庄重神秘的战术陈列台风格
- 自动观战：2D 棋子 + 血条
- 结果结算：冷静的战术报告页

## 当前状态

当前仓库已完成 Phase1-Phase14，主流程稳定可用：

- 已创建并可启动 `GodlingBattle` Godot 项目
- 已完成 `出战前准备 -> 自动观战 -> 结果结算 -> 返回出战前准备`
- 观战页已升级为四象限 UI（含暂停/倍速/时间线导航/战报联动）
- 已补齐 headless 回归测试与 benchmark 门禁链路

## 先看哪些文件

为降低新会话 token 成本，默认按这个顺序：

1. [AGENTS.MD](AGENTS.MD)（项目级记忆与快速接力入口）
2. [docs/HANDOFF.md](docs/HANDOFF.md)（当前状态与最新改动）
3. 按当前任务再定向阅读对应 `spec/plan`（不要默认全量通读 `docs/superpowers/*`）

## 下一步

下一步建议进入 Phase15：在保持现有主流程稳定前提下，继续强化 Observe 战报中心的信息密度与判读速度：

- 增加“关键事件彩色标签”
- 增加“阶段汇总卡片”
- 让玩家可在 3 秒内识别战局转折与胜负原因

## 约定

- 新项目保持独立，不要把新系统文件再写回旧 `Godling`
- 首期不做混合交互战斗
- 统一使用术语 `出战前准备`，不要写成“远征前准备”
- Godot 资源导入配置 `*.import` 需纳入版本管理
- `tests/*.gd.uid` 统一排除版本管理（测试脚本按路径执行，避免频繁 UID 噪音）
- 继续忽略 `.godot/` 与 `.import/` 目录缓存，不提交引擎缓存产物

## Benchmark 门禁

- 安装预提交 hook：
  - `./tools/install_git_hooks.sh`
- 手动执行 benchmark 门禁：
  - `./tools/run_benchmark_gate.sh`
- 更新主基线（已确认性能变更合理后）：
  - `BENCH_WRITE_BASELINE=1 ./tools/run_benchmark_gate.sh`

详细规则见：[docs/benchmark-baseline-policy.md](docs/benchmark-baseline-policy.md)

## Continuous Security Guardrails

- This repo runs `gitleaks` in GitHub Actions on push/PR/schedule.
- Local pre-commit secret scan is available in `.githooks/pre-commit`.
- Enable hooks locally:

```bash
git config core.hooksPath .githooks
```
