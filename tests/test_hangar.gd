extends SceneTree
const MAIN = preload("res://scripts/Main.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var host := Control.new()
	host.set_script(MAIN)
	root.add_child(host)
	host.progress = {"coins": 1500, "skills": {}}
	host.show_hangar()
	host.buy_hangar("gold")
	host.equip_hangar("gold")
	host.buy_hangar("battery")
	host.buy_hangar("repair")
	host.show_hangar()
	assert(host.progress.coins == 720)
	host.start_mission()
	assert(host.energy == 65)
	assert(host.art.ship_tint == Color("ffe080"))
	host.shield = 50
	host.use_repair()
	assert(host.shield == 65)
	host.use_repair()
	assert(host.shield == 65)
	var balance: int = host.progress.coins
	host.fail_mission()
	assert(host.progress.coins == balance)
	host.start_mission()
	host.hits = 10
	host.finish_mission()
	balance = host.progress.coins
	host.finish_mission()
	host.show_hangar()
	assert(host.progress.coins == balance)
	host.load_progress()
	assert(host.progress.coins == balance)
	host.queue_free()
	await process_frame
	print("Hangar integration tests passed")
	quit()
