class_name SoundEffects
extends Node

static var singleton: SoundEffects = null

func _enter_tree() -> void :
    if singleton == null:
        singleton = self

func _exit_tree() -> void :
    if singleton == self:
        singleton = null

func _init() -> void :
    if singleton == null:
        singleton = self

@export var effects: Array[AudioStream]
@export var prefab: PackedScene

func add_many(indices: Array[int], pos: Vector2, volume: float = 1.0, pitch_range: float = 0.1):
    for i in indices: add(i, pos, volume, pitch_range)

func add(index: int, pos: Vector2, volume: float = 1.0, pitch_range: float = 0.1):
    var effect: = prefab.instantiate()

    if effect is Node2D:
        effect.position = pos

    if effect is AudioStreamPlayer2D:
        effect.volume_linear = volume
        effect.pitch_scale = randf_range(1 - pitch_range, 1 + pitch_range)
        effect.stream = effects[index]

    add_child(effect)
