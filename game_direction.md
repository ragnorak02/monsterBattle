# Game Direction — Monster Catcher

## Vision
A 2D Pokemon-style monster catching game built in Godot 4.6. Pixel art aesthetic,
turn-based battles, overworld exploration, and a roster of 30 collectible monsters.

## Completed Milestones
- **Phase 1 — Core Loop**: Overworld movement, wild monster encounters, turn-based
  battle system, party management, data-driven monsters/skills

## Planned Milestones
- **Phase 2 — Catching & Progression**: Monster catching mechanic, XP/leveling,
  evolution system, expanded overworld areas
- **Phase 3 — Story & Polish**: NPC dialogue trees, quest system, gym/boss battles,
  save/load, audio polish
- **Phase 4 — Content & Release**: Full monster roster balancing, multiple areas,
  final art pass, playtesting

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
