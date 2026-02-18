extends Node

# ── Monster Catcher Test Runner ──
# Runs all test groups headlessly and outputs a JSON report.
# Launch: godot --path . --headless res://scenes/tests/test_runner.tscn

var _pass_count: int = 0
var _fail_count: int = 0
var _current_test: String = ""
var _details: Array = []  # Array of { name, status, message }

# ── Lifecycle ──

func _ready() -> void:
	print("=== Monster Catcher Test Runner ===")

	_run_damage_calculator_tests()
	_run_type_effectiveness_tests()
	_run_monster_instance_tests()
	_run_game_manager_tests()
	_run_inventory_tests()
	_run_area_persistence_tests()
	_run_scene_loading_tests()
	_run_asset_existence_tests()
	_run_performance_tests()

	var total := _pass_count + _fail_count
	print("")
	print("Results: %d passed, %d failed, %d total" % [_pass_count, _fail_count, total])

	_emit_json_report()

	if _fail_count > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

# ── Assertion Helpers ──

func _begin(test_name: String) -> void:
	_current_test = test_name

func _pass(msg: String = "") -> void:
	_pass_count += 1
	_details.append({"name": _current_test, "status": "pass", "message": msg})

func _fail(msg: String) -> void:
	_fail_count += 1
	print("  FAIL [%s]: %s" % [_current_test, msg])
	_details.append({"name": _current_test, "status": "fail", "message": msg})

func _assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual == expected:
		_pass(msg)
	else:
		_fail("%s — expected %s, got %s" % [msg, str(expected), str(actual)])

func _assert_true(val: bool, msg: String = "") -> void:
	if val:
		_pass(msg)
	else:
		_fail("%s — expected true" % msg)

func _assert_false(val: bool, msg: String = "") -> void:
	if not val:
		_pass(msg)
	else:
		_fail("%s — expected false" % msg)

func _assert_not_null(val: Variant, msg: String = "") -> void:
	if val != null:
		_pass(msg)
	else:
		_fail("%s — expected non-null" % msg)

func _assert_gt(a: Variant, b: Variant, msg: String = "") -> void:
	if a > b:
		_pass(msg)
	else:
		_fail("%s — expected %s > %s" % [msg, str(a), str(b)])

func _assert_lt(a: Variant, b: Variant, msg: String = "") -> void:
	if a < b:
		_pass(msg)
	else:
		_fail("%s — expected %s < %s" % [msg, str(a), str(b)])

# ── JSON Report ──

func _emit_json_report() -> void:
	var total := _pass_count + _fail_count
	var status := "pass" if _fail_count == 0 else "fail"
	var report := {
		"game": "monsterbattle",
		"passed": _pass_count,
		"failed": _fail_count,
		"total": total,
		"status": status,
		"details": _details
	}
	print("===JSON_REPORT_START===")
	print(JSON.stringify(report))
	print("===JSON_REPORT_END===")

# ── Mock Helpers ──

func _make_monster_data(hp: int, atk: int, def_val: int, agi: int) -> MonsterData:
	var data := MonsterData.new()
	data.max_hp = hp
	data.attack = atk
	data.defense = def_val
	data.agility = agi
	return data

func _make_skill(p_name: String, p_power: int, p_accuracy: float = 1.0) -> SkillData:
	var skill := SkillData.new()
	skill.skill_name = p_name
	skill.power = p_power
	skill.accuracy = p_accuracy
	return skill

func _make_monster(hp: int, atk: int, def_val: int, agi: int, lvl: int = 5) -> MonsterInstance:
	var data := _make_monster_data(hp, atk, def_val, agi)
	return MonsterInstance.new(data, lvl)

func _make_typed_monster(hp: int, atk: int, def_val: int, agi: int, etype: String, lvl: int = 5) -> MonsterInstance:
	var data := _make_monster_data(hp, atk, def_val, agi)
	data.element_type = etype
	return MonsterInstance.new(data, lvl)

