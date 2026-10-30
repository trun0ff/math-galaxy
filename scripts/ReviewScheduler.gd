extends RefCounted
class_name ReviewScheduler

const INTERVAL_DAYS := [1, 3, 7, 14, 30]

static func is_due(stats: Dictionary, day: int) -> bool:
	return int(stats.get("attempts", 0)) > 0 and int(stats.get("next_review_day", day + 1)) <= day

static func schedule(stats: Dictionary, day: int, independent_good: bool, failed: bool) -> Dictionary:
	var result: Dictionary = stats.duplicate(true)
	var stage: int = clampi(int(result.get("review_stage", -1)), -1, INTERVAL_DAYS.size() - 1)
	if failed:
		stage = -1
		result["next_review_day"] = day + 1
	elif independent_good:
		stage = mini(stage + 1, INTERVAL_DAYS.size() - 1)
		result["next_review_day"] = day + INTERVAL_DAYS[stage]
	elif not result.has("next_review_day"):
		result["next_review_day"] = day + 1
	result["review_stage"] = stage
	return result
