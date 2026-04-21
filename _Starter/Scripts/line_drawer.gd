class_name LineDrawer
extends Node

@export var line: Line2D

static var _singleton: LineDrawer = null
static var singleton: LineDrawer:
    get:
        return _singleton

func _enter_tree() -> void :
    if singleton == null:
        _singleton = self

func _exit_tree() -> void :
    if singleton == self:
        _singleton = null

func _init() -> void :
    if singleton == null:
        _singleton = self

func add(from: Vector2, to: Vector2, delay: float = 0.05):
    line.points[0] = from
    line.points[1] = to
    line.width = randf_range(3, 12)
    line.show()
    await get_tree().create_timer(delay).timeout
    line.hide()
