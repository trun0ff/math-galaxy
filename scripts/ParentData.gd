extends RefCounted

const L10N = preload("res://scripts/Localization.gd")

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
	if n == 0: return L10N.text("No data")
	return L10N.text("%d/%d correct (%.1f%%), mean %.2fs, median %.2fs") % [int(b.get("ok", 0)), n, 100.0 * float(b.get("ok", 0)) / n, float(b.get("seconds", 0)) / n, median(b)]

static func mission(p: Dictionary, world: int, level: int, seconds: float, hits: int, misses: int, won: bool) -> void:
	var rows: Array = p.get("mission_history", [])
	rows.append({"date": Time.get_datetime_string_from_system(true), "world": world, "level": level, "seconds": seconds, "hits": hits, "misses": misses, "won": won})
	p["mission_history"] = rows.slice(maxi(0, rows.size() - 100))
	p["missions_recorded"] = int(p.get("missions_recorded", 0)) + 1

static func write_save(path: String, p: Dictionary) -> bool:
	return preload("res://scripts/SaveManager.gd").write_save(path, p)

static func validate(value: Variant) -> bool:
	return preload("res://scripts/SaveManager.gd").validate(value)
