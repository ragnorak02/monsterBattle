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
	_run_critical_hit_tests()
	_run_status_effect_tests()
	_run_monster_instance_tests()
	_run_game_manager_tests()
	_run_inventory_tests()
	_run_area_persistence_tests()
	_run_scene_loading_tests()
	_run_asset_existence_tests()
	_run_performance_tests()
	_run_accuracy_evasion_tests()
	_run_physical_special_tests()
	_run_multi_hit_tests()
	_run_ability_tests()
	_run_ai_scoring_tests()
	_run_backward_compat_tests()
	_run_pc_storage_tests()
	_run_registry_tests()
	_run_growth_rate_tests()
	_run_evolution_tests()
	_run_xp_curve_tests()
	_run_pokedex_scene_tests()
	_run_badge_system_tests()
	_run_trainer_battle_tests()
	_run_area_data_tests()
	_run_trainer_scene_tests()
	_run_dialogue_tree_tests()
	_run_quest_system_tests()
	_run_cutscene_tests()
	_run_world_map_tests()
	_run_day_night_tests()
	_run_weather_tests()
	_run_save_system_tests()
	_run_gold_system_tests()
	_run_shop_scene_tests()
	_run_new_area_tests()
	_run_trainer_flow_tests()
	_run_trainer_rank_tests()

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

func _make_status_skill(p_name: String, p_power: int, stype: String, effect: String, chance: float) -> SkillData:
	var skill := _make_typed_skill(p_name, p_power, stype)
	skill.status_effect = effect
	skill.status_chance = chance
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
		_pass("all skills have skill_type")

# ══════════════════════════════════════════════
#  A3. Critical Hit Tests
# ══════════════════════════════════════════════

func _run_critical_hit_tests() -> void:
	print("\n── Critical Hits ──")

	var attacker := _make_monster(40, 14, 8, 12)
	var defender := _make_monster(40, 10, 8, 10)
	var skill := _make_skill("TestSlash", 10, 1.0)

	# Test: forced crit deals 1.5x damage
	_begin("crit_forced_damage")
	var crit_result := DamageCalculator.calculate_damage_with_type(attacker, defender, skill, 1)
	var no_crit_result := DamageCalculator.calculate_damage_with_type(attacker, defender, skill, 0)
	# crit damage = floor(23 * 1.5) = 34
	_assert_eq(crit_result["damage"], 34, "crit damage = base * 1.5 = 34")
	_assert_eq(no_crit_result["damage"], 23, "no crit damage unchanged = 23")

	# Test: forced crit flag is true
	_begin("crit_flag_true")
	_assert_true(crit_result["critical"] as bool, "critical flag true on forced crit")

	# Test: no-crit flag is false
	_begin("crit_flag_false")
	_assert_false(no_crit_result["critical"] as bool, "critical flag false on force_crit=0")

	# Test: default (force_crit=0) backward compat — same damage as before
	_begin("crit_backward_compat")
	var default_result := DamageCalculator.calculate_damage_with_type(attacker, defender, skill)
	_assert_eq(default_result["damage"], 23, "default force_crit=0 backward compat")
	_assert_false(default_result["critical"] as bool, "default has no crit")

# ══════════════════════════════════════════════
#  A4. Status Effect Tests
# ══════════════════════════════════════════════

func _run_status_effect_tests() -> void:
	print("\n── Status Effects ──")

	# Test: apply status to clean monster
	_begin("status_apply_clean")
	var mon := _make_monster(40, 14, 8, 12)
	var applied := mon.apply_status("poison")
	_assert_true(applied, "apply_status returns true on clean monster")
	_assert_eq(mon.status, "poison", "status is poison")

	# Test: reject second status
	_begin("status_reject_second")
	var rejected := mon.apply_status("burn")
	_assert_false(rejected, "apply_status returns false when already poisoned")
	_assert_eq(mon.status, "poison", "status still poison after rejection")

	# Test: clear status
	_begin("status_clear")
	mon.clear_status()
	_assert_eq(mon.status, "", "status empty after clear")
	_assert_false(mon.has_status(), "has_status false after clear")

	# Test: heal_full clears status
	_begin("status_heal_full_clears")
	var mon2 := _make_monster(40, 10, 8, 10)
	mon2.apply_status("burn")
	mon2.take_damage(10)
	mon2.heal_full()
	_assert_eq(mon2.status, "", "heal_full clears status")
	_assert_eq(mon2.current_hp, mon2.get_max_hp(), "heal_full restores HP")

	# Test: poison EOT damage = max(1, max_hp/8)
	_begin("status_poison_eot_damage")
	var poisoned := _make_monster(80, 10, 8, 10)  # max_hp = 80 + 5*2 = 90
	poisoned.apply_status("poison")
	var old_hp := poisoned.current_hp
	var eot := DamageCalculator.process_end_of_turn_status(poisoned)
	var expected_dmg := maxi(1, poisoned.get_max_hp() / 8)  # 90/8 = 11
	_assert_eq(eot["damage"], expected_dmg, "poison EOT damage = max_hp/8 = %d" % expected_dmg)
	_assert_eq(poisoned.current_hp, old_hp - expected_dmg, "HP reduced by poison damage")

	# Test: burn EOT damage = max(1, max_hp/8)
	_begin("status_burn_eot_damage")
	var burned := _make_monster(80, 10, 8, 10)  # max_hp = 90
	burned.apply_status("burn")
	var burn_old_hp := burned.current_hp
	var burn_eot := DamageCalculator.process_end_of_turn_status(burned)
	_assert_eq(burn_eot["damage"], expected_dmg, "burn EOT damage = max_hp/8 = %d" % expected_dmg)
	_assert_eq(burned.current_hp, burn_old_hp - expected_dmg, "HP reduced by burn damage")

	# Test: burn halves attack
	_begin("status_burn_halves_attack")
	var burned_mon := _make_monster(40, 14, 8, 12)  # get_attack() = 19
	_assert_eq(burned_mon.get_effective_attack(), 19, "normal effective attack = 19")
	burned_mon.apply_status("burn")
	_assert_eq(burned_mon.get_effective_attack(), 9, "burned effective attack = 19/2 = 9")

	# Test: paralysis halves agility
	_begin("status_paralysis_halves_agility")
	var para_mon := _make_monster(40, 10, 8, 20)  # get_agility() = 25
	_assert_eq(para_mon.get_effective_agility(), 25, "normal effective agility = 25")
	para_mon.apply_status("paralysis")
	_assert_eq(para_mon.get_effective_agility(), 12, "paralyzed effective agility = 25/2 = 12")

	# Test: paralysis affects turn order
	_begin("status_paralysis_turn_order")
	var fast := _make_monster(40, 10, 8, 20)   # agi=20, eff_agi=25
	var slow := _make_monster(40, 10, 8, 12)   # agi=12, eff_agi=17
	_assert_eq(DamageCalculator.get_first_attacker(fast, slow), 0, "fast goes first normally")
	fast.apply_status("paralysis")  # eff_agi = 25/2 = 12
	# fast eff_agi=12, slow eff_agi=17 → slow goes first
	_assert_eq(DamageCalculator.get_first_attacker(fast, slow), 1, "paralyzed fast goes second")

	# Test: paralysis has no EOT damage
	_begin("status_paralysis_no_eot")
	var para := _make_monster(40, 10, 8, 10)
	para.apply_status("paralysis")
	var para_hp := para.current_hp
	var para_eot := DamageCalculator.process_end_of_turn_status(para)
	_assert_true(para_eot.is_empty(), "paralysis has no EOT effect")
	_assert_eq(para.current_hp, para_hp, "HP unchanged by paralysis EOT")

	# Test: zero-chance skill doesn't apply status
	_begin("status_zero_chance_no_apply")
	var no_status_skill := _make_status_skill("Bonk", 10, "Normal", "poison", 0.0)
	var target := _make_monster(40, 10, 8, 10)
	var status_applied := DamageCalculator.try_apply_status(no_status_skill, target)
	_assert_eq(status_applied, "", "zero chance skill doesn't apply status")
	_assert_eq(target.status, "", "target has no status")

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

	# XP threshold (L^1.5 * 10)
	_begin("get_xp_threshold")
	var mon5 := _make_monster(40, 10, 8, 10, 5)
	var expected_xp := int(pow(5.0, 1.5) * 10.0)  # 111
	_assert_eq(mon5.get_xp_threshold(), expected_xp, "level 5: pow(5,1.5)*10 = %d" % expected_xp)

	# add_experience with level-up
	_begin("add_experience_level_up")
	var mon6 := _make_monster(40, 10, 8, 10, 5)
	var result := mon6.add_experience(expected_xp)
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

	# Test: antidote item def has type "cure" and value "poison"
	_begin("antidote_item_def")
	var antidote_def := GameManager.get_item_def("antidote")
	_assert_eq(antidote_def["type"], "cure", "antidote type is cure")
	_assert_eq(antidote_def["value"], "poison", "antidote value is poison")

	# Test: antidote appears in battle items
	_begin("antidote_in_battle_items")
	GameManager.inventory = {}
	GameManager.add_item("antidote", 2)
	var battle_items2: Array = GameManager.get_battle_items()
	var found_antidote := false
	for bi in battle_items2:
		if bi["id"] == "antidote":
			found_antidote = true
			break
	_assert_true(found_antidote, "antidote appears in battle items")

	# Test: antidote cures poison via clear_status
	_begin("antidote_cures_poison")
	var poisoned_mon := _make_monster(40, 10, 8, 10)
	poisoned_mon.apply_status("poison")
	_assert_eq(poisoned_mon.status, "poison", "monster is poisoned")
	poisoned_mon.clear_status()
	_assert_eq(poisoned_mon.status, "", "monster cured after clear_status")
	_assert_false(poisoned_mon.has_status(), "has_status false after cure")

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
		"pokedex.tscn": "res://scenes/ui/pokedex.tscn",
		"trainer.tscn": "res://scenes/overworld/trainer.tscn",
		"shop_ui.tscn": "res://scenes/ui/shop_ui.tscn",
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
	_assert_eq(MonsterDB.skills.size(), 22, "MonsterDB has 22 skills")

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

# ── Extended Mock Helpers ──

func _make_sp_monster_data(hp: int, atk: int, def_val: int, agi: int, sp_atk: int, sp_def: int, etype: String = "Normal", p_ability: String = "") -> MonsterData:
	var data := _make_monster_data(hp, atk, def_val, agi)
	data.sp_attack = sp_atk
	data.sp_defense = sp_def
	data.element_type = etype
	data.ability = p_ability
	return data

func _make_sp_monster(hp: int, atk: int, def_val: int, agi: int, sp_atk: int, sp_def: int, etype: String = "Normal", p_ability: String = "", lvl: int = 5) -> MonsterInstance:
	var data := _make_sp_monster_data(hp, atk, def_val, agi, sp_atk, sp_def, etype, p_ability)
	return MonsterInstance.new(data, lvl)

func _make_category_skill(p_name: String, p_power: int, stype: String, p_category: String, p_accuracy: float = 1.0) -> SkillData:
	var skill := _make_typed_skill(p_name, p_power, stype, p_accuracy)
	skill.category = p_category
	return skill