func _make_typed_skill(p_name: String, p_power: int, stype: String, p_accuracy: float = 1.0) -> SkillData:
	var skill := _make_skill(p_name, p_power, p_accuracy)
	skill.skill_type = stype
	return skill

# ══════════════════════════════════════════════
#  A. Damage Calculator Tests
# ══════════════════════════════════════════════

func _run_damage_calculator_tests() -> void:
	print("\n── Damage Calculator ──")

	# Test 1: Basic damage formula
	_begin("damage_basic_formula")
	# attacker: atk=14, level=5 → get_attack()=19
	# defender: def=8, level=5  → get_defense()=13
	# skill power=10
	# damage = max(1, (19 + 10) - (13 / 2)) = max(1, 29 - 6) = 23
	var attacker := _make_monster(40, 14, 8, 12)
	var defender := _make_monster(40, 10, 8, 10)
	var skill := _make_skill("TestSlash", 10, 1.0)
	var dmg := DamageCalculator.calculate_damage(attacker, defender, skill)
	_assert_eq(dmg, 23, "basic formula")

	# Test 2: Minimum damage is 1
	_begin("damage_minimum_one")
	var tank := _make_monster(100, 5, 200, 5)
	var weak_skill := _make_skill("Tickle", 1, 1.0)
	var weak_attacker := _make_monster(20, 1, 5, 5)
	var min_dmg := DamageCalculator.calculate_damage(weak_attacker, tank, weak_skill)
	_assert_eq(min_dmg, 1, "min damage should be 1")

	# Test 3: Accuracy 1.0 always hits
	_begin("accuracy_1.0_always_hits")
	var perfect_skill := _make_skill("SureHit", 10, 1.0)
	var hit := DamageCalculator.check_accuracy(perfect_skill)
	_assert_true(hit, "accuracy 1.0 always hits")

	# Test 4: Catch rate at full HP (~0.15)
	_begin("catch_rate_full_hp")
	var wild := _make_monster(40, 10, 8, 10)
	# Full HP → hp_percent=1.0 → rate = 0.15 + 0.0 * 0.75 = 0.15
	var rate := DamageCalculator.calculate_catch_rate(wild)
	_assert_true(absf(rate - 0.15) < 0.01, "full HP catch rate ~0.15, got %.3f" % rate)

	# Test 5: Catch rate at half HP (~0.525)
	_begin("catch_rate_half_hp")
	var half_hp_mon := _make_monster(40, 10, 8, 10)
	half_hp_mon.current_hp = half_hp_mon.get_max_hp() / 2
	var half_rate := DamageCalculator.calculate_catch_rate(half_hp_mon)
	_assert_true(absf(half_rate - 0.525) < 0.05, "half HP catch rate ~0.525, got %.3f" % half_rate)

	# Test 6: Catch rate near death (clamped at 0.95)
	_begin("catch_rate_near_death")
	var dying := _make_monster(40, 10, 8, 10)
	dying.current_hp = 1
	var death_rate := DamageCalculator.calculate_catch_rate(dying)
	_assert_true(death_rate >= 0.85, "near-death catch rate >= 0.85, got %.3f" % death_rate)
	_assert_true(death_rate <= 0.95, "near-death catch rate <= 0.95, got %.3f" % death_rate)

	# Test 7: First attacker based on agility
	_begin("first_attacker_agility")
	var fast := _make_monster(40, 10, 8, 20)   # agi=20, get_agility()=25
	var slow := _make_monster(40, 10, 8, 5)    # agi=5, get_agility()=10
	_assert_eq(DamageCalculator.get_first_attacker(fast, slow), 0, "faster monster goes first")
	_assert_eq(DamageCalculator.get_first_attacker(slow, fast), 1, "slower monster goes second")
	# Tie goes to first arg (player)
	var equal := _make_monster(40, 10, 8, 12)
	var equal2 := _make_monster(40, 10, 8, 12)
	_assert_eq(DamageCalculator.get_first_attacker(equal, equal2), 0, "tie goes to first arg")

# ══════════════════════════════════════════════
#  A2. Type Effectiveness Tests
# ══════════════════════════════════════════════

