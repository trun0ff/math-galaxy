extends Control
## Textured fighters, monster variants and layered battle effects.

signal ship_impact
var ship_actor: TextureRect
var monster_actor: TextureRect
var enemy_attack_timer: float = 0.0
var enemy_laser_timer: float = 0.0
var pending_destruction: bool = false
var enemy_shot_color := Color("d54bff")
var attack_origin := Vector2.ZERO
var attack_target := Vector2.ZERO
const ENEMY_COLORS = [Color("da4fff"), Color("ff952b"), Color("32e3ff")]

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
const PLAYER_TEXTURES = [preload("res://assets/battle/fighter_cyan.png"), preload("res://assets/battle/fighter_gold.png"), preload("res://assets/battle/fighter_violet.png")]
const ENEMY_TEXTURES = [preload("res://assets/battle/monster_cyclops.png"), preload("res://assets/battle/monster_mech.png"), preload("res://assets/battle/monster_crystal.png")]
const WORLD_BACKGROUNDS = [preload("res://assets/battle/world_1_background_fade.png"), preload("res://assets/battle/world_2_background_fade.png"), preload("res://assets/battle/world_3_background_fade.png"), preload("res://assets/battle/world_4_background_fade.png"), preload("res://assets/battle/world_5_background_fade.png")]
var damage_labels: Array[Dictionary] = []
var ship_variant: int = 0
var ship_tint := Color.WHITE
var current_world: int = 1

func set_world(idx: int) -> void:
	current_world = clampi(idx, 1, 5)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship_actor = make_actor(preload("res://assets/shaders/ship_engine.gdshader"))
	monster_actor = make_actor(preload("res://assets/shaders/monster_motion.gdshader"))
	rng.randomize()
	for i in range(115):
		stars.append(Vector2(rng.randf(), rng.randf()))

func _process(delta: float) -> void:
	time_passed += delta
	enemy_laser_timer = maxf(0.0, enemy_laser_timer - delta)
	if enemy_attack_timer > 0.0:
		enemy_attack_timer = maxf(0.0, enemy_attack_timer - delta)
		if enemy_attack_timer == 0.0:
			apply_ship_impact()
	update_actors()
	hit_timer = maxf(0.0, hit_timer - delta)
	damage_timer = maxf(0.0, damage_timer - delta)
	laser_timer = maxf(0.0, laser_timer - delta)
	death_timer = maxf(0.0, death_timer - delta)
	enemy_impact = maxf(0.0, enemy_impact - delta)
	enemy_defeated = maxf(0.0, enemy_defeated - delta)
	for i in range(damage_labels.size() - 1, -1, -1):
		damage_labels[i]["age"] += delta
		if damage_labels[i]["age"] > 1.1:
			damage_labels.remove_at(i)
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
	damage_labels.append({"pos": enemy_position() + Vector2(-28, -52), "age": 0.0, "text": "-1", "color": Color("ffe18b")})
	enemy_hp -= 1
	enemy_impact = 0.42
	burst(enemy_position(), 22, [Color("fff2a0"), Color("ffb347"), Color("ff5fa2"), Color("b9ebff")])
	if enemy_hp <= 0:
		burst(enemy_position(), 75, [Color("fff2a0"), Color("ffb347"), Color("ff5fa2"), Color("b9ebff")], 235.0)
		enemy_defeated = 0.31
		enemy_index += 1
		enemy_max_hp = 6 if boss_mode else 3
		enemy_hp = enemy_max_hp

func monster_species() -> int:
	return (enemy_index + current_world - 1) % ENEMY_TEXTURES.size()

func hit_ship() -> void:
	if death_timer > 0.0 or enemy_attack_timer > 0.0: return
	# Charge, fire, travel, then impact. The HUD listens for the arrival signal.
	enemy_attack_timer = 0.36
	enemy_shot_color = ENEMY_COLORS[monster_species()]
	attack_origin = enemy_position() + Vector2(-48, 5)
	attack_target = ship_position() + Vector2(45, 0)

