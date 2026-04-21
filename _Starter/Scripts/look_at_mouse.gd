class_name LookAtMouse extends Node2D

@export var distance: = 100
@export var target: Node2D

var original_pos: Vector2
var target_pos: Vector2
var look_speed: = 1.0
var ignore_target: = true

func _ready() -> void :
    original_pos = position
    target_pos = original_pos

func _process(delta: float) -> void :
    var mp: = get_global_mouse_position()
    var pos: = mp if ignore_target or not target or global_position.distance_to(mp) < global_position.distance_to(target.global_position) else target.global_position
    target_pos = original_pos.move_toward(to_local(pos), delta * 60 * 100).normalized() * distance
    position = position.move_toward(target_pos, delta * 300 * look_speed)
