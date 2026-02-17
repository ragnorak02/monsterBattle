class_name MonsterInstance
extends Resource

@export var base_data: Resource  # MonsterData
@export var level: int = 5
@export var current_hp: int = 0
@export var skills: Array[Resource] = []  # Array of SkillData
@export var experience: int = 0

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
		return int(base_data.get("max_hp")) + (level * 2)
	return 1

func get_attack() -> int:
	if base_data:
		return int(base_data.get("attack")) + level
	return 1

func get_defense() -> int:
	if base_data:
		return int(base_data.get("defense")) + level
	return 1

func get_agility() -> int:
	if base_data:
		return int(base_data.get("agility")) + level
	return 1

func is_fainted() -> bool:
	return current_hp <= 0

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)

func heal(amount: int) -> void:
	current_hp = min(get_max_hp(), current_hp + amount)

func heal_full() -> void:
	current_hp = get_max_hp()

func get_xp_threshold() -> int:
	return level * level * 10

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
