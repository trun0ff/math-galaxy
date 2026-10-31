extends Control

const L10N = preload("res://scripts/Localization.gd")

const DATA = preload("res://scripts/ParentData.gd")
const KEYPAD = preload("res://scripts/ui/NeonKeypad.gd")
var host: Control
var body: VBoxContainer
var pin := ""
var first_pin := ""
var unlocked := false
var changing_pin := false
var notice: Label
var failures := 0
var blocked_until := 0

func setup(owner_node: Control) -> void:
	host = owner_node
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("07122d")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	gate()

func clear() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	button(L10N.text("Close / lock"), func(): host.show_menu(); queue_free())

func label(text: String) -> Label:
	var node := Label.new()
	node.text = L10N.text(text)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(node)
	return node

func button(text: String, action: Callable) -> void:
	var node := Button.new()
	node.text = L10N.text(text)
	node.custom_minimum_size.y = 44
	node.pressed.connect(action)
	body.add_child(node)

func gate() -> void:
	clear()
	pin = ""
	var exists: bool = host.progress.has("parent_pin") and not changing_pin
	label(L10N.text("PARENT DASHBOARD — ") + (L10N.text("Enter PIN") if exists else L10N.text("Create a 4–8 digit PIN, then repeat it")))
	label(L10N.text("Offline protection against accidental actions. This is not cryptographic security. PIN cannot be recovered here."))
	notice = label("")
	var keypad := VBoxContainer.new()
	keypad.set_script(KEYPAD)
	body.add_child(keypad)
	keypad.connect("key_pressed", func(key: String):
		if Time.get_ticks_msec() < blocked_until:
			notice.text = L10N.text("Please wait 30 seconds.")
			return
		if key == "⌫": pin = pin.left(maxi(0, pin.length() - 1))
		elif key == "OK":
			check_pin(exists)
			return
		elif pin.length() < 8 and key.is_valid_int(): pin += key
		keypad.call("set_value", "•".repeat(pin.length()))
	)

func check_pin(exists: bool) -> void:
	if pin.length() < 4:
		notice.text = L10N.text("Use 4–8 digits.")
		return
	if exists:
		var stored: Dictionary = host.progress.parent_pin
		if (str(stored.get("salt", "")) + pin).sha256_text() != stored.get("hash", ""):
			failures += 1
			if failures % 5 == 0: blocked_until = Time.get_ticks_msec() + 30000
			notice.text = L10N.text("Incorrect PIN.")
			pin = ""
			return
	else:
		if first_pin.is_empty():
			first_pin = pin
			pin = ""
			notice.text = L10N.text("Repeat the PIN and press OK.")
			return
		if pin != first_pin:
			first_pin = ""
			pin = ""
			notice.text = L10N.text("PINs did not match. Start again.")
			return
		var salt := str(Time.get_ticks_usec()) + str(randi())
		host.progress["parent_pin"] = {"salt": salt, "hash": (salt + pin).sha256_text()}
		host.save_progress()
	changing_pin = false
	unlocked = true
	dashboard()

func dashboard() -> void:
	if not unlocked: return
	clear()
	label(L10N.text("PARENT DASHBOARD"))
	label(L10N.text("Diagnostics start with v10. Existing learning evidence remains below; older response times cannot be reconstructed. All times include errors, skips and timeouts in their respective category."))
	var d: Dictionary = host.progress.get("diagnostics", {})
	for source in ["battle", "workshop"]:
		label(L10N.text(source.to_upper()))
		for category in ["independent", "choice", "assisted", "demo"]:
			label(L10N.text(category) + ": " + DATA.summary(d.get(source + "/" + category, {})))
	label(L10N.text("Completed missions (all versions): %d; tracked outcomes: %d") % [host.progress.get("missions", 0), host.progress.get("missions_recorded", 0)])
	var totals: Dictionary = host.progress.get("workshop_totals", {})
	label(L10N.text("Workshop since v10: %d completed, %d independent, %d hints, %d mistakes") % [totals.get("completed", 0), totals.get("independent", 0), totals.get("hints", 0), totals.get("mistakes", 0)])
	button(L10N.text("Worlds and sublevels"), worlds)
	button(L10N.text("8 × 8 ordered facts / problem examples"), facts)
	button(L10N.text("Days / weeks / recent missions"), history)
	button(L10N.text("Timing / local backup / reset"), settings)

