extends PanelContainer
func _ready() -> void:
	var padding := StyleBoxEmpty.new()
	padding.content_margin_left = 14
	padding.content_margin_right = 14
	padding.content_margin_top = 8
	padding.content_margin_bottom = 8
	add_theme_stylebox_override("panel", padding)
	resized.connect(queue_redraw)
func _draw() -> void:
	var w := size.x
	var h := size.y
	var cut := minf(20, h * 0.35)
	var shape := PackedVector2Array([Vector2(cut,1),Vector2(w-cut,1),Vector2(w-1,cut),Vector2(w-1,h-cut),Vector2(w-cut,h-1),Vector2(cut,h-1),Vector2(1,h-cut),Vector2(1,cut)])
	draw_colored_polygon(shape, Color("06152e"))
	draw_polyline(shape + PackedVector2Array([shape[0]]), Color("517295"), 3, true)
	draw_line(Vector2(cut+6,4),Vector2(w-cut-6,4),Color("44d9ff"),2,true)
	draw_line(Vector2(cut+6,h-4),Vector2(w-cut-6,h-4),Color("227eb1"),2,true)
