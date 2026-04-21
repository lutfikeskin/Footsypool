class_name Main extends Node2D

@export var kicker: Kicker
@export var dude_prefab: PackedScene
@export var ball: Ball
@export var cam: Camera
@export var multi_label: RichTextLabel
@export var score_label: RichTextLabel
@export var goal_score_label: RichTextLabel
@export var round_label: RichTextLabel
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

var dudes: Array[Dude] = []
var spots: Array[Vector2] = []
var player_count: = 0
var enemy_count: = 0
var multi: = 1
var score: = 100
var level: = 0
var total_score: = 0
var shown_score: = 0
var has_failed: = false
var shown_kick_help: = false
var shown_opponent_help: = false
var has_moved: = false
var started: = false
var picked_upgrades: Dictionary = {}
var upgrade_thresholds: Array[int] = [800, 2200, 4200, 7000]
var next_upgrade_index: = 0
var pending_upgrade: = false
var current_upgrade_choices: Array[String] = []
var weapon_upgrade_active: = false
var ghost_shot_active: = false
var ricochet_bonus: = 0
var quick_reload_bonus: = 0
var pressure_shield_ready: = false
var weapon_shots_left: = 0
var banker_instinct_active: = false
var safe_pass_active: = false
var overclock_shot_active: = false
var anchor_boots_active: = false
var chain_assist_active: = false
var recovery_drill_active: = false
var single_relocate_active: = false
var single_relocate_charges: = 0
var bank_kill_carry_active: = false
var relocate_mode_active: = false
var chain_assist_bonus: = 0.0
var safe_pass_available: = false
var wet_grass_active: = false
var wind_lane_active: = false
var fog_turn_active: = false
var fog_turn_round_gap: = 3
var wind_strength: = 0.12
var turns_without_progress: = 0
var kills_last_round: = 0
var kills_this_round: = 0

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
    if not player: dude.make_enemy()
    if elite and not player:
        dude.make_elite()
    if player:
        dude.set_weapon_enabled(weapon_upgrade_active)
    dude.set_number(player_count if player else enemy_count)

func get_closest(pos: Vector2, include_enemies: bool) -> Dude:
    var sorted: = dudes.filter( func(d: Dude): return d.player or include_enemies).duplicate()
    sorted.sort_custom( func(a: Dude, b: Dude): return pos.distance_to(a.global_position) < pos.distance_to(b.global_position))
    return sorted.front()

func show_help(first: String, second: String):
    appearers[0].show_with_text(Utils.as_wavy(mark(first)))
    appearers[1].show_with_text(Utils.as_wavy(mark(second)), 0.2)
    pitch_music(1.1)
    SoundEffects.singleton.add(17, global_position, 0.8)

func mark(text: String):
    return Utils.colorize(text, "#FFA69E")

func next_level():
    kills_last_round = kills_this_round
    kills_this_round = 0
    if score <= 0:
        turns_without_progress += 1
    else:
        turns_without_progress = 0
    total_score += score
    score_label.text = "%s " % [Utils.as_score(total_score)]
    Effects.singleton.pop("[wave][font_size=60]+%s[/font_size][/wave]" % [Utils.as_score(score)], ball.global_position + Vector2.DOWN * 60)
    shown_score = 0
    score = 0
    level += 1
    kicker.line.hide()
    check_upgrade_trigger()
    await wait_upgrade_done()
    await get_tree().create_timer(0.5).timeout

    var enemy_spawns: = get_enemy_spawn_count()
    for amt in enemy_spawns:
        if spots.size() > 0:
            var spot: = spots.pick_random() as Vector2
            add_dude(false, spot, is_elite_round() and amt == enemy_spawns - 1)
            spots.remove_at(spots.find(spot))
        else:
            add_dude(false, get_start_pos() + Vector2(randf_range(-260, 260), randf_range(-140, 140)), is_elite_round() and amt == enemy_spawns - 1)
    add_dude(true, get_start_pos())
    await dudes.back().moved
    reset_round_resources()
    if relocate_mode_active:
        pass
    elif weapon_upgrade_active and weapon_shots_left > 0 and get_enemies().size() > 0:
        kicker.start_weapon_phase()
    else:
        kicker.placing = true
        kicker.line.show()
    spots.clear()
    for d in dudes: d.touched = false
    round_label.text = " Round %d" % [(level + 1)]
    await get_tree().create_timer(0.5).timeout
    score = 100 * (level + 1) * multi
    if not shown_opponent_help:
        shown_opponent_help = true
        show_help("Don't let (them) get the (ball)!", "How long can you (survive) and (score)...")
    if wet_grass_active:
        show_floating_help("Wet Grass\nBall slows on bounces", get_start_pos() + Vector2.LEFT * 180)
    if wind_lane_active:
        show_floating_help("Wind Lane\nLong shots drift right", get_start_pos() + Vector2.RIGHT * 180)
    if fog_turn_active:
        show_floating_help("Fog turn!\nPreview reduced", get_start_pos())

