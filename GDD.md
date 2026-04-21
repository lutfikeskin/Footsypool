# Footsypool — Game Design Document

**Version:** 1.0  
**Engine:** Godot 4.6 (GDScript)  
**Genre:** Arcade Sports / Roguelite  
**Platform:** PC (Windows, Linux, macOS)  
**Target Rating:** E (Everyone)

---

## Table of Contents

1. [Game Overview](#1-game-overview)
2. [Core Pillars](#2-core-pillars)
3. [Gameplay Loop](#3-gameplay-loop)
4. [Controls](#4-controls)
5. [Mechanics](#5-mechanics)
6. [Progression & Difficulty](#6-progression--difficulty)
7. [Upgrade System](#7-upgrade-system)
8. [Enemies](#8-enemies)
9. [Boss Encounters](#9-boss-encounters)
10. [Environmental Modifiers](#10-environmental-modifiers)
11. [Scoring](#11-scoring)
12. [Audio & Visual Design](#12-audio--visual-design)
13. [UI & HUD](#13-ui--hud)
14. [Win & Loss Conditions](#14-win--loss-conditions)
15. [Technical Overview](#15-technical-overview)

---

## 1. Game Overview

**Footsypool** is a turn-based arcade game that fuses the spatial strategy of pool/billiards with the competitive spirit of street football. The player controls a small team of field players and attempts to pass and shoot a ball into a goal, outmaneuvering an ever-growing roster of enemy interceptors.

Each run is a single escalating session: score goals to level up, earn upgrade choices at score milestones, and survive increasingly hostile environmental conditions. The run ends when the player fails twice.

**Elevator Pitch:** *"Pool meets football — bounce your way to goal, upgrade your squad, survive the chaos."*

---

## 2. Core Pillars

| Pillar | Description |
|---|---|
| **Readable Chaos** | Many moving parts (enemies, bounces, modifiers) but every outcome should feel explainable. |
| **Reward Creativity** | Bank shots, long ricochets, and chain passes should feel powerful and score more. |
| **Escalating Tension** | Each level adds enemies, modifiers, or boss twists that demand adaptation. |
| **Quick Decision-Making** | All interactions are a single click; the thinking is strategic, not mechanical. |

---

## 3. Gameplay Loop

```
START ROUND
│
├─ New teammate spawns at the top of the field
│
├─ PLACEMENT PHASE
│   └─ Player clicks to position the new teammate on the field
│
├─ PASS PHASE
│   └─ Ball passes from current holder to the nearest player (ally or enemy)
│       ├─ Ally catch → continue, optionally fire weapon shot
│       └─ Enemy catch → round fail (1st = last chance, 2nd = game over)
│
├─ KICK PHASE
│   └─ Player aims with mouse; trajectory preview shown
│   └─ Click to kick; ball bounces off walls and players
│       ├─ Ball enters goal → GOAL! Score awarded, advance level
│       ├─ Enemy intercepts ball → round fail
│       ├─ Ball bounces > max bounces → "DROPPED THE BALL!" fail
│       └─ Same player touches ball twice → "DOUBLE TOUCH!" fail
│
└─ LEVEL UP → enemies increase, modifiers may activate → repeat
```

---

## 4. Controls

| Input | Action |
|---|---|
| **Left Click** | Confirm placement / confirm kick direction / fire weapon shot |
| **Mouse Move** | Aim kick direction / hover targets |
| **Escape** | Toggle options/pause menu |

The cursor changes context automatically:
- **Crosshair**: Cursor is outside the playfield or in a targeting state
- **Ring**: Cursor is inside the playfield, ready to kick

---

## 5. Mechanics

### 5.1 Ball Physics

- The ball bounces off field walls and field boundaries.
- Each wall bounce increments the **bounce counter**.
- Bounce counter resets to zero after each goal or fail.
- The ball has a maximum bounce range per bounce to prevent perpetual motion.
- Ball speed is reduced when an enemy touches it.

### 5.2 Bounce Counter & Multiplier

- Every bounce adds +1 to the round's **bounce count**.
- Higher bounce counts increase the score multiplier for that round.
- **Banker Instinct** upgrade grants +35% bonus if bounces ≥ 3.

### 5.3 Trajectory Preview

- A dotted-line preview shows the ball path for up to **5 bounces** before the kick.
- **Ghost Shot** upgrade reduces preview to 3 bounces.
- **Fog** modifiers reduce preview visibility to 65% (or 0% in full Blind Shot boss mode).
- **Anchor Boots** upgrade ignores preview reductions from fog/wind.

### 5.4 Catching

- Ally catch: ball stays in team possession, round continues.
- Enemy catch: a fail is triggered.
- **Safe Pass**: protects the first ally catch of each round from enemy interception (consumed per round).
- The **chain assist** bonus increases weapon accuracy by +5% for each consecutive ally catch, up to +20%.

### 5.5 Weapon System (Unlockable)

- Unlocked via the **Weapon System** upgrade.
- Player gets 1 weapon shot per round (+1 per **Quick Reload** upgrade).
- After an ally catches the ball, click the shooter, then click an enemy to fire.
- **Hit Chance**: 78% base + chain assist bonus (up to +20%) + Overclock (+7%) − wind penalty (−5%) − elite enemy penalty (−8%).
- A hit eliminates the enemy and scores `+35 × level` bonus points.
- A miss produces a "MISSED SHOT!" notification and consumes the shot.

### 5.6 Double Touch Rule

- If the ball touches the same player twice in a single kick sequence, "DOUBLE TOUCH!" is called and the round fails.

### 5.7 Max Bounces

- Default maximum: **10 bounces**.
- **Ricochet Master** upgrade adds +1 per acquisition.
- Exceeding the maximum triggers a "DROPPED THE BALL!" fail.

---

## 6. Progression & Difficulty

### 6.1 Level Structure

- Levels are numbered from **0** upward and increment after each goal.
- There is no level cap; the run ends only on a second fail.

### 6.2 Enemy Spawning Formula

| Condition | Enemy Count Change |
|---|---|
| Base | `floor(level / 5) + 1` |
| Level ≥ 3 | +1 |
| Level ≥ 6 | +1 |
| No progress for 2 turns | +1 extra |
| Player killed 2+ enemies last round | +1 extra |

### 6.3 Environmental Unlock Timeline

| Level | Modifier Activated |
|---|---|
| 3 | Wet Grass (ball slows on bounces) |
| 5 | Wind Lane (aim drift, preview reduction) |
| 6+ | Fog Turns (every 3 rounds) |
| 10+ | Boss Encounters (rotating every 5 rounds) |

---

## 7. Upgrade System

Upgrades are offered at four cumulative score thresholds. At each threshold, **3 random upgrades** (from the pool of 13) are presented and the player picks **1**.

### 7.1 Score Thresholds

| Threshold | Upgrade Choice # |
|---|---|
| 800 | 1st |
| 2,200 | 2nd |
| 4,200 | 3rd |
| 7,000 | 4th |

### 7.2 Upgrade Catalogue

| # | Upgrade | Effect |
|---|---|---|
| 1 | **Weapon System** | Unlock tactical weapon shots (1/round). First shot in Quick Reload rounds is free. |
| 2 | **Ghost Shot** | First ball bounce pierces through an enemy. Preview reduced to 3 bounces. |
| 3 | **Ricochet Master** | +1 maximum bounces allowed per kick. |
| 4 | **Quick Reload** | +1 weapon shot available per round. |
| 5 | **Pressure Shield** | Absorb one fail — the first loss in a run is ignored. |
| 6 | **Banker Instinct** | +35% score bonus when bounce count ≥ 3. |
| 7 | **Safe Pass** | First ally catch each round is protected from enemy interception. |
| 8 | **Overclock Shot** | +7% weapon hit chance; ball travels faster; aiming is more demanding. |
| 9 | **Anchor Boots** | Ignore aim drift and preview penalties from wind and fog. |
| 10 | **Chain Assist** | +5% weapon hit chance per consecutive ally catch (max +20%). |
| 11 | **Recovery Drill** | Gain +1 tactical shot after receiving the first fail in a run. |
| 12 | **Relocate Player** | Once per upgrade selection, move one teammate to a new position. |
| 13 | **Bank Kill Carry** | After a bounce reaches a teammate, eliminate the first enemy in the ball's path and continue. |

---

## 8. Enemies

### 8.1 Standard Enemies

- Spawn at random field positions, minimum distance from the ball.
- Intercept the ball if it bounces through or near them.
- Larger groups require more deliberate routing of bank shots.

### 8.2 Elite Enemies

- Appear every 5 levels (levels 5, 10, 15, …).
- Visually larger than standard enemies.
- Harder to hit with weapon shots (−8% hit chance).

---

## 9. Boss Encounters

Boss encounters are active from **level 10 onward**, rotating every 5 rounds. Only one boss type is active at a time.

| Boss | Nickname | Special Rule |
|---|---|---|
| **Shifter** | Mobile Boss | Repositions to a random location on the field each round. Targeting ring is **cyan**. |
| **Blind Shot** | Full Fog | The entire field goes dark during aiming — only the player and ball remain visible. |
| **Sniper** | Sniper | Eliminates one random teammate at the start of each round. Targeting ring is **purple**. |

---

## 10. Environmental Modifiers

### 10.1 Wet Grass
- **Trigger:** Level 3+
- **Effect:** Ball speed multiplied by ×0.9 on each bounce.

### 10.2 Wind Lane
- **Trigger:** Level 5+
- **Effects:**
  - Weapon accuracy −5%.
  - Long shots drift to the right (unless **Anchor Boots** equipped).
  - Trajectory preview scaled down to 65% length (unless **Anchor Boots** equipped).
- **Escalation:** After 2+ turns without progress, wind strength increases.

### 10.3 Fog Turn
- **Trigger:** Every 3 rounds from level 6+
- **Normal Fog:** Preview visibility reduced to 65%.
- **Boss Fog (Blind Shot):** Full darkness; only the player and ball are visible while aiming.

---

## 11. Scoring

### 11.1 Round Score Formula

```
Round Score = 100 × (level + 1) × multiplier × score_factor
             + (bounces + ally_catches × 10) × multiplier
```

- **Multiplier** increases as the bounce counter grows.
- **Score factor** is modified by active upgrades (e.g., Banker Instinct adds ×1.35 when bounces ≥ 3).

### 11.2 Bonus Points

| Event | Points |
|---|---|
| Weapon kill | +35 × level |
| First ally catch of the round | Score bonus |
| Goal scored | Full round score awarded |

### 11.3 Total Score

- Accumulates across all rounds.
- Triggers upgrade offers at the thresholds listed in Section 7.1.
- Displayed as a running total in the HUD.

---

## 12. Audio & Visual Design

### 12.1 Visual Style

- **Perspective:** Top-down 2D.
- **Art Style:** Pixel art with a bright, clean sports aesthetic.
- **Resolution:** Native 1920×1080, windowed default at 1280×720 (scalable, borderless).
- **Color coding for catch rings:**

| Color | Meaning |
|---|---|
| White | Ally / standard receiver |
| Yellow / Gold | Ally with weapon available |
| Red | Elite enemy |
| Cyan | Mobile Boss (Shifter) |
| Purple | Sniper Boss |

### 12.2 Audio

- **Background Music:** Continuous looping track; pitch shifts dynamically:
  - Normal play: ×1.0
  - Goal scored: ×1.3 (excitement spike)
  - First fail: ×0.5 (tension drop)
  - After fail resolves: returns to ×1.0
- **Sound Effects:** Dedicated sounds for kicks, wall hits, catches, goals, fails, enemy spawns, and weapon shots.
- **Font:** Norwester (custom bitmap font).

---

## 13. UI & HUD

| Element | Location | Description |
|---|---|---|
| Round Number | Top area | Current level indicator |
| Total Score | Top area | Cumulative score across all rounds |
| Round Score Counter | Center/top | Animated counter showing score earned this round |
| Multiplier Display | HUD | Current score multiplier (×1, ×2, ×3…) |
| Catch Rings | Field overlay | Colored rings around players showing eligibility |
| Trajectory Preview | Field overlay | Dotted line showing predicted ball path |
| Fail Message | Center screen | "Last chance…" or game-over prompt |
| Upgrade Screen | Full screen | Three upgrade cards; player picks one |
| Options Menu | Overlay | Accessible via Escape key |

---

## 14. Win & Loss Conditions

### 14.1 Round Win — Goal Scored

- The ball enters the goal zone.
- Score is awarded; level increments.
- Enemy count recalculates for the next round.

### 14.2 Round Fail — Two-Strike System

| Strike | Result |
|---|---|
| 1st fail | "Last chance…" message displayed. Round restarts with same level. |
| 2nd fail | Game over. Player sees final score and options to restart or review. |

**Fail Triggers:**
- Enemy intercepts the ball during pass or kick.
- Bounce count exceeds the maximum (DROPPED THE BALL!).
- Same player touches the ball twice (DOUBLE TOUCH!).

### 14.3 Pressure Shield Interaction

- If the **Pressure Shield** upgrade is held, the very first fail of the entire run is absorbed (no last-chance warning shown; the round simply restarts).

---

## 15. Technical Overview

| Property | Value |
|---|---|
| Engine | Godot 4.6 |
| Language | GDScript |
| Physics | Jolt Physics (3D engine, 2D gameplay) |
| Renderer | GL Compatibility |
| Native Resolution | 1920×1080 |
| Default Window | 1280×720 (borderless, scalable) |
| Version | 1.0.0 |

### 15.1 Project Structure

```
/Scripts/         — Core game scripts (main, ball, dude, kicker, catcher)
/Scenes/          — Scene files (main.tscn, dude, bits, ground_bits)
/Sprites/         — Pixel art assets (70+ images)
/Sounds/          — Audio assets (31+ files: SFX + music)
/_Starter/        — Engine utility framework (effects, particles, UI helpers, camera, menus)
/Builds/          — Export builds
/addons/          — Editor plugins (info panel, color palette)
```

### 15.2 Key Scripts

| Script | Responsibility |
|---|---|
| `main.gd` | Game state, round management, scoring, upgrades, modifier logic |
| `ball.gd` | Ball movement, bounce physics, collision detection |
| `dude.gd` | Player/enemy actor: position, catch logic, visual state |
| `kicker.gd` | Kick input, trajectory preview rendering, weapon fire |
| `catcher.gd` | Catch ring display, receiver targeting |
