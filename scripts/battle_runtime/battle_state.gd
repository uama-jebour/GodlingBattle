extends RefCounted

const MAX_SECONDS := 600
const TICK_RATE := 10


func initialize(setup: Dictionary) -> Dictionary:
	return {
		"setup": setup.duplicate(true),
		"tick_rate": TICK_RATE,
		"elapsed_ticks": 0,
		"max_ticks": MAX_SECONDS * TICK_RATE,
		"entities": [],
		"events": [],
		"strategies": [],
		"log_entries": [],
		"completed": false
	}
