class_name Main extends Node2D

@export var kicker: Kicker
@export var dude_prefab: PackedScene
@export var ball: Ball
@export var cam: Camera
@export var multi_label: RichTextLabel
@export var score_label: RichTextLabel
@export var goal_score_label: RichTextLabel
@export var round_label: RichTextLabel
@export var status_label: RichTextLabel
@export var buttons: Array[Button]
@export var menu: OptionsMenu
@export var appearers: Array[Appearer]
@export var floating_help: RichTextLabel
@export var burst: Burst
@export var hide_on_start: Array[Node]
@export var start_stuff: Array[Appearer]
@export var music: AudioStreamPlayer
@export var upgrade_wrap: Control
@export var upgrade_buttons: Array[Button]
@export var upgrade_title: RichTextLabel
@export var obstacle_root: Node2D
@export var field_sprite: Sprite2D
@export var goal_posts: Array[Node2D]
# Enemies never spawn this close to the ball's kick-off spot, so the placement pass can be kept safe.
@export var enemy_spawn_keepout: float = 230.0

const ROUNDS_PER_STAGE: = 5
const UPGRADE_EVERY: = 2
const MAX_LIVES: = 3
const MAX_ENEMIES: = 14
const UPGRADE_CHOICES: = 3
const RUN_COMPLETE_STAGES: = 3

# run state
var dudes: Array[Dude] = []
var spots: Array[Vector2] = []
var player_count: = 0
var enemy_count: = 0
var multi: = 1
var score: = 100
var level: = 0
var total_score: = 0
var shown_score: = 0
var lives: = 1
var game_over: = false
var shown_kick_help: = false
var shown_opponent_help: = false
var has_moved: = false
var started: = false

# upgrades: id -> level
var upgrades: Dictionary = {}
var pending_upgrade: = false
var current_upgrade_choices: Array[String] = []

# per-round resources
var weapon_shots_left: = 0
var safe_pass_available: = false
var relocate_charges: = 0
var ghost_shot_ready: = false

# stage: arena + weather
var layout_id: = "open"
var weather: Array[String] = []
var wind_dir: = Vector2.RIGHT
var obstacles: Array[Obstacle] = []

# boss
var boss_id: = ""
var boss_unit: Dude
var _keeper_posts: Array[Obstacle] = []
var _boss_fog_active: = false
var _boss_fog_saved_visible: Dictionary = {}

func _ready() -> void :
    var p: = cam.global_position
    cam.global_position += Vector2.UP * 200
    cam.zoom = Vector2.ONE * 0.8
    get_tree().create_tween().tween_property(cam, "global_position", p, 1).set_trans(Tween.TRANS_SPRING)
    get_tree().create_tween().tween_property(cam, "zoom", Vector2.ONE, 1).set_trans(Tween.TRANS_SPRING)
    for idx in upgrade_buttons.size():
        upgrade_buttons[idx].pressed.connect(_on_upgrade_button_pressed.bind(idx))
    upgrade_wrap.hide()
    for hh in hide_on_start: hh.hide()
    kicker.line.hide()
    add_dude(true, get_start_pos())
    refresh_hud()
    await dudes.back().moved

func pan_off():
    get_tree().create_tween().tween_property(cam, "global_position", cam.global_position + Vector2.UP * 300, 0.3).set_trans(Tween.TRANS_SPRING)
    get_tree().create_tween().tween_property(cam, "zoom", Vector2.ONE * 0.8, 0.3).set_trans(Tween.TRANS_SPRING)

func play():
    cam.shake(5, 0.15)
    kicker.line.show()
    kicker.placing = true
    for ss in start_stuff:
        ss.disappear()
    started = true
    for hh in hide_on_start: hh.show()
    reset_round_resources()
    refresh_hud()
    if has_moved: return
    await get_tree().create_timer(0.5).timeout
    show_help("(Move) the (player) to the (field)!", "(Click) on the (spot) you desire...")

func _process(_delta: float) -> void :
    var diff: = maxi(roundi(absi(score - shown_score) * 0.2), 5)
    shown_score = roundi(move_toward(shown_score, score, diff))
    goal_score_label.text = Utils.as_score(shown_score)