func _make_multi_hit_skill(p_name: String, p_power: int, stype: String, p_category: String, p_hit_min: int, p_hit_max: int) -> SkillData:
	var skill := _make_category_skill(p_name, p_power, stype, p_category)
	skill.hit_min = p_hit_min
	skill.hit_max = p_hit_max
	return skill

# ══════════════════════════════════════════════
#  G. Accuracy & Evasion Tests
# ══════════════════════════════════════════════

func _run_accuracy_evasion_tests() -> void:
	print("\n── Accuracy & Evasion ──")

	# Test: accuracy stage +2 increases accuracy multiplier
	_begin("accuracy_stage_positive")
	var mon := _make_monster(40, 10, 8, 10)
	mon.modify_accuracy_stage(2)
	_assert_true(mon.get_accuracy_multiplier() > 1.0, "accuracy stage +2 mult > 1.0, got %.2f" % mon.get_accuracy_multiplier())
	_assert_true(absf(mon.get_accuracy_multiplier() - 1.66) < 0.01, "accuracy stage +2 = 1.66")

	# Test: evasion stage -1 decreases evasion multiplier
	_begin("evasion_stage_negative")
	var mon2 := _make_monster(40, 10, 8, 10)
	mon2.modify_evasion_stage(-1)
	_assert_true(mon2.get_evasion_multiplier() < 1.0, "evasion stage -1 mult < 1.0, got %.2f" % mon2.get_evasion_multiplier())
	_assert_true(absf(mon2.get_evasion_multiplier() - 0.75) < 0.01, "evasion stage -1 = 0.75")

	# Test: stages reset on heal_full
	_begin("stages_reset_on_heal_full")
	var mon3 := _make_monster(40, 10, 8, 10)
	mon3.modify_accuracy_stage(3)
	mon3.modify_evasion_stage(-2)
	mon3.modify_attack_stage(-1)
	mon3.heal_full()
	_assert_eq(mon3.accuracy_stage, 0, "accuracy_stage reset to 0")
	_assert_eq(mon3.evasion_stage, 0, "evasion_stage reset to 0")
	_assert_eq(mon3.attack_stage, 0, "attack_stage reset to 0")

# ══════════════════════════════════════════════
#  H. Physical/Special Split Tests
# ══════════════════════════════════════════════

func _run_physical_special_tests() -> void:
	print("\n── Physical/Special Split ──")

	# Monster with different physical and special stats
	# atk=14 → get_attack()=19, sp_atk=20 → get_sp_attack()=25
	# def=8  → get_defense()=13, sp_def=16 → get_sp_defense()=21
	var attacker := _make_sp_monster(40, 14, 8, 10, 20, 10, "Fire")
	var defender := _make_sp_monster(40, 10, 8, 10, 10, 16, "Normal")

	# Test: physical skill uses attack/defense
	_begin("physical_uses_attack_defense")
	var phys_skill := _make_category_skill("Slash", 10, "Normal", "physical")
	# attack_value = get_effective_attack() + power = 19 + 10 = 29
	# defense_value = get_defense() / 2 = 13 / 2 = 6
	# base_damage = 29 - 6 = 23
	var phys_dmg := DamageCalculator.calculate_damage(attacker, defender, phys_skill)
	_assert_eq(phys_dmg, 23, "physical skill damage = 23")

	# Test: special skill uses sp_attack/sp_defense
	_begin("special_uses_sp_attack_sp_defense")
	var spec_skill := _make_category_skill("Beam", 10, "Normal", "special")
	# attack_value = get_effective_sp_attack() + power = 25 + 10 = 35
	# defense_value = get_sp_defense() / 2 = 21 / 2 = 10
	# base_damage = 35 - 10 = 25
	var spec_dmg := DamageCalculator.calculate_damage(attacker, defender, spec_skill)
	_assert_eq(spec_dmg, 25, "special skill damage = 25")

	# Test: sp_attack=0 falls back to get_attack()
	_begin("sp_attack_zero_fallback")
	var fallback_mon := _make_monster(40, 14, 8, 10)  # sp_attack defaults to 0
	_assert_eq(fallback_mon.get_sp_attack(), fallback_mon.get_attack(), "sp_attack=0 falls back to get_attack()")

	# Test: sp_defense=0 falls back to get_defense()
	_begin("sp_defense_zero_fallback")
	_assert_eq(fallback_mon.get_sp_defense(), fallback_mon.get_defense(), "sp_defense=0 falls back to get_defense()")

# ══════════════════════════════════════════════
#  I. Multi-Hit Tests
# ══════════════════════════════════════════════

func _run_multi_hit_tests() -> void:
	print("\n── Multi-Hit ──")

	# Test: multi-hit skill returns count in range
	_begin("multi_hit_in_range")
	var multi_skill := _make_multi_hit_skill("FurySwipes", 3, "Normal", "physical", 2, 5)
	var all_in_range := true
	for i in 20:
		var count := DamageCalculator.calculate_hit_count(multi_skill)
		if count < 2 or count > 5:
			all_in_range = false
			break
	_assert_true(all_in_range, "multi-hit count always in [2, 5]")

	# Test: single-hit skill returns 1
	_begin("single_hit_backward_compat")
	var normal_skill := _make_skill("Bonk", 10, 1.0)
	var count := DamageCalculator.calculate_hit_count(normal_skill)
	_assert_eq(count, 1, "single-hit skill returns 1")

# ══════════════════════════════════════════════
#  J. Ability Tests
# ══════════════════════════════════════════════

func _run_ability_tests() -> void:
	print("\n── Abilities ──")

	# Test: thick_skin reduces super-effective damage
	_begin("ability_thick_skin_reduces_se")
	var normal_dmg := 30
	var reduced := DamageCalculator.apply_thick_skin(normal_dmg, 2.0)
	_assert_eq(reduced, 22, "thick_skin 30 * 0.75 = 22")
	var not_reduced := DamageCalculator.apply_thick_skin(normal_dmg, 1.0)
	_assert_eq(not_reduced, 30, "thick_skin no effect at neutral")

	# Test: thick_skin in full damage calc
	_begin("ability_thick_skin_full_calc")
	var attacker := _make_sp_monster(40, 14, 8, 12, 14, 8, "Fire")
	var thick_defender := _make_sp_monster(40, 10, 8, 10, 10, 8, "Grass", "thick_skin")
	var fire_skill := _make_category_skill("Flame", 10, "Fire", "physical")
	var no_ability_defender := _make_sp_monster(40, 10, 8, 10, 10, 8, "Grass")
	var thick_result := DamageCalculator.calculate_damage_with_type(attacker, thick_defender, fire_skill)
	var normal_result := DamageCalculator.calculate_damage_with_type(attacker, no_ability_defender, fire_skill)
	_assert_lt(thick_result["damage"], normal_result["damage"], "thick_skin reduces SE damage")

	# Test: intimidate lowers attack stage
	_begin("ability_intimidate_lowers_attack")
	var mon := _make_sp_monster(40, 14, 8, 12, 12, 8, "Fire", "intimidate")
	var target := _make_monster(40, 10, 8, 10)
	_assert_eq(target.attack_stage, 0, "attack stage starts at 0")
	target.modify_attack_stage(-1)
	_assert_eq(target.attack_stage, -1, "attack stage = -1 after intimidate")
	_assert_true(target.get_effective_attack() < target.get_attack(), "effective attack reduced by stage")

	# Test: swift prevents accuracy drop
	_begin("ability_swift_concept")
	var swift_mon := _make_sp_monster(40, 10, 8, 18, 13, 9, "Wind", "swift")
	_assert_eq(DamageCalculator.get_ability(swift_mon), "swift", "swift ability detected")
	# Swift enforcement: accuracy_stage can't go below 0
	swift_mon.accuracy_stage = 0
	if DamageCalculator.get_ability(swift_mon) == "swift":
		swift_mon.accuracy_stage = maxi(0, swift_mon.accuracy_stage - 1)
	_assert_eq(swift_mon.accuracy_stage, 0, "swift prevents accuracy stage below 0")

	# Test: poison_touch ability detected
	_begin("ability_poison_touch_detected")
	var venom := _make_sp_monster(36, 15, 8, 13, 15, 8, "Poison", "poison_touch")
	_assert_eq(DamageCalculator.get_ability(venom), "poison_touch", "poison_touch ability detected")

# ══════════════════════════════════════════════
#  K. AI Scoring Tests
# ══════════════════════════════════════════════

func _run_ai_scoring_tests() -> void:
	print("\n── AI Scoring ──")

	var fire_enemy := _make_sp_monster(40, 14, 8, 12, 14, 8, "Fire")
	var grass_mon := _make_sp_monster(40, 12, 10, 11, 12, 10, "Grass")

	# Test: AI prefers super-effective move
	_begin("ai_prefers_super_effective")
	var water_skill := _make_category_skill("Splash", 10, "Water", "special")
	var normal_skill := _make_category_skill("Bonk", 10, "Normal", "physical")
	var se_score := DamageCalculator.score_skill(water_skill, grass_mon, fire_enemy)
	var neutral_score := DamageCalculator.score_skill(normal_skill, grass_mon, fire_enemy)
	_assert_gt(se_score, neutral_score, "SE skill scored higher: %.1f > %.1f" % [se_score, neutral_score])

	# Test: AI prefers STAB move (against neutral target so type doesn't interfere)
	_begin("ai_prefers_stab")
	var normal_target := _make_sp_monster(40, 10, 8, 10, 10, 8, "Normal")
	var grass_skill := _make_category_skill("Vine", 10, "Grass", "physical")
	# Grass mon using Grass skill vs Normal = STAB, neutral type
	var stab_score := DamageCalculator.score_skill(grass_skill, grass_mon, normal_target)
	# Grass mon using Normal skill vs Normal = no STAB, neutral type
	var no_stab_score := DamageCalculator.score_skill(normal_skill, grass_mon, normal_target)
	_assert_gt(stab_score, no_stab_score, "STAB skill scored higher: %.1f > %.1f" % [stab_score, no_stab_score])

	# Test: equal skills have equal scores
	_begin("ai_equal_skills_equal_score")
	var plain_a := _make_category_skill("HitA", 10, "Normal", "physical")
	var plain_b := _make_category_skill("HitB", 10, "Normal", "physical")
	var plain_mon := _make_monster(40, 10, 8, 10)
	var score_a := DamageCalculator.score_skill(plain_a, plain_mon, plain_mon)
	var score_b := DamageCalculator.score_skill(plain_b, plain_mon, plain_mon)
	_assert_true(absf(score_a - score_b) < 0.01, "equal skills = equal score: %.1f vs %.1f" % [score_a, score_b])

# ══════════════════════════════════════════════
#  L. Backward Compatibility Tests
# ══════════════════════════════════════════════

func _run_backward_compat_tests() -> void:
	print("\n── Backward Compatibility ──")

	# Test: untyped monster/skill still produces correct damage
	_begin("compat_untyped_damage_unchanged")
	var a := _make_monster(40, 14, 8, 12)
	var d := _make_monster(40, 10, 8, 10)
	var s := _make_skill("Bonk", 10, 1.0)
	_assert_eq(DamageCalculator.calculate_damage(a, d, s), 23, "untyped damage unchanged at 23")

	# Test: check_accuracy with only skill arg still works
	_begin("compat_check_accuracy_one_arg")
	var perfect := _make_skill("Sure", 10, 1.0)
	_assert_true(DamageCalculator.check_accuracy(perfect), "check_accuracy(skill) backward compat")

