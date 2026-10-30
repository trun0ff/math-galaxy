extends Control
## Lightweight, asset-free 2D battle VFX. Compatible with Godot 4.x.

var time_passed: float = 0.0
var hit_timer: float = 0.0
var damage_timer: float = 0.0
var laser_timer: float = 0.0
var death_timer: float = 0.0
var enemy_index: int = 0
var stars: Array[Vector2] = []
var debris: Array[Dictionary] = []
var shockwaves: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	for i in range(115):
		stars.append(Vector2(rng.randf(), rng.randf()))

func _process(delta: float) -> void:
	time_passed += delta
	hit_timer = maxf(0.0, hit_timer - delta)
	damage_timer = maxf(0.0, damage_timer - delta)
	laser_timer = maxf(0.0, laser_timer - delta)
	death_timer = maxf(0.0, death_timer - delta)
	for i in range(debris.size() - 1, -1, -1):
		var p: Dictionary = debris[i]
		p["life"] = float(p["life"]) - delta
		if p["life"] <= 0.0:
			debris.remove_at(i)
		else:
			p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * delta
			p["vel"] = Vector2(p["vel"]) * 0.98
			debris[i] = p
	for i in range(shockwaves.size() - 1, -1, -1):
		var s: Dictionary = shockwaves[i]
		s["age"] = float(s["age"]) + delta
		if s["age"] > 0.65:
			shockwaves.remove_at(i)
		else:
			shockwaves[i] = s
	queue_redraw()

func ship_position() -> Vector2:
	return Vector2(size.x * 0.22, size.y * 0.51 + sin(time_passed * 2.6) * 5.0)

func enemy_position() -> Vector2:
	return Vector2(size.x * 0.78, size.y * 0.51 + sin(time_passed * 2.1) * 8.0)

func burst(at: Vector2, count: int, palette: Array[Color], speed: float = 165.0) -> void:
	for i in range(count):
		var angle: float = rng.randf_range(0.0, TAU)
		var velocity := Vector2.RIGHT.rotated(angle) * rng.randf_range(speed * 0.3, speed)
		debris.append({"pos": at, "vel": velocity, "life": rng.randf_range(0.25, 0.82), "max_life": 0.82, "radius": rng.randf_range(1.5, 5.5), "color": palette[i % palette.size()]})
	shockwaves.append({"pos": at, "age": 0.0})

func hit_enemy() -> void:
	if death_timer > 0.0:
		return
	laser_timer = 0.36
	hit_timer = 0.6
	burst(enemy_position(), 38, [Color("fff2a0"), Color("ffb347"), Color("ff5fa2"), Color("b9ebff")])
	enemy_index += 1

func hit_ship() -> void:
	if death_timer > 0.0:
		return
	damage_timer = 0.6
	burst(ship_position(), 14, [Color("ff5579"), Color("ffa152"), Color("b2f0ff")], 100.0)

