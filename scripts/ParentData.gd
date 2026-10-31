extends RefCounted

const DEFAULT_LIMITS = [8, 20, 35, 60, 45]

static func duration(p: Dictionary) -> float:
	return clampf(float(p.get("parent_settings", {}).get("duration", 300)), 120, 900)

static func limits(p: Dictionary) -> Array:
	var result: Array = DEFAULT_LIMITS.duplicate()
	var values: Variant = p.get("parent_settings", {}).get("limits", result)
	if values is Array and values.size() == 5:
		for i in range(5):
			result[i] = clampf(float(values[i]), 5, 180)
	return result

static func add(bucket: Dictionary, correct: bool, seconds: float) -> void:
	bucket["n"] = int(bucket.get("n", 0)) + 1
	bucket["ok"] = int(bucket.get("ok", 0)) + int(correct)
	bucket["seconds"] = float(bucket.get("seconds", 0)) + seconds
	# Millisecond histogram retains exact median of recorded rounded times.
	var histogram: Dictionary = bucket.get("times", {})
	var key := str(roundi(seconds * 1000))
	histogram[key] = int(histogram.get(key, 0)) + 1
	bucket["times"] = histogram

static func record(p: Dictionary, q: Dictionary, world: int, level: int, correct: bool, mode: String, hinted: bool, seconds: float, source: String) -> void:
	var d: Dictionary = p.get("diagnostics", {})
	var category := "demo" if mode == "demo" else "assisted" if hinted else "choice" if mode == "choices" else "independent"
	var date := Time.get_date_string_from_system(true)
	var day := int(Time.get_unix_time_from_system() / 86400)
	var keys: Array = [source + "/" + category, "day/" + date + "/" + category, "week/" + str(int(floor(float(day + 3) / 7))) + "/" + category]
	if source == "battle":
		keys.append("world/%d/%s" % [world, category])
		keys.append("level/%d:%d/%s" % [world, level, category])
		keys.append("fact/%s/%s" % [q["key"], category])
	for key in keys:
		var bucket: Dictionary = d.get(key, {})
		add(bucket, correct, clampf(seconds, 0, 3600))
		d[key] = bucket
	p["diagnostics"] = d

static func median(bucket: Dictionary) -> float:
	var histogram: Dictionary = bucket.get("times", {})
	var values: Array = histogram.keys()
	values.sort_custom(func(a, b): return int(a) < int(b))
	var n := int(bucket.get("n", 0))
	if n == 0: return 0
	var count := 0
	var left := -1.0
	for key in values:
		count += int(histogram[key])
		if left < 0 and count > int((n - 1) / 2): left = float(key)
		if count > int(n / 2): return (left + float(key)) / 2000.0
	return 0

static func summary(b: Dictionary) -> String:
	var n := int(b.get("n", 0))
	if n == 0: return "No data"
	return "%d/%d correct (%.1f%%), mean %.2fs, median %.2fs" % [int(b.get("ok", 0)), n, 100.0 * float(b.get("ok", 0)) / n, float(b.get("seconds", 0)) / n, median(b)]

static func mission(p: Dictionary, world: int, level: int, seconds: float, hits: int, misses: int, won: bool) -> void:
	var rows: Array = p.get("mission_history", [])
	rows.append({"date": Time.get_datetime_string_from_system(true), "world": world, "level": level, "seconds": seconds, "hits": hits, "misses": misses, "won": won})
	p["mission_history"] = rows.slice(maxi(0, rows.size() - 100))
	p["missions_recorded"] = int(p.get("missions_recorded", 0)) + 1

static func write_save(path: String, p: Dictionary) -> bool:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(p))
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path)) == OK

static func validate(value: Variant) -> bool:
	if not value is Dictionary or not value.get("skills") is Dictionary: return false
	if not valid_tree(value): return false
	if value.has("missions") and not (value.missions is int or value.missions is float): return false
	if int(value.get("schema_version", 0)) > 11: return false
	for key in ["skills", "strategies", "workshop_steps", "completed_levels", "level_evidence", "parent_settings", "diagnostics", "parent_pin", "learning_config", "workshop_clean_streak", "workshop_totals", "rewards"]:
		if value.has(key) and not value[key] is Dictionary: return false
	for key in ["mission_history", "workshop_history"]:
		if value.has(key) and not value[key] is Array: return false
	for key in ["skills", "strategies", "workshop_steps", "diagnostics", "level_evidence"]:
		for item in value.get(key, {}).values():
			if not item is Dictionary: return false
	var rewards: Dictionary = value.get("rewards", {})
	for key in ["owned", "achievements", "days", "records"]:
		if rewards.has(key) and not rewards[key] is Dictionary: return false
	if rewards.has("settled") and (not (rewards.settled is int or rewards.settled is float) or not is_finite(float(rewards.settled)) or float(rewards.settled) < 0): return false
	if rewards.has("equipped") and not rewards.equipped is String: return false
	for record in rewards.get("records", {}).values():
		if not record is Dictionary: return false
		if record.has("accuracy") and (not (record.accuracy is int or record.accuracy is float) or not is_finite(float(record.accuracy)) or float(record.accuracy) < 0 or float(record.accuracy) > 1): return false
	var settings: Dictionary = value.get("parent_settings", {})
	if settings.has("duration") and not (settings.duration is float or settings.duration is int): return false
	if settings.has("limits"):
		if not settings.limits is Array or settings.limits.size() != 5: return false
		for number in settings.limits:
			if not (number is float or number is int): return false
	for row in value.get("mission_history", []):
		for key in ["date", "world", "level", "seconds", "hits", "misses", "won"]:
			if not row.has(key): return false
	return true

static func valid_tree(value: Variant, depth: int = 0) -> bool:
	if depth > 24: return false
	if value is Dictionary:
		for key in value:
			var item: Variant = value[key]
			if str(key) in ["coins", "schema_version", "mission_sequence", "workshop_sequence", "attempt_sequence", "legacy_unlocked_world", "unlocked_world", "n", "ok", "seconds", "world", "level", "hits", "misses", "attempts", "correct", "wrong", "total_ms", "independent_correct", "fast", "evidence_version", "review_stage", "next_review_day", "hints", "duration"]:
				if not (item is int or item is float) or not is_finite(float(item)) or float(item) < -1: return false
			if str(key) in ["history", "step_results", "limits", "mission_history", "workshop_history"] and not item is Array: return false
			if str(key) in ["history", "step_results", "mission_history", "workshop_history"]:
				for row in item:
					if not row is Dictionary: return false
			if str(key) in ["times", "attempt_ids", "successful_days", "successful_missions", "default", "worlds", "distinct", "boss_distinct"] and not item is Dictionary: return false
			if str(key) == "times":
				for time in item:
					if not str(time).is_valid_int() or not (item[time] is int or item[time] is float) or float(item[time]) < 0: return false
			if not valid_tree(item, depth + 1): return false
	elif value is Array:
		for item in value:
			if not valid_tree(item, depth + 1): return false
	return true
