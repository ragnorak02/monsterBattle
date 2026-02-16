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
@export var starting_skills: Array[Resource] = []