func destroy_ship() -> void:
	death_timer = 1.65
	damage_timer = 1.65
	burst(ship_position(), 110, [Color("ffdf70"), Color("ff8146"), Color("ff315e"), Color("92e7ff")], 285.0)

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 50.0 or h < 50.0:
		return
	# Several softly glowing nebula layers and parallax starfields.
	draw_rect(Rect2(Vector2.ZERO, size), Color("08132b"))
	for i in range(4):
		var center := Vector2(w * (0.18 + i * 0.23), h * (0.22 + (i % 2) * 0.48))
		var tint: Color = [Color("273d7e"), Color("362c70"), Color("174f65"), Color("502954")][i]
		for j in range(7, 0, -1):
			var alpha: float = 0.012 + (8.0 - j) * 0.003
			draw_circle(center, float(j) * 28.0, Color(tint.r, tint.g, tint.b, alpha))
	for i in range(stars.size()):
		var star: Vector2 = stars[i]
		var layer: int = i % 3
		var x: float = fposmod(star.x * w - time_passed * (9.0 + 17.0 * layer), w)
		var y: float = star.y * h
		var brightness: float = 0.55 + 0.25 * sin(time_passed * (1.0 + float(i % 5)) + i)
		draw_circle(Vector2(x, y), 0.6 + float(layer) * 0.55, Color(0.7, 0.88, 1.0, brightness))
	var ship: Vector2 = ship_position()
	var enemy: Vector2 = enemy_position()
	if damage_timer > 0.0 and death_timer == 0.0:
		ship += Vector2(rng.randf_range(-4.0, 4.0), rng.randf_range(-3.0, 3.0))
	if death_timer <= 0.0:
		# Engine bloom and ship hull.
		var flame: float = 20.0 + sin(time_passed * 23.0) * 7.0
		draw_colored_polygon(PackedVector2Array([ship + Vector2(-54, -9), ship + Vector2(-84 - flame, 0), ship + Vector2(-54, 9)]), Color("ffae4f"))
		draw_colored_polygon(PackedVector2Array([ship + Vector2(-50, -4), ship + Vector2(-70 - flame * 0.7, 0), ship + Vector2(-50, 4)]), Color("d9faff"))
		draw_colored_polygon(PackedVector2Array([ship + Vector2(-62, 0), ship + Vector2(8, -25), ship + Vector2(60, 0), ship + Vector2(8, 25)]), Color("65d8ff"))
		draw_colored_polygon(PackedVector2Array([ship + Vector2(-28, -9), ship + Vector2(-56, -44), ship + Vector2(9, -17)]), Color("2865bd"))
		draw_colored_polygon(PackedVector2Array([ship + Vector2(-28, 9), ship + Vector2(-56, 44), ship + Vector2(9, 17)]), Color("2865bd"))
		draw_circle(ship + Vector2(12, 0), 13, Color("10275e"))
		draw_arc(ship + Vector2(12, 0), 13, 0, TAU, 32, Color("d3ffff"), 3.0)
	if hit_timer <= 0.35:
		var color: Color = [Color("ae6fff"), Color("ff7777"), Color("6addad")][enemy_index % 3]
		var enemy_scale: float = 1.0 + sin(time_passed * 3.0) * 0.025
		draw_circle(enemy, 46.0 * enemy_scale, Color(color.r, color.g, color.b, 0.12))
		draw_circle(enemy, 38.0 * enemy_scale, color)
		draw_line(enemy + Vector2(-24, -27), enemy + Vector2(-41, -51), color, 7.0)
		draw_line(enemy + Vector2(24, -27), enemy + Vector2(41, -51), color, 7.0)
		for offset in [-15.0, 15.0]:
			draw_circle(enemy + Vector2(offset, -8), 9.0, Color.WHITE)
			draw_circle(enemy + Vector2(offset + 2.0, -8), 4.5, Color("1a1640"))
		draw_arc(enemy + Vector2(0, 6), 15, 0.2, PI - 0.2, 22, Color("2a1d57"), 3.0)
	if laser_timer > 0.0:
		var opacity: float = minf(1.0, laser_timer * 4.0)
		draw_line(ship + Vector2(58, 0), enemy, Color(0.1, 0.7, 1.0, 0.25 * opacity), 23.0)
		draw_line(ship + Vector2(58, 0), enemy, Color(0.65, 0.95, 1.0, opacity), 8.0)
		draw_line(ship + Vector2(58, 0), enemy, Color(1.0, 1.0, 1.0, opacity), 3.0)
	if damage_timer > 0.0:
		var amount: float = minf(1.0, damage_timer * 2.2)
		draw_arc(ship, 68.0 + (1.0 - amount) * 15.0, 0.0, TAU, 64, Color(1.0, 0.22, 0.33, amount), 8.0)
	for wave in shockwaves:
		var age: float = wave["age"]
		var fade: float = 1.0 - age / 0.65
		draw_arc(wave["pos"], 8.0 + 115.0 * age, 0.0, TAU, 48, Color(1.0, 0.84, 0.48, 0.75 * fade), 4.0 * fade + 0.5)
	for p in debris:
		var opacity: float = clampf(float(p["life"]) / float(p["max_life"]), 0.0, 1.0)
		var c: Color = p["color"]
		draw_circle(p["pos"], float(p["radius"]) * opacity, Color(c.r, c.g, c.b, opacity))
