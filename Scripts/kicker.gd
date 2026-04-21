class_name Kicker extends Node2D

@export var ball: Ball
@export var line: Line2D
@export var main: Main
@export var field: CollisionPolygon2D
@export var cursor: Node2D
@export var cursor_ring: Node2D
@export var cursor_cross: Node2D
@export var swap_preview_ring: Sprite2D

var bounces: = 0
var placing: = false
var current: Dude
var kicking: = false
var line_len: = 0.0
var catcher: Dude
var selecting_weapon_shooter: = false
var selecting_weapon_target: = false
var weapon_shooter: Dude
var selecting_swap_first: = false
var selecting_swap_second: = false
var swap_placing_first: = false
var swap_placing_second: = false
var first_swap_dude: Dude
var second_swap_dude: Dude
var first_swap_target: Vector2 = Vector2.ZERO
var swap_preview_warn_timer: = 0.0

func get_dir() -> Vector2:
    return (line.get_global_mouse_position() - ball.global_position).normalized()

func _process(_delta: float) -> void :
    bounces = 0
    line_len = 0
    line.clear_points()
    main.floating_help.hide()

    if catcher: catcher.catch_ring.hide()
    if selecting_swap_first or selecting_swap_second or swap_placing_first or swap_placing_second:
        for d in main.dudes:
            if d.player:
                d.catch_ring.show()
                d.catch_ring.self_modulate = Color(0.45, 1, 0.55, 1)

    var mp: = line.get_global_mouse_position()
    cursor_ring.visible = (placing and is_inside(mp)) or selecting_weapon_target or selecting_swap_first or selecting_swap_second or swap_placing_first or swap_placing_second
    cursor_cross.visible = not cursor_ring.visible and placing

    cursor.global_position = mp
    update_swap_preview(mp)

    if placing:
        line.add_point(line.to_local(mp))
        line.add_point(line.to_local(main.dudes.back().global_position))

    if kicking:
        line.add_point(line.to_local(ball.global_position))
        add_bounce(ball.global_position, get_dir())

    if selecting_weapon_shooter:
        var shooter := get_shooter_at_pos(mp)
        if shooter:
            shooter.catch_ring.show()
            main.show_floating_help("Pick shooter", shooter.global_position)

    if selecting_weapon_target:
        var enemy := get_enemy_at_pos(mp)
        if enemy:
            enemy.catch_ring.show()
            main.show_floating_help("Shoot target", enemy.global_position)

    if selecting_swap_first:
        var first := get_player_at_pos(mp)
        if first:
            first.catch_ring.show()
            main.show_floating_help("Pick first teammate", first.global_position)

    if selecting_swap_second:
        var second := get_player_at_pos(mp)
        if second and second != first_swap_dude:
            second.catch_ring.show()
            main.show_floating_help("Pick second teammate", second.global_position)

    if swap_placing_first and first_swap_dude:
        first_swap_dude.catch_ring.show()
        main.show_floating_help("Set first position", mp)

    if swap_placing_second and second_swap_dude:
        second_swap_dude.catch_ring.show()
        main.show_floating_help("Set second position", mp)

func add_bounce(from: Vector2, dir: Vector2):
    var result = get_hit(from, dir, bounces > 0)
    var preview_scale: = main.get_preview_scale()
    var preview_cap: = 3 if main.ghost_shot_active else roundi(5 * preview_scale)
    var max_preview_len: = (520 if main.ghost_shot_active else 820) * preview_scale
    if result.has("hit") and bounces < preview_cap:
        line_len += from.distance_to(result.hit)
        line.add_point(line.to_local(result.hit))
        line.add_point(line.to_local(result.hit))
        bounces += 1
        if not result.goal and not result.catcher and line_len < max_preview_len:
            add_bounce(result.hit, reflect(dir, result.normal))
        if result.catcher:
            catcher = result.catcher
            catcher.catch_ring.show()
            if catcher.touched and main.level < 5:
                main.show_floating_help("Double touches\nare punished", catcher.global_position)

func reflect(dir: Vector2, normal: Vector2) -> Vector2:
    return dir - 2 * dir.dot(normal) * normal

func pass_ball(include_enemies: bool):


    current = main.get_closest(ball.global_position, include_enemies)
    current.toggle_collision(false)
    get_tree().create_tween().tween_property(ball, "position", current.global_position, 0.3).set_trans(Tween.TRANS_BOUNCE)
    current.looker.ignore_target = true
    await get_tree().create_timer(0.3 * 0.5).timeout
    line.show()
    current.hop()
    current.touched = true

    if not main.shown_kick_help:
        main.shown_kick_help = true
        main.show_help("Now (shoot) a (goal)!", "(Bounces) increase the (score) (multiplier)...")

    if current.player:
        main.raise_hands()
    else:
        main.bad("LOST THE BALL!", current.global_position + Vector2.UP * 50)
        main.reset_multi()
        main.failed()

