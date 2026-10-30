extends RefCounted
class_name WorkshopEngine

const DECOMPOSITION = preload("res://scripts/DecompositionEngine.gd")

static func prepare(question: Dictionary, mode: String) -> Dictionary:
	var steps: Array[Dictionary] = DECOMPOSITION.steps(question)
	return {"question": question.duplicate(true), "mode": mode, "steps": steps, "index": 0, "mistakes": 0, "hints": 0, "complete": false, "independent": mode == "solo"}

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
		session["index"] = int(session["index"]) + 1
		session["complete"] = int(session["index"]) >= session["steps"].size()
	else:
		session["mistakes"] = int(session["mistakes"]) + 1
	return correct

static func reveal(session: Dictionary) -> void:
	if current_step(session).is_empty():
		return
	session["hints"] = int(session["hints"]) + 1
	session["independent"] = false

static func summary(session: Dictionary) -> Dictionary:
	return {"world": int(session["question"]["world"]), "mode": str(session["mode"]), "completed": bool(session["complete"]), "mistakes": int(session["mistakes"]), "hints": int(session["hints"]), "independent": bool(session["independent"]) and int(session["mistakes"]) == 0 and bool(session["complete"])}
