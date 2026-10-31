extends SceneTree
const L = preload("res://scripts/LearningEngine.gd")
const W = preload("res://scripts/WorkshopEngine.gd")
class TestMain extends "res://scripts/Main.gd":
	func save_progress() -> void:
		pass

func _initialize() -> void:
	var s: Dictionary = {}
	for i in range(5):
		s = L.record(s, true, "answer", 2.0, "numeric", false, 1, 100, str(i))
	assert(s.state != "MASTERED")
	assert(s.review_stage == 0)
	s = L.record(s, true, "answer", 2.0, "numeric", false, 2, 101, "next_day")
	assert(s.state == "MASTERED")
	assert(s.review_stage == 1)
	assert(L.effective_state(s, 104) == "REVIEW_REQUIRED")
	var copy: Dictionary = L.record(s, true, "answer", 2.0, "numeric", false, 2, 101, "next_day")
	assert(copy == s)
	var restored: Dictionary = JSON.parse_string(JSON.stringify(s))
	assert(int(restored.independent_correct) == 6)
	assert(L.record(restored, true, "answer", 2.0, "numeric", false, 2, 101, "next_day") == restored)
	s = L.record(s, false, "answer", 1.0, "numeric", false, 3, 102, "error")
	assert(s.state == "REVIEW_REQUIRED")
	for mode in ["choices", "demo", "numeric"]:
		var assisted: Dictionary = {}
		for i in range(10):
			assisted = L.record(assisted, true, "demo" if mode == "demo" else "answer", 1.0, mode, mode == "numeric", i, 100+i, str(i))
		assert(int(assisted.independent_correct) == 0)
		assert(assisted.state != "MASTERED")
	var legacy: Dictionary = {"attempts": 900, "fast": 800, "independent_correct": 800, "state": "MASTERED"}
	var migrated: Dictionary = L.migrate(legacy)
	assert(migrated.legacy == legacy)
	assert(L.effective_state(legacy, 100) == "NEW")
	assert(L.migrate(migrated) == migrated)
	var skip: Dictionary = L.record({}, false, "skip", 3.0, "numeric", false, 1, 100)
	skip = L.record(skip, false, "timeout", 8.0, "numeric", false, 1, 100)
	assert(skip.skips == 1 and skip.timeouts == 1)
	var calibrated: Dictionary = L.record({}, true, "answer", 4.0, "numeric", false, 1, 100, "cal", {"speed_scale": 2.0})
	assert(calibrated.fast == 1)
	var app = TestMain.new()
	var q: Dictionary = {"world": 2, "a": 12, "b": 3, "answer": 36, "sign": "×", "key": "2_12_3"}
	app.progress = {"workshop_sequence": 1}
	app.workshop_session = W.prepare(q, "guided")
	app.workshop_session["session_id"] = "workshop:1"
	app.workshop_step_started = Time.get_ticks_msec()
	app.record_workshop_attempt(true, "answer")
	assert(app.progress.workshop_steps.size() == 1)
	assert(app.progress.get("strategies", {}).is_empty())
	app.workshop_session.index = app.workshop_session.steps.size() - 1
	app.record_workshop_attempt(true, "answer")
	assert(app.progress.strategies.w2_no_carry.independent_correct == 0)
	app.progress.workshop_sequence = 2
	app.workshop_session = W.prepare(q, "solo")
	app.workshop_session["session_id"] = "workshop:2"
	app.record_workshop_attempt(true, "answer")
	assert(app.progress.strategies.w2_no_carry.independent_correct == 1)
	app.progress.workshop_sequence = 3
	app.workshop_session = W.prepare(q, "demo")
	app.workshop_session["session_id"] = "workshop:3"
	app.workshop_session.index = app.workshop_session.steps.size() - 1
	app.record_workshop_attempt(true, "demo")
	assert(app.progress.strategies.w2_no_carry.independent_correct == 1)
	assert(app.progress.strategies.w2_no_carry.demonstrations == 1)
	app.workshop_session.recorded = true
	var snapshot: Dictionary = app.progress.duplicate(true)
	app.finish_workshop()
	app.finish_workshop()
	assert(app.progress == snapshot)
	var test_path: String = "res://.v9_roundtrip.tmp"
	var output = FileAccess.open(test_path, FileAccess.WRITE)
	output.store_string(JSON.stringify(app.progress))
	output.close()
	var input = FileAccess.open(test_path, FileAccess.READ)
	var loaded: Dictionary = JSON.parse_string(input.get_as_text())
	input.close()
	assert(int(loaded.strategies.w2_no_carry.independent_correct) == 1)
	assert(loaded.strategies.w2_no_carry.attempt_ids.has("workshop:2:1"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	app.free()
	print("Mastery and workshop tests passed")
	quit(0)
