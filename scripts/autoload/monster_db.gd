extends Node

var monsters: Dictionary = {}  # id -> MonsterData
var skills: Dictionary = {}    # skill_name -> SkillData

func _ready() -> void:
	_load_skills()
	_load_monsters()
	print("MonsterDB: Loaded %d skills, %d monsters" % [skills.size(), monsters.size()])

func _load_skills() -> void:
	var dir := DirAccess.open("res://data/skills")
	if not dir:
		push_warning("MonsterDB: Could not open skills directory")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var skill := load("res://data/skills/" + file_name) as Resource
			var sname: String = str(skill.get("skill_name")) if skill else ""
			if sname != "":
				skills[sname] = skill
		file_name = dir.get_next()
	dir.list_dir_end()

func _load_monsters() -> void:
	var dir := DirAccess.open("res://data/monsters")
	if not dir:
		push_warning("MonsterDB: Could not open monsters directory")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var monster := load("res://data/monsters/" + file_name) as Resource
			var mid: int = int(monster.get("id")) if monster else 0
			if mid > 0:
				monsters[mid] = monster
		file_name = dir.get_next()
	dir.list_dir_end()

func get_monster(id: int) -> Resource:
	return monsters.get(id)

func get_skill(p_skill_name: String) -> Resource:
	return skills.get(p_skill_name)

func get_starter_monsters() -> Array:
	return [get_monster(1), get_monster(2), get_monster(3)]

func get_random_wild_monster() -> Resource:
	var ids := monsters.keys()
	if ids.is_empty():
		return null
	return monsters[ids[randi() % ids.size()]]
