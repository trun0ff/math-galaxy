extends RefCounted
class_name DecompositionEngine

# Presentation-agnostic guided steps. Each question carries its own correct answer.
static func steps(q: Dictionary) -> Array[Dictionary]:
	var a: int = int(q["a"])
	var b: int = int(q["b"])
	var world: int = int(q["world"])
	var result: Array[Dictionary] = []
	if world == 1:
		return result
	if world == 5:
		var quotient: int = int(a / b)
		var base: int = int(quotient / 10) * 10
		if base == 0:
			base = maxi(1, int(quotient / 2))
		var remaining: int = quotient - base
		result.append({"prompt": "How much is %d × %d?" % [b, base], "answer": b * base})
		result.append({"prompt": "How much is %d - %d?" % [a, b * base], "answer": b * remaining})
		result.append({"prompt": "How many groups of %d are in %d?" % [b, b * remaining], "answer": remaining})
		result.append({"prompt": "Add %d + %d" % [base, remaining], "answer": quotient})
		return result
	if world == 4:
		var tens_b: int = int(b / 10) * 10
		var units_b: int = b % 10
		result.append({"prompt": "How much is %d × %d?" % [a, tens_b], "answer": a * tens_b})
		result.append({"prompt": "How much is %d × %d?" % [a, units_b], "answer": a * units_b})
		result.append({"prompt": "Add %d + %d" % [a * tens_b, a * units_b], "answer": a * b})
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
		result.append({"prompt": "How much is %d × %d?" % [part, b], "answer": part * b})
		total += part * b
	if parts.size() > 1:
		result.append({"prompt": "Add the partial products", "answer": total})
	return result
