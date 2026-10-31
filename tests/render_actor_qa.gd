extends SceneTree
## GPU regression: idle motion must not alter pixels outside authored parts.
## Run without --headless, using --rendering-method gl_compatibility.
const F = preload("res://scripts/FleetBalance.gd")
const B = preload("res://scripts/SpaceScene.gd")
var actors: Array[Dictionary] = []
var viewport: SubViewport
const DEST = "res://.test-user/animation-qa/"

func _initialize() -> void: call_deferred("run")

func add_actor(texture: Texture2D, material: ShaderMaterial, regions: Array, title: String) -> void:
	var index := actors.size()
	var cell := Vector2((index % 5) * 280, int(index / 5) * 220)
	var actor := TextureRect.new()
	actor.texture = texture
	actor.material = material
	actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	actor.size = Vector2(240, 240.0 * texture.get_height() / texture.get_width())
	if actor.size.y > 180: actor.size *= 180.0 / actor.size.y
	actor.position = cell + Vector2(140, 95) - actor.size * 0.5
	viewport.add_child(actor)
	var label := Label.new()
	label.text = title
	label.position = cell + Vector2(12, 193)
	viewport.add_child(label)
	actors.append({"node": actor, "regions": regions, "ship": index < 13, "label": label})

func snapshot(clock: float, filename: String) -> Image:
	for entry in actors:
		entry.node.material.set_shader_parameter("clock", clock)
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	assert(image.save_png(DEST + filename) == OK)
	return image

func in_region(uv: Vector2, region: Vector4, ship: bool, margin: float = 0.02) -> bool:
	if ship:
		return uv.x >= region.x - margin and uv.x <= region.z + margin and uv.y >= region.y - margin and uv.y <= region.w + margin
	return ((uv - Vector2(region.x, region.y)) / (Vector2(region.z, region.w) + Vector2.ONE * margin)).length() < 1.0

func run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1400, 1320)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background := ColorRect.new()
	background.color = Color("07122d")
	background.size = Vector2(viewport.size)
	viewport.add_child(background)
	for index in range(F.SHIP_IDS.size()):
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/shaders/ship_engine.gdshader")
		material.set_shader_parameter("engine_color", Color(F.SHIP_TINTS[index]))
		F.configure_engine(material, index)
		add_actor(F.ship_texture(F.SHIP_IDS[index]), material, F.ENGINE_REGIONS[index], F.SHIP_NAMES[index])
	for species in range(F.MONSTER_NAMES.size()):
		var material := ShaderMaterial.new()
		material.shader = preload("res://assets/shaders/monster_motion.gdshader")
		material.set_shader_parameter("species", species)
		material.set_shader_parameter("motion_kind", B.MONSTER_MOTION[species])
		B.RIG.configure(material, species)
		material.set_shader_parameter("jaw", 0.25)
		add_actor(F.monster_texture(species), material, B.RIG.regions_for(species), F.MONSTER_NAMES[species])
	var first := await snapshot(0.2, "idle-a.png")
	var second := await snapshot(0.47, "idle-b.png")
	for entry in actors:
		var actor: TextureRect = entry.node
		var protected_changes := 0
		var animated_pixels := 0
		for y in range(2, int(actor.size.y) - 2):
			for x in range(2, int(actor.size.x) - 2):
				var point := Vector2i(actor.position + Vector2(x, y))
				if first.get_pixelv(point).is_equal_approx(second.get_pixelv(point)): continue
				var uv := (Vector2(point) + Vector2.ONE * 0.5 - actor.position) / actor.size
				var allowed := false
				for region in entry.regions:
					if in_region(uv, region, entry.ship): allowed = true
				if allowed: animated_pixels += 1
				else: protected_changes += 1
		print("%s: animated=%d protected_changes=%d" % [actor.texture.resource_path.get_file(), animated_pixels, protected_changes])
		assert(animated_pixels > 0 and protected_changes == 0)
	for entry in actors:
		if not entry.ship:
			entry.node.material.set_shader_parameter("attack_charge", 0.8)
			entry.node.material.set_shader_parameter("attack_recoil", 0.7)
			entry.node.material.set_shader_parameter("jaw", 0.8)
	await snapshot(0.47, "attack.png")
	for entry in actors:
		if not entry.ship:
			entry.node.material.set_shader_parameter("impact_flash", 0.7)
			entry.node.material.set_shader_parameter("damage_fraction", 0.6)
	await snapshot(0.47, "damage.png")
	# Export an actual four-second loop, not a mock animation of the screenshot.
	DirAccess.make_dir_recursive_absolute(DEST + "frames")
	viewport.size = Vector2i(1400, 660)
	for index in range(actors.size()):
		var entry: Dictionary = actors[index]
		if entry.ship:
			entry.node.hide()
			entry.label.hide()
			continue
		var cell := index - 13
		var offset := Vector2((cell % 5 - index % 5) * 280, (int(cell / 5) - int(index / 5)) * 220)
		entry.node.position += offset
		entry.label.position += offset
		entry.node.material.set_shader_parameter("damage_fraction", 0.0)
		entry.node.material.set_shader_parameter("impact_flash", 0.0)
	for frame in range(40):
		var clock := frame / 10.0
		for index in range(13, actors.size()):
			var material: ShaderMaterial = actors[index].node.material
			var charge := sin((clock - 2.2) / 0.4 * PI) if clock > 2.2 and clock < 2.6 else 0.0
			material.set_shader_parameter("jaw", 0.25 + 0.18 * sin(clock * 2.5 + index) + charge * 0.6)
			material.set_shader_parameter("attack_charge", charge)
			material.set_shader_parameter("attack_recoil", charge)
		await snapshot(clock, "frames/frame_%02d.png" % frame)
	# Capture the real location menu too: only picture nodes have blur materials.
	var menu_view := SubViewport.new()
	menu_view.size = Vector2i(1280, 720)
	menu_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(menu_view)
	var host := preload("res://tests/test_location_victory.gd").TestMain.new()
	menu_view.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.progress = preload("res://scripts/SaveManager.gd").migrate({"schema_version": 14, "skills": {}, "completed_levels": {"1:0": true}})
	for language in ["en", "uk"]:
		preload("res://scripts/Localization.gd").apply_language(language)
		host.show_levels()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		assert(menu_view.get_texture().get_image().save_png(DEST + "locations-" + language + ".png") == OK)
	host.free()
	print("GPU localized actor animation tests passed")
	quit()
