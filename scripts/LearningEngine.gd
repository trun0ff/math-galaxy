extends RefCounted
class_name LearningEngine

const REVIEW_SCHEDULER = preload("res://scripts/ReviewScheduler.gd")
const SCHEMA_VERSION := 4
const MAX_HISTORY := 120
const DEFAULT_CRITERIA := {"min_independent": 5, "min_fast": 3, "min_days": 2, "min_missions": 2, "fast_seconds": 3.0, "good_seconds": 5.0, "speed_scale": 1.0, "interval_days": [1, 3, 7, 14, 30]}

static func migrate(stats: Dictionary) -> Dictionary:
	var s: Dictionary = stats.duplicate(true)
	if int(s.get("evidence_version", 0)) != SCHEMA_VERSION:
		# Preserve old aggregates verbatim, but do not infer trustworthy evidence.
		if not s.is_empty():
			s = {"legacy": s}
		s["evidence_version"] = SCHEMA_VERSION
	return s

static func criteria_for(progress: Dictionary, world: int) -> Dictionary:
	var config: Dictionary = progress.get("learning_config", {})
	var result: Dictionary = DEFAULT_CRITERIA.duplicate(true)
	var limits: Array = [8.0, 20.0, 35.0, 60.0, 45.0]
	result["fast_seconds"] = float(limits[clampi(world, 1, 5) - 1]) * 0.375
	result["good_seconds"] = float(limits[clampi(world, 1, 5) - 1]) * 0.625
	result.merge(config.get("default", {}), true)
	result.merge(config.get("worlds", {}).get(str(world), {}), true)
	return result

static func record(stats: Dictionary, correct: bool, reason: String, seconds: float, mode: String, hinted: bool, mission_id: int, day: int, attempt_id: String = "", criteria: Dictionary = {}) -> Dictionary:
	var s: Dictionary = migrate(stats)
	var config: Dictionary = DEFAULT_CRITERIA.duplicate(true)
	config.merge(criteria, true)
	var ids: Dictionary = s.get("attempt_ids", {}).duplicate()
	if not attempt_id.is_empty() and ids.has(attempt_id):
		return s
	if not attempt_id.is_empty():
		ids[attempt_id] = true
	s["attempt_ids"] = ids
	seconds = maxf(0.0, seconds)
	var independent: bool = correct and reason == "answer" and not hinted and mode == "numeric"
	var fast: bool = independent and seconds <= float(config["fast_seconds"]) * maxf(0.1, float(config["speed_scale"]))
	var good: bool = independent and seconds <= float(config["good_seconds"]) * maxf(0.1, float(config["speed_scale"]))
	var failed: bool = not correct and mode != "demo"
	# Evidence counters start from zero; legacy aggregates live under legacy.
	s["attempts"] = int(s.get("attempts", 0)) + 1
	s["correct"] = int(s.get("correct", 0)) + (1 if correct else 0)
	s["wrong"] = int(s.get("wrong", 0)) + (0 if correct else 1)
	s["hints"] = int(s.get("hints", 0)) + (1 if hinted else 0)
	s["total_ms"] = int(s.get("total_ms", 0)) + roundi(seconds * 1000.0)
	s["fast"] = int(s.get("fast", 0)) + (1 if fast else 0)
	s["independent_correct"] = int(s.get("independent_correct", 0)) + (1 if independent else 0)
	s["demonstrations"] = int(s.get("demonstrations", 0)) + int(mode == "demo")
	s["choice_attempts"] = int(s.get("choice_attempts", 0)) + int(mode == "choices")
	s["choice_correct"] = int(s.get("choice_correct", 0)) + (1 if correct and mode == "choices" else 0)
	s["hinted_correct"] = int(s.get("hinted_correct", 0)) + (1 if correct and hinted else 0)
	s["skips"] = int(s.get("skips", 0)) + (1 if reason == "skip" else 0)
	s["timeouts"] = int(s.get("timeouts", 0)) + (1 if reason == "timeout" else 0)
	var history: Array = s.get("history", []).duplicate(true)
	history.append({"day": day, "mission": mission_id, "correct": correct, "seconds": seconds, "mode": mode, "hinted": hinted, "assisted": hinted or mode != "numeric", "reason": reason, "id": attempt_id})
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
	var previous: String = effective_state(s, day)
	var ready: bool = int(s["independent_correct"]) >= int(config["min_independent"]) and int(s["fast"]) >= int(config["min_fast"]) and days.size() >= maxi(2, int(config["min_days"])) and missions.size() >= int(config["min_missions"])
	if failed and (previous == "MASTERED" or previous == "REVIEW_REQUIRED"):
		s["state"] = "REVIEW_REQUIRED"
	elif ready and recent_failures == 0 and good:
		s["state"] = "MASTERED"
	elif previous == "MASTERED":
		s["state"] = "MASTERED"
	elif previous == "REVIEW_REQUIRED" and not good:
		s["state"] = "REVIEW_REQUIRED"
	elif previous == "REVIEW_REQUIRED":
		s["state"] = "REVIEW_REQUIRED"
	elif recent_failures >= 2:
		s["state"] = "LEARNING"
	elif int(s["independent_correct"]) >= 2:
		s["state"] = "PRACTICING"
	else:
		s["state"] = "LEARNING"
	s = REVIEW_SCHEDULER.schedule(s, day, good, failed, config["interval_days"])
	return s

static func effective_state(stats: Dictionary, day: int) -> String:
	var state: String = str(migrate(stats).get("state", "NEW"))
	if state == "MASTERED" and REVIEW_SCHEDULER.is_due(stats, day):
		return "REVIEW_REQUIRED"
	return state
