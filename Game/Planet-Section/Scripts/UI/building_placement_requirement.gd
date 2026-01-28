extends Control

var global_amount = 0
var req_amount = 1

@onready var planet = get_tree().current_scene

func set_item(item: Item, _req_amount: int) -> void:
	global_amount = planet.get_global_item_amount(item)
	req_amount = _req_amount
	
	$Icon.texture = item.icon
	$Amount.text = "%d / %d" % [global_amount, req_amount]
	
	if not is_valid():
		$Amount.self_modulate = Color.from_rgba8(210, 0, 0, 255)
	else:
		$Amount.self_modulate = Color.from_rgba8(0, 168, 0, 255)


func is_valid() -> bool:
	return (global_amount >= req_amount)
