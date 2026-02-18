extends Control

signal battle_ended(result: String, overworld_id: int)

enum BattleState {
	INTRO,
	PLAYER_TURN,
	EXECUTE_FIRST,
	EXECUTE_SECOND,
	CHECK_FAINT,
	WIN,
	LOSE,
	RUN,
	CATCH_ATTEMPT,
	ITEM_USE,
	XP_REWARD,
	LEARN_SKILL,
	EVOLUTION,
	OUTRO
}

var wild_monster_data: Resource  # MonsterData
var wild_overworld_id: int = -1
var wild_monster_level: int = 5
var auto_battle: bool = false  # Auto-pick skills for testing

var _state: BattleState = BattleState.INTRO
var _player_monster: MonsterInstance
var _enemy_monster: MonsterInstance
var _player_skill: Resource
var _enemy_skill: Resource
var _player_goes_first: bool = true
var _caught: bool = false
var _pending_skills: Array = []

@onready var player_display: Control = $BattleUI/HBox/PlayerSide/PlayerDisplay
@onready var enemy_display: Control = $BattleUI/HBox/EnemySide/EnemyDisplay
@onready var action_menu: PanelContainer = $BattleUI/ActionPanel
@onready var message_label: Label = $BattleUI/MessageLabel
@onready var background: TextureRect = $Background

func _get_name(monster: MonsterInstance) -> String:
	return str(monster.base_data.get("monster_name"))

func _get_skill_name(skill: Resource) -> String:
	return str(skill.get("skill_name"))

func _ready() -> void:
	print("[BATTLE] _ready() called, wild_monster_data=%s" % str(wild_monster_data))
	_player_monster = GameManager.get_first_alive_monster()
	if not _player_monster:
		print("[BATTLE] ERROR: No alive player monster!")
		_end_battle("lose")
		return

	print("[BATTLE] Player monster: %s (HP:%d/%d)" % [_get_name(_player_monster), _player_monster.current_hp, _player_monster.get_max_hp()])
	_enemy_monster = MonsterInstance.new(wild_monster_data, wild_monster_level)
	print("[BATTLE] Enemy monster: %s Lv.%d (HP:%d/%d)" % [_get_name(_enemy_monster), wild_monster_level, _enemy_monster.current_hp, _enemy_monster.get_max_hp()])

	print("[BATTLE] Setting up displays...")
	player_display.setup(_player_monster, true)
	enemy_display.setup(_enemy_monster, false)

	print("[BATTLE] Setting up action menu with %d skills..." % _player_monster.skills.size())
	action_menu.setup_skills(_player_monster.skills)
	action_menu.skill_selected.connect(_on_skill_selected)
	action_menu.catch_selected.connect(_on_catch_selected)
	action_menu.run_selected.connect(_on_run_selected)
	action_menu.item_selected.connect(_on_item_selected)
	action_menu.set_enabled(false)

	AudioManager.play_music("res://assets/audio/music/battle_theme.wav")
	_start_intro()

func _start_intro() -> void:
	_state = BattleState.INTRO
	action_menu.set_enabled(false)
	var msg := "A wild %s (Lv.%d) appeared!" % [_get_name(_enemy_monster), _enemy_monster.level]
	print("[BATTLE] %s" % msg)
	_show_message(msg)
	await get_tree().create_timer(1.5).timeout
	msg = "Go, %s!" % _get_name(_player_monster)
	print("[BATTLE] %s" % msg)
	_show_message(msg)
	await get_tree().create_timer(1.0).timeout
	_start_player_turn()

func _start_player_turn() -> void:
	_state = BattleState.PLAYER_TURN
	var msg := "What will %s do?" % _get_name(_player_monster)
	print("[BATTLE] %s" % msg)
	_show_message(msg)
	action_menu.set_enabled(true)

	# Auto-battle: pick first skill after a short delay
	if auto_battle:
		await get_tree().create_timer(0.5).timeout
		if _state == BattleState.PLAYER_TURN and _player_monster.skills.size() > 0:
			var skill: Resource = _player_monster.skills[0]
			print("[BATTLE] [AUTO] Picking skill: %s" % _get_skill_name(skill))
			_on_skill_selected(skill)

func _on_skill_selected(skill: Resource) -> void:
	if _state != BattleState.PLAYER_TURN:
		return
	print("[BATTLE] Player selected: %s" % _get_skill_name(skill))
	_player_skill = skill
	_enemy_skill = _pick_enemy_skill()
	print("[BATTLE] Enemy will use: %s" % (_get_skill_name(_enemy_skill) if _enemy_skill else "nothing"))
	action_menu.set_enabled(false)
	_resolve_turn()

