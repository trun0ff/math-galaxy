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
 root.size = Vector2i(1280, 720)
 host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for world in P.WORLD_ORDER:
  host.world = world
  host.show_menu()
  await process_frame
  host.show_levels()
  await process_frame
  var grid: GridContainer = host.find_child("SublevelGrid", true, false)
  assert(grid != null and grid.columns > 1)
  assert(grid.get_child_count() == P.levels(world).size())
  assert(grid.get_child(0).find_child("LocationPreview", true, false).texture != null)
  for level in range(P.levels(world).size()):
   host.level = level
   host.start_mission()
   await process_frame
   assert(host.input_mode == P.input_mode(level))
   if level == 0: assert(host.question_limit == 5.0)
   for attempt in range(5):
    var selected: Dictionary = host.choose_question()
    assert(selected.world == world and P.matches(world, level, selected))
   assert(host.art.current_world == world)
   assert(host.art.location_texture.resource_path == host.LOCATIONS.asset_path(world, level))
 host.free()
 print("World pairs UI tests passed")
 quit()
