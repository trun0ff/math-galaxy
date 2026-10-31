extends Control

# Small, exact examples keep the pictures countable, even for large questions.
var places := false

func _ready() -> void:
	custom_minimum_size = Vector2(0, 150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var cell: float = minf(170.0, size.x / 3.0)
	var left: float = (size.x - cell * 3.0) / 2.0
	for group in range(3):
		var origin := Vector2(left + group * cell + 8, 8)
		draw_style_box(_box(), Rect2(origin, Vector2(cell - 16, 132)))
		if places:
			var count: int = [1, 2, 3][group]
			for item in range(count):
				if group == 0:
					for row in range(10):
						for column in range(10):
							draw_rect(Rect2(origin + Vector2(15 + column * 8, 20 + row * 8), Vector2(6, 6)), Color("67e8f9"))
				elif group == 1:
					for row in range(10):
						draw_rect(Rect2(origin + Vector2(25 + item * 24, 20 + row * 8), Vector2(12, 6)), Color("fcd34d"))
				else:
					draw_circle(origin + Vector2(28 + item * 28, 60), 8, Color("c4b5fd"))
		else:
			for item in range(4):
				draw_circle(origin + Vector2(35 + (item % 2) * 38, 42 + int(item / 2) * 40), 11, Color("67e8f9"))

func _box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("142c4c")
	box.set_corner_radius_all(12)
	return box