func hide_help():
    appearers[0].disappear(0.15)
    appearers[1].disappear()

func show_floating_help(text: String, pos: Vector2):
    floating_help.global_position = pos + Vector2.UP * 120 - 0.5 * floating_help.size
    floating_help.text = Utils.as_wavy(text)
    floating_help.show()

func show_help(first: String, second: String):
    appearers[0].show_with_text(Utils.as_wavy(mark(first)))
    appearers[1].show_with_text(Utils.as_wavy(mark(second)), 0.2)
    pitch_music(1.1)
    SoundEffects.singleton.add(17, global_position, 0.8)

func mark(text: String):
    return Utils.colorize(text, "#FFA69E")

# ---------------------------------------------------------------- run structure

func get_stage() -> int:
    return floori(level / float(ROUNDS_PER_STAGE)) + 1

func round_in_stage() -> int:
    return level % ROUNDS_PER_STAGE

func is_boss_round() -> bool:
    return round_in_stage() == ROUNDS_PER_STAGE - 1

func has_weather(id: String) -> bool:
    return weather.has(id)

func has_upgrade(id: String) -> bool:
    return upgrade_level(id) > 0

func upgrade_level(id: String) -> int:
    return upgrades.get(id, 0)

func life_cap() -> int:
    return 1 if has_upgrade("glass_cannon") else MAX_LIVES

func boss_active(id: String) -> bool:
    return boss_id == id and boss_unit != null and is_instance_valid(boss_unit)

func get_boss_name() -> String:
    return RunData.BOSS_INFO[boss_id].name if boss_id != "" else ""

func next_level():
    var goal_bounces: = ball.bounces
    var boss_beaten: = boss_id != ""
    var goal_factor: = get_goal_factor(goal_bounces)
    var earned: = roundi(score * goal_factor)
    total_score += earned
    score_label.text = "%s " % [Utils.as_score(total_score)]
    var bonus_text: = ""
    if goal_factor != 1.0:
        bonus_text = " [font_size=36]x%.1f[/font_size]" % [goal_factor]
    Effects.singleton.pop("[wave][font_size=60]+%s%s[/font_size][/wave]" % [Utils.as_score(earned), bonus_text], ball.global_position + Vector2.DOWN * 60)
    shown_score = 0
    score = 0
    level += 1
    kicker.line.hide()
    end_boss_round()

    if boss_beaten:
        await get_tree().create_timer(0.6).timeout
        lives = mini(lives + 1, life_cap())
        Effects.singleton.pop("[wave][font_size=70]BOSS DEFEATED!", get_start_pos() + Vector2.UP * 300)
        SoundEffects.singleton.add(5, get_start_pos(), 1.2)
        cam.shake(12, 0.3)
        if level == RUN_COMPLETE_STAGES * ROUNDS_PER_STAGE:
            await get_tree().create_timer(0.8).timeout
            Effects.singleton.pop("[wave][font_size=50]RUN COMPLETE! Endless mode...", get_start_pos() + Vector2.UP * 380)
        refresh_hud()

    var new_stage: = round_in_stage() == 0
    if new_stage:
        start_stage()

    if boss_beaten:
        offer_upgrade(true)
    elif level % UPGRADE_EVERY == 0:
        offer_upgrade(false)
    await wait_upgrade_done()
    await get_tree().create_timer(0.5).timeout

    spawn_round_enemies()
    if is_boss_round():
        begin_boss_round()
    if has_upgrade("big_team"):
        var extra_pos: = random_point_in_field(90.0, 120.0)
        if extra_pos != Vector2.ZERO:
            add_dude(true, extra_pos)
    # Bench player must be spawned last: placement moves dudes.back().
    add_dude(true, get_start_pos())
    # Everyone settles before placement opens, so the pass after placing cannot be stolen
    # by an enemy that is still running in.
    await wait_for_dudes_settled()
    reset_round_resources()
    spots.clear()
    for d in dudes: d.touched = false
    round_label.text = " Round %d" % [(level + 1)]
    begin_player_phase()
    await get_tree().create_timer(0.5).timeout
    if has_upgrade("chaos"):
        multi += 3
        multi_label.text = "x%d " % [multi]
    score = 100 * (level + 1) * multi
    announce_round(new_stage)
    refresh_hud()