func enable_kick():
    if current and not current.player:
        return
    line.show()
    kicking = true

func cancel_all_modes():
    placing = false
    kicking = false
    selecting_weapon_shooter = false
    selecting_weapon_target = false
    selecting_swap_first = false
    selecting_swap_second = false
    swap_placing_first = false
    swap_placing_second = false
    first_swap_dude = null
    second_swap_dude = null
    first_swap_target = Vector2.ZERO
    line.hide()
    main.floating_help.hide()
    for d in main.dudes:
        if d.player:
            d.catch_ring.hide()
            d.catch_ring.self_modulate = Color(1, 0.94, 0.34, 1) if d.has_weapon else Color.WHITE
    reset_swap_preview()

func start_weapon_phase():
    if not main.weapon_upgrade_active:
        return
    if main.weapon_shots_left <= 0:
        return
    if main.get_enemies().is_empty():
        return
    cancel_all_modes()
    selecting_weapon_shooter = true
    line.hide()
    main.show_help("Choose a (shooter)", "Then (click) an enemy to fire")

func start_swap_phase():
    if not main.swap_positions_active:
        return
    if main.swap_positions_charges <= 0:
        return
    cancel_all_modes()
    selecting_swap_first = true
    line.hide()
    main.show_help("Relocate ready", "Pick (first) teammate")

func is_inside(pos: Vector2) -> bool:
    return Geometry2D.is_point_in_polygon(pos, field.polygon)

func _input(event: InputEvent) -> void :
    if event is InputEventMouseButton and event.is_pressed():
        if main.is_interaction_blocked():
            return
        if not main.started:
            return

        var mp: = get_global_mouse_position()

        if main.menu.open or main.buttons.any( func(b: Button): return b.is_hovered()):
            if main.menu.open and is_inside(mp):
                main.menu.toggle()
            return

        if swap_placing_first:
            if not is_inside(mp):
                return
            first_swap_target = mp
            swap_placing_first = false
            swap_placing_second = true
            main.show_help("Relocate ready", "Place (second) teammate")
            return
        if swap_placing_second:
            if not is_inside(mp):
                return
            if mp.distance_to(first_swap_target) < 80:
                main.bad("TOO CLOSE!", mp)
                swap_preview_warn_timer = 0.22
                return
            if not main.consume_swap_charge():
                cancel_all_modes()
                main.finish_swap_reposition()
                return
            await relocate_selected(first_swap_target, mp)
            cancel_all_modes()
            main.finish_swap_reposition()
            return
        if placing:
            main.has_moved = true
            if not is_inside(mp):
                return
            SoundEffects.singleton.add(3, mp)
            SoundEffects.singleton.add(10, mp)
            main.hide_help()
            placing = false
            main.dudes.back().move_to(mp)
            get_tree().create_tween().tween_property(ball, "position", main.global_position, 0.3).set_trans(Tween.TRANS_BOUNCE)
            await main.dudes.back().moved
            pass_ball(true)
            await get_tree().create_timer(0.5).timeout
            enable_kick()
            return
        if selecting_weapon_shooter:
            var shooter := get_shooter_at_pos(mp)
            if not shooter:
                return
            weapon_shooter = shooter
            selecting_weapon_shooter = false
            selecting_weapon_target = true
            main.hide_help()
            return
        if selecting_swap_first:
            var p1 := get_player_at_pos(mp)
            if not p1:
                return
            first_swap_dude = p1
            selecting_swap_first = false
            selecting_swap_second = true
            main.show_help("Relocate ready", "Pick (second) teammate")
            return
        if selecting_swap_second:
            var p2 := get_player_at_pos(mp)
            if not p2 or p2 == first_swap_dude:
                return
            second_swap_dude = p2
            selecting_swap_second = false
            swap_placing_first = true
            main.show_help("Relocate ready", "Place (first) teammate")
            return
        if selecting_weapon_target:
            var enemy := get_enemy_at_pos(mp)
            if not enemy:
                return
            if not main.consume_weapon_shot():
                cancel_all_modes()
                placing = true
                line.show()
                return
            selecting_weapon_target = false
            fire_weapon(weapon_shooter, enemy)
            await get_tree().create_timer(0.1).timeout
            if main.weapon_shots_left > 0 and main.get_enemies().size() > 0:
                start_weapon_phase()
            else:
                placing = true
                line.show()
            return
        if kicking:
            main.hide_help()
            kicking = false
            line.hide()
            main.lower_hands()
            var d: = get_dir()
            var shot_len: = ball.global_position.distance_to(mp)
            if main.is_aim_penalty_active() and shot_len > 380:
                var miss_angle: = randf_range(-0.16, 0.16)
                d = d.rotated(miss_angle)
            var wind_push: = main.get_wind_strength()
            if wind_push > 0.0:
                d = (d + Vector2.RIGHT * wind_push).normalized()
            if main.ghost_shot_active:
                ball.pierce_first_enemy = true
            if current:
                current.looker.ignore_target = false
                current.kick(d.x < 0)
                main.wait_and_shake(0.15)
            await get_tree().create_timer(0.1).timeout
            ball.kick(d)
        if current:
            await get_tree().create_timer(0.1).timeout
            current.toggle_collision(true)

