extends SceneTree
const M = preload("res://scripts/MathEngine.gd")
const P = preload("res://scripts/LearningProgression.gd")
const L = preload("res://scripts/LearningEngine.gd")
class TestMain extends "res://scripts/Main.gd":
	func save_progress() -> void:
		pass

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for world in range(1, 6):
		for i in range(1000):
			var q: Dictionary = M.generate(world)
			check_question(q)
			for level in range(P.levels(world).size()):
				check_question(P.generate(world, level))
	var sample := {"a": 7, "b": 8, "world": 1, "sign": "×", "answer": 56}
	var hints: Array[String] = M.hint_stages(sample)
	assert(hints[0].contains("5 × 8") and not hints[0].contains("56"))
	assert(hints[1].contains("(5 × 8) + (2 × 8)"))
	assert(hints[2].contains("40 + 16 = 56"))
	var stats := L.record({}, true, "answer", 1.0, "numeric", true, 1, 1, "hint")
	assert(stats.independent_correct == 0 and stats.history[0].assisted)
	assert(L.record(stats, true, "answer", 1.0, "numeric", true, 1, 1, "hint") == stats)
	var app := TestMain.new()
	# Do not add Main to the tree: never load or write the player's save.
	app.start_mission()
	assert(app.energy == 50 and app.shield == 100)
	var initial_limit: float = app.question_limit
	var sequence: int = app.progress.attempt_sequence
	for cost in [25, 15, 10]:
		var before: int = app.energy
		app.use_hint()
		assert(app.energy == before - cost)
	assert(app.hint_stage == 3 and app.energy == 0)
	assert(app.question_limit == initial_limit + 18.0)
	app.use_hint()
	assert(app.energy == 0 and app.progress.attempt_sequence == sequence and app.queue.size() == 1)
	var queued_key: String = app.question.key
	app.progress.attempt_sequence = sequence + 3
	assert(app.choose_question().key == queued_key and app.queue.is_empty())
	app.energy = 0
	app.hint_stage = 0
	app.use_hint()
	assert(app.hint_stage == 0 and app.energy == 0)
	app.hint_used = true
	var hp: int = app.art.enemy_hp
	app.resolve_answer(app.question.answer, "answer")
	assert(app.hits == 1 and app.combo == 1 and app.art.enemy_hp == hp - 1)
	assert(app.progress.skills[app.question.key].independent_correct == 0)
	app.art.set_boss_mode(true)
	assert(app.art.enemy_hp == 6)
	for i in range(6): app.art.hit_enemy()
	assert(app.art.enemy_hp == 6 and app.art.enemy_index == 1)
	for boundary in [0.0, 35.0, 85.0, 235.0, 280.0]:
		app.elapsed = boundary
		assert(app.determine_phase() == [0.0, 35.0, 85.0, 235.0, 280.0].find(boundary))
	app.elapsed = 279.5
	app.phase = 3
	app.transition_delay = 1.0
	app._process(0.5)
	assert(app.phase == 4 and not app.finished and app.elapsed == 280.0)
	app._process(19.0)
	assert(not app.finished)
	app._process(1.0)
	assert(app.finished and app.elapsed == 300.0)
	app.start_mission()
	assert(app.combo == 0 and app.hits == 0 and not app.finished and app.queue.is_empty())
	app.shield = 50
	app.combo = 4
	app.resolve_answer(app.question.answer, "answer")
	assert(app.combo == 5 and app.shield == 65)
	app.next_question()
	app.shield = 20
	var coins: int = app.progress.coins
	app.resolve_answer(-1, "skip")
	assert(app.shield == 0 and app.pending_defeat and app.combo == 0)
	app.finish_mission()
	assert(app.screen == "game_over" and app.progress.coins == coins)
	app.start_mission()
	assert(app.shield == 100 and app.energy == 50 and not app.pending_defeat)
	app.free()
	print("Hints, generators and battle tests passed")
	quit()

func check_question(q: Dictionary) -> void:
	if q.sign == "÷":
		assert(int(q.a) % int(q.b) == 0 and int(q.a) / int(q.b) == int(q.answer))
	else:
		assert(int(q.a) * int(q.b) == int(q.answer))
	for alternate in [false, true]:
		var hints: Array[String] = M.hint_stages(q, alternate)
		assert(hints.size() == 3 and hints[2].ends_with(str(q.answer)))

		var expression := Expression.new()
		var formula: String = hints[1].split(" = ")[1].replace("×", "*").replace("÷", "/")
		assert(expression.parse(formula) == OK)
		var result = expression.execute()
		assert(not expression.has_execute_failed() and is_equal_approx(float(result), float(q.answer)))