func get_start_pos() -> Vector2:
    return global_position + Vector2.UP * 50

func pop_multi(pos: Vector2):
    multi += ball.bounces
    Effects.singleton.pop("[wave]x%d[/wave] " % [ball.bounces], pos)
    multi_label.text = "x%d " % [multi]

func add_score(amount: int, pos: Vector2):
    var final_amount: = roundi(amount * multi * get_score_factor())
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
    if pressure_shield_ready:
        pressure_shield_ready = false
        bad("SHIELD SAVED YOU!", ball.global_position)
        SoundEffects.singleton.add(11, ball.global_position, 1.1)
        kicker.pass_ball(false)
        await get_tree().create_timer(0.2).timeout
        kicker.enable_kick()
        return
    if has_failed:
        await get_tree().create_timer(0.9).timeout
        SoundEffects.singleton.add(4, global_position, 3)

        get_tree().create_tween().tween_property(music, "pitch_scale", 0.01, 2).set_trans(Tween.TRANS_QUAD)
        cam.shake(20, 0.25)
        appearers[2].appear()
        appearers[3].appear(0.2)
        appearers[4].appear(0.4)
        if recovery_drill_active:
            weapon_shots_left += 1
            show_floating_help("Recovery Drill\n+1 tactical shot", get_start_pos())
    else:
        cam.shake(10, 0.2)
        await get_tree().create_timer(0.75).timeout
        cam.shake(15, 0.2)
        pitch_music(0.5, 0.4)
        SoundEffects.singleton.add(4, global_position, 3)

        has_failed = true
        Effects.singleton.pop("[wave][font_size=50]Last chance...", global_position)
        await get_tree().create_timer(0.5).timeout
        kicker.pass_ball(false)
        await get_tree().create_timer(0.3).timeout
        kicker.enable_kick()
    pressure_shield_ready = false

func wait_and_shake(delay: float):
    await get_tree().create_timer(delay).timeout
    cam.shake(5, 0.1)

func halve_score():
    score = roundi(score * 0.5)

func is_interaction_blocked() -> bool:
    return pending_upgrade

func check_upgrade_trigger():
    if next_upgrade_index >= upgrade_thresholds.size():
        return
    if total_score < upgrade_thresholds[next_upgrade_index]:
        return
    pending_upgrade = true
    kicker.cancel_all_modes()
    show_upgrade_menu()
    next_upgrade_index += 1

func show_upgrade_menu():
    var pool: Array[String] = [
        "weapon_system",
        "ghost_shot",
        "ricochet_master",
        "quick_reload",
        "pressure_shield",
        "banker_instinct",
        "safe_pass",
        "overclock_shot",
        "anchor_boots",
        "chain_assist",
        "recovery_drill",
        "single_relocate",
        "bank_kill_carry"
    ]
    current_upgrade_choices.clear()
    while current_upgrade_choices.size() < 3 and pool.size() > 0:
        var pick: String = pool.pick_random()
        pool.erase(pick)
        if picked_upgrades.get(pick, false):
            continue
        current_upgrade_choices.push_back(pick)
    if current_upgrade_choices.is_empty():
        pending_upgrade = false
        return
    upgrade_title.text = "[wave]Choose an upgrade[/wave]"
    for idx in upgrade_buttons.size():
        var button: Button = upgrade_buttons[idx]
        if idx < current_upgrade_choices.size():
            button.show()
            button.text = get_upgrade_label(current_upgrade_choices[idx])
        else:
            button.hide()
    upgrade_wrap.show()

func get_upgrade_label(id: String) -> String:
    match id:
        "weapon_system": return "Weapon System\nManual shot each round"
        "ghost_shot": return "Ghost Shot\nShort aim, pierce first enemy"
        "ricochet_master": return "Ricochet Master\n+1 max bounce"
        "quick_reload": return "Quick Reload\n+1 weapon shot / round"
        "pressure_shield": return "Pressure Shield\nIgnore first fail"
        "banker_instinct": return "Banker Instinct\nBig bonus on bank-heavy goals"
        "safe_pass": return "Safe Pass\nFirst ally receive is protected"
        "overclock_shot": return "Overclock Shot\nFaster shot, tougher aim, better pierce"
        "anchor_boots": return "Anchor Boots\nIgnore wind/fog penalties"
        "chain_assist": return "Chain Assist\nTeam catches buff gun accuracy"
        "recovery_drill": return "Recovery Drill\nGain tactical shot after first fail"
        "single_relocate": return "Relocate Player\nMove one teammate once"
        "bank_kill_carry": return "Bank Kill Carry\nAfter bank, kill enemy and continue"
    return id

func _on_upgrade_button_pressed(index: int):
    if not pending_upgrade:
        return
    if index >= current_upgrade_choices.size():
        return
    var chosen: String = current_upgrade_choices[index]
    apply_upgrade(chosen)
    picked_upgrades[chosen] = true
    upgrade_wrap.hide()
    pending_upgrade = false