func _run_type_effectiveness_tests() -> void:
	print("\n── Type Effectiveness ──")

	# Test: Super effective (Fire > Grass = 2.0x)
	_begin("type_super_effective")
	var mult := DamageCalculator.get_type_multiplier("Fire", "Grass")
	_assert_true(absf(mult - 2.0) < 0.01, "Fire > Grass = 2.0x, got %.2f" % mult)

	# Test: Not very effective (Fire > Water = 0.5x)
	_begin("type_not_very_effective")
	mult = DamageCalculator.get_type_multiplier("Fire", "Water")
	_assert_true(absf(mult - 0.5) < 0.01, "Fire > Water = 0.5x, got %.2f" % mult)

	# Test: Neutral (Fire > Dark = 1.0x)
	_begin("type_neutral")
	mult = DamageCalculator.get_type_multiplier("Fire", "Dark")
	_assert_true(absf(mult - 1.0) < 0.01, "Fire > Dark = 1.0x, got %.2f" % mult)

	# Test: Core triangle Fire > Grass > Water > Fire
	_begin("type_core_triangle")
	_assert_true(DamageCalculator.get_type_multiplier("Fire", "Grass") > 1.0, "Fire > Grass")
	_assert_true(DamageCalculator.get_type_multiplier("Grass", "Water") > 1.0, "Grass > Water")
	_assert_true(DamageCalculator.get_type_multiplier("Water", "Fire") > 1.0, "Water > Fire")

	# Test: STAB (monster type matches skill type)
	_begin("type_stab_bonus")
	var fire_mon := _make_typed_monster(40, 14, 8, 12, "Fire")
	var normal_mon := _make_typed_monster(40, 10, 8, 10, "Normal")
	var fire_skill := _make_typed_skill("Flame", 10, "Fire")
	var result := DamageCalculator.calculate_damage_with_type(fire_mon, normal_mon, fire_skill)
	_assert_true(result["stab"] as bool, "STAB should be true for Fire mon + Fire skill")

	# Test: No STAB for mismatched types
	_begin("type_no_stab_mismatch")
	var water_skill := _make_typed_skill("Splash", 10, "Water")
	result = DamageCalculator.calculate_damage_with_type(fire_mon, normal_mon, water_skill)
	_assert_false(result["stab"] as bool, "no STAB for Fire mon + Water skill")

	# Test: No STAB for Normal type
	_begin("type_no_stab_normal")
	var normal_skill := _make_typed_skill("Hit", 10, "Normal")
	result = DamageCalculator.calculate_damage_with_type(normal_mon, fire_mon, normal_skill)
	_assert_false(result["stab"] as bool, "no STAB for Normal type skills")

	# Test: Backward compatibility (untyped = same as old)
	_begin("type_backward_compat")
	var plain_attacker := _make_monster(40, 14, 8, 12)
	var plain_defender := _make_monster(40, 10, 8, 10)
	var plain_skill := _make_skill("Bonk", 10, 1.0)
	var old_damage := DamageCalculator.calculate_damage(plain_attacker, plain_defender, plain_skill)
	_assert_eq(old_damage, 23, "backward compatible damage = 23")

	# Test: Super effective damage is higher than neutral
	_begin("type_super_effective_damage")
	var grass_mon := _make_typed_monster(40, 10, 8, 10, "Grass")
	var fire_skill2 := _make_typed_skill("Burn", 10, "Fire")
	var se_result := DamageCalculator.calculate_damage_with_type(fire_mon, grass_mon, fire_skill2)
	var neutral_result := DamageCalculator.calculate_damage_with_type(fire_mon, normal_mon, fire_skill2)
	_assert_gt(se_result["damage"], neutral_result["damage"], "super effective > neutral damage")

	# Test: All 30 monsters have element_type set
	_begin("all_monsters_have_element_type")
	var type_ok := true
	for id: int in MonsterDB.monsters:
		var data: Resource = MonsterDB.monsters[id]
		var etype: Variant = data.get("element_type")
		if etype == null or str(etype) == "":
			_fail("monster id=%d missing element_type" % id)
			type_ok = false
	if type_ok:
		_pass("all 30 monsters have element_type")

	# Test: All 20 skills have skill_type set
	_begin("all_skills_have_skill_type")
	var skill_ok := true
	for sname: String in MonsterDB.skills:
		var data: Resource = MonsterDB.skills[sname]
		var stype: Variant = data.get("skill_type")
		if stype == null or str(stype) == "":
			_fail("skill '%s' missing skill_type" % sname)
			skill_ok = false
	if skill_ok:
		_pass("all 20 skills have skill_type")