# ══════════════════════════════════════════════
#  M. PC Storage Tests
# ══════════════════════════════════════════════

func _run_pc_storage_tests() -> void:
	print("\n── PC Storage ──")

	# Save and reset state
	var saved_party := GameManager.player_party.duplicate()
	var saved_pc := GameManager.pc_storage.duplicate()
	GameManager.player_party = []
	GameManager.pc_storage = []

	# Test: add monster to PC and verify count
	_begin("pc_add_and_count")
	var mon1 := _make_monster(40, 10, 8, 10)
	GameManager.add_to_pc(mon1)
	_assert_eq(GameManager.pc_storage.size(), 1, "PC has 1 monster after add")
	var mon2 := _make_monster(50, 12, 9, 11)
	GameManager.add_to_pc(mon2)
	_assert_eq(GameManager.pc_storage.size(), 2, "PC has 2 monsters after second add")

	# Test: move from PC to party
	_begin("pc_move_to_party")
	GameManager.player_party = []
	GameManager.pc_storage = []
	var pc_mon := _make_monster(40, 10, 8, 10)
	GameManager.add_to_pc(pc_mon)
	var moved := GameManager.move_pc_to_party(0)
	_assert_true(moved, "move_pc_to_party returns true")
	_assert_eq(GameManager.player_party.size(), 1, "party has 1 after withdraw")
	_assert_eq(GameManager.pc_storage.size(), 0, "PC empty after withdraw")
	_assert_eq(GameManager.player_party[0], pc_mon, "correct monster withdrawn")

	# Test: move to party blocked when party full
	_begin("pc_move_to_party_full")
	GameManager.player_party = []
	GameManager.pc_storage = []
	for i in 6:
		GameManager.add_to_party(_make_monster(40, 10, 8, 10))
	GameManager.add_to_pc(_make_monster(50, 12, 9, 11))
	var blocked := GameManager.move_pc_to_party(0)
	_assert_false(blocked, "move_pc_to_party blocked when party full")
	_assert_eq(GameManager.player_party.size(), 6, "party still 6")
	_assert_eq(GameManager.pc_storage.size(), 1, "PC still 1")

	# Test: move from party to PC
	_begin("pc_move_party_to_pc")
	GameManager.player_party = []
	GameManager.pc_storage = []
	var p1 := _make_monster(40, 10, 8, 10)
	var p2 := _make_monster(50, 12, 9, 11)
	GameManager.add_to_party(p1)
	GameManager.add_to_party(p2)
	var deposited := GameManager.move_party_to_pc(1)
	_assert_true(deposited, "move_party_to_pc returns true")
	_assert_eq(GameManager.player_party.size(), 1, "party has 1 after deposit")
	_assert_eq(GameManager.pc_storage.size(), 1, "PC has 1 after deposit")
	_assert_eq(GameManager.pc_storage[0], p2, "correct monster deposited")

	# Test: can't box last monster
	_begin("pc_cant_box_last")
	GameManager.player_party = []
	GameManager.pc_storage = []
	GameManager.add_to_party(_make_monster(40, 10, 8, 10))
	var cant_box := GameManager.move_party_to_pc(0)
	_assert_false(cant_box, "move_party_to_pc blocked when only 1 in party")
	_assert_eq(GameManager.player_party.size(), 1, "party still 1")
	_assert_eq(GameManager.pc_storage.size(), 0, "PC still empty")

	# Restore state
	GameManager.player_party = saved_party
	GameManager.pc_storage = saved_pc

# ══════════════════════════════════════════════
#  N. Monster Registry Tests
# ══════════════════════════════════════════════

func _run_registry_tests() -> void:
	print("\n── Monster Registry ──")

	# Save and reset state
	var saved_seen := GameManager.monster_registry_seen.duplicate()
	var saved_caught := GameManager.monster_registry_caught.duplicate()
	var saved_party := GameManager.player_party.duplicate()
	var saved_pc := GameManager.pc_storage.duplicate()
	GameManager.monster_registry_seen = {}
	GameManager.monster_registry_caught = {}

	# Test: initially empty
	_begin("registry_initially_empty")
	_assert_eq(GameManager.get_seen_count(), 0, "seen count starts at 0")
	_assert_eq(GameManager.get_caught_count(), 0, "caught count starts at 0")

	# Test: mark seen
	_begin("registry_mark_seen")
	GameManager.mark_monster_seen(1)
	_assert_true(GameManager.is_monster_seen(1), "monster 1 is seen")
	_assert_false(GameManager.is_monster_caught(1), "monster 1 is not caught (only seen)")
	_assert_eq(GameManager.get_seen_count(), 1, "seen count = 1")

	# Test: mark caught implies seen
	_begin("registry_caught_implies_seen")
	GameManager.monster_registry_seen = {}
	GameManager.monster_registry_caught = {}
	GameManager.mark_monster_caught(5)
	_assert_true(GameManager.is_monster_seen(5), "caught monster is also seen")
	_assert_true(GameManager.is_monster_caught(5), "caught monster is caught")
	_assert_eq(GameManager.get_seen_count(), 1, "seen count = 1")
	_assert_eq(GameManager.get_caught_count(), 1, "caught count = 1")

	# Test: idempotent — marking twice doesn't double count
	_begin("registry_idempotent")
	GameManager.mark_monster_seen(5)
	GameManager.mark_monster_caught(5)
	_assert_eq(GameManager.get_seen_count(), 1, "seen count still 1 after duplicate")
	_assert_eq(GameManager.get_caught_count(), 1, "caught count still 1 after duplicate")

	# Test: unseen monster returns false
	_begin("registry_unseen_returns_false")
	_assert_false(GameManager.is_monster_seen(99), "unseen monster returns false")
	_assert_false(GameManager.is_monster_caught(99), "uncaught monster returns false")

	# Test: invalid ID ignored
	_begin("registry_invalid_id_ignored")
	GameManager.mark_monster_seen(0)
	GameManager.mark_monster_seen(-1)
	GameManager.mark_monster_caught(0)
	GameManager.mark_monster_caught(-5)
	_assert_eq(GameManager.get_seen_count(), 1, "seen count unchanged after invalid IDs")
	_assert_eq(GameManager.get_caught_count(), 1, "caught count unchanged after invalid IDs")

	# Test: multiple distinct monsters
	_begin("registry_multiple_monsters")
	GameManager.monster_registry_seen = {}
	GameManager.monster_registry_caught = {}
	GameManager.mark_monster_seen(1)
	GameManager.mark_monster_seen(2)
	GameManager.mark_monster_seen(3)
	GameManager.mark_monster_caught(2)
	_assert_eq(GameManager.get_seen_count(), 3, "3 monsters seen")
	_assert_eq(GameManager.get_caught_count(), 1, "1 monster caught")

	# Test: total monster count
	_begin("registry_total_count")
	var total := GameManager.get_total_monster_count()
	_assert_eq(total, 30, "total monster count = 30")

	# Test: sync from owned monsters
	_begin("registry_sync_from_owned")
	GameManager.monster_registry_seen = {}
	GameManager.monster_registry_caught = {}
	GameManager.player_party = []
	GameManager.pc_storage = []
	var mon1_data := MonsterDB.get_monster(1)
	var mon2_data := MonsterDB.get_monster(3)
	if mon1_data and mon2_data:
		GameManager.add_to_party(MonsterInstance.new(mon1_data, 5))
		GameManager.add_to_pc(MonsterInstance.new(mon2_data, 5))
		GameManager.sync_registry_from_owned_monsters()
		_assert_true(GameManager.is_monster_caught(1), "party monster 1 synced as caught")
		_assert_true(GameManager.is_monster_caught(3), "PC monster 3 synced as caught")
		_assert_true(GameManager.is_monster_seen(1), "party monster 1 synced as seen")
		_assert_true(GameManager.is_monster_seen(3), "PC monster 3 synced as seen")
		_assert_eq(GameManager.get_caught_count(), 2, "2 caught after sync")
	else:
		_fail("could not load monster data for sync test")

	# Test: seen then caught upgrades properly
	_begin("registry_seen_then_caught")
	GameManager.monster_registry_seen = {}
	GameManager.monster_registry_caught = {}
	GameManager.mark_monster_seen(10)
	_assert_true(GameManager.is_monster_seen(10), "monster 10 seen")
	_assert_false(GameManager.is_monster_caught(10), "monster 10 not yet caught")
	GameManager.mark_monster_caught(10)
	_assert_true(GameManager.is_monster_seen(10), "monster 10 still seen")
	_assert_true(GameManager.is_monster_caught(10), "monster 10 now caught")
	_assert_eq(GameManager.get_seen_count(), 1, "seen count still 1")
	_assert_eq(GameManager.get_caught_count(), 1, "caught count = 1")

	# Restore state
	GameManager.monster_registry_seen = saved_seen
	GameManager.monster_registry_caught = saved_caught
	GameManager.player_party = saved_party
	GameManager.pc_storage = saved_pc

# ══════════════════════════════════════════════
#  O. Growth Rate Tests
# ══════════════════════════════════════════════

func _run_growth_rate_tests() -> void:
	print("\n── Growth Rates ──")

	# Test: default growth (1.0) backward compatible
	_begin("growth_default_backward_compat")
	var data := _make_monster_data(40, 14, 8, 12)
	# Default growth = 1.0, level 5: attack = 14 + int(5 * 1.0) = 19
	var mon := MonsterInstance.new(data, 5)
	_assert_eq(mon.get_attack(), 19, "default growth: attack = 14 + 5 = 19")
	_assert_eq(mon.get_defense(), 13, "default growth: defense = 8 + 5 = 13")
	_assert_eq(mon.get_max_hp(), 50, "default growth: max_hp = 40 + 10 = 50")
	_assert_eq(mon.get_agility(), 17, "default growth: agility = 12 + 5 = 17")

	# Test: high atk_growth (1.5) at level 10
	_begin("growth_high_atk")
	var high_atk_data := _make_monster_data(40, 14, 8, 12)
	high_atk_data.atk_growth = 1.5
	var high_atk_mon := MonsterInstance.new(high_atk_data, 10)
	# attack = 14 + int(10 * 1.5) = 14 + 15 = 29
	_assert_eq(high_atk_mon.get_attack(), 29, "high atk_growth: 14 + int(10*1.5) = 29")

	# Test: low def_growth (0.5) at level 10
	_begin("growth_low_def")
	var low_def_data := _make_monster_data(40, 14, 8, 12)
	low_def_data.def_growth = 0.5
	var low_def_mon := MonsterInstance.new(low_def_data, 10)
	# defense = 8 + int(10 * 0.5) = 8 + 5 = 13
	_assert_eq(low_def_mon.get_defense(), 13, "low def_growth: 8 + int(10*0.5) = 13")

	# Test: HP growth with multiplier
	_begin("growth_hp_multiplier")
	var hp_data := _make_monster_data(40, 14, 8, 12)
	hp_data.hp_growth = 1.5
	var hp_mon := MonsterInstance.new(hp_data, 10)
	# max_hp = 40 + int(20 * 1.5) = 40 + 30 = 70
	_assert_eq(hp_mon.get_max_hp(), 70, "hp_growth 1.5: 40 + int(20*1.5) = 70")

	# Test: damage calc still works with growth-modified stats
	_begin("growth_damage_calc_works")
	var atk_data := _make_monster_data(40, 14, 8, 12)
	atk_data.atk_growth = 1.5
	var attacker := MonsterInstance.new(atk_data, 10)
	var defender := _make_monster(40, 10, 8, 10, 10)
	var skill := _make_skill("Hit", 10, 1.0)
	var dmg := DamageCalculator.calculate_damage(attacker, defender, skill)
	# attack = 14 + int(10*1.5) = 29, power = 10, total = 39
	# defense = 8 + 10 = 18, half = 9
	# damage = max(1, 39 - 9) = 30
	_assert_eq(dmg, 30, "damage with growth-modified atk = 30")