func apply_upgrade(id: String):
    match id:
        "weapon_system":
            weapon_upgrade_active = true
            for d in dudes:
                if d.player:
                    d.set_weapon_enabled(true)
        "ghost_shot":
            ghost_shot_active = true
        "ricochet_master":
            ricochet_bonus += 1
        "quick_reload":
            quick_reload_bonus += 1
        "pressure_shield":
            pressure_shield_ready = true
        "banker_instinct":
            banker_instinct_active = true
        "safe_pass":
            safe_pass_active = true
        "overclock_shot":
            overclock_shot_active = true
        "anchor_boots":
            anchor_boots_active = true
        "chain_assist":
            chain_assist_active = true
        "recovery_drill":
            recovery_drill_active = true
        "single_relocate":
            single_relocate_active = true
            single_relocate_charges = 1
            relocate_mode_active = true
            kicker.start_relocate_phase()
        "bank_kill_carry":
            bank_kill_carry_active = true

func wait_upgrade_done():
    while pending_upgrade:
        await get_tree().process_frame

func reset_round_resources():
    weapon_shots_left = 1 + quick_reload_bonus if weapon_upgrade_active else 0
    chain_assist_bonus = 0.0
    safe_pass_available = safe_pass_active
    wet_grass_active = level >= 3
    wind_lane_active = level >= 5
    fog_turn_active = level >= 6 and level % fog_turn_round_gap == 0
    if turns_without_progress >= 2:
        wind_strength = 0.18
    else:
        wind_strength = 0.12
    if single_relocate_active and single_relocate_charges > 0 and started and relocate_mode_active:
        kicker.start_relocate_phase()

func consume_weapon_shot() -> bool:
    if weapon_shots_left <= 0:
        return false
    weapon_shots_left -= 1
    return true

func get_weapon_candidates() -> Array[Dude]:
    return dudes.filter(func(d: Dude): return d.player and d.has_weapon)

func get_enemies() -> Array[Dude]:
    return dudes.filter(func(d: Dude): return not d.player)

func remove_dude(d: Dude):
    if not d:
        return
    var idx: = dudes.find(d)
    if idx >= 0:
        dudes.remove_at(idx)
    d.queue_free()

func kill_enemy(enemy: Dude, pos: Vector2):
    if not enemy or enemy.player:
        return
    add_score(35 * (level + 1), pos)
    Effects.singleton.pop("[wave][font_size=45]DOWN![/font_size][/wave]", pos + Vector2.UP * 40)
    SoundEffects.singleton.add(4, pos, 0.8)
    kills_this_round += 1
    remove_dude(enemy)

func get_max_bounces() -> int:
    return 10 + ricochet_bonus

func get_enemy_spawn_count() -> int:
    var base: = floori(level / 5.0) + 1
    if level >= 3:
        base += 1
    if level >= 6:
        base += 1
    if turns_without_progress >= 2:
        base += 1
    if kills_last_round >= 2:
        base += 1
    return base

func is_elite_round() -> bool:
    return level > 0 and level % 5 == 0

func register_player_catch():
    if chain_assist_active:
        chain_assist_bonus = minf(chain_assist_bonus + 0.05, 0.2)

func consume_safe_pass() -> bool:
    if not safe_pass_available:
        return false
    safe_pass_available = false
    return true

func consume_single_relocate_charge() -> bool:
    if single_relocate_charges <= 0:
        return false
    single_relocate_charges -= 1
    return true

func finish_single_relocate():
    relocate_mode_active = false

func resume_after_relocate():
    if weapon_upgrade_active and weapon_shots_left > 0 and get_enemies().size() > 0:
        kicker.start_weapon_phase()
    else:
        kicker.placing = true
        kicker.line.show()

func get_weapon_hit_chance() -> float:
    var chance: = 0.78 + chain_assist_bonus
    if overclock_shot_active:
        chance += 0.07
    if wind_lane_active and not anchor_boots_active:
        chance -= 0.05
    return clampf(chance, 0.65, 0.9)

func is_aim_penalty_active() -> bool:
    return (wind_lane_active or fog_turn_active) and not anchor_boots_active

func get_wind_strength() -> float:
    return wind_strength if wind_lane_active and not anchor_boots_active else 0.0

func get_preview_scale() -> float:
    if fog_turn_active and not anchor_boots_active:
        return 0.65
    return 1.0

func get_ball_speed_factor() -> float:
    return 1.18 if overclock_shot_active else 1.0

func get_score_factor() -> float:
    var factor: = 1.0
    if banker_instinct_active and ball.bounces >= 3:
        factor += 0.35
    if ball.bounces <= 1 and level >= 5:
        factor -= 0.15
    return clampf(factor, 0.65, 1.8)

func _on_play_button_pressed() -> void :
    pass
