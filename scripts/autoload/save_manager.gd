extends Node

const SAVE_PATH: String = "user://save_data.json"
const BACKUP_PATH: String = "user://save_data.backup.json"
const CURRENT_SAVE_VERSION: int = 4

func save_game() -> bool:
	# Create backup of existing save before writing
	if FileAccess.file_exists(SAVE_PATH):
		var existing := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if existing:
			var content := existing.get_as_text()
			existing.close()
			var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if backup:
				backup.store_string(content)
				backup.close()

	var data: Dictionary = _serialize()
	var json_string := JSON.stringify(data, "\t")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Could not open save file for writing")
		return false
	file.store_string(json_string)
	file.close()
	print("SaveManager: Game saved")
	return true

func load_game() -> bool:
	var data: Dictionary = _load_json(SAVE_PATH)
	if data.is_empty():
		# Try backup
		print("SaveManager: Primary save failed, trying backup...")
		data = _load_json(BACKUP_PATH)
	if data.is_empty():
		push_error("SaveManager: No valid save data found")
		return false

	data = _migrate_save(data)

	if not _validate_save(data):
		push_error("SaveManager: Save data validation failed")
		return false

	_deserialize(data)
	print("SaveManager: Game loaded")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)
	print("SaveManager: Save deleted")

# ── Serialization ──

func _serialize() -> Dictionary:
	var data: Dictionary = {}
	data["save_version"] = CURRENT_SAVE_VERSION
	data["player_gender"] = GameManager.player_gender
	data["gold"] = GameManager.gold
	data["current_area"] = GameManager.current_area
	data["game_time"] = GameManager.game_time
	data["time_period"] = GameManager.time_period
	data["trainer_rank"] = GameManager.trainer_rank
	data["trainer_experience"] = GameManager.trainer_experience

	# Building state
	data["is_in_building"] = GameManager.is_in_building
	data["building_return_area"] = GameManager.building_return_area
	data["building_return_position"] = {"x": GameManager.building_return_position.x, "y": GameManager.building_return_position.y}

	# Party
	data["player_party"] = _serialize_monster_array(GameManager.player_party)

	# PC Storage
	data["pc_storage"] = _serialize_monster_array(GameManager.pc_storage)

	# Inventory
	data["inventory"] = GameManager.inventory.duplicate()

	# Badges & Trainers
	data["badges"] = GameManager.badges.duplicate()
	data["defeated_trainers"] = GameManager.defeated_trainers.duplicate()

	# Registry
	var seen_keys: Array = []
	for key in GameManager.monster_registry_seen:
		seen_keys.append(key)
	data["monster_registry_seen"] = seen_keys

	var caught_keys: Array = []
	for key in GameManager.monster_registry_caught:
		caught_keys.append(key)
	data["monster_registry_caught"] = caught_keys

	# Quests
	data["active_quests"] = GameManager.active_quests.duplicate(true)
	data["completed_quests"] = GameManager.completed_quests.duplicate()

	# Area state
	var positions: Dictionary = {}
	for area_name: String in GameManager.area_player_positions:
		var pos: Vector2 = GameManager.area_player_positions[area_name]
		positions[area_name] = {"x": pos.x, "y": pos.y}
	data["area_player_positions"] = positions

	data["area_defeated_monsters"] = GameManager.area_defeated_monsters.duplicate(true)

	# Legacy defeated monster IDs
	data["defeated_monster_ids"] = GameManager.defeated_monster_ids.duplicate()

	return data

func _serialize_monster_array(monsters: Array) -> Array:
	var result: Array = []
	for monster: MonsterInstance in monsters:
		result.append(_serialize_monster(monster))
	return result

func _serialize_monster(monster: MonsterInstance) -> Dictionary:
	var skill_names: Array = []
	for skill: Resource in monster.skills:
		if skill:
			skill_names.append(str(skill.get("skill_name")))

	var base_id: int = 0
	if monster.base_data:
		base_id = int(monster.base_data.get("id"))

	return {
		"base_id": base_id,
		"level": monster.level,
		"current_hp": monster.current_hp,
		"experience": monster.experience,
		"skill_names": skill_names,
		"status": monster.status,
	}

# ── Deserialization ──

