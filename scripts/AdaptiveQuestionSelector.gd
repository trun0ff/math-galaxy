extends RefCounted
class_name AdaptiveQuestionSelector

const LEARNING_ENGINE = preload("res://scripts/LearningEngine.gd")
const REVIEW_SCHEDULER = preload("res://scripts/ReviewScheduler.gd")
const MATH_ENGINE = preload("res://scripts/MathEngine.gd")
const RECENT_WINDOW := 5

static func choose(world: int, skills: Dictionary, recent_keys: Array, day: int) -> Dictionary:
	var candidates: Array[Dictionary] = []
	if world == 1:
		for a in range(2, 10):
			for b in range(2, 10):
				candidates.append({"a": a, "b": b, "answer": a * b, "sign": "×", "world": 1, "key": "1_%d_%d" % [a, b]})
	else:
		for i in range(48):
			candidates.append(MATH_ENGINE.generate(world))
	# Previously encountered tasks must remain eligible for spaced review in every world.
	if world != 1:
		for key in skills.keys():
			var pieces: PackedStringArray = str(key).split("_")
			if pieces.size() != 3 or not str(pieces[0]).is_valid_int() or int(pieces[0]) != world:
				continue
			if not str(pieces[1]).is_valid_int() or not str(pieces[2]).is_valid_int():
				continue
			var a: int = int(pieces[1])
			var b: int = int(pieces[2])
			if a <= 0 or b <= 0:
				continue
			var division: bool = world == 5
			if division and (a % b != 0):
				continue
			candidates.append({"a": a, "b": b, "answer": int(a / b) if division else a * b, "sign": "÷" if division else "×", "world": world, "key": str(key)})
	var recent: Array = recent_keys.slice(maxi(0, recent_keys.size() - RECENT_WINDOW))
	var filtered: Array[Dictionary] = []
	for q in candidates:
		if recent.has(q["key"]):
			continue
		if world == 1 and recent.has("1_%d_%d" % [q["b"], q["a"]]):
			continue
		filtered.append(q)
	if filtered.is_empty():
		filtered = candidates
	var pools: Dictionary = {"weak": [], "due": [], "mastered": [], "new": []}
	for q in filtered:
		var s: Dictionary = skills.get(q["key"], {})
		var state: String = LEARNING_ENGINE.effective_state(s, day)
		var category: String = "weak"
		if int(s.get("attempts", 0)) == 0:
			category = "new"
		elif REVIEW_SCHEDULER.is_due(s, day):
			category = "due"
		elif state == "MASTERED":
			category = "mastered"
		pools[category].append(q)
	# Weighted mix: weak 40%, due 30%, mastered 20%, new 10%.
	var roll: float = randf()
	var order: Array[String] = ["weak", "due", "mastered", "new"]
	if roll < 0.4:
		order = ["weak", "due", "new", "mastered"]
	elif roll < 0.7:
		order = ["due", "weak", "new", "mastered"]
	elif roll < 0.9:
		order = ["mastered", "due", "weak", "new"]
	else:
		order = ["new", "weak", "due", "mastered"]
	for name in order:
		var pool: Array = pools[name]
		if not pool.is_empty():
			return pool.pick_random()
	return MATH_ENGINE.generate(world)
