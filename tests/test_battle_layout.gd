extends SceneTree
const L10N = preload("res://scripts/Localization.gd")
const SAVE = preload("res://scripts/SaveManager.gd")
class TestMain extends "res://scripts/Main.gd":
 func save_progress() -> void: pass
 func load_progress() -> void: pass
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var host := TestMain.new()
 root.add_child(host)
 host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 host.set_process(false)
 for width in [1280, 1920]:
  root.size = Vector2i(width, 720)
  for language in ["en", "uk"]:
   L10N.apply_language(language)
   for mode in [0, 1]:
    host.progress = SAVE.migrate({"skills": {}})
    host.progress.rewards.owned["repair"] = true
    host.world = 4
    host.level = mode
    host.start_mission()
    await process_frame
    await process_frame
    for button in host.find_children("*", "Button", true, false):
     if not button.is_visible_in_tree(): continue
     var rect: Rect2 = button.get_global_rect()
     assert(rect.position.x >= 0 and rect.end.x <= width + 1, "Horizontal overflow: " + str(button.name) + " " + str(rect))
     assert(rect.position.y >= 0 and rect.end.y <= 721, "Vertical overflow: " + str(button.name) + " " + str(rect))
    if mode == 1:
     var grid: GridContainer = host.keypad.get_child(1)
     for index in range(9):
      assert(grid.get_child(index).get_child(0).text == str(index + 1))
      assert(grid.get_child(index).size.y >= 64)
    if mode == 1:
     for stage in range(3):
      host.use_hint()
      await process_frame
      await process_frame
      assert(not host.hint_button.visible and host.hint_close_button.visible)
      assert(host.keypad.get_global_rect().end.y <= 721, "Hint must not push the keyboard offscreen")
      host.close_hint()
    host.shield = 60
    var coins: int = host.progress.coins
    host.use_repair()
    assert(host.shield == 75 and host.progress.coins == coins)
    assert(host.find_child("BattleRepair", true, false).disabled)
    host.use_repair()
    assert(host.shield == 75)
 host.free()
 print("Battle layout, keyboard order and repair controls tests passed")
 quit()
