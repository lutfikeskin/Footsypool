extends Node

@export var label: Control

func _ready() -> void :
    if label is Label or label is RichTextLabel:
        label.text = ProjectSettings.get_setting("application/config/version")