func announce_round(new_stage: bool):
    if new_stage:
        var layout_name: String = RunData.LAYOUTS[layout_id].name
        var parts: Array[String] = []
        for w in weather:
            parts.push_back("(%s): %s" % [RunData.WEATHERS[w].name, RunData.WEATHERS[w].desc])
        var second: = "Clear skies. Enemies come back fresh..." if parts.is_empty() else " | ".join(parts)
        show_help("Stage %d: (%s)" % [get_stage(), layout_name], second)
    elif is_boss_round() and boss_id != "":
        show_help("Boss: (%s)" % [get_boss_name()], "%s. (Kill) it to stop it!" % [RunData.BOSS_INFO[boss_id].desc])
    elif not shown_opponent_help:
        shown_opponent_help = true
        show_help("Don't let (them) get the (ball)!", "How long can you (survive) and (score)...")

func begin_player_phase():
    if relocate_charges > 0 and get_players().size() > 1:
        kicker.start_relocate_phase()
    elif weapon_shots_left > 0 and not get_enemies().is_empty():
        kicker.start_weapon_phase()
    else:
        kicker.placing = true
        kicker.line.show()

func resume_after_relocate():
    if weapon_shots_left > 0 and not get_enemies().is_empty():
        kicker.start_weapon_phase()
    else:
        kicker.placing = true
        kicker.line.show()

func skip_relocate():
    relocate_charges = 0
    kicker.cancel_all_modes()
    resume_after_relocate()
    refresh_hud()

func skip_weapon():
    weapon_shots_left = 0
    kicker.cancel_all_modes()
    kicker.placing = true
    kicker.line.show()
    refresh_hud()

func reset_round_resources():
    weapon_shots_left = 0
    if has_upgrade("weapon_system"):
        weapon_shots_left = 1 + upgrade_level("quick_reload") + (2 if has_upgrade("glass_cannon") else 0)
    safe_pass_available = has_upgrade("safe_pass")
    relocate_charges = 1 if has_upgrade("relocate") else 0
    ghost_shot_ready = has_upgrade("ghost_shot")

# ---------------------------------------------------------------- stage: arena + weather

func start_stage():
    for e in get_enemies():
        remove_dude(e)
    boss_unit = null
    clear_layout()
    var stage: = get_stage()
    if stage == 1:
        layout_id = "open"
    else:
        var ids: Array = RunData.LAYOUTS.keys().filter(func(k): return k != layout_id and k != "open")
        layout_id = ids.pick_random()
    for cfg in RunData.LAYOUTS[layout_id].obstacles:
        spawn_obstacle(cfg)
    weather.clear()
    var count: = 0 if stage == 1 else (1 if stage < 4 else 2)
    var pool: Array = RunData.WEATHERS.keys().duplicate()
    for _i in count:
        if pool.is_empty(): break
        var w: String = pool.pick_random()
        pool.erase(w)
        weather.push_back(w)
    wind_dir = Vector2.RIGHT if randf() < 0.5 else Vector2.LEFT
    apply_weather_visuals()

func apply_weather_visuals():
    if not field_sprite: return
    var tint: = Color.WHITE
    for w in weather:
        tint *= RunData.WEATHERS[w].tint
    get_tree().create_tween().tween_property(field_sprite, "modulate", tint, 0.8)

func spawn_obstacle(cfg: Dictionary) -> Obstacle:
    var o: = Obstacle.new()
    obstacle_root.add_child(o)
    o.setup(cfg)
    obstacles.push_back(o)
    return o

func clear_layout():
    for o in obstacles:
        if is_instance_valid(o):
            o.queue_free()
    obstacles.clear()
    _keeper_posts.clear()

func is_point_free(p: Vector2, margin: float) -> bool:
    for o in obstacles:
        if not is_instance_valid(o): continue
        if p.distance_to(o.global_position) < o.clearance_radius() + margin:
            return false
    return true

