class_name MonsterData
extends Resource

@export var id: int
@export var monster_name: String
@export var front_sprite: Texture2D
@export var back_sprite: Texture2D
@export var overworld_sprite: SpriteFrames
@export var max_hp: int
@export var attack: int
@export var defense: int
@export var agility: int
@export var element_type: String = "Normal"
@export var starting_skills: Array[Resource] = []
@export var evolves_into_id: int = 0
@export var evolution_level: int = 0
@export var learnable_skills: Dictionary = {}  # { int_level: SkillData resource }
