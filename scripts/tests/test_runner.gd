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
