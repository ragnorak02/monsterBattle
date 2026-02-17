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
	_run_monster_instance_tests()
	_run_game_manager_tests()
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
