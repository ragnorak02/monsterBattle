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
- [ ] 41. Monster registry (seen/caught)
- [ ] 42. Pokedex UI
- [ ] 43. XP curve balancing
- [ ] 44. Evolution animation polish
- [ ] 45. Level-up stat growth tuning

---

## Macro Phase 4 — Overworld Expansion (46–60)

- [x] 46. Overworld scene functional
- [x] 47. NPC dialogue system
- [x] 48. Wild encounter zones
- [x] 49. Route transitions
- [ ] 50. Multiple towns
- [ ] 51. Gym leaders
- [ ] 52. Badge system
- [ ] 53. Trainer battles
- [ ] 54. Trainer AI switching logic
- [ ] 55. Quest system
- [ ] 56. Dialogue trees (data-driven)
- [ ] 57. Cutscene framework
- [ ] 58. World map UI
- [ ] 59. Weather system
- [ ] 60. Day/Night cycle

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

Current Goal: Begin Macro Phase 3 — Catching & Progression
Current Task: Antidotes, PC storage, monster registry
Work Mode: Feature Development
Next Milestone: Macro Phase 3 complete (checkpoints 31–45)

---

# Known Gaps

- No save system
- No achievements system
- No PC storage (caught monsters lost if party full)
- No Pokedex/registry UI
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