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
		"attack_power": 4.0,
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
		"attack_power": 1.5,
		"attack_speed": 1.5,
		"attack_range": 1.0,
		"tags": ["虚无"],
		"move_logic": "chase_nearest",
		"combat_ai": "melee"
	}),
	"ally_arc_shooter": TYPES.unit({
		"unit_id": "ally_arc_shooter",
		"display_name": "弧矢射手",
		"type": "normal",
		"move_mode": "walking",
		"attack_mode": "ranged",
		"move_speed": 11.0,
		"radius": 2.0,
		"max_hp": 26.0,
		"attack_power": 2.2,
		"attack_speed": 1.35,
		"attack_range": 4.2,
		"tags": ["友军", "远程"],
		"move_logic": "chase_nearest",
		"combat_ai": "ranged"
	}),
	"ally_guardian_sentinel": TYPES.unit({
		"unit_id": "ally_guardian_sentinel",
		"display_name": "守护哨兵",
		"type": "elite",
		"move_mode": "walking",
		"attack_mode": "melee",
		"move_speed": 8.0,
		"radius": 2.8,
		"max_hp": 68.0,
		"attack_power": 3.4,
		"attack_speed": 1.1,
		"attack_range": 1.3,
		"tags": ["友军", "守护"],
		"move_logic": "chase_nearest",
		"combat_ai": "melee"
	}),
	"enemy_wandering_demon": TYPES.unit({
		"unit_id": "enemy_wandering_demon",
		"display_name": "游荡魔",
		"type": "normal",
		"move_mode": "walking",
		"attack_mode": "melee",
		"move_speed": 9.0,
		"radius": 2.5,
		"max_hp": 42.0,
		"attack_power": 3.0,
		"attack_speed": 1.2,
		"attack_range": 1.0,
		"tags": ["恶魔"],
		"move_logic": "chase_nearest",
		"combat_ai": "melee"
	}),
	"enemy_animated_machine": TYPES.unit({
		"unit_id": "enemy_animated_machine",
		"display_name": "活化机械",
		"type": "normal",
		"move_mode": "walking",
		"attack_mode": "ranged",
		"move_speed": 7.0,
		"radius": 2.5,
		"max_hp": 52.0,
		"attack_power": 3.8,
		"attack_speed": 1.1,
		"attack_range": 3.8,
		"tags": ["机械"],
		"move_logic": "chase_nearest",
		"combat_ai": "ranged"
	}),
	"enemy_hunter_fiend": TYPES.unit({
		"unit_id": "enemy_hunter_fiend",
		"display_name": "追猎魔",
		"type": "elite",
		"move_mode": "walking",
		"attack_mode": "melee",
		"move_speed": 10.0,
		"radius": 3.0,
		"max_hp": 38.0,
		"attack_power": 4.5,
		"attack_speed": 1.4,
		"attack_range": 1.2,
		"tags": ["恶魔", "召唤"],
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
		"effect_def": {"type": "ally_tag_attack_shift", "tag": "虚无", "bonus": 3.0, "penalty": -3.0}
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
		"effect_def": {"type": "enemy_front_nuke", "damage": 14.0}
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
		"unresolved_effect_def": {
			"type": "summon",
			"unit_id": "enemy_hunter_fiend",
			"count": 1,
			"spawn_anchor": "right_flank",
			"spawn_jitter": {"x": 18.0, "y": 48.0}
		}
	}),
	"evt_demon_ambush": TYPES.event({
		"event_id": "evt_demon_ambush",
		"name": "恶魔伏击",
		"trigger_def": {"type": "elapsed_gte", "value": 6.0},
		"warning_seconds": 3.0,
		"response_tag": "恶魔召唤",
		"response_level": 1,
		"unresolved_effect_def": {"type": "summon", "unit_id": "enemy_hunter_fiend", "count": 1}
	}),
	"evt_void_collapse": TYPES.event({
		"event_id": "evt_void_collapse",
		"name": "虚空坍缩",
		"trigger_def": {"type": "elapsed_gte", "value": 7.0},
		"warning_seconds": 2.0,
		"response_tag": "崩解防护",
		"response_level": 2,
		"unresolved_effect_def": {"type": "void_shock", "damage": 8.0}
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
	}),
	"battle_void_gate_beta": TYPES.battle({
		"battle_id": "battle_void_gate_beta",
		"display_name": "虚无裂隙·二层",
		"battlefield_id": "field_void_gate",
		"enemy_units": ["enemy_wandering_demon", "enemy_animated_machine"],
		"event_ids": ["evt_demon_ambush", "evt_void_collapse"],
		"seed": 20260330
	}),
	"battle_void_gate_test_baseline": TYPES.battle({
		"battle_id": "battle_void_gate_test_baseline",
		"display_name": "测试基线·初始编排",
		"battlefield_id": "field_void_gate",
		"enemy_units": ["enemy_wandering_demon", "enemy_animated_machine", "enemy_wandering_demon"],
		"event_ids": ["evt_hunter_fiend_arrival"],
		"seed": 26033101
	}),
	"battle_test_enemy_melee": TYPES.battle({
		"battle_id": "battle_test_enemy_melee",
		"display_name": "测试矩阵·全近战",
		"battlefield_id": "field_void_gate",
		"enemy_units": ["enemy_wandering_demon", "enemy_wandering_demon", "enemy_wandering_demon"],
		"event_ids": [],
		"seed": 26033111
	}),
	"battle_test_enemy_ranged": TYPES.battle({
		"battle_id": "battle_test_enemy_ranged",
		"display_name": "测试矩阵·全远程",
		"battlefield_id": "field_void_gate",
		"enemy_units": ["enemy_animated_machine", "enemy_animated_machine", "enemy_animated_machine"],
		"event_ids": [],
		"seed": 26033112
	}),
	"battle_test_enemy_mixed": TYPES.battle({
		"battle_id": "battle_test_enemy_mixed",
		"display_name": "测试矩阵·近远混合",
		"battlefield_id": "field_void_gate",
		"enemy_units": ["enemy_wandering_demon", "enemy_animated_machine", "enemy_wandering_demon"],
		"event_ids": [],
		"seed": 26033113
	}),
	"battle_test_enemy_elite": TYPES.battle({
		"battle_id": "battle_test_enemy_elite",
		"display_name": "测试矩阵·精英主导",
		"battlefield_id": "field_void_gate",
		"enemy_units": ["enemy_hunter_fiend", "enemy_wandering_demon", "enemy_animated_machine"],
		"event_ids": [],
		"seed": 26033114
	})
}


