# MONSTER CATCHER (monsterBattle)
AMARIS Development Specification

Engine: Godot 4.6  
Platform: PC  
Renderer: GL Compatibility  
Resolution: 640×360 (2x → 1280×720 integer scale)  
Genre: Monster RPG  
Studio: AMARIS  
Controller Required: Yes (Keyboard + Gamepad)

---

# AMARIS Studio Rules (Non-Negotiable)

- `project_status.json` is the single source of truth.
- CLAUDE.md defines structure + checkpoints only.
- Completion % must NOT be duplicated here.
- All gameplay systems must remain testable.
- Debug flags default false in production.
- Never delete checklist items — mark N/A.

Launcher Contract:
- game.config.json must remain valid.
- tests/run-tests.bat must execute headless.
- ISO8601 minute precision timestamps.

---

# Godot Execution Contract (MANDATORY)

Godot installed at:

Z:/godot

Claude MUST use:

Z:/godot/godot.exe

Never assume PATH.
Never use Downloads directory.
Never reinstall engine.

Headless boot:
Z:/godot/godot.exe --path . --headless --quit-after 1

Headless tests:
Z:/godot/godot.exe --path . --headless --script res://tests/run_tests.gd

If new scripts added:
Z:/godot/godot.exe --path . --headless --import

---

# Critical Godot 4.6 Resource Pattern

When a variable is typed as generic `Resource`, you MUST use:

resource.get("property")

Never use direct property access.

Examples:
str(resource.get("monster_name"))
int(resource.get("power"))
float(resource.get("accuracy"))
resource.get("front_sprite") as Texture2D

This rule is non-negotiable.

---

# Project Overview

Pokemon-style monster catching RPG.

Core Loop:

Overworld  
→ Wild Encounter  
→ Turn-Based Battle  
→ Catch / Defeat  
→ XP / Level Up / Evolution  
→ Explore  

Pillars:
- Data-driven monsters and skills (.tres only)
- Deterministic battle state machine
- Pixel-art integer scaling
- Accessible controls
- Expandable monster roster (30+)

---

# Architecture Summary

Autoloads:
- GameManager
- SceneManager
- MonsterDB
- AudioManager
- AssetRegistry
- ThemeManager

Resources:
- MonsterData
- SkillData
- MonsterInstance

Battle States:
INTRO → PLAYER_TURN → EXECUTE → CHECK_FAINT → WIN/LOSE/RUN → OUTRO

Damage:
max(1, (atk + power) - (def/2))

Run success: 60%

Collision layers:
1=player, 2=environment, 4=npc, 8=wild_monster

---

# Structured Development Checklist
AMARIS STANDARD — 95 Checkpoints

## Macro Phase 1 — Foundation (1–15)

- [x] 1. Repo standardized
- [x] 2. GL Compatibility enforced
- [x] 3. 640×360 integer scale confirmed
- [x] 4. 6 autoloads registered
- [x] 5. Resource-driven data pattern
- [x] 6. Battle state machine implemented
- [x] 7. Damage formula deterministic
- [x] 8. Turn order by agility
- [x] 9. Run logic implemented
- [x] 10. Encounter trigger working
- [x] 11. XP system implemented
- [x] 12. Evolution system implemented
- [x] 13. Skill learning system
- [ ] 14. Version visible in UI
- [ ] 15. Logging standardization

---

## Macro Phase 2 — Type System & Combat Depth (16–30)

- [x] 16. Type effectiveness triangle (Fire > Grass > Water)
- [x] 17. Expanded type chart
- [x] 18. STAB bonus (1.5x)
- [x] 19. Critical hits (12.5%, 1.5x)
- [x] 20. Status effects (poison)
- [x] 21. Status effects (burn)
- [x] 22. Status effects (paralysis)
- [x] 23. Status effect turn resolution
- [x] 24. Status effect visual indicators
- [x] 25. Accuracy + evasion modifiers
- [x] 26. Skill category split (physical/special)
- [x] 27. Multi-hit skills
- [x] 28. Passive abilities system
- [x] 29. Battle UI polish pass
- [x] 30. AI move selection improvement

---

## Macro Phase 3 — Catching & Progression (31–45)

