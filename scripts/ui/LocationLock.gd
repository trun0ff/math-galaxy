extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 26, Color(0.02, 0.04, 0.1, 0.82))
	draw_arc(center + Vector2(0, -7), 10, PI, TAU, 24, Color("eaf4ff"), 4, true)
	draw_style_box(lock_body(), Rect2(center + Vector2(-16, -7), Vector2(32, 25)))
	draw_circle(center + Vector2(0, 3), 3, Color("152340"))
	draw_line(center + Vector2(0, 4), center + Vector2(0, 10), Color("152340"), 3)

func lock_body() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("eaf4ff")
	style.set_corner_radius_all(4)
	return style
