extends ProductionBuilding

var prod_items: Dictionary[Recipe, int]

func _ready() -> void:
	super._ready()
	var planet = get_tree().current_scene
	prod_items = planet.mine
	
	var temp := []
	for recipe in prod_items:
		temp.append(recipe)
	
	while temp.size() > 0:
		recipes.push_front(temp.pop_back())
