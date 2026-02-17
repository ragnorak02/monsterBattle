class_name DamageCalculator

static func calculate_damage(attacker: MonsterInstance, defender: MonsterInstance, skill: Resource) -> int:
	# Formula: max(1, (attacker.attack + skill.power) - (defender.defense / 2))
	var attack_value := attacker.get_attack() + int(skill.get("power"))
	var defense_value := defender.get_defense() / 2
	return maxi(1, attack_value - defense_value)

static func check_accuracy(skill: Resource) -> bool:
	return randf() <= float(skill.get("accuracy"))

static func check_run_success() -> bool:
	# 60% success rate
	return randf() <= 0.6

static func get_first_attacker(monster_a: MonsterInstance, monster_b: MonsterInstance) -> int:
	# Returns 0 if a goes first, 1 if b goes first
	# Higher agility goes first. Ties: first arg (player) goes first.
	if monster_a.get_agility() >= monster_b.get_agility():
		return 0
	return 1

static func calculate_catch_rate(enemy: MonsterInstance) -> float:
	# Full HP ~15%, half HP ~52%, near-death ~90%
	var hp_percent := float(enemy.current_hp) / float(enemy.get_max_hp())
	return clampf(0.15 + (1.0 - hp_percent) * 0.75, 0.1, 0.95)

static func check_catch_success(enemy: MonsterInstance) -> bool:
	return randf() <= calculate_catch_rate(enemy)
