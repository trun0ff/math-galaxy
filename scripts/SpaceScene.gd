extends Control
## Lightweight, asset-free 2D battle VFX. Compatible with Godot 4.x.

var time_passed: float = 0.0
var hit_timer: float = 0.0
var damage_timer: float = 0.0
var laser_timer: float = 0.0
var death_timer: float = 0.0
var enemy_index: int = 0
var enemy_hp: int = 3
var enemy_max_hp: int = 3
var boss_mode: bool = false
var enemy_impact: float = 0.0
var enemy_defeated: float = 0.0
var stars: Array[Vector2] = []
var debris: Array[Dictionary] = []
var shockwaves: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
const PLAYER_TEXTURE = preload("res://assets/battle/player.png")
const ENEMY_TEXTURES = [preload("res://assets/battle/enemy_1.png"), preload("res://assets/battle/enemy_2.png"), preload("res://assets/battle/enemy_3.png")]
const SPACE_TEXTURE = preload("res://assets/battle/nebula.jpg")

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
	enemy_impact = maxf(0.0, enemy_impact - delta)
	enemy_defeated = maxf(0.0, enemy_defeated - delta)
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

func set_boss_mode(active: bool) -> void:
	if boss_mode == active: return
	boss_mode = active
	enemy_max_hp = 6 if active else 3
	enemy_hp = enemy_max_hp
	enemy_defeated = 0.0

func hit_enemy() -> void:
	if death_timer > 0.0:
		return
	laser_timer = 0.36
	hit_timer = 0.6
	enemy_hp -= 1
	enemy_impact = 0.42
	burst(enemy_position(), 22, [Color("fff2a0"), Color("ffb347"), Color("ff5fa2"), Color("b9ebff")])
	if enemy_hp <= 0:
		burst(enemy_position(), 75, [Color("fff2a0"), Color("ffb347"), Color("ff5fa2"), Color("b9ebff")], 235.0)
		enemy_defeated = 0.31
		enemy_index += 1
		enemy_max_hp = 6 if boss_mode else 3
		enemy_hp = enemy_max_hp

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
	# Painted nebula texture with a subtle animated parallax star layer.
	draw_texture_rect(SPACE_TEXTURE, Rect2(Vector2.ZERO, size), false, Color.WHITE)
	for i in range(stars.size()):
		var star: Vector2 = stars[i]
		var layer: int = i % 3
		var x: float = fposmod(star.x * w - time_passed * (9.0 + 17.0 * layer), w)
		var y: float = star.y * h
		var brightness: float = 0.55 + 0.25 * sin(time_passed * (1.0 + float(i % 5)) + i)
		draw_circle(Vector2(x, y), 0.6 + float(layer) * 0.55, Color(0.7, 0.88, 1.0, brightness))
		if i % 19 == 0:
			var twinkle: float = 2.0 + 1.7 * (0.5 + 0.5 * sin(time_passed * 2.0 + i))
			draw_line(Vector2(x - twinkle, y), Vector2(x + twinkle, y), Color(0.5, 0.85, 1.0, brightness * 0.45), 1.0)
			draw_line(Vector2(x, y - twinkle), Vector2(x, y + twinkle), Color(0.5, 0.85, 1.0, brightness * 0.45), 1.0)
	var ship: Vector2 = ship_position()
	var enemy: Vector2 = enemy_position()
	if damage_timer > 0.0 and death_timer == 0.0:
		ship += Vector2(rng.randf_range(-4.0, 4.0), rng.randf_range(-3.0, 3.0))
	if death_timer <= 0.0:
		# Textured ship sprite, animated engine plume and engine core glow.
		var flame: float = 24.0 + sin(time_passed * 22.0) * 8.0
		draw_circle(ship + Vector2(-68, 0), 32.0 + flame * 0.3, Color(0.16, 0.65, 1.0, 0.14))
		draw_colored_polygon(PackedVector2Array([ship + Vector2(-57, -12), ship + Vector2(-102 - flame, 0), ship + Vector2(-57, 12)]), Color(0.25, 0.78, 1.0, 0.48))
		draw_colored_polygon(PackedVector2Array([ship + Vector2(-62, -5), ship + Vector2(-95 - flame * 0.65, 0), ship + Vector2(-62, 5)]), Color("e5ffff"))
		draw_texture_rect(PLAYER_TEXTURE, Rect2(ship - Vector2(93, 93), Vector2(186, 186)), false)
	if enemy_defeated <= 0.0:
		var enemy_scale: float = (1.35 if boss_mode else 1.0) * (1.0 + sin(time_passed * 3.0) * 0.025)
		var enemy_size := Vector2(125.0, 125.0) * enemy_scale
		var shake := Vector2(sin(time_passed * 76.0) * enemy_impact * 13.0, cos(time_passed * 64.0) * enemy_impact * 9.0)
		draw_texture_rect(ENEMY_TEXTURES[enemy_index % 3], Rect2(enemy + shake - enemy_size * 0.5, enemy_size), false)
		# Damage persists on the same enemy until its HP reaches zero.
		var damage_fraction: float = 1.0 - float(enemy_hp) / float(enemy_max_hp)
		if damage_fraction > 0.0:
			for n in range(1 + int(damage_fraction * 4.0)):
				var origin := enemy + Vector2(-24.0 + n * 11.0, -23.0 + n % 2 * 13.0)
				draw_polyline(PackedVector2Array([origin, origin + Vector2(7, 11), origin + Vector2(1, 20)]), Color(0.11, 0.05, 0.22, 0.85), 2.4)
			if damage_fraction > 0.5:
				for n in range(3):
					var spark := enemy + Vector2(22.0 + n * 5.0, -24.0 + sin(time_passed * 9.0 + n) * 8.0)
					draw_circle(spark, 2.0 + sin(time_passed * 12.0 + n), Color("ffba69"))
		if enemy_impact > 0.0:
			draw_circle(enemy, 49.0 * enemy_scale, Color(1.0, 0.66, 0.77, enemy_impact * 0.6))
		# Persistent HP bar for normal enemies and tougher bosses.
		var bar_width: float = 126.0 if boss_mode else 90.0
		var bar_rect := Rect2(enemy + Vector2(-bar_width * 0.5, 66.0 * enemy_scale), Vector2(bar_width, 8))
		draw_rect(bar_rect, Color("1a2244"), true)
		draw_rect(Rect2(bar_rect.position, Vector2(bar_width * float(enemy_hp) / float(enemy_max_hp), 8)), Color("ff526d") if enemy_hp <= 1 else Color("67e9da"), true)
		draw_rect(bar_rect, Color("b7dcff"), false, 1.0)
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