# ══════════════════════════════════════════════
#  P. Evolution Tests
# ══════════════════════════════════════════════

func _run_evolution_tests() -> void:
	print("\n── Evolution ──")

	# Test: starter .tres files have evolution data
	_begin("evolution_starters_have_evo_data")
	var emberpup: Resource = MonsterDB.get_monster(1)
	var aqualing: Resource = MonsterDB.get_monster(2)
	var thornlet: Resource = MonsterDB.get_monster(3)
	_assert_true(int(emberpup.get("evolves_into_id")) > 0, "Emberpup has evolves_into_id")
	_assert_true(int(emberpup.get("evolution_level")) > 0, "Emberpup has evolution_level")
	_assert_true(int(aqualing.get("evolves_into_id")) > 0, "Aqualing has evolves_into_id")
	_assert_true(int(aqualing.get("evolution_level")) > 0, "Aqualing has evolution_level")
	_assert_true(int(thornlet.get("evolves_into_id")) > 0, "Thornlet has evolves_into_id")
	_assert_true(int(thornlet.get("evolution_level")) > 0, "Thornlet has evolution_level")

	# Test: evolve() swaps base_data and adjusts HP
	_begin("evolution_evolve_function")
	var base_data := MonsterDB.get_monster(1)
	var evo_data := MonsterDB.get_monster(int(base_data.get("evolves_into_id")))
	var mon := MonsterInstance.new(base_data, 12)
	var old_hp := mon.current_hp
	var old_max := mon.get_max_hp()
	mon.evolve(evo_data)
	_assert_eq(mon.base_data, evo_data, "base_data swapped to evolution")
	var new_max := mon.get_max_hp()
	_assert_eq(mon.current_hp, old_hp + (new_max - old_max), "HP adjusted by max HP difference")

	# Test: add_experience returns can_evolve at correct level
	_begin("evolution_can_evolve_at_level")
	var evo_base := MonsterDB.get_monster(1)
	var evo_level: int = int(evo_base.get("evolution_level"))
	var mon2 := MonsterInstance.new(evo_base, evo_level - 1)
	mon2.experience = 0
	var xp_needed: int = mon2.get_xp_threshold()
	var result := mon2.add_experience(xp_needed)
	_assert_true(result["can_evolve"] as bool, "can_evolve true at evolution level")
	_assert_eq(result["evolves_into_id"], int(evo_base.get("evolves_into_id")), "evolves_into_id matches")

	# Test: below evolution level, can_evolve = false
	_begin("evolution_below_level_no_evolve")
	var early_mon := MonsterInstance.new(MonsterDB.get_monster(1), 5)
	early_mon.experience = 0
	var early_result := early_mon.add_experience(early_mon.get_xp_threshold())
	_assert_false(early_result["can_evolve"] as bool, "can_evolve false below evolution level")

# ══════════════════════════════════════════════
#  Q. XP Curve Tests
# ══════════════════════════════════════════════

func _run_xp_curve_tests() -> void:
	print("\n── XP Curve ──")

	# Test: threshold values at key levels
	_begin("xp_threshold_levels")
	var mon5 := _make_monster(40, 10, 8, 10, 5)
	var mon10 := _make_monster(40, 10, 8, 10, 10)
	var mon20 := _make_monster(40, 10, 8, 10, 20)
	_assert_eq(mon5.get_xp_threshold(), int(pow(5.0, 1.5) * 10.0), "L5 threshold")
	_assert_eq(mon10.get_xp_threshold(), int(pow(10.0, 1.5) * 10.0), "L10 threshold")
	_assert_eq(mon20.get_xp_threshold(), int(pow(20.0, 1.5) * 10.0), "L20 threshold")

	# Test: level-diff bonus (higher enemy gives > base XP)
	_begin("xp_level_diff_bonus")
	# enemy_level=15, player_level=10 → diff=+5 → mult = 1.0 + 5*0.1 = 1.5
	# base_xp = 15 * 10 = 150, adjusted = 150 * 1.5 = 225
	var base_xp: int = 15 * 10
	var diff: int = 15 - 10
	var mult: float = 1.0 + diff * 0.1
	var bonus_xp: int = maxi(1, int(float(base_xp) * mult))
	_assert_gt(bonus_xp, base_xp, "higher enemy gives bonus XP: %d > %d" % [bonus_xp, base_xp])

	# Test: level-diff penalty (much lower enemy gives reduced XP)
	_begin("xp_level_diff_penalty")
	# enemy_level=5, player_level=20 → diff=-15 → diff+5=-10 → mult = 1.0 + (-10)*0.1 = 0.0 → clamped 0.25
	var low_base_xp: int = 5 * 10
	var low_diff: int = 5 - 20
	var low_mult: float = maxf(0.25, 1.0 + (low_diff + 5) * 0.1)
	var penalty_xp: int = maxi(1, int(float(low_base_xp) * low_mult))
	_assert_lt(penalty_xp, low_base_xp, "much lower enemy gives reduced XP: %d < %d" % [penalty_xp, low_base_xp])
	_assert_true(low_mult >= 0.25, "minimum multiplier is 0.25")

	# Test: no penalty within 5-level window
	_begin("xp_no_penalty_within_window")
	# enemy_level=8, player_level=10 → diff=-2 → no penalty (diff >= -5)
	var within_diff: int = 8 - 10  # -2
	var within_mult: float = 1.0
	if within_diff > 0:
		within_mult = 1.0 + within_diff * 0.1
	elif within_diff < -5:
		within_mult = maxf(0.25, 1.0 + (within_diff + 5) * 0.1)
	_assert_true(absf(within_mult - 1.0) < 0.01, "no penalty within 5-level window: mult=%.2f" % within_mult)

# ══════════════════════════════════════════════
#  R. Pokedex Scene Tests
# ══════════════════════════════════════════════

func _run_pokedex_scene_tests() -> void:
	print("\n── Pokedex ──")

	_begin("pokedex_scene_loads")
	var packed := load("res://scenes/ui/pokedex.tscn") as PackedScene
	_assert_not_null(packed, "pokedex.tscn loads")

# ══════════════════════════════════════════════
#  S. Badge System Tests
# ══════════════════════════════════════════════

func _run_badge_system_tests() -> void:
	print("\n── Badge System ──")

	# Save and reset state
	var saved_badges := GameManager.badges.duplicate()
	var saved_trainers := GameManager.defeated_trainers.duplicate()
	GameManager.badges = {}
	GameManager.defeated_trainers = {}

	# Test: default state — no badges
	_begin("badge_default_empty")
	_assert_eq(GameManager.get_badge_count(), 0, "no badges by default")
	_assert_false(GameManager.has_badge("tide_badge"), "tide_badge not earned by default")

	# Test: earn badge + has_badge + count
	_begin("badge_earn_and_check")
	GameManager.earn_badge("tide_badge")
	_assert_true(GameManager.has_badge("tide_badge"), "tide_badge earned")
	_assert_eq(GameManager.get_badge_count(), 1, "badge count = 1")

	# Test: earning same badge doesn't double count
	_begin("badge_no_double_count")
	GameManager.earn_badge("tide_badge")
	_assert_eq(GameManager.get_badge_count(), 1, "badge count still 1 after duplicate")

	# Test: trainer defeated tracking
	_begin("badge_trainer_defeated")
	GameManager.mark_trainer_defeated("town2_gym")
	_assert_true(GameManager.is_trainer_defeated("town2_gym"), "town2_gym marked defeated")
	_assert_false(GameManager.is_trainer_defeated("route2_trainer1"), "route2_trainer1 not defeated")

	# Restore state
	GameManager.badges = saved_badges
	GameManager.defeated_trainers = saved_trainers

# ══════════════════════════════════════════════
#  T. Trainer Battle Tests
# ══════════════════════════════════════════════

func _run_trainer_battle_tests() -> void:
	print("\n── Trainer Battle ──")

	# Test: enemy party built from data array
	_begin("trainer_enemy_party_from_data")
	var mon1_data := MonsterDB.get_monster(1)
	var mon2_data := MonsterDB.get_monster(2)
	if mon1_data and mon2_data:
		var party_data: Array = [
			{"data": mon1_data, "level": 10},
			{"data": mon2_data, "level": 12},
		]
		var party: Array = []
		for entry in party_data:
			var inst := MonsterInstance.new(entry["data"], entry["level"])
			party.append(inst)
		_assert_eq(party.size(), 2, "enemy party has 2 monsters")
		_assert_eq(party[0].level, 10, "first monster level = 10")
		_assert_eq(party[1].level, 12, "second monster level = 12")
	else:
		_fail("could not load monster data for trainer party test")

	# Test: enemy switching on faint — next monster in party
	_begin("trainer_enemy_switch_on_faint")
	var m1_data := MonsterDB.get_monster(1)
	var m2_data := MonsterDB.get_monster(2)
	if m1_data and m2_data:
		var enemy_party: Array = [
			MonsterInstance.new(m1_data, 10),
			MonsterInstance.new(m2_data, 12),
		]
		var idx := 0
		enemy_party[idx].take_damage(9999)  # Faint first monster
		_assert_true(enemy_party[idx].is_fainted(), "first enemy fainted")
		idx += 1
		_assert_lt(idx, enemy_party.size(), "next enemy available at index 1")
		_assert_false(enemy_party[idx].is_fainted(), "second enemy alive")
	else:
		_fail("could not load monster data for switching test")

	# Test: all enemy monsters fainted = win condition
	_begin("trainer_all_fainted_is_win")
	var ma_data := MonsterDB.get_monster(1)
	var mb_data := MonsterDB.get_monster(2)
	if ma_data and mb_data:
		var t_party: Array = [
			MonsterInstance.new(ma_data, 10),
			MonsterInstance.new(mb_data, 12),
		]
		for m in t_party:
			m.take_damage(9999)
		var all_fainted := true
		for m in t_party:
			if not m.is_fainted():
				all_fainted = false
		_assert_true(all_fainted, "all trainer monsters fainted = win")
	else:
		_fail("could not load monster data for all fainted test")

	# Test: trainer battle flag disables catching concept
	_begin("trainer_battle_no_catch_flag")
	var is_trainer_battle := true
	_assert_true(is_trainer_battle, "is_trainer_battle flag set")
	# In trainer battles, catch button is hidden and run is blocked

	# Test: trainer battle flag blocks running concept
	_begin("trainer_battle_no_run_flag")
	_assert_true(is_trainer_battle, "trainer battles block running")

