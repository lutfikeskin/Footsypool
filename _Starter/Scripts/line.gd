@tool
extends Line2D

@export var targets: Array[Node2D]

func _process(_delta: float) -> void :
    var i: int = 0
    for p in targets:
        points[i] = to_local(p.global_position) - to_local(global_position)
        i += 1
