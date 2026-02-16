class_name MonsterInstance
extends Resource

@export var base_data: Resource  # MonsterData
@export var level: int = 5
@export var current_hp: int = 0
@export var skills: Array[Resource] = []  # Array of SkillData

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
