extends Button
@export var accent_color: Color = Color("2873bd"):
	set(value):
		accent_color = value
		queue_redraw()

func _ready() -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	resized.connect(queue_redraw)

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 30 or h < 20:
		return
	var cut: float = minf(18.0, minf(w, h) * 0.20)
	var points := PackedVector2Array([Vector2(cut,1), Vector2(w-cut,1), Vector2(w-1,cut), Vector2(w-1,h-cut), Vector2(w-cut,h-1), Vector2(cut,h-1), Vector2(1,h-cut), Vector2(1,cut)])
	var accent: Color = accent_color.lightened(0.50)
	var hover: bool = is_hovered() and not disabled
	var down: bool = button_pressed
	var body: Color = accent_color.darkened(0.035 if hover else 0.14)
	if down:
		body = body.lightened(0.12)
	if disabled:
		body = Color("243045")
		hover = false
	draw_colored_polygon(points, body)
	draw_colored_polygon(
		points,
		Color(accent.r, accent.g, accent.b, 0.08 if not hover else 0.16)
	)
	var outline: Color = accent if not disabled else Color("5b6783")
	draw_polyline(points + PackedVector2Array([points[0]]), outline, 2.7, true)
	var inner := PackedVector2Array([Vector2(cut + 5, 5), Vector2(w-cut-5, 5), Vector2(w-7, cut+1), Vector2(w-7, h-cut-1), Vector2(w-cut-5, h-5), Vector2(cut+5, h-5), Vector2(7, h-cut-1), Vector2(7, cut+1)])
	draw_polyline(inner + PackedVector2Array([inner[0]]), Color(1,1,1,0.10 if not hover else 0.22), 1.3, true)
	var top := PackedVector2Array([Vector2(cut+8,5), Vector2(w-cut-8,5), Vector2(w-cut-14,11), Vector2(cut+14,11)])
	draw_colored_polygon(top, Color(accent.r, accent.g, accent.b, 0.18 if not hover else 0.34))
	draw_line(Vector2(cut+7,h-6), Vector2(w-cut-7,h-6), Color(accent.r, accent.g, accent.b, 0.18), 2.0, true)
	for x in [cut+6, w-cut-6]:
		draw_circle(Vector2(x,h*0.5), 1.9, outline)
