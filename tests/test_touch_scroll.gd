extends SceneTree

class WorldCardHost extends "res://scripts/Main.gd":
 func _ready() -> void: pass
 func select_world(value: int) -> void:
  world = value
  screen = "menu"
 func open_world_locations(value: int) -> void:
  world = value
  screen = "levels"

var clicks: int = 0

func _initialize() -> void: call_deferred("run")

var use_mouse := false

func touch(position: Vector2, pressed: bool) -> void:
 if use_mouse:
  var event := InputEventMouseButton.new()
  event.position = position
  event.global_position = position
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  Input.parse_input_event(event)
 else:
  var event := InputEventScreenTouch.new()
  event.position = position
  event.pressed = pressed
  Input.parse_input_event(event)

func drag(position: Vector2, relative: Vector2) -> void:
 if use_mouse:
  var event := InputEventMouseMotion.new()
  event.position = position
  event.global_position = position
  event.relative = relative
  event.button_mask = MOUSE_BUTTON_MASK_LEFT
  Input.parse_input_event(event)
 else:
  var event := InputEventScreenDrag.new()
  event.position = position
  event.relative = relative
  Input.parse_input_event(event)

func run() -> void:
 root.size = Vector2i(1280, 720)
 for variant in range(4):
  var horizontal: bool = variant % 2 == 1
  use_mouse = variant >= 2
  clicks = 0
  var scroll := preload("res://scripts/ui/TouchScroll.gd").new()
  scroll.position = Vector2(40, 40)
  scroll.size = Vector2(500, 400)
  scroll.scroll_deadzone = 12
  scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if horizontal else ScrollContainer.SCROLL_MODE_DISABLED
  scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if horizontal else ScrollContainer.SCROLL_MODE_AUTO
  root.add_child(scroll)
  var box: BoxContainer = HBoxContainer.new() if horizontal else VBoxContainer.new()
  scroll.add_child(box)
  for index in range(10):
   var button := Button.new()
   button.custom_minimum_size = Vector2(300, 150)
   button.text = "Card %d" % index
   button.pressed.connect(func(): clicks += 1)
   box.add_child(button)
  await process_frame
  await process_frame
  var start := Vector2(240, 160)
  touch(start, true)
  await process_frame
  var motion := Vector2(-120, 0) if horizontal else Vector2(0, -80)
  drag(start + motion, motion)
  await process_frame
  touch(start + motion, false)
  await process_frame
  assert(scroll.scroll_horizontal > 0 if horizontal else scroll.scroll_vertical > 0, "Swipe must scroll over a card")
  assert(clicks == 0, "Swipe must not activate a card")
  if use_mouse:
   scroll.velocity = Vector2.ZERO
   scroll.scroll_horizontal = 0
   scroll.scroll_vertical = 0
   await process_frame
   touch(start, true)
   await process_frame
   touch(start, false)
   await process_frame
   assert(clicks == 1, "Tap must still activate a card")
  scroll.free()
 var host := WorldCardHost.new()
 root.add_child(host)
 host.set_process(false)
 var card: Button = host.make_world_card(6)
 host.add_child(card)
 card.position = Vector2(40, 40)
 card.size = card.custom_minimum_size
 await process_frame
 await process_frame
 use_mouse = true
 touch(card.global_position + Vector2(100, 60), true)
 await process_frame
 touch(card.global_position + Vector2(100, 60), false)
 await process_frame
 assert(host.world == 6 and host.screen == "menu", "Picture selects a world without leaving the galaxy")
 var text_button: Button = card.find_child("OpenWorldLocations", true, false)
 var text_center := text_button.get_global_rect().get_center()
 touch(text_center, true)
 await process_frame
 touch(text_center, false)
 await process_frame
 assert(host.screen == "levels", "Text opens the world's locations")
 host.free()
 print("Touch scrolling and swipe cancellation tests passed")
 quit()
