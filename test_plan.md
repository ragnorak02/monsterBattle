# Test Plan — Monster Catcher

## Current Test Infrastructure
No automated test framework is configured. Testing is currently manual.

## Manual Smoke Tests

### Overworld
- [ ] Game launches to overworld (boy sprite visible, camera follows)
- [ ] WASD/Arrow movement works in all 4 directions
- [ ] Player sprite animates when walking
- [ ] Wild monsters wander gently without leaving bounds
- [ ] Interacting with wild monster opens encounter UI
- [ ] NPC interaction shows dialogue box
- [ ] Tab opens party menu
- [ ] Controls HUD displays at bottom of screen

### Encounter UI
- [ ] Left panel shows wild monster name + sprite
- [ ] Right panel lists party monsters with HP status
- [ ] Fainted monsters show as "(Fainted)" and are not selectable
- [ ] Selecting a monster transitions to battle scene

### Battle System
- [ ] Battle intro message displays for ~1.5 seconds
- [ ] Player and enemy sprites + HP bars render correctly
- [ ] Skill buttons appear with name and accuracy
- [ ] Attacking deals damage according to formula: max(1, atk+power - def/2)
- [ ] Turn order respects agility (higher goes first, ties = player)
- [ ] Accuracy check can cause misses
- [ ] Reducing enemy HP to 0 triggers win state
- [ ] Player HP reaching 0 triggers lose state
- [ ] Run button has ~60% success rate; failure = enemy free attack
- [ ] Win returns to overworld, defeated monster removed from map
- [ ] Lose returns to overworld with defeat message

### Party Menu
- [ ] Shows all party monsters with level, HP, and skills
- [ ] Navigable with keyboard/gamepad
- [ ] Escape/Cancel closes menu

### Audio
- [ ] Town theme plays in overworld
- [ ] Battle theme plays during encounters
- [ ] Hit, faint, run, select SFX play at correct moments

### Debug
- [ ] F1 triggers encounter UI with random monster

## Future: Automated Testing
- Consider GdUnit4 or Gut framework for unit tests
- Priority targets: damage_calculator.gd, monster_instance.gd stat formulas
- Integration test: full battle flow (start → attack → win)