func get_shooter_at_pos(pos: Vector2) -> Dude:
    var candidates: Array[Dude] = main.get_weapon_candidates()
    for d in candidates:
        if d.global_position.distance_to(pos) < 55:
            return d
    return null

func get_enemy_at_pos(pos: Vector2) -> Dude:
    for d in main.get_enemies():
        if d.global_position.distance_to(pos) < 55:
            return d
    return null

func fire_weapon(shooter: Dude, enemy: Dude):
    if not shooter or not enemy:
        return
    shooter.kick(enemy.global_position.x < shooter.global_position.x)
    Effects.singleton.add(2, shooter.global_position)
    SoundEffects.singleton.add(2, shooter.global_position, 2)
    await get_tree().create_timer(0.08).timeout
    var hit_chance := main.get_weapon_hit_chance()
    if enemy.elite_enemy:
        hit_chance -= 0.08
    if randf() <= hit_chance:
        main.kill_enemy(enemy, enemy.global_position)
    else:
        main.bad("MISSED SHOT!", enemy.global_position)

func get_player_at_pos(pos: Vector2) -> Dude:
    for d in main.dudes:
        if d.player and d.global_position.distance_to(pos) < 55:
            return d
    return null

func relocate_selected(first_target: Vector2, second_target: Vector2):
    if not first_swap_dude or not second_swap_dude:
        return
    first_swap_dude.move_to(first_target)
    second_swap_dude.move_to(second_target)
    SoundEffects.singleton.add(3, first_target)
    SoundEffects.singleton.add(3, second_target)
    Effects.singleton.pop("[wave]REPOSITION![/wave]", (first_target + second_target) * 0.5)
    await get_tree().create_timer(0.35).timeout

func update_swap_preview(mp: Vector2):
    if not swap_preview_ring:
        return
    var active: = swap_placing_first or swap_placing_second
    if not active:
        reset_swap_preview()
        return
    swap_preview_ring.show()
    swap_preview_ring.global_position = mp
    if swap_preview_warn_timer > 0:
        swap_preview_warn_timer = maxf(0.0, swap_preview_warn_timer - get_process_delta_time())
        swap_preview_ring.self_modulate = Color(1, 0.28, 0.28, 0.95)
        return
    if not is_inside(mp):
        swap_preview_ring.self_modulate = Color(1, 0.35, 0.35, 0.85)
        return
    if swap_placing_second and mp.distance_to(first_swap_target) < 80:
        swap_preview_ring.self_modulate = Color(1, 0.55, 0.3, 0.9)
        return
    swap_preview_ring.self_modulate = Color(0.45, 1, 0.55, 0.9)

func reset_swap_preview():
    if not swap_preview_ring:
        return
    swap_preview_warn_timer = 0.0
    swap_preview_ring.hide()
    swap_preview_ring.self_modulate = Color(0.45, 1, 0.55, 0.9)

func get_hit(from: Vector2, dir: Vector2, can_catch: bool) -> Dictionary:
    var space_state = get_world_2d().direct_space_state
    var query = PhysicsRayQueryParameters2D.create(from, from + dir * 1500)
    var result: = space_state.intersect_ray(query)
    if result.has("position"):
        result.set("hit", result.position.move_toward(from, 10))
        result.set("goal", result.has("collider") and result.collider.name == "Goal")
        result.set("catcher", null)
        if result.collider is Catcher and (can_catch or not result.collider.dude.player):
            if result.collider.dude.player and main.consume_safe_pass():
                return result
            result.set("catcher", result.collider.dude)
    return result
