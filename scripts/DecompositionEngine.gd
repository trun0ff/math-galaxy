extends RefCounted
class_name DecompositionEngine

# Presentation-agnostic guided steps. Each question carries its own correct answer.
static func steps(q: Dictionary, strategy: String = "tens") -> Array[Dictionary]:
	var a: int = int(q["a"])
	var b: int = int(q["b"])
	var world: int = int(q["world"])
	var result: Array[Dictionary] = []
	if world == 1:
		return result
	if world == 5:
		var quotient: int = int(a / b)
		var base: int = int(quotient / 10) * 10
		if strategy == "halves" or base == 0 or base >= quotient:
			base = maxi(1, int(quotient / 2))
		var remaining: int = quotient - base
		result.append({"prompt": "How much is %d × %d?" % [b, base], "expression": "%d × %d" % [b, base], "answer": b * base})
		result.append({"prompt": "How much is %d - %d?" % [a, b * base], "expression": "%d - %d" % [a, b * base], "answer": b * remaining})
		result.append({"prompt": "How many groups of %d are in %d?" % [b, b * remaining], "expression": "%d ÷ %d" % [b * remaining, b], "answer": remaining})
		result.append({"prompt": "Add %d + %d" % [base, remaining], "expression": "%d + %d" % [base, remaining], "answer": quotient})
		return result
	if world == 4:
		var tens_b: int = int(b / 10) * 10
		var units_b: int = b % 10
		result.append({"prompt": "How much is %d × %d?" % [a, tens_b], "expression": "%d × %d" % [a, tens_b], "answer": a * tens_b})
		result.append({"prompt": "How much is %d × %d?" % [a, units_b], "expression": "%d × %d" % [a, units_b], "answer": a * units_b})
		result.append({"prompt": "Add %d + %d" % [a * tens_b, a * units_b], "expression": "%d + %d" % [a * tens_b, a * units_b], "answer": a * b})
		return result
	var place: int = 100 if world == 3 else 10
	var parts: Array[int] = []
	while place >= 1:
		var part: int = int(a / place) % 10 * place
		if part > 0:
			parts.append(part)
		place = int(place / 10)
	var total: int = 0
	for part in parts:
		result.append({"prompt": "How much is %d × %d?" % [part, b], "expression": "%d × %d" % [part, b], "answer": part * b})
		total += part * b
	if parts.size() > 1:
		var add_parts: Array[String] = []
		for part in parts:
			add_parts.append(str(part * b))
		result.append({"prompt": "Add the partial products", "expression": " + ".join(add_parts), "answer": total})
	return result

# Compact representation shown above the keypad; no hidden final answer.
static func explanation(q: Dictionary, strategy: String = "tens") -> String:
	var a: int = int(q["a"])
	var b: int = int(q["b"])
	var world: int = int(q["world"])
	if world == 5:
		var quotient: int = int(a / b)
		var first: int = int(quotient / 10) * 10
		if strategy == "halves" or first == 0 or first >= quotient:
			first = maxi(1, int(quotient / 2))
		var part_a: int = b * first
		return "%d = %d + %d   →   (%d ÷ %d) + (%d ÷ %d)" % [a, part_a, a - part_a, part_a, b, a - part_a, b]
	if world == 4:
		return "%d × (%d + %d)" % [a, int(b / 10) * 10, b % 10]
	var place: int = 100 if world == 3 else 10
	var chunks: Array[String] = []
	while place >= 1:
		var part: int = int(a / place) % 10 * place
		if part > 0:
			chunks.append(str(part))
		place = int(place / 10)
	return "(%s) × %d" % [" + ".join(chunks), b]
