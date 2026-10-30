extends Control

var t: float = 0.0
var flash: float = 0.0
var damaged: float = 0.0
var shot: float = 0.0
var enemy_index: int = 0
var stars: Array[Vector2] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(70):
		stars.append(Vector2(randf(), randf()))

func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 2.2)
	damaged = maxf(0.0, damaged - delta * 2.2)
	shot = maxf(0.0, shot - delta * 2.0)
	queue_redraw()

func hit_enemy() -> void:
	flash = 1.0
	shot = 1.0
	enemy_index += 1

func hit_ship() -> void:
	damaged = 1.0

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 20.0 or h < 20.0:
		return
	# Parallax stars
	for i in range(stars.size()):
		var s: Vector2 = stars[i]
		var x: float = fposmod(s.x * w - t * (12.0 + float(i % 4) * 12.0), w)
		var y: float = s.y * h
		draw_circle(Vector2(x, y), 0.9 + float(i % 3) * 0.5, Color(0.7, 0.83, 1.0, 0.5))
	var sy: float = h * 0.51 + sin(t * 3.0) * 6.0
	var ship: Vector2 = Vector2(w * 0.22, sy)
	var enemy: Vector2 = Vector2(w * 0.78, h * 0.51 + sin(t * 2.0) * 8.0)
	# Ship thruster and body
	draw_colored_polygon(PackedVector2Array([ship + Vector2(-55, -9), ship + Vector2(-92 - randf() * 15, 0), ship + Vector2(-55, 9)]), Color(1.0, 0.58 + 0.2 * sin(t * 12.0), 0.16))
	draw_colored_polygon(PackedVector2Array([ship + Vector2(-60, 0), ship + Vector2(12, -24), ship + Vector2(56, 0), ship + Vector2(12, 24)]), Color("58c9ff"))
	draw_colored_polygon(PackedVector2Array([ship + Vector2(-25, -9), ship + Vector2(-55, -45), ship + Vector2(10, -16)]), Color("2467cb"))
	draw_colored_polygon(PackedVector2Array([ship + Vector2(-25, 9), ship + Vector2(-55, 45), ship + Vector2(10, 16)]), Color("2467cb"))
	draw_circle(ship + Vector2(12, 0), 13, Color("14295a"))
	draw_arc(ship + Vector2(12, 0), 13, 0, TAU, 24, Color("bdf9ff"), 3.0)
	# Enemy
	var ec: Color = [Color("aa5cff"), Color("ff736c"), Color("74df9c")][enemy_index % 3]
	draw_circle(enemy, 42, ec)
	draw_circle(enemy + Vector2(-17, -9), 10, Color.WHITE)
	draw_circle(enemy + Vector2(17, -9), 10, Color.WHITE)
	draw_circle(enemy + Vector2(-15, -7), 5, Color("291c55"))
	draw_circle(enemy + Vector2(19, -7), 5, Color("291c55"))
	draw_arc(enemy + Vector2(0, 8), 16, 0.2, PI - 0.2, 20, Color("291c55"), 3.0)
	draw_line(enemy + Vector2(-30, -27), enemy + Vector2(-43, -54), ec, 8.0)
	draw_line(enemy + Vector2(30, -27), enemy + Vector2(43, -54), ec, 8.0)
	if shot > 0.0:
		draw_line(ship + Vector2(55, 0), enemy, Color(0.6, 0.95, 1.0, shot), 11.0 * shot)
	if flash > 0.0:
		draw_arc(enemy, 50 + 50 * (1.0 - flash), 0, TAU, 64, Color(1.0, 0.86, 0.3, flash), 8.0 * flash)
	if damaged > 0.0:
		draw_arc(ship, 65, 0, TAU, 48, Color(1.0, 0.2, 0.26, damaged), 10.0)
