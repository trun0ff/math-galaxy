extends SceneTree
const BATTLE = preload("res://scripts/SpaceScene.gd")
const FLEET = preload("res://scripts/FleetBalance.gd")
const PREVIEW = preload("res://scripts/ui/EnginePreview.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var battle := BATTLE.new()
	root.add_child(battle)
	battle.size = Vector2(1100, 220)
	battle.set_process(false)
	assert(battle.MONSTER_MOTION.size() == FLEET.MONSTER_NAMES.size())
	for ship in FLEET.SHIP_IDS:
		battle.configure_encounter(ship, "laser", FLEET.encounter(5, 7, 12))
		battle.update_actors()
		var position: Vector2 = battle.ship_actor.position
		var clock: float = battle.ship_actor.material.get_shader_parameter("clock")
		battle._process(0.13)
		assert(battle.ship_actor.texture == FLEET.ship_texture(ship))
		assert(battle.ship_actor.material.get_shader_parameter("clock") > clock)
		assert(not battle.ship_actor.position.is_equal_approx(position))
		# The hangar drives the same engine shader, even without a battle.
		var preview := TextureRect.new()
		preview.set_script(PREVIEW)
		preview.material = battle.ship_actor.material.duplicate()
		preview._process(0.15)
		assert(is_equal_approx(float(preview.material.get_shader_parameter("clock")), 0.15))
		preview.free()
	for species in range(FLEET.MONSTER_NAMES.size()):
		battle.configure_encounter("default", "laser", FLEET.encounter(5, 7, 12))
		battle.encounter_species = species
		battle.enemy_impact = 0.0
		battle.enemy_attack_timer = 0.0
		battle.update_actors()
		var idle := battle.monster_pose(species)
		battle._process(0.19)
		var moving := battle.monster_pose(species)
		assert(not Vector2(idle.stretch).is_equal_approx(moving.stretch))
		assert(battle.monster_actor.texture == FLEET.monster_texture(species))
		assert(int(battle.monster_actor.material.get_shader_parameter("motion_kind")) == battle.MONSTER_MOTION[species])
		battle.hit_ship()
		battle._process(0.1)
		assert(float(battle.monster_actor.material.get_shader_parameter("attack_charge")) > 0.5)
		assert(not Vector2(battle.monster_pose(species).stretch).is_equal_approx(moving.stretch))
		battle._process(0.16)
		assert(float(battle.monster_actor.material.get_shader_parameter("attack_recoil")) > 0.5)
		battle._process(0.2)
		assert(float(battle.monster_actor.material.get_shader_parameter("attack_charge")) == 0)
		battle.hit_enemy()
		battle._process(0.16)
		assert(float(battle.monster_actor.material.get_shader_parameter("impact_flash")) > 0)
		assert(float(battle.monster_actor.material.get_shader_parameter("damage_fraction")) > 0)
		battle._process(1.0)
		assert(float(battle.monster_actor.material.get_shader_parameter("impact_flash")) == 0)
		assert(battle.monster_actor.visible)
	battle.free()
	print("All 13 ships and 13 monsters animation tests passed")
	quit()