func apply_wind(dir: Vector2) -> Vector2:
    if not has_weather("wind"):
        return dir
    return (dir + wind_dir * 0.2).normalized()

func get_preview_caps() -> Dictionary:
    var b: = 5
    var length: = 820.0
    if has_weather("fog"):
        b = 2
        length = 480.0
    if boss_active("blind"):
        b = 1
        length = 600.0
    var scout: = upgrade_level("scout")
    b += scout
    length += 150.0 * scout
    return {"bounces": b, "length": length}

func get_max_bounces() -> int:
    var b: = 10 + upgrade_level("ricochet_master")
    if has_weather("wet"): b -= 2
    if has_upgrade("greed"): b -= 2
    return maxi(b, 4)

func get_goal_factor(bounces: int) -> float:
    var factor: = 1.0
    if has_upgrade("banker") and bounces >= 4:
        factor += 0.5
    if has_upgrade("greed"):
        factor *= 1.6
    return factor

func bump_bonus(pos: Vector2):
    multi += 1
    multi_label.text = "x%d " % [multi]
    Effects.singleton.pop("[wave]BUMP! +1[/wave]", pos + Vector2.UP * 30)
    SoundEffects.singleton.add(3, pos, 1.2)

# ---------------------------------------------------------------- bosses

func begin_boss_round():
    boss_id = RunData.BOSSES[(get_stage() - 1) % RunData.BOSSES.size()]
    var pos: Vector2
    if boss_id == "keeper":
        for cfg in RunData.KEEPER_POSTS:
            _keeper_posts.push_back(spawn_obstacle(cfg))
        pos = RunData.KEEPER_HOME
    else:
        pos = pick_enemy_spawn()
    add_dude(false, pos, true)
    boss_unit = dudes.back()
    boss_unit.mark_boss(boss_id)

func end_boss_round():
    end_boss_fog_for_aim()
    if boss_unit and is_instance_valid(boss_unit):
        remove_dude(boss_unit)
    boss_unit = null
    boss_id = ""
    for o in _keeper_posts:
        if is_instance_valid(o):
            obstacles.erase(o)
            o.queue_free()
    _keeper_posts.clear()

func on_aim_start(holder: Dude):
    if boss_active("blind"):
        begin_boss_fog_for_aim(holder)
    if boss_active("keeper"):
        boss_unit.move_to(Vector2(randf_range(RunData.KEEPER_X_MIN, RunData.KEEPER_X_MAX), RunData.KEEPER_HOME.y))

func on_player_kick():
    if boss_active("sniper"):
        snipe_teammate()

func on_ball_bounced():
    if boss_active("shifter"):
        var dest: = random_point_in_field(80.0, 160.0)
        if dest != Vector2.ZERO:
            boss_unit.move_to(dest)

func snipe_teammate():
    var holder: Dude = kicker.current
    var players: = get_players()
    if players.size() <= 2:
        return
    var candidates: = players.filter(func(d: Dude): return d != holder)
    if candidates.is_empty():
        return
    var victim: Dude = candidates.pick_random()
    bad("SNIPED!", victim.global_position + Vector2.UP * 50)
    SoundEffects.singleton.add(6, victim.global_position, 1.0)
    Effects.singleton.add(2, victim.global_position)
    remove_dude(victim)
    refresh_hud()

func begin_boss_fog_for_aim(holder: Dude) -> void :
    if _boss_fog_active:
        return
    _boss_fog_active = true
    _boss_fog_saved_visible.clear()
    var root: Node = get_parent()
    var items: Array[CanvasItem] = []
    for node_name in ["Area", "Field", "Bg", "Goal Score Title", "Goal Score", "Logo", "Floating Help"]:
        var n: Node = root.get_node_or_null(NodePath(node_name))
        if n and n is CanvasItem:
            items.push_back(n)
    if obstacle_root:
        items.push_back(obstacle_root)
    for d in dudes:
        if d != holder:
            items.push_back(d)
    for ci in items:
        _boss_fog_saved_visible[ci] = ci.visible
        ci.visible = false

