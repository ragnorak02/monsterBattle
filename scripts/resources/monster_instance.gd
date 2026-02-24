class_name MonsterInstance
extends Resource

@export var base_data: Resource  # MonsterData
@export var level: int = 5
@export var current_hp: int = 0
@export var skills: Array[Resource] = []  # Array of SkillData
@export var experience: int = 0

var status: String = ""  # "poison", "burn", "paralysis", or ""
var attack_stage: int = 0     # -6 to +6  (used by Intimidate etc.)
var accuracy_stage: int = 0   # -6 to +6
var evasion_stage: int = 0    # -6 to +6

const STAGE_MULTIPLIERS: Dictionary = {
	-6: 0.33, -5: 0.38, -4: 0.43, -3: 0.5, -2: 0.6, -1: 0.75,
	0: 1.0,
	1: 1.33, 2: 1.66, 3: 2.0, 4: 2.33, 5: 2.66, 6: 3.0,
}

func _init(p_base: Resource = null, p_level: int = 5) -> void:
	if p_base:
		base_data = p_base
		level = p_level
		current_hp = get_max_hp()
		var starting: Array = p_base.get("starting_skills") as Array
		if starting:
			skills = starting.duplicate()

func get_max_hp() -> int:
	if base_data:
		var growth: float = float(base_data.get("hp_growth")) if base_data.get("hp_growth") else 1.0
		return int(base_data.get("max_hp")) + int(float(level * 2) * growth)
	return 1

func get_attack() -> int:
	if base_data:
		var growth: float = float(base_data.get("atk_growth")) if base_data.get("atk_growth") else 1.0
		return int(base_data.get("attack")) + int(float(level) * growth)
	return 1

func get_defense() -> int:
	if base_data:
		var growth: float = float(base_data.get("def_growth")) if base_data.get("def_growth") else 1.0
		return int(base_data.get("defense")) + int(float(level) * growth)
	return 1

func get_agility() -> int:
	if base_data:
		var growth: float = float(base_data.get("agi_growth")) if base_data.get("agi_growth") else 1.0
		return int(base_data.get("agility")) + int(float(level) * growth)
	return 1

func is_fainted() -> bool:
	return current_hp <= 0

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)

func heal(amount: int) -> void:
	current_hp = min(get_max_hp(), current_hp + amount)

func heal_full() -> void:
	current_hp = get_max_hp()
	clear_status()
	reset_stages()

func apply_status(s: String) -> bool:
	if status != "":
		return false
	status = s
	return true

func clear_status() -> void:
	status = ""

func has_status() -> bool:
	return status != ""

func get_sp_attack() -> int:
	if base_data:
		var sp_atk: int = int(base_data.get("sp_attack")) if base_data.get("sp_attack") else 0
		if sp_atk > 0:
			var growth: float = float(base_data.get("sp_atk_growth")) if base_data.get("sp_atk_growth") else 1.0
			return sp_atk + int(float(level) * growth)
	return get_attack()

func get_sp_defense() -> int:
	if base_data:
		var sp_def: int = int(base_data.get("sp_defense")) if base_data.get("sp_defense") else 0
		if sp_def > 0:
			var growth: float = float(base_data.get("sp_def_growth")) if base_data.get("sp_def_growth") else 1.0
			return sp_def + int(float(level) * growth)
	return get_defense()

func get_attack_stage_multiplier() -> float:
	var stage := clampi(attack_stage, -6, 6)
	return STAGE_MULTIPLIERS.get(stage, 1.0)

func get_effective_attack() -> int:
	var base := get_attack()
	if status == "burn":
		base = base / 2
	return maxi(1, int(float(base) * get_attack_stage_multiplier()))

func get_effective_sp_attack() -> int:
	var base := get_sp_attack()
	if status == "burn":
		base = base / 2
	return maxi(1, int(float(base) * get_attack_stage_multiplier()))

func get_effective_agility() -> int:
	if status == "paralysis":
		return get_agility() / 2
	return get_agility()

func get_accuracy_multiplier() -> float:
	var stage := clampi(accuracy_stage, -6, 6)
	return STAGE_MULTIPLIERS.get(stage, 1.0)

func get_evasion_multiplier() -> float:
	var stage := clampi(evasion_stage, -6, 6)
	return STAGE_MULTIPLIERS.get(stage, 1.0)

func reset_stages() -> void:
	attack_stage = 0
	accuracy_stage = 0
	evasion_stage = 0

func modify_attack_stage(amount: int) -> void:
	attack_stage = clampi(attack_stage + amount, -6, 6)

func modify_accuracy_stage(amount: int) -> void:
	accuracy_stage = clampi(accuracy_stage + amount, -6, 6)

func modify_evasion_stage(amount: int) -> void:
	evasion_stage = clampi(evasion_stage + amount, -6, 6)

func get_xp_threshold() -> int:
	return int(pow(float(level), 1.5) * 10.0)

func add_experience(amount: int) -> Dictionary:
	experience += amount
	var result := {
		"leveled_up": false,
		"old_level": level,
		"new_level": level,
		"new_skills": [],
		"can_evolve": false,
		"evolves_into_id": 0
	}
	while experience >= get_xp_threshold():
		experience -= get_xp_threshold()
		var old_max_hp := get_max_hp()
		level += 1
		var new_max_hp := get_max_hp()
		current_hp += new_max_hp - old_max_hp
		result["leveled_up"] = true
		result["new_level"] = level
		# Check learnable skills at this level
		if base_data:
			var learnable: Dictionary = base_data.get("learnable_skills") as Dictionary
			if learnable and learnable.has(level):
				var new_skill: Resource = learnable[level] as Resource
				if new_skill:
					(result["new_skills"] as Array).append(new_skill)
			# Check evolution
			var evo_level: int = int(base_data.get("evolution_level"))
			var evo_id: int = int(base_data.get("evolves_into_id"))
			if evo_level > 0 and evo_id > 0 and level >= evo_level:
				result["can_evolve"] = true
				result["evolves_into_id"] = evo_id
	return result

func evolve(new_base_data: Resource) -> void:
	var old_max_hp := get_max_hp()
	base_data = new_base_data
	var new_max_hp := get_max_hp()
	current_hp += new_max_hp - old_max_hp

func learn_skill(new_skill: Resource, replace_index: int = -1) -> bool:
	if skills.size() < 4:
		skills.append(new_skill)
		return true
	elif replace_index >= 0 and replace_index < skills.size():
		skills[replace_index] = new_skill
		return true
	return false
