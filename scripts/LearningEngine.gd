extends RefCounted
class_name LearningEngine

const REVIEW_SCHEDULER = preload("res://scripts/ReviewScheduler.gd")
const SCHEMA_VERSION := 3
const FAST_SECONDS := 3.0
const GOOD_SECONDS := 5.0
const MAX_HISTORY := 120
const MASTERY_MIN_INDEPENDENT := 5
const MASTERY_MIN_FAST := 3
const MASTERY_MIN_DAYS := 2
const MASTERY_MIN_MISSIONS := 2

static func record(stats: Dictionary, correct: bool, reason: String, seconds: float, mode: String, hinted: bool, mission_id: int, day: int) -> Dictionary:
	var s: Dictionary = stats.duplicate(true)
	var independent: bool = correct and not hinted and mode == "numeric"
	var fast: bool = independent and seconds <= FAST_SECONDS
	var good: bool = independent and seconds <= GOOD_SECONDS
	var failed: bool = not correct
	# Retain the legacy aggregate fields for existing save files.
	s["attempts"] = int(s.get("attempts", 0)) + 1
	s["correct"] = int(s.get("correct", 0)) + (1 if correct else 0)
	s["wrong"] = int(s.get("wrong", 0)) + (0 if correct else 1)
	s["hints"] = int(s.get("hints", 0)) + (1 if hinted else 0)
	s["total_ms"] = int(s.get("total_ms", 0)) + roundi(seconds * 1000.0)
	s["fast"] = int(s.get("fast", 0)) + (1 if fast else 0)
	s["independent_correct"] = int(s.get("independent_correct", 0)) + (1 if independent else 0)
	s["choice_correct"] = int(s.get("choice_correct", 0)) + (1 if correct and mode == "choices" else 0)
	s["hinted_correct"] = int(s.get("hinted_correct", 0)) + (1 if correct and hinted else 0)
	s["skips"] = int(s.get("skips", 0)) + (1 if reason == "skip" else 0)
	s["timeouts"] = int(s.get("timeouts", 0)) + (1 if reason == "timeout" else 0)
	var history: Array = s.get("history", []).duplicate(true)
	history.append({"day": day, "mission": mission_id, "correct": correct, "seconds": seconds, "mode": mode, "hinted": hinted, "reason": reason})
	if history.size() > MAX_HISTORY:
		history = history.slice(history.size() - MAX_HISTORY)
	s["history"] = history
	var days: Dictionary = s.get("successful_days", {}).duplicate(true)
	var missions: Dictionary = s.get("successful_missions", {}).duplicate(true)
	if independent:
		days[str(day)] = true
		missions[str(mission_id)] = true
	s["successful_days"] = days
	s["successful_missions"] = missions
	var recent_failures: int = 0
	for i in range(maxi(0, history.size() - 5), history.size()):
		if not bool(history[i].get("correct", false)):
			recent_failures += 1
	var previous: String = str(s.get("state", "NEW"))
	var ready: bool = int(s["independent_correct"]) >= MASTERY_MIN_INDEPENDENT and int(s["fast"]) >= MASTERY_MIN_FAST and days.size() >= MASTERY_MIN_DAYS and missions.size() >= MASTERY_MIN_MISSIONS
	if failed and (previous == "MASTERED" or previous == "REVIEW_REQUIRED"):
		s["state"] = "REVIEW_REQUIRED"
	elif ready and recent_failures == 0 and good:
		s["state"] = "MASTERED"
	elif previous == "MASTERED" and not good:
		s["state"] = "REVIEW_REQUIRED"
	elif previous == "REVIEW_REQUIRED" and recent_failures > 0:
		s["state"] = "REVIEW_REQUIRED"
	elif int(s["independent_correct"]) >= 2:
		s["state"] = "PRACTICING"
	else:
		s["state"] = "LEARNING"
	s = REVIEW_SCHEDULER.schedule(s, day, good, failed)
	return s

static func effective_state(stats: Dictionary, day: int) -> String:
	var state: String = str(stats.get("state", "NEW"))
	if state == "MASTERED" and REVIEW_SCHEDULER.is_due(stats, day):
		return "REVIEW_REQUIRED"
	return state
