class_name Recipe
extends Resource

@export var recipe_name: String
@export var display_icon: Texture2D
@export var requirements: Array[ItemAmount]
@export var outputs: Array[ItemAmount]
@export var creation_time: float
@export var unlocks_at_level: int = 1
