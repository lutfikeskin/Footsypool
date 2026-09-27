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
var selecting_relocate_player: = false
var placing_relocate_target: = false
var relocate_player: Dude
var relocate_preview_warn_timer: = 0.0
var preview_pierce: = false

func get_dir() -> Vector2:
    return (line.get_global_mouse_position() - ball.global_position).normalized()

func _process(_delta: float) -> void :
    bounces = 0
    line_len = 0
    line.clear_points()
    main.floating_help.hide()

    if catcher: catcher.catch_ring.hide()
    if selecting_relocate_player or placing_relocate_target:
        for d in main.dudes:
            if d.player:
                d.catch_ring.show()
                d.catch_ring.self_modulate = Color(0.45, 1, 0.55, 1)

    var mp: = line.get_global_mouse_position()
    cursor_ring.visible = (placing and is_inside(mp)) or selecting_weapon_target or selecting_relocate_player or placing_relocate_target
    cursor_cross.visible = not cursor_ring.visible and placing

    cursor.global_position = mp
    update_swap_preview(mp)

    if placing:
        line.add_point(line.to_local(mp))
        line.add_point(line.to_local(main.dudes.back().global_position))

    if kicking:
        preview_pierce = main.ghost_shot_ready
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

    if selecting_relocate_player:
        var selected := get_player_at_pos(mp)
        if selected:
            selected.catch_ring.show()
            main.show_floating_help("Pick teammate", selected.global_position)

    if placing_relocate_target and relocate_player:
        relocate_player.catch_ring.show()
        main.show_floating_help("Set new position", mp)

# Preview mirrors Ball.bounce exactly: same raycast, same wind, same pass-through rules.
func add_bounce(from: Vector2, dir: Vector2):
    var caps: = main.get_preview_caps()
    var result = get_hit(from, dir, bounces > 0, bounces + 1, preview_pierce)
    for p in result.get("passed", []):
        if p.kind == "pierce":
            preview_pierce = false
    if result.has("hit") and bounces < caps.bounces:
        line_len += from.distance_to(result.hit)
        line.add_point(line.to_local(result.hit))
        line.add_point(line.to_local(result.hit))
        bounces += 1
        if not result.goal and not result.catcher and line_len < caps.length:
            add_bounce(result.hit, main.apply_wind(reflect(dir, result.normal)))
        if result.catcher:
            catcher = result.catcher
            catcher.catch_ring.show()
            if catcher.touched and main.level < 5 and not main.safe_pass_available:
                main.show_floating_help("Double touches\nare punished", catcher.global_position)

func reflect(dir: Vector2, normal: Vector2) -> Vector2:
    return dir - 2 * dir.dot(normal) * normal

func pass_ball(include_enemies: bool):
    current = main.get_closest(ball.global_position, include_enemies)
    if not current:
        main.bad("NO TARGET!", ball.global_position)
        main.reset_multi()
        main.failed()
        return
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
    if current and current.player:
        main.on_aim_start(current)

func cancel_all_modes():
    main.end_boss_fog_for_aim()
    placing = false
    kicking = false
    selecting_weapon_shooter = false
    selecting_weapon_target = false
    selecting_relocate_player = false
    placing_relocate_target = false
    relocate_player = null
    line.hide()
    main.floating_help.hide()
    for d in main.dudes:
        if d.player:
            d.catch_ring.hide()
            d.catch_ring.self_modulate = Color(1, 0.94, 0.34, 1) if d.has_weapon else Color.WHITE
    reset_swap_preview()

func start_weapon_phase():
    if main.weapon_shots_left <= 0:
        return
    if main.get_enemies().is_empty():
        return
    cancel_all_modes()
    selecting_weapon_shooter = true
    line.hide()
    main.show_help("Choose a (shooter)", "(Click) an enemy to fire, (right click) to skip")

func start_relocate_phase():
    if main.relocate_charges <= 0:
        return
    cancel_all_modes()
    selecting_relocate_player = true
    line.hide()
    main.show_help("Playmaker ready", "Pick a (teammate) to move, (right click) to skip")

func is_inside(pos: Vector2) -> bool:
    return Geometry2D.is_point_in_polygon(pos, field.polygon)

