extends RefCounted

const L10N = preload("res://scripts/Localization.gd")

const VERSION := 14
const REWARDS = preload("res://scripts/RewardManager.gd")

static func migrate(value: Dictionary) -> Dictionary:
	var p := value.duplicate(true)
	if not p.has("skills"): p["skills"] = {}
	for key in ["strategies", "completed_levels", "level_evidence"]:
		if not p.has(key): p[key] = {}
	if not p.has("legacy_unlocked_world"):
		p["legacy_unlocked_world"] = int(p.get("unlocked_world", 1))
	if int(p.get("schema_version", 0)) < 14:
		# Preserve old independent passes as both halves of the same skill.
		for bucket in ["completed_levels", "level_evidence"]:
			var remapped: Dictionary = {}
			for key in p[bucket]:
				var parts: PackedStringArray = str(key).split(":")
				if parts.size() != 2: continue
				var base: String = parts[0] + ":"
				var index: int = int(parts[1]) * 2
				remapped[base + str(index + 1)] = p[bucket][key]
				if bucket == "completed_levels": remapped[base + str(index)] = p[bucket][key]
			p[bucket] = remapped
	REWARDS.migrate(p)
	p["schema_version"] = VERSION
	return p

static func read_profile(path: String) -> Variant:
	if not FileAccess.file_exists(path): return null
	if FileAccess.get_file_as_bytes(path).size() > 16000000: return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return null
	var value: Variant = parser.data
	# Earliest profiles had no skills bucket.
	if value is Dictionary and not value.has("skills"): value["skills"] = {}
	return migrate(value) if validate(value) else null

static func load_profile(path: String) -> Dictionary:
	var value: Variant = read_profile(path)
	if value != null: return {"data": value, "warning": "", "writable": true}
	var backup: Variant = read_profile(path + ".bak")
	if backup != null:
		return {"data": backup, "warning": L10N.text("Profile recovered from backup. The original file is preserved until the next save."), "writable": true}
	var damaged := FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")
	return {"data": migrate({"coins": 0, "missions": 0, "skills": {}}), "warning": L10N.text("Profile cannot be read. Files preserved; saving is disabled. Restore a valid profile from the parent screen.") if damaged else "", "writable": not damaged}

static func write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	return error == OK

static func write_save(path: String, p: Dictionary) -> bool:
	if not validate(p): return false
	var clean := migrate(p)
	if not write_text(path + ".tmp", JSON.stringify(clean)): return false
	if read_profile(path + ".tmp") == null: return false
	if FileAccess.file_exists(path):
		if read_profile(path) != null:
			if not write_text(path + ".bak.tmp", FileAccess.get_file_as_string(path)): return false
			if DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak") != OK: return false
		else:
			# Preserve corrupt or unsupported data before replacing it.
			var preserved := path + ".unreadable_%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
			if DirAccess.copy_absolute(path, preserved) != OK: return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

static func validate(value: Variant) -> bool:
	if not value is Dictionary or not value.get("skills") is Dictionary: return false
	if not valid_tree(value): return false
	if value.has("missions") and not (value.missions is int or value.missions is float): return false
	if int(value.get("schema_version", 0)) > VERSION: return false
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
		if not settings.limits is Array or settings.limits.size() not in [5, 8]: return false
		for number in settings.limits:
			if not (number is float or number is int): return false
	for row in value.get("mission_history", []):
		for key in ["date", "world", "level", "seconds", "hits", "misses", "won"]:
			if not row is Dictionary or not row.has(key): return false
	return true

static func valid_tree(value: Variant, depth: int = 0) -> bool:
	if value is float and not is_finite(value): return false
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
