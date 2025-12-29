extends Control

var is_open := false
var curr_building: Building = null

const inv_section := preload("res://Planet-Section/Scenes/UI/inv_section.tscn")
const worker_row := preload("res://Planet-Section/Scenes/UI/worker_row.tscn")
const inv_slot := preload("res://Planet-Section/Scenes/UI/inv_slot.tscn")
@onready var item_deleter = %UI/DeleteItemConf

@onready var inventories_container: Node = $Content/Card/Inventories
@onready var name_label: Label = $Content/Card/BuildingName


func building_clicked(building: Building) -> void:
	# toggle close on second click
	if is_instance_valid(curr_building) and curr_building == building and is_open:
		close()
		return
	
	if not is_open:
		open()
	
	# if same building, nothing to do
	if curr_building == building:
		return
	
	# switch selection: disconnect old, clear UI, attach new
	_disconnect_from_building()
	clear_info()
	
	curr_building = building
	_fill_inv_info(building)
	_fill_worker_info(building)
	
	# connect updates from the building
	if not building.request_inv_update.is_connected(update_inv):
		building.request_inv_update.connect(update_inv)
	
	if not building.request_worker_info_update.is_connected(update_worker_info):
		building.request_worker_info_update.connect(update_worker_info)
	
	if not building.destroyed.is_connected(_on_building_destroyed):
		building.destroyed.connect(_on_building_destroyed)


func _fill_inv_info(building: Building) -> void:
	if not is_instance_valid(building):
		return
	name_label.text = building.name
	
	var invs := building.inventories
	for inv_name in invs.keys():
		var new_inv = inv_section.instantiate()
		new_inv.get_node("SectionName").text = inv_name
		new_inv.name = inv_name
		inventories_container.add_child(new_inv)
		
		var slot_target: GridContainer = new_inv.get_node("GridContainer")
		var slots = invs[inv_name].slots
		for i in range(slots.size()):
			var new_slot: UiInvSlot = inv_slot.instantiate()
			new_slot.set_slot(slots, i, invs[inv_name].is_slot_claimed(i))
			slot_target.add_child(new_slot)
			
			# connect to item_deleter
			if not new_slot.inv_slot_clicked.is_connected(item_deleter.delete_item_prompt):
				new_slot.inv_slot_clicked.connect(item_deleter.delete_item_prompt)
		
		for i in range(slot_target.columns):
			var padding = PanelContainer.new()
			slot_target.add_child(padding)


func _fill_worker_info(building: Building) -> void:
	if not is_instance_valid(building):
		return
	
	update_worker_info(building)
	
	var worker_list = $Content/Card/WorkerSection/WorkerList
	for worker in range(building.worker_limit):
		add_worker_row(worker_list)


func update_inv(inv_name: String) -> void:
	if not is_instance_valid(curr_building):
		_disconnect_from_building()
		close()
		return
	
	var invs := curr_building.inventories
	var target_inv_path := inv_name + "/GridContainer"
	if not inventories_container.has_node(target_inv_path):
		clear_info()
		_fill_inv_info(curr_building)
		return
	
	var target_inv: Control = inventories_container.get_node(target_inv_path)
	var slots = invs[inv_name].slots
	
	# update every slot UI child with new data
	for i in range(slots.size()):
		if i >= target_inv.get_child_count():
			clear_info()
			_fill_inv_info(curr_building)
			return
		var slot = target_inv.get_child(i)
		slot.set_slot(slots, i, invs[inv_name].is_slot_claimed(i))


func update_worker_info(building: Building = curr_building) -> void:
	var worker_nums = $Content/Card/WorkerSection/WorkerInfo/HBoxContainer
	var format_string_max = "Limit Workers: %d/%d"
	var format_string_current = "Current workers: %d"
	worker_nums.get_node("Max").text = format_string_max % [building.worker_limit, building.max_workers]
	worker_nums.get_node("Current").text = format_string_current % building.assigned_workers.size()


func add_worker_row(dest: Node) -> void:
	var new_row = worker_row.instantiate()
	dest.add_child(new_row)
	
	if dest.get_child_count() <= 1:
		var padding = PanelContainer.new()
		dest.add_child(padding)
	else:
		dest.move_child(new_row, -2)


func pop_worker_row(target: Node) -> void:
	if target.get_child_count() <= 2:
		for child in target.get_children():
			child.queue_free()
		return
	
	target.get_child(-2).queue_free()


func _on_worker_increase_pressed() -> void:
	if not is_instance_valid(curr_building):
		return
	
	if curr_building.increment_workers():
		add_worker_row($Content/Card/WorkerSection/WorkerList)


func _on_worker_decrease_pressed() -> void:
	if not is_instance_valid(curr_building):
		return
	
	if curr_building.decrement_workers():
		pop_worker_row($Content/Card/WorkerSection/WorkerList)


func clear_info() -> void:
	for inv in inventories_container.get_children():
		inv.queue_free()
	
	for worker in $Content/Card/WorkerSection/WorkerList.get_children():
		$Content/Card/WorkerSection/WorkerList.remove_child(worker)
		worker.queue_free()


func _disconnect_from_building() -> void:
	if not is_instance_valid(curr_building):
		curr_building = null
		return
	
	# disconnect updates
	if curr_building.request_inv_update.is_connected(update_inv):
		curr_building.request_inv_update.disconnect(update_inv)
	
	if curr_building.request_worker_info_update.is_connected(update_worker_info):
		curr_building.request_worker_info_update.disconnect(update_worker_info)
	
	if curr_building.destroyed.is_connected(_on_building_destroyed):
		curr_building.destroyed.disconnect(_on_building_destroyed)
	
	curr_building = null


func open() -> void:
	# ensure only one major UI open
	if %UI/BuildingMenu and %UI/BuildingMenu.is_open:
		%UI/BuildingMenu._on_tab_pressed("Exit")

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", Vector2.ZERO, 0.65)
	is_open = true


func close() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", Vector2(-300, 0), 0.60)
	_disconnect_from_building()
	clear_info()
	is_open = false


func _on_building_destroyed() -> void:
	_disconnect_from_building()
	clear_info()
	close()
