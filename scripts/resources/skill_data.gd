class_name SkillData
extends Resource

@export var skill_name: String
@export var power: int
@export var accuracy: float = 1.0
@export var skill_type: String = "Normal"
@export var category: String = "physical"  # "physical" or "special"
@export var hit_min: int = 1
@export var hit_max: int = 1
@export var status_effect: String = ""  # "poison", "burn", "paralysis", or ""
@export var status_chance: float = 0.0  # 0.0–1.0