func _input(event: InputEvent) -> void :
    if not (event is InputEventMouseButton and event.is_pressed()):
        return
    if main.is_interaction_blocked():
        return
    if not main.started:
        return

    var mp: = get_global_mouse_position()

    if main.menu.open or main.buttons.any( func(b: Button): return b.is_hovered()):
        if main.menu.open and is_inside(mp):
            main.menu.toggle()
        return

    if event.button_index == MOUSE_BUTTON_RIGHT:
        if selecting_relocate_player or placing_relocate_target:
            main.skip_relocate()
        elif selecting_weapon_shooter or selecting_weapon_target:
            main.skip_weapon()
        return
    if event.button_index != MOUSE_BUTTON_LEFT:
        return

    if placing_relocate_target:
        if not is_inside(mp):
            return
        if get_closest_player_distance(mp, relocate_player) < 75 or not main.is_point_free(mp, 45.0):
            main.bad("TOO CLOSE!" if main.is_point_free(mp, 45.0) else "BLOCKED!", mp)
            relocate_preview_warn_timer = 0.22
            return
        if not main.consume_relocate_charge():
            cancel_all_modes()
            main.resume_after_relocate()
            return
        await relocate_selected(mp)
        cancel_all_modes()
        main.resume_after_relocate()
        return
    if selecting_relocate_player:
        var p := get_player_at_pos(mp)
        if not p:
            return
        relocate_player = p
        selecting_relocate_player = false
        placing_relocate_target = true
        main.show_help("Playmaker ready", "Click a new (field) position")
        return
    if placing:
        main.has_moved = true
        if not is_inside(mp):
            return
        if not main.is_point_free(mp, 45.0):
            main.bad("BLOCKED!", mp)
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
        main.refresh_hud()
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
        ball.pierce_armed = main.ghost_shot_ready
        main.on_player_kick()
        if current:
            current.looker.ignore_target = false
            current.kick(d.x < 0)
            main.wait_and_shake(0.15)
        await get_tree().create_timer(0.1).timeout
        ball.kick(d)
        main.end_boss_fog_for_aim()
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
    if not is_instance_valid(enemy):
        return
    var hit_chance := main.get_weapon_hit_chance()
    if enemy.elite_enemy:
        hit_chance -= 0.1
    if randf() <= hit_chance:
        main.kill_enemy(enemy, enemy.global_position)
    else:
        main.bad("MISSED SHOT!", enemy.global_position)

# The freshly spawned bench player (dudes.back()) is placed by the normal flow, not by Playmaker.
func get_player_at_pos(pos: Vector2) -> Dude:
    for d in main.dudes:
        if d == main.dudes.back():
            continue
        if d.player and d.global_position.distance_to(pos) < 55:
            return d
    return null

func relocate_selected(target: Vector2):
    if not relocate_player:
        return
    relocate_player.move_to(target)
    SoundEffects.singleton.add(3, target)
    Effects.singleton.pop("[wave]RELOCATE![/wave]", target)
    await relocate_player.moved

func update_swap_preview(mp: Vector2):
    if not swap_preview_ring:
        return
    var active: = placing_relocate_target
    if not active:
        reset_swap_preview()
        return
    swap_preview_ring.show()
    swap_preview_ring.global_position = mp
    if relocate_preview_warn_timer > 0:
        relocate_preview_warn_timer = maxf(0.0, relocate_preview_warn_timer - get_process_delta_time())
        swap_preview_ring.self_modulate = Color(1, 0.28, 0.28, 0.95)
        return
    if not is_inside(mp) or not main.is_point_free(mp, 45.0):
        swap_preview_ring.self_modulate = Color(1, 0.35, 0.35, 0.85)
        return
    if get_closest_player_distance(mp, relocate_player) < 75:
        swap_preview_ring.self_modulate = Color(1, 0.55, 0.3, 0.9)
        return
    swap_preview_ring.self_modulate = Color(0.45, 1, 0.55, 0.9)

func reset_swap_preview():
    if not swap_preview_ring:
        return
    relocate_preview_warn_timer = 0.0
    swap_preview_ring.hide()
    swap_preview_ring.self_modulate = Color(0.45, 1, 0.55, 0.9)

func get_closest_player_distance(pos: Vector2, ignore: Dude = null) -> float:
    var closest: = INF
    for d in main.dudes:
        if not d.player:
            continue
        if d == ignore:
            continue
        closest = minf(closest, pos.distance_to(d.global_position))
    return closest

# Raycast one ball segment. `segment` is 1-based (matches Ball.bounces).
# Enemies the ball passes through (Ghost Shot pierce, Bank Shot Hunter kill) are
# listed in result.passed and excluded from the ray so the segment continues past them.
func get_hit(from: Vector2, dir: Vector2, can_catch: bool, segment: int = 1, pierce_armed: bool = false) -> Dictionary:
    var space_state = get_world_2d().direct_space_state
    var exclude: Array[RID] = []
    var passed: Array = []
    for _i in 4:
        var query = PhysicsRayQueryParameters2D.create(from, from + dir * 1500)
        query.exclude = exclude
        var result: = space_state.intersect_ray(query)
        if not result.has("position"):
            return result
        result.set("hit", result.position.move_toward(from, 10))
        result.set("goal", result.has("collider") and result.collider.name == "Goal")
        result.set("catcher", null)
        result.set("passed", passed)
        if result.collider is Catcher:
            var dude: Dude = result.collider.dude
            if not dude.player:
                if pierce_armed:
                    pierce_armed = false
                    passed.push_back({"dude": dude, "kind": "pierce"})
                    exclude.push_back(result.rid)
                    continue
                if main.has_upgrade("bank_kill") and segment > 3:
                    passed.push_back({"dude": dude, "kind": "kill"})
                    exclude.push_back(result.rid)
                    continue
            if can_catch or not dude.player:
                result.set("catcher", dude)
        return result
    return {}
