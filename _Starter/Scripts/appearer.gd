class_name Appearer
extends Node

@export var appear_after: = 0.0
@export var auto_hide_after: = 0.0
@export var duration: = 0.3
@export var center_pivot: = false

var obj
var size: Vector2
var shown: = false
var tween: PropertyTweener

func _ready() -> void :
    obj = self
    if obj is Node2D or obj is Control:
        size = obj.scale
        obj.scale = Vector2.ZERO

    repivot()

    if appear_after > 0:
        appear(appear_after)
    if auto_hide_after:
        disappear(auto_hide_after)

func repivot():
    if center_pivot:
        obj.pivot_offset = size * 0.5

func appear(delay: float = 0.0):
    if shown or not get_tree():
        return
    repivot()
    if tween: await tween.finished
    shown = true
    tween = get_tree().create_tween().tween_property(obj, "scale", size, duration).set_trans(Tween.TRANS_BOUNCE).set_delay(delay)
    await tween.finished
    tween = null

func disappear(delay: float = 0.0):
    if not shown or not get_tree():
        return
    repivot()
    if tween: await tween.finished
    shown = false
    tween = get_tree().create_tween().tween_property(obj, "scale", Vector2.ZERO, duration).set_trans(Tween.TRANS_ELASTIC).set_delay(delay)
    await tween.finished
    tween = null

func show_with_text(text: String, delay: float = -1):
    if obj is Label or obj is RichTextLabel:
        obj.text = text
    if delay > 0: await get_tree().create_timer(delay).timeout
    appear()

func set_text(text: String):
    if obj is Label or obj is RichTextLabel:
        obj.text = text