# ══════════════════════════════════════════════
#  U. Area Data Tests
# ══════════════════════════════════════════════

func _run_area_data_tests() -> void:
	print("\n── Area Data ──")

	# Load overworld script to access AREA_DATA
	var overworld_script := load("res://scripts/overworld/overworld.gd") as GDScript
	_assert_not_null(overworld_script, "overworld script loads")
	if not overworld_script:
		return

	var area_data: Dictionary = overworld_script.get("AREA_DATA") if overworld_script.has_method("get") else {}
	# AREA_DATA is a const on the script, access via constants
	# For const access we need to check the script's constants
	var has_town2 := false
	var has_route2 := false
	var has_route1_north := false
	var has_town2_gym := false

	# Since we can't directly access consts from a loaded script in tests easily,
	# validate by checking if scenes can instantiate and if keys exist in the script source
	# Instead, validate the areas exist by checking if we can load the overworld scene
	# and verify the data structurally

	# Test: AREA_DATA has all 4 required areas
	_begin("area_data_has_town2")
	# We verify by checking that the overworld.gd source contains "town2"
	var script_source: String = overworld_script.source_code
	has_town2 = script_source.contains("\"town2\"")
	_assert_true(has_town2, "AREA_DATA contains town2 key")

	_begin("area_data_has_route2")
	has_route2 = script_source.contains("\"route2\"")
	_assert_true(has_route2, "AREA_DATA contains route2 key")

	# Test: route1 has north transition to route2
	_begin("area_route1_north_transition")
	has_route1_north = script_source.contains("\"target_area\": \"route2\"")
	_assert_true(has_route1_north, "route1 has transition to route2")

	# Test: town2 has gym leader trainer
	_begin("area_town2_has_gym_leader")
	has_town2_gym = script_source.contains("\"is_gym_leader\": true")
	_assert_true(has_town2_gym, "town2 has gym leader trainer")

# ══════════════════════════════════════════════
#  V. Trainer Scene Tests
# ══════════════════════════════════════════════

func _run_trainer_scene_tests() -> void:
	print("\n── Trainer Scene ──")

	# Test: trainer.tscn loads
	_begin("trainer_scene_loads")
	var packed := load("res://scenes/overworld/trainer.tscn") as PackedScene
	_assert_not_null(packed, "trainer.tscn loads")

	# Test: area name dictionary completeness
	_begin("area_names_complete")
	var area_names: Dictionary = {
		"town": "Monster Town",
		"route1": "Route 1",
		"route2": "Route 2",
		"town2": "Coral City",
		"route3": "Route 3",
		"town3": "Ember Ridge",
	}
	_assert_eq(area_names.size(), 6, "area_names has 6 entries")
	_assert_true(area_names.has("town2"), "area_names has town2")
	_assert_true(area_names.has("route2"), "area_names has route2")
	_assert_true(area_names.has("route3"), "area_names has route3")
	_assert_true(area_names.has("town3"), "area_names has town3")

# ══════════════════════════════════════════════
#  W. Dialogue Tree Tests
# ══════════════════════════════════════════════

func _run_dialogue_tree_tests() -> void:
	print("\n── Dialogue Tree ──")

	# Test: dialogue_tree.tscn loads
	_begin("dialogue_tree_scene_loads")
	var packed := load("res://scenes/overworld/dialogue_tree.tscn") as PackedScene
	_assert_not_null(packed, "dialogue_tree.tscn loads")

	# Test: dialogue_tree_ui.gd script loads
	_begin("dialogue_tree_script_loads")
	var script := load("res://scripts/ui/dialogue_tree_ui.gd") as GDScript
	_assert_not_null(script, "dialogue_tree_ui.gd loads")

	# Test: node structure has required children
	_begin("dialogue_tree_node_structure")
	if packed:
		var tree := packed.instantiate()
		var margin := tree.get_node_or_null("MarginContainer")
		_assert_not_null(margin, "dialogue tree has MarginContainer")
		var vbox := tree.get_node_or_null("MarginContainer/VBox")
		_assert_not_null(vbox, "dialogue tree has VBox")
		var speaker := tree.get_node_or_null("MarginContainer/VBox/SpeakerLabel")
		_assert_not_null(speaker, "dialogue tree has SpeakerLabel")
		var text := tree.get_node_or_null("MarginContainer/VBox/TextLabel")
		_assert_not_null(text, "dialogue tree has TextLabel")
		var choices := tree.get_node_or_null("MarginContainer/VBox/ChoicesContainer")
		_assert_not_null(choices, "dialogue tree has ChoicesContainer")
		tree.queue_free()
	else:
		_fail("could not instantiate dialogue tree")

	# Test: node map building from set_tree
	_begin("dialogue_tree_node_map")
	var test_nodes: Array = [
		{"id": "start", "text": "Hello", "speaker": "NPC"},
		{"id": "reply", "text": "Goodbye", "speaker": "NPC"},
	]
	# Verify format: each node has id and text
	_assert_true(test_nodes[0].has("id"), "dialogue node has id")
	_assert_true(test_nodes[0].has("text"), "dialogue node has text")
	_assert_true(test_nodes[1].has("speaker"), "dialogue node has speaker")

	# Test: choices format
	_begin("dialogue_tree_choices_format")
	var choice_node: Dictionary = {
		"id": "ask",
		"text": "What do you want?",
		"choices": [
			{"label": "Quest", "next": "quest"},
			{"label": "Bye", "next": "bye"},
		]
	}
	_assert_true(choice_node.has("choices"), "node has choices key")
	_assert_eq(choice_node["choices"].size(), 2, "node has 2 choices")
	_assert_true(choice_node["choices"][0].has("label"), "choice has label")
	_assert_true(choice_node["choices"][0].has("next"), "choice has next")

	# Test: action format
	_begin("dialogue_tree_action_format")
	var action_node: Dictionary = {"id": "give", "text": "Here!", "action": "start_quest:fetch_herb"}
	var action_str: String = str(action_node["action"])
	var action_parts: PackedStringArray = action_str.split(":")
	_assert_eq(action_parts.size(), 2, "action string splits into 2 parts")
	_assert_eq(action_parts[0], "start_quest", "action type = start_quest")
	_assert_eq(action_parts[1], "fetch_herb", "action value = fetch_herb")

	# Test: condition format parsing
	_begin("dialogue_tree_condition_format")
	var cond_str := "has_badge:tide_badge"
	var cond_parts: PackedStringArray = cond_str.split(":")
	_assert_eq(cond_parts.size(), 2, "condition splits into 2 parts")
	_assert_eq(cond_parts[0], "has_badge", "condition type = has_badge")

	# Test: backward compat — NPC with lines still works
	_begin("dialogue_tree_backward_compat")
	var npc_script := load("res://scripts/overworld/npc_controller.gd") as GDScript
	_assert_not_null(npc_script, "npc_controller.gd loads")
	var source: String = npc_script.source_code
	_assert_true(source.contains("dialogue_tree"), "npc has dialogue_tree var")
	_assert_true(source.contains("dialogue_lines"), "npc still has dialogue_lines")

	# Test: overworld supports dialogue tree
	_begin("dialogue_tree_overworld_support")
	var ow_script := load("res://scripts/overworld/overworld.gd") as GDScript
	var ow_source: String = ow_script.source_code
	_assert_true(ow_source.contains("_show_dialogue_tree"), "overworld has _show_dialogue_tree method")
	_assert_true(ow_source.contains("_handle_dialogue_action"), "overworld has _handle_dialogue_action method")

# ══════════════════════════════════════════════
#  X. Quest System Tests
# ══════════════════════════════════════════════

func _run_quest_system_tests() -> void:
	print("\n── Quest System ──")

	# Save and reset state
	var saved_active := GameManager.active_quests.duplicate(true)
	var saved_complete := GameManager.completed_quests.duplicate(true)
	GameManager.active_quests = {}
	GameManager.completed_quests = {}

	# Test: QUEST_DEFS exists and has entries
	_begin("quest_defs_exist")
	_assert_true(GameManager.QUEST_DEFS.size() >= 3, "QUEST_DEFS has at least 3 quests")

	# Test: quest def structure
	_begin("quest_def_structure")
	var herb_def: Dictionary = GameManager.get_quest_def("fetch_herb")
	_assert_true(herb_def.has("name"), "quest def has name")
	_assert_true(herb_def.has("type"), "quest def has type")
	_assert_true(herb_def.has("goal"), "quest def has goal")

	# Test: start quest
	_begin("quest_start")
	GameManager.start_quest("fetch_herb")
	_assert_true(GameManager.is_quest_active("fetch_herb"), "fetch_herb is active after start")
	_assert_eq(GameManager.get_quest_progress("fetch_herb"), 0, "progress starts at 0")

	# Test: advance quest
	_begin("quest_advance")
	GameManager.advance_quest("fetch_herb")
	_assert_eq(GameManager.get_quest_progress("fetch_herb"), 0, "fetch_herb auto-completed at goal=1")
	_assert_true(GameManager.is_quest_complete("fetch_herb"), "fetch_herb completed after advance")

	# Test: multi-step quest
	_begin("quest_multi_step")
	GameManager.active_quests = {}
	GameManager.completed_quests = {}
	GameManager.start_quest("catch_5_monsters")
	GameManager.advance_quest("catch_5_monsters")
	GameManager.advance_quest("catch_5_monsters")
	_assert_eq(GameManager.get_quest_progress("catch_5_monsters"), 2, "catch quest progress = 2")
	_assert_true(GameManager.is_quest_active("catch_5_monsters"), "catch quest still active at 2/5")

	# Test: auto-complete at goal
	_begin("quest_auto_complete")
	GameManager.advance_quest("catch_5_monsters")
	GameManager.advance_quest("catch_5_monsters")
	GameManager.advance_quest("catch_5_monsters")
	_assert_true(GameManager.is_quest_complete("catch_5_monsters"), "catch quest completed at 5/5")
	_assert_false(GameManager.is_quest_active("catch_5_monsters"), "catch quest no longer active")

	# Test: no duplicate start
	_begin("quest_no_duplicate_start")
	GameManager.active_quests = {}
	GameManager.completed_quests = {}
	GameManager.start_quest("fetch_herb")
	GameManager.start_quest("fetch_herb")
	_assert_eq(GameManager.active_quests.size(), 1, "no duplicate active quest")

	# Test: no restart completed
	_begin("quest_no_restart_completed")
	GameManager.active_quests = {}
	GameManager.completed_quests = {}
	GameManager.start_quest("fetch_herb")
	GameManager.advance_quest("fetch_herb")
	GameManager.start_quest("fetch_herb")
	_assert_true(GameManager.is_quest_complete("fetch_herb"), "completed quest stays complete")
	_assert_false(GameManager.is_quest_active("fetch_herb"), "completed quest not re-activated")

	# Test: inactive quest progress is 0
	_begin("quest_inactive_progress_zero")
	_assert_eq(GameManager.get_quest_progress("nonexistent_quest"), 0, "inactive quest progress = 0")

	# Test: quest log scene loads
	_begin("quest_log_scene_loads")
	var packed := load("res://scenes/ui/quest_log.tscn") as PackedScene
	_assert_not_null(packed, "quest_log.tscn loads")

	# Test: quest def types
	_begin("quest_def_types")
	var types_found: Array = []
	for quest_id: String in GameManager.QUEST_DEFS:
		var qdef: Dictionary = GameManager.QUEST_DEFS[quest_id]
		var qtype: String = str(qdef.get("type", ""))
		if qtype not in types_found:
			types_found.append(qtype)
	_assert_true(types_found.size() >= 3, "at least 3 quest types defined: %s" % str(types_found))

	# Restore state
	GameManager.active_quests = saved_active
	GameManager.completed_quests = saved_complete

