extends PanelContainer

@export var strategy_id := ""
@export var strategy_cost := 0


func render(id: String, cost: int) -> void:
	strategy_id = id
	strategy_cost = cost
