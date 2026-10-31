extends SceneTree
const F = preload("res://scripts/FleetBalance.gd")
const R = preload("res://scripts/RewardManager.gd")
const P = preload("res://scripts/LearningProgression.gd")
const B = preload("res://scripts/SpaceScene.gd")
class TestMain extends "res://scripts/Main.gd":
	func save_progress() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
	assert(F.SHIP_IDS.size() == 13 and F.WEAPON_IDS.size() == 10 and F.MONSTER_NAMES.size() == 13)
	for world in P.WORLD_ORDER:
		for level in range(P.levels(world).size()):
			var minimum := 12 if P.is_final(world, level) else 10
			var data := F.encounter(world, level, minimum)
			var attainable := false
			for ship in range(F.SHIP_IDS.size()):
				for weapon in range(F.WEAPON_IDS.size()):
					if F.DRAW[weapon] > F.POWER[ship]: continue
					var damage := F.damage(ship, weapon, data)
					var answers := int(ceil(float(data.hp) / damage))
					assert(answers >= minimum and answers <= int(ceil(minimum * 1.8)))
					if F.SHIP_COSTS[ship] + F.WEAPON_COSTS[weapon] <= data.budget and answers == minimum: attainable = true
			assert(attainable)
	var p := {"coins": 100000, "skills": {}, "rewards": {"equipped": "gold", "owned": {"gold": true}}}
	R.migrate(p)
	assert(p.rewards.equipped == "gold" and p.rewards.weapon == "machine_gun")
	assert(R.purchase(p, "weapon_7"))
	assert(not R.equip(p, "weapon_7"))
	assert(R.purchase(p, "ship_10") and R.equip(p, "ship_10") and R.equip(p, "weapon_7"))
	assert(R.equip(p, "default") and p.rewards.weapon == "laser")
	# Even two perfect first missions plus all plausible first bonuses cannot buy a hull.
	var fresh := {"coins": 0}
	R.settle(fresh, 1, true, 10, 0, 150, 1, "day1", 1)
	R.settle(fresh, 2, true, 10, 0, 150, 1, "day2", 1)
	assert(not R.purchase(fresh, "violet") and not R.purchase(fresh, "machine_gun"))
	for id in F.SHIP_IDS:
		assert(F.ship_texture(id) != null)
	for species in range(F.MONSTER_NAMES.size()):
		assert(F.monster_texture(species) != null)
	for i in range(1, 8):
		var texture: Texture2D = load("res://assets/battle/weapon_%d.png" % i)
		var image := texture.get_image()
		assert(not image.is_empty() and image.get_pixel(0, 0).a < 0.01)
	var battle := B.new()
	root.add_child(battle)
	battle.set_process(false)
	var data := F.encounter(1, 0, 10)
	battle.configure_encounter("default", "laser", data)
	var species := battle.monster_species()
	for i in range(10):
		battle.hit_enemy()
		battle._process(0.6)
		assert(battle.monster_species() == species)
		var hp := battle.enemy_hp
		battle.set_boss_mode(i % 2 == 0)
		assert(battle.enemy_hp == hp)
	assert(battle.enemy_hp == 0 and battle.enemy_index == 0)
	battle._process(2)
	assert(not battle.monster_actor.visible)
	battle.free()
	var host := TestMain.new()
	root.add_child(host)
	host.set_process(false)
	host.progress = {"skills": {}, "coins": 0}
	host.start_mission()
	host.resolve_answer(-1, "skip")
	host._process(1.1)
	for i in range(9):
		host.resolve_answer(host.question.answer, "answer")
		host._process(1.1)
	assert(not host.finished and host.hits == 9)
	host.resolve_answer(host.question.answer, "answer")
	host._process(1.1)
	assert(host.finished and host.art.enemy_hp == 0)
	host.free()
	print("Fleet, economy and single encounter tests passed")
	quit()
