extends RefCounted
class_name SkillTaxonomy

# A stable number of strategy buckets replaces unbounded expression-level skills
# for worlds 2-5. Existing expression statistics remain readable.
static func key_for(q: Dictionary) -> String:
	var world: int = int(q.get("world", 1))
	var a: int = int(q.get("a", 0))
	var b: int = int(q.get("b", 0))
	match world:
		1:
			return str(q.get("key", "1_%d_%d" % [a, b]))
		2:
			return "w2_%s" % ("carry" if (a % 10) * b >= 10 else "no_carry")
		3:
			var ones_carry: bool = (a % 10) * b >= 10
			var tens_carry: bool = (int(a / 10) % 10) * b >= 10
			return "w3_%s" % ("multi_carry" if ones_carry and tens_carry else "carry" if ones_carry or tens_carry else "no_carry")
		4:
			var products: int = (a % 10) * (b % 10)
			return "w4_%s" % ("carry" if products >= 10 else "no_carry")
		6, 7, 8:
			return "w%d_divide_by_%d" % [world, b]
		5:
			return "w5_%s" % ("two_digit_divisor" if b >= 10 else "one_digit_divisor")
	return "unknown"

static func world_for_key(key: String) -> int:
	if key.begins_with("w") and key.length() >= 2 and key.substr(1, 1).is_valid_int():
		return int(key.substr(1, 1))
	if key.begins_with("1_"):
		return 1
	return 0
