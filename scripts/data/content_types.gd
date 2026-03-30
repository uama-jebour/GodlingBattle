extends RefCounted


static func unit(def: Dictionary) -> Dictionary:
	return def.duplicate(true)


static func strategy(def: Dictionary) -> Dictionary:
	return def.duplicate(true)


static func event(def: Dictionary) -> Dictionary:
	return def.duplicate(true)


static func battle(def: Dictionary) -> Dictionary:
	return def.duplicate(true)
