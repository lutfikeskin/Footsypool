extends Node2D

@export var target: Vector2

var original_pos: Vector2

func _ready() -> void :
    original_pos = position

func _process(_delta: float) -> void :
    position = original_pos.move_toward(to_local(target), 100).normalized() * 40