func end_boss_fog_for_aim() -> void :
    if not _boss_fog_active:
        return
    _boss_fog_active = false
    for item in _boss_fog_saved_visible.keys():
        if is_instance_valid(item) and item is CanvasItem:
            (item as CanvasItem).visible = _boss_fog_saved_visible[item] as bool
    _boss_fog_saved_visible.clear()

# ---------------------------------------------------------------- dudes

func add_dude(player: bool, pos: Vector2, elite: bool = false):
    if player: player_count += 1
    else: enemy_count += 1
    var dude: = dude_prefab.instantiate() as Dude
    dude.looker.target = ball
    dude.looker.ignore_target = player
    dude.looker.look_speed = randf_range(0.8, 1.2)
    dudes.push_back(dude)
    add_child(dude)
    var offset = randf_range(-200, 200)
    dude.position = Vector2(offset, 300) if player else Vector2(offset, -1000)
    dude.move_to(pos)
    dude.player = player
    if not player:
        dude.make_enemy()
        if elite:
            dude.make_elite()
    else:
        dude.set_weapon_enabled(has_upgrade("weapon_system"))
        dude.set_catch_scale(get_catch_scale())
    dude.set_number(player_count if player else enemy_count)

func wait_for_dudes_settled():
    while dudes.any(func(d: Dude): return is_instance_valid(d) and d.moving):
        await get_tree().process_frame

func get_catch_scale() -> float:
    return 1.0 + 0.2 * upgrade_level("magnet_boots")

func get_closest(pos: Vector2, include_enemies: bool) -> Dude:
    var sorted: = dudes.filter( func(d: Dude): return d.player or include_enemies).duplicate()
    if sorted.is_empty():
        return null
    sorted.sort_custom( func(a: Dude, b: Dude): return pos.distance_to(a.global_position) < pos.distance_to(b.global_position))
    return sorted.front()

func get_players() -> Array[Dude]:
    return dudes.filter(func(d: Dude): return d.player)

func get_enemies() -> Array[Dude]:
    return dudes.filter(func(d: Dude): return not d.player)

func get_weapon_candidates() -> Array[Dude]:
    return dudes.filter(func(d: Dude): return d.player and d.has_weapon)

func remove_dude(d: Dude):
    if not d:
        return
    var idx: = dudes.find(d)
    if idx >= 0:
        dudes.remove_at(idx)
    d.queue_free()

func kill_enemy(enemy: Dude, pos: Vector2):
    if not enemy or not is_instance_valid(enemy) or enemy.player:
        return
    var amount: = 35 * (level + 1)
    if has_upgrade("bounty"):
        amount *= 2
        multi += 1
        multi_label.text = "x%d " % [multi]
    var is_boss: = enemy == boss_unit
    if is_boss:
        amount += 100 * (level + 1)
    add_score(amount, pos)
    if is_boss:
        boss_unit = null
        Effects.singleton.pop("[wave][font_size=60]BOSS DOWN![/font_size][/wave]", pos + Vector2.UP * 90)
        SoundEffects.singleton.add(5, pos, 1.1)
        end_boss_fog_for_aim()
    else:
        Effects.singleton.pop("[wave][font_size=45]DOWN![/font_size][/wave]", pos + Vector2.UP * 40)
    SoundEffects.singleton.add(4, pos, 0.8)
    remove_dude(enemy)
    refresh_hud()

# ---------------------------------------------------------------- spawning

func get_start_pos() -> Vector2:
    return global_position + Vector2.UP * 50

func spawn_round_enemies():
    var current: = get_enemies().size()
    var amount: = maxi(get_enemy_target() - current, 1)
    amount = mini(amount, maxi(MAX_ENEMIES - current, 0))
    for _i in amount:
        add_dude(false, pick_enemy_spawn())

func get_enemy_target() -> int:
    var stage: = get_stage()
    var target: int
    if stage == 1:
        target = 1 + level
    else:
        target = 2 * stage + round_in_stage()
    if has_upgrade("chaos"):
        target += 2
    return mini(target, MAX_ENEMIES)

