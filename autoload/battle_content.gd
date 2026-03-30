extends Node

const TYPES := preload("res://scripts/data/content_types.gd")

var _units := {
	"hero_angel": TYPES.unit({
		"unit_id": "hero_angel",
		"display_name": "英雄：天使",
		"type": "hero",
		"move_mode": "flying",
		"attack_mode": "ranged",
		"move_speed": 10.0,
		"radius": 3.0,
		"max_hp": 100.0,
		"attack_power": 5.0,
		"attack_speed": 1.5,
		"attack_range": 4.0,
		"tags": ["英雄", "天使"],
		"move_logic": "chase_nearest",
		"combat_ai": "ranged"
	}),
	"ally_hound_remnant": TYPES.unit({
		"unit_id": "ally_hound_remnant",
		"display_name": "野犬残形",
		"type": "normal",
		"move_mode": "walking",
		"attack_mode": "melee",
		"move_speed": 15.0,
		"radius": 2.0,
		"max_hp": 20.0,
		"attack_power": 2.0,
		"attack_speed": 1.5,
		"attack_range": 1.0,
		"tags": ["虚无"],
		"move_logic": "chase_nearest",
		"combat_ai": "melee"
	})
}

var _strategies := {
	"strat_void_echo": TYPES.strategy({
		"strategy_id": "strat_void_echo",
		"name": "虚无回响",
		"kind": "passive",
		"cost": 1,
		"cooldown": -1.0,
		"tags": ["虚无"],
		"trigger_def": {"type": "always_on"},
		"effect_def": {"type": "ally_tag_attack_shift", "tag": "虚无", "bonus": 5.0, "penalty": -5.0}
	}),
	"strat_chill_wave": TYPES.strategy({
		"strategy_id": "strat_chill_wave",
		"name": "寒潮冲击",
		"kind": "active",
		"cost": 3,
		"cooldown": 8.0,
		"tags": ["寒霜"],
		"trigger_def": {"type": "cooldown"},
		"effect_def": {"type": "enemy_group_slow", "ratio": 0.35, "duration": 3.0}
	}),
	"strat_counter_demon_summon": TYPES.strategy({
		"strategy_id": "strat_counter_demon_summon",
		"name": "反制恶魔召唤",
		"kind": "response",
		"cost": 2,
		"cooldown": 0.0,
		"tags": ["反制"],
		"trigger_def": {"type": "event_response", "response_tag": "恶魔召唤", "response_level": 1},
		"effect_def": {"type": "event_cancel", "event_tag": "恶魔召唤", "event_level": 1}
	}),
	"strat_nuclear_strike": TYPES.strategy({
		"strategy_id": "strat_nuclear_strike",
		"name": "核击协议",
		"kind": "active",
		"cost": 6,
		"cooldown": 25.0,
		"tags": ["爆发"],
		"trigger_def": {"type": "cooldown"},
		"effect_def": {"type": "enemy_front_nuke", "damage": 20.0}
	})
}

var _events := {
	"evt_hunter_fiend_arrival": TYPES.event({
		"event_id": "evt_hunter_fiend_arrival",
		"name": "追猎魔登场",
		"trigger_def": {
			"type": "any",
			"rules": [
				{"type": "elapsed_gte", "value": 15.0},
				{"type": "ally_hp_ratio_lte", "value": 0.5}
			]
		},
		"warning_seconds": 5.0,
		"response_tag": "恶魔召唤",
		"response_level": 1,
		"unresolved_effect_def": {"type": "summon", "unit_id": "enemy_hunter_fiend", "count": 1}
	})
}

var _battles := {
	"battle_void_gate_alpha": TYPES.battle({
		"battle_id": "battle_void_gate_alpha",
		"display_name": "虚无裂隙·一层",
		"battlefield_id": "field_void_gate",
		"enemy_units": ["enemy_wandering_demon", "enemy_animated_machine"],
		"event_ids": ["evt_hunter_fiend_arrival"],
		"seed": 1001
	})
}


func get_unit(unit_id: String) -> Dictionary:
	return _units.get(unit_id, {}).duplicate(true)


func get_strategy(strategy_id: String) -> Dictionary:
	return _strategies.get(strategy_id, {}).duplicate(true)


func get_event(event_id: String) -> Dictionary:
	return _events.get(event_id, {}).duplicate(true)


func get_battle(battle_id: String) -> Dictionary:
	return _battles.get(battle_id, {}).duplicate(true)


func get_test_packs() -> Array:
	return [
		{
			"pack_id": "pack_melee_alpha",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": []
		},
		{
			"pack_id": "pack_melee_freeze",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": ["strat_chill_wave"]
		},
		{
			"pack_id": "pack_void_echo",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": ["strat_void_echo"]
		},
		{
			"pack_id": "pack_counter_check",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": ["strat_counter_demon_summon"]
		},
		{
			"pack_id": "pack_nuke_check",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": ["strat_nuclear_strike"]
		},
		{
			"pack_id": "pack_combo_alpha",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": ["strat_void_echo", "strat_chill_wave"]
		}
	]
