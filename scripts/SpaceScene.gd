extends Control
## Textured fighters, monster variants and layered battle effects.

const FLEET = preload("res://scripts/FleetBalance.gd")
# One motion profile for every species, including the original three.
const MONSTER_MOTION = [0, 1, 2, 3, 1, 3, 4, 1, 2, 3, 1, 4, 4]

func monster_pose(species: int) -> Dictionary:
	var charge := smoothstep(0.0, 1.0, clampf((0.36 - enemy_attack_timer) / 0.14, 0, 1)) * smoothstep(0.16, 0.22, enemy_attack_timer) if enemy_attack_timer > 0 else 0.0
	var recoil := sin(clampf((0.22 - enemy_attack_timer) / 0.22, 0, 1) * PI) if enemy_attack_timer > 0 else 0.0
	return {"charge": charge, "recoil": recoil, "kind": MONSTER_MOTION[species]}

const RIG = preload("res://scripts/MonsterRig.gd")
const MONSTER_PARTS = RIG.PARTS

var actor_layout_scale := 1.0
var single_encounter := false
var encounter_species := 0
var attack_damage := 1
var incoming_damage := 20
var equipped_ship := ""
var equipped_weapon := ""
var shot_damage := 1
var ember_clock := 0.0
var encounter_defeated := false

func configure_encounter(ship: String, weapon: String, data: Dictionary) -> void:
	single_encounter = true
	encounter_defeated = false
	equipped_ship = ship
	equipped_weapon = weapon
	ship_variant = FLEET.ship_index(ship)
	attack_damage = FLEET.damage(ship_variant, FLEET.weapon_index(weapon), data)
	incoming_damage = 20 - FLEET.ARMOR[ship_variant]
	var pool: Array = FLEET.monster_pool(int(data.tier))
	encounter_species = int(data.get("monster_species", pool[0]))
	enemy_max_hp = int(data.hp)
	enemy_hp = enemy_max_hp
	display_hp = enemy_hp
	hp_trail = enemy_hp

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

const SHIP_COLORS = [Color("32cfff"), Color("ffba32"), Color("b657ff")]
const WEAPONS = ["laser", "machine_gun", "lightning"]
var weapon_mode := "laser"
var shot_age := 0.0
var shot_duration := 0.5
var shot_arrival := 0.15
var shot_origin := Vector2.ZERO
var shot_target := Vector2.ZERO
var shot_color := Color("32cfff")
var shot_species := 0
var pending_enemy_hit := false
var pending_enemy_kill := false
var shot_hp := 3
var display_hp := 3.0
var hp_trail := 3.0
var retreating := false
var retreat_age := 0.0
var effects: Control

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
const WORLD_BACKGROUNDS = [preload("res://assets/battle/world_1_background_fade.png"), preload("res://assets/battle/world_2_background_fade.png"), preload("res://assets/battle/world_3_background_fade.png"), preload("res://assets/battle/world_4_background_fade.png"), preload("res://assets/battle/world_5_background_fade.png"), preload("res://assets/locations/world_6.png"), preload("res://assets/locations/world_7.png"), preload("res://assets/locations/world_8.png")]
var damage_labels: Array[Dictionary] = []
var ship_variant: int = 0
var ship_tint := Color.WHITE
var current_world: int = 1
var location_texture: Texture2D

func set_location(texture: Texture2D) -> void:
	location_texture = texture
	queue_redraw()

func set_world(idx: int) -> void:
	current_world = clampi(idx, 1, 8)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship_actor = make_actor(preload("res://assets/shaders/ship_engine.gdshader"))
	monster_actor = make_actor(preload("res://assets/shaders/monster_motion.gdshader"))
	effects = Control.new()
	effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(effects)
	effects.draw.connect(func(): draw_foreground(effects))
	rng.randomize()
	for i in range(115):
		stars.append(Vector2(rng.randf(), rng.randf()))