func _deserialize(data: Dictionary) -> void:
	GameManager.player_gender = str(data.get("player_gender", ""))
	GameManager.gold = int(data.get("gold", 100))
	GameManager.current_area = str(data.get("current_area", "town"))
	GameManager.game_time = float(data.get("game_time", 10.0))
	GameManager.time_period = str(data.get("time_period", "day"))
	GameManager.trainer_rank = int(data.get("trainer_rank", 1))
	GameManager.trainer_experience = int(data.get("trainer_experience", 0))

	# Building state
	GameManager.is_in_building = bool(data.get("is_in_building", false))
	GameManager.building_return_area = str(data.get("building_return_area", ""))
	var bpos_data: Dictionary = data.get("building_return_position", {})
	GameManager.building_return_position = Vector2(
		float(bpos_data.get("x", 0.0)),
		float(bpos_data.get("y", 0.0))
	)

	# Party
	GameManager.player_party = _deserialize_monster_array(data.get("player_party", []))

	# PC Storage
	GameManager.pc_storage = _deserialize_monster_array(data.get("pc_storage", []))

	# Inventory
	GameManager.inventory = {}
	var inv: Dictionary = data.get("inventory", {})
	for key: String in inv:
		GameManager.inventory[key] = int(inv[key])

	# Badges & Trainers
	GameManager.badges = {}
	var badges_data: Dictionary = data.get("badges", {})
	for key: String in badges_data:
		GameManager.badges[key] = true

	GameManager.defeated_trainers = {}
	var trainers_data: Dictionary = data.get("defeated_trainers", {})
	for key: String in trainers_data:
		GameManager.defeated_trainers[key] = true

	# Registry
	GameManager.monster_registry_seen = {}
	var seen_arr: Array = data.get("monster_registry_seen", [])
	for id in seen_arr:
		GameManager.monster_registry_seen[int(id)] = true

	GameManager.monster_registry_caught = {}
	var caught_arr: Array = data.get("monster_registry_caught", [])
	for id in caught_arr:
		GameManager.monster_registry_caught[int(id)] = true

	# Quests
	GameManager.active_quests = {}
	var active_q: Dictionary = data.get("active_quests", {})
	for key: String in active_q:
		GameManager.active_quests[key] = active_q[key]

	GameManager.completed_quests = {}
	var completed_q: Dictionary = data.get("completed_quests", {})
	for key: String in completed_q:
		GameManager.completed_quests[key] = true

	# Area positions
	GameManager.area_player_positions = {}
	var positions: Dictionary = data.get("area_player_positions", {})
	for area_name: String in positions:
		var pos_data: Dictionary = positions[area_name]
		GameManager.area_player_positions[area_name] = Vector2(
			float(pos_data.get("x", 0.0)),
			float(pos_data.get("y", 0.0))
		)

	# Area defeated monsters
	GameManager.area_defeated_monsters = {}
	var area_defeated: Dictionary = data.get("area_defeated_monsters", {})
	for area_name: String in area_defeated:
		var ids: Array = area_defeated[area_name]
		var int_ids: Array[int] = []
		for id in ids:
			int_ids.append(int(id))
		GameManager.area_defeated_monsters[area_name] = int_ids

	# Legacy defeated monster IDs
	GameManager.defeated_monster_ids = []
	var legacy_ids: Array = data.get("defeated_monster_ids", [])
	for id in legacy_ids:
		GameManager.defeated_monster_ids.append(int(id))

func _deserialize_monster_array(arr: Array) -> Array[MonsterInstance]:
	var result: Array[MonsterInstance] = []
	for entry in arr:
		var monster := _deserialize_monster(entry as Dictionary)
		if monster:
			result.append(monster)
	return result

func _deserialize_monster(data: Dictionary) -> MonsterInstance:
	var base_id: int = int(data.get("base_id", 0))
	if base_id <= 0:
		return null
	var base_data: Resource = MonsterDB.get_monster(base_id)
	if not base_data:
		push_warning("SaveManager: Unknown monster ID %d, skipping" % base_id)
		return null

	var monster := MonsterInstance.new(base_data, int(data.get("level", 5)))
	monster.current_hp = int(data.get("current_hp", monster.get_max_hp()))
	monster.experience = int(data.get("experience", 0))
	monster.status = str(data.get("status", ""))

	# Restore skills
	var skill_names: Array = data.get("skill_names", [])
	if not skill_names.is_empty():
		monster.skills = []
		for sname in skill_names:
			var skill: Resource = MonsterDB.get_skill(str(sname))
			if skill:
				monster.skills.append(skill)

	return monster

# ── Migration ──

func _migrate_save(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("save_version", 0))
	if version < 1:
		data["save_version"] = 1
	if version < 2:
		data["gold"] = 100
		data["save_version"] = 2
	if version < 3:
		data["trainer_rank"] = 1
		data["trainer_experience"] = 0
		data["save_version"] = 3
	if version < 4:
		data["is_in_building"] = false
		data["building_return_area"] = ""
		data["building_return_position"] = {"x": 0.0, "y": 0.0}
		data["save_version"] = 4
	return data

# ── Validation ──

func _validate_save(data: Dictionary) -> bool:
	if not data.has("save_version"):
		return false
	if not data.has("player_gender"):
		return false
	if not data.has("player_party"):
		return false
	return true

# ── JSON Loading ──

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_warning("SaveManager: JSON parse error in %s" % path)
		return {}

	if json.data is Dictionary:
		return json.data as Dictionary
	return {}