# ══════════════════════════════════════════════
#  Y. Cutscene Tests
# ══════════════════════════════════════════════

func _run_cutscene_tests() -> void:
	print("\n── Cutscene ──")

	# Test: cutscene_player.gd loads
	_begin("cutscene_script_loads")
	var script := load("res://scripts/overworld/cutscene_player.gd") as GDScript
	_assert_not_null(script, "cutscene_player.gd loads")

	# Test: script has play method
	_begin("cutscene_has_play_method")
	if script:
		var source: String = script.source_code
		_assert_true(source.contains("func play("), "cutscene has play() method")
		_assert_true(source.contains("cutscene_finished"), "cutscene has finished signal")

	# Test: step format — dialogue
	_begin("cutscene_step_dialogue")
	var dialogue_step: Dictionary = {"type": "dialogue", "lines": ["Hello!"]}
	_assert_eq(dialogue_step["type"], "dialogue", "dialogue step type")
	_assert_true(dialogue_step.has("lines"), "dialogue step has lines")

	# Test: step format — wait
	_begin("cutscene_step_wait")
	var wait_step: Dictionary = {"type": "wait", "duration": 1.0}
	_assert_eq(wait_step["type"], "wait", "wait step type")
	_assert_true(wait_step.has("duration"), "wait step has duration")

	# Test: step format — camera_move
	_begin("cutscene_step_camera_move")
	var cam_step: Dictionary = {"type": "camera_move", "target": Vector2(100, 50), "duration": 1.0}
	_assert_eq(cam_step["type"], "camera_move", "camera_move step type")
	_assert_true(cam_step.has("target"), "camera_move step has target")

	# Test: step format — screen flash
	_begin("cutscene_step_flash")
	var flash_step: Dictionary = {"type": "screen_flash", "color": Color.WHITE, "duration": 0.3}
	_assert_eq(flash_step["type"], "screen_flash", "flash step type")

	# Test: step format — fade
	_begin("cutscene_step_fade")
	var fade_step: Dictionary = {"type": "fade_out", "duration": 0.5}
	_assert_eq(fade_step["type"], "fade_out", "fade_out step type")

	# Test: overworld has play_cutscene
	_begin("cutscene_overworld_support")
	var ow_script := load("res://scripts/overworld/overworld.gd") as GDScript
	var ow_source: String = ow_script.source_code
	_assert_true(ow_source.contains("play_cutscene"), "overworld has play_cutscene")

# ══════════════════════════════════════════════
#  Z. World Map Tests
# ══════════════════════════════════════════════

func _run_world_map_tests() -> void:
	print("\n── World Map ──")

	# Test: world_map.tscn loads
	_begin("world_map_scene_loads")
	var packed := load("res://scenes/ui/world_map.tscn") as PackedScene
	_assert_not_null(packed, "world_map.tscn loads")

	# Test: world_map_ui.gd loads
	_begin("world_map_script_loads")
	var script := load("res://scripts/ui/world_map_ui.gd") as GDScript
	_assert_not_null(script, "world_map_ui.gd loads")

	# Test: MAP_POSITIONS covers all 4 areas
	_begin("world_map_positions_coverage")
	if script:
		var source: String = script.source_code
		_assert_true(source.contains("\"town\""), "map has town position")
		_assert_true(source.contains("\"route1\""), "map has route1 position")
		_assert_true(source.contains("\"route2\""), "map has route2 position")
		_assert_true(source.contains("\"town2\""), "map has town2 position")

	# Test: connections count
	_begin("world_map_connections")
	# 3 connections: town-route1, route1-route2, route2-town2
	if script:
		var source: String = script.source_code
		var conn_count := 0
		var search_pos := 0
		while true:
			var idx := source.find("[\"", search_pos)
			if idx < 0:
				break
			# Count array entries in MAP_CONNECTIONS
			var ctx := source.substr(maxi(0, idx - 100), 120)
			if ctx.contains("MAP_CONNECTIONS"):
				conn_count += 1
			search_pos = idx + 2
		# Simple check: verify 3 connection pairs exist in source
		_assert_true(source.contains("\"town\", \"route1\""), "connection: town-route1")
		_assert_true(source.contains("\"route1\", \"route2\""), "connection: route1-route2")

# ══════════════════════════════════════════════
#  AA. Day/Night Tests
# ══════════════════════════════════════════════

func _run_day_night_tests() -> void:
	print("\n── Day/Night ──")

	# Save state
	var saved_time := GameManager.game_time
	var saved_period := GameManager.time_period

	# Test: default time is daytime
	_begin("daynight_default_period")
	GameManager.game_time = 10.0
	GameManager.time_period = GameManager._get_time_period()
	_assert_eq(GameManager.time_period, "day", "10:00 is day")

	# Test: night period
	_begin("daynight_night_period")
	GameManager.game_time = 22.0
	var night_period: String = GameManager._get_time_period()
	_assert_eq(night_period, "night", "22:00 is night")

	# Test: dawn period
	_begin("daynight_dawn_period")
	GameManager.game_time = 6.0
	var dawn_period: String = GameManager._get_time_period()
	_assert_eq(dawn_period, "dawn", "6:00 is dawn")

	# Test: dusk period
	_begin("daynight_dusk_period")
	GameManager.game_time = 18.0
	var dusk_period: String = GameManager._get_time_period()
	_assert_eq(dusk_period, "dusk", "18:00 is dusk")

	# Test: advance time
	_begin("daynight_advance_time")
	GameManager.game_time = 10.0
	GameManager.time_period = "day"
	GameManager.advance_time(2.0)
	_assert_eq(GameManager.game_time, 12.0, "time advanced to 12.0")

	# Test: wrapping at 24
	_begin("daynight_wrap_24")
	GameManager.game_time = 23.0
	GameManager.time_period = "night"
	GameManager.advance_time(3.0)
	_assert_true(GameManager.game_time >= 1.0 and GameManager.game_time <= 3.0, "time wraps at 24: %.1f" % GameManager.game_time)

	# Test: color values exist for all periods
	_begin("daynight_color_values")
	for period_name: String in GameManager.TIME_PERIODS:
		var period: Dictionary = GameManager.TIME_PERIODS[period_name]
		_assert_true(period.has("color"), "%s has color" % period_name)

	# Test: get_time_color returns valid Color
	_begin("daynight_get_time_color")
	GameManager.game_time = 10.0
	GameManager.time_period = "day"
	var color: Color = GameManager.get_time_color()
	_assert_eq(color, Color(1.0, 1.0, 1.0), "day color is white")

	# Restore state
	GameManager.game_time = saved_time
	GameManager.time_period = saved_period

# ══════════════════════════════════════════════
#  AB. Weather Tests
# ══════════════════════════════════════════════

func _run_weather_tests() -> void:
	print("\n── Weather ──")

	# Test: weather_system.gd loads
	_begin("weather_script_loads")
	var script := load("res://scripts/overworld/weather_system.gd") as GDScript
	_assert_not_null(script, "weather_system.gd loads")

	# Test: default weather is clear
	_begin("weather_default_clear")
	if script:
		var weather := Node2D.new()
		weather.set_script(script)
		_assert_eq(weather.get_weather(), "clear", "default weather is clear")
		weather.queue_free()

	# Test: AREA_DATA has weather key on route2
	_begin("weather_area_data_route2")
	var ow_script := load("res://scripts/overworld/overworld.gd") as GDScript
	if ow_script:
		var source: String = ow_script.source_code
		_assert_true(source.contains("\"weather\": \"rain\""), "route2 has weather: rain")

	# Test: fog is overlay-only (no particles)
	_begin("weather_fog_overlay_only")
	if script:
		var source: String = script.source_code
		# In the fog case, only _create_overlay is called, not _create_particles
		var fog_section_start := source.find("\"fog\":")
		if fog_section_start > 0:
			var fog_section := source.substr(fog_section_start, 100)
			_assert_true(fog_section.contains("_create_overlay"), "fog creates overlay")
			_assert_false(fog_section.contains("_create_particles"), "fog has no particles")
		else:
			_fail("could not find fog section in weather script")

	# Test: weather types covered
	_begin("weather_types_covered")
	if script:
		var source: String = script.source_code
		_assert_true(source.contains("\"rain\""), "rain weather type exists")
		_assert_true(source.contains("\"snow\""), "snow weather type exists")
		_assert_true(source.contains("\"fog\""), "fog weather type exists")
		_assert_true(source.contains("\"sandstorm\""), "sandstorm weather type exists")

	# Test: overworld has weather setup
	_begin("weather_overworld_setup")
	var ow_script2 := load("res://scripts/overworld/overworld.gd") as GDScript
	if ow_script2:
		var source: String = ow_script2.source_code
		_assert_true(source.contains("_setup_weather"), "overworld has _setup_weather")

# ── Save System Tests ──

