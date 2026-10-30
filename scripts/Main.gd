extends Control

const SCENE_SCRIPT = preload("res://scripts/SpaceScene.gd")
const KEYPAD_SCRIPT = preload("res://scripts/ui/NeonKeypad.gd")
const SAVE_PATH = "user://math_galaxy_progress.json"
const MISSION_LENGTH := 300.0
const PHASE_LIMITS := [35.0, 85.0, 235.0, 280.0, 300.0]
const PHASE_NAMES := ["WARM-UP", "WORKSHOP", "SPACE BATTLE", "BOSS", "REWARDS"]
const WORLD_NAMES := ["Lightning Academy", "Mechanic Desert", "Crystal Planet", "Titan City", "Black Hole"]
const BACK := Color("0b1128")
const PANEL := Color("172448")
const BLUE := Color("2563eb")

var progress: Dictionary = {"coins": 0, "missions": 0, "skills": {}}
var world: int = 1
var screen: String = "menu"
var elapsed: float = 0.0
var question_elapsed: float = 0.0
var question_limit: float = 8.0
var phase: int = -1
var shield: int = 100
var energy: int = 50
var combo: int = 0
var hits: int = 0
var misses: int = 0
var coins_earned: int = 0
var question: Dictionary = {}
var queue: Array[Dictionary] = []
var input_mode: String = "numeric"
var input_value: String = ""
var hint_used: bool = false
var question_active: bool = false
var transition_delay: float = 0.0
var finished: bool = false
var paused: bool = false
var last_key: String = ""
var pending_defeat: bool = false

var header: Label
var info: Label
var question_label: Label
var answer_label: Label
var keypad: VBoxContainer
var feedback: Label
var timer_label: Label
var shield_label: Label
var energy_label: Label
var timer_bar: ProgressBar
var shield_bar: ProgressBar
var answer_area: VBoxContainer
var art: Control
var main_box: VBoxContainer

func _ready() -> void:
	randomize()
	load_progress()
	show_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		paused = false
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_progress()

func _process(delta: float) -> void:
	if screen != "battle" or paused or finished:
		return
	if transition_delay > 0.0:
		transition_delay -= delta
		if transition_delay <= 0.0:
			if pending_defeat:
				fail_mission()
			elif elapsed >= PHASE_LIMITS[4]: finish_mission()
			else: next_question()
		return
	elapsed = minf(MISSION_LENGTH, elapsed + delta)
	var next_phase: int = determine_phase()
	if next_phase != phase:
		phase = next_phase
		if phase == 4:
			finish_mission()
			return
		update_phase_label()
	if question_active:
		question_elapsed += delta
		if question_elapsed >= question_limit:
			resolve_answer(-1, "timeout")
	update_hud()

func determine_phase() -> int:
	for i in range(PHASE_LIMITS.size()):
		if elapsed < PHASE_LIMITS[i]: return i
	return 4

func clear_screen() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

func make_label(value: String, font_size: int = 24, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

func make_button(value: String, fn: Callable, color: Color = BLUE, min_x: float = 100.0) -> Button:
	# Shared styling for every navigation, battle, answer and result button.
	var btn := Button.new()
	btn.text = value
	btn.custom_minimum_size = Vector2(min_x, 56)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 21)
	btn.add_theme_color_override("font_color", Color("f0faff"))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color("94a5c4"))
	var accent := color.lightened(0.35)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color.darkened(0.32)
	normal.border_color = accent
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(16)
	normal.shadow_color = Color(accent.r, accent.g, accent.b, 0.34)
	normal.shadow_size = 7
	normal.shadow_offset = Vector2(0, 3)
	normal.content_margin_left = 15.0
	normal.content_margin_right = 15.0
	normal.content_margin_top = 9.0
	normal.content_margin_bottom = 9.0
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.12)
	hover.border_color = accent.lightened(0.24)
	hover.shadow_size = 12
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.14)
	pressed.border_color = Color("e9ffff")
	pressed.shadow_size = 2
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("263047")
	disabled.border_color = Color("42506a")
	disabled.shadow_size = 0
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(func(): animate_button(btn))
	btn.pressed.connect(fn)
	btn.mouse_entered.connect(func(): pulse_button(btn))
	return btn

