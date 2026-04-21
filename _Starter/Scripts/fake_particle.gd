class_name FakeParticle
extends RigidBody2D

@export var line: Line2D

var lifetime: = 1.0
var points: PackedVector2Array

func _ready() -> void :
    line.reparent(get_tree().root)

func _process(_delta: float) -> void :
    pass

func _physics_process(delta: float) -> void :
    lifetime -= delta
    if linear_velocity.length() > 50:
        points.push_back(line.to_local(global_position))
        line.points = points
    if lifetime <= 0 and len(points) > 0:
        points.remove_at(0)
        line.points = points
    if lifetime <= 0 and len(points) == 0:
        queue_free()

func _notification(event: int):
    if line and event == NOTIFICATION_PREDELETE:
        line.queue_free()