- [x] 31. Catch mechanic exists
- [x] 32. Capture ball types
- [x] 33. Catch rate modifiers (HP-based)
- [x] 34. Item inventory system
- [x] 35. Potion usage
- [x] 36. Antidotes
- [x] 37. Gender selection flow restored
- [x] 38. Starter selection flow restored
- [x] 39. PC storage system
- [x] 40. Party size enforcement (6 max)
- [x] 41. Monster registry (seen/caught)
- [x] 42. Pokedex UI
- [x] 43. XP curve balancing
- [x] 44. Evolution animation polish
- [x] 45. Level-up stat growth tuning

---

## Macro Phase 4 — Overworld Expansion (46–60)

- [x] 46. Overworld scene functional
- [x] 47. NPC dialogue system
- [x] 48. Wild encounter zones
- [x] 49. Route transitions
- [x] 50. Multiple towns
- [x] 51. Gym leaders
- [x] 52. Badge system
- [x] 53. Trainer battles
- [x] 54. Trainer AI switching logic
- [x] 55. Quest system
- [x] 56. Dialogue trees (data-driven)
- [x] 57. Cutscene framework
- [x] 58. World map UI
- [x] 59. Weather system
- [x] 60. Day/Night cycle

---

## Macro Phase 5 — Save & Persistence (61–70)

- [ ] 61. Save system (JSON or ResourceSaver)
- [ ] 62. Continue option enabled
- [ ] 63. Party persistence
- [ ] 64. Registry persistence
- [ ] 65. Inventory persistence
- [ ] 66. Save version migration
- [ ] 67. Auto-save after battle
- [ ] 68. Corruption fallback
- [ ] 69. Save/load regression tests
- [ ] 70. Launcher compliance save check

---

## Macro Phase 6 — Audio / Art / Polish (71–85)

- [x] 71. Town theme
- [x] 72. Battle theme
- [x] 73. Basic SFX
- [ ] 74. Audio dead reference cleanup
- [ ] 75. Additional SFX
- [ ] 76. Pixel art final pass
- [ ] 77. Battle animation polish
- [ ] 78. UI animation polish
- [ ] 79. VFX for crit/status
- [ ] 80. Screenshake
- [ ] 81. Accessibility pass
- [ ] 82. Colorblind-safe palette audit
- [ ] 83. Performance audit
- [ ] 84. Asset pipeline finalization
- [ ] 85. Content balance pass (30 monsters)

---

## Macro Phase 7 — Achievements & Meta (86–95)

Current state: achievementsSystem = missing :contentReference[oaicite:6]{index=6}

- [ ] 86. Add achievements.json
- [ ] 87. AchievementManager autoload
- [ ] 88. first_catch achievement
- [ ] 89. full_party achievement
- [ ] 90. first_evolution achievement
- [ ] 91. defeat_gym_leader achievement
- [ ] 92. complete_registry achievement
- [ ] 93. Achievement toast system
- [ ] 94. Status.html integration
- [ ] 95. Dashboard progress hook

---

# PHASE 6 — EXPERIENCE SYSTEM (PLAYER + MONSTERS)

## OBJECTIVE

Introduce a scalable RPG experience and leveling system for:
- Player character
- All owned monsters ("Pokey")

System must support:
- EXP gain after battles
- Level progression
- Stat scaling
- Move unlocks (future compatible)
- Save persistence

---

## DATA ARCHITECTURE

### Monster Data Model Expansion

- [x] Add fields to Monster:
      - level
      - currentEXP
      - expToNextLevel
      - baseStats
      - growthCurveType
      - learnedMoves[]
- [x] Create ExperienceCurve utility
- [x] Implement levelUp() method
- [x] Trigger stat recalculation on levelUp

---

### Trainer Rank System (replaces Player Experience Model)

- [x] Add trainer_rank
- [x] Add trainer_experience
- [x] Add get_trainer_xp_threshold
- [x] Hook trainer EXP gain into battle resolution
- [x] Add trainer title lookup

---

## BATTLE INTEGRATION

- [x] Award EXP to active monster
- [x] Full-party EXP sharing (all non-fainted)
- [x] Award trainer EXP
- [x] Display "Level Up" popup with stat deltas
- [x] Recalculate stats immediately
- [x] XP bar in battle display (player side)
- [x] Save updated values

---

## VALIDATION

- EXP increases after battle
- Level increases properly
- Stats scale predictably
- No overflow errors
- Save/load retains level