func worlds() -> void:
	clear()
	button(L10N.text("Overview"), dashboard)
	var d: Dictionary = host.progress.get("diagnostics", {})
	for w in range(1, 6):
		label(host.WORLD_NAMES[w - 1])
		for category in ["independent", "choice", "assisted"]:
			label(L10N.text(category) + ": " + DATA.summary(d.get("world/%d/%s" % [w, category], {})))
		for l in range(host.PROGRESSION.levels(w).size()):
			var key := "%d:%d" % [w, l]
			label("%s — %s — %s" % [host.PROGRESSION.levels(w)[l], L10N.text("passed") if host.progress.get("completed_levels", {}).get(key, false) else L10N.text("pending"), DATA.summary(d.get("level/" + key + "/independent", {}))])

func facts() -> void:
	clear()
	button(L10N.text("Overview"), dashboard)
	label(L10N.text("Rows × columns: 2–9. Cells show independent correct / attempts since v10. Tap for details."))
	var grid := GridContainer.new()
	grid.columns = 8
	body.add_child(grid)
	var d: Dictionary = host.progress.get("diagnostics", {})
	for a in range(2, 10):
		for b in range(2, 10):
			var key := "1_%d_%d" % [a, b]
			var bucket: Dictionary = d.get("fact/" + key + "/independent", {})
			var cell := Button.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.custom_minimum_size.y = 52
			cell.text = "%d×%d\n%d/%d" % [a, b, bucket.get("ok", 0), bucket.get("n", 0)]
			cell.pressed.connect(func(): fact_detail(key))
			grid.add_child(cell)
	label(L10N.text("Problem examples: independent errors, or learning evidence requiring review"))
	var keys: Array = host.progress.get("skills", {}).keys()
	keys.sort()
	for key in keys:
		var old: Dictionary = host.progress.skills[key]
		var bucket: Dictionary = d.get("fact/" + str(key) + "/independent", {})
		if int(bucket.get("n", 0)) > int(bucket.get("ok", 0)) or old.get("state", "") == "REVIEW_REQUIRED":
			label(str(key) + ": " + DATA.summary(bucket))

func fact_detail(key: String) -> void:
	clear()
	button(L10N.text("Back to matrix"), facts)
	label(key.replace("_", " "))
	for category in ["independent", "choice", "assisted"]:
		label(L10N.text(category) + ": " + DATA.summary(host.progress.get("diagnostics", {}).get("fact/" + key + "/" + category, {})))
	var evidence: Dictionary = host.progress.get("skills", {}).get(key, {})
	label(L10N.text("Learning state: ") + L10N.text(host.LEARNING_ENGINE.effective_state(evidence, int(Time.get_unix_time_from_system() / 86400))))

func history() -> void:
	clear()
	button(L10N.text("Overview"), dashboard)
	label(L10N.text("Daily / weekly totals, UTC dates; weeks start Monday (numeric week ID)"))
	var d: Dictionary = host.progress.get("diagnostics", {})
	var keys: Array = d.keys()
	keys.sort()
	for key in keys:
		if str(key).begins_with("day/") or str(key).begins_with("week/"):
			label(str(key) + ": " + DATA.summary(d[key]))
	label(L10N.text("Last 100 missions (UTC), newest first"))
	var rows: Array = host.progress.get("mission_history", []).duplicate()
	rows.reverse()
	for row in rows:
		label(L10N.text("%s — W%d level %d — %s — %d correct / %d missed — %.0fs") % [row.date, row.world, int(row.level) + 1, L10N.text("completed") if row.won else L10N.text("failed / exited"), row.hits, row.misses, row.seconds])

func spin(title: String, value: float, minimum: float, maximum: float) -> SpinBox:
	label(title)
	var node := SpinBox.new()
	node.min_value = minimum
	node.max_value = maximum
	node.value = value
	body.add_child(node)
	return node