func animate_button(btn: Button) -> void:
	if not is_instance_valid(btn): return
	btn.pivot_offset = btn.size * 0.5
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(0.965, 0.965), 0.07)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func pulse_button(btn: Button) -> void:
	if not is_instance_valid(btn) or btn.disabled: return
	var tw := btn.create_tween()
	tw.tween_property(btn, "modulate", Color("c6f8ff"), 0.09)
	tw.tween_property(btn, "modulate", Color.WHITE, 0.16)

func build_root() -> VBoxContainer:
	clear_screen()
	var bg := ColorRect.new()
	bg.color = BACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 35)
	margin.add_theme_constant_override("margin_right", 35)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	main_box = VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 10)
	margin.add_child(main_box)
	return main_box

func show_menu() -> void:
	screen = "menu"
	finished = false
	var root := build_root()
	var space := Control.new()
	space.custom_minimum_size.y = 50
	root.add_child(space)
	root.add_child(make_label("✦  MATH GALAXY  ✦", 58, Color("7dd3fc")))
	root.add_child(make_label("Learn multiplication. Power your spaceship.", 26, Color("c4d7ff")))
	var gap := Control.new()
	gap.custom_minimum_size.y = 22
	root.add_child(gap)
	root.add_child(make_label("CHOOSE A WORLD", 24, Color("fcd34d")))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(grid)
	for i in range(5):
		var idx: int = i + 1
		var b := make_button("%d\n%s" % [idx,WORLD_NAMES[i]], func(): select_world(idx), Color("17669e") if idx == world else Color("293c73"), 205)
		b.custom_minimum_size.y = 95
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(filler)
	root.add_child(make_label("Crystals: %d      Missions played: %d" % [progress.get("coins",0), progress.get("missions",0)], 22, Color("a7bddf")))
	root.add_child(make_button("▶  START 5-MINUTE MISSION", start_mission, Color("12896f")))
	root.add_child(make_label("Prototype • Offline • Landscape • No account required", 16, Color("8999b7")))

func select_world(value: int) -> void:
	world = value
	show_menu()

func start_mission() -> void:
	elapsed = 0.0
	phase = 0
	shield = 100
	energy = 50
	combo = 0
	hits = 0
	misses = 0
	coins_earned = 0
	queue.clear()
	transition_delay = 0.0
	question_active = false
	last_key = ""
	pending_defeat = false
	finished = false
	paused = false
	screen = "battle"
	build_battle()
	next_question()

func build_battle() -> void:
	var root := build_root()
	var top := HBoxContainer.new()
	root.add_child(top)
	shield_label = make_label("SHIELD 100%", 20, Color("7dd3fc"))
	shield_label.custom_minimum_size.x = 220
	top.add_child(shield_label)
	shield_bar = ProgressBar.new()
	shield_bar.max_value = 100
	shield_bar.value = 100
	shield_bar.custom_minimum_size = Vector2(135, 20)
	top.add_child(shield_bar)
	header = make_label("WARM-UP", 23, Color("fcd34d"))
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(header)
	energy_label = make_label("ENERGY 50", 20, Color("fcd34d"))
	top.add_child(energy_label)
	info = make_label("05:00", 24)
	info.custom_minimum_size.x = 120
	top.add_child(info)
	art = Control.new()
	art.set_script(SCENE_SCRIPT)
	art.custom_minimum_size.y = 170
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(art)
	var question_row := HBoxContainer.new()
	root.add_child(question_row)
	question_label = make_label("7 × 8 = ?", 46)
	question_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_row.add_child(question_label)
	var timer_container := VBoxContainer.new()
	question_row.add_child(timer_container)
	timer_label = make_label("8.0 s", 26, Color("fcd34d"))
	timer_container.add_child(timer_label)
	timer_bar = ProgressBar.new()
	timer_bar.custom_minimum_size = Vector2(140, 14)
	timer_container.add_child(timer_bar)
	style_progress(timer_bar, Color("ffc857"))
	feedback = make_label("", 20, Color("a7f3d0"))
	feedback.custom_minimum_size.y = 34
	root.add_child(feedback)
	answer_area = VBoxContainer.new()
	answer_area.custom_minimum_size.y = 180
	root.add_child(answer_area)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(footer)
	footer.add_child(make_button("✦  HINT (-25 energy)", use_hint, Color("6543bd"), 210))
	footer.add_child(make_button("↷  SKIP (-20 shield)", func(): resolve_answer(-1, "skip"), Color("a23e64"), 230))
	footer.add_child(make_button("◀  EXIT", exit_mission, Color("34496d"), 110))
	update_phase_label()

