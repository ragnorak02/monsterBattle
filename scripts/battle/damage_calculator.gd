class_name DamageCalculator

# Type effectiveness chart: attacker_type -> { defender_type: multiplier }
# 2.0 = super effective, 0.5 = not very effective, absent = 1.0 neutral
const TYPE_CHART: Dictionary = {
	"Fire": {"Grass": 2.0, "Ice": 2.0, "Water": 0.5, "Rock": 0.5},
	"Water": {"Fire": 2.0, "Rock": 2.0, "Grass": 0.5, "Electric": 0.5},
	"Grass": {"Water": 2.0, "Rock": 2.0, "Fire": 0.5, "Ice": 0.5},
	"Electric": {"Water": 2.0, "Wind": 2.0, "Rock": 0.5, "Grass": 0.5},
	"Wind": {"Grass": 2.0, "Poison": 2.0, "Rock": 0.5, "Electric": 0.5},
	"Rock": {"Fire": 2.0, "Ice": 2.0, "Water": 0.5, "Grass": 0.5},
	"Ice": {"Grass": 2.0, "Wind": 2.0, "Fire": 0.5, "Rock": 0.5},
	"Dark": {"Ice": 2.0, "Normal": 2.0, "Fire": 0.5, "Poison": 0.5},
	"Poison": {"Grass": 2.0, "Water": 2.0, "Rock": 0.5, "Dark": 0.5},
	"Normal": {},
}

static func get_type_multiplier(attack_type: String, defend_type: String) -> float:
	if attack_type == "" or defend_type == "" or attack_type == "Normal":
		return 1.0
	if TYPE_CHART.has(attack_type):
		var matchups: Dictionary = TYPE_CHART[attack_type]
		if matchups.has(defend_type):
			return matchups[defend_type]
	return 1.0

static func calculate_damage_with_type(attacker: MonsterInstance, defender: MonsterInstance, skill: Resource) -> Dictionary:
	var base_damage := _base_damage(attacker, defender, skill)

	var skill_type: String = str(skill.get("skill_type")) if skill.get("skill_type") else "Normal"
	var attacker_type: String = str(attacker.base_data.get("element_type")) if attacker.base_data.get("element_type") else "Normal"
	var defender_type: String = str(defender.base_data.get("element_type")) if defender.base_data.get("element_type") else "Normal"

	# STAB: 1.5x when monster type matches skill type (except Normal)
	var stab: float = 1.0
	if skill_type != "Normal" and skill_type == attacker_type:
		stab = 1.5

	var type_mult: float = get_type_multiplier(skill_type, defender_type)

	var final_damage := maxi(1, int(float(base_damage) * stab * type_mult))

	var effectiveness: String = "neutral"
	if type_mult > 1.0:
		effectiveness = "super_effective"
	elif type_mult < 1.0:
		effectiveness = "not_very_effective"

	return {
		"damage": final_damage,
		"effectiveness": effectiveness,
		"multiplier": type_mult,
		"stab": stab > 1.0,
	}

static func _base_damage(attacker: MonsterInstance, defender: MonsterInstance, skill: Resource) -> int:
	var attack_value := attacker.get_attack() + int(skill.get("power"))
	var defense_value := defender.get_defense() / 2
	return maxi(1, attack_value - defense_value)

static func calculate_damage(attacker: MonsterInstance, defender: MonsterInstance, skill: Resource) -> int:
	# Backward-compatible: returns typed damage as int
	var result := calculate_damage_with_type(attacker, defender, skill)
	return result["damage"]

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

static func calculate_catch_rate_with_ball(enemy: MonsterInstance, ball_multiplier: float) -> float:
	var base_rate := calculate_catch_rate(enemy)
	return clampf(base_rate * ball_multiplier, 0.1, 0.95)

static func check_catch_success(enemy: MonsterInstance) -> bool:
	return randf() <= calculate_catch_rate(enemy)
