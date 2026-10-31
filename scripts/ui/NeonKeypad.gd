extends VBoxContainer
## Reusable neon numeric input. Emits a digit, delete or submit request.
signal key_pressed(key: String)

const FANCY = preload("res://scripts/ui/FancyButton.gd")
const BASE := Color("1689c4")
const EDGE := Color("2c86ff")
const TEXT := Color("eefaff")

@export var key_height: float = 44.0

var display: Label
var current_value := ""

func _ready() -> void:
	add_theme_constant_override("separation", 3)
	var display_shell := PanelContainer.new()
	display_shell.custom_minimum_size = Vector2(0, 44)
	display_shell.add_theme_stylebox_override("panel", _style(Color("0d1d3c"), Color("33b8df"), 12, 1))
	add_child(display_shell)
	display = Label.new()
	display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	display.add_theme_font_size_override("font_size", 31)
	display.add_theme_color_override("font_color", Color("e1faff"))
	display_shell.add_child(display)
	set_value("")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 3)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(grid)
	for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "OK"]:
		var button := Button.new()
		button.set_script(FANCY)
		button.text = ""
		button.custom_minimum_size = Vector2(112, key_height)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 24)
		button.add_theme_color_override("font_color", TEXT)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		var base := BASE
		var accent := EDGE
		if key == "OK":
			base = Color("087e83")
			accent = Color("00f2b2")
		elif key == "⌫":
			base = Color("78375a")
			accent = Color("ff8fa3")
		button.set("accent_color", accent)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pivot_offset = button.custom_minimum_size * 0.5
		button.mouse_entered.connect(_on_hover.bind(button))
		button.pressed.connect(_on_pressed.bind(key, button))
		grid.add_child(button)
		var caption := Label.new()
		caption.text = key
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 28 if key_height >= 60 else 23)
		caption.add_theme_color_override("font_color", TEXT)
		caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(caption)

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
	var tw := button.create_tween()
	tw.tween_property(button, "scale", Vector2(0.93, 0.93), 0.07)
	tw.parallel().tween_property(button, "modulate", Color("a5f4ff"), 0.07)
	tw.tween_property(button, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(button, "modulate", Color.WHITE, 0.16)
	key_pressed.emit(key)

func _on_hover(button: Button) -> void:
	var tw := button.create_tween()
	tw.tween_property(button, "modulate", Color("b7f0ff"), 0.09)
	tw.tween_property(button, "modulate", Color.WHITE, 0.15)

func set_value(value: String) -> void:
	current_value = value
	if display != null:
		display.text = value if not value.is_empty() else "_ _ _"

func flash(correct: bool) -> void:
	if display == null:
		return
	var color := Color("6affb0") if correct else Color("ff6f91")
	var tw := create_tween()
	tw.tween_property(display, "modulate", color, 0.10)
	tw.tween_property(display, "modulate", Color.WHITE, 0.30)

static func key_from_event(event: InputEvent) -> String:
	if not event is InputEventKey or not event.pressed or event.echo: return ""
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER: return "OK"
	if event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE: return "⌫"
	if event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9: return str(event.keycode - KEY_KP_0)
	var value := char(event.unicode) if event.unicode > 0 else OS.get_keycode_string(event.keycode)
	return value if value.length() == 1 and value.is_valid_int() else ""
