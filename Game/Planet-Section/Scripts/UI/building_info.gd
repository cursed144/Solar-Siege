extends Control

var is_open := false
var curr_building: Building = null
const inv_section := preload("res://Planet-Section/Scenes/UI/inv_section.tscn")
const inv_slot := preload("res://Planet-Section/Scenes/UI/inv_slot.tscn")
@onready var item_deleter = %UI/DeleteItemConf


func building_clicked(building: Building) -> void:
	if is_instance_valid(curr_building) and (curr_building == building) and is_open:
		close()
		return
	
	if not is_open:
		open()
	
	if curr_building == building:
		return
	
	disconnect_updates()
	clear_info()
	fill_info(building)
	curr_building = building
	building.request_inv_update.connect(update_inv)


func fill_info(building: Building = curr_building) -> void:
	$Content/Card/BuildingName.text = building.name
	var invs := building.inventories
	
	for inv_name in invs.keys():
		var new_inv = inv_section.instantiate()
		new_inv.get_node("SectionName").text = inv_name
		new_inv.name = inv_name
		$Content/Card/Inventories.add_child(new_inv)
		
		var slot_target: GridContainer = new_inv.get_node("GridContainer")
		var slots = invs[inv_name].slots
		for i in range(slots.size()):
			var new_slot = inv_slot.instantiate()
			new_slot.set_slot(slots, i, true)
			slot_target.add_child(new_slot)
			new_slot.inv_slot_clicked.connect(item_deleter.delete_item_prompt)
		
		for i in range(slot_target.columns):
			var padding = PanelContainer.new()
			slot_target.add_child(padding)
	


func update_inv(inv_name: String) -> void:
	var invs := curr_building.inventories
	
	var target_inv: Control = $Content/Card/Inventories.get_node(inv_name + "/GridContainer")
	var slots = invs[inv_name].slots
	for i in range(slots.size()):
		var slot = target_inv.get_child(i)
		slot.set_slot(slots, i, false)


func disconnect_updates(source: Building = curr_building) -> void:
	if not is_instance_valid(source):
		return
	if not source.request_update.is_connected(update_inv):
		return
	
	source.request_update.disconnect(update_inv)


func clear_info() -> void:
	for inv in $Content/Card/Inventories.get_children():
		inv.queue_free()


func open() -> void:
	if %UI/BuildingMenu.is_open:
		%UI/BuildingMenu._on_tab_pressed("Exit")
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", Vector2.ZERO, 0.65)
	
	is_open = true

func close():
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", Vector2(-300, 0), 0.60)
	
	is_open = false
