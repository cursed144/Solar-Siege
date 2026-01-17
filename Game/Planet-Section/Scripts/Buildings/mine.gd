extends Building

var prod_items: Dictionary[Recipe, int]

func _ready() -> void:
	super._ready()
	var planet = get_tree().current_scene
	prod_items = planet.mine
	
	for recipe in prod_items:
		recipes.append(recipe)
