extends Button
@export var accent_color: Color = Color("2873bd"):
	set(value):
		accent_color = value
		queue_redraw()

func _ready() -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for event in [mouse_entered, mouse_exited, button_down, button_up, resized, focus_entered, focus_exited]:
		event.connect(queue_redraw)

func frame(inset: float) -> PackedVector2Array:
	var w := size.x - inset
	var h := size.y - inset
	var c := minf(18.0, size.y * 0.24)
	return PackedVector2Array([Vector2(inset+c,inset), Vector2(w-c,inset), Vector2(w,inset+c), Vector2(w,h-c), Vector2(w-c,h), Vector2(inset+c,h), Vector2(inset,h-c), Vector2(inset,inset+c)])

func _draw() -> void:
	if size.x < 30 or size.y < 20: return
	var active := (is_hovered() or has_focus()) and not disabled
	var light := accent_color.lightened(0.4) if not disabled else Color("65748e")
	var edge := frame(3)
	var closed := edge + PackedVector2Array([edge[0]])
	# Layered luminous rim, gunmetal chassis, and inset glass.
	draw_polyline(closed, Color(light, 0.09 if not active else 0.22), 11, true)
	draw_colored_polygon(frame(1), Color("060f23"))
	draw_polyline(frame(1) + PackedVector2Array([frame(1)[0]]), Color("7687ab"), 1.5, true)
	draw_colored_polygon(edge, accent_color.darkened(0.68))
	draw_polyline(closed, light, 2.4, true)
	var glass := frame(7)
	var top_color := accent_color.darkened(0.23 if active else 0.46)
	var bottom_color := accent_color.darkened(0.62 if button_pressed else 0.82)
	if disabled:
		top_color = Color("273449")
		bottom_color = Color("121b2c")
	var colors := PackedColorArray()
	for point in glass:
		colors.append(top_color.lerp(bottom_color, point.y / size.y))
	draw_polygon(glass, colors)
	draw_polyline(glass + PackedVector2Array([glass[0]]), Color(light, 0.55), 1.0, true)
	var c := minf(18.0, size.y * 0.24)
	for x in [8.0, size.x - 8.0]:
		draw_line(Vector2(x,c+2), Vector2(x,size.y-c-2), Color(light, 0.2), 8, true)
		draw_line(Vector2(x,c+2), Vector2(x,size.y-c-2), light, 2.5, true)
	draw_line(Vector2(c+8,9), Vector2(size.x-c-8,9), Color(light, 0.85), 2, true)
	draw_line(Vector2(c+12,size.y-9), Vector2(size.x-c-12,size.y-9), Color(light, 0.35), 1.2, true)
