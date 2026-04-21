class_name FakeParticles
extends Node2D

@export var particle: PackedScene
@export var amount: = 5
@export var amount_variation: = 0.0
@export var lifetime: = 1.0
@export var lifetime_variation: = 0.1
@export var velocity: = 1.0
@export var velocity_variation: = 0.1
@export var width: = 10
@export var width_variation: = 0.1
@export var width_curve: Curve
@export var color_dark_variation: = 0.0
@export var color_light_variation: = 0.0

var particles: Array[FakeParticle]

func _ready() -> void :
    for i in range(amount):
        var p: = particle.instantiate() as FakeParticle
        particles.push_back(p)
        p.lifetime = lifetime * get_variation(lifetime_variation)
        p.line.width = width * get_variation(width_variation)
        p.line.width_curve = width_curve
        p.line.modulate = modulate.darkened(randf() * color_dark_variation).lightened(randf() * color_light_variation)
        call_deferred("add_child", p)
    await get_tree().create_timer(0.01).timeout
    for p in particles:
        if p:
            p.apply_impulse(Vector2.from_angle(randf() * TAU) * 1000 * velocity * get_variation(velocity_variation))

    await get_tree().create_timer(5).timeout
    queue_free()

func get_variation(variation: float) -> float:
    return 1 + randf_range( - variation, variation)
