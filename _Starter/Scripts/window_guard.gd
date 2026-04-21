class_name WindowGuard extends Node

var size_mod: = 1.0

func _ready():
    get_viewport().size_changed.connect(size_changed)
    size_changed()

func size_changed():
    var height: = DisplayServer.window_get_size().y

    get_tree().root.content_scale_factor = clampf(height / 1080.0, 0.5, 1) * size_mod