func style_progress(bar: ProgressBar, fill: Color) -> void:
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("0d1730")
	bg.set_corner_radius_all(7)
	bar.add_theme_stylebox_override("background", bg)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(7)
	bar.add_theme_stylebox_override("fill", fg)

func update_phase_label() -> void:
	if header != null:
		header.text = "%s  •  WORLD %d" % [PHASE_NAMES[phase], world]

func update_hud() -> void:
	info.text = "%02d:%02d" % [int(ceil(MISSION_LENGTH-elapsed)) / 60, int(ceil(MISSION_LENGTH-elapsed)) % 60]
	shield_label.text = "SHIELD %d%%" % shield
	shield_bar.value = shield
	energy_label.text = "ENERGY %d  •  COMBO %d" % [energy, combo]
	timer_label.text = "%.1f s" % maxf(0.0, question_limit - question_elapsed)
	timer_bar.max_value = question_limit
	timer_bar.value = maxf(0.0, question_limit - question_elapsed)

func choose_question() -> Dictionary:
	if phase >= 3 and not queue.is_empty() and randf() < 0.75:
		return queue.pop_front()
	var skills: Dictionary = progress.get("skills", {})
	var candidates: Array[Dictionary] = []
	for i in range(12):
		var q: Dictionary = MathEngine.generate(world)
		if q["key"] == last_key: continue
		candidates.append(q)
	if candidates.is_empty(): return MathEngine.generate(world)
	candidates.shuffle()
	candidates.sort_custom(func(a: Dictionary,b: Dictionary): return skill_priority(a, skills) > skill_priority(b, skills))
	return candidates[0] if randf() < 0.7 else candidates[randi_range(0, candidates.size()-1)]

func skill_priority(q: Dictionary, skills: Dictionary) -> float:
	var s: Dictionary = skills.get(q["key"], {})
	var attempts: int = s.get("attempts", 0)
	if attempts == 0: return 1.5
	return (float(s.get("wrong", 0)) + 1.0) / (float(attempts) + 1.0) + 1.0 / (1.0 + float(s.get("fast",0)))

func next_question() -> void:
	if finished: return
	if elapsed >= MISSION_LENGTH:
		finish_mission()
		return
	question = choose_question()
	last_key = question["key"]
	question_elapsed = 0.0
	question_limit = [8.0, 20.0, 35.0, 60.0, 45.0][world - 1]
	if phase == 1: question_limit += 8.0
	hint_used = false
	question_active = true
	input_value = ""
	input_mode = "choices" if randf() < 0.25 else "numeric"
	question_label.text = "%d %s %d = ?" % [question["a"],question["sign"],question["b"]]
	feedback.text = "Enter your answer" if input_mode == "numeric" else "Choose the answer"
	build_answers()

func build_answers() -> void:
	keypad = null
	for c in answer_area.get_children():
		answer_area.remove_child(c)
		c.queue_free()
	if input_mode == "choices":
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		answer_area.add_child(row)
		for value in MathEngine.options(question):
			var v: int = value
			var b := make_button(str(value), func(): resolve_answer(v, "answer"), Color("246cba"), 110)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size.y = 96
			row.add_child(b)
	else:
		var center := CenterContainer.new()
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answer_area.add_child(center)
		keypad = VBoxContainer.new()
		keypad.set_script(KEYPAD_SCRIPT)
		keypad.custom_minimum_size.x = 388
		center.add_child(keypad)
		keypad.call("set_value", "")
		keypad.connect("key_pressed", Callable(self, "press_digit"))

func press_digit(digit: String) -> void:
	if not question_active or input_mode != "numeric": return
	if digit == "⌫":
		input_value = input_value.substr(0, maxi(0, input_value.length()-1))
	elif digit == "OK":
		if input_value.is_valid_int(): resolve_answer(int(input_value), "answer")
	else:
		if input_value.length() < 6: input_value += digit
	if keypad != null:
		keypad.call("set_value", input_value)