---

# PHASE 7 — STATUS MENU REFACTOR

## CURRENT PROBLEM

Menu is cluttered.
Too much player info.
Poor layout.
No proper party overview.

We will restructure to match classic monster RPG layout.

Reference:
- menu1.png
- menu2.png

---

# MENU STRUCTURE OVERVIEW

## Menu 1 — Party Overview

Layout:

LEFT SIDE:
- Active monster (walking companion)
- Expanded stats preview
- HP bar
- Level
- Small sprite

RIGHT SIDE:
- Vertical list of party monsters (max 6)
- Each shows:
    - Small sprite
    - Name
    - Level
    - HP bar
    - Status condition (if any)

Controller:
- D-pad up/down = select monster
- A = Open details (Menu 2)
- B = Close menu

---

## Implementation Tasks

- [ ] Create PartyMenuScene
- [ ] Limit party to 6 monsters
- [ ] Create PartySlot UI component
- [ ] Add HP bar component
- [ ] Add Level display
- [ ] Highlight selected slot
- [ ] Add smooth open animation
- [ ] Remove unnecessary player stat clutter

---

# MENU 2 — Detailed Monster View

When selecting a monster:

Display:

LEFT:
- Large sprite
- Level
- EXP bar
- HP
- Status
- Type

RIGHT:
- Stats:
    - Attack
    - Defense
    - Speed
    - Special
- Move list
- Move power
- Move type
- Move description

Controller:
- LB/RB = switch tabs (Stats / Moves / EXP)
- B = return to Menu 1

---

## Implementation Tasks

- [ ] Create MonsterDetailScene
- [ ] Create TabSwitchComponent
- [ ] Create EXP progress bar
- [ ] Create MoveList UI
- [ ] Ensure scaling layout
- [ ] Ensure 16:9 compatibility
- [ ] Add smooth transition animation

---

# PHASE 8 — SAVE SYSTEM EXPANSION

- [ ] Add level + EXP to save data
- [ ] Add learned moves to save data
- [ ] Add party order persistence
- [ ] Add versioning to save file
- [ ] Implement migration handler for older saves

---

# PHASE 9 — AUTOMATION COMPLIANCE

- [ ] Update project_status.json
- [ ] Increment macroPhase
- [ ] Add completionPercent delta
- [ ] Add regression tests:
      - EXP gain
      - Level up
      - Menu navigation
      - Controller compliance
- [ ] Run headless tests
- [ ] Confirm no null errors

---

# FINAL VALIDATION CHECKLIST

- [ ] EXP system working
- [ ] Monsters level correctly
- [ ] Player levels correctly
- [ ] Menu clean & readable
- [ ] No UI overflow
- [ ] Controller navigation smooth
- [ ] Save/load stable
- [ ] Party max size enforced
- [ ] Performance stable (no frame drops)

---

Proceed phase by phase.
No rushed refactors.
Preserve modular architecture.

---

# Debug Flags

Must exist and default false:

- DEBUG_BATTLE
- DEBUG_TYPES
- DEBUG_CATCH
- DEBUG_AI
- DEBUG_XP
- DEBUG_UI

---

# Test Contract

Test runner:
tests/run-tests.bat

Ensure:
- All tests pass after gameplay changes
- Add regression tests when modifying damage formula
- Add tests for type effectiveness and crit logic

---

# Automation Contract

After major updates:

1. Update project_status.json:
   - macroPhase
   - subphaseIndex
   - completionPercent
   - timestamps
   - testStatus

2. Run tests headless.
3. Confirm no regressions.
4. Commit.
5. Push.

AMARIS dashboard depends on this.

---

# Current Focus

Current Goal: Phase 6 Experience System Complete — Continue Phase 5/7
Current Task: Save & persistence system / Status menu refactor
Work Mode: Feature Development
Next Milestone: Macro Phase 5 (checkpoints 61–70)

---

# Known Gaps

- No save system
- No achievements system
- No version display in game UI
- AI move selection is score-based (could be deeper)

---

# Long-Term Vision

Monster Catcher should evolve into:

- 3+ regions
- 8 gym leaders
- 60+ monsters
- Full type system
- Competitive battle logic
- Meta progression
- Studio-grade launcher tracking

---

END OF FILE