func _on_catch_selected() -> void:
	if _state != BattleState.PLAYER_TURN:
		return
	action_menu.set_enabled(false)
	_state = BattleState.CATCH_ATTEMPT

	var catch_rate := DamageCalculator.calculate_catch_rate(_enemy_monster)
	print("[BATTLE] Attempting catch (rate: %.0f%%)" % (catch_rate * 100))
	_show_message("You threw a capture device...")
	await get_tree().create_timer(1.0).timeout

	if DamageCalculator.check_catch_success(_enemy_monster):
		_caught = true
		var enemy_name: String = _get_name(_enemy_monster)
		print("[BATTLE] Catch success!")
		if GameManager.player_party.size() < 6:
			var caught_instance := MonsterInstance.new(wild_monster_data, _enemy_monster.level)
			caught_instance.current_hp = _enemy_monster.current_hp
			caught_instance.skills = _enemy_monster.skills.duplicate()
			caught_instance.experience = _enemy_monster.experience
			GameManager.add_to_party(caught_instance)
			_show_message("Gotcha! %s was caught!" % enemy_name)
		else:
			_show_message("%s was caught but your party is full! It was released." % enemy_name)
		await get_tree().create_timer(1.5).timeout
		await _grant_xp()
	else:
		print("[BATTLE] Catch failed!")
		_show_message("It broke free!")
		await get_tree().create_timer(0.8).timeout
		_enemy_skill = _pick_enemy_skill()
		await _execute_attack(_enemy_monster, _player_monster, _enemy_skill, false)
		await _check_faint()

func _on_run_selected() -> void:
	if _state != BattleState.PLAYER_TURN:
		return
	action_menu.set_enabled(false)

	if DamageCalculator.check_run_success():
		print("[BATTLE] Run success!")
		_show_message("Got away safely!")
		_state = BattleState.RUN
		await get_tree().create_timer(1.0).timeout
		_end_battle("run")
	else:
		print("[BATTLE] Run failed!")
		_show_message("Couldn't escape!")
		_enemy_skill = _pick_enemy_skill()
		await get_tree().create_timer(0.8).timeout
		await _execute_attack(_enemy_monster, _player_monster, _enemy_skill, false)
		await _check_faint()

func _on_item_selected(item_id: String) -> void:
	if _state != BattleState.PLAYER_TURN:
		return
	action_menu.set_enabled(false)
	_state = BattleState.ITEM_USE

	var item_def: Dictionary = GameManager.get_item_def(item_id)
	if item_def.is_empty():
		_start_player_turn()
		return

	if not GameManager.remove_item(item_id):
		_show_message("No %s left!" % item_def["name"])
		await get_tree().create_timer(0.8).timeout
		_start_player_turn()
		return

	var item_type: String = item_def["type"]
	if item_type == "heal":
		var heal_amount: int = int(item_def["value"])
		var p_name: String = _get_name(_player_monster)
		var old_hp: int = _player_monster.current_hp
		_player_monster.heal(heal_amount)
		var healed: int = _player_monster.current_hp - old_hp
		print("[BATTLE] Used %s, healed %s for %d HP" % [item_def["name"], p_name, healed])
		_show_message("Used %s! %s recovered %d HP!" % [item_def["name"], p_name, healed])
		player_display.update_hp()
		await get_tree().create_timer(1.0).timeout
		# Enemy gets a free attack
		_enemy_skill = _pick_enemy_skill()
		await _execute_attack(_enemy_monster, _player_monster, _enemy_skill, false)
		await _check_faint()

	elif item_type == "catch":
		var ball_mult: float = float(item_def["value"])
		var catch_rate := DamageCalculator.calculate_catch_rate_with_ball(_enemy_monster, ball_mult)
		print("[BATTLE] Used %s (%.1fx), catch rate: %.0f%%" % [item_def["name"], ball_mult, catch_rate * 100])
		_show_message("You threw a %s..." % item_def["name"])
		await get_tree().create_timer(1.0).timeout

		if randf() <= catch_rate:
			_caught = true
			var enemy_name: String = _get_name(_enemy_monster)
			print("[BATTLE] Catch success!")
			if GameManager.player_party.size() < 6:
				var caught_instance := MonsterInstance.new(wild_monster_data, _enemy_monster.level)
				caught_instance.current_hp = _enemy_monster.current_hp
				caught_instance.skills = _enemy_monster.skills.duplicate()
				caught_instance.experience = _enemy_monster.experience
				GameManager.add_to_party(caught_instance)
				_show_message("Gotcha! %s was caught!" % enemy_name)
			else:
				_show_message("%s was caught but your party is full! It was released." % enemy_name)
			await get_tree().create_timer(1.5).timeout
			await _grant_xp()
		else:
			print("[BATTLE] Catch failed!")
			_show_message("It broke free!")
			await get_tree().create_timer(0.8).timeout
			_enemy_skill = _pick_enemy_skill()
			await _execute_attack(_enemy_monster, _player_monster, _enemy_skill, false)
			await _check_faint()

