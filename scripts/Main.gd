extends Control

const LEARNING_ENGINE = preload("res://scripts/LearningEngine.gd")
const SCENE_SCRIPT = preload("res://scripts/SpaceScene.gd")
const KEYPAD_SCRIPT = preload("res://scripts/ui/NeonKeypad.gd")
const FANCY_BUTTON = preload("res://scripts/ui/FancyButton.gd")
const WORLD_ART = [preload("res://assets/worlds/1_lightning_clean.jpg"), preload("res://assets/worlds/2_desert_clean.jpg"), preload("res://assets/worlds/3_crystal_clean.jpg"), preload("res://assets/worlds/4_titan_clean.jpg"), preload("res://assets/worlds/5_blackhole_clean.jpg")]
const MENU_GALAXY = preload("res://assets/battle/menu_galaxy.jpg")
const MENU_BACKGROUNDS = [preload("res://assets/battle/world_1_background.jpg"), preload("res://assets/battle/world_2_background.jpg"), preload("res://assets/battle/world_3_background.jpg"), preload("res://assets/battle/world_4_background.jpg"), preload("res://assets/battle/world_5_background.jpg")]
const WORLD_SUBTITLES = ["TABLE 2-9", "2 DIGITS × 1", "3 DIGITS × 1", "2 DIGITS × 2", "EXACT DIVISION"]
const SAVE_PATH = "user://math_galaxy_progress.json"
const MISSION_LENGTH := 300.0
const PHASE_LIMITS := [35.0, 85.0, 235.0, 280.0, 300.0]
const PHASE_NAMES := ["WARM-UP", "WORKSHOP", "SPACE BATTLE", "BOSS", "REWARDS"]
const WORLD_NAMES := ["Lightning Academy", "Mechanic Desert", "Crystal Planet", "Titan City", "Black Hole"]
const BACK := Color("07122d")
const BLUE := Color("2388ef")

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
			elif elapsed >= PHASE_LIMITS[4]:
				finish_mission()
			else:
				next_question()
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
		if elapsed < PHASE_LIMITS[i]:
			return i
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

func space_panel(fill: Color, border: Color, radius: int = 18, shadow_alpha: float = 0.28) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(border.r, border.g, border.b, shadow_alpha)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func decorate_button_text(btn: Button, value: String, font_size: int = 21, color: Color = Color("eefaff")) -> void:
	btn.text = ""
	for child in btn.get_children():
		if child is Label and child.name == "Caption":
			child.queue_free()
	var cap := Label.new()
	cap.name = "Caption"
	cap.text = value
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", font_size)
	cap.add_theme_color_override("font_color", color)
	cap.add_theme_constant_override("outline_size", 2)
	cap.add_theme_color_override("font_outline_color", Color(0,0,0,0.45))
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(cap)

func make_button(value: String, fn: Callable, color: Color = BLUE, min_x: float = 100.0, min_y: float = 56.0, font_size: int = 22) -> Button:
	var btn := Button.new()
	btn.set_script(FANCY_BUTTON)
	btn.set("accent_color", color)
	btn.custom_minimum_size = Vector2(min_x, min_y)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	decorate_button_text(btn, value, font_size)
	btn.pressed.connect(func(): animate_button(btn))
	btn.pressed.connect(fn)
	btn.mouse_entered.connect(func(): pulse_button(btn))
	return btn

func animate_button(btn: Button) -> void:
	if not is_instance_valid(btn): return
	btn.pivot_offset = btn.size * 0.5
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(0.975, 0.975), 0.07)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func pulse_button(btn: Button) -> void:
	if not is_instance_valid(btn) or btn.disabled: return
	var tw := btn.create_tween()
	tw.tween_property(btn, "modulate", Color("d8f7ff"), 0.09)
	tw.tween_property(btn, "modulate", Color.WHITE, 0.15)

