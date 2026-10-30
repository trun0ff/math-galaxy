extends VBoxContainer
## Reusable neon numeric input. Emits a digit, delete or submit request.
signal key_pressed(key: String)

const BASE := Color("152950")
const EDGE := Color("4e7cc7")
const TEXT := Color("eefaff")

var display: Label
var current_value := ""

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	var display_shell := PanelContainer.new()
	display_shell.custom_minimum_size = Vector2(0, 36)
	display_shell.add_theme_stylebox_override("panel", _style(Color("0d1d3c"), Color("33b8df"), 12, 1))
	add_child(display_shell)
	display = Label.new()
	display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	display.add_theme_font_size_override("font_size", 26)
	display.add_theme_color_override("font_color", Color("b3f2ff"))
	display_shell.add_child(display)
	set_value("")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 5)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(grid)
	for key in ["7", "8", "9", "4", "5", "6", "1", "2", "3", "⌫", "0", "OK"]:
		var button := Button.new()
		button.text = key
		button.custom_minimum_size = Vector2(104, 36)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_color_override("font_color", TEXT)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		var base := BASE
		var accent := EDGE
		if key == "OK":
			base = Color("087e83")
			accent = Color("48f4d9")
		elif key == "⌫":
			base = Color("78375a")
			accent = Color("ff8fa3")
		button.add_theme_stylebox_override("normal", _style(base, accent, 12, 2))
		button.add_theme_stylebox_override("hover", _style(base.lightened(0.20), accent.lightened(0.2), 12, 2))
		button.add_theme_stylebox_override("pressed", _style(accent.darkened(0.25), Color.WHITE, 12, 2))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pivot_offset = button.custom_minimum_size * 0.5
		button.pressed.connect(_on_pressed.bind(key, button))
		grid.add_child(button)

func _style(fill: Color, edge: Color, radius: int, edge_size: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(edge_size)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(edge.r, edge.g, edge.b, 0.30)
	s.shadow_size = 4
	s.content_margin_left = 5.0
	s.content_margin_right = 5.0
	return s

func _on_pressed(key: String, button: Button) -> void:
	var tw := create_tween()
	tw.tween_property(button, "modulate", Color("a5f4ff"), 0.075)
	tw.tween_property(button, "modulate", Color.WHITE, 0.15)
	key_pressed.emit(key)

func set_value(value: String) -> void:
	current_value = value
	if display != null:
		display.text = "ANSWER   " + (value if not value.is_empty() else "_ _ _")

func flash(correct: bool) -> void:
	if display == null:
		return
	var color := Color("6affb0") if correct else Color("ff6f91")
	var tw := create_tween()
	tw.tween_property(display, "modulate", color, 0.10)
	tw.tween_property(display, "modulate", Color.WHITE, 0.30)
