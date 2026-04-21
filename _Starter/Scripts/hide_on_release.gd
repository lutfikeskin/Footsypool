extends CanvasItem

func _ready():
    if not OS.is_debug_build():
        hide()