func build_root(bg_texture: Texture2D = null) -> VBoxContainer:
	clear_screen()
	var bg := ColorRect.new()
	bg.color = BACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	if bg_texture != null:
		var tex := TextureRect.new()
		tex.texture = bg_texture
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.modulate = Color(1,1,1,0.85)
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(tex)
		var shade := ColorRect.new()
		shade.color = Color(0.03,0.05,0.11,0.25)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	main_box = VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 6)
	margin.add_child(main_box)
	return main_box

func make_stat_chip(icon: String, text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(180, 56)
	p.add_theme_stylebox_override("panel", space_panel(Color("102548"), Color("2ca7ff"), 14, 0.22))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	p.add_child(row)
	var left := make_label(icon, 28, Color("69d8ff"))
	left.custom_minimum_size.x = 36
	row.add_child(left)
	var val := make_label(text, 23, Color("eef7ff"))
	row.add_child(val)
	return p

func show_menu() -> void:
	screen = "menu"
	finished = false
	var root := build_root(MENU_GALAXY)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(Control.new())
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(make_stat_chip("💎", "Crystals %d" % progress.get("coins",0)))
	top.add_child(make_stat_chip("🏅", "Missions %d" % progress.get("missions",0)))
	var settings := make_button("⚙", func(): null, Color("274784"), 58, 56, 24)
	settings.disabled = true
	top.add_child(settings)
	root.add_child(top)
	root.add_child(make_label("MATH GALAXY", 56, Color("84d8ff")))
	root.add_child(make_label("Learn multiplication. Power your spaceship.", 24, Color("d5e4ff")))
	root.add_child(make_label("CHOOSE A WORLD", 21, Color("ffd85b")))
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 12)
	root.add_child(cards)
	for i in range(5):
		cards.add_child(make_world_card(i + 1))
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(fill)
	var start_wrap := CenterContainer.new()
	root.add_child(start_wrap)
	start_wrap.add_child(make_button("▶  START 5-MINUTE MISSION", start_mission, Color("00e485"), 520, 78, 29))
	root.add_child(make_label("Prototype • Offline • Landscape • No account required", 16, Color("b2c2dd")))

func make_world_card(idx: int) -> Button:
	var selected: bool = idx == world
	var b := make_button("", func(): select_world(idx), Color("2dcdf6") if selected else Color("4260a4"), 210, 210, 20)
	b.clip_contents = true
	var picture_clip := Control.new()
	picture_clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture_clip.offset_left = 9
	picture_clip.offset_top = 10
	picture_clip.offset_right = -9
	picture_clip.offset_bottom = -12
	picture_clip.clip_contents = true
	picture_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(picture_clip)
	var pic := TextureRect.new()
	pic.texture = WORLD_ART[idx - 1]
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pic.offset_left = 0
	pic.offset_top = 0
	pic.offset_right = 0
	pic.offset_bottom = 0
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture_clip.add_child(pic)
	var glow := ColorRect.new()
	glow.color = Color(0.1,0.2,0.4,0.16 if selected else 0.28)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture_clip.add_child(glow)
	var footer := PanelContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 8
	footer.offset_right = -8
	footer.offset_top = -103
	footer.offset_bottom = -21
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_theme_stylebox_override("panel", space_panel(Color(0.03,0.05,0.12,0.70), Color("57cfff") if selected else Color("7184b5"), 12, 0.05))
	b.add_child(footer)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	footer.add_child(box)
	box.add_child(make_label("WORLD %d" % idx, 14, Color("fff2a6")))
	box.add_child(make_label(WORLD_NAMES[idx - 1], 17, Color("f8fdff")))
	box.add_child(make_label(WORLD_SUBTITLES[idx - 1], 13, Color("8ff0ff" if selected else Color("b0d0ff"))))
	return b

func select_world(value: int) -> void:
	world = value
	show_menu()

