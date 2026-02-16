# Monster Catcher Game

## Project Overview
- Godot 4.6 stable 2D Pokemon-style monster catching game
- Resolution: 640x360 (2x integer scale to 1280x720)
- Renderer: GL Compatibility (pixel art friendly)
- Godot path: `/c/Users/nick/Downloads/Godot_v4.6-stable_win64.exe/Godot_v4.6-stable_win64_console.exe`

## Critical Godot 4.6 Pattern
When `base_data` or any variable is typed as generic `Resource` (not the specific class), you CANNOT access properties directly like `resource.monster_name`. Godot 4.6 strict type inference fails with "Cannot infer the type of variable".

**Fix:** Use `resource.get("property_name")` with explicit casts:
- `str(resource.get("monster_name"))` for strings
- `int(resource.get("power"))` for ints
- `float(resource.get("accuracy"))` for floats
- `resource.get("front_sprite") as Texture2D` for textures

This applies to ALL scripts that touch MonsterData or SkillData properties.

## Current Repo State (Auto-Detected)
- Phase 1 complete: 26 scripts (1,618 LOC), 15 scenes, 50 .tres resources, 64 sprites, 6 audio files
- Gender/starter select screens exist but are bypassed — main.gd quick-starts as boy + Emberpup
- `tileset_placeholder.png` in use — overworld tilemap is procedurally generated from placeholder
- 2 missing audio refs in AssetRegistry: `cancel.wav` and `encounter.wav` (dead references, unused in code)
- No test framework or automated tests present
- No TODO/FIXME/HACK comments found in codebase
- `_auto_test` flag in overworld.gd and `auto_battle` flag in battle_controller.gd exist for dev testing
- 6 autoloads registered (GameManager, SceneManager, MonsterDB, AudioManager, AssetRegistry, ThemeManager)
- Battle system fully functional: state machine, damage calc, HP bars, win/lose/run
- No secrets, .env files, or credentials detected

## Architecture
- 6 Autoloads: GameManager, SceneManager, MonsterDB, AudioManager, AssetRegistry, ThemeManager
- 3 Resource classes: MonsterData, SkillData, MonsterInstance (in `scripts/resources/`)
- Scene flow: main.tscn → (skips gender/starter) → overworld ↔ battle/party_menu/dialogue
- All monster/skill data is data-driven via .tres files in `data/` folder

## Key Conventions
- .tres files use `script_class` references (SkillData, MonsterData)
- In .tscn files: sub_resources MUST appear before the nodes that reference them
- Collision layers: 1=player, 2=environment, 4=npc, 8=wild_monster
- Player interaction ray collision_mask=12 (NPC + wild_monster)

## Battle System
- State machine: INTRO → PLAYER_TURN → EXECUTE → CHECK_FAINT → WIN/LOSE/RUN → OUTRO
- Damage: max(1, (attacker.attack + skill.power) - (defender.defense / 2))
- Turn order: higher agility first, ties go to player
- Run: 60% success, fail = enemy free attack
- F1 debug key triggers encounter UI with random monster
