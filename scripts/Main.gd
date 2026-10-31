extends Control

const UI_FONT = preload("res://assets/fonts/InterfaceFont.tres")
const UI_THEME = preload("res://assets/ui/game_theme.tres")
const L10N = preload("res://scripts/Localization.gd")

const REWARD_MANAGER = preload("res://scripts/RewardManager.gd")
const HANGAR = preload("res://scripts/Hangar.gd")

const PARENT_DATA = preload("res://scripts/ParentData.gd")
const PARENT_UI = preload("res://scripts/ParentDashboard.gd")

const LOCATIONS = preload("res://scripts/WorldLocations.gd")
const PROGRESSION = preload("res://scripts/LearningProgression.gd")
const LEARNING_ENGINE = preload("res://scripts/LearningEngine.gd")
const ADAPTIVE_SELECTOR = preload("res://scripts/AdaptiveQuestionSelector.gd")
const SKILL_TAXONOMY = preload("res://scripts/SkillTaxonomy.gd")
const DECOMPOSITION_ENGINE = preload("res://scripts/DecompositionEngine.gd")
const WORKSHOP_ENGINE = preload("res://scripts/WorkshopEngine.gd")
const SCENE_SCRIPT = preload("res://scripts/SpaceScene.gd")
const KEYPAD_SCRIPT = preload("res://scripts/ui/NeonKeypad.gd")
const FANCY_BUTTON = preload("res://scripts/ui/FancyButton.gd")
const WORLD_ART = [preload("res://assets/worlds/1_lightning_clean.jpg"), preload("res://assets/worlds/2_desert_clean.jpg"), preload("res://assets/worlds/3_crystal_clean.jpg"), preload("res://assets/worlds/4_titan_clean.jpg"), preload("res://assets/worlds/5_blackhole_clean.jpg"), preload("res://assets/locations/world_6.png"), preload("res://assets/locations/world_7.png"), preload("res://assets/locations/world_8.png")]
const MENU_GALAXY = preload("res://assets/battle/menu_galaxy.jpg")
const MENU_BACKGROUNDS = [preload("res://assets/battle/world_1_background.jpg"), preload("res://assets/battle/world_2_background.jpg"), preload("res://assets/battle/world_3_background.jpg"), preload("res://assets/battle/world_4_background.jpg"), preload("res://assets/battle/world_5_background.jpg"), preload("res://assets/locations/world_6.png"), preload("res://assets/locations/world_7.png"), preload("res://assets/locations/world_8.png")]
const WORLD_SUBTITLES = ["TABLE 2-9", "2 DIGITS × 1", "3 DIGITS × 1", "2 DIGITS × 2", "EXACT DIVISION", "TABLE ÷ 2–9", "2 DIGITS ÷ 1", "3 DIGITS ÷ 1"]
const SAVE_MANAGER = preload("res://scripts/SaveManager.gd")
const MISSION_MANAGER = preload("res://scripts/MissionManager.gd")
var save_writable := true
var save_warning := ""
const SAVE_PATH = "user://math_galaxy_progress.json"
const FLEET = preload("res://scripts/FleetBalance.gd")
var encounter_data: Dictionary = {}
var question_target := 10
const PHASE_NAMES := ["WARM-UP", "WORKSHOP", "SPACE BATTLE", "BOSS", "REWARDS"]
const WORLD_NAMES := ["Lightning Academy", "Mechanic Desert", "Crystal Planet", "Titan City", "Black Hole", "Tidal Ocean", "Aurora Gardens", "Solar Forge"]
const BACK := Color("07122d")
const BLUE := Color("2388ef")

var progress: Dictionary = {"coins": 0, "missions": 0, "skills": {}}
var world: int = 1
var level: int = 0
var level_practice: bool = false
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
var difficult_facts: Dictionary = {}
var repair_used := false
var question: Dictionary = {}
var queue: Array[Dictionary] = []
var input_mode: String = "numeric"
var input_value: String = ""
var hint_used: bool = false
var hint_visible: bool = false
var hint_close_button: Button
var hint_stage: int = 0
var hint_texts: Array[String] = []
var hint_button: Button
const HINT_COSTS = [25, 15, 10]
const HINT_SECONDS = [8.0, 6.0, 4.0]
var question_active: bool = false
var transition_delay: float = 0.0
var finished: bool = false
var paused: bool = false
var last_key: String = ""
var recent_keys: Array[String] = []
var pending_defeat: bool = false
var question_attempt_id: String = ""
var workshop_step_started: int = 0
var workshop_session: Dictionary = {}
var workshop_keypad: VBoxContainer
var workshop_value: String = ""
var workshop_feedback: Label
var workshop_next: Button
var workshop_path: VBoxContainer
var workshop_review_open: bool = false

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
	theme = UI_THEME
	L10N.initialize()
	randomize()
	load_progress()
	migrate_learning_data()
	show_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		paused = false
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_progress()

func _process(delta: float) -> void:
	if screen != "battle" or paused or finished or hint_visible:
		return
	elapsed += delta
	if pending_defeat:
		transition_delay -= delta
		if transition_delay <= 0.0: fail_mission()
		return
	if transition_delay > 0.0:
		transition_delay -= delta
		if transition_delay <= 0.0: next_question()
		update_hud()
		return
	if question_active:
		question_elapsed += delta
		if question_elapsed >= question_limit:
			resolve_answer(-1, "timeout")
	update_hud()

func determine_phase() -> int:
	return mini(3, MISSION_MANAGER.question_phase(hits + misses, question_target))

func clear_screen() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

