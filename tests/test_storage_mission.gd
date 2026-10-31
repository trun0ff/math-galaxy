extends SceneTree
const S = preload("res://scripts/SaveManager.gd")
const M = preload("res://scripts/MissionManager.gd")
const T = preload("res://scripts/SkillTaxonomy.gd")
const R = preload("res://scripts/ReviewScheduler.gd")
const MATH = preload("res://scripts/MathEngine.gd")
const DATA = preload("res://scripts/ParentData.gd")

func _initialize() -> void:
	seed(1300)
	for world in range(1, 6):
		for i in range(1000):
			var q := MATH.generate(world)
			assert(T.world_for_key(T.key_for(q)) == world)
			var options := MATH.options(q)
			assert(options.size() == 4 and options.has(int(q.answer)))
			var unique := {}
			for option in options:
				assert(option > 0 and not unique.has(option))
				unique[option] = true
			if world == 1: assert(q.a >= 2 and q.a <= 9 and q.b >= 2 and q.b <= 9)
			if world == 2: assert(q.a >= 10 and q.a <= 99 and q.b >= 2 and q.b <= 9)
			if world == 3: assert(q.a >= 100 and q.a <= 999 and q.b >= 2 and q.b <= 9)
			if world == 4: assert(q.a >= 10 and q.a <= 99 and q.b >= 10 and q.b <= 99)
			if world == 5:
				assert(q.a % q.b == 0)
				assert((q.a >= 10 and q.a <= 99 and q.b >= 2 and q.b <= 9) or (q.a >= 100 and q.a <= 999 and q.b >= 10 and q.b <= 99))
	for pair in [[12, 2, "w2_no_carry"], [19, 9, "w2_carry"], [111, 2, "w3_no_carry"], [119, 2, "w3_carry"], [199, 9, "w3_multi_carry"]]:
		assert(T.key_for({"world": 2 if pair[0] < 100 else 3, "a": pair[0], "b": pair[1]}) == pair[2])
	var stats := {"attempts": 1}
	var day := 100
	for interval in [1, 3, 7, 14, 30, 30]:
		stats = R.schedule(stats, day, true, false)
		assert(stats.next_review_day == day + interval)
		assert(not R.is_due(stats, day + interval - 1))
		assert(R.is_due(stats, day + interval))
		assert(R.schedule(stats, day, true, false) == stats)
		day += interval
	stats = R.schedule(stats, day, false, true)
	assert(stats.review_stage == -1 and stats.next_review_day == day + 1)
	var path := "user://v13_test_%d.json" % Time.get_ticks_usec()
	var legacy := {"coins": 123, "missions": 4, "unlocked_world": 3, "skills": {"1_2_3": {"correct": 5}}}
	assert(S.write_text(path, JSON.stringify(legacy)))
	var loaded := S.load_profile(path)
	assert(loaded.writable and loaded.warning == "")
	assert(loaded.data.coins == 123 and loaded.data.legacy_unlocked_world == 3)
	assert(loaded.data.skills["1_2_3"].correct == 5 and loaded.data.schema_version == 13)
	assert(S.write_save(path, loaded.data))
	assert(S.read_profile(path + ".bak").coins == 123)
	assert(S.write_text(path, "{broken"))
	loaded = S.load_profile(path)
	assert(loaded.writable and loaded.warning != "" and loaded.data.coins == 123)
	assert(S.write_save(path, loaded.data))
	assert(S.read_profile(path).coins == 123)
	assert(S.write_text(path, "{broken"))
	assert(S.write_text(path + ".bak", "[]"))
	loaded = S.load_profile(path)
	assert(not loaded.writable and loaded.warning != "")
	assert(FileAccess.get_file_as_string(path) == "{broken")
	assert(not S.validate({"skills": {}, "schema_version": 99}))
	assert(not S.validate({"skills": {}, "mission_history": [42]}))
	assert(not S.validate({"skills": {}, "coins": "bad"}))
	assert(not S.validate({"skills": {}, "parent_settings": {"limits": [1]}}))
	assert(DATA.validate(S.migrate({"coins": 7})))
	for duration in [120.0, 300.0, 900.0]:
		var limits := M.phase_limits(duration)
		assert(M.phase_at(0, limits) == 0)
		for i in range(4):
			assert(M.phase_at(limits[i] - 0.001, limits) == i)
			assert(M.phase_at(limits[i], limits) == i + 1)
		assert(M.phase_at(duration, limits) == 4)
	# Remove only this test's uniquely named files, including preserved corrupt data.
	var dir := DirAccess.open("user://")
	for name in dir.get_files():
		if name.begins_with(path.get_file()): dir.remove(name)
	print("Storage and mission tests passed")
	quit()
