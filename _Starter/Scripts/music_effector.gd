class_name MusicEffector extends Node

@export var bus_index: int = 1
@export var pitch_index: int

static var singleton: MusicEffector = null

func _enter_tree() -> void :
    if singleton == null:
        singleton = self

func _exit_tree() -> void :
    if singleton == self:
        singleton = null

func _init() -> void :
    if singleton == null:
        singleton = self

func reset():
    pitch(1)

func pitch(target: float, duration: float = 1, revert: bool = false):
    var eff: = AudioServer.get_bus_effect(bus_index, pitch_index) as AudioEffectPitchShift
    var tween: = get_tree().create_tween()
    tween.tween_property(eff, "pitch_scale", target, duration).set_trans(Tween.TRANS_QUAD)
    if revert:
        tween.tween_property(eff, "pitch_scale", 1, duration).set_trans(Tween.TRANS_QUAD)