func apply_ship_impact() -> void:
	enemy_laser_timer = 0.12
	damage_timer = 0.6
	damage_labels.append({"pos": ship_position() + Vector2(-20, -58), "age": 0.0, "text": "-20", "color": Color("ff668a")})
	burst(attack_target, 24, [enemy_shot_color, Color("ffffff"), Color("b2f0ff")], 140.0)
	ship_impact.emit()
	if pending_destruction:
		pending_destruction = false
		explode_ship()

func destroy_ship() -> void:
	if enemy_attack_timer > 0.0:
		pending_destruction = true
	else:
		explode_ship()

func explode_ship() -> void:
	death_timer = 1.65
	damage_timer = 1.65
	burst(ship_position(), 110, [Color("ffdf70"), Color("ff8146"), Color("ff315e"), Color("92e7ff")], 285.0)

func make_actor(shader: Shader) -> TextureRect:
	var actor := TextureRect.new()
	actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var material := ShaderMaterial.new()
	material.shader = shader
	actor.material = material
	add_child(actor)
	return actor

func update_actors() -> void:
	if ship_actor == null: return
	var engine_color: Color = [Color("32cfff"), Color("ffba32"), Color("b657ff")][clampi(ship_variant, 0, 2)]
	ship_actor.texture = PLAYER_TEXTURES[clampi(ship_variant, 0, 2)]
	ship_actor.size = Vector2(235, 235 * float(ship_actor.texture.get_height()) / float(ship_actor.texture.get_width()))
	ship_actor.position = ship_position() - ship_actor.size * 0.5
	if damage_timer > 0.0:
		ship_actor.position += Vector2(sin(time_passed * 85) * 3, cos(time_passed * 67) * 2)
	ship_actor.visible = death_timer <= 0.0
	ship_actor.material.set_shader_parameter("clock", time_passed)
	ship_actor.material.set_shader_parameter("engine_color", engine_color)
	var species := monster_species()
	monster_actor.texture = ENEMY_TEXTURES[species]
	var scale_factor := (1.35 if boss_mode else 1.0) * (1.0 + sin(time_passed * 3) * 0.025)
	monster_actor.size = Vector2(155 * float(monster_actor.texture.get_width()) / float(monster_actor.texture.get_height()), 155) * scale_factor
	monster_actor.position = enemy_position() - monster_actor.size * 0.5 + Vector2(sin(time_passed * 76) * enemy_impact * 13, cos(time_passed * 64) * enemy_impact * 9)
	monster_actor.visible = enemy_defeated <= 0.0
	var blink_phase := fposmod(time_passed + species * 0.71, 4.1)
	var blink := maxf(0.0, 1.0 - absf(blink_phase - 3.7) / 0.13)
	var attack_jaw := sin((1.0 - enemy_attack_timer / 0.36) * PI) if enemy_attack_timer > 0 else 0.0
	var jaw := maxf(attack_jaw, enemy_impact * 2.2) + 0.08 * (0.5 + 0.5 * sin(time_passed * 2.5))
	monster_actor.material.set_shader_parameter("species", species)
	monster_actor.material.set_shader_parameter("blink", blink)
	monster_actor.material.set_shader_parameter("jaw", jaw)
	monster_actor.material.set_shader_parameter("skin_color", ENEMY_COLORS[species].darkened(0.65))

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 50.0 or h < 50.0:
		return
	# Painted nebula texture with a subtle animated parallax star layer.
	draw_texture_rect(WORLD_BACKGROUNDS[current_world - 1], Rect2(Vector2.ZERO, size), false, Color.WHITE)
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
		# The painted engine plume belongs to the hull; pulse its light without a second flame.
		var engine_color: Color = [Color("32cfff"), Color("ffba32"), Color("b657ff")][clampi(ship_variant, 0, 2)]
		var pulse := 0.10 + 0.04 * sin(time_passed * 18.0)
		draw_circle(ship + Vector2(-70, 0), 27, Color(engine_color, pulse))
	if enemy_defeated <= 0.0:
		var enemy_scale: float = (1.35 if boss_mode else 1.0) * (1.0 + sin(time_passed * 3.0) * 0.025)
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
			var impact := enemy + Vector2(-42, 0)
			var flash := enemy_impact / 0.42
			for radius in [40.0, 23.0, 10.0]:
				draw_circle(impact, radius * flash, Color(1.0, 0.65 + flash * 0.3, 0.3, flash * 0.25))
			for ray in range(8):
				var direction := Vector2.RIGHT.rotated(float(ray) * TAU / 8.0 + 0.2)
				draw_line(impact + direction * 8, impact + direction * (18 + flash * 45), Color(1, 0.88, 0.56, flash), 2.0, true)
		# Persistent HP bar for normal enemies and tougher bosses.
		var bar_width: float = 126.0 if boss_mode else 90.0
		var bar_rect := Rect2(enemy + Vector2(-bar_width * 0.5, 77.5 * enemy_scale + 5.0), Vector2(bar_width, 8))
		draw_rect(bar_rect, Color("1a2244"), true)
		draw_rect(Rect2(bar_rect.position, Vector2(bar_width * float(enemy_hp) / float(enemy_max_hp), 8)), Color("ff526d") if enemy_hp <= 1 else Color("67e9da"), true)
		draw_rect(bar_rect, Color("b7dcff"), false, 1.0)
	if laser_timer > 0.0:
		var opacity: float = minf(1.0, laser_timer * 4.0)
		draw_line(ship + Vector2(58, 0), enemy, Color(0.1, 0.7, 1.0, 0.25 * opacity), 23.0)
		draw_line(ship + Vector2(58, 0), enemy, Color(0.65, 0.95, 1.0, opacity), 8.0)
		draw_line(ship + Vector2(58, 0), enemy, Color(1.0, 1.0, 1.0, opacity), 3.0)
	if enemy_attack_timer > 0.0 or enemy_laser_timer > 0.0:
		var color := enemy_shot_color
		var charge := clampf((0.36 - enemy_attack_timer) / 0.14, 0, 1)
		draw_circle(attack_origin, 9 + charge * 10, Color(color, 0.18))
		draw_circle(attack_origin, 3 + charge * 5, color.lightened(0.5))
		if enemy_attack_timer <= 0.22:
			var travel := clampf((0.22 - enemy_attack_timer) / 0.22, 0, 1)
			var head := attack_origin.lerp(attack_target, travel)
			var fade := 1.0 if enemy_attack_timer > 0 else enemy_laser_timer / 0.12
			draw_line(attack_origin, head, Color(color, fade * 0.13), 22, true)
			draw_line(attack_origin, head, Color(color, fade), 5, true)
			draw_line(attack_origin, head, Color(1, 1, 1, fade), 1.5, true)
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
		var position: Vector2 = p["pos"]
		var velocity: Vector2 = p["vel"]
		draw_circle(position, float(p["radius"]) * opacity * 3.0, Color(c.r, c.g, c.b, opacity * 0.08))
		draw_line(position - velocity * 0.035, position, Color(c.r, c.g, c.b, opacity), maxf(1.0, float(p["radius"]) * opacity), true)
		draw_circle(position, maxf(0.6, float(p["radius"]) * opacity * 0.4), Color(1, 0.98, 0.9, opacity))
	for label in damage_labels:
		var age: float = label["age"]
		var at: Vector2 = label["pos"] + Vector2(0, -age * 52.0)
		var color: Color = label["color"]
		color.a = minf(1.0, (1.1 - age) * 3.0)
		var font := ThemeDB.fallback_font
		draw_string_outline(font, at, label["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, Color(0.02, 0.03, 0.12, color.a))
		draw_string(font, at, label["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 30, color)
