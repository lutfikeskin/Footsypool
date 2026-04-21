class_name TextPop extends Node2D

@export var label: RichTextLabel
@export var anim: AnimationPlayer

func pop(text: String):
    label.text = text
