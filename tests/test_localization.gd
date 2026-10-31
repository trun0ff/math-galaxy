extends SceneTree

const L10N = preload("res://scripts/Localization.gd")
const CATALOG = preload("res://scripts/TranslationCatalog.gd")
const MAIN = preload("res://scripts/Main.gd")
const DECOMPOSITION = preload("res://scripts/DecompositionEngine.gd")
const PROGRESSION = preload("res://scripts/LearningProgression.gd")

func _initialize() -> void:
	call_deferred("run")

func labels(node: Node) -> String:
	var result := ""
	if node is Label: result += node.text + "\n"
	for child in node.get_children(): result += labels(child)
	return result

func run() -> void:
	var original := FileAccess.get_file_as_bytes(L10N.SETTINGS_PATH)
	var existed := FileAccess.file_exists(L10N.SETTINGS_PATH)
	L10N.initialize()
	var host := Control.new()
	host.set_script(MAIN)
	root.add_child(host)
	host.set_process(false)
	var before: Dictionary = host.progress.duplicate(true)
	var selector: Button = host.find_child("Language_uk", true, false)
	selector.pressed.emit()
	assert(L10N.language == "uk")
	assert(labels(host).contains("ОБЕРИ СВІТ"))
	assert(host.progress == before, "Language must not change learning data")
	L10N.apply_language("en")
	L10N.initialize()
	assert(L10N.language == "uk", "Language must survive restart")
	assert(PROGRESSION.levels(1)[0].begins_with("Таблиця 2"))
	var steps := DECOMPOSITION.steps({"a": 24, "b": 3, "world": 2})
	assert(steps[0].prompt.begins_with("Скільки"))
	assert(steps[0].answer == 60)
	host.show_levels()
	assert(labels(host).contains("Таблиця 2"))
	host.world = 2
	host.show_workshop()
	assert(labels(host).contains("ПОКАЖИ МЕНІ"))
	host.show_hangar()
	assert(labels(host).contains("Фіолетовий корпус"))
	host.show_menu()
	await process_frame
	await process_frame
	assert(host.main_box.size.x <= 1280)
	selector = host.find_child("Language_en", true, false)
	selector.pressed.emit()
	assert(labels(host).contains("CHOOSE A WORLD"))
	assert(host.progress.skills == before.skills)
	# Every translated format keeps exactly the same placeholders and order.
	var pattern := RegEx.new()
	pattern.compile("%[-+0-9.]*[dsf%]")
	for source in CATALOG.UK:
		var a: Array[String] = []
		var b: Array[String] = []
		for match_source in pattern.search_all(source): a.append(match_source.get_string())
		for match_target in pattern.search_all(CATALOG.UK[source]): b.append(match_target.get_string())
		assert(a == b, source)
	L10N.apply_language("unsupported")
	assert(L10N.language == "en")
	if existed:
		var file := FileAccess.open(L10N.SETTINGS_PATH, FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	else:
		DirAccess.remove_absolute(L10N.SETTINGS_PATH)
	host.queue_free()
	await process_frame
	print("Localization tests passed")
	quit()
