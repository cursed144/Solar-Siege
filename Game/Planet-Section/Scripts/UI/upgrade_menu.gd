extends Control

const REQ := preload("res://Planet-Section/Scenes/UI/building_placement_requirement.tscn")

var building: Building = null
var upgrade_requirements: UpgradeRequirement

@onready var req_placement := $Requirements/HBoxContainer


func _process(_delta: float) -> void:
	if is_instance_valid(building):
		for i in range(req_placement.get_child_count()):
			var item_amount = upgrade_requirements.items[i]
			var row = req_placement.get_child(i)
			row.set_item(item_amount.item, item_amount.amount)
		set_confirm_button_status()


func on_upgrade_button_clicked(_building: Building) -> void:
	if not is_instance_valid(_building):
		return
	
	clear()
	show()
	building = _building
	var sprite = building.get_node("Sprite2D").texture
	$BuildImage.texture = sprite
	$Level.text = "Upgrade To Level " + str(building.level + 1)
	
	upgrade_requirements = building.level_reqs[building.level-1] # Building starts as level 1
	for item_amount in upgrade_requirements.items:
		var new_req = REQ.instantiate()
		req_placement.add_child(new_req)


func clear() -> void:
	building = null
	
	for child in req_placement.get_children():
		child.queue_free()
	
	hide()


func set_confirm_button_status() -> void:
	var valid := true
	
	for row in req_placement.get_children():
		if not row.is_valid():
			valid = false
			break
	
	if valid:
		$Confirm.disabled = false
		$Confirm.self_modulate = Color.WHITE
		$Confirm.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		$Confirm.disabled = true
		$Confirm.self_modulate = Color(1, 1, 1, 0.5)
		$Confirm.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_confirm_pressed() -> void:
	var planet = get_tree().current_scene
	planet.create_global_claim(name, upgrade_requirements)
	planet.get_claimed_global_items(name)
	building.begin_upgrade(upgrade_requirements.upgrade_time)

func _on_cancel_pressed() -> void:
	clear()