func _process(delta: float) -> void:
	time_passed += delta
	ember_clock += delta
	if single_encounter and enemy_hp > 0 and display_hp < enemy_max_hp * 0.65 and ember_clock > 0.16:
		ember_clock = 0.0
		var at := enemy_position() + Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))
		debris.append({"pos": at, "vel": Vector2(rng.randf_range(-12, 12), -35), "life": 0.7, "max_life": 0.7, "radius": 2.5, "color": Color("ffac57")})
	if retreating: retreat_age += delta
	if laser_timer > 0.0:
		var previous_age := shot_age
		shot_age += delta
		if weapon_mode == "machine_gun":
			for bullet in range(5):
				var arrival := bullet * 0.055 + 0.32
				if previous_age < arrival and shot_age >= arrival:
					burst(shot_target + Vector2(0, (bullet - 2) * 4), 5, [shot_color, Color.WHITE], 100)
		if pending_enemy_hit and shot_age >= shot_arrival:
			apply_enemy_impact()
	hp_trail = move_toward(hp_trail, display_hp, delta * maxf(1.1, enemy_max_hp * 0.8))
	enemy_laser_timer = maxf(0.0, enemy_laser_timer - delta)
	if enemy_attack_timer > 0.0:
		enemy_attack_timer = maxf(0.0, enemy_attack_timer - delta)
		if enemy_attack_timer == 0.0:
			apply_ship_impact()
	hit_timer = maxf(0.0, hit_timer - delta)
	damage_timer = maxf(0.0, damage_timer - delta)
	laser_timer = maxf(0.0, laser_timer - delta)
	death_timer = maxf(0.0, death_timer - delta)
	enemy_impact = maxf(0.0, enemy_impact - delta)
	enemy_defeated = maxf(0.0, enemy_defeated - delta)
	if enemy_defeated == 0 and not pending_enemy_hit and display_hp <= 0:
		display_hp = enemy_hp
		hp_trail = enemy_hp
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
	update_actors()
	queue_redraw()
	if effects != null: effects.queue_redraw()

func ship_position() -> Vector2:
	var retreat_distance := (size.x * 0.22 + 220) * pow(clampf(retreat_age / 1.05, 0, 1), 2.0) if retreating else 0.0
	return Vector2(size.x * 0.22 - retreat_distance, size.y * 0.51 + sin(time_passed * 2.6) * 5.0)

func enemy_position() -> Vector2:
	return Vector2(size.x * 0.78, size.y * 0.51)

func burst(at: Vector2, count: int, palette: Array[Color], speed: float = 165.0) -> void:
	for i in range(count):
		var angle: float = rng.randf_range(0.0, TAU)
		var velocity := Vector2.RIGHT.rotated(angle) * rng.randf_range(speed * 0.3, speed)
		debris.append({"pos": at, "vel": velocity, "life": rng.randf_range(0.25, 0.82), "max_life": 0.82, "radius": rng.randf_range(1.5, 5.5), "color": palette[i % palette.size()]})
	shockwaves.append({"pos": at, "age": 0.0})

func set_boss_mode(active: bool) -> void:
	if boss_mode == active: return
	boss_mode = active
	if single_encounter: return
	enemy_max_hp = 6 if active else 3
	enemy_hp = enemy_max_hp
	enemy_defeated = 0.0
	display_hp = enemy_max_hp
	hp_trail = enemy_max_hp

func hit_enemy() -> void:
	if retreating or (single_encounter and enemy_hp <= 0): return
	if pending_enemy_hit: apply_enemy_impact()
	weapon_mode = WEAPONS[clampi(ship_variant, 0, 2)]
	shot_color = SHIP_COLORS[clampi(ship_variant, 0, 2)]
	if not equipped_weapon.is_empty():
		var wi := FLEET.weapon_index(equipped_weapon)
		weapon_mode = FLEET.MODES[wi]
		shot_color = Color(FLEET.COLORS[wi])
	shot_origin = ship_position() + Vector2(88, 5)
	shot_target = enemy_position() + Vector2(-40, 0)
	shot_species = monster_species()
	shot_age = 0.0
	shot_duration = 0.7 if weapon_mode == "machine_gun" else 0.5
	shot_arrival = 0.54 if weapon_mode == "machine_gun" else 0.15
	laser_timer = shot_duration
	pending_enemy_hit = true
	shot_damage = mini(attack_damage, enemy_hp)
	enemy_hp -= shot_damage
	shot_hp = enemy_hp
	pending_enemy_kill = enemy_hp <= 0
	if pending_enemy_kill and not single_encounter:
		enemy_index += 1
		enemy_max_hp = 6 if boss_mode else 3
		enemy_hp = enemy_max_hp

