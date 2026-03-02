extends Node

const GAME_VERSION: String = "v0.6.0"

signal party_changed
signal inventory_changed
signal pc_storage_changed
signal registry_changed
signal quest_updated(quest_id: String)
signal time_changed(new_period: String)
signal gold_changed
signal trainer_rank_changed

var player_gender: String = ""  # "boy" or "girl"
var gold: int = 100
var trainer_rank: int = 1
var trainer_experience: int = 0

const TRAINER_TITLES: Dictionary = {
	1: "Rookie", 6: "Novice", 11: "Skilled", 16: "Veteran", 21: "Expert", 31: "Master",
}
var player_party: Array[MonsterInstance] = []
var pc_storage: Array[MonsterInstance] = []
var defeated_monster_ids: Array[int] = []  # Track removed overworld monsters (legacy, for backward compat)
var is_in_battle: bool = false
var is_in_menu: bool = false
var is_in_dialogue: bool = false
var monster_registry_seen: Dictionary = {}
var monster_registry_caught: Dictionary = {}

# ── Debug Flags ──
var DEBUG_TRAINER: bool = false

# ── Badges & Trainers ──
var badges: Dictionary = {}              # { "gym_1": true }
var defeated_trainers: Dictionary = {}   # { "town2_gym": true }

# ── Inventory ──
var inventory: Dictionary = {}  # { item_id: count }

const SHOP_PRICES: Dictionary = {
	"potion": 100,
	"super_potion": 300,
	"capture_ball": 150,
	"great_ball": 400,
	"antidote": 75,
}

const ITEM_DEFS: Dictionary = {
	"potion": {"name": "Potion", "type": "heal", "value": 30, "battle": true},
	"super_potion": {"name": "Super Potion", "type": "heal", "value": 60, "battle": true},
	"capture_ball": {"name": "Capture Ball", "type": "catch", "value": 1.5, "battle": true},
	"great_ball": {"name": "Great Ball", "type": "catch", "value": 2.0, "battle": true},
	"antidote": {"name": "Antidote", "type": "cure", "value": "poison", "battle": true},
}

# ── Area Persistence ──
var current_area: String = "town"
var area_player_positions: Dictionary = {}  # { area_name: Vector2 }
var area_defeated_monsters: Dictionary = {}  # { area_name: Array[int] }

# ── Building Interior State ──
var is_in_building: bool = false
var building_return_area: String = ""
var building_return_position: Vector2 = Vector2.ZERO

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

# ── PC Storage Methods ──

func add_to_pc(monster: MonsterInstance) -> void:
	pc_storage.append(monster)
	pc_storage_changed.emit()

func remove_from_pc(index: int) -> MonsterInstance:
	if index < 0 or index >= pc_storage.size():
		return null
	var monster := pc_storage[index]
	pc_storage.remove_at(index)
	pc_storage_changed.emit()
	return monster

func move_pc_to_party(pc_index: int) -> bool:
	if player_party.size() >= 6:
		return false
	if pc_index < 0 or pc_index >= pc_storage.size():
		return false
	var monster := pc_storage[pc_index]
	pc_storage.remove_at(pc_index)
	player_party.append(monster)
	party_changed.emit()
	pc_storage_changed.emit()
	return true

func move_party_to_pc(party_index: int) -> bool:
	if player_party.size() <= 1:
		return false
	if party_index < 0 or party_index >= player_party.size():
		return false
	var monster := player_party[party_index]
	player_party.remove_at(party_index)
	pc_storage.append(monster)
	party_changed.emit()
	pc_storage_changed.emit()
	return true

# ── Monster Registry Methods ──

func mark_monster_seen(id: int) -> void:
	if id <= 0:
		return
	if not monster_registry_seen.has(id):
		monster_registry_seen[id] = true
		registry_changed.emit()

func mark_monster_caught(id: int) -> void:
	if id <= 0:
		return
	var changed := false
	if not monster_registry_seen.has(id):
		monster_registry_seen[id] = true
		changed = true
	if not monster_registry_caught.has(id):
		monster_registry_caught[id] = true
		changed = true
	if changed:
		registry_changed.emit()

func is_monster_seen(id: int) -> bool:
	return monster_registry_seen.has(id)

func is_monster_caught(id: int) -> bool:
	return monster_registry_caught.has(id)

func get_seen_count() -> int:
	return monster_registry_seen.size()

func get_caught_count() -> int:
	return monster_registry_caught.size()

func get_total_monster_count() -> int:
	return MonsterDB.monsters.size()

func sync_registry_from_owned_monsters() -> void:
	for monster in player_party:
		var id: int = int(monster.base_data.get("id"))
		if id > 0:
			mark_monster_caught(id)
	for monster in pc_storage:
		var id: int = int(monster.base_data.get("id"))
		if id > 0:
			mark_monster_caught(id)

# ── Badge & Trainer Methods ──

func earn_badge(badge_id: String) -> void:
	badges[badge_id] = true

