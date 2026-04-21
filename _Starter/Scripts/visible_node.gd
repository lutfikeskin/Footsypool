@tool
class_name VisibleNode
extends Node2D

@export var color: = Color.AQUAMARINE:
    set(value):
        color = value
        queue_redraw()
@export var size: = 50:
    set(value):
        size = value
        queue_redraw()
@export var show_label: = true:
    set(value):
        show_label = value
        queue_redraw()


func _draw():
    if Engine.is_editor_hint():
        if show_label:
            draw_string(ThemeDB.fallback_font, Vector2( - size * 10 + size * 0.15, - size * 2 + size * 0.15), name, HORIZONTAL_ALIGNMENT_CENTER, size * 20, int(size * 1.5), Color.BLACK)
            draw_string(ThemeDB.fallback_font, Vector2( - size * 10, - size * 2), name, HORIZONTAL_ALIGNMENT_CENTER, size * 20, int(size * 1.5))
        draw_set_transform(Vector2.ZERO, PI * 0.25, Vector2.ONE)
        draw_rect(get_rect(size * 0.75), Color.WHITE, true)
        draw_rect(get_rect(size * 0.5), Color.BLACK, true)
        draw_rect(get_rect(0), color, true)

func get_rect(extension: = 0.0) -> Rect2:
    return Rect2(-0.5 * Vector2(size + extension, size + extension), Vector2(size + extension, size + extension))
