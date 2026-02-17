# Game Direction — Monster Catcher

## Vision
A 2D Pokemon-style monster catching game built in Godot 4.6. Pixel art aesthetic,
turn-based battles, overworld exploration, and a roster of 30 collectible monsters.

## Completed Milestones

### Phase 1 — Core Loop (COMPLETE)
- Overworld movement, camera, wild monster encounters
- Turn-based battle system with damage calc, HP bars, win/lose/run
- Party management and encounter UI
- NPC interaction & dialogue system
- Data-driven monsters/skills via .tres resources
- Controls HUD (keyboard + gamepad)
- Audio: town theme, battle theme, SFX

### Phase 2 — Catching & Progression (partial)
- Monster catching mechanic (catch rate calc, catch attempt battle state)
- XP & leveling system (add_experience, get_xp_threshold, level-up flow)
- Evolution system (evolve method, EVOLUTION battle state, stat recalc)
- Skill learning on level-up (LEARN_SKILL state, skill replace dialog)
- Automated test suite (47 tests, 6 groups, all passing)

## Planned Milestones

### Phase 2 — Remaining
- Re-enable gender & starter selection flow
- Expanded overworld areas with route transitions
- Type effectiveness system (Fire > Grass > Water > Fire triangle)
- Item/inventory system (Potions, Capture Balls, Antidotes)

### Phase 3 — Story & Polish
- Save/Load system (JSON or Godot ResourceSaver)
- Pokedex / monster registry (seen/caught tracking)
- Trainer battles with AI opponents (switch strategy, type coverage)
- Gym leaders with themed teams and badges
- NPC dialogue trees (data-driven, not hardcoded)
- Quest system with objectives
- Status effects (poison, paralysis, burn)
- PC/storage box system (store monsters beyond party of 6)
- Audio polish + more SFX
- Critical hits (12.5% chance, 1.5x damage)
- STAB bonus (Same Type Attack Bonus)

### Phase 4 — Content & Release
- Multiple towns and routes with transition system
- Full monster roster balancing pass
- Final pixel art (replace placeholder tileset)
- Stat stages (+/- attack, defense, speed in battle)
- Breeding/egg system
- Playtesting and difficulty tuning
- Bug fixes and polish

## Gameplay Improvement Suggestions

### Quick Wins (1-2 sessions each)
- **Type effectiveness** — Fire > Grass > Water > Fire triangle + more matchups
- **Critical hits** — 12.5% chance, 1.5x damage multiplier
- **Status effects** — Poison (DOT), Paralysis (skip turn chance), Burn (half attack)
- **STAB bonus** — 1.5x damage if monster type matches skill type

### Medium Features (3-5 sessions)
- **Item/inventory system** — Potions, Capture Balls, Antidotes with bag UI
- **Pokedex/Monster Registry** — Seen/caught tracking with completion percentage
- **Save/Load system** — JSON serialization or Godot ResourceSaver
- **Wild encounter zones** — Tall grass areas with level-scaled random spawns
- **PC/Storage box** — Store monsters beyond party of 6, swap from PC

### Major Features (full phase)
- **Trainer battles with AI** — NPC trainers with switching strategy, type coverage, item use
- **Multiple routes/towns** — Scene transitions, world map, gated progression
- **Gym leaders** — Themed teams, badge collection, scaling difficulty
- **Quest/story system** — Branching NPC dialogue, objectives, rewards
- **Breeding/egg system** — Monster pairs, egg hatching, inherited stats/moves

## Design Pillars
1. **Data-Driven**: All monsters and skills defined as .tres resources — no hardcoded content
2. **Pixel Art First**: 640x360 native resolution, integer scaling, GL Compatibility renderer
3. **Accessible Controls**: Full keyboard + gamepad support with visible control hints
4. **Simple & Fun**: Focus on core Pokemon loop — explore, encounter, battle, catch

## Current Roster
- 30 monsters (3 starters: Emberpup, Aqualing, Thornlet)
- 20 skills with power/accuracy stats
- 5 implied element types (Fire, Water, Grass, Electric, Dark, etc.)

## Technical Constraints
- Godot 4.6 stable — GL Compatibility renderer only
- Must use `resource.get("property")` pattern for generic Resource access (see CLAUDE.md)
- All .tscn sub_resources must appear before referencing nodes