func make_label(value: String, font_size: int = 24, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = L10N.text(value)
	l.add_theme_font_override("font", UI_FONT)
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
	cap.text = L10N.text(value)
	cap.autowrap_mode = TextServer.AUTOWRAP_OFF
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.add_theme_font_override("font", UI_FONT)
	cap.add_theme_font_size_override("font_size", font_size)
	cap.add_theme_color_override("font_color", color)
	cap.add_theme_constant_override("outline_size", 2)
	cap.add_theme_color_override("font_outline_color", Color(0,0,0,0.45))
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(cap)
	cap.offset_left = 20
	cap.offset_right = -20
	cap.offset_top = 6
	cap.offset_bottom = -6

func make_button(value: String, fn: Callable, color: Color = BLUE, min_x: float = 100.0, min_y: float = 56.0, font_size: int = 22) -> Button:
	var btn := Button.new()
	btn.set_script(FANCY_BUTTON)
	btn.set("accent_color", color)
	btn.custom_minimum_size = Vector2(maxf(min_x, UI_FONT.get_string_size(L10N.text(value), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 48), maxf(min_y, font_size + 24))
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
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	var logo := TextureRect.new()
	logo.name = "GameLogo"
	logo.texture = load("res://assets/ui/math_galaxy_logo.png")
	logo.custom_minimum_size = Vector2(240, 110)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(logo)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(make_stat_chip("💎", L10N.text("Crystals %d") % progress.get("coins",0)))
	top.add_child(make_stat_chip("🏅", L10N.text("Missions %d") % progress.get("missions",0)))
	var settings := make_button("", open_parent, Color("274784"), 58, 56, 24)
	var settings_icon := TextureRect.new()
	settings_icon.texture = preload("res://assets/ui/settings.svg")
	settings_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	settings_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	settings_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings.add_child(settings_icon)
	settings_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_icon.offset_left = 16
	settings_icon.offset_right = -16
	settings_icon.offset_top = 15
	settings_icon.offset_bottom = -15
	top.add_child(make_button(L10N.text("HANGAR"), show_hangar, Color("2865ad"), 150, 56, 20))
	top.add_child(settings)
	var languages := HBoxContainer.new()
	languages.name = "LanguageSelector"
	for code in ["en", "uk"]:
		var selected_code: String = code
		var flag := make_button("", func():
			var error := L10N.select_language(selected_code)
			show_menu()
			if error != OK: report_save_warning(L10N.text("Could not save language preference."))
		, Color("22bfff") if L10N.language == code else Color("274784"), 58, 56, 24)
		flag.name = "Language_" + code
		flag.tooltip_text = "Українська" if code == "uk" else "English"
		var icon := TextureRect.new()
		icon.texture = load("res://assets/ui/flag_" + code + ".svg")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flag.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 13
		icon.offset_right = -13
		icon.offset_top = 14
		icon.offset_bottom = -14
		languages.add_child(flag)
	top.add_child(languages)
	root.add_child(top)
	root.add_child(make_label(L10N.text("Learn multiplication and division. Power your spaceship."), 24, Color("d5e4ff")))
	root.add_child(make_label(L10N.text("CHOOSE A WORLD"), 21, Color("ffd85b")))
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 12)
	var world_scroll := horizontal_strip(root, 356)
	world_scroll.add_child(cards)
	for id in PROGRESSION.WORLD_ORDER:
		cards.add_child(make_world_card(id))
	world_scroll.set_deferred("scroll_horizontal", maxi(0, PROGRESSION.WORLD_ORDER.find(world) * 312 - 400))
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(fill)
	var actions := HBoxContainer.new()
	actions.name = "WorldActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	root.add_child(actions)
	actions.add_child(make_button(L10N.text("✦  MATH WORKSHOP"), show_workshop, Color("2865ad"), 440, 78, 26))
	var continue_button := make_button(L10N.text("▶  CONTINUE"), continue_game, Color("00e485"), 340, 78, 29)
	continue_button.name = "ContinueGame"
	continue_button.disabled = PROGRESSION.continue_target(progress).is_empty()
	actions.add_child(continue_button)

func show_workshop() -> void:
	screen = "workshop"
	var root := build_root(MENU_BACKGROUNDS[world - 1])
	var top := HBoxContainer.new()
	root.add_child(top)
	top.add_child(make_button(L10N.text("◀  GALAXY"), show_menu, Color("425d88"), 190, 64, 19))
	top.add_child(make_label(L10N.text("   MATH WORKSHOP - WORLD %d") % (PROGRESSION.WORLD_ORDER.find(world) + 1), 30, Color("84d8ff")))
	if world == 1:
		root.add_child(make_label(L10N.text("Workshop begins in World 2. Select worlds 2-5."), 23))
		return
	root.add_child(make_label(L10N.text("Choose how you want to learn:"), 24))
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 14)
	root.add_child(modes)
	modes.add_child(make_button(L10N.text("SHOW ME"), func(): start_workshop("demo"), Color("2364ad"), 210, 60, 21))
	modes.add_child(make_button(L10N.text("SOLVE TOGETHER"), func(): start_workshop("guided"), Color("2364ad"), 260, 60, 21))
	modes.add_child(make_button(L10N.text("TRY MYSELF"), func(): start_workshop("solo"), Color("00a978"), 235, 60, 21))
	root.add_child(make_label(L10N.text("Practice is separate from battle scores and rewards."), 19, Color("bbd6f3")))

func start_workshop(mode: String) -> void:
	var q: Dictionary = MathEngine.generate(world)
	progress["workshop_sequence"] = int(progress.get("workshop_sequence", 0)) + 1
	workshop_session = WORKSHOP_ENGINE.prepare(q, mode)
	workshop_session["session_id"] = "workshop:%d" % int(progress["workshop_sequence"])
	save_progress()
	workshop_review_open = false
	show_workshop_step()

func show_workshop_step() -> void:
	workshop_step_started = Time.get_ticks_msec()
	screen = "workshop_step"
	workshop_value = ""
	workshop_keypad = null
	var root := build_root(MENU_BACKGROUNDS[world - 1])
	root.add_child(make_button(L10N.text("◀  BACK TO WORKSHOP"), show_workshop, Color("425d88"), 270, 64, 19))
	var q: Dictionary = workshop_session["question"]
	root.add_child(make_label("%d %s %d = ?" % [int(q["a"]), str(q["sign"]), int(q["b"])], 43, Color("8de8ff")))
	var step: Dictionary = WORKSHOP_ENGINE.current_step(workshop_session)
	if step.is_empty():
		finish_workshop()
		return
	var idx: int = int(workshop_session["index"])
	var count: int = workshop_session["steps"].size()
	root.add_child(make_label(L10N.text("STEP %d OF %d") % [idx + 1, count], 19, Color("fcd34d")))
	root.add_child(make_label(str(step["prompt"]), 25, Color.WHITE))
	# Concrete decomposition stays visible. It is an explanation, not an input field.
	root.add_child(make_label(DECOMPOSITION_ENGINE.explanation(q, str(workshop_session.get("strategy", "tens"))), 19, Color("bbd6f3")))
	add_workshop_solution_path(root)
	if world >= 5:
		root.add_child(make_button(L10N.text("↻  ANOTHER DIVISION METHOD"), switch_workshop_strategy, Color("425d88"), 340, 42, 17))
	workshop_feedback = make_label("", 19, Color("c4e5ff"))
	if workshop_session["mode"] == "demo":
		root.add_child(make_label(L10N.text("Answer: %d") % int(step["answer"]), 30, Color("8fffc4")))
		root.add_child(make_button(L10N.text("NEXT STEP ▶"), advance_workshop_demo, Color("00a978"), 230, 58, 22))
	else:
		# The same actual scene script, buttons, colours and behaviour as battle mode.
		var center := CenterContainer.new()
		root.add_child(center)
		workshop_keypad = VBoxContainer.new()
		workshop_keypad.set_script(KEYPAD_SCRIPT)
		workshop_keypad.custom_minimum_size.x = 450
		center.add_child(workshop_keypad)
		workshop_keypad.call("set_value", "")
		workshop_keypad.connect("key_pressed", Callable(self, "press_workshop_digit"))
		root.add_child(workshop_feedback)
		var actions := HBoxContainer.new()
		actions.alignment = BoxContainer.ALIGNMENT_CENTER
		root.add_child(actions)
		actions.add_child(make_button(L10N.text("HINT"), reveal_workshop_step, Color("425d88"), 140, 44, 19))
		workshop_next = make_button(L10N.text("NEXT STEP ▶"), advance_workshop_step, Color("2865ad"), 220, 44, 19)
		workshop_next.visible = false
		actions.add_child(workshop_next)

