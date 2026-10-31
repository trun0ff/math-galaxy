extends SceneTree
const P = preload("res://scripts/LearningProgression.gd")
class TestMain extends "res://scripts/Main.gd":
 func save_progress() -> void: pass
 func load_progress() -> void: pass
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var host := TestMain.new()
 root.add_child(host)
 host.set_process(false)
 for world in P.WORLD_ORDER:
  host.world = world
  host.show_menu()
  await process_frame
  host.show_levels()
  await process_frame
  for level in [0, 1]:
   host.level = level
   host.start_mission()
   await process_frame
   assert(host.input_mode == P.input_mode(level))
   if level == 0: assert(host.question_limit == 5.0)
   assert(host.art.current_world == world)
 host.free()
 print("World pairs UI tests passed")
 quit()