# Enemies prefer spots the ball travelled through last round, then the area near the bench.
func pick_enemy_spawn() -> Vector2:
    for _pick in 14:
        if spots.is_empty():
            break
        var i: = randi_range(0, spots.size() - 1)
        var cand: Vector2 = spots[i]
        if spawn_keepout_ok(cand) and is_point_free(cand, 50.0) and _min_dist_to_any_dude(cand, null) >= 60.0:
            spots.remove_at(i)
            return cand
    if not spots.is_empty():
        spots.remove_at(randi_range(0, spots.size() - 1))
    return pick_enemy_spawn_with_clearance(get_start_pos())

func spawn_keepout_ok(p: Vector2) -> bool:
    return p.distance_to(global_position) >= enemy_spawn_keepout

func pick_enemy_spawn_with_clearance(fallback_center: Vector2) -> Vector2:
    for _attempt in 40:
        var candidate: Vector2 = fallback_center + Vector2(randf_range(-300, 300), randf_range(-200, 140))
        if not kicker.is_inside(candidate) or not is_point_free(candidate, 50.0):
            continue
        if spawn_keepout_ok(candidate) and _min_dist_to_any_dude(candidate, null) >= 60.0:
            return candidate
    for _attempt in 30:
        var anywhere: = random_point_in_field(60.0)
        if anywhere != Vector2.ZERO and spawn_keepout_ok(anywhere):
            return anywhere
    for relax in [180.0, 140.0, 100.0]:
        for _attempt in 28:
            var c2: Vector2 = fallback_center + Vector2(randf_range(-300, 300), randf_range(-200, 140))
            if not kicker.is_inside(c2):
                continue
            if c2.distance_to(global_position) >= relax:
                return c2
    return fallback_center

func random_point_in_field(min_other_dist: float, min_ball_dist: float = 0.0) -> Vector2:
    var field_poly: CollisionPolygon2D = kicker.field
    if not field_poly or field_poly.polygon.is_empty():
        return Vector2.ZERO
    var poly: PackedVector2Array = field_poly.polygon
    var xf: Transform2D = field_poly.global_transform
    var aabb: Rect2 = Rect2(poly[0], Vector2.ZERO)
    for p in poly:
        aabb = aabb.expand(p)
    for _i in 48:
        var local_pt: Vector2 = Vector2(
            randf_range(aabb.position.x, aabb.position.x + aabb.size.x),
            randf_range(aabb.position.y, aabb.position.y + aabb.size.y))
        if not Geometry2D.is_point_in_polygon(local_pt, poly):
            continue
        var world_pt: Vector2 = xf * local_pt
        if _min_dist_to_any_dude(world_pt, null) < min_other_dist:
            continue
        if not is_point_free(world_pt, 45.0):
            continue
        if min_ball_dist > 0 and world_pt.distance_to(ball.global_position) < min_ball_dist:
            continue
        return world_pt
    return Vector2.ZERO

func _min_dist_to_any_dude(world_pt: Vector2, ignore: Dude) -> float:
    var best: float = 1e9
    for d in dudes:
        if d == ignore:
            continue
        best = minf(best, world_pt.distance_to(d.global_position))
    return best

# ---------------------------------------------------------------- score / feedback

func pop_multi(pos: Vector2):
    multi += ball.bounces
    Effects.singleton.pop("[wave]x%d[/wave] " % [ball.bounces], pos)
    multi_label.text = "x%d " % [multi]

func add_score(amount: int, pos: Vector2):
    var final_amount: = amount * multi
    score += final_amount
    Effects.singleton.pop("[wave][font_size=80]+%s[/font_size][/wave]" % [Utils.as_score(final_amount)], pos)
    SoundEffects.singleton.add(12, pos, 0.3)
    SoundEffects.singleton.add(13, pos, 1.3)
    goal_score_label.text = Utils.as_score(score)

func bad(text: String, pos: Vector2):
    Effects.singleton.pop("[wave][font_size=40][color=#FFA69E]%s" % [text], pos + Vector2.UP * 60)

func raise_hands():
    for d in dudes:
        if d.player and not d.touched:
            d.raise()

func lower_hands():
    for d in dudes:
        d.reset()

func reset_multi():
    multi = 1
    multi_label.text = "x1 "