# Persistent solution board: unresolved values remain hidden until supplied or shown.
func add_workshop_solution_path(root: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", space_panel(Color("0d2041", 0.94), Color("3e9dd9"), 12, 0.12))
	root.add_child(panel)
	var scroll := preload("res://scripts/ui/TouchScroll.gd").new()
	scroll.custom_minimum_size.y = 162
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	workshop_path = VBoxContainer.new()
	workshop_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workshop_path.add_theme_constant_override("separation", 3)
	scroll.add_child(workshop_path)
	refresh_workshop_solution_path()

func refresh_workshop_solution_path() -> void:
	if not is_instance_valid(workshop_path):
		return
	for child in workshop_path.get_children():
		workshop_path.remove_child(child)
		child.queue_free()
	workshop_path.add_child(make_label(L10N.text("SOLUTION PATH"), 19, Color("8de8ff")))
	var session_steps: Array = workshop_session.get("steps", [])
	var results: Array = workshop_session.get("step_results", [])
	var completed: Dictionary = {}
	for entry in results:
		completed[int(entry["step"])] = entry
	var current_index: int = int(workshop_session.get("index", 0))
	var last_index: int = session_steps.size() - 1
	var mode: String = str(workshop_session.get("mode", "guided"))
	var guidance: int = WORKSHOP_ENGINE.guidance_level(progress, world, mode)
	var show_structure: bool = mode != "solo" or workshop_review_open
	if not show_structure:
		workshop_path.add_child(make_label(L10N.text("Solve the full expression yourself. Open HINT to see support."), 17, Color("bbd6f3")))
		return
	var q: Dictionary = workshop_session["question"]
	var partial_values: Array[String] = []
	for i in range(session_steps.size()):
		var part: Dictionary = session_steps[i]
		if i == last_index:
			continue
		var expression: String = str(part.get("expression", part["prompt"]))
		var value_text: String = "?"
		var status: String = L10N.text("TO SOLVE")
		var color := Color("bbd6f3")
		if completed.has(i):
			var recorded: Dictionary = completed[i]
			value_text = str(recorded["answer"])
			match str(recorded["source"]):
				"self": status = L10N.text("MY ANSWER"); color = Color("8fffc4")
				"hint": status = L10N.text("WITH HINT"); color = Color("fcd34d")
				_: status = L10N.text("SHOWN"); color = Color("b6d2fa")
			if int(recorded.get("mistakes", 0)) > 0:
				status += L10N.text(" / RETRIED")
		elif i == current_index:
			status = L10N.text("CURRENT STEP") if not bool(workshop_session.get("current_hint", false)) else L10N.text("HINT OPENED")
			color = Color("8de8ff")
		if guidance >= 2 and i > current_index and not workshop_review_open:
			expression = L10N.text("Next calculation")
		elif guidance >= 1 and i > current_index + 1 and not workshop_review_open:
			expression = L10N.text("Upcoming calculation")
		var row_panel := PanelContainer.new()
		if i == current_index and not workshop_review_open:
			row_panel.add_theme_stylebox_override("panel", space_panel(Color("193e65", 0.94), Color("69e5ff"), 7, 0.0))
		else:
			row_panel.add_theme_stylebox_override("panel", space_panel(Color("102348", 0.55), Color("253c62"), 7, 0.0))
		workshop_path.add_child(row_panel)
		var row_label := make_label("%d. %s = %s   [%s]" % [i + 1, expression, value_text, status], 17, color)
		row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row_panel.add_child(row_label)
		partial_values.append(value_text)
	if last_index > 0:
		var is_division: bool = int(q["world"]) >= 5
		if is_division:
			var first_quotient: int = int(q["a"] / q["b"]) - int(session_steps[2]["answer"])
			var remaining_quotient: String = partial_values[2] if partial_values.size() > 2 else "?"
			workshop_path.add_child(make_label(L10N.text("Combine quotients: %d + %s = %s") % [first_quotient, remaining_quotient, partial_values[3] if partial_values.size() > 3 else "?"], 18, Color("8de8ff")))
		else:
			var products: Array = partial_values.slice(0, partial_values.size() - 1)
			workshop_path.add_child(make_label(L10N.text("Add partial products: %s = %s") % [" + ".join(products), partial_values[partial_values.size() - 1]], 18, Color("8de8ff")))
	if last_index >= 0:
		var final_value: String = "?"
		var final_status: String = L10N.text("TO SOLVE")
		if completed.has(last_index):
			final_value = str(completed[last_index]["answer"])
			final_status = L10N.text("MY ANSWER") if str(completed[last_index]["source"]) == "self" else L10N.text("ASSISTED / SHOWN")
		workshop_path.add_child(make_label(L10N.text("Result: %d %s %d = %s   [%s]") % [int(q["a"]), str(q["sign"]), int(q["b"]), final_value, final_status], 18, Color("8fffc4")))

func switch_workshop_strategy() -> void:
	if world < 5:
		return
	var strategy: String = "halves" if str(workshop_session.get("strategy", "tens")) == "tens" else "tens"
	# Changing a method starts a fresh attempt; previous mistakes are retained.
	WORKSHOP_ENGINE.change_strategy(workshop_session, strategy)
	show_workshop_step()

func press_workshop_digit(digit: String) -> void:
	if screen != "workshop_step" or workshop_session.get("mode", "demo") == "demo":
		return
	if not is_instance_valid(workshop_next) or workshop_next.visible:
		return
	if digit == "⌫":
		workshop_value = workshop_value.substr(0, maxi(0, workshop_value.length() - 1))
	elif digit == "OK":
		submit_workshop_step()
	else:
		if workshop_value.length() < 7 and digit.is_valid_int():
			workshop_value += digit
	if is_instance_valid(workshop_keypad):
		workshop_keypad.call("set_value", workshop_value)

func advance_workshop_demo() -> void:
	var demo_index: int = int(workshop_session["index"])
	record_workshop_attempt(true, "demo")
	var history: Array = workshop_session.get("step_results", [])
	history.append({"step": demo_index, "answer": int(WORKSHOP_ENGINE.current_step(workshop_session)["answer"]), "source": "shown"})
	workshop_session["step_results"] = history
	workshop_session["index"] = demo_index + 1
	workshop_session["complete"] = int(workshop_session["index"]) >= workshop_session["steps"].size()
	show_workshop_step()

func submit_workshop_step() -> void:
	if not is_instance_valid(workshop_next) or workshop_next.visible:
		return
	if not workshop_value.is_valid_int():
		workshop_feedback.text = L10N.text("Enter a whole number first.")
		return
	var expected: int = int(WORKSHOP_ENGINE.current_step(workshop_session)["answer"])
	record_workshop_attempt(int(workshop_value) == expected, "answer")
	var correct: bool = WORKSHOP_ENGINE.check(workshop_session, int(workshop_value))
	workshop_step_started = Time.get_ticks_msec()
	workshop_keypad.call("flash", correct)
	if correct:
		workshop_feedback.text = L10N.text("Correct! Continue to the next step.")
		workshop_next.visible = true
		refresh_workshop_solution_path()
	else:
		workshop_feedback.text = L10N.text("Not quite. Check this calculation and try again. Your mistake is recorded.")

func reveal_workshop_step() -> void:
	if is_instance_valid(workshop_next) and workshop_next.visible:
		return
	WORKSHOP_ENGINE.reveal(workshop_session)
	workshop_review_open = true
	var step: Dictionary = WORKSHOP_ENGINE.current_step(workshop_session)
	workshop_feedback.text = L10N.text("Hint: this step equals %d. Type it to continue.") % int(step["answer"])
	refresh_workshop_solution_path()

func advance_workshop_step() -> void:
	show_workshop_step()

func finish_workshop() -> void:
	if bool(workshop_session.get("recorded", false)):
		return
	workshop_session["recorded"] = true
	var outcome: Dictionary = WORKSHOP_ENGINE.summary(workshop_session)
	var records: Array = progress.get("workshop_history", [])
	outcome["timestamp"] = int(Time.get_unix_time_from_system())
	records.append(outcome)
	if records.size() > 200:
		records.pop_front()
	progress["workshop_history"] = records
	var totals: Dictionary = progress.get("workshop_totals", {})
	for key in ["completed", "hints", "mistakes", "independent"]:
		totals[key] = int(totals.get(key, 0)) + int(outcome.get(key, 0))
	progress["workshop_totals"] = totals
	WORKSHOP_ENGINE.record_guided_streak(progress, outcome)
	save_progress()
	screen = "workshop_complete"
	var root := build_root(MENU_BACKGROUNDS[world - 1])
	root.add_child(make_label(L10N.text("WORKSHOP COMPLETE!"), 48, Color("8fffc4")))
	root.add_child(make_label(L10N.text("Mistakes: %d   Hints: %d") % [int(outcome["mistakes"]), int(outcome["hints"])], 27))
	root.add_child(make_label(L10N.text("Independent: YES") if outcome["independent"] else L10N.text("Guided practice completed"), 23, Color("c4e5ff")))
	root.add_child(make_button(L10N.text("REVIEW SOLUTION"), show_workshop_review, Color("2865ad"), 280, 58, 20))
	root.add_child(make_button(L10N.text("TRY ANOTHER"), func(): start_workshop(str(workshop_session["mode"])), Color("00a978"), 260, 64, 22))
	root.add_child(make_button(L10N.text("BACK TO WORKSHOP"), show_workshop, Color("425d88"), 280, 64, 21))

func show_workshop_review() -> void:
	screen = "workshop_review"
	workshop_review_open = true
	var root := build_root(MENU_BACKGROUNDS[world - 1])
	root.add_child(make_label(L10N.text("REVIEW YOUR SOLUTION"), 35, Color("8de8ff")))
	root.add_child(make_label(DECOMPOSITION_ENGINE.explanation(workshop_session["question"], str(workshop_session.get("strategy", "tens"))), 20, Color("bbd6f3")))
	# Reuse the same solution-path renderer, with all completed steps intact.
	add_workshop_solution_path(root)
	root.add_child(make_button(L10N.text("BACK TO WORKSHOP"), show_workshop, Color("425d88"), 280, 64, 20))
	root.add_child(make_button(L10N.text("TRY ANOTHER"), func(): start_workshop(str(workshop_session["mode"])), Color("00a978"), 260, 58, 20))

func horizontal_strip(root: Control, height: float) -> ScrollContainer:
	var navigation := HBoxContainer.new()
	root.add_child(navigation)
	var scroll := preload("res://scripts/ui/TouchScroll.gd").new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = height
	navigation.add_child(make_button("‹", func(): scroll.scroll_horizontal -= 400, Color("2865ad"), 48, 60, 30))
	navigation.add_child(scroll)
	navigation.add_child(make_button("›", func(): scroll.scroll_horizontal += 400, Color("2865ad"), 48, 60, 30))
	scroll.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			scroll.scroll_horizontal += 160 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -160
			scroll.accept_event()
	)
	return scroll

