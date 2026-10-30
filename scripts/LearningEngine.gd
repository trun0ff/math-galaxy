extends RefCounted
class_name LearningEngine

const SCHEMA_VERSION := 2
const FAST_SECONDS := 3.0
const GOOD_SECONDS := 5.0
const MAX_HISTORY := 120
const REVIEW_DAYS := [1, 3, 7, 14, 30]

static func record(stats: Dictionary, correct: bool, reason: String, seconds: float, mode: String, hinted: bool, mission_id: int, day: int) -> Dictionary:
	var s: Dictionary = stats.duplicate(true)
	# Legacy counters remain intact for older saves and screens.
	s["attempts"] = int(s.get("attempts", 0)) + 1
	s["correct"] = int(s.get("correct", 0)) + (1 if correct else 0)
	s["wrong"] = int(s.get("wrong", 0)) + (0 if correct else 1)
	s["hints"] = int(s.get("hints", 0)) + (1 if hinted else 0)
	s["total_ms"] = int(s.get("total_ms", 0)) + roundi(seconds * 1000.0)
	var independent: bool = correct and not hinted and mode == "numeric"
	var fast: bool = independent and seconds <= FAST_SECONDS
	s["fast"] = int(s.get("fast", 0)) + (1 if fast else 0)
	s["independent_correct"] = int(s.get("independent_correct", 0)) + (1 if independent else 0)
	s["choice_correct"] = int(s.get("choice_correct", 0)) + (1 if correct and mode == "choices" else 0)
	s["hinted_correct"] = int(s.get("hinted_correct", 0)) + (1 if correct and hinted else 0)
	s["skips"] = int(s.get("skips", 0)) + (1 if reason == "skip" else 0)
	s["timeouts"] = int(s.get("timeouts", 0)) + (1 if reason == "timeout" else 0)
	var history: Array = s.get("history", [])
	history.append({"day": day, "mission": mission_id, "correct": correct, "seconds": seconds, "mode": mode, "hinted": hinted, "reason": reason})
	if history.size() > MAX_HISTORY:
		history = history.slice(history.size() - MAX_HISTORY)
	s["history"] = history
	var days: Dictionary = s.get("successful_days", {})
	if independent:
		days[str(day)] = true
	s["successful_days"] = days
	var missions: Dictionary = s.get("successful_missions", {})
	if independent:
		missions[str(mission_id)] = true
	s["successful_missions"] = missions
	var recent_failures: int = 0
	for i in range(maxi(0, history.size() - 5), history.size()):
		if not bool(history[i].get("correct", false)):
			recent_failures += 1
	var prior_state: String = str(s.get("state", "NEW"))
	var ready: bool = int(s["independent_correct"]) >= 5 and int(s["fast"]) >= 3 and days.size() >= 2 and missions.size() >= 2
	if ready and recent_failures == 0:
		s["state"] = "MASTERED"
	elif prior_state == "MASTERED" or (prior_state == "REVIEW_REQUIRED" and recent_failures > 0):
		s["state"] = "REVIEW_REQUIRED"
	elif int(s["independent_correct"]) >= 2:
		s["state"] = "PRACTICING"
	else:
		s["state"] = "LEARNING"
	var stage: int = int(s.get("review_stage", 0))
	if independent and seconds <= GOOD_SECONDS:
		stage = mini(stage + 1, REVIEW_DAYS.size() - 1)
	elif not correct:
		stage = maxi(0, stage - 1)
	s["review_stage"] = stage
	s["next_review_day"] = day + REVIEW_DAYS[stage] if correct else day + 1
	return s
