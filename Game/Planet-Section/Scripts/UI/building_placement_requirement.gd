extends Control

func set_item(item: Item, req_amount: int) -> void:
	var planet = get_tree().current_scene
	var global_amount = planet.get_global_item_amount(item)
	$Icon.texture = item.icon
	$Amount.text = "%d / %d" % [global_amount, req_amount]
	
	if global_amount < req_amount:
		$Amount.self_modulate = Color.from_rgba8(210, 0, 0, 255)
	else:
		$Amount.self_modulate = Color.from_rgba8(0, 168, 0, 255)
