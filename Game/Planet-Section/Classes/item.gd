class_name Item
extends Resource

enum ID {
	WOOD_LOG,
	ROCK,
	COAL,
	IRON_ORE,
	WOOD_PLANKS,
	STEEL_PLATES
}

@export var id: int
@export var name: String
@export var icon: Texture2D
@export var max_per_stack: int


static func new_item(_id: int = 0, _max_per_stack: int = 40, _name: String = "ITEM", _icon: Texture2D = null) -> Item:
	var item := Item.new()
	item.id = _id
	item.max_per_stack = _max_per_stack
	item.name = _name
	item.icon = _icon
	
	return item