func get_unit(unit_id: String) -> Dictionary:
	return _units.get(unit_id, {}).duplicate(true)


func get_strategy(strategy_id: String) -> Dictionary:
	return _strategies.get(strategy_id, {}).duplicate(true)


func get_all_strategy_ids() -> Array[String]:
	var strategy_ids: Array[String] = []
	for strategy_id in _strategies.keys():
		strategy_ids.append(String(strategy_id))
	strategy_ids.sort()
	return strategy_ids


func get_event(event_id: String) -> Dictionary:
	return _events.get(event_id, {}).duplicate(true)


func get_battle(battle_id: String) -> Dictionary:
	return _battles.get(battle_id, {}).duplicate(true)


func get_all_battle_ids() -> Array[String]:
	var battle_ids: Array[String] = []
	for battle_id in _battles.keys():
		battle_ids.append(String(battle_id))
	battle_ids.sort()
	return battle_ids


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
		},
		{
			"pack_id": "pack_goal_1_1_baseline",
			"battle_id": "battle_void_gate_test_baseline",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": []
		},
		{
			"pack_id": "pack_goal_1_2_hero_only",
			"battle_id": "battle_void_gate_test_baseline",
			"hero_id": "hero_angel",
			"ally_ids": [],
			"strategy_ids": ["strat_chill_wave"]
		},
		{
			"pack_id": "pack_a1_enemy_melee",
			"battle_id": "battle_test_enemy_melee",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": []
		},
		{
			"pack_id": "pack_a1_enemy_ranged",
			"battle_id": "battle_test_enemy_ranged",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": []
		},
		{
			"pack_id": "pack_a1_enemy_mixed",
			"battle_id": "battle_test_enemy_mixed",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": []
		},
		{
			"pack_id": "pack_a1_enemy_elite",
			"battle_id": "battle_test_enemy_elite",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": []
		},
		{
			"pack_id": "pack_a2_quantity_allies",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_entries": [
				{"unit_id": "ally_hound_remnant", "count": 3}
			],
			"strategy_ids": []
		},
		{
			"pack_id": "pack_a2_individual_allies",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_entries": [
				{"unit_id": "ally_guardian_sentinel", "count": 1}
			],
			"strategy_ids": []
		},
		{
			"pack_id": "pack_a2_mixed_allies",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_entries": [
				{"unit_id": "ally_hound_remnant", "count": 2},
				{"unit_id": "ally_arc_shooter", "count": 1}
			],
			"strategy_ids": []
		},
		{
			"pack_id": "pack_a3_active_chill",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": ["strat_chill_wave"]
		},
		{
			"pack_id": "pack_a3_active_nuke",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": ["strat_nuclear_strike"]
		},
		{
			"pack_id": "pack_a3_active_combo",
			"battle_id": "battle_void_gate_alpha",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": ["strat_chill_wave", "strat_nuclear_strike"]
		},
		{
			"pack_id": "pack_multi_event_beta",
			"battle_id": "battle_void_gate_beta",
			"hero_id": "hero_angel",
			"ally_ids": ["ally_hound_remnant", "ally_hound_remnant", "ally_hound_remnant"],
			"strategy_ids": ["strat_counter_demon_summon"]
		}
	]
