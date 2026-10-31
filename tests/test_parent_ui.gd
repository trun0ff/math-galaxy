extends SceneTree
const MAIN = preload("res://scripts/Main.gd")
const UI = preload("res://scripts/ParentDashboard.gd")
class TestMain extends "res://scripts/Main.gd":
	func save_progress() -> void:
		pass

func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var host := TestMain.new()
	host.progress = {"skills": {}}
	# Keep host outside the tree to avoid loading the real profile.
	var panel := Control.new()
	panel.set_script(UI)
	root.add_child(panel)
	panel.setup(host)
	await process_frame
	assert(panel.body.size.x <= panel.size.x)
	panel.pin = "1234"
	panel.check_pin(false)
	assert(not host.progress.has("parent_pin"))
	panel.pin = "9876"
	panel.check_pin(false)
	assert(not host.progress.has("parent_pin"))
	panel.pin = "1234"
	panel.check_pin(false)
	panel.pin = "1234"
	panel.check_pin(false)
	assert(host.progress.has("parent_pin"))
	panel.unlocked = false
	panel.gate()
	panel.pin = "9999"
	panel.check_pin(true)
	assert(not panel.unlocked)
	panel.pin = "1234"
	panel.check_pin(true)
	assert(panel.unlocked)
	for method in ["dashboard", "worlds", "facts", "history", "settings"]:
		panel.call(method)
		await process_frame
		await process_frame
		assert(panel.body.size.x <= panel.size.x, method + " exceeds viewport")
	panel.queue_free()
	host.free()
	print("Parent screen layout smoke tests passed")
	quit()