func has_badge(badge_id: String) -> bool:
	return badges.has(badge_id)

func get_badge_count() -> int:
	return badges.size()

func mark_trainer_defeated(trainer_id: String) -> void:
	defeated_trainers[trainer_id] = true

func is_trainer_defeated(trainer_id: String) -> bool:
	return defeated_trainers.has(trainer_id)

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

# ── Gold Methods ──

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit()

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit()
	return true

func get_gold() -> int:
	return gold

# ── Quest System ──

const QUEST_DEFS: Dictionary = {
	"fetch_herb": {
		"name": "Herb Delivery",
		"description": "Talk to the elder in Monster Town.",
		"type": "talk",
		"goal": 1,
	},
	"defeat_route2_trainer": {
		"name": "Route 2 Challenge",
		"description": "Defeat Bug Catcher Tim on Route 2.",
		"type": "defeat_trainer",
		"target": "route2_trainer1",
		"goal": 1,
	},
	"catch_5_monsters": {
		"name": "Monster Collector",
		"description": "Catch 5 wild monsters.",
		"type": "catch_count",
		"goal": 5,
	},
}

var active_quests: Dictionary = {}    # { quest_id: { "progress": int } }
var completed_quests: Dictionary = {} # { quest_id: true }

func start_quest(quest_id: String) -> void:
	if not QUEST_DEFS.has(quest_id):
		return
	if active_quests.has(quest_id) or completed_quests.has(quest_id):
		return
	active_quests[quest_id] = {"progress": 0}
	quest_updated.emit(quest_id)

func advance_quest(quest_id: String, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return
	active_quests[quest_id]["progress"] += amount
	var quest_def: Dictionary = QUEST_DEFS.get(quest_id, {})
	var goal: int = int(quest_def.get("goal", 1))
	if active_quests[quest_id]["progress"] >= goal:
		complete_quest(quest_id)
	else:
		quest_updated.emit(quest_id)

func complete_quest(quest_id: String) -> void:
	if completed_quests.has(quest_id):
		return
	active_quests.erase(quest_id)
	completed_quests[quest_id] = true
	quest_updated.emit(quest_id)

func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)

func is_quest_complete(quest_id: String) -> bool:
	return completed_quests.has(quest_id)

func get_quest_progress(quest_id: String) -> int:
	if active_quests.has(quest_id):
		return int(active_quests[quest_id]["progress"])
	return 0

func get_quest_def(quest_id: String) -> Dictionary:
	return QUEST_DEFS.get(quest_id, {})

# ── Day/Night Cycle ──

var game_time: float = 10.0  # Hours (0-24)
var time_period: String = "day"

const TIME_PERIODS: Dictionary = {
	"dawn":  {"start": 5.0, "end": 7.0, "color": Color(1.0, 0.9, 0.8)},
	"day":   {"start": 7.0, "end": 17.0, "color": Color(1.0, 1.0, 1.0)},
	"dusk":  {"start": 17.0, "end": 19.0, "color": Color(1.0, 0.8, 0.6)},
	"night": {"start": 19.0, "end": 5.0, "color": Color(0.6, 0.6, 0.9)},
}

func advance_time(hours: float) -> void:
	game_time += hours
	if game_time >= 24.0:
		game_time -= 24.0
	var new_period: String = _get_time_period()
	if new_period != time_period:
		time_period = new_period
		time_changed.emit(time_period)

func _get_time_period() -> String:
	for period_name: String in TIME_PERIODS:
		var period: Dictionary = TIME_PERIODS[period_name]
		var start_h: float = float(period["start"])
		var end_h: float = float(period["end"])
		if start_h < end_h:
			if game_time >= start_h and game_time < end_h:
				return period_name
		else:
			# Wraps midnight (night: 19-5)
			if game_time >= start_h or game_time < end_h:
				return period_name
	return "day"

func get_time_color() -> Color:
	return TIME_PERIODS.get(time_period, TIME_PERIODS["day"])["color"] as Color

# ── Trainer Rank ──

func get_trainer_xp_threshold() -> int:
	return int(pow(float(trainer_rank), 1.5) * 10.0)

func add_trainer_experience(amount: int) -> Dictionary:
	var result := {"ranked_up": false, "old_rank": trainer_rank, "new_rank": trainer_rank}
	trainer_experience += amount
	while trainer_experience >= get_trainer_xp_threshold():
		trainer_experience -= get_trainer_xp_threshold()
		trainer_rank += 1
		result["ranked_up"] = true
		result["new_rank"] = trainer_rank
	if result["ranked_up"]:
		trainer_rank_changed.emit()
	return result

func get_trainer_title() -> String:
	var best_title: String = "Rookie"
	for threshold: int in TRAINER_TITLES:
		if trainer_rank >= threshold:
			best_title = TRAINER_TITLES[threshold]
	return best_title

func reset_trainer_rank() -> void:
	trainer_rank = 1
	trainer_experience = 0
