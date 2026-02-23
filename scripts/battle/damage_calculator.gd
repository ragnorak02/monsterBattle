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

# ── Ability Helpers ──

static func get_ability(monster: MonsterInstance) -> String:
	if monster.base_data:
		var ab: Variant = monster.base_data.get("ability")
		if ab:
			return str(ab)
	return ""

static func apply_thick_skin(damage: int, type_mult: float) -> int:
	if type_mult > 1.0:
		return maxi(1, int(damage * 0.75))
	return damage

# ── Core Damage ──

# force_crit: 0 = no crit (default, backward compat), 1 = force crit, -1 = random roll
static func calculate_damage_with_type(attacker: MonsterInstance, defender: MonsterInstance, skill: Resource, force_crit: int = 0) -> Dictionary:
	var base_damage := _base_damage(attacker, defender, skill)

	var skill_type: String = str(skill.get("skill_type")) if skill.get("skill_type") else "Normal"
	var attacker_type: String = str(attacker.base_data.get("element_type")) if attacker.base_data.get("element_type") else "Normal"
	var defender_type: String = str(defender.base_data.get("element_type")) if defender.base_data.get("element_type") else "Normal"

	# STAB: 1.5x when monster type matches skill type (except Normal)
	var stab: float = 1.0
	if skill_type != "Normal" and skill_type == attacker_type:
		stab = 1.5

	var type_mult: float = get_type_multiplier(skill_type, defender_type)

	# Critical hit
	var is_crit: bool = false
	if force_crit == 1:
		is_crit = true
	elif force_crit == -1:
		is_crit = check_critical()
	var crit_mult: float = 1.5 if is_crit else 1.0

	var final_damage := maxi(1, int(float(base_damage) * stab * type_mult * crit_mult))

	# Ability: thick_skin reduces super-effective damage by 25%
	if get_ability(defender) == "thick_skin":
		final_damage = apply_thick_skin(final_damage, type_mult)

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
		"critical": is_crit,
	}

static func _base_damage(attacker: MonsterInstance, defender: MonsterInstance, skill: Resource) -> int:
	var power: int = int(skill.get("power"))
	var category: String = str(skill.get("category")) if skill.get("category") else "physical"

	var attack_value: int
	var defense_value: int

	if category == "special":
		attack_value = attacker.get_effective_sp_attack() + power
		defense_value = defender.get_sp_defense() / 2
	else:
		attack_value = attacker.get_effective_attack() + power
		defense_value = defender.get_defense() / 2

	return maxi(1, attack_value - defense_value)

static func calculate_damage(attacker: MonsterInstance, defender: MonsterInstance, skill: Resource) -> int:
	# Backward-compatible: returns typed damage as int
	var result := calculate_damage_with_type(attacker, defender, skill)
	return result["damage"]

# ── Accuracy ──

static func check_accuracy(skill: Resource, attacker: MonsterInstance = null, defender: MonsterInstance = null) -> bool:
	var base_acc: float = float(skill.get("accuracy"))
	if attacker and defender:
		var effective_acc: float = base_acc * attacker.get_accuracy_multiplier() / defender.get_evasion_multiplier()
		return randf() <= clampf(effective_acc, 0.1, 1.0)
	return randf() <= base_acc

# ── Multi-hit ──

static func calculate_hit_count(skill: Resource) -> int:
	var hit_min: int = int(skill.get("hit_min")) if skill.get("hit_min") else 1
	var hit_max: int = int(skill.get("hit_max")) if skill.get("hit_max") else 1
	if hit_min <= 0:
		hit_min = 1
	if hit_max < hit_min:
		hit_max = hit_min
	if hit_min == hit_max:
		return hit_min
	return randi_range(hit_min, hit_max)

# ── Critical / Run ──

static func check_critical() -> bool:
	return randf() < 0.125  # 12.5% chance

static func check_run_success() -> bool:
	# 60% success rate
	return randf() <= 0.6

static func get_first_attacker(monster_a: MonsterInstance, monster_b: MonsterInstance) -> int:
	# Returns 0 if a goes first, 1 if b goes first
	# Higher effective agility goes first. Ties: first arg (player) goes first.
	if monster_a.get_effective_agility() >= monster_b.get_effective_agility():
		return 0
	return 1

# ── Catching ──

static func calculate_catch_rate(enemy: MonsterInstance) -> float:
	# Full HP ~15%, half HP ~52%, near-death ~90%
	var hp_percent := float(enemy.current_hp) / float(enemy.get_max_hp())
	return clampf(0.15 + (1.0 - hp_percent) * 0.75, 0.1, 0.95)

static func calculate_catch_rate_with_ball(enemy: MonsterInstance, ball_multiplier: float) -> float:
	var base_rate := calculate_catch_rate(enemy)
	return clampf(base_rate * ball_multiplier, 0.1, 0.95)

static func check_catch_success(enemy: MonsterInstance) -> bool:
	return randf() <= calculate_catch_rate(enemy)

# ── Status Effect Functions ──

static func try_apply_status(skill: Resource, target: MonsterInstance) -> String:
	var effect: String = str(skill.get("status_effect")) if skill.get("status_effect") else ""
	if effect == "":
		return ""
	var chance: float = float(skill.get("status_chance")) if skill.get("status_chance") else 0.0
	if chance <= 0.0:
		return ""
	if randf() > chance:
		return ""
	if target.apply_status(effect):
		return effect
	return ""

static func process_end_of_turn_status(monster: MonsterInstance) -> Dictionary:
	# Returns { "damage": int, "status": String } or empty if no effect
	if monster.status == "poison" or monster.status == "burn":
		var dmg := maxi(1, monster.get_max_hp() / 8)
		monster.take_damage(dmg)
		return {"damage": dmg, "status": monster.status}
	return {}

static func check_paralysis_skip() -> bool:
	# 25% chance paralyzed monster can't move
	return randf() < 0.25

# ── AI Scoring ──

static func score_skill(skill: Resource, attacker: MonsterInstance, defender: MonsterInstance) -> float:
	var power: int = int(skill.get("power")) if skill.get("power") else 0
	var score: float = float(power)

	var skill_type: String = str(skill.get("skill_type")) if skill.get("skill_type") else "Normal"
	var attacker_type: String = str(attacker.base_data.get("element_type")) if attacker.base_data.get("element_type") else "Normal"
	var defender_type: String = str(defender.base_data.get("element_type")) if defender.base_data.get("element_type") else "Normal"

	# Type effectiveness
	var type_mult: float = get_type_multiplier(skill_type, defender_type)
	if type_mult > 1.0:
		score *= 2.0
	elif type_mult < 1.0:
		score *= 0.5

	# STAB
	if skill_type != "Normal" and skill_type == attacker_type:
		score *= 1.5

	# Status effect bonus if target has no status
	var effect: String = str(skill.get("status_effect")) if skill.get("status_effect") else ""
	if effect != "" and not defender.has_status():
		score += 5.0

	# Category matching monster's stronger stat
	var category: String = str(skill.get("category")) if skill.get("category") else "physical"
	if category == "special" and attacker.get_sp_attack() > attacker.get_attack():
		score *= 1.2
	elif category == "physical" and attacker.get_attack() >= attacker.get_sp_attack():
		score *= 1.2

	return score
