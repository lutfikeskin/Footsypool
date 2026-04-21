class_name MoveTowards extends Node2D

@export var target: Node2D

func _process(_delta: float) -> void :
    var pos: = target.global_position if target else Vector2.ZERO
    position = Vector2.ZERO.move_toward(to_local(pos), 100).normalized() * 40
