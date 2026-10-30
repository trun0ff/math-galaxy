extends Button
## Reusable hand-drawn sci-fi button plate. Text and input remain native Godot controls.
@export var accent_color: Color = Color("2873bd"):
    set(value):
        accent_color = value
        queue_redraw()

func _ready() -> void:
    for state in ["normal", "hover", "pressed", "disabled", "focus"]:
        add_theme_stylebox_override(state, StyleBoxEmpty.new())
    mouse_entered.connect(queue_redraw)
    mouse_exited.connect(queue_redraw)
    button_down.connect(queue_redraw)
    button_up.connect(queue_redraw)
    resized.connect(queue_redraw)

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w < 25 or h < 20: return
    var cut: float = minf(16.0, minf(w, h) * 0.22)
    var points := PackedVector2Array([Vector2(cut,1),Vector2(w-cut,1),Vector2(w-1,cut),Vector2(w-1,h-cut),Vector2(w-cut,h-1),Vector2(cut,h-1),Vector2(1,h-cut),Vector2(1,cut)])
    var accent: Color = accent_color.lightened(0.42)
    var hover: bool = is_hovered() and not disabled
    var down: bool = button_pressed
    var body: Color = Color("101e40").lerp(accent_color.darkened(0.45), 0.42 if not hover else 0.64)
    if down: body = body.lightened(0.12)
    if disabled: body = Color("1b253b")
    draw_colored_polygon(points, body)
    draw_polyline(points + PackedVector2Array([points[0]]), accent if not disabled else Color("46546b"), 2.5, true)
    var top := PackedVector2Array([Vector2(cut+7,4),Vector2(w-cut-7,4),Vector2(w-cut-13,10),Vector2(cut+13,10)])
    draw_colored_polygon(top, Color(accent.r,accent.g,accent.b,0.21 if not hover else 0.43))
    draw_line(Vector2(cut+4,h-5),Vector2(w-cut-4,h-5),Color(accent.r,accent.g,accent.b,0.20),2.0,true)
    for x in [cut+4,w-cut-4]:
        draw_circle(Vector2(x,h*0.5),2.0,accent)
