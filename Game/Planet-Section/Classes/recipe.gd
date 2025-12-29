class_name Recipe
extends Resource

@export var recipe_name: String
@export var display_icon: Texture2D
@export var requirements: Array[ItemAmount]
@export var outputs: Array[ItemAmount]
@export var creation_time: float
@export var is_unlocked: bool


static func amounts_to_stacks(amounts: Array[ItemAmount]) -> Array[ItemStack]:
	var out: Array[ItemStack] = []
	
	for amount in amounts:
		if amount == null:
			continue
		out.append_array(amount.to_stack())
	
	return out
