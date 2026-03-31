# GodlingBattle Phase A3 主动策略测试链路设计

## 1. 背景

A1（多敌人）与 A2（多友方）已完成，测试目标 1.7「主动策略测试」仍缺少独立测试入口与成套验证。

## 2. 目标

1. 在出战前准备新增 A3 主动策略测试预设（寒潮、核击、双主动）。
2. 在内容测试包中新增 A3 主动策略包，便于批量跑测。
3. 补齐主动策略效果与观战主视效的集成测试。

## 3. 方案

1. 预设层：新增 `preset_a3_active_chill`、`preset_a3_active_nuke`、`preset_a3_active_combo`。
2. 内容层：新增 `pack_a3_active_chill`、`pack_a3_active_nuke`、`pack_a3_active_combo`。
3. 验证层：
- runtime：验证寒潮产生减速状态、核击造成前排生命下降并有 `strategy_cast` 日志。
- observe：基于真实 runtime 输出，验证战技高亮/弹字/闪屏主视效可见。

## 4. 边界

1. 不修改主动策略底层机制与数值平衡。
2. 不调整战斗主流程和结果契约。
3. 仅补齐 A3 测试链路可见性与可验证性。

## 5. 验收标准

1. 准备页可见并可应用 3 个 A3 预设。
2. A3 测试包可在内容层被检索到。
3. A3 新增 runtime/observe 测试通过，且既有主动策略测试不回归。
