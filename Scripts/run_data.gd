@abstract class_name RunData

# Static run definitions: upgrades, weather, arena layouts and bosses.
# Text in "desc" must not contain parentheses; Main.mark() turns them into color tags.

const RARITY_COLORS: = {
    "common": Color(0.88, 0.92, 0.96),
    "rare": Color(0.45, 0.75, 1.0),
    "epic": Color(0.95, 0.55, 1.0),
    "gamble": Color(1.0, 0.55, 0.35),
}

const UPGRADES: = {
    "ricochet_master": {"name": "Ricochet Master", "desc": "+1 max bounce", "rarity": "common", "max": 3},
    "scout": {"name": "Scout", "desc": "Longer aim preview, +1 bounce shown", "rarity": "common", "max": 2},
    "magnet_boots": {"name": "Magnet Boots", "desc": "Teammates catch from farther away", "rarity": "common", "max": 2},
    "tough_skin": {"name": "Tough Skin", "desc": "Double touch no longer halves score", "rarity": "common", "max": 1},
    "bounty": {"name": "Bounty Hunter", "desc": "Kills score double and add +1 multi", "rarity": "common", "max": 1},
    "safe_pass": {"name": "Safe Pass", "desc": "First double touch each round is forgiven", "rarity": "common", "max": 1},
    "weapon_system": {"name": "Weapon System", "desc": "One tactical shot per round", "rarity": "rare", "max": 1},
    "quick_reload": {"name": "Quick Reload", "desc": "+1 tactical shot per round", "rarity": "rare", "max": 2, "requires": "weapon_system"},
    "relocate": {"name": "Playmaker", "desc": "Move one teammate each round", "rarity": "rare", "max": 1},
    "ghost_shot": {"name": "Ghost Shot", "desc": "Once per round the ball pierces the first enemy", "rarity": "rare", "max": 1},
    "extra_life": {"name": "Extra Life", "desc": "+1 life", "rarity": "rare", "max": 2},
    "wide_goal": {"name": "Wide Goal", "desc": "Goal mouth is 30% wider", "rarity": "epic", "max": 1},
    "bank_kill": {"name": "Bank Shot Hunter", "desc": "After 3 bounces the ball kills enemies it meets", "rarity": "epic", "max": 1},
    "banker": {"name": "Banker Instinct", "desc": "Goals with 4+ bounces score +50%", "rarity": "epic", "max": 1},
    "big_team": {"name": "Deep Bench", "desc": "+1 extra teammate every round", "rarity": "epic", "max": 1},
    "greed": {"name": "Greed", "desc": "Goal score x1.6 but -2 max bounces", "rarity": "gamble", "max": 1},
    "glass_cannon": {"name": "Glass Cannon", "desc": "Weapon +2 shots per round, but only 1 life max", "rarity": "gamble", "max": 1},
    "chaos": {"name": "Chaos Pitch", "desc": "+3 multi every round, but +2 enemies every round", "rarity": "gamble", "max": 1},
}

const WEATHERS: = {
    "wet": {"name": "Wet Grass", "desc": "-2 max bounces", "tint": Color(0.72, 0.86, 1.0)},
    "wind": {"name": "Wind", "desc": "Ball drifts after every bounce, shown in preview", "tint": Color(0.96, 0.94, 0.82)},
    "fog": {"name": "Fog", "desc": "Aim preview shows only 2 bounces", "tint": Color(0.78, 0.78, 0.8)},
}

const LAYOUTS: = {
    "open": {"name": "Open Pitch", "obstacles": []},
    "pillars": {"name": "Pillars", "obstacles": [
        {"shape": "circle", "pos": Vector2(760, 560), "r": 38.0},
        {"shape": "circle", "pos": Vector2(1172, 560), "r": 38.0},
        {"shape": "circle", "pos": Vector2(966, 690), "r": 38.0},
    ]},
    "bumpers": {"name": "Bumper Alley", "obstacles": [
        {"shape": "rect", "pos": Vector2(720, 640), "size": Vector2(220, 28), "rot": 0.4, "bumper": true},
        {"shape": "rect", "pos": Vector2(1212, 640), "size": Vector2(220, 28), "rot": -0.4, "bumper": true},
    ]},
    "fortress": {"name": "Fortress", "obstacles": [
        {"shape": "rect", "pos": Vector2(846, 470), "size": Vector2(150, 28)},
        {"shape": "rect", "pos": Vector2(1086, 470), "size": Vector2(150, 28)},
    ]},
    "islands": {"name": "Islands", "obstacles": [
        {"shape": "circle", "pos": Vector2(700, 500), "r": 26.0},
        {"shape": "circle", "pos": Vector2(1232, 500), "r": 26.0},
        {"shape": "circle", "pos": Vector2(760, 780), "r": 26.0},
        {"shape": "circle", "pos": Vector2(1172, 780), "r": 26.0},
    ]},
}

const BOSSES: Array[String] = ["shifter", "keeper", "sniper", "blind"]

const BOSS_INFO: = {
    "shifter": {"name": "Shifter", "desc": "Boss repositions after every bounce", "color": Color(0.35, 0.75, 1.0)},
    "keeper": {"name": "Keeper", "desc": "Goal narrows and the keeper guards the mouth", "color": Color(1.0, 0.8, 0.3)},
    "sniper": {"name": "Sniper", "desc": "Every shot you take costs a teammate", "color": Color(0.85, 0.35, 1.0)},
    "blind": {"name": "Blind Shot", "desc": "Only you and the ball are visible while aiming", "color": Color(0.6, 0.6, 0.72)},
}

const KEEPER_POSTS: = [
    {"shape": "rect", "pos": Vector2(800, 235), "size": Vector2(120, 26)},
    {"shape": "rect", "pos": Vector2(1132, 235), "size": Vector2(120, 26)},
]
const KEEPER_HOME: = Vector2(966, 300)
const KEEPER_X_MIN: = 890.0
const KEEPER_X_MAX: = 1042.0

static func upgrade_name(id: String) -> String:
    return UPGRADES[id].name if UPGRADES.has(id) else id

static func rarity_color(rarity: String) -> Color:
    return RARITY_COLORS.get(rarity, Color.WHITE)