func pitch_music(target: float, duration: float = 0.75):
    var safe_target: = maxf(target, 0.01)
    get_tree().create_tween().tween_property(music, "pitch_scale", safe_target, duration).set_trans(Tween.TRANS_QUAD)
    await get_tree().create_timer(duration).timeout
    get_tree().create_tween().tween_property(music, "pitch_scale", 1, duration).set_trans(Tween.TRANS_QUAD)

func failed():
    if game_over:
        return
    if lives > 0:
        lives -= 1
        refresh_hud()
        cam.shake(10, 0.2)
        await get_tree().create_timer(0.75).timeout
        cam.shake(15, 0.2)
        pitch_music(0.5, 0.4)
        SoundEffects.singleton.add(4, global_position, 3)
        if lives == 0:
            Effects.singleton.pop("[wave][font_size=50]Last chance...", global_position)
        else:
            Effects.singleton.pop("[wave][font_size=50]Lost a life! %d left" % [lives], global_position)
        await get_tree().create_timer(0.5).timeout
        kicker.pass_ball(false)
        await get_tree().create_timer(0.3).timeout
        kicker.enable_kick()
        return
    game_over = true
    await get_tree().create_timer(0.9).timeout
    SoundEffects.singleton.add(4, global_position, 3)
    get_tree().create_tween().tween_property(music, "pitch_scale", 0.01, 2).set_trans(Tween.TRANS_QUAD)
    cam.shake(20, 0.25)
    appearers[2].appear()
    appearers[3].appear(0.2)
    appearers[4].appear(0.4)

func wait_and_shake(delay: float):
    await get_tree().create_timer(delay).timeout
    cam.shake(5, 0.1)

func halve_score():
    score = roundi(score * 0.5)

func is_interaction_blocked() -> bool:
    return pending_upgrade

# ---------------------------------------------------------------- upgrades

func offer_upgrade(boss_reward: bool):
    var choices: = pick_upgrade_choices(boss_reward)
    if choices.is_empty():
        return
    pending_upgrade = true
    kicker.cancel_all_modes()
    current_upgrade_choices = choices
    upgrade_title.text = "[wave]Boss reward! Pick one[/wave]" if boss_reward else "[wave]Choose an upgrade[/wave]"
    for idx in upgrade_buttons.size():
        var button: Button = upgrade_buttons[idx]
        if idx < choices.size():
            var id: String = choices[idx]
            var u: Dictionary = RunData.UPGRADES[id]
            var name_text: String = u.name
            if u.max > 1:
                name_text += " %s" % [RomanNumbers.get_string(upgrade_level(id) + 1)]
            button.text = "%s  [%s]\n%s" % [name_text, str(u.rarity).to_upper(), u.desc]
            var c: Color = RunData.rarity_color(u.rarity)
            for prop in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
                button.add_theme_color_override(prop, c)
            button.show()
        else:
            button.hide()
    upgrade_wrap.show()

func pick_upgrade_choices(boss_reward: bool) -> Array[String]:
    var stage: = get_stage()
    var weights: = {
        "common": maxi(20, 60 - 10 * (stage - 1)),
        "rare": 30 + 5 * (stage - 1),
        "epic": 10 + 5 * (stage - 1),
        "gamble": 8 if stage >= 2 else 0,
    }
    var pool: Array[String] = []
    for id in RunData.UPGRADES:
        if can_offer(id, boss_reward):
            pool.push_back(id)
    var picks: Array[String] = []
    while picks.size() < UPGRADE_CHOICES and not pool.is_empty():
        var total: int = 0
        for id in pool:
            total += weights[RunData.UPGRADES[id].rarity]
        if total <= 0:
            break
        var roll: = randi_range(1, total)
        var chosen: String = pool.back()
        for id in pool:
            roll -= weights[RunData.UPGRADES[id].rarity]
            if roll <= 0:
                chosen = id
                break
        picks.push_back(chosen)
        pool.erase(chosen)
    return picks

func can_offer(id: String, boss_reward: bool) -> bool:
    var u: Dictionary = RunData.UPGRADES[id]
    if upgrade_level(id) >= u.max:
        return false
    if u.has("requires") and not has_upgrade(u.requires):
        return false
    if id == "extra_life" and lives >= life_cap():
        return false
    if id == "glass_cannon" and has_upgrade("extra_life"):
        return false
    if boss_reward and u.rarity == "common":
        return false
    return true