func settings() -> void:
	clear()
	button(L10N.text("Overview"), dashboard)
	var duration := spin(L10N.text("Mission seconds: 120–900 (default 300). Phase proportions stay the same; Rewards begins at 280/300."), DATA.duration(host.progress), 120, 900)
	var inputs: Array = []
	for i in range(5):
		inputs.append(spin(L10N.text("World %d answer seconds: 5–180 (default %d)") % [i + 1, DATA.DEFAULT_LIMITS[i]], DATA.limits(host.progress)[i], 5, 180))
	button(L10N.text("Save timing"), func():
		var values: Array = []
		for item in inputs: values.append(item.value)
		host.progress["parent_settings"] = {"duration": duration.value, "limits": values}
		host.save_progress()
		dashboard())
	button(L10N.text("Restore default timing"), func(): host.progress.erase("parent_settings"); host.save_progress(); settings())
	button(L10N.text("Change PIN (repeat required)"), func():
		confirm(L10N.text("Change PIN?"), func(): changing_pin = true; first_pin = ""; unlocked = false; gate()))
	label(L10N.text("Export includes the local PIN hash. Keep backups private. Imports keep your current PIN and make a backup before replacing progress."))
	button(L10N.text("Export JSON…"), func(): choose_file(false))
	button(L10N.text("Import JSON…"), func(): choose_file(true))
	button(L10N.text("Reset progress (two confirmations)"), func(): confirm(L10N.text("Reset all learning progress?"), func(): confirm(L10N.text("Final confirmation: reset? A backup will be saved."), reset)))

func confirm(text: String, action: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = text
	add_child(dialog)
	dialog.confirmed.connect(func(): dialog.queue_free(); action.call())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(560, 180))

func message(text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.dialog_text = text
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(560, 180))

func backup() -> bool:
	return DATA.write_save("user://parent_backup_%d_%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec()], host.progress)

func reset() -> void:
	if not backup():
		message(L10N.text("Backup failed. No changes made."))
		return
	var clean: Dictionary = {"skills": {}, "coins": 0, "missions": 0, "parent_pin": host.progress.parent_pin}
	if not DATA.write_save(host.SAVE_PATH, clean):
		message(L10N.text("Save failed. No changes made."))
		return
	host.progress = clean
	host.save_writable = true
	host.migrate_learning_data()
	dashboard()

func choose_file(importing: bool) -> void:
	var picker := FileDialog.new()
	picker.access = FileDialog.ACCESS_FILESYSTEM
	picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE if importing else FileDialog.FILE_MODE_SAVE_FILE
	picker.filters = PackedStringArray([L10N.text("*.json ; Math Galaxy save")])
	picker.use_native_dialog = OS.get_name() == "Android"
	add_child(picker)
	picker.file_selected.connect(func(path: String):
		picker.queue_free()
		if not importing:
			message(L10N.text("Export saved.") if DATA.write_save(path, host.progress) else L10N.text("Export failed."))
			return
		if FileAccess.get_file_as_bytes(path).size() > 16000000:
			message(L10N.text("File is too large (limit 16 MB)."))
			return
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not DATA.validate(parsed):
			message(L10N.text("Invalid or unsupported save. Current data unchanged."))
			return
		confirm(L10N.text("Replace progress with this save? A backup will be saved first."), func():
			if not backup():
				message(L10N.text("Backup failed. No changes made."))
				return
			if parsed.has("mission_history"): parsed["mission_history"] = parsed.mission_history.slice(maxi(0, parsed.mission_history.size() - 100))
			if parsed.has("workshop_history"): parsed["workshop_history"] = parsed.workshop_history.slice(maxi(0, parsed.workshop_history.size() - 100))
			parsed["parent_pin"] = host.progress.parent_pin.duplicate(true)
			if not DATA.write_save(host.SAVE_PATH, parsed):
				message(L10N.text("Save failed. No changes made."))
				return
			host.progress = parsed
			host.load_progress()
			host.migrate_learning_data()
			dashboard())
	)
	picker.canceled.connect(picker.queue_free)
	picker.popup_centered_ratio(0.85)
