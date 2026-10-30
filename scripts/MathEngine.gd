extends RefCounted
class_name MathEngine

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

static func hint(question: Dictionary) -> String:
	var a: int = question["a"]
	var b: int = question["b"]
	if question["sign"] == "÷":
		return "Find how many times %d fits into %d.\nCheck: divisor × answer = dividend." % [b, a]
	if a < 10 and b < 10:
		return "%d × %d = (%d × %d) + (%d × %d)" % [a, b, a, 5, a, b-5] if b > 5 else "Think of %d groups of %d." % [a,b]
	if a >= 10:
		var high: int = int(a / 10) * 10
		return "%d × %d = (%d × %d) + (%d × %d)" % [a,b,high,b,a-high,b]
	return "Split the number into easier parts."
