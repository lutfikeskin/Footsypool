class_name Obstacle extends StaticBody2D

# Arena obstacle. The ball's raycast treats it like a wall, so it reflects naturally.

var radius: = 0.0
var rect_size: = Vector2.ZERO
var bumper: = false
var color: = Color(0.16, 0.2, 0.24)

func setup(cfg: Dictionary):
    global_position = cfg.pos
    rotation = cfg.get("rot", 0.0)
    bumper = cfg.get("bumper", false)
    if bumper:
        color = Color(1.0, 0.65, 0.25)
    var cs: = CollisionShape2D.new()
    if cfg.shape == "circle":
        var s: = CircleShape2D.new()
        s.radius = cfg.r
        cs.shape = s
        radius = cfg.r
    else:
        var s: = RectangleShape2D.new()
        s.size = cfg.size
        cs.shape = s
        rect_size = cfg.size
    add_child(cs)
    z_index = roundi(global_position.y)
    queue_redraw()

func clearance_radius() -> float:
    return radius if radius > 0 else rect_size.length() * 0.5

func _draw():
    var shadow: = Color(0, 0, 0, 0.25)
    var outline: = Color(1, 1, 1, 0.35)
    if radius > 0:
        draw_circle(Vector2(0, 12), radius, shadow)
        draw_circle(Vector2.ZERO, radius, color)
        draw_arc(Vector2.ZERO, radius - 3, 0, TAU, 32, outline, 4)
        if bumper:
            draw_circle(Vector2.ZERO, radius * 0.4, Color(1, 1, 1, 0.6))
    else:
        var r: = Rect2(-rect_size * 0.5, rect_size)
        draw_rect(Rect2(r.position + Vector2(0, 12), r.size), shadow)
        draw_rect(r, color)
        draw_rect(r.grow(-3), outline, false, 4)
        if bumper:
            draw_rect(Rect2(r.position + Vector2(r.size.x * 0.3, r.size.y * 0.3), r.size * Vector2(0.4, 0.4)), Color(1, 1, 1, 0.6))
