extends RefCounted
class_name WorkshopEngine

const DECOMPOSITION = preload("res://scripts/DecompositionEngine.gd")

static func prepare(question: Dictionary, mode: String) -> Dictionary:
	var steps: Array[Dictionary] = DECOMPOSITION.steps(question)
	# End guided work with a full, unassisted calculation. Solo starts with it.
	var final_step: Dictionary = {"prompt": "Now solve the original problem", "answer": int(question["answer"])}
	if mode == "solo":
		steps = [final_step]
	else:
		steps.append(final_step)
	return {"question": question.duplicate(true), "mode": mode, "steps": steps, "index": 0, "mistakes": 0, "hints": 0, "complete": false, "independent": mode == "solo", "strategy": "tens", "step_results": [], "step_errors": {}, "revealed_review": false}

static func current_step(session: Dictionary) -> Dictionary:
	var index: int = int(session.get("index", 0))
	var steps: Array = session.get("steps", [])
	if index < 0 or index >= steps.size():
		return {}
	return steps[index]

static func check(session: Dictionary, submitted: int) -> bool:
	var step: Dictionary = current_step(session)
	if step.is_empty():
		return false
	var correct: bool = submitted == int(step["answer"])
	if correct:
		var step_index: int = int(session["index"])
		var history: Array = session.get("step_results", [])
		var assisted: bool = bool(session.get("current_hint", false))
		history.append({"step": step_index, "answer": submitted, "source": "hint" if assisted else "self", "mistakes": int(session.get("step_errors", {}).get(step_index, 0))})
		session["step_results"] = history
		session["current_hint"] = false
		session["index"] = step_index + 1
		session["complete"] = int(session["index"]) >= session["steps"].size()
	else:
		session["mistakes"] = int(session["mistakes"]) + 1
		var errors: Dictionary = session.get("step_errors", {})
		var failed_index: int = int(session["index"])
		errors[failed_index] = int(errors.get(failed_index, 0)) + 1
		session["step_errors"] = errors
	return correct

static func reveal(session: Dictionary) -> void:
	if current_step(session).is_empty():
		return
	session["hints"] = int(session["hints"]) + 1
	session["independent"] = false
	session["current_hint"] = true

static func summary(session: Dictionary) -> Dictionary:
	return {"world": int(session["question"]["world"]), "mode": str(session["mode"]), "completed": bool(session["complete"]), "mistakes": int(session["mistakes"]), "hints": int(session["hints"]), "independent": bool(session["independent"]) and int(session["mistakes"]) == 0 and bool(session["complete"])}

static func change_strategy(session: Dictionary, strategy: String) -> void:
	if session.get("mode", "") == "solo":
		# Solo mode keeps the full original question regardless of method.
		session["strategy"] = strategy
		return
	var steps: Array[Dictionary] = DECOMPOSITION.steps(session["question"], strategy)
	steps.append({"prompt": "Now solve the original problem", "answer": int(session["question"]["answer"])})
	session["steps"] = steps
	session["index"] = 0
	session["strategy"] = strategy
	session["complete"] = false
	session["step_results"] = []
	session["step_errors"] = {}
	session["current_hint"] = false

# Guided scaffolding fades only after several completed clean guided sessions.
# Demonstrations and assisted sessions never increase the clean streak.
static func guidance_level(progress: Dictionary, world_id: int, mode: String) -> int:
	if mode != "guided":
		return 0
	var streak: int = int(progress.get("workshop_clean_streak", {}).get(str(world_id), 0))
	if streak >= 6:
		return 2
	if streak >= 3:
		return 1
	return 0

static func record_guided_streak(progress: Dictionary, outcome: Dictionary) -> void:
	if str(outcome.get("mode", "")) != "guided":
		return
	var streaks: Dictionary = progress.get("workshop_clean_streak", {})
	var key: String = str(outcome.get("world", 0))
	if bool(outcome.get("completed", false)) and int(outcome.get("mistakes", 0)) == 0 and int(outcome.get("hints", 0)) == 0:
		streaks[key] = mini(10, int(streaks.get(key, 0)) + 1)
	else:
		streaks[key] = 0
	progress["workshop_clean_streak"] = streaks
