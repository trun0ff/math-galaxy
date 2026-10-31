extends ProgressBar

func _ready() -> void:
	show_percentage = false
	for state in ["background", "fill"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	value_changed.connect(func(_value: float): queue_redraw())
	resized.connect(queue_redraw)

func contour(inset: float) -> PackedVector2Array:
	var w := size.x - inset
	var h := size.y - inset
	var c := maxf(2.0, h * 0.38)
	return PackedVector2Array([Vector2(inset+c,inset),Vector2(w-c,inset),Vector2(w,h*0.5),Vector2(w-c,h),Vector2(inset+c,h),Vector2(inset,h*0.5)])

func _draw() -> void:
	if size.x < 20: return
	var outer := contour(1)
	draw_colored_polygon(outer, Color("071329"))
	draw_polyline(outer + PackedVector2Array([outer[0]]), Color("a9c5eb"), 2, true)
	var inner := contour(4)
	draw_colored_polygon(inner, Color("173252"))
	var ratio := float(value - min_value) / maxf(1, max_value - min_value)
	if ratio > 0:
		var width := (size.x - 12) * ratio
		var height := size.y - 12
		var c := minf(height * 0.4, width * 0.35)
		var points := PackedVector2Array([Vector2(6+c,6), Vector2(6+width-c,6), Vector2(6+width,6+height/2), Vector2(6+width-c,6+height), Vector2(6+c,6+height), Vector2(6,6+height/2)])
		var color := Color("20d4ff") if ratio > 0.25 else Color("ff527a")
		draw_colored_polygon(points, color)
		draw_line(Vector2(9+c,8),Vector2(4+width-c,8),color.lightened(0.6),2,true)
		for x in range(25, int(width), 22):
			draw_line(Vector2(x+6,8),Vector2(x, size.y-8),Color(0.8,1,1,0.12),2,true)
