class_name Item
extends Resource

@export var id: ItemLoader.ItemID
@export var name: String
@export var icon: Texture2D
@export var max_per_stack: int


static func sort_by_id_asc(a: Item, b: Item):
		if a.id < b.id:
			return true
		return false