func _on_upgrade_button_pressed(index: int):
    if not pending_upgrade:
        return
    if index >= current_upgrade_choices.size():
        return
    apply_upgrade(current_upgrade_choices[index])
    upgrade_wrap.hide()
    pending_upgrade = false
    SoundEffects.singleton.add(11, get_start_pos(), 1.0)

func apply_upgrade(id: String):
    upgrades[id] = upgrade_level(id) + 1
    match id:
        "weapon_system":
            for d in dudes:
                if d.player:
                    d.set_weapon_enabled(true)
        "glass_cannon":
            upgrades["weapon_system"] = maxi(upgrade_level("weapon_system"), 1)
            lives = mini(lives, life_cap())
            for d in dudes:
                if d.player:
                    d.set_weapon_enabled(true)
        "magnet_boots":
            for d in dudes:
                if d.player:
                    d.set_catch_scale(get_catch_scale())
        "extra_life":
            lives = mini(lives + 1, life_cap())
        "wide_goal":
            for post in goal_posts:
                post.scale.x = 0.7
    refresh_hud()

func wait_upgrade_done():
    while pending_upgrade:
        await get_tree().process_frame

func consume_weapon_shot() -> bool:
    if weapon_shots_left <= 0:
        return false
    weapon_shots_left -= 1
    return true

func consume_safe_pass() -> bool:
    if not safe_pass_available:
        return false
    safe_pass_available = false
    refresh_hud()
    return true

func consume_relocate_charge() -> bool:
    if relocate_charges <= 0:
        return false
    relocate_charges -= 1
    refresh_hud()
    return true

func get_weapon_hit_chance() -> float:
    return 0.8

# ---------------------------------------------------------------- HUD

func refresh_hud():
    if not status_label:
        return
    var lines: Array[String] = []

    var stage_parts: Array[String] = ["Stage %d" % [get_stage()]]
    stage_parts.push_back(RunData.LAYOUTS[layout_id].name)
    for w in weather:
        var wname: String = RunData.WEATHERS[w].name
        if w == "wind":
            wname += " >>" if wind_dir.x > 0 else " <<"
        stage_parts.push_back("[color=#9ED8FF]%s[/color]" % [wname])
    lines.push_back("[color=#FF8C9A]LIVES %d[/color]  ·  %s" % [lives, "  ·  ".join(stage_parts)])

    if boss_id != "":
        var info: Dictionary = RunData.BOSS_INFO[boss_id]
        var c: Color = info.color
        if boss_unit and is_instance_valid(boss_unit):
            lines.push_back("[color=#%s]BOSS: %s[/color] - %s" % [c.to_html(false), info.name, info.desc])
        else:
            lines.push_back("[color=#%s]BOSS DOWN[/color] - score to claim the reward" % [c.to_html(false)])

    var perk_parts: Array[String] = []
    for id in upgrades:
        var u: Dictionary = RunData.UPGRADES[id]
        var text: String = u.name
        if u.max > 1:
            text += " " + RomanNumbers.get_string(upgrades[id])
        perk_parts.push_back("[color=#%s]%s[/color]" % [RunData.rarity_color(u.rarity).to_html(false), text])
    if not perk_parts.is_empty():
        lines.push_back("Perks: " + " · ".join(perk_parts))

    var res_parts: Array[String] = []
    if has_upgrade("weapon_system"):
        res_parts.push_back("Shots %d" % [weapon_shots_left])
    if relocate_charges > 0:
        res_parts.push_back("Playmaker ready")
    if ghost_shot_ready:
        res_parts.push_back("Ghost Shot ready")
    if safe_pass_available:
        res_parts.push_back("Safe Pass ready")
    if not res_parts.is_empty():
        lines.push_back("[color=#C8FFC8]%s[/color]" % ["  ·  ".join(res_parts)])

    status_label.text = "\n".join(lines)

func _on_play_button_pressed() -> void :
    pass