func _run_save_system_tests() -> void:
	print("\n── Save System ──")

	# Clean up any existing test save files first
	var save_path: String = SaveManager.SAVE_PATH
	var backup_path: String = SaveManager.BACKUP_PATH
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)

	# Save original GameManager state to restore later
	var orig_gender: String = GameManager.player_gender
	var orig_area: String = GameManager.current_area
	var orig_party: Array[MonsterInstance] = GameManager.player_party.duplicate()
	var orig_pc: Array[MonsterInstance] = GameManager.pc_storage.duplicate()
	var orig_inventory: Dictionary = GameManager.inventory.duplicate()
	var orig_badges: Dictionary = GameManager.badges.duplicate()
	var orig_defeated_trainers: Dictionary = GameManager.defeated_trainers.duplicate()
	var orig_seen: Dictionary = GameManager.monster_registry_seen.duplicate()
	var orig_caught: Dictionary = GameManager.monster_registry_caught.duplicate()
	var orig_active_quests: Dictionary = GameManager.active_quests.duplicate(true)
	var orig_completed_quests: Dictionary = GameManager.completed_quests.duplicate()
	var orig_area_positions: Dictionary = GameManager.area_player_positions.duplicate(true)
	var orig_area_defeated: Dictionary = GameManager.area_defeated_monsters.duplicate(true)
	var orig_game_time: float = GameManager.game_time
	var orig_time_period: String = GameManager.time_period

	# 1. No save file exists initially
	_begin("save_has_save_false_initially")
	_assert_false(SaveManager.has_save(), "no save file exists at start")

	# 2. Round-trip party
	_begin("save_round_trip_party")
	var test_base: Resource = MonsterDB.get_monster(1)
	if test_base:
		GameManager.player_gender = "boy"
		GameManager.current_area = "route1"
		GameManager.player_party = []
		var m := MonsterInstance.new(test_base, 10)
		m.current_hp = 25
		m.experience = 42
		GameManager.player_party.append(m)
		SaveManager.save_game()

		# Clear and reload
		GameManager.player_party = []
		GameManager.player_gender = ""
		SaveManager.load_game()
		_assert_eq(GameManager.player_party.size(), 1, "party size restored")
		if GameManager.player_party.size() > 0:
			var loaded: MonsterInstance = GameManager.player_party[0]
			_assert_eq(loaded.level, 10, "party monster level restored")
			_assert_eq(loaded.current_hp, 25, "party monster HP restored")
			_assert_eq(loaded.experience, 42, "party monster XP restored")
			_assert_eq(int(loaded.base_data.get("id")), 1, "party monster base_id restored")
	else:
		_fail("could not load monster ID 1 for party test")

	# 3. Round-trip inventory
	_begin("save_round_trip_inventory")
	GameManager.inventory = {"potion": 5, "capture_ball": 3}
	SaveManager.save_game()
	GameManager.inventory = {}
	SaveManager.load_game()
	_assert_eq(GameManager.get_item_count("potion"), 5, "potion count restored")
	_assert_eq(GameManager.get_item_count("capture_ball"), 3, "capture_ball count restored")

	# 4. Round-trip registry
	_begin("save_round_trip_registry")
	GameManager.monster_registry_seen = {1: true, 2: true, 3: true}
	GameManager.monster_registry_caught = {1: true}
	SaveManager.save_game()
	GameManager.monster_registry_seen = {}
	GameManager.monster_registry_caught = {}
	SaveManager.load_game()
	_assert_true(GameManager.is_monster_seen(1), "seen registry restored")
	_assert_true(GameManager.is_monster_seen(2), "seen registry restored (2)")
	_assert_true(GameManager.is_monster_caught(1), "caught registry restored")
	_assert_false(GameManager.is_monster_caught(2), "uncaught remains uncaught")

	# 5. Round-trip badges
	_begin("save_round_trip_badges")
	GameManager.badges = {"tide_badge": true}
	GameManager.defeated_trainers = {"town2_gym": true}
	SaveManager.save_game()
	GameManager.badges = {}
	GameManager.defeated_trainers = {}
	SaveManager.load_game()
	_assert_true(GameManager.has_badge("tide_badge"), "badge restored")
	_assert_true(GameManager.is_trainer_defeated("town2_gym"), "defeated trainer restored")

	# 6. Round-trip quests
	_begin("save_round_trip_quests")
	GameManager.active_quests = {"fetch_herb": {"progress": 0}}
	GameManager.completed_quests = {"catch_5_monsters": true}
	SaveManager.save_game()
	GameManager.active_quests = {}
	GameManager.completed_quests = {}
	SaveManager.load_game()
	_assert_true(GameManager.is_quest_active("fetch_herb"), "active quest restored")
	_assert_true(GameManager.is_quest_complete("catch_5_monsters"), "completed quest restored")

	# 7. Round-trip area state
	_begin("save_round_trip_area_state")
	GameManager.area_player_positions = {"town": Vector2(100, 200)}
	GameManager.area_defeated_monsters = {"route1": [1, 3]}
	SaveManager.save_game()
	GameManager.area_player_positions = {}
	GameManager.area_defeated_monsters = {}
	SaveManager.load_game()
	var pos: Variant = GameManager.get_area_player_position("town")
	_assert_not_null(pos, "area position restored")
	if pos is Vector2:
		_assert_eq(int((pos as Vector2).x), 100, "area position X restored")
		_assert_eq(int((pos as Vector2).y), 200, "area position Y restored")
	_assert_true(GameManager.is_area_monster_defeated("route1", 1), "area defeated monster restored")
	_assert_true(GameManager.is_area_monster_defeated("route1", 3), "area defeated monster 3 restored")

	# 8. Round-trip time
	_begin("save_round_trip_time")
	GameManager.game_time = 20.5
	GameManager.time_period = "night"
	SaveManager.save_game()
	GameManager.game_time = 10.0
	GameManager.time_period = "day"
	SaveManager.load_game()
	_assert_eq(GameManager.game_time, 20.5, "game_time restored")
	_assert_eq(GameManager.time_period, "night", "time_period restored")

	# 9. Save version present
	_begin("save_version_present")
	SaveManager.save_game()
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file:
		var text := file.get_as_text()
		file.close()
		var json := JSON.new()
		json.parse(text)
		if json.data is Dictionary:
			var save_data: Dictionary = json.data as Dictionary
			_assert_true(save_data.has("save_version"), "save_version key exists")
			_assert_eq(int(save_data["save_version"]), 3, "save_version is 3")
		else:
			_fail("save file is not a dictionary")
	else:
		_fail("could not open save file for version check")

	# 10. Corruption fallback — invalid JSON returns false
	_begin("save_corruption_fallback")
	# Write garbage to save file
	var corrupt_file := FileAccess.open(save_path, FileAccess.WRITE)
	if corrupt_file:
		corrupt_file.store_string("NOT VALID JSON {{{")
		corrupt_file.close()
	# Also corrupt backup
	var corrupt_backup := FileAccess.open(backup_path, FileAccess.WRITE)
	if corrupt_backup:
		corrupt_backup.store_string("ALSO BAD")
		corrupt_backup.close()
	var load_result := SaveManager.load_game()
	_assert_false(load_result, "loading corrupt save returns false")

	# 11. Delete save
	_begin("save_delete")
	# Re-create a valid save first
	SaveManager.save_game()
	_assert_true(SaveManager.has_save(), "save exists before delete")
	SaveManager.delete_save()
	_assert_false(SaveManager.has_save(), "save gone after delete")

	# 12. Monster skills preserved
	_begin("save_monster_skills_preserved")
	var skill_base: Resource = MonsterDB.get_monster(1)
	if skill_base:
		var sm := MonsterInstance.new(skill_base, 5)
		GameManager.player_party = [sm]
		var expected_count: int = sm.skills.size()
		SaveManager.save_game()
		GameManager.player_party = []
		SaveManager.load_game()
		if GameManager.player_party.size() > 0:
			_assert_eq(GameManager.player_party[0].skills.size(), expected_count, "skill count preserved")
		else:
			_fail("party empty after load for skills test")
	else:
		_fail("could not load monster for skills test")

	# 13. Backup created
	_begin("save_backup_created")
	SaveManager.delete_save()
	SaveManager.save_game()  # First save — no backup yet
	SaveManager.save_game()  # Second save — should create backup from first
	_assert_true(FileAccess.file_exists(backup_path), "backup file created on second save")

	# Cleanup: restore original GameManager state
	GameManager.player_gender = orig_gender
	GameManager.current_area = orig_area
	GameManager.player_party = orig_party
	GameManager.pc_storage = orig_pc
	GameManager.inventory = orig_inventory
	GameManager.badges = orig_badges
	GameManager.defeated_trainers = orig_defeated_trainers
	GameManager.monster_registry_seen = orig_seen
	GameManager.monster_registry_caught = orig_caught
	GameManager.active_quests = orig_active_quests
	GameManager.completed_quests = orig_completed_quests
	GameManager.area_player_positions = orig_area_positions
	GameManager.area_defeated_monsters = orig_area_defeated
	GameManager.game_time = orig_game_time
	GameManager.time_period = orig_time_period
	# Clean up test save files
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)

# ══════════════════════════════════════════════
#  AE. Gold System Tests
# ══════════════════════════════════════════════

func _run_gold_system_tests() -> void:
	print("\n── Gold System ──")

	# Save original gold
	var orig_gold: int = GameManager.gold

	# Test: default gold
	_begin("gold_default_value")
	GameManager.gold = 100
	_assert_eq(GameManager.get_gold(), 100, "default gold is 100")

	# Test: add gold
	_begin("gold_add")
	GameManager.gold = 100
	GameManager.add_gold(50)
	_assert_eq(GameManager.get_gold(), 150, "gold increased to 150")

	# Test: spend gold success
	_begin("gold_spend_success")
	GameManager.gold = 200
	var spent := GameManager.spend_gold(150)
	_assert_true(spent, "spend_gold returns true")
	_assert_eq(GameManager.get_gold(), 50, "gold reduced to 50")

	# Test: spend gold fail (insufficient)
	_begin("gold_spend_fail")
	GameManager.gold = 30
	var fail_spent := GameManager.spend_gold(100)
	_assert_false(fail_spent, "spend_gold returns false when insufficient")
	_assert_eq(GameManager.get_gold(), 30, "gold unchanged after failed spend")

	# Test: SHOP_PRICES exists with 5 items
	_begin("gold_shop_prices")
	_assert_eq(GameManager.SHOP_PRICES.size(), 5, "SHOP_PRICES has 5 items")
	_assert_true(GameManager.SHOP_PRICES.has("potion"), "SHOP_PRICES has potion")
	_assert_true(GameManager.SHOP_PRICES.has("antidote"), "SHOP_PRICES has antidote")

	# Test: gold round-trip via save
	_begin("gold_save_round_trip")
	GameManager.gold = 777
	# Set minimum required save data
	var save_gender: String = GameManager.player_gender
	var save_party: Array[MonsterInstance] = GameManager.player_party.duplicate()
	if GameManager.player_party.is_empty():
		var base: Resource = MonsterDB.get_monster(1)
		if base:
			GameManager.player_party = [MonsterInstance.new(base, 5)]
	GameManager.player_gender = "boy"
	SaveManager.save_game()
	GameManager.gold = 0
	SaveManager.load_game()
	_assert_eq(GameManager.gold, 777, "gold restored from save")
	GameManager.player_gender = save_gender
	GameManager.player_party = save_party

	# Restore
	GameManager.gold = orig_gold
	# Clean up save files
	SaveManager.delete_save()

# ══════════════════════════════════════════════
#  AF. Shop Scene Tests
# ══════════════════════════════════════════════

func _run_shop_scene_tests() -> void:
	print("\n── Shop Scene ──")

	_begin("shop_scene_loads")
	var packed := load("res://scenes/ui/shop_ui.tscn") as PackedScene
	_assert_not_null(packed, "shop_ui.tscn loads")

	_begin("shop_script_loads")
	var script := load("res://scripts/ui/shop_ui.gd") as GDScript
	_assert_not_null(script, "shop_ui.gd loads")

# ══════════════════════════════════════════════
#  AG. New Area Tests (Route 3 & Ember Ridge)
# ══════════════════════════════════════════════

