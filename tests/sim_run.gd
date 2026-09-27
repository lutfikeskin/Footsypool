extends SceneTree

# Headless smoke test: drives a full run through the real game flow.
# Run:  godot --headless --path . -s tests/sim_run.gd
# It places the bench player, searches the aim preview for a direct goal path,
# shoots, handles upgrade menus / optional phases, and logs each round.
# Logs go to stderr so they interleave correctly with engine errors.

const TARGET_ROUNDS: = 16
const MAX_SECONDS: = 300.0

var main: Main
var kicker: Kicker
var ball: Ball
var shots: = 0
var goals: = 0
var failures: = 0
var errors: = 0
var logged_level: = -1

func _initialize():
    Engine.time_scale = 4.0
    var scene: = (load("res://Scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    main = scene.get_node("Main")
    kicker = scene.get_node("Kicker")
    ball = scene.get_node("Ball")
    run()

func run():
    await create_timer(1.5).timeout
    main.play()
    await create_timer(1.0).timeout
    var start: = Time.get_ticks_msec()
    var last_lives: = main.lives
    while main.level < TARGET_ROUNDS and not main.game_over:
        if (Time.get_ticks_msec() - start) / 1000.0 > MAX_SECONDS:
            printerr("TIMEOUT: stuck at level %d (placing=%s kicking=%s pending=%s)" % [main.level, kicker.placing, kicker.kicking, main.pending_upgrade])
            errors += 1
            break
        if main.lives < last_lives:
            failures += 1
            var holder: = kicker.current
            printerr("  LIFE LOST at R%02d: holder=%s ball=%s" % [main.level + 1,
                ("player" if holder and holder.player else "enemy") if holder else "none", ball.global_position.round()])
        last_lives = main.lives

        if main.pending_upgrade:
            var pick: = pick_upgrade()
            printerr("  upgrade -> %s" % [main.current_upgrade_choices[pick]])
            main._on_upgrade_button_pressed(pick)
        elif kicker.selecting_relocate_player or kicker.placing_relocate_target:
            printerr("  relocate skipped")
            main.skip_relocate()
        elif kicker.selecting_weapon_shooter or kicker.selecting_weapon_target:
            await use_weapon()
        elif kicker.placing:
            if main.level != logged_level:
                logged_level = main.level
                log_round()
            await place_bench_player()
        elif kicker.kicking:
            await shoot()
        await create_timer(0.15).timeout

    printerr("")
    printerr("=== RESULT: rounds=%d stage=%d lives=%d game_over=%s shots=%d goals=%d failures=%d errors=%d" % [main.level, main.get_stage(), main.lives, main.game_over, shots, goals, failures, errors])
    printerr("=== upgrades: %s" % [main.upgrades])
    await create_timer(0.5).timeout
    quit(1 if errors > 0 else 0)

func log_round():
    var boss: = main.get_boss_name() if main.boss_id != "" else "-"
    printerr("R%02d stage=%d layout=%s weather=%s boss=%s enemies=%d players=%d obstacles=%d lives=%d multi=%d maxb=%d" % [
        main.level + 1, main.get_stage(), main.layout_id, main.weather, boss,
        main.get_enemies().size(), main.get_players().size(), main.obstacles.size(),
        main.lives, main.multi, main.get_max_bounces()])

func pick_upgrade() -> int:
    # Prefer the stackable/safe stuff first so more code paths get exercised.
    var order: = ["weapon_system", "ghost_shot", "bank_kill", "magnet_boots", "relocate", "wide_goal", "ricochet_master", "scout", "big_team", "extra_life"]
    for want in order:
        var idx: = main.current_upgrade_choices.find(want)
        if idx >= 0:
            return idx
    return 0

# Like a careful player: put the bench player inside the field as close to the ball as allowed.
func place_bench_player():
    var bench: Dude = main.dudes.back()
    var ball_pos: = main.global_position
    var best: = Vector2.ZERO
    var best_dist: = INF
    for _i in 120:
        var cand: = Vector2(966 + randf_range(-220, 220), randf_range(640, 820))
        if not kicker.is_inside(cand): continue
        if not main.is_point_free(cand, 45.0): continue
        if main._min_dist_to_any_dude(cand, bench) < 70.0: continue
        var dist: = cand.distance_to(ball_pos)
        if dist < best_dist:
            best_dist = dist
            best = cand
    if best == Vector2.ZERO:
        best = Vector2(966, 780)
    var closest_enemy: = INF
    for d in main.dudes:
        if not d.player:
            closest_enemy = minf(closest_enemy, d.global_position.distance_to(ball_pos))
    if closest_enemy < best_dist:
        printerr("  WARNING: enemy closer to kick-off (%.0f) than best placement (%.0f)" % [closest_enemy, best_dist])
    # Mirror of Kicker._input placing branch.
    main.has_moved = true
    main.hide_help()
    kicker.placing = false
    bench.move_to(best)
    create_tween().tween_property(ball, "position", main.global_position, 0.3)
    await bench.moved
    kicker.pass_ball(true)
    await create_timer(0.5).timeout
    kicker.enable_kick()

func use_weapon():
    var shooters: = main.get_weapon_candidates()
    var enemies: = main.get_enemies()
    if shooters.is_empty() or enemies.is_empty():
        main.skip_weapon()
        return
    kicker.weapon_shooter = shooters.front()
    kicker.selecting_weapon_shooter = false
    kicker.selecting_weapon_target = false
    if not main.consume_weapon_shot():
        main.skip_weapon()
        return
    var target: Dude = main.boss_unit if main.boss_unit and is_instance_valid(main.boss_unit) else enemies.front()
    printerr("  weapon fire at %s" % ["BOSS" if target == main.boss_unit else "enemy"])
    kicker.fire_weapon(kicker.weapon_shooter, target)
    await create_timer(0.3).timeout
    if main.weapon_shots_left > 0 and main.get_enemies().size() > 0:
        kicker.start_weapon_phase()
    else:
        kicker.placing = true
        kicker.line.show()

func shoot():
    var d: = find_goal_dir()
    shots += 1
    # Mirror of Kicker._input kicking branch.
    main.hide_help()
    kicker.kicking = false
    kicker.line.hide()
    main.lower_hands()
    ball.pierce_armed = main.ghost_shot_ready
    main.on_player_kick()
    var level_before: = main.level
    if kicker.current:
        kicker.current.looker.ignore_target = false
        kicker.current.kick(d.x < 0)
    await create_timer(0.1).timeout
    ball.kick(d)
    main.end_boss_fog_for_aim()
    await create_timer(0.1).timeout
    if kicker.current:
        kicker.current.toggle_collision(true)
    # wait until the shot resolves: aim re-enabled, placing (new round), upgrade, or game over
    var waited: = 0.0
    while not (kicker.kicking or kicker.placing or main.pending_upgrade or main.game_over or kicker.selecting_relocate_player or kicker.selecting_weapon_shooter):
        await create_timer(0.1).timeout
        waited += 0.1
        if waited > 40.0:
            printerr("  shot never resolved")
            errors += 1
            return
    if main.level > level_before:
        goals += 1

func find_goal_dir() -> Vector2:
    var best: = Vector2.UP
    var best_segments: = 999
    var found: = false
    for deg in range(-80, 81, 2):
        var dir: = Vector2.UP.rotated(deg_to_rad(deg))
        var segs: = simulate(dir)
        if segs > 0 and segs < best_segments:
            best_segments = segs
            best = dir
            found = true
    if not found:
        printerr("  no goal path found, shooting blind")
    return best

# Uses the same raycast as the preview and the ball. Returns segment count on goal, 0 otherwise.
func simulate(dir: Vector2) -> int:
    var from: = ball.global_position
    var d: = dir
    var seg: = 1
    var pierce: = main.ghost_shot_ready
    while seg <= main.get_max_bounces():
        var r: = kicker.get_hit(from, d, true, seg, pierce)
        if not r.has("position"):
            return 0
        for p in r.get("passed", []):
            if p.kind == "pierce":
                pierce = false
        if r.catcher:
            return 0
        if r.goal:
            return seg
        from = r.hit
        d = main.apply_wind(kicker.reflect(d, r.normal))
        seg += 1
    return 0