func apply_enemy_impact() -> void:
	pending_enemy_hit = false
	display_hp = maxf(0, shot_hp)
	hit_timer = 0.65
	enemy_impact = 0.55
	damage_labels.append({"pos": enemy_position() + Vector2(-14, -70), "age": 0.0, "text": "-%d" % shot_damage, "color": shot_color.lightened(0.6), "enemy": true})
	burst(shot_target, 35, [shot_color, Color("fff1be"), Color.WHITE], 200)
	if pending_enemy_kill:
		burst(enemy_position(), 75, [shot_color, Color("ffbf68"), Color.WHITE], 235)
		enemy_defeated = 0.28
		if single_encounter: encounter_defeated = true

func monster_species() -> int:
	if single_encounter: return encounter_species
	return (enemy_index + current_world - 1) % ENEMY_TEXTURES.size()

func visual_species() -> int:
	return shot_species if pending_enemy_hit or enemy_defeated > 0 else monster_species()

func hit_ship() -> void:
	if retreating or death_timer > 0.0 or enemy_attack_timer > 0.0: return
	# Charge, fire, travel, then impact. The HUD listens for the arrival signal.
	enemy_attack_timer = 0.36
	enemy_shot_color = ENEMY_COLORS[monster_species() % ENEMY_COLORS.size()]
	attack_origin = enemy_position() + Vector2(-48, 5)
	attack_target = ship_position() + Vector2(87, 0)

func apply_ship_impact() -> void:
	enemy_laser_timer = 0.12
	damage_timer = 0.6
	damage_labels.append({"pos": ship_position() + Vector2(-20, -58), "age": 0.0, "text": "-%d" % incoming_damage, "color": Color("ff668a")})
	burst(attack_target, 24, [enemy_shot_color, Color("ffffff"), Color("b2f0ff")], 140.0)
	ship_impact.emit()
	if pending_destruction:
		pending_destruction = false
		start_retreat()

func destroy_ship() -> void:
	if enemy_attack_timer > 0.0:
		pending_destruction = true
	else:
		start_retreat()

func start_retreat() -> void:
	retreating = true
	retreat_age = 0.0
	death_timer = 1.65
	# Shield fragments, not a hull explosion: the pilot escapes intact.
	burst(attack_target, 28, [Color("54dcff"), Color("c7faff"), Color("5298ff")], 170)

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
	if not equipped_ship.is_empty():
		engine_color = Color(FLEET.SHIP_TINTS[ship_variant])
	ship_actor.texture = FLEET.ship_texture(equipped_ship) if not equipped_ship.is_empty() else PLAYER_TEXTURES[clampi(ship_variant, 0, 2)]
	ship_actor.size = Vector2(235, 235 * float(ship_actor.texture.get_height()) / float(ship_actor.texture.get_width())) * actor_layout_scale
	ship_actor.position = ship_position() - ship_actor.size * 0.5
	if damage_timer > 0.0:
		ship_actor.position += Vector2(sin(time_passed * 85) * 3, cos(time_passed * 67) * 2)
	ship_actor.visible = not retreating or retreat_age < 1.1
	ship_actor.flip_h = retreating
	ship_actor.material.set_shader_parameter("clock", time_passed)
	ship_actor.material.set_shader_parameter("engine_color", engine_color)
	FLEET.configure_engine(ship_actor.material, FLEET.ship_index(equipped_ship) if not equipped_ship.is_empty() else [0, 2, 1][clampi(ship_variant, 0, 2)])
	var species := visual_species()
	monster_actor.texture = FLEET.monster_texture(species) if single_encounter else ENEMY_TEXTURES[species]
	var pose := monster_pose(species)
	var scale_factor := 1.35 if single_encounter or boss_mode else 1.0
	monster_actor.size = Vector2(155 * float(monster_actor.texture.get_width()) / float(monster_actor.texture.get_height()), 155) * scale_factor * actor_layout_scale
	monster_actor.pivot_offset = monster_actor.size * 0.5
	monster_actor.rotation = 0.0
	monster_actor.position = enemy_position() - monster_actor.size * 0.5
	monster_actor.visible = enemy_defeated <= 0.0 and not encounter_defeated
	var blink_phase := fposmod(time_passed + species * 0.71, 4.1)
	var blink := maxf(0.0, 1.0 - absf(blink_phase - 3.7) / 0.13)
	var attack_jaw := sin((1.0 - enemy_attack_timer / 0.36) * PI) if enemy_attack_timer > 0 else 0.0
	var jaw := maxf(attack_jaw, enemy_impact * 2.2) + 0.25 + 0.18 * sin(time_passed * 2.5 + species)
	monster_actor.material.set_shader_parameter("damage_fraction", 1.0 - display_hp / float(enemy_max_hp))
	monster_actor.material.set_shader_parameter("impact_flash", enemy_impact / 0.55)
	monster_actor.material.set_shader_parameter("clock", time_passed)
	monster_actor.material.set_shader_parameter("impact_color", shot_color)
	monster_actor.material.set_shader_parameter("species", species)
	monster_actor.material.set_shader_parameter("motion_kind", int(pose.kind))
	RIG.configure(monster_actor.material, species)
	monster_actor.material.set_shader_parameter("attack_charge", float(pose.charge))
	monster_actor.material.set_shader_parameter("attack_recoil", float(pose.recoil))
	monster_actor.material.set_shader_parameter("blink", blink)
	monster_actor.material.set_shader_parameter("jaw", jaw)
	monster_actor.material.set_shader_parameter("skin_color", ENEMY_COLORS[species % ENEMY_COLORS.size()].darkened(0.65))

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 50.0 or h < 50.0:
		return
	# Painted nebula texture with a subtle animated parallax star layer.
	var backdrop: Texture2D = location_texture if location_texture != null else WORLD_BACKGROUNDS[current_world - 1]
	var source_size := Vector2(backdrop.get_width(), backdrop.get_height())
	var crop := source_size
	var target_aspect: float = size.x / size.y
	if source_size.x / source_size.y < target_aspect:
		crop.y = source_size.x / target_aspect
	else:
		crop.x = source_size.y * target_aspect
	var origin := Vector2((source_size.x - crop.x) * 0.5, clampf(source_size.y * 0.37 - crop.y * 0.5, 0, source_size.y - crop.y))
	draw_texture_rect_region(backdrop, Rect2(Vector2.ZERO, size), Rect2(origin, crop))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.025, 0.08, 0.22))
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

