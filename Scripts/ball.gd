class_name Ball extends Node2D

@export var kicker: Kicker
@export var main: Main
@export var sprite: Node2D

var bounces: = 0
var pierce_armed: = false

func kick(dir: Vector2):
    bounces = 0
    bounce(dir)

func bad_sound(pos: Vector2):
    SoundEffects.singleton.add(15, pos)
    await get_tree().create_timer(0.2).timeout
    SoundEffects.singleton.add(16, pos)

func bounce(dir: Vector2):
    bounces += 1
    var result: = kicker.get_hit(global_position, dir, true, bounces, pierce_armed)
    if not result.has("position"):
        return

    # Enemies the ball passes through on this segment (Ghost Shot / Bank Shot Hunter).
    for passed in result.get("passed", []):
        var target: Dude = passed.dude
        if not is_instance_valid(target):
            continue
        if passed.kind == "pierce":
            pierce_armed = false
            main.ghost_shot_ready = false
            Effects.singleton.pop("[wave]PIERCE![/wave]", target.global_position + Vector2.UP * 40)
            SoundEffects.singleton.add(10, target.global_position, 1.4)
        else:
            Effects.singleton.pop("[wave]BANK KILL![/wave]", target.global_position + Vector2.UP * 80)
            main.kill_enemy(target, target.global_position)

    var catcher: Dude = result.catcher
    var caught: bool = catcher != null and (bounces > 1 or not catcher.player)
    var pos: Vector2 = catcher.global_position if caught else result.hit
    var duration: = pos.distance_to(global_position) * 0.0005 / (maxi(bounces, 4) * 0.15)
    if catcher and not caught and not catcher.touched:
        main.add_score(roundi(catcher.score * (main.level + 1) * 10), pos)
        catcher.kick_after(dir.x > 0, duration * 0.8)
    var spot: = (pos + global_position) * 0.5
    if kicker.is_inside(spot):
        main.spots.push_back(spot)
    get_tree().create_tween().tween_property(self, "position", pos, duration).set_trans(Tween.TRANS_QUAD)
    get_tree().create_tween().tween_property(sprite, "rotation_degrees", randf_range(0, 360), duration).set_trans(Tween.TRANS_BOUNCE)
    await get_tree().create_timer(duration * 0.6).timeout
    if catcher and not caught:
        catcher.kick(global_position.x < catcher.global_position.x)
    await get_tree().create_timer(duration * 0.4).timeout

    if caught:
        main.cam.shake(3, 0.1)
        catcher.hop()
        if catcher.player:
            if catcher.touched:
                if main.consume_safe_pass():
                    Effects.singleton.pop("[wave]SAFE PASS![/wave]", pos + Vector2.UP * 40)
                    SoundEffects.singleton.add(11, pos, 1.2)
                else:
                    main.bad("DOUBLE TOUCH!", pos)
                    bad_sound(pos)
                    main.reset_multi()
                    if not main.has_upgrade("tough_skin"):
                        main.halve_score()
            else:
                main.add_score(roundi(catcher.score * (main.level + 1) * 10), pos)
            kicker.current = catcher
            kicker.enable_kick()
            catcher.touched = true
            main.raise_hands()
        else:
            main.bad("LOST THE BALL!", pos)
            main.reset_multi()
            main.failed()
            bad_sound(pos)
        return

    if result.goal:
        SoundEffects.singleton.add(5, global_position, 1.3)
        SoundEffects.singleton.add(6, global_position)
        SoundEffects.singleton.add(11, global_position, 1.5)
        Effects.singleton.pop("[wave][font_size=90]GOAL!", pos)
        Effects.singleton.add(2, global_position)
        main.pitch_music(1.3)
        main.burst.global_position = global_position
        main.burst.play()
        main.cam.shake(20, 0.4)
        var scorer: Dude = kicker.current
        await main.next_level()
        await get_tree().create_timer(0.3).timeout
        if is_instance_valid(scorer):
            scorer.hop()
        return

    if result.collider is Obstacle and (result.collider as Obstacle).bumper:
        main.bump_bonus(pos)

    if can_continue():
        main.pop_multi(pos)
        main.cam.shake(3, 0.1)
        main.on_ball_bounced()
        bounce(main.apply_wind(kicker.reflect(dir, result.normal)))
    else:
        await get_tree().create_timer(0.4).timeout
        main.bad("DROPPED THE BALL!", pos)
        main.reset_multi()
        bad_sound(pos)
        main.failed()
        return

    Effects.singleton.add(1, global_position)
    Effects.singleton.add(2, global_position)
    SoundEffects.singleton.add(7, global_position, 0.5)
    SoundEffects.singleton.add(8, global_position, 0.5)
    SoundEffects.singleton.add(9, global_position, 1)
    SoundEffects.singleton.add(10, global_position)

func can_continue() -> bool:
    return bounces < main.get_max_bounces()

func _process(_delta: float) -> void :
    z_index = roundi(global_position.y)
