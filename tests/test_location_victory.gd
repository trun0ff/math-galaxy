extends SceneTree
const P = preload("res://scripts/LearningProgression.gd")
const S = preload("res://scripts/SaveManager.gd")
const L = preload("res://scripts/Localization.gd")
class TestMain extends "res://scripts/Main.gd":
	func save_progress() -> void: pass
	func load_progress() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var host := TestMain.new()
	root.add_child(host)
	host.set_process(false)
	host.progress = S.migrate({"skills": {}})
	host.start_mission()
	host.art.set_process(false)
	for mistake in range(2):
		host.resolve_answer(-1, "skip")
		host.art._process(0.5)
		host._process(1.1)
	for correct in range(10):
		host.resolve_answer(host.question.answer, "answer")
		host.art._process(0.6)
		host._process(1.1)
	assert(host.finished and host.hits == 10 and host.misses == 2)
	assert(P.is_unlocked(host.progress, 1, 1))
	assert(not P.is_unlocked(host.progress, 1, 2))
	# Travel unlocks immediately, while mastery still needs independent evidence.
	assert(not P.can_pass(host.progress, 1, 0))
	var path := "res://.test-user/location-victory-save.json"
	assert(S.write_save(path, host.progress))
	assert(not S.validate({"skills": {"fact": {"correct": true}}}))
	assert(S.validate({"skills": {"fact": {"history": [{"correct": true}]}}}))
	assert(P.is_unlocked(S.load_profile(path).data, 1, 1))
	for language in ["en", "uk"]:
		L.apply_language(language)
		host.show_levels()
		await process_frame
		await process_frame
		assert(host.find_child("PracticeOnly", true, false).tooltip_text != "")
		var grid: GridContainer = host.find_child("SublevelGrid", true, false)
		for card in grid.get_children():
			var image: TextureRect = card.find_child("LocationPreview", true, false)
			var locked: bool = card.get_index() >= 2
			assert((image.material != null) == locked)
			assert((image.get_node_or_null("LocationLock") != null) == locked)
			assert(card.material == null)
			for label in card.find_children("*", "Label", true, false):
				assert(label.material == null and label.modulate.a == 1)
		if language == "en":
			assert(L.text("WORLD %d - SUBLEVELS") == "WORLD %d - LOCATIONS")
			assert(L.text("retry this level") == "retry this location")
		else:
			assert(L.text("SUBLEVEL PASSED") == "ЛОКАЦІЮ ПРОЙДЕНО")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.test-user/locations-" + language + ".png")
	var history := {"schema_version": 14, "skills": {}, "mission_history": [
		{"world": 1, "level": 0, "won": true, "hits": 10, "misses": 2},
		{"world": 1, "level": 1, "won": true, "hits": 10, "practice": true},
		{"world": 1, "level": 2, "won": false, "hits": 10},
		{"world": 1, "level": 3, "won": true, "hits": 2}
	]}
	var migrated := S.migrate(history)
	assert(P.is_unlocked(migrated, 1, 1))
	assert(not P.is_unlocked(migrated, 1, 2))
	assert(migrated.skills.is_empty() and migrated.level_evidence.is_empty())
	assert(S.migrate(migrated) == migrated)
	assert(not P.complete_victory(migrated, 1, 1, 10, 1, 100))
	assert(not P.complete_victory(migrated, 1, 1, 10, 0, 0))
	assert(not P.complete_victory(migrated, 1, 1, 10, 0, 100, true))
	host.free()
	L.apply_language("en")
	print("Location victory, image blur and terminology tests passed")
	quit()