# ══════════════════════════════════════════════
#  B. Monster Instance Tests
# ══════════════════════════════════════════════

func _run_monster_instance_tests() -> void:
	print("\n── Monster Instance ──")

	# Stat formulas: base_stat + level
	_begin("get_max_hp")
	var mon := _make_monster(40, 14, 8, 12, 5)
	_assert_eq(mon.get_max_hp(), 50, "max_hp = 40 + 5*2 = 50")

	_begin("get_attack")
	_assert_eq(mon.get_attack(), 19, "attack = 14 + 5 = 19")

	_begin("get_defense")
	_assert_eq(mon.get_defense(), 13, "defense = 8 + 5 = 13")

	_begin("get_agility")
	_assert_eq(mon.get_agility(), 17, "agility = 12 + 5 = 17")

	# take_damage
	_begin("take_damage_basic")
	var mon2 := _make_monster(40, 10, 8, 10, 5)
	mon2.take_damage(15)
	_assert_eq(mon2.current_hp, mon2.get_max_hp() - 15, "HP reduced by 15")

	_begin("take_damage_floor_zero")
	var mon3 := _make_monster(40, 10, 8, 10, 5)
	mon3.take_damage(9999)
	_assert_eq(mon3.current_hp, 0, "HP floors at 0")

	# is_fainted
	_begin("is_fainted_at_zero")
	_assert_true(mon3.is_fainted(), "fainted at 0 HP")

	_begin("is_fainted_above_zero")
	var healthy := _make_monster(40, 10, 8, 10, 5)
	_assert_false(healthy.is_fainted(), "not fainted above 0 HP")

	# heal
	_begin("heal_basic")
	var hurt := _make_monster(40, 10, 8, 10, 5)
	hurt.take_damage(20)
	hurt.heal(10)
	_assert_eq(hurt.current_hp, hurt.get_max_hp() - 10, "healed 10 HP")

	_begin("heal_capped_at_max")
	hurt.heal(9999)
	_assert_eq(hurt.current_hp, hurt.get_max_hp(), "heal capped at max HP")

	# XP threshold
	_begin("get_xp_threshold")
	var mon5 := _make_monster(40, 10, 8, 10, 5)
	_assert_eq(mon5.get_xp_threshold(), 250, "level 5: 5*5*10 = 250")

	# add_experience with level-up
	_begin("add_experience_level_up")
	var mon6 := _make_monster(40, 10, 8, 10, 5)
	var result := mon6.add_experience(250)
	_assert_true(result["leveled_up"] as bool, "should level up")
	_assert_eq(result["old_level"], 5, "old level = 5")
	_assert_eq(result["new_level"], 6, "new level = 6")

# ══════════════════════════════════════════════
#  C. Game Manager Tests
# ══════════════════════════════════════════════