func start_mission() -> void:
	progress["mission_sequence"] = int(progress.get("mission_sequence", 0)) + 1
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
	var root := build_root(MENU_BACKGROUNDS[world - 1])
	var top_panel := PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", space_panel(Color(0.02,0.07,0.19,0.78), Color("2aaeff"), 16, 0.18))
	root.add_child(top_panel)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 16)
	top_panel.add_child(top)
	shield_label = make_label("SHIELD 100%", 20, Color("8de5ff"))
	shield_label.custom_minimum_size.x = 160
	top.add_child(shield_label)
	shield_bar = ProgressBar.new()
	shield_bar.max_value = 100
	shield_bar.value = 100
	shield_bar.custom_minimum_size = Vector2(220, 22)
	style_progress(shield_bar, Color("44d0ff"))
	top.add_child(shield_bar)
	header = make_label("WORLD %d • %s" % [world, WORLD_NAMES[world - 1]], 22, Color("ffe270"))
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(header)
	energy_label = make_label("ENERGY 50  •  COMBO 0", 20, Color("ffd85d"))
	energy_label.custom_minimum_size.x = 250
	top.add_child(energy_label)
	info = make_label("05:00", 26, Color.WHITE)
	info.custom_minimum_size.x = 92
	top.add_child(info)

	art = Control.new()
	art.set_script(SCENE_SCRIPT)
	art.call("set_world", world)
	art.custom_minimum_size.y = 220
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root.add_child(art)

	var question_card := PanelContainer.new()
	question_card.add_theme_stylebox_override("panel", space_panel(Color(0.01,0.07,0.18,0.51), Color("1daeff"), 18, 0.12))
	root.add_child(question_card)
	var qbox := VBoxContainer.new()
	qbox.alignment = BoxContainer.ALIGNMENT_CENTER
	qbox.add_theme_constant_override("separation", 8)
	question_card.add_child(qbox)
	var question_row := Control.new()
	question_row.custom_minimum_size.y = 75
	question_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qbox.add_child(question_row)
	question_label = make_label("7 × 8 = ?", 52, Color.WHITE)
	question_row.add_child(question_label)
	question_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var timer_shell := VBoxContainer.new()
	question_row.add_child(timer_shell)
	timer_shell.custom_minimum_size = Vector2(150, 56)
	timer_shell.anchor_left = 1.0
	timer_shell.anchor_right = 1.0
	timer_shell.anchor_top = 0.0
	timer_shell.anchor_bottom = 0.0
	timer_shell.offset_left = -168.0
	timer_shell.offset_right = -12.0
	timer_shell.offset_top = 5.0
	timer_shell.offset_bottom = 64.0
	timer_shell.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_label = make_label("8.0 s", 23, Color("ffd85b"))
	timer_shell.add_child(timer_label)
	timer_bar = ProgressBar.new()
	timer_bar.custom_minimum_size = Vector2(142, 13)
	style_progress(timer_bar, Color("ffc857"))
	timer_shell.add_child(timer_bar)
	feedback = make_label("", 22, Color("a7f3d0"))
	qbox.add_child(feedback)

	answer_area = VBoxContainer.new()
	answer_area.custom_minimum_size.y = 175
	answer_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(answer_area)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	footer.add_child(make_button("✦ HINT  -25 ENERGY", use_hint, Color("9d50ff"), 230, 51, 19))
	footer.add_child(make_button("↻ SKIP  -20 SHIELD", func(): resolve_answer(-1, "skip"), Color("f04d76"), 235, 51, 19))
	footer.add_child(make_button("◀ EXIT", exit_mission, Color("4f8cdb"), 125, 51, 19))
	update_phase_label()

func style_progress(bar: ProgressBar, fill: Color) -> void:
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("0b1531")
	bg.set_corner_radius_all(9)
	bg.set_border_width_all(1)
	bg.border_color = Color("385791")
	bar.add_theme_stylebox_override("background", bg)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(9)
	bar.add_theme_stylebox_override("fill", fg)

