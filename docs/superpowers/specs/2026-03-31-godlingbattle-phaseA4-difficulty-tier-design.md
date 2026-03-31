# GodlingBattle Phase A4 三档难度关卡设计

## 1. 目标

围绕测试目标 1.8，补齐面向玩家三档战斗力的正式难度关卡配置：低战力、中战力、高战力。

## 2. 方案

1. 新增三档关卡：
- `battle_test_difficulty_tier1`（低战力）
- `battle_test_difficulty_tier2`（中战力）
- `battle_test_difficulty_tier3`（高战力）
2. 使用敌方数量与精英占比构成难度曲线：`2 < 3 < 4`，且高档包含更多精英。
3. 在准备页暴露 A4 三档测试预设，直接映射到对应关卡。
4. 在 content 测试包中新增 A4 三档 pack，便于批量验证。

## 3. 验收标准

1. 准备页可见并可应用 A4 三档预设。
2. content 可检索到 A4 三档关卡与 pack。
3. runtime 首帧敌方规模满足阶梯曲线，且高档精英压力高于低档。
4. 既有 preset/content 一致性测试不回归。