func _run_game_manager_tests() -> void:
	print("\n── Game Manager ──")

	# Reset state before tests
	GameManager.player_party = []

	# add_to_party
	_begin("add_to_party")
	var mon := _make_monster(40, 10, 8, 10)
	GameManager.add_to_party(mon)
	_assert_eq(GameManager.player_party.size(), 1, "party size is 1")

	# Party max 6
	_begin("party_max_six")
	GameManager.player_party = []
	for i in range(6):
		GameManager.add_to_party(_make_monster(40, 10, 8, 10))
	_assert_eq(GameManager.player_party.size(), 6, "party at max 6")
	GameManager.add_to_party(_make_monster(40, 10, 8, 10))
	_assert_eq(GameManager.player_party.size(), 6, "7th monster rejected")

	# get_first_alive_monster skips fainted
	_begin("get_first_alive_skips_fainted")
	GameManager.player_party = []
	var fainted_mon := _make_monster(40, 10, 8, 10)
	fainted_mon.take_damage(9999)
	var alive_mon := _make_monster(40, 10, 8, 10)
	GameManager.add_to_party(fainted_mon)
	GameManager.add_to_party(alive_mon)
	var first := GameManager.get_first_alive_monster()
	_assert_eq(first, alive_mon, "skips fainted, returns alive")

	# all_fainted
	_begin("all_fainted")
	GameManager.player_party = []
	var f1 := _make_monster(40, 10, 8, 10)
	f1.take_damage(9999)
	var f2 := _make_monster(40, 10, 8, 10)
	f2.take_damage(9999)
	GameManager.add_to_party(f1)
	GameManager.add_to_party(f2)
	_assert_true(GameManager.all_fainted(), "all fainted = true")
	GameManager.add_to_party(_make_monster(40, 10, 8, 10))
	_assert_false(GameManager.all_fainted(), "all fainted = false with alive member")

	# heal_all_party
	_begin("heal_all_party")
	GameManager.player_party = []
	var hurt1 := _make_monster(40, 10, 8, 10)
	hurt1.take_damage(20)
	var hurt2 := _make_monster(40, 10, 8, 10)
	hurt2.take_damage(30)
	GameManager.add_to_party(hurt1)
	GameManager.add_to_party(hurt2)
	GameManager.heal_all_party()
	_assert_eq(hurt1.current_hp, hurt1.get_max_hp(), "monster 1 fully healed")
	_assert_eq(hurt2.current_hp, hurt2.get_max_hp(), "monster 2 fully healed")

	# Cleanup
	GameManager.player_party = []

# ══════════════════════════════════════════════
#  C2. Inventory Tests
# ══════════════════════════════════════════════

func _run_inventory_tests() -> void:
	print("\n── Inventory ──")

	# Reset inventory
	GameManager.inventory = {}

	# Test: add valid item
	_begin("inventory_add_item")
	var added := GameManager.add_item("potion", 3)
	_assert_true(added, "add_item returns true for valid item")
	_assert_eq(GameManager.get_item_count("potion"), 3, "potion count = 3")

	# Test: stack items
	_begin("inventory_stack_items")
	GameManager.add_item("potion", 2)
	_assert_eq(GameManager.get_item_count("potion"), 5, "potions stack to 5")

	# Test: remove item
	_begin("inventory_remove_item")
	var removed := GameManager.remove_item("potion", 2)
	_assert_true(removed, "remove_item returns true")
	_assert_eq(GameManager.get_item_count("potion"), 3, "potion count = 3 after removing 2")

	# Test: remove insufficient fails
	_begin("inventory_remove_insufficient")
	var failed := GameManager.remove_item("potion", 99)
	_assert_false(failed, "remove_item fails with insufficient count")
	_assert_eq(GameManager.get_item_count("potion"), 3, "count unchanged after failed remove")

	# Test: add invalid item rejected
	_begin("inventory_reject_invalid")
	var invalid := GameManager.add_item("nonexistent_item", 1)
	_assert_false(invalid, "add_item rejects unknown item_id")

	# Test: get_battle_items
	_begin("inventory_get_battle_items")
	GameManager.inventory = {}
	GameManager.add_item("potion", 5)
	GameManager.add_item("capture_ball", 10)
	var battle_items: Array = GameManager.get_battle_items()
	_assert_eq(battle_items.size(), 2, "2 battle items")

	# Test: catch rate with ball multiplier
	_begin("inventory_catch_rate_with_ball")
	var wild := _make_monster(40, 10, 8, 10)
	var base_rate := DamageCalculator.calculate_catch_rate(wild)
	var ball_rate := DamageCalculator.calculate_catch_rate_with_ball(wild, 1.5)
	_assert_gt(ball_rate, base_rate, "ball multiplier increases catch rate")

	# Test: get_item_def
	_begin("inventory_get_item_def")
	var potion_def := GameManager.get_item_def("potion")
	_assert_eq(potion_def["name"], "Potion", "potion name correct")
	_assert_eq(potion_def["type"], "heal", "potion type is heal")

	# Test: remove last item erases key
	_begin("inventory_remove_last_erases")
	GameManager.inventory = {}
	GameManager.add_item("potion", 1)
	GameManager.remove_item("potion", 1)
	_assert_eq(GameManager.get_item_count("potion"), 0, "potion count 0 after removing last")
	_assert_false(GameManager.inventory.has("potion"), "potion key erased from inventory")

	# Cleanup
	GameManager.inventory = {}