func update_phase_label() -> void:
	if header != null:
		header.text = "%s  •  WORLD %d" % [PHASE_NAMES[phase], world]
	if art != null and is_instance_valid(art):
		art.call("set_boss_mode", phase == 3)

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
		if q["key"] == last_key:
			continue
		candidates.append(q)
	if candidates.is_empty():
		return MathEngine.generate(world)
	candidates.shuffle()
	candidates.sort_custom(func(a: Dictionary,b: Dictionary): return skill_priority(a, skills) > skill_priority(b, skills))
	return candidates[0] if randf() < 0.7 else candidates[randi_range(0, candidates.size()-1)]

func skill_priority(q: Dictionary, skills: Dictionary) -> float:
	var s: Dictionary = skills.get(q["key"], {})
	var attempts: int = s.get("attempts", 0)
	if attempts == 0:
		return 1.5
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
	if phase == 1:
		question_limit += 8.0
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
		row.add_theme_constant_override("separation", 14)
		row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		answer_area.add_child(row)
		for value in MathEngine.options(question):
			var v: int = value
			var b := make_button(str(value), func(): resolve_answer(v, "answer"), Color("2c86ff"), 140, 81, 34)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(b)
	else:
		var center := CenterContainer.new()
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answer_area.add_child(center)
		keypad = VBoxContainer.new()
		keypad.set_script(KEYPAD_SCRIPT)
		keypad.custom_minimum_size.x = 420
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
	var stats: Dictionary = LEARNING_ENGINE.record(skills.get(skill_key, {}), correct, reason, question_elapsed, input_mode, hint_used, int(progress.get("mission_sequence", 0)), int(Time.get_unix_time_from_system() / 86400.0))
	if keypad != null:
		keypad.call("flash", correct)
	if correct:
		hits += 1
		combo += 1
		energy = mini(100, energy + (15 if fast else 10))
		shield = mini(100, shield + 5 + (10 if combo % 5 == 0 else 0))
		var reward: int = 10 + (5 if fast else 0)
		coins_earned += reward
		feedback.text = "DIRECT HIT! +%d crystals" % reward
		art.call("hit_enemy")
	else:
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
	save_progress()
	screen = "game_over"
	var root := build_root(MENU_BACKGROUNDS[world - 1])
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	root.add_child(make_label("SHIP DESTROYED", 58, Color("fb7185")))
	root.add_child(make_label("World %d: %s" % [world, WORLD_NAMES[world - 1]], 26))
	root.add_child(make_label("Correct: %d        Missed: %d" % [hits, misses], 31))
	root.add_child(make_label("Shield: 0%  •  No mission crystals awarded", 24, Color("fda4af")))
	root.add_child(make_label("Your answers were saved for future practice", 21, Color("a7bddf")))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	root.add_child(row)
	row.add_child(make_button("↻  RETRY LEVEL", start_mission, Color("00e485"), 260, 68, 24))
	row.add_child(make_button("◀  RETURN TO GALAXY", show_menu, Color("425d88"), 280, 68, 24))
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
	var root := build_root(MENU_BACKGROUNDS[world - 1])
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	root.add_child(make_label("MISSION COMPLETE", 58, Color("fcd34d")))
	root.add_child(make_label("World %d: %s" % [world,WORLD_NAMES[world - 1]], 26))
	root.add_child(make_label("Correct: %d        Missed: %d        Shield: %d%%" % [hits,misses,shield], 31))
	root.add_child(make_label("+%d crystals    •    %d questions awaiting review" % [coins_earned,queue.size()], 29, Color("7dd3fc")))
	root.add_child(make_label("Progress has been saved locally", 21, Color("a7f3d0")))
	root.add_child(make_button("◀  RETURN TO GALAXY", show_menu, Color("00e485"), 280, 68, 24))
	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sp2)

func exit_mission() -> void:
	finish_mission()

func save_progress() -> void:
	progress["schema_version"] = 2
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
	progress["schema_version"] = 2
