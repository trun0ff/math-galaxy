extends RefCounted

class_name MathEngine

const L10N = preload("res://scripts/Localization.gd")


static func generate(world: int) -> Dictionary:
	var a: int
	var b: int
	var result: int
	var sign_text: String = "×"
	match world:
		1:
			a = randi_range(2, 9); b = randi_range(2, 9)
			result = a * b
		2:
			a = randi_range(10, 99); b = randi_range(2, 9)
			result = a * b
		3:
			a = randi_range(100, 999); b = randi_range(2, 9)
			result = a * b
		4:
			a = randi_range(10, 99); b = randi_range(10, 99)
			result = a * b
		_:
			sign_text = "÷"
			if randf() < 0.5:
				b = randi_range(2, 9)
				result = randi_range(2, int(99.0 / b))
				a = result * b
				while a < 10:
					result = randi_range(2, int(99.0 / b)); a = result * b
			else:
				b = randi_range(10, 49)
				result = randi_range(2, int(999.0 / b))
				a = result * b
				while a < 100:
					result = randi_range(2, int(999.0 / b)); a = result * b
	return {"a": a, "b": b, "answer": result, "sign": sign_text, "world": world, "key": "%d_%d_%d" % [world,a,b]}

static func options(question: Dictionary) -> Array[int]:
	var right: int = question["answer"]
	var values: Array[int] = [right]
	var guesses: Array[int] = [right - question["b"], right + question["b"], right - question["a"], right + question["a"], right + 1, right - 1, right + 10, right - 10]
	guesses.shuffle()
	for n in guesses:
		if n > 0 and not values.has(n):
			values.append(n)
		if values.size() == 4:
			break
	while values.size() < 4:
		var candidate: int = maxi(1, right + randi_range(-25, 25))
		if not values.has(candidate): values.append(candidate)
	values.shuffle()
	return values

# Each path is selected once per question; all three stages share its parts.
static func hint_stages(q: Dictionary, alternate: bool = false) -> Array[String]:
	var a: int = int(q.a)
	var b: int = int(q.b)
	var parts: Array[int] = []
	var expressions: Array[String] = []
	var values: Array[String] = []
	if q.sign == "÷":
		var quotient: int = int(a / b)
		var first: int = int(quotient / 10) * 10
		if alternate or first == 0 or first == quotient:
			first = maxi(1, int(quotient / 2))
		var chunk: int = first * b
		return [L10N.text("Use a known multiple: %d × %d. Then divide what remains.") % [b, first],
			"%d ÷ %d = (%d ÷ %d) + (%d ÷ %d)" % [a, b, chunk, b, a - chunk, b],
			"%d = %d + %d; %d ÷ %d = %d + %d = %d" % [a, chunk, a - chunk, a, b, first, quotient - first, quotient]]
	var split: int = a
	var factor: int = b
	if int(q.world) == 4 and not alternate:
		split = b
		factor = a
	if int(q.world) == 1:
		var base: int = 5 if split > 5 else maxi(1, int(split / 2))
		parts.assign([base, split - base])
	elif alternate and split % 10 > 0:
		parts.assign([split + 10 - split % 10, -(10 - split % 10)])
	else:
		for place in [100, 10, 1]:
			var part: int = int(split / place) % 10 * place
			if part > 0: parts.append(part)
		# Round numbers still get a useful split rather than the original problem.
		if parts.size() == 1:
			parts.assign([int(split / 2), split - int(split / 2)])
	for part in parts:
		expressions.append("(%d × %d)" % [part, factor])
		values.append(str(part * factor))
	return [L10N.text("Start with %d × %d; use the remaining groups. You can split into places or use a nearby round number.") % [parts[0], factor],
		"%d × %d = %s" % [a, b, " + ".join(expressions)],
		"%s = %s = %d" % [" + ".join(expressions), " + ".join(values), a * b]]

static func hint(question: Dictionary) -> String:
	return hint_stages(question)[0]