func _pick_enemy_skill() -> Resource:
	var skills_arr: Array = _enemy_monster.skills
	if skills_arr.is_empty():
		return null
	return skills_arr[randi() % skills_arr.size()]

func _resolve_turn() -> void:
	var first_order := DamageCalculator.get_first_attacker(_player_monster, _enemy_monster)
	_player_goes_first = (first_order == 0)
	print("[BATTLE] Turn order: %s goes first" % ("Player" if _player_goes_first else "Enemy"))

	if _player_goes_first:
		_state = BattleState.EXECUTE_FIRST
		await _execute_attack(_player_monster, _enemy_monster, _player_skill, true)
		if await _check_faint():
			return
		_state = BattleState.EXECUTE_SECOND
		await _execute_attack(_enemy_monster, _player_monster, _enemy_skill, false)
		await _check_faint()
	else:
		_state = BattleState.EXECUTE_FIRST
		await _execute_attack(_enemy_monster, _player_monster, _enemy_skill, false)
		if await _check_faint():
			return
		_state = BattleState.EXECUTE_SECOND
		await _execute_attack(_player_monster, _enemy_monster, _player_skill, true)
		await _check_faint()

func _execute_attack(attacker: MonsterInstance, defender: MonsterInstance, skill: Resource, is_player_attacking: bool) -> void:
	if not skill:
		print("[BATTLE] No skill to execute!")
		return

	var a_name: String = _get_name(attacker)
	var s_name: String = _get_skill_name(skill)
	var msg := "%s used %s!" % [a_name, s_name]
	print("[BATTLE] %s" % msg)
	_show_message(msg)
	await get_tree().create_timer(0.6).timeout

	if not DamageCalculator.check_accuracy(skill):
		print("[BATTLE] %s's attack missed!" % a_name)
		_show_message("It missed!")
		await get_tree().create_timer(0.6).timeout
		return

	var result := DamageCalculator.calculate_damage_with_type(attacker, defender, skill)
	var damage: int = result["damage"]
	defender.take_damage(damage)
	AudioManager.play_sfx("res://assets/audio/sfx/hit.wav")

	var d_name: String = _get_name(defender)
	print("[BATTLE] %s dealt %d damage to %s (HP: %d/%d)" % [a_name, damage, d_name, defender.current_hp, defender.get_max_hp()])
	_show_message("It dealt %d damage!" % damage)

	if is_player_attacking:
		enemy_display.update_hp()
	else:
		player_display.update_hp()

	await get_tree().create_timer(0.6).timeout

	# Show type effectiveness message
	var effectiveness: String = result["effectiveness"]
	if effectiveness == "super_effective":
		_show_message("It's super effective!")
		await get_tree().create_timer(0.6).timeout
	elif effectiveness == "not_very_effective":
		_show_message("It's not very effective...")
		await get_tree().create_timer(0.6).timeout

func _check_faint() -> bool:
	_state = BattleState.CHECK_FAINT

	if _enemy_monster.is_fainted():
		AudioManager.play_sfx("res://assets/audio/sfx/faint.wav")
		print("[BATTLE] Enemy %s fainted! YOU WIN!" % _get_name(_enemy_monster))
		_show_message("%s fainted!" % _get_name(_enemy_monster))
		await get_tree().create_timer(1.0).timeout
		_show_message("You win!")
		_state = BattleState.WIN
		await get_tree().create_timer(1.0).timeout
		await _grant_xp()
		return true

	if _player_monster.is_fainted():
		AudioManager.play_sfx("res://assets/audio/sfx/faint.wav")
		print("[BATTLE] Player %s fainted!" % _get_name(_player_monster))
		_show_message("%s fainted!" % _get_name(_player_monster))
		await get_tree().create_timer(1.0).timeout

		var next_monster: MonsterInstance = GameManager.get_first_alive_monster()
		if next_monster and next_monster != _player_monster:
			_player_monster = next_monster
			print("[BATTLE] Sending in next monster: %s" % _get_name(_player_monster))
			_show_message("Go, %s!" % _get_name(_player_monster))
			player_display.setup(_player_monster, true)
			action_menu.setup_skills(_player_monster.skills)
			await get_tree().create_timer(1.0).timeout
			_start_player_turn()
			return true
		else:
			print("[BATTLE] All monsters fainted! YOU LOSE!")
			_show_message("All your monsters fainted...")
			_state = BattleState.LOSE
			await get_tree().create_timer(1.5).timeout
			_end_battle("lose")
			return true

	_start_player_turn()
	return false

