class_name BattleMonster
extends RefCounted

var instance: MonsterInstance
var is_player: bool

func _init(p_instance: MonsterInstance, p_is_player: bool) -> void:
	instance = p_instance
	is_player = p_is_player

func get_name() -> String:
	return str(instance.base_data.get("monster_name"))

func get_front_sprite() -> Texture2D:
	return instance.base_data.get("front_sprite") as Texture2D

func get_back_sprite() -> Texture2D:
	return instance.base_data.get("back_sprite") as Texture2D

func get_skills() -> Array:
	return instance.skills

func choose_random_skill() -> Resource:
	var skills := instance.skills
	if skills.is_empty():
		return null
	return skills[randi() % skills.size()]
