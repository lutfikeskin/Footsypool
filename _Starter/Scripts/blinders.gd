class_name Blinders
extends CanvasLayer

@export var left: ColorRect
@export var right: ColorRect
@export var duration = 0.4

signal opened
signal closed

static var singleton: Blinders = null

func _enter_tree() -> void :
    if singleton == null:
        singleton = self

func _exit_tree() -> void :
    if singleton == self:
        singleton = null

func _init() -> void :
    if singleton == null:
        singleton = self

func _ready() -> void :
    prepare()
    show()
    await get_tree().create_timer(0.1).timeout
    open()

func prepare():
    var win: = DisplayServer.window_get_size()
    left.set_size(Vector2(win.x * 0.5, win.y * 2) / get_tree().root.content_scale_factor, true)
    right.set_size(Vector2(win.x * 0.5, win.y * 2) / get_tree().root.content_scale_factor, true)

func open():
    prepare()
    get_tree().create_tween().tween_property(left, "scale", Vector2(0, 1), duration).set_trans(Tween.TRANS_QUAD)
    get_tree().create_tween().tween_property(right, "scale", Vector2(0, 1), duration).set_trans(Tween.TRANS_QUAD)
    await get_tree().create_timer(duration).timeout
    opened.emit()

func close():
    prepare()
    get_tree().create_tween().tween_property(left, "scale", Vector2(1, 1), duration).set_trans(Tween.TRANS_BOUNCE)
    get_tree().create_tween().tween_property(right, "scale", Vector2(-1, 1), duration).set_trans(Tween.TRANS_BOUNCE)
    await get_tree().create_timer(duration + 0.1).timeout
    closed.emit()

func quit():
    if OS.get_name() == "Web":
        return
    close()
    await get_tree().create_timer(duration + 0.1).timeout
    get_tree().quit()