# ══════════════════════════════════════════════
#  C3. Area Persistence Tests
# ══════════════════════════════════════════════

func _run_area_persistence_tests() -> void:
	print("\n── Area Persistence ──")

	# Reset area state
	GameManager.current_area = "town"
	GameManager.area_player_positions = {}
	GameManager.area_defeated_monsters = {}

	# Test: position persistence per area
	_begin("area_position_persistence")
	GameManager.set_area_player_position("town", Vector2(100, 200))
	GameManager.set_area_player_position("route1", Vector2(300, 50))
	var town_pos: Variant = GameManager.get_area_player_position("town")
	var route_pos: Variant = GameManager.get_area_player_position("route1")
	_assert_eq(town_pos, Vector2(100, 200), "town position saved")
	_assert_eq(route_pos, Vector2(300, 50), "route1 position saved")

	# Test: defeated monsters separate per area
	_begin("area_defeated_separate")
	GameManager.mark_area_monster_defeated("town", 1)
	GameManager.mark_area_monster_defeated("town", 3)
	GameManager.mark_area_monster_defeated("route1", 2)
	_assert_true(GameManager.is_area_monster_defeated("town", 1), "town monster 1 defeated")
	_assert_true(GameManager.is_area_monster_defeated("town", 3), "town monster 3 defeated")
	_assert_false(GameManager.is_area_monster_defeated("town", 2), "town monster 2 not defeated")
	_assert_true(GameManager.is_area_monster_defeated("route1", 2), "route1 monster 2 defeated")
	_assert_false(GameManager.is_area_monster_defeated("route1", 1), "route1 monster 1 not defeated")

	# Test: unvisited area returns null position
	_begin("area_unvisited_returns_null")
	var unknown_pos: Variant = GameManager.get_area_player_position("unknown_area")
	_assert_eq(unknown_pos, null, "unvisited area returns null")

	# Test: unvisited area has no defeated monsters
	_begin("area_unvisited_no_defeated")
	_assert_false(GameManager.is_area_monster_defeated("unknown_area", 1), "unvisited area has no defeated")
	var defeated: Array = GameManager.get_area_defeated("unknown_area")
	_assert_eq(defeated.size(), 0, "unvisited area defeated list empty")

	# Test: duplicate defeated not added twice
	_begin("area_no_duplicate_defeated")
	GameManager.area_defeated_monsters = {}
	GameManager.mark_area_monster_defeated("town", 5)
	GameManager.mark_area_monster_defeated("town", 5)
	var town_defeated: Array = GameManager.get_area_defeated("town")
	_assert_eq(town_defeated.size(), 1, "no duplicate defeated monsters")

	# Cleanup
	GameManager.current_area = "town"
	GameManager.area_player_positions = {}
	GameManager.area_defeated_monsters = {}

# ══════════════════════════════════════════════
#  D. Scene Loading Tests
# ══════════════════════════════════════════════

