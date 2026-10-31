extends ScrollContainer

# Observe presses before cards consume them; cancel their click once a swipe begins.
var pointer: int = -2
var origin := Vector2.ZERO
var previous := Vector2.ZERO
var start_scroll := Vector2.ZERO
var dragging := false
var velocity := Vector2.ZERO

func _ready() -> void:
 scroll_deadzone = 12

func _input(event: InputEvent) -> void:
 if not is_visible_in_tree(): return
 if event is InputEventMouse and event.device == -1:
  if dragging and event is InputEventMouseMotion: get_viewport().set_input_as_handled()
  return
 if event is InputEventScreenTouch:
  if event.pressed: begin(event.position, event.index)
  elif event.index == pointer: finish()
 elif event is InputEventScreenDrag and event.index == pointer:
  move_pointer(event.position)
 elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  if event.pressed: begin(event.position, -1)
  elif pointer == -1: finish()
 elif event is InputEventMouseMotion and pointer == -1:
  move_pointer(event.position)

func begin(position: Vector2, id: int) -> void:
 if pointer != -2 or not get_global_rect().has_point(position): return
 # Keep scrollbar thumbs and form sliders directly operable.
 var hovered := get_viewport().gui_get_hovered_control()
 if hovered is Range: return
 velocity = Vector2.ZERO
 pointer = id
 origin = position
 previous = position
 start_scroll = Vector2(scroll_horizontal, scroll_vertical)

func enabled_motion(value: Vector2) -> Vector2:
 return Vector2(value.x if horizontal_scroll_mode != SCROLL_MODE_DISABLED else 0.0,
  value.y if vertical_scroll_mode != SCROLL_MODE_DISABLED else 0.0)

func move_pointer(position: Vector2) -> void:
 var distance := enabled_motion(origin - position)
 if not dragging and distance.length() > scroll_deadzone:
  dragging = true
  propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
  scroll_started.emit()
 if dragging:
  scroll_horizontal = int(start_scroll.x + distance.x)
  scroll_vertical = int(start_scroll.y + distance.y)
  velocity = enabled_motion(previous - position) / maxf(get_process_delta_time(), 0.008)
  get_viewport().set_input_as_handled()
 previous = position

func finish() -> void:
 pointer = -2
 if dragging:
  dragging = false
  propagate_notification(Control.NOTIFICATION_SCROLL_END)
  scroll_ended.emit()

func _process(delta: float) -> void:
 if pointer != -2 or velocity.length() < 10.0: return
 var before := Vector2(scroll_horizontal, scroll_vertical)
 scroll_horizontal += int(velocity.x * delta)
 scroll_vertical += int(velocity.y * delta)
 velocity = velocity.move_toward(Vector2.ZERO, 2400.0 * delta)
 if before == Vector2(scroll_horizontal, scroll_vertical): velocity = Vector2.ZERO

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
  finish()
  velocity = Vector2.ZERO
