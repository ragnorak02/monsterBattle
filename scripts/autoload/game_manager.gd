extends Node

signal party_changed

var player_gender: String = ""  # "boy" or "girl"
var player_party: Array[MonsterInstance] = []
var defeated_monster_ids: Array[int] = []  # Track removed overworld monsters
var is_in_battle: bool = false
var is_in_menu: bool = false
var is_in_dialogue: bool = false

func can_player_move() -> bool:
	return not is_in_battle and not is_in_menu and not is_in_dialogue

func add_to_party(monster: MonsterInstance) -> void:
	if player_party.size() < 6:
		player_party.append(monster)
		party_changed.emit()

func get_first_alive_monster() -> MonsterInstance:
	for monster in player_party:
		if not monster.is_fainted():
			return monster
	return null

func all_fainted() -> bool:
	for monster in player_party:
		if not monster.is_fainted():
			return false
	return true

func mark_monster_defeated(overworld_id: int) -> void:
	if overworld_id not in defeated_monster_ids:
		defeated_monster_ids.append(overworld_id)

func is_monster_defeated(overworld_id: int) -> bool:
	return overworld_id in defeated_monster_ids

func heal_all_party() -> void:
	for monster in player_party:
		monster.heal_full()
	party_changed.emit()
