class_name Camera extends Camera2D

@export var rotation_amount: = 0.1

var shake_duration: = 0.0
var shake_amount: = 0.0

func shake(amount: float, duration: float):
    shake_duration = duration
    shake_amount = amount

func _process(delta):
    if shake_duration > 0:
        shake_duration -= delta

    var amt: = shake_amount if shake_duration > 0 else 0.0
    offset = Vector2.ONE.rotated(randf() * PI) * amt
    rotation_degrees = randf_range(-1, 1) * amt * rotation_amount