func draw_foreground(canvas: Control) -> void:
	var ship := ship_position()
	var enemy := enemy_position()
	if enemy_defeated <= 0 and not encounter_defeated:
		var scale_factor := 1.35 if single_encounter or boss_mode else 1.0
		draw_enemy_hp(canvas, Vector2(enemy.x, minf(size.y - 19, enemy.y + 77.5 * scale_factor + 7)))
		if enemy_impact > 0:
			var flash := enemy_impact / 0.55
			for radius in [32.0, 17.0, 7.0]:
				canvas.draw_circle(shot_target, radius * flash, Color(shot_color.lightened(0.5), flash * 0.2))
			for ray in range(10):
				var direction := Vector2.RIGHT.rotated(ray * TAU / 10 + 0.2)
				canvas.draw_line(shot_target + direction * 8, shot_target + direction * (15 + flash * 42), Color(shot_color.lightened(0.65), flash), 2, true)
	if laser_timer > 0:
		draw_player_weapon(canvas)
	if enemy_attack_timer > 0 or enemy_laser_timer > 0:
		var color := enemy_shot_color
		var charge := clampf((0.36 - enemy_attack_timer) / 0.14, 0, 1)
		canvas.draw_circle(attack_origin, 9 + charge * 10, Color(color, 0.18))
		canvas.draw_circle(attack_origin, 3 + charge * 5, color.lightened(0.5))
		if enemy_attack_timer <= 0.22:
			var travel := clampf((0.22 - enemy_attack_timer) / 0.22, 0, 1)
			var head := attack_origin.lerp(attack_target, travel)
			var fade := 1.0 if enemy_attack_timer > 0 else enemy_laser_timer / 0.12
			beam(canvas, attack_origin, head, color, fade, 5)
	if damage_timer > 0 and not retreating:
		draw_shield_impact(canvas, ship)
	for wave in shockwaves:
		var age: float = wave["age"]
		var fade := 1.0 - age / 0.65
		canvas.draw_arc(wave["pos"], 8 + 115 * age, 0, TAU, 48, Color(0.65, 0.89, 1, 0.5 * fade), 3 * fade + 0.5, true)
	for particle in debris:
		var opacity := clampf(float(particle["life"]) / float(particle["max_life"]), 0, 1)
		var color: Color = particle["color"]
		var position: Vector2 = particle["pos"]
		var velocity: Vector2 = particle["vel"]
		canvas.draw_circle(position, float(particle["radius"]) * opacity * 3, Color(color, opacity * 0.08))
		canvas.draw_line(position - velocity * 0.035, position, Color(color, opacity), maxf(1, float(particle["radius"]) * opacity), true)
		canvas.draw_circle(position, maxf(0.6, float(particle["radius"]) * opacity * 0.4), Color(1, 0.98, 0.9, opacity))
	for label in damage_labels:
		var age: float = label["age"]
		var at: Vector2 = label["pos"] + Vector2(0, -age * 35)
		var color: Color = label["color"]
		color.a = minf(1, (1.1 - age) * 3)
		var font := ThemeDB.fallback_font
		var font_size := int(30 + 9 * maxf(0, 1 - age * 6))
		if label.get("enemy", false):
			var plate := PackedVector2Array([at+Vector2(-13,-34),at+Vector2(51,-34),at+Vector2(59,-19),at+Vector2(51,7),at+Vector2(-13,7),at+Vector2(-21,-8)])
			canvas.draw_colored_polygon(plate, Color(0.03,0.06,0.16,color.a*0.85))
			canvas.draw_polyline(plate + PackedVector2Array([plate[0]]), Color(shot_color,color.a*0.8), 1.5,true)
		canvas.draw_string_outline(font,at,label["text"],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,6,Color(0.02,0.03,0.12,color.a))
		canvas.draw_string(font,at,label["text"],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func beam(canvas: Control, origin: Vector2, target: Vector2, color: Color, opacity: float, width: float) -> void:
	canvas.draw_line(origin,target,Color(color,opacity*0.1),width*4,true)
	canvas.draw_line(origin,target,Color(color,opacity*0.28),width*2,true)
	canvas.draw_line(origin,target,Color(color,opacity),width,true)
	canvas.draw_line(origin,target,Color(1,1,1,opacity),maxf(1,width*0.3),true)

func draw_player_weapon(canvas: Control) -> void:
	var fade := clampf(laser_timer / 0.25,0,1)
	if weapon_mode == "machine_gun":
		for bullet in range(5):
			var flight := (shot_age - bullet * 0.055) / 0.32
			if flight < 0 or flight > 1: continue
			var head := shot_origin.lerp(shot_target,flight) + Vector2(0,(bullet-2)*3)
			beam(canvas,head-Vector2(18,0),head,shot_color,1,4)
			canvas.draw_circle(head,3,Color.WHITE)
	elif weapon_mode == "lightning":
		var points := PackedVector2Array([shot_origin])
		for step in range(1,18):
			var position := shot_origin.lerp(shot_target,float(step)/18)
			position.y += sin(step*11.7+floor(time_passed*30)*3.1) * (8 + sin(step*3.2)*6)
			points.append(position)
		points.append(shot_target)
		canvas.draw_polyline(points,Color(shot_color,fade*0.12),17,true)
		canvas.draw_polyline(points,Color(shot_color,fade),4,true)
		canvas.draw_polyline(points,Color(1,1,1,fade),1.4,true)
		for branch in [5,10,14]:
			var at := points[branch]
			canvas.draw_polyline(PackedVector2Array([at,at+Vector2(9,-17),at+Vector2(31,-24)]),Color(shot_color,fade*0.65),1.5,true)
	elif weapon_mode in ["plasma", "gravity", "nova"]:
		var flight := clampf(shot_age / shot_arrival, 0, 1)
		var at := shot_origin.lerp(shot_target, flight)
		var radius := 13.0 if weapon_mode == "plasma" else 20.0
		canvas.draw_circle(at, radius * 1.7, Color(shot_color, fade * 0.15))
		canvas.draw_circle(at, radius, Color(shot_color, fade * 0.75))
		for ring in range(3):
			canvas.draw_arc(at, radius + ring * 5, time_passed * 8 + ring, time_passed * 8 + ring + PI * 1.5, 24, Color(shot_color.lightened(0.5), fade), 2, true)
		canvas.draw_circle(at, 5, Color.WHITE)
		if weapon_mode == "gravity":
			for mote in range(9):
				var angle := mote * TAU / 9 + time_passed * 11
				var offset := Vector2(cos(angle), sin(angle) * 0.5) * (24 + sin(time_passed * 7 + mote) * 9)
				canvas.draw_circle(at + offset, 2, Color(shot_color.lightened(0.7), fade))
		elif weapon_mode == "nova":
			for ray in range(8):
				var direction := Vector2.RIGHT.rotated(ray * TAU / 8 + time_passed)
				canvas.draw_line(at + direction * 9, at + direction * 34, Color(shot_color, fade), 2, true)
	elif weapon_mode == "pulse":
		for side in [-1, 1]:
			var offset := Vector2(0, side * 9)
			beam(canvas, shot_origin + offset, shot_origin.lerp(shot_target, clampf(shot_age / shot_arrival, 0, 1)) + offset, shot_color, fade, 4)
	elif weapon_mode in ["cryo", "solar", "rail"]:
		beam(canvas, shot_origin, shot_target, shot_color, fade, 12 if weapon_mode == "solar" else 3)
		for ring in range(6):
			var at := shot_origin.lerp(shot_target, (ring + 1) / 7.0)
			canvas.draw_arc(at, 6 + ring, time_passed * 9, time_passed * 9 + PI, 12, Color(shot_color, fade), 2, true)
	else:
		var progress := clampf(shot_age/shot_arrival,0,1)
		beam(canvas,shot_origin,shot_origin.lerp(shot_target,progress),shot_color,fade,6)
	canvas.draw_circle(shot_origin,11,Color(shot_color,fade*0.17))
	canvas.draw_circle(shot_origin,4,Color(shot_color.lightened(0.7),fade))

func draw_enemy_hp(canvas: Control, at: Vector2) -> void:
	var width := 140.0 if boss_mode else 114.0
	var height := 16.0
	var left := at - Vector2(width/2,0)
	var shape := PackedVector2Array([left+Vector2(7,0),left+Vector2(width-7,0),left+Vector2(width,8),left+Vector2(width-7,16),left+Vector2(7,16),left+Vector2(0,8)])
	var color: Color = ENEMY_COLORS[visual_species() % ENEMY_COLORS.size()]
	canvas.draw_colored_polygon(shape,Color("071025"))
	canvas.draw_polyline(shape+PackedVector2Array([shape[0]]),color.lightened(0.4),1.5,true)
	var trail_width := (width-16)*hp_trail/float(enemy_max_hp)
	canvas.draw_rect(Rect2(left+Vector2(8,4),Vector2(trail_width,8)),Color("ffce83"))
	for segment in range(10):
		var segment_width := (width-16)/10.0
		var segment_color := color if float(segment) / 10.0 < display_hp / enemy_max_hp else Color("1b2844")
		var rect := Rect2(left+Vector2(8+segment*segment_width,4),Vector2(segment_width-3,8))
		canvas.draw_rect(rect,segment_color)
		if float(segment) / 10.0 < display_hp / enemy_max_hp: canvas.draw_line(rect.position,rect.position+Vector2(rect.size.x,0),segment_color.lightened(0.6),1,true)
	if hp_trail > display_hp:
		canvas.draw_rect(Rect2(left+Vector2(8+(width-16)*display_hp/float(enemy_max_hp),4),Vector2((width-16)*(hp_trail-display_hp)/float(enemy_max_hp),8)),Color(1,0.7,0.35,0.7))
	var font := ThemeDB.fallback_font
	if single_encounter:
		var title: String = preload("res://scripts/Localization.gd").text(FLEET.MONSTER_NAMES[visual_species()])
		var title_at := at + Vector2(-font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x / 2, -7)
		canvas.draw_string_outline(font, title_at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color("071025"))
		canvas.draw_string(font, title_at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color.lightened(0.6))
	var text := "%d / %d" % [int(display_hp),enemy_max_hp]
	var text_at := at + Vector2(-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x/2,12)
	canvas.draw_string_outline(font,text_at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,3,Color("071025"))
	canvas.draw_string(font,text_at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)

func draw_shield_impact(canvas: Control, at: Vector2) -> void:
	var opacity := clampf(damage_timer/0.6,0,1)
	var radius := 92.0 + (1-opacity)*8
	var center := at + Vector2(0,3)
	# Curved shield facing the incoming projectile, with fine energized bands.
	for band in [0,1,2]:
		canvas.draw_arc(center,radius+band*3,-1.12,1.12,48,Color(0.19,0.75,1,opacity*(0.12 if band != 1 else 0.85)),8 if band == 1 else 3,true)
	canvas.draw_arc(center,radius,-0.9,0.9,40,Color(0.75,0.97,1,opacity),1.5,true)
	for cell in range(7):
		var angle := -0.8+cell*0.27
		var point := center+Vector2.RIGHT.rotated(angle)*(radius-7)
		var hexagon := PackedVector2Array()
		for vertex in range(7): hexagon.append(point+Vector2.RIGHT.rotated(vertex*TAU/6)*6)
		canvas.draw_polyline(hexagon,Color(0.36,0.87,1,opacity*0.5),1,true)
	canvas.draw_circle(center+Vector2(radius,0),12,Color(0.5,0.9,1,opacity*0.2))