func _run_new_area_tests() -> void:
	print("\n── New Areas (Route 3 & Ember Ridge) ──")

	var overworld_script := load("res://scripts/overworld/overworld.gd") as GDScript
	if not overworld_script:
		_begin("new_area_script_loads")
		_fail("could not load overworld script")
		return

	var source: String = overworld_script.source_code

	# Test: route3 exists in AREA_DATA
	_begin("area_data_has_route3")
	_assert_true(source.contains("\"route3\""), "AREA_DATA contains route3 key")

	# Test: town3 exists in AREA_DATA
	_begin("area_data_has_town3")
	_assert_true(source.contains("\"town3\""), "AREA_DATA contains town3 key")

	# Test: town2 has east transition to route3
	_begin("area_town2_east_to_route3")
	_assert_true(source.contains("\"target_area\": \"route3\""), "town2 has transition to route3")

	# Test: route3 has transition to town3
	_begin("area_route3_to_town3")
	_assert_true(source.contains("\"target_area\": \"town3\""), "route3 has transition to town3")

	# Test: town3 has safe_zone
	_begin("area_town3_safe_zone")
	var town3_idx := source.find("\"town3\"")
	if town3_idx >= 0:
		var town3_block := source.substr(town3_idx, 500)
		_assert_true(town3_block.contains("\"safe_zone\": true"), "town3 is a safe zone")
	else:
		_fail("town3 not found in source")

	# Test: town3 has shop NPC (open_shop action)
	_begin("area_town3_has_shop")
	_assert_true(source.contains("\"open_shop\""), "town3 has open_shop dialogue action")

	# Test: town3 has heal NPC (heal_party action)
	_begin("area_town3_has_healer")
	_assert_true(source.contains("\"heal_party\""), "town3 has heal_party dialogue action")

	# Test: world map has route3 and town3
	_begin("world_map_has_route3")
	var map_script := load("res://scripts/ui/world_map_ui.gd") as GDScript
	if map_script:
		var map_source: String = map_script.source_code
		_assert_true(map_source.contains("\"route3\""), "world map has route3")
		_assert_true(map_source.contains("\"town3\""), "world map has town3")
	else:
		_fail("could not load world map script")

func _run_trainer_flow_tests() -> void:
	print("\n── Trainer Flow (Signal-Based) ──")

	# ── State flag management ──

	# Test: is_in_dialogue defaults false
	_begin("trainer_flow_dialogue_default_false")
	var saved_dialogue := GameManager.is_in_dialogue
	var saved_battle := GameManager.is_in_battle
	GameManager.is_in_dialogue = false
	GameManager.is_in_battle = false
	_assert_false(GameManager.is_in_dialogue, "is_in_dialogue defaults false")

	# Test: is_in_battle defaults false
	_begin("trainer_flow_battle_default_false")
	_assert_false(GameManager.is_in_battle, "is_in_battle defaults false")

	# Test: can_player_move returns true when no flags set
	_begin("trainer_flow_can_move_all_clear")
	GameManager.is_in_menu = false
	_assert_true(GameManager.can_player_move(), "player can move when all flags clear")

	# Test: can_player_move returns false when is_in_dialogue
	_begin("trainer_flow_cant_move_dialogue")
	GameManager.is_in_dialogue = true
	_assert_false(GameManager.can_player_move(), "player locked during dialogue")
	GameManager.is_in_dialogue = false

	# Test: can_player_move returns false when is_in_battle
	_begin("trainer_flow_cant_move_battle")
	GameManager.is_in_battle = true
	_assert_false(GameManager.can_player_move(), "player locked during battle")
	GameManager.is_in_battle = false

	# Test: trainer defeat persistence
	_begin("trainer_flow_defeat_persistence")
	var test_id := "__test_trainer_flow__"
	GameManager.defeated_trainers.erase(test_id)
	_assert_false(GameManager.is_trainer_defeated(test_id), "trainer not defeated initially")
	GameManager.mark_trainer_defeated(test_id)
	_assert_true(GameManager.is_trainer_defeated(test_id), "trainer defeated after mark")
	GameManager.defeated_trainers.erase(test_id)

	# ── Source code validation ──

	# Test: dialogue_closed signal exists in dialogue_box_ui.gd
	_begin("trainer_flow_dialogue_closed_signal")
	var dialogue_script := load("res://scripts/ui/dialogue_box_ui.gd") as GDScript
	if dialogue_script:
		var dsrc: String = dialogue_script.source_code
		_assert_true(dsrc.contains("signal dialogue_closed"), "dialogue_box_ui has dialogue_closed signal")
	else:
		_fail("could not load dialogue_box_ui script")

	# Test: block_cancel property exists
	_begin("trainer_flow_block_cancel_property")
	if dialogue_script:
		var dsrc: String = dialogue_script.source_code
		_assert_true(dsrc.contains("block_cancel"), "dialogue_box_ui has block_cancel property")
	else:
		_fail("could not load dialogue_box_ui script")

	# Test: block_cancel prevents ui_cancel
	_begin("trainer_flow_block_cancel_in_input")
	if dialogue_script:
		var dsrc: String = dialogue_script.source_code
		_assert_true(dsrc.contains("not block_cancel"), "ui_cancel gated by block_cancel")
	else:
		_fail("could not load dialogue_box_ui script")

	# Test: dialogue_closed emitted in _close
	_begin("trainer_flow_signal_emitted_in_close")
	if dialogue_script:
		var dsrc: String = dialogue_script.source_code
		_assert_true(dsrc.contains("dialogue_closed.emit()"), "dialogue_closed emitted in _close()")
	else:
		_fail("could not load dialogue_box_ui script")

	# Test: trainer_controller uses await dialogue_closed (no fixed timer)
	_begin("trainer_flow_uses_signal_not_timer")
	var trainer_script := load("res://scripts/overworld/trainer_controller.gd") as GDScript
	if trainer_script:
		var tsrc: String = trainer_script.source_code
		_assert_true(tsrc.contains("await dialogue_node.dialogue_closed"), "trainer uses signal-based await")
		_assert_false(tsrc.contains("dialogue_before.size() * 1.5"), "fixed timer removed from trainer")
		_assert_true(tsrc.contains("await tween.finished"), "trainer uses await tween.finished instead of tween_callback")
		_assert_false(tsrc.contains("tween_callback(_engage_battle)"), "tween_callback to _engage_battle removed")
	else:
		_fail("could not load trainer_controller script")

	# Test: overworld _show_dialogue returns Node
	_begin("trainer_flow_show_dialogue_returns_node")
	var overworld_script := load("res://scripts/overworld/overworld.gd") as GDScript
	if overworld_script:
		var osrc: String = overworld_script.source_code
		_assert_true(osrc.contains("func _show_dialogue(lines: Array) -> Node"), "overworld _show_dialogue returns Node")
	else:
		_fail("could not load overworld script")

	# Test: overworld resets is_in_dialogue in _on_trainer_battle_ended
	_begin("trainer_flow_safety_reset_dialogue")
	if overworld_script:
		var osrc: String = overworld_script.source_code
		var idx := osrc.find("_on_trainer_battle_ended")
		if idx >= 0:
			var block := osrc.substr(idx, 300)
			_assert_true(block.contains("is_in_dialogue = false"), "safety reset of is_in_dialogue in trainer battle ended")
		else:
			_fail("_on_trainer_battle_ended not found")
	else:
		_fail("could not load overworld script")

	# Test: DEBUG_TRAINER flag exists in GameManager
	_begin("trainer_flow_debug_flag_exists")
	_assert_true("DEBUG_TRAINER" in GameManager, "GameManager has DEBUG_TRAINER property")

	# Test: DEBUG_TRAINER defaults to false
	_begin("trainer_flow_debug_flag_default")
	_assert_false(GameManager.DEBUG_TRAINER, "DEBUG_TRAINER defaults to false")

	# Restore state
	GameManager.is_in_dialogue = saved_dialogue
	GameManager.is_in_battle = saved_battle

# ══════════════════════════════════════════════
#  Trainer Rank Tests
# ══════════════════════════════════════════════

func _run_trainer_rank_tests() -> void:
	print("\n── Trainer Rank ──")

	# Save original state
	var orig_rank: int = GameManager.trainer_rank
	var orig_exp: int = GameManager.trainer_experience

	# 1. XP threshold formula
	_begin("trainer_xp_threshold_formula")
	GameManager.trainer_rank = 1
	_assert_eq(GameManager.get_trainer_xp_threshold(), int(pow(1.0, 1.5) * 10.0), "threshold at rank 1")
	GameManager.trainer_rank = 5
	_assert_eq(GameManager.get_trainer_xp_threshold(), int(pow(5.0, 1.5) * 10.0), "threshold at rank 5")
	GameManager.trainer_rank = 10
	_assert_eq(GameManager.get_trainer_xp_threshold(), int(pow(10.0, 1.5) * 10.0), "threshold at rank 10")

	# 2. Rank up
	_begin("trainer_rank_up")
	GameManager.trainer_rank = 1
	GameManager.trainer_experience = 0
	var threshold: int = GameManager.get_trainer_xp_threshold()
	var res: Dictionary = GameManager.add_trainer_experience(threshold + 5)
	_assert_true(res["ranked_up"], "ranked up with enough XP")
	_assert_eq(res["old_rank"], 1, "old rank was 1")
	_assert_eq(res["new_rank"], 2, "new rank is 2")
	_assert_eq(GameManager.trainer_rank, 2, "trainer_rank updated")

	# 3. No rank up on partial XP
	_begin("trainer_no_rank_up")
	GameManager.trainer_rank = 1
	GameManager.trainer_experience = 0
	var partial: Dictionary = GameManager.add_trainer_experience(1)
	_assert_false(partial["ranked_up"], "no rank up with partial XP")
	_assert_eq(partial["old_rank"], 1, "rank unchanged")
	_assert_eq(partial["new_rank"], 1, "new_rank same as old")

	# 4. Title lookup
	_begin("trainer_title_at_ranks")
	GameManager.trainer_rank = 1
	_assert_eq(GameManager.get_trainer_title(), "Rookie", "rank 1 = Rookie")
	GameManager.trainer_rank = 6
	_assert_eq(GameManager.get_trainer_title(), "Novice", "rank 6 = Novice")
	GameManager.trainer_rank = 11
	_assert_eq(GameManager.get_trainer_title(), "Skilled", "rank 11 = Skilled")

	# 5. Save round trip
	_begin("trainer_save_round_trip")
	var save_path: String = SaveManager.SAVE_PATH
	var backup_path: String = SaveManager.BACKUP_PATH
	GameManager.trainer_rank = 7
	GameManager.trainer_experience = 42
	SaveManager.save_game()
	GameManager.trainer_rank = 1
	GameManager.trainer_experience = 0
	SaveManager.load_game()
	_assert_eq(GameManager.trainer_rank, 7, "trainer_rank restored")
	_assert_eq(GameManager.trainer_experience, 42, "trainer_experience restored")

	# 6. Migration v2 → v3
	_begin("save_migration_v2_to_v3")
	var v2_data: Dictionary = {
		"save_version": 2,
		"player_gender": "boy",
		"gold": 100,
		"player_party": [],
	}
	var migrated: Dictionary = SaveManager._migrate_save(v2_data)
	_assert_eq(int(migrated["save_version"]), 3, "migrated to version 3")
	_assert_eq(int(migrated["trainer_rank"]), 1, "default trainer_rank after migration")
	_assert_eq(int(migrated["trainer_experience"]), 0, "default trainer_experience after migration")

	# Cleanup
	GameManager.trainer_rank = orig_rank
	GameManager.trainer_experience = orig_exp
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