func _run_scene_loading_tests() -> void:
	print("\n── Scene Loading ──")

	var scenes := {
		"main.tscn": "res://scenes/main.tscn",
		"overworld.tscn": "res://scenes/overworld/overworld.tscn",
		"battle_scene.tscn": "res://scenes/battle/battle_scene.tscn",
		"encounter_ui.tscn": "res://scenes/ui/encounter_ui.tscn",
		"party_menu.tscn": "res://scenes/ui/party_menu.tscn",
		"player.tscn": "res://scenes/overworld/player.tscn",
		"gender_select.tscn": "res://scenes/gender_select.tscn",
		"starter_select.tscn": "res://scenes/starter_select.tscn",
		"inventory_ui.tscn": "res://scenes/ui/inventory_ui.tscn",
	}

	for scene_name: String in scenes:
		_begin("load_scene_%s" % scene_name.get_basename())
		var path: String = scenes[scene_name]
		var packed := load(path) as PackedScene
		_assert_not_null(packed, "scene loads: %s" % scene_name)

# ══════════════════════════════════════════════
#  E. Asset Existence Tests
# ══════════════════════════════════════════════

func _run_asset_existence_tests() -> void:
	print("\n── Asset Existence ──")

	# MonsterDB monster count
	_begin("monsterdb_monster_count")
	_assert_eq(MonsterDB.monsters.size(), 30, "MonsterDB has 30 monsters")

	# MonsterDB skill count
	_begin("monsterdb_skill_count")
	_assert_eq(MonsterDB.skills.size(), 20, "MonsterDB has 20 skills")

	# Starters exist
	_begin("starters_exist")
	_assert_not_null(MonsterDB.get_monster(1), "starter ID 1 exists")
	_assert_not_null(MonsterDB.get_monster(2), "starter ID 2 exists")
	_assert_not_null(MonsterDB.get_monster(3), "starter ID 3 exists")

	# All monsters have front_sprite and back_sprite
	_begin("all_monsters_have_sprites")
	var sprite_failures := 0
	for id: int in MonsterDB.monsters:
		var data: Resource = MonsterDB.monsters[id]
		var name_str: String = str(data.get("monster_name"))
		var front: Variant = data.get("front_sprite")
		var back: Variant = data.get("back_sprite")
		if front == null:
			_fail("monster %s (id=%d) missing front_sprite" % [name_str, id])
			sprite_failures += 1
		if back == null:
			_fail("monster %s (id=%d) missing back_sprite" % [name_str, id])
			sprite_failures += 1
	if sprite_failures == 0:
		_pass("all 30 monsters have front + back sprites")

	# Audio files exist
	_begin("audio_files_exist")
	var audio_paths := [
		"res://assets/audio/music/town_theme.wav",
		"res://assets/audio/music/battle_theme.wav",
		"res://assets/audio/sfx/hit.wav",
		"res://assets/audio/sfx/faint.wav",
		"res://assets/audio/sfx/select.wav",
		"res://assets/audio/sfx/run.wav",
	]
	var audio_ok := true
	for audio_path: String in audio_paths:
		if not ResourceLoader.exists(audio_path):
			_fail("missing audio: %s" % audio_path)
			audio_ok = false
	if audio_ok:
		_pass("all 6 audio files exist")

# ══════════════════════════════════════════════
#  F. Performance Sanity Tests
# ══════════════════════════════════════════════

func _run_performance_tests() -> void:
	print("\n── Performance Sanity ──")

	# Re-load all monster resources < 2000ms
	_begin("perf_load_all_monsters")
	var start := Time.get_ticks_msec()
	for id: int in MonsterDB.monsters:
		var path := "res://data/monsters/monster_%03d.tres" % id
		if ResourceLoader.exists(path):
			load(path)
	var elapsed := Time.get_ticks_msec() - start
	_assert_lt(elapsed, 2000, "load all monsters in %dms (< 2000ms)" % elapsed)

	# Load battle scene < 1000ms
	_begin("perf_load_battle_scene")
	start = Time.get_ticks_msec()
	var _scene := load("res://scenes/battle/battle_scene.tscn")
	elapsed = Time.get_ticks_msec() - start
	_assert_lt(elapsed, 1000, "load battle scene in %dms (< 1000ms)" % elapsed)