func _grant_xp() -> void:
	_state = BattleState.XP_REWARD
	var xp_amount: int = _enemy_monster.level * 10
	var p_name: String = _get_name(_player_monster)
	print("[BATTLE] %s gained %d XP" % [p_name, xp_amount])
	_show_message("%s gained %d XP!" % [p_name, xp_amount])
	await get_tree().create_timer(1.2).timeout

	var result: Dictionary = _player_monster.add_experience(xp_amount)

	if result["leveled_up"]:
		var new_level: int = result["new_level"]
		print("[BATTLE] %s leveled up to Lv.%d!" % [p_name, new_level])
		_show_message("%s grew to Lv.%d!" % [p_name, new_level])
		player_display.setup(_player_monster, true)
		await get_tree().create_timer(1.5).timeout

		# Handle new skills
		var new_skills: Array = result["new_skills"]
		for skill in new_skills:
			await _handle_learn_skill(skill)

		# Handle evolution
		if result["can_evolve"]:
			var evo_id: int = result["evolves_into_id"]
			await _handle_evolution(evo_id)

	var battle_result: String = "catch" if _caught else "win"
	_end_battle(battle_result)

func _handle_learn_skill(skill: Resource) -> void:
	_state = BattleState.LEARN_SKILL
	var skill_name: String = str(skill.get("skill_name"))
	var p_name: String = _get_name(_player_monster)

	if _player_monster.skills.size() < 4:
		_player_monster.learn_skill(skill)
		print("[BATTLE] %s learned %s!" % [p_name, skill_name])
		_show_message("%s learned %s!" % [p_name, skill_name])
		await get_tree().create_timer(1.5).timeout
	else:
		_show_message("%s wants to learn %s, but already knows 4 skills!" % [p_name, skill_name])
		await get_tree().create_timer(1.5).timeout
		_show_message("Choose a skill to forget, or don't learn it.")
		await get_tree().create_timer(1.0).timeout
		action_menu.setup_skill_replace(_player_monster.skills, skill)
		var chosen_index: int = await action_menu.replace_skill_chosen
		if chosen_index >= 0:
			var old_skill_name: String = str(_player_monster.skills[chosen_index].get("skill_name"))
			_player_monster.learn_skill(skill, chosen_index)
			print("[BATTLE] %s forgot %s and learned %s!" % [p_name, old_skill_name, skill_name])
			_show_message("%s forgot %s and learned %s!" % [p_name, old_skill_name, skill_name])
		else:
			print("[BATTLE] %s did not learn %s" % [p_name, skill_name])
			_show_message("%s did not learn %s." % [p_name, skill_name])
		await get_tree().create_timer(1.5).timeout
		# Restore normal skill buttons
		action_menu.setup_skills(_player_monster.skills)

func _handle_evolution(evolves_into_id: int) -> void:
	_state = BattleState.EVOLUTION
	var old_name: String = _get_name(_player_monster)
	var new_data: Resource = MonsterDB.get_monster(evolves_into_id)
	if not new_data:
		print("[BATTLE] ERROR: Could not find evolution data for id %d" % evolves_into_id)
		return

	var new_name: String = str(new_data.get("monster_name"))
	print("[BATTLE] %s is evolving into %s!" % [old_name, new_name])
	_show_message("What? %s is evolving!" % old_name)
	await get_tree().create_timer(2.0).timeout

	_player_monster.evolve(new_data)
	_show_message("%s evolved into %s!" % [old_name, new_name])
	player_display.setup(_player_monster, true)
	await get_tree().create_timer(2.0).timeout

func _show_message(text: String) -> void:
	if message_label:
		message_label.text = text

func _end_battle(result: String) -> void:
	_state = BattleState.OUTRO
	print("[BATTLE] Battle ended: %s" % result)

	if result == "lose":
		GameManager.heal_all_party()

	AudioManager.play_music("res://assets/audio/music/town_theme.wav")
	battle_ended.emit(result, wild_overworld_id)
	queue_free()
