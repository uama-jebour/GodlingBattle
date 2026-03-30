extends Control

const DEFAULT_STRATEGY_BUDGET := 16


func build_battle_setup(selection: Dictionary) -> Dictionary:
	var hero_id := String(selection.get("hero_id", ""))
	var ally_ids: Array = selection.get("ally_ids", [])
	var strategy_ids: Array = selection.get("strategy_ids", [])
	var battle_id := String(selection.get("battle_id", ""))
	if hero_id.is_empty():
		return {"invalid_reason": "missing_hero"}
	if ally_ids.size() != 3:
		return {"invalid_reason": "invalid_ally_count"}
	if battle_id.is_empty() or BattleContent.get_battle(battle_id).is_empty():
		return {"invalid_reason": "missing_battle"}
	var total_cost := 0
	for strategy_id in strategy_ids:
		total_cost += int(BattleContent.get_strategy(String(strategy_id)).get("cost", 0))
	if total_cost > DEFAULT_STRATEGY_BUDGET:
		return {"invalid_reason": "strategy_budget_exceeded"}
	return {
		"hero_id": hero_id,
		"ally_ids": ally_ids.duplicate(),
		"strategy_ids": strategy_ids.duplicate(),
		"battle_id": battle_id,
		"seed": int(selection.get("seed", 0))
	}


func start_battle(selection: Dictionary) -> void:
	var setup := build_battle_setup(selection)
	if setup.has("invalid_reason"):
		return
	SessionState.battle_setup = setup
	AppRouter.goto_observe()
