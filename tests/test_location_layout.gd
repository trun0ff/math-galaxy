extends SceneTree
const L10N = preload("res://scripts/Localization.gd")
const P = preload("res://scripts/LearningProgression.gd")
const PARENT_UI = preload("res://scripts/ParentDashboard.gd")
const SAVE = preload("res://scripts/SaveManager.gd")
class TestMain extends "res://scripts/Main.gd":
 func save_progress() -> void: pass
 func load_progress() -> void: pass
func _initialize() -> void: call_deferred("run")
func run() -> void:
 root.size = Vector2i(1280, 720)
 var host := TestMain.new()
 root.add_child(host)
 host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 host.set_process(false)
 host.progress = SAVE.migrate({"skills": {}})
 for world in P.WORLD_ORDER:
  assert(P.is_unlocked(host.progress, world, 0) == (world == 1))
 host.progress["parent_settings"] = {"independent_worlds": true}
 for world in P.WORLD_ORDER:
  assert(P.is_unlocked(host.progress, world, 0))
  assert(not P.is_unlocked(host.progress, world, 1))
 assert(SAVE.validate(host.progress))
 host.select_world(6)
 assert(host.world == 6 and host.screen == "menu")
 host.open_world_locations(6)
 assert(host.world == 6 and host.screen == "levels")
 host.show_menu()
 assert(host.find_child("WorldActions", true, false).get_child_count() == 2)
 for language in ["en", "uk"]:
  L10N.apply_language(language)
  for subtitle in host.WORLD_SUBTITLES:
   if language == "uk": assert(L10N.text(subtitle) != subtitle)
  if language == "uk" and DisplayServer.get_name() != "headless":
   host.world = 6
   host.show_menu()
   await process_frame
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://.test-user/world-gallery.png")
  for world in P.WORLD_ORDER:
   host.world = world
   host.show_levels()
   await process_frame
   await process_frame
   var grid: GridContainer = host.find_child("SublevelGrid", true, false)
   assert(grid.columns == 2)
   for card in grid.get_children():
    var preview: TextureRect = card.find_child("LocationPreview", true, false)
    assert(preview.texture.resource_path == host.LOCATIONS.asset_path(world, card.get_index()))
    assert(card.size.x > 420)
    var content: VBoxContainer = card.get_child(1)
    assert(content.get_combined_minimum_size().y <= card.size.y - 30, "Content overflow: " + str(world) + " / " + card.name)
   if world == 6 and language == "uk" and DisplayServer.get_name() != "headless":
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://.test-user/sublevel-grid.png")
  host.world = 6
  host.level = 1
  host.start_mission()
  await process_frame
  await process_frame
  if language == "uk" and DisplayServer.get_name() != "headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://.test-user/tidal-battle.png")
 # The option persists and timing controls must preserve it.
 var panel := Control.new()
 panel.set_script(PARENT_UI)
 root.add_child(panel)
 panel.setup(host)
 panel.settings()
 var toggle: CheckButton = panel.find_child("IndependentWorlds", true, false)
 assert(toggle.button_pressed)
 toggle.button_pressed = false
 assert(not P.is_unlocked(host.progress, 6, 0))
 toggle.button_pressed = true
 assert(P.is_unlocked(host.progress, 6, 0))
 var profile_path := "res://.test-user/independent_worlds_test.json"
 assert(SAVE.write_save(profile_path, host.progress))
 var loaded: Dictionary = SAVE.load_profile(profile_path).data
 assert(loaded.parent_settings.independent_worlds)
 for action in ["Save timing", "Restore default timing"]:
  panel.settings()
  for control in panel.body.get_children():
   if control is Button and control.get_node_or_null("Caption") != null and control.get_node("Caption").text == L10N.text(action):
    control.pressed.emit()
    break
  assert(host.progress.parent_settings.independent_worlds)
 panel.free()
 for width in [1600, 960, 720]:
  root.content_scale_size = Vector2i(width, 720)
  root.size = Vector2i(width, 720)
  host.show_levels()
  await process_frame
  await process_frame
  var grid: GridContainer = host.find_child("SublevelGrid", true, false)
  assert(grid.size.x <= width)
  assert(grid.columns == (2 if width >= 960 else 1))
 host.free()
 print("Location layout, translations and independent worlds tests passed")
 quit()
