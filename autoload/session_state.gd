extends Node

var battle_setup: Dictionary = {}
var last_battle_result: Dictionary = {}
var last_timeline: Array = []


func clear_runtime() -> void:
	last_battle_result = {}
	last_timeline = []
