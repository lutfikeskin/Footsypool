class_name Effects
extends Node

static var singleton: Effects = null

func _enter_tree() -> void :
    if singleton == null:
        singleton = self

func _exit_tree() -> void :
    if singleton == self:
        singleton = null

func _init() -> void :
    if singleton == null:
        singleton = self

@export var effects: Array[PackedScene]
@export var pop_index: = 0

var pools: Array[Array]

func _ready() -> void :
    pools = []
    pools.resize(len(effects))
    pools.fill([])

func add_many(indices: Array[int], pos: Vector2):
    for i in indices: add(i, pos)

func pop(text: String, pos: Vector2) -> TextPop:
    var t: = add(pop_index, pos, 2) as TextPop
    t.pop(text)
    return t

func add(index: int, pos: Vector2, pool_size: int = -1) -> Node:
    var effect: = effects[index].instantiate()
    if pool_size >= 0:
        pools[index].push_back(effect)
        if len(pools[index]) > pool_size:
            (pools[index].pop_front() as Node).queue_free()

    call_deferred("add_child", effect)

    if effect is MovableRigidbody:
        effect.move_to(pos, 0)
        return effect

    if effect is Node2D:
        effect.position = pos

    if effect is GPUParticles2D or effect is CPUParticles2D:
        effect.restart()

    return effect