func _unhandled_key_input(event: InputEvent) -> void:
	if screen != "battle" or not question_active or not event.pressed: return
	if event is InputEventKey:
		var key := OS.get_keycode_string(event.keycode)
		if key.length() == 1 and key.is_valid_int(): press_digit(key)
		elif event.keycode == KEY_ENTER: press_digit("OK")
		elif event.keycode == KEY_BACKSPACE: press_digit("⌫")

func use_hint() -> void:
	if not question_active: return
	if energy < 25:
		feedback.text = "Not enough energy"
		return
	if hint_used: return
	energy -= 25
	hint_used = true
	feedback.text = MathEngine.hint(question)
	question_limit += 8.0

func resolve_answer(value: int, reason: String) -> void:
	if not question_active or finished: return
	question_active = false
	var correct: bool = reason == "answer" and value == question["answer"]
	var fast: bool = question_elapsed <= question_limit * 0.45 and not hint_used
	var skill_key: String = question["key"]
	var skills: Dictionary = progress["skills"]
	var stats: Dictionary = skills.get(skill_key, {"attempts":0,"correct":0,"wrong":0,"fast":0,"hints":0,"total_ms":0})
	stats["attempts"] += 1
	stats["total_ms"] += int(question_elapsed * 1000.0)
	if hint_used: stats["hints"] += 1
	if keypad != null:
		keypad.call("flash", correct)
	if correct:
		stats["correct"] += 1
		if fast and input_mode == "numeric": stats["fast"] += 1
		hits += 1
		combo += 1
		energy = mini(100, energy + (15 if fast else 10))
		shield = mini(100, shield + 5 + (10 if combo % 5 == 0 else 0))
		var reward: int = 10 + (5 if fast else 0)
		coins_earned += reward
		feedback.text = "DIRECT HIT! +%d crystals" % reward
		art.call("hit_enemy")
	else:
		stats["wrong"] += 1
		misses += 1
		combo = 0
		shield = maxi(0, shield - 20)
		feedback.text = "%s! Answer: %d" % [reason.to_upper(), question["answer"]]
		art.call("hit_ship")
		if queue.size() < 30:
			queue.append(question.duplicate(true))
		if shield == 0:
			feedback.text = "SHIELD DESTROYED! MISSION FAILED"
	skills[skill_key] = stats
	update_hud()
	if shield == 0:
		pending_defeat = true
		transition_delay = 1.65
		art.call("destroy_ship")
		return
	transition_delay = 1.0

func fail_mission() -> void:
	if finished: return
	finished = true
	question_active = false
	transition_delay = 0.0
	# Keep practice statistics for adaptive learning, but don't award mission crystals.
	save_progress()
	screen = "game_over"
	var root := build_root()
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	root.add_child(make_label("SHIP DESTROYED", 58, Color("fb7185")))
	root.add_child(make_label("World %d: %s" % [world, WORLD_NAMES[world - 1]], 26))
	root.add_child(make_label("Correct: %d        Missed: %d" % [hits, misses], 31))
	root.add_child(make_label("Shield: 0%  •  No mission crystals awarded", 24, Color("fda4af")))
	root.add_child(make_label("Your answers were saved for future practice", 21, Color("a7bddf")))
	root.add_child(make_button("↻  RETRY LEVEL", start_mission, Color("12896f")))
	root.add_child(make_button("◀  RETURN TO GALAXY", show_menu, Color("34496d")))
	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sp2)

func finish_mission() -> void:
	if finished: return
	finished = true
	question_active = false
	progress["coins"] = int(progress.get("coins",0)) + coins_earned
	progress["missions"] = int(progress.get("missions",0)) + 1
	save_progress()
	screen = "results"
	var root := build_root()
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	root.add_child(make_label("MISSION COMPLETE", 58, Color("fcd34d")))
	root.add_child(make_label("World %d: %s" % [world,WORLD_NAMES[world - 1]], 26))
	root.add_child(make_label("Correct: %d        Missed: %d        Shield: %d%%" % [hits,misses,shield], 31))
	root.add_child(make_label("+%d crystals    •    %d questions awaiting review" % [coins_earned,queue.size()], 29, Color("7dd3fc")))
	root.add_child(make_label("Progress has been saved locally", 21, Color("a7f3d0")))
	root.add_child(make_button("◀  RETURN TO GALAXY", show_menu, Color("12896f")))
	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sp2)

func exit_mission() -> void:
	finish_mission()

func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(progress))
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		progress = parsed
		if not progress.has("skills"): progress["skills"] = {}
