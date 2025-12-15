extends Control

var is_open := false
var curr_building: Building = null
var inv_section := preload("res://Planet-Section/Scenes/UI/inv_section.tscn")
var inv_slot := preload("res://Planet-Section/Scenes/UI/inv_slot.tscn")


func building_clicked(building: Building) -> void:
	if is_instance_valid(curr_building) and (curr_building == building) and is_open:
		close()
		return
	
	if not is_open:
		open()
	
	disconnect_updates()
	clear_info()
	fill_info(building)
	curr_building = building
	building.request_update.connect(update_info)


func fill_info(building: Building = curr_building) -> void:
	$Content/Card/BuildingName.text = building.name
	var invs := building.inventories
	
	for inv_name in invs.keys():
		var new_inv = inv_section.instantiate()
		new_inv.get_node("SectionName").text = inv_name
		$Content/Card/Inventories.add_child(new_inv)
		
		var slot_target: GridContainer = new_inv.get_node("GridContainer")
		for slot in invs[inv_name].slots:
			var new_slot = inv_slot.instantiate()
			if is_instance_valid(slot):
				new_slot.get_node("Item").texture = slot.item.icon
			
			slot_target.add_child(new_slot)
		
		for i in range(slot_target.columns):
			var padding = PanelContainer.new()
			slot_target.add_child(padding)
	


func update_info() -> void:
	pass


func clear_info() -> void:
	for inv in $Content/Card/Inventories.get_children():
		inv.queue_free()


func disconnect_updates(source: Building = curr_building) -> void:
	if not is_instance_valid(source):
		return
	if not source.request_update.is_connected(update_info):
		return
	
	source.request_update.disconnect(update_info)


func open() -> void:
	if %UI/BuildingMenu.is_open:
		%UI/BuildingMenu._on_tab_pressed("Exit")
	
	$AnimationPlayer.play("open")
	is_open = true

func close():
	$AnimationPlayer.stop()
	$AnimationPlayer.play("close")
	is_open = false
	disconnect_updates()
