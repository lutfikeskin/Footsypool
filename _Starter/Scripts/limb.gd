class_name Limb
extends Line2D

@export var target: Node2D
@export var length: = 100.0

@export var flip: = false

var upper: LimbSegment
var lower: LimbSegment

func _ready() -> void :
    upper = LimbSegment.new(length, 0, false)
    lower = LimbSegment.new(length, 1, true)

func _process(_delta: float) -> void :
    var pos: = target.global_position
    var normal: = (pos - global_position).normalized()

    lower.follow(pos, normal, flip)
    upper.follow(lower.start, normal, flip)

    upper.constrain(global_position)
    lower.constrain(upper.end)

    points[1] = upper.end - global_position
    points[2] = target.global_position - global_position

class LimbSegment:
    var start: Vector2
    var end: Vector2
    var length: float
    var isTip: bool

    func _init(l: float, index: int, tip: bool):
        start = Vector2(l * index, 0)
        end = Vector2(l * (index + 1), 0)
        length = l
        isTip = tip

    func follow(target: Vector2, normal: Vector2, flip: bool):
        var diff: = target - start;
        var dir: = diff.normalized() * length

        if isTip:
            var flipped: = dir.reflect(normal).normalized() * length
            var flipMod: = -1 if flip else 1
            if normal.y * flipMod < 0:
                dir = flipped if dir.x > flipped.x else dir
            if normal.y * flipMod >= 0:
                dir = flipped if dir.x < flipped.x else dir


        end = target;
        start = end - dir;

    func constrain(pos: Vector2):
        var dir: = end - start
        if dir.length() > 0:
            start = pos
            end = start + dir.normalized() * length
