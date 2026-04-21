class_name Ball extends Node2D

@export var kicker: Kicker
@export var main: Main
@export var sprite: Node2D

var bounces: = 0
var pierce_first_enemy: = false

func kick(dir: Vector2):
    bounces = 0
    bounce(dir)

func bad_sound(pos: Vector2):
    SoundEffects.singleton.add(15, pos)
    await get_tree().create_timer(0.2).timeout
    SoundEffects.singleton.add(16, pos)

func bounce(dir: Vector2):
    bounces += 1
    var result: = kicker.get_hit(global_position, dir, true)
    if result.has("position"):
        var can_bank_kill: bool = main.bank_kill_carry_active and result.catcher and is_instance_valid(result.catcher) and not result.catcher.player and bounces > 1
        if can_bank_kill:
            var enemy: Dude = result.catcher
            if is_instance_valid(enemy):
                var kill_pos: Vector2 = enemy.global_position
                main.kill_enemy(enemy, kill_pos)
                result.catcher = null
                result.hit = kill_pos
        var can_pierce: bool = pierce_first_enemy and result.catcher and not result.catcher.player and bounces <= 1
        var caught: bool = result.catcher and not can_pierce and (bounces > 1 or not result.catcher.player)
        var pos: Vector2 = result.catcher.global_position if caught else result.hit
        if can_pierce:
            pierce_first_enemy = false
            Effects.singleton.pop("[wave]PIERCE![/wave]", pos + Vector2.UP * 40)
            SoundEffects.singleton.add(10, pos, 1.4)
        var speed_factor: = main.get_ball_speed_factor()
        if main.wet_grass_active:
            speed_factor *= 0.9
        var duration: = pos.distance_to(global_position) * 0.0005 / (maxi(bounces, 4) * 0.15 * speed_factor)
        if result.catcher and not caught and not result.catcher.touched:
            main.add_score(roundi(result.catcher.score * (main.level + 1) * 10), pos)
            result.catcher.kick_after(dir.x > 0, duration * 0.8)
        var spot: = (pos + global_position) * 0.5
        if kicker.is_inside(spot):
            main.spots.push_back(spot)
        get_tree().create_tween().tween_property(self, "position", pos, duration).set_trans(Tween.TRANS_QUAD)
        get_tree().create_tween().tween_property(sprite, "rotation_degrees", randf_range(0, 360), duration).set_trans(Tween.TRANS_BOUNCE)
        await get_tree().create_timer(duration * 0.6).timeout
        if result.catcher and not caught:
            result.catcher.kick(global_position.x < result.catcher.global_position.x)
        await get_tree().create_timer(duration * 0.4).timeout
        if caught:
            main.cam.shake(3, 0.1)
            result.catcher.hop()
            if result.catcher.player:
                if result.catcher.touched:
                    main.bad("DOUBLE TOUCH!", pos)
                    bad_sound(pos)
                    main.reset_multi()
                    main.halve_score()
                else:
                    main.add_score(roundi(result.catcher.score * (main.level + 1) * 10), pos)
                kicker.current = result.catcher
                kicker.enable_kick()
                result.catcher.touched = true
                main.raise_hands()
                main.register_player_catch()
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
            main.next_level()
            await get_tree().create_timer(0.3).timeout
            kicker.current.hop()
            return
        if can_continue():
            main.pop_multi(pos)
            main.cam.shake(3, 0.1)
            bounce(kicker.reflect(dir, result.normal))
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
