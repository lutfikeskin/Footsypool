class_name Dude extends Node2D

@export var body: StaticBody2D
@export var player: bool
@export var anim: AnimationPlayer
@export var spot: Sprite2D
@export var number: Label
@export var enemy_colors: Array[Color]
@export var sprite: Sprite2D
@export var brow: Control
@export var hairs: Array[Sprite2D]
@export var catch_ring: Sprite2D
@export var extra_hairs: Array[Sprite2D]
@export var looker: LookAtMouse

var score: = 1
var touched: = false
var has_weapon: = false
var elite_enemy: = false
var is_boss: = false
var boss_kind: = ""
var moving: = false

signal moved

func _ready() -> void :
    var h: = hairs.pick_random() as Sprite2D
    h.show()
    h.flip_h = randf() < 0.5

func get_anim_speed() -> float:
    return randf_range(0.9, 1.1)

func move_to(pos: Vector2):
    var speed_mod: = 1.0 if player else 1.5
    var duration: = pos.distance_to(global_position) * 0.003 / speed_mod
    moving = true
    get_tree().create_tween().tween_property(self, "global_position", pos, duration).set_trans(Tween.TRANS_QUAD)
    anim.play("run")
    anim.speed_scale = 3.5 * get_anim_speed()
    await get_tree().create_timer(duration).timeout
    anim.speed_scale = get_anim_speed()
    anim.play("idle")
    moving = false
    moved.emit()

func toggle_collision(state: bool):
    body.process_mode = Node.PROCESS_MODE_INHERIT if state else Node.PROCESS_MODE_DISABLED

func make_enemy():
    spot.self_modulate = Color.WHITE
    number.self_modulate = enemy_colors[1]
    sprite.self_modulate = enemy_colors[0]
    brow.show()
    for h in hairs: h.self_modulate = enemy_colors[1]
    for h in extra_hairs: h.self_modulate = enemy_colors[1]
    catch_ring.self_modulate = enemy_colors[0]

func set_number(num: int):
    score = num
    number.text = str(num)

func set_weapon_enabled(state: bool):
    has_weapon = state
    catch_ring.self_modulate = Color(1, 0.94, 0.34, 1) if state else Color.WHITE

# Magnet Boots: scales the catch body so the ball is caught from farther away.
func set_catch_scale(factor: float):
    body.scale = Vector2.ONE * factor

func make_elite():
    elite_enemy = true
    scale = Vector2.ONE * 1.08
    catch_ring.self_modulate = Color(0.93, 0.3, 0.3, 1)

func mark_boss(kind: String):
    is_boss = true
    boss_kind = kind
    scale = Vector2.ONE * 1.3
    var c: Color = RunData.BOSS_INFO[kind].color
    catch_ring.self_modulate = c
    sprite.self_modulate = c.darkened(0.35)
    for h in hairs: h.self_modulate = c
    for h in extra_hairs: h.self_modulate = c

func step():
    await get_tree().create_timer(0.25).timeout
    if not SoundEffects.singleton: return
    if randf() < 0.5: Effects.singleton.add(3, global_position)
    SoundEffects.singleton.add(18, global_position, randf_range(0.25, 0.5))

func kick(left: bool):
    SoundEffects.singleton.add(2, global_position, 2)
    SoundEffects.singleton.add(10, global_position)
    Effects.singleton.add(2, global_position)
    anim.play("kick_left" if left else "kick_right")
    await anim.animation_finished
    reset()

func kick_after(left: bool, delay: float):
    await get_tree().create_timer(delay).timeout
    kick(left)

func hop():
    anim.speed_scale = 1.5 * get_anim_speed()
    anim.play("hop")
    Effects.singleton.add(4, global_position)
    SoundEffects.singleton.add(1, global_position)
    SoundEffects.singleton.add(0, global_position)
    await anim.animation_finished
    reset()

func raise():
    anim.play(["raise_left", "raise_right"].pick_random())

func reset():
    anim.speed_scale = get_anim_speed()
    anim.play("idle")

func _process(_delta: float) -> void :
    z_index = roundi(global_position.y)
