extends Node

signal party_changed
signal inventory_changed

var player_gender: String = ""  # "boy" or "girl"
var player_party: Array[MonsterInstance] = []
var defeated_monster_ids: Array[int] = []  # Track removed overworld monsters (legacy, for backward compat)
var is_in_battle: bool = false
var is_in_menu: bool = false
var is_in_dialogue: bool = false

# ── Inventory ──
var inventory: Dictionary = {}  # { item_id: count }

const ITEM_DEFS: Dictionary = {
	"potion": {"name": "Potion", "type": "heal", "value": 30, "battle": true},
	"super_potion": {"name": "Super Potion", "type": "heal", "value": 60, "battle": true},
	"capture_ball": {"name": "Capture Ball", "type": "catch", "value": 1.5, "battle": true},
	"great_ball": {"name": "Great Ball", "type": "catch", "value": 2.0, "battle": true},
	"antidote": {"name": "Antidote", "type": "heal", "value": 0, "battle": false},
}

# ── Area Persistence ──
var current_area: String = "town"
var area_player_positions: Dictionary = {}  # { area_name: Vector2 }
var area_defeated_monsters: Dictionary = {}  # { area_name: Array[int] }

func get_area_defeated(area: String) -> Array:
	if area_defeated_monsters.has(area):
		return area_defeated_monsters[area]
	return []

func mark_area_monster_defeated(area: String, overworld_id: int) -> void:
	if not area_defeated_monsters.has(area):
		area_defeated_monsters[area] = []
	if overworld_id not in area_defeated_monsters[area]:
		area_defeated_monsters[area].append(overworld_id)

func is_area_monster_defeated(area: String, overworld_id: int) -> bool:
	if not area_defeated_monsters.has(area):
		return false
	return overworld_id in area_defeated_monsters[area]

func set_area_player_position(area: String, pos: Vector2) -> void:
	area_player_positions[area] = pos

func get_area_player_position(area: String) -> Variant:
	return area_player_positions.get(area, null)

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

# ── Inventory Methods ──

func add_item(item_id: String, count: int = 1) -> bool:
	if not ITEM_DEFS.has(item_id):
		return false
	if inventory.has(item_id):
		inventory[item_id] += count
	else:
		inventory[item_id] = count
	inventory_changed.emit()
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	if not inventory.has(item_id) or inventory[item_id] < count:
		return false
	inventory[item_id] -= count
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	inventory_changed.emit()
	return true

func get_item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

func get_item_def(item_id: String) -> Dictionary:
	return ITEM_DEFS.get(item_id, {})

func get_battle_items() -> Array:
	var items: Array = []
	for item_id: String in inventory:
		if ITEM_DEFS.has(item_id) and ITEM_DEFS[item_id]["battle"]:
			items.append({"id": item_id, "name": ITEM_DEFS[item_id]["name"], "count": inventory[item_id]})
	return items