func make_world_card(idx: int) -> Button:
	var selected: bool = idx == world
	var b := make_button("", func(): select_world(idx), Color("2dcdf6") if selected else Color("4260a4"), 300, 330, 20)
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
	pic.texture = LOCATIONS.world_portrait(idx) if idx >= 6 else WORLD_ART[idx - 1]
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pic.offset_left = 0
	pic.offset_top = 0
	pic.offset_right = 0
	pic.offset_bottom = 0
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture_material := ShaderMaterial.new()
	picture_material.shader = preload("res://assets/shaders/beveled_picture.gdshader")
	pic.material = picture_material
	pic.resized.connect(func(): picture_material.set_shader_parameter("rect_size", pic.size))
	picture_clip.add_child(pic)
	var glow := ColorRect.new()
	glow.color = Color(0.1,0.2,0.4,0.16 if selected else 0.28)
	glow.material = picture_material
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture_clip.add_child(glow)
	var footer := PanelContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 8
	footer.offset_right = -8
	footer.offset_top = -172
	footer.offset_bottom = -21
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_theme_stylebox_override("panel", space_panel(Color(0.03,0.05,0.12,0.70), Color("57cfff") if selected else Color("7184b5"), 12, 0.05))
	b.add_child(footer)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	footer.add_child(box)
	box.add_child(make_label(L10N.text("WORLD %d") % (PROGRESSION.WORLD_ORDER.find(idx) + 1), 20, Color("fff2a6")))
	var title := make_label(L10N.text(WORLD_NAMES[idx - 1]), 26, Color("f8fdff"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var subtitle := make_label(L10N.text(WORLD_SUBTITLES[idx - 1]), 19, Color("8ff0ff" if selected else Color("b0d0ff")))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subtitle)
	ignore_card_mouse(box)
	var open_locations := Button.new()
	open_locations.name = "OpenWorldLocations"
	open_locations.mouse_filter = Control.MOUSE_FILTER_STOP
	open_locations.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	open_locations.tooltip_text = L10N.text("WORLD %d - SUBLEVELS") % (PROGRESSION.WORLD_ORDER.find(idx) + 1)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		open_locations.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var text_hit_area := Control.new()
	text_hit_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(text_hit_area)
	text_hit_area.add_child(open_locations)
	open_locations.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	open_locations.pressed.connect(func(): open_world_locations(idx))
	return b

func select_world(value: int) -> void:
	world = value
	level = 0
	show_menu()

func open_world_locations(value: int) -> void:
	world = value
	level = 0
	show_levels()

func continue_game() -> void:
	var target: Dictionary = PROGRESSION.continue_target(progress)
	if target.is_empty(): return
	world = int(target.world)
	select_level(int(target.level))

func show_levels() -> void:
	screen = "levels"
	var root := build_root(MENU_BACKGROUNDS[world - 1])
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	root.add_child(top)
	var back := make_button(L10N.text("◀  GALAXY"), show_menu, Color("4260a4"), 0, 64, 19)
	back.name = "LocationsBack"
	top.add_child(back)
	var title := make_label(L10N.text("WORLD %d - SUBLEVELS") % (PROGRESSION.WORLD_ORDER.find(world) + 1), 34, Color("84d8ff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(title)
	var practice := make_button("", start_level_practice, Color("4260a4"), 190, 64, 19)
	practice.name = "PracticeOnly"
	practice.tooltip_text = L10N.text("Practice does not open locations. Play a location card to advance.")
	practice.disabled = not PROGRESSION.is_unlocked(progress, world, 0)
	top.add_child(practice)
	var practice_content := HBoxContainer.new()
	practice.add_child(practice_content)
	practice_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	practice_content.offset_left = 14
	practice_content.offset_right = -14
	practice_content.offset_top = 6
	practice_content.offset_bottom = -6
	practice_content.alignment = BoxContainer.ALIGNMENT_CENTER
	practice_content.add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/ui/practice.svg")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(32, 32)
	practice_content.add_child(icon)
	var caption := VBoxContainer.new()
	caption.alignment = BoxContainer.ALIGNMENT_CENTER
	caption.add_theme_constant_override("separation", 0)
	practice_content.add_child(caption)
	caption.add_child(make_label(L10N.text("Training"), 20, Color("eefaff")))
	caption.add_child(make_label(L10N.text("No progress"), 15, Color("ffe49b")))
	ignore_card_mouse(practice_content)
	var instruction := make_label(L10N.text("Each victory opens the next location. Choose first, then solve on your own."), 19, Color("c1dcff"))
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(instruction)
	var scroll := preload("res://scripts/ui/TouchScroll.gd").new()
	scroll.name = "SublevelScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "SublevelGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	scroll.resized.connect(func(): grid.columns = clampi(int((scroll.size.x + 14) / 440), 1, 2))
	for i in range(PROGRESSION.levels(world).size()):
		grid.add_child(make_sublevel_card(i))

func make_sublevel_card(index: int) -> Button:
	var available: bool = PROGRESSION.is_unlocked(progress, world, index)
	var completed: bool = bool(progress.get("completed_levels", {}).get(PROGRESSION.id_for(world, index), false))
	var choice: bool = PROGRESSION.input_mode(index) == "choices"
	var color := Color("28cfe6") if choice else Color("bc8aff")
	var card := make_button("", func(): select_level(index), color if available else Color("425473"), 320, 480, 20)
	card.name = "Sublevel_%d" % index
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.disabled = not available
	card.focus_mode = Control.FOCUS_ALL
	card.clip_contents = true
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16
	content.offset_right = -16
	content.offset_top = 16
	content.offset_bottom = -16
	content.add_theme_constant_override("separation", 5)
	card.add_child(content)
	var image := TextureRect.new()
	image.name = "LocationPreview"
	image.texture = LOCATIONS.texture(world, index)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.custom_minimum_size.y = 190
	if not available:
		var blur := ShaderMaterial.new()
		blur.shader = preload("res://assets/shaders/locked_location.gdshader")
		blur.set_shader_parameter("blurred_image", preload("res://scripts/ui/LocationArt.gd").blurred_thumbnail(image.texture))
		image.material = blur
		var lock := Control.new()
		lock.name = "LocationLock"
		lock.set_script(preload("res://scripts/ui/LocationLock.gd"))
		image.add_child(lock)
		lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(image)
	var status: String = L10N.text("Completed · replay") if completed else L10N.text("Ready to explore") if available else L10N.text("Locked")
	content.add_child(make_card_label("%02d  ·  %s" % [index + 1, status], 20, Color("ffe49b")))
	content.add_child(make_card_label(LOCATIONS.title(world, index), 26, Color("c8ecff")))
	content.add_child(make_card_label(L10N.text(PROGRESSION.TRACKS[world - 1][int(index / 2)]), 26, Color.WHITE))
	var explanation: String = L10N.text("Choose the correct answer from 4 options.\nYou have 5 seconds per example.") if choice else L10N.text("Solve the same skill on your own.\nType your answer using the keypad.")
	content.add_child(make_card_label(explanation, 21, Color("dce8ff")))
	var footer := make_card_label(L10N.text("Choose · 5 seconds") if choice else L10N.text("Enter · reinforcement"), 20, color.lightened(0.25))
	footer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	footer.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	content.add_child(footer)
	if not available:
		card.tooltip_text = PROGRESSION.requirement(progress, world, index)
		footer.text = L10N.text("Finish the previous sublevel") if index > 0 else PROGRESSION.requirement(progress, world, index)
	else:
		card.tooltip_text = L10N.text("Defeat the monster to unlock the next location. Mistakes are allowed.")
	ignore_card_mouse(content)
	return card

func make_card_label(value: String, font_size: int, color: Color) -> Label:
	var label := make_label(value, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func ignore_card_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control: ignore_card_mouse(child)

func select_level(index: int) -> void:
	if not PROGRESSION.is_unlocked(progress, world, index): return
	level = index
	level_practice = false
	start_mission()

func start_level_practice() -> void:
	if not PROGRESSION.is_unlocked(progress, world, 0): return
	level = PROGRESSION.practice_target(progress, world)
	level_practice = true
	start_mission()

func start_mission() -> void:
	question_target = 12 if PROGRESSION.is_final(world, level) else 10
	REWARD_MANAGER.migrate(progress)
	progress["mission_sequence"] = maxi(int(progress.get("mission_sequence", 0)), int(progress.rewards.settled)) + 1
	save_progress()
	difficult_facts.clear()
	repair_used = false
	elapsed = 0.0
	phase = 0
	shield = 100
	encounter_data = FLEET.encounter(world, level, question_target)
	energy = 65 if progress.rewards.owned.has("battery") else 50
	combo = 0
	hits = 0
	misses = 0
	coins_earned = 0
	queue.clear()
	hint_visible = false
	transition_delay = 0.0
	question_active = false
	last_key = ""
	recent_keys.clear()
	pending_defeat = false
	finished = false
	paused = false
	screen = "battle"
	build_battle()
	next_question()

func build_battle() -> void:
	var root := build_root(LOCATIONS.texture(world, level))
	var top_panel := PanelContainer.new()
	top_panel.set_script(preload("res://scripts/ui/BattleHudFrame.gd"))
	root.add_child(top_panel)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 10)
	top_panel.add_child(top)
	shield_label = make_label("100%", 20, Color("8de5ff"))
	shield_label.custom_minimum_size.x = 64
	var shield_icon := TextureRect.new()
	shield_icon.texture = preload("res://assets/ui/shield.svg")
	shield_icon.custom_minimum_size = Vector2(34, 40)
	shield_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shield_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shield_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(shield_icon)
	top.move_child(shield_icon, 0)
	top.add_child(shield_label)
	shield_bar = ProgressBar.new()
	shield_bar.max_value = 100
	shield_bar.value = 100
	shield_bar.custom_minimum_size = Vector2(160, 22)
	shield_bar.set_script(preload("res://scripts/ui/ShieldMeter.gd"))
	shield_bar.custom_minimum_size.y = 28
	shield_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(shield_bar)
	if progress.rewards.owned.has("repair"):
		var repair := make_button("+15", use_repair, Color("2865ad"), 110, 64, 20)
		repair.name = "BattleRepair"
		repair.tooltip_text = L10N.text("Repair pulse restores 15 shield once per mission.")
		var repair_caption: Label = repair.get_node("Caption")
		repair_caption.offset_left = 42
		var wrench := TextureRect.new()
		wrench.texture = load("res://assets/ui/repair.svg")
		wrench.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wrench.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wrench.mouse_filter = Control.MOUSE_FILTER_IGNORE
		repair.add_child(wrench)
		wrench.position = Vector2(13, 16)
		wrench.size = Vector2(30, 30)
		top.add_child(repair)
	header = make_label(L10N.text("WORLD %d") % (PROGRESSION.WORLD_ORDER.find(world) + 1), 18, Color("ffe270"))
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(header)
	energy_label = make_label(L10N.text("ENERGY 50  •  COMBO 0"), 18, Color("ffd85d"))
	energy_label.custom_minimum_size.x = 200
	top.add_child(energy_label)
	info = make_label("", 14, Color.WHITE)
	info.custom_minimum_size.x = 92
	top.add_child(info)
	top.add_child(make_button(L10N.text("◀ EXIT"), exit_mission, Color("4f8cdb"), 120, 64, 20))

	art = Control.new()
	art.set_script(SCENE_SCRIPT)
	art.call("set_world", world)
	art.call("set_location", LOCATIONS.texture(world, level))
	art.set("actor_layout_scale", 0.6 if PROGRESSION.input_mode(level) == "numeric" else 1.0)
	art.custom_minimum_size.y = 132 if PROGRESSION.input_mode(level) == "numeric" else 204
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root.add_child(art)
	var location_caption := make_label(LOCATIONS.title(world, level) + " · " + L10N.text(PROGRESSION.TRACKS[world - 1][int(level / 2)]), 16, Color("bfe8ff"))
	root.add_child(location_caption)
	art.connect("ship_impact", update_hud)

	var question_card := PanelContainer.new()
	question_card.add_theme_stylebox_override("panel", space_panel(Color(0.01,0.07,0.18,0.51), Color("1daeff"), 18, 0.12))
	root.add_child(question_card)
	var qbox := VBoxContainer.new()
	qbox.alignment = BoxContainer.ALIGNMENT_CENTER
	qbox.add_theme_constant_override("separation", 4)
	question_card.add_child(qbox)
	var question_row := HBoxContainer.new()
	question_row.add_theme_constant_override("separation", 12)
	question_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qbox.add_child(question_row)
	hint_button = make_button(L10N.text("✦ HINT 1/3  -25"), use_hint, Color("9d50ff"), 220, 64, 20)
	question_row.add_child(hint_button)
	hint_close_button = make_button(L10N.text("CONTINUE ▶"), close_hint, Color("2865ad"), 220, 64, 20)
	hint_close_button.visible = false
	question_row.add_child(hint_close_button)
	question_label = make_label("7 × 8 = ?", 46, Color.WHITE)
	question_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_row.add_child(question_label)
	var timer_shell := VBoxContainer.new()
	question_row.add_child(timer_shell)
	timer_shell.custom_minimum_size = Vector2(142, 56)
	timer_shell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	timer_shell.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_label = make_label("8.0 s", 23, Color("ffd85b"))
	timer_shell.add_child(timer_label)
	timer_bar = ProgressBar.new()
	timer_bar.custom_minimum_size = Vector2(142, 13)
	style_progress(timer_bar, Color("ffc857"))
	timer_shell.add_child(timer_bar)
	var skip := make_button(L10N.text("↻ SKIP  -%d SHIELD") % (20 - FLEET.ARMOR[FLEET.ship_index(str(progress.rewards.equipped))]), func(): resolve_answer(-1, "skip"), Color("f04d76"), 235, 64, 20)
	skip.name = "BattleSkip"
	question_row.add_child(skip)
	feedback = make_label("", 22, Color("a7f3d0"))
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qbox.add_child(feedback)

	answer_area = VBoxContainer.new()
	answer_area.custom_minimum_size.y = 81
	answer_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(answer_area)

	art.call("configure_encounter", str(progress.rewards.equipped), str(progress.rewards.weapon), encounter_data)
	update_hud()
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
		header.text = L10N.text("%s  •  WORLD %d") % [L10N.text(PHASE_NAMES[phase]), PROGRESSION.WORLD_ORDER.find(world) + 1]
	if art != null and is_instance_valid(art):
		art.call("set_boss_mode", phase == 3)

func update_hud() -> void:
	info.text = L10N.text("Hits: %d\nDamage: %d • Armor: %d") % [hits, int(art.get("attack_damage")), FLEET.ARMOR[FLEET.ship_index(str(progress.rewards.equipped))]]
	if art == null or float(art.get("enemy_attack_timer")) <= 0.0:
		shield_label.text = "%d%%" % shield
		shield_bar.value = shield
	energy_label.text = L10N.text("ENERGY %d  •  COMBO %d") % [energy, combo]
	timer_label.text = L10N.text("PAUSED") if hint_visible else "%.1f s" % maxf(0.0, question_limit - question_elapsed)
	timer_bar.max_value = question_limit
	timer_bar.value = maxf(0.0, question_limit - question_elapsed)

func choose_question() -> Dictionary:
	for i in range(queue.size()):
		if int(progress.get("attempt_sequence", 0)) >= int(queue[i].get("retry_after", 0)):
			var retry: Dictionary = queue[i]
			queue.remove_at(i)
			retry.erase("retry_after")
			return retry
	# Both halves of a skill stay on the selected topic, including independent world starts.
	return PROGRESSION.generate(world, level)

func choose_question_legacy() -> Dictionary:
	var today: int = int(Time.get_unix_time_from_system() / 86400.0)
	if phase >= 3 and not queue.is_empty() and randf() < 0.75:
		var pending: Dictionary = queue.pop_front()
		if not recent_keys.has(str(pending.get("key", ""))):
			return pending
	return ADAPTIVE_SELECTOR.choose(world, progress.get("skills", {}), recent_keys, today, progress.get("strategies", {}))

func next_question() -> void:
	if finished: return
	if hits + misses >= question_target and int(art.get("enemy_hp")) <= 0:
		finish_mission()
		return
	phase = determine_phase()
	update_phase_label()
	question = choose_question()
	progress["attempt_sequence"] = int(progress.get("attempt_sequence", 0)) + 1
	question_attempt_id = "battle:%d" % int(progress["attempt_sequence"])
	save_progress()
	last_key = question["key"]
	recent_keys.append(last_key)
	if recent_keys.size() > 5:
		recent_keys.pop_front()
	question_elapsed = 0.0
	question_limit = PARENT_DATA.limits(progress)[int(question["world"]) - 1]
	if phase == 1:
		question_limit += 8.0
	hint_used = false
	hint_stage = 0
	hint_button.visible = true
	hint_visible = false
	hint_close_button.visible = false
	hint_texts = MathEngine.hint_stages(question, randf() < 0.5 and int(question.world) > 1)
	hint_button.get_node("Caption").text = L10N.text("✦ HINT 1/3  -25")
	question_active = true
	input_value = ""
	input_mode = PROGRESSION.input_mode(level)
	if input_mode == "choices": question_limit = 5.0
	question_label.text = "%d %s %d = ?" % [question["a"],question["sign"],question["b"]]
	feedback.text = L10N.text("Enter your answer") if input_mode == "numeric" else L10N.text("Choose the answer")
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
		keypad.set("key_height", 64.0)
		keypad.custom_minimum_size.x = 510
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
	if not event.pressed: return
	if screen == "workshop_step" and workshop_session.get("mode", "demo") != "demo":
		if event is InputEventKey:
			var workshop_key := OS.get_keycode_string(event.keycode)
			if workshop_key.length() == 1 and workshop_key.is_valid_int(): press_workshop_digit(workshop_key)
			elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER: press_workshop_digit("OK")
			elif event.keycode == KEY_BACKSPACE: press_workshop_digit("⌫")
		return
	if screen != "battle" or not question_active: return
	if event is InputEventKey:
		var key := OS.get_keycode_string(event.keycode)
		if key.length() == 1 and key.is_valid_int(): press_digit(key)
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER: press_digit("OK")
		elif event.keycode == KEY_BACKSPACE: press_digit("⌫")

func queue_review() -> void:
	for pending in queue:
		if pending.key == question.key: return
	if queue.size() < 30:
		var retry: Dictionary = question.duplicate(true)
		retry["retry_after"] = int(progress.get("attempt_sequence", 0)) + 3
		queue.append(retry)

func show_hint_pause() -> void:
	hint_button.visible = false
	hint_visible = true
	hint_close_button.visible = true
	update_hud()

func close_hint() -> void:
	hint_button.visible = true
	hint_visible = false
	hint_close_button.visible = false
	if question_active:
		feedback.text = L10N.text("Enter your answer") if input_mode == "numeric" else L10N.text("Choose the answer")
	update_hud()

func use_hint() -> void:
	if not question_active or finished or paused: return
	if hint_stage == 3:
		feedback.text = hint_texts[2]
		show_hint_pause()
		return
	var cost: int = HINT_COSTS[hint_stage]
	if energy < cost:
		feedback.text = L10N.text("Not enough energy") + ("\n" + hint_texts[hint_stage - 1] if hint_stage > 0 else "")
		if hint_stage > 0: show_hint_pause()
		return
	energy -= cost
	hint_used = true
	feedback.text = L10N.text("Hint %d/3: %s") % [hint_stage + 1, hint_texts[hint_stage]]
	question_limit += HINT_SECONDS[hint_stage]
	hint_stage += 1
	queue_review()
	hint_button.get_node("Caption").text = L10N.text("✦ REVIEW HINT") if hint_stage == 3 else L10N.text("✦ HINT %d/3  -%d") % [hint_stage + 1, HINT_COSTS[hint_stage]]
	show_hint_pause()

func resolve_answer(value: int, reason: String) -> void:
	if not question_active or finished: return
	close_hint()
	question_active = false
	var correct: bool = reason == "answer" and value == question["answer"]
	PARENT_DATA.record(progress, question, world, level, correct, input_mode, hint_used, question_elapsed, "battle")
	var fast: bool = question_elapsed <= question_limit * 0.45 and not hint_used
	var skill_key: String = question["key"]
	var skills: Dictionary = progress["skills"]
	if correct and input_mode == "numeric" and not hint_used and int(skills.get(skill_key, {}).get("wrong", 0)) > 0:
		difficult_facts[skill_key] = true
	var stats: Dictionary = LEARNING_ENGINE.record(skills.get(skill_key, {}), correct, reason, question_elapsed, input_mode, hint_used, int(progress.get("mission_sequence", 0)), int(Time.get_unix_time_from_system() / 86400.0), question_attempt_id, LEARNING_ENGINE.criteria_for(progress, int(question["world"])))
	if keypad != null:
		keypad.call("flash", correct)
	if correct:
		hits += 1
		combo += 1
		energy = mini(100, energy + (15 if fast else 10))
		shield = mini(100, shield + 5 + (10 if combo % 5 == 0 else 0))
		var reward: int = 10 + (5 if fast else 0)
		if hits <= question_target: coins_earned += reward
		else: reward = 0
		feedback.text = L10N.text("DIRECT HIT! +%d pending crystals") % reward
		art.call("hit_enemy")
	else:
		misses += 1
		combo = 0
		shield = maxi(0, shield - int(art.get("incoming_damage")))
		feedback.text = L10N.text("%s! Answer: %d") % [L10N.text(reason.to_upper()), question["answer"]]
		art.call("hit_ship")
		queue_review()
		if shield == 0:
			feedback.text = L10N.text("SHIELD DEPLETED! RETREATING")
	PROGRESSION.record(progress, world, level, question, correct, reason, input_mode, hint_used, phase == 3 and not level_practice)
	skills[skill_key] = stats
	if int(question["world"]) > 1:
		var strategy_key: String = SKILL_TAXONOMY.key_for(question)
		var strategies: Dictionary = progress.get("strategies", {})
		strategies[strategy_key] = LEARNING_ENGINE.record(strategies.get(strategy_key, {}), correct, reason, question_elapsed, input_mode, hint_used, int(progress.get("mission_sequence", 0)), int(Time.get_unix_time_from_system() / 86400.0), question_attempt_id, LEARNING_ENGINE.criteria_for(progress, int(question["world"])))
		progress["strategies"] = strategies
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
	REWARD_MANAGER.settle(progress, int(progress.mission_sequence), false, hits, misses, 0, 0, Time.get_date_string_from_system(true), world)
	PARENT_DATA.mission(progress, world, level, elapsed, hits, misses, false, level_practice)
	question_active = false
	transition_delay = 0.0
	save_progress()
	screen = "game_over"
	var root := build_root(MENU_BACKGROUNDS[world - 1])
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	root.add_child(make_label(L10N.text("EMERGENCY RETREAT"), 58, Color("fb7185")))
	root.add_child(make_label(L10N.text("World %d: %s") % [PROGRESSION.WORLD_ORDER.find(world) + 1, L10N.text(WORLD_NAMES[world - 1])], 26))
	root.add_child(make_label(L10N.text("Correct: %d        Missed: %d") % [hits, misses], 31))
	root.add_child(make_label(L10N.text("Shield: 0%  •  No mission crystals awarded"), 24, Color("fda4af")))
	root.add_child(make_label(L10N.text("Your answers were saved for future practice"), 21, Color("a7bddf")))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	root.add_child(row)
	row.add_child(make_button(L10N.text("◀  RETURN TO WORLD"), show_levels, Color("00e485"), 280, 68, 24))
	row.add_child(make_button(L10N.text("↻  RETRY LEVEL"), start_mission, Color("2865ad"), 260, 68, 24))
	row.add_child(make_button(L10N.text("◀  RETURN TO GALAXY"), show_menu, Color("425d88"), 280, 68, 24))
	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sp2)

func finish_mission() -> void:
	if finished: return
	if shield <= 0 or pending_defeat:
		fail_mission()
		return
	if art == null or int(art.get("enemy_hp")) > 0 or hits < question_target: return
	finished = true
	PARENT_DATA.mission(progress, world, level, elapsed, hits, misses, true, level_practice)
	question_active = false
	var payout: Dictionary = REWARD_MANAGER.settle(progress, int(progress.mission_sequence), true, hits, misses, coins_earned, difficult_facts.size(), Time.get_date_string_from_system(true), world)
	coins_earned = int(payout.amount)
	progress["missions"] = int(progress.get("missions",0)) + 1
	var passed: bool = false
	if not level_practice:
		passed = PROGRESSION.complete_victory(progress, world, level, hits, int(art.get("enemy_hp")), shield, level_practice)
	save_progress()
	screen = "results"
	var root := build_root(MENU_BACKGROUNDS[world - 1])
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	root.add_child(make_label(L10N.text("MISSION COMPLETE"), 58, Color("fcd34d")))
	root.add_child(make_label(L10N.text("World %d: %s") % [PROGRESSION.WORLD_ORDER.find(world) + 1,L10N.text(WORLD_NAMES[world - 1])], 26))
	root.add_child(make_label(L10N.text("Correct: %d        Missed: %d        Shield: %d%%") % [hits,misses,shield], 31))
	root.add_child(make_label(L10N.text("+%d crystals    •    %d questions awaiting review") % [coins_earned,queue.size()], 29, Color("7dd3fc")))
	var reward_note := make_label(str(payout.details), 17, Color("ffd85b"))
	reward_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(reward_note)
	root.add_child(make_label(L10N.text("SUBLEVEL PASSED") if passed else L10N.text("Practice complete. Play the location to unlock the next one.") if level_practice else L10N.text("Victory recorded."), 21, Color("a7f3d0")))
	if passed and PROGRESSION.is_unlocked(progress, world, level + 1):
		root.add_child(make_button(L10N.text("NEXT LOCATION ▶"), func(): select_level(level + 1), Color("2865ad"), 280, 56, 22))
	root.add_child(make_button(L10N.text("◀  RETURN TO WORLD"), show_levels, Color("00e485"), 280, 68, 24))
	root.add_child(make_button(L10N.text("◀  RETURN TO GALAXY"), show_menu, Color("425d88"), 280, 64, 20))
	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(sp2)

func exit_mission() -> void:
	coins_earned = 0
	fail_mission()

func save_progress() -> void:
	if not save_writable: return
	REWARD_MANAGER.migrate(progress)
	if not SAVE_MANAGER.write_save(SAVE_PATH, progress):
		report_save_warning(L10N.text("Could not save progress. Check available storage and permissions."))

func report_save_warning(text: String) -> void:
	push_warning(text)
	if text == save_warning: return
	save_warning = text
	var dialog := AcceptDialog.new()
	dialog.title = L10N.text("Profile storage")
	dialog.dialog_text = text
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(680, 200))

func load_progress() -> void:
	var result := SAVE_MANAGER.load_profile(SAVE_PATH)
	progress = result.data
	save_writable = result.writable
	if not str(result.warning).is_empty():
		call_deferred("report_save_warning", str(result.warning))

func record_workshop_attempt(correct: bool, reason: String) -> void:
	var q: Dictionary = workshop_session["question"]
	var index: int = int(workshop_session["index"])
	var final_step: bool = index == workshop_session["steps"].size() - 1
	var mode: String = str(workshop_session["mode"])
	var assisted: bool = mode != "solo" or int(workshop_session["hints"]) > 0 or int(workshop_session["mistakes"]) > 0
	var count: int = int(workshop_session.get("attempt_count", 0)) + 1
	workshop_session["attempt_count"] = count
	var event_id: String = "%s:%d" % [workshop_session["session_id"], count]
	var day: int = int(Time.get_unix_time_from_system() / 86400.0)
	var seconds: float = (Time.get_ticks_msec() - workshop_step_started) / 1000.0
	PARENT_DATA.record(progress, q, int(q["world"]), -1, correct, "demo" if mode == "demo" else "numeric", assisted, seconds, "workshop")
	var bucket: String = "skills" if int(q["world"]) == 1 else "strategies"
	var key: String = SKILL_TAXONOMY.key_for(q)
	if not final_step:
		bucket = "workshop_steps"
		key += ":%s:%d" % [workshop_session.get("strategy", "tens"), index]
	var records: Dictionary = progress.get(bucket, {})
	records[key] = LEARNING_ENGINE.record(records.get(key, {}), correct, reason, seconds, "demo" if mode == "demo" else "numeric", assisted, -int(progress["workshop_sequence"]), day, event_id, LEARNING_ENGINE.criteria_for(progress, int(q["world"])))
	progress[bucket] = records
	save_progress()

func migrate_learning_data() -> void:
	for bucket in ["skills", "strategies", "workshop_steps"]:
		var records: Dictionary = progress.get(bucket, {})
		for key in records:
			records[key] = LEARNING_ENGINE.migrate(records[key])
		progress[bucket] = records

func open_parent() -> void:
	screen = "parent"
	var panel := Control.new()
	panel.set_script(PARENT_UI)
	add_child(panel)
	panel.call("setup", self)

func show_hangar() -> void:
	HANGAR.show(self)

func buy_hangar(id: String) -> void:
	if not save_writable:
		HANGAR.show(self, L10N.text("Restore your profile before purchasing."))
		return
	REWARD_MANAGER.migrate(progress)
	if progress.rewards.owned.has(id):
		equip_hangar(id)
		return
	var before := progress.duplicate(true)
	if not REWARD_MANAGER.purchase(progress, id):
		show_game_notice(L10N.text("Not enough crystals"), L10N.text("Need %d more crystals. Complete missions to earn them.") % maxi(0, int(REWARD_MANAGER.CATALOG.get(id, {}).get("cost", 0)) - int(progress.coins)))
		return
	if str(REWARD_MANAGER.CATALOG[id].get("kind", "")) in ["ship", "weapon"]:
		REWARD_MANAGER.equip(progress, id)
	if not PARENT_DATA.write_save(SAVE_PATH, progress):
		progress = before
		HANGAR.show(self, L10N.text("Could not save purchase. Crystals returned."))
		return
	HANGAR.show(self, "Unlocked!" )

func equip_hangar(id: String) -> void:
	if not save_writable: return
	var before := progress.duplicate(true)
	if REWARD_MANAGER.equip(progress, id):
		if not PARENT_DATA.write_save(SAVE_PATH, progress):
			progress = before
			HANGAR.show(self, L10N.text("Could not save selection"))
			return
	HANGAR.show(self)

func use_repair() -> void:
	if screen != "battle" or finished or pending_defeat or repair_used or not progress.rewards.owned.has("repair"): return
	repair_used = true
	var repair_button := find_child("BattleRepair", true, false)
	if repair_button != null: repair_button.disabled = true
	shield = mini(100, shield + 15)
	feedback.text = L10N.text("Repair pulse used (+15 shield)")
	update_hud()

func show_game_notice(title: String, message: String) -> void:
	var existing := get_node_or_null("GameNotice")
	if existing != null:
		remove_child(existing)
		existing.queue_free()
	var overlay := ColorRect.new()
	overlay.name = "GameNotice"
	overlay.color = Color(0.01, 0.025, 0.08, 0.82)
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 220)
	panel.add_theme_stylebox_override("panel", space_panel(Color("0b1935"), Color("ffbf59"), 18, 0.35))
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	panel.add_child(content)
	content.add_child(make_label(title, 30, Color("ffd16d")))
	var description := make_label(message, 22, Color("d0e7ff"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)
	content.add_child(make_button(L10N.text("GOT IT"), overlay.queue_free, Color("2865ad"), 220, 54, 22))
