extends Control

const inv_section := preload("res://Planet-Section/Scenes/UI/inv_section.tscn")
const worker_row := preload("res://Planet-Section/Scenes/UI/worker_row.tscn")
const inv_slot := preload("res://Planet-Section/Scenes/UI/inv_slot.tscn")

var is_open := false
var curr_building: Building = null
var is_mouse_in_area := false

@onready var destroy_button: TextureButton = %UI/DestroyBuilding/Confirm
@onready var item_deleter = %UI/DeleteItemConf
@onready var recipe_menu = $RecipeMenu

@onready var worker_row_container: VBoxContainer = $Content/Card/WorkerSection/WorkerList
@onready var inventories_container: Node = $Content/Card/Inventories
@onready var name_label: Label = $Content/Card/BuildingName


func _process(_delta: float) -> void:
	if is_instance_valid(curr_building):
		for i in range(curr_building.worker_limit):
			var row = worker_row_container.get_child(i)
			var progress: TextureProgressBar = row.get_node("Progress")
			var timer: Timer = curr_building.get_node("WorkerRows/" + row.name + "/Timer")
			
			if timer.time_left >= 0.05:
				progress.max_value = timer.wait_time
				progress.value = timer.wait_time - timer.time_left
			else:
					progress.value = 0


func _input(event: InputEvent) -> void:
	if (event.is_action_released("scroll_down") or event.is_action_released("scroll_up")) and is_mouse_in_area:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		
		if event.is_action_released("scroll_up"):
			tween.tween_property($Content, "scroll_vertical", $Content.scroll_vertical - 175, 0.5)
		elif event.is_action_released("scroll_down"):
			tween.tween_property($Content, "scroll_vertical", $Content.scroll_vertical + 175, 0.5)



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
	connect_to_building(building)


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
		
		var padding_size = ((slot_target.get_child_count()+4) / 4) * 68
		slot_target.custom_minimum_size.y = padding_size


func _fill_worker_info(building: Building) -> void:
	if not is_instance_valid(building):
		return
	if building.max_workers < 1:
		$Content/Card/WorkerSection.hide()
	
	for worker in range(building.worker_limit):
		add_worker_row(worker_row_container)
	
	update_worker_rows(building)


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


func update_worker_rows(building: Building = curr_building) -> void:
	var worker_nums = $Content/Card/WorkerSection/WorkerInfo/HBoxContainer
	var format_string_max = "Limit Workers: %d/%d"
	var format_string_current = "Current workers: %d"
	worker_nums.get_node("Max").text = format_string_max % [building.worker_limit, building.max_workers]
	worker_nums.get_node("Current").text = format_string_current % building.assigned_workers.size()
	
	await get_tree().process_frame
	for i in range(building.worker_limit):
		var work_controller = building.get_node("WorkerRows/" + str(i+1))
		var row = worker_row_container.get_child(i)
		if not is_instance_valid(row):
			continue
		
		if work_controller.is_work_required():
			row.set_display_item(work_controller.assigned_recipe, work_controller.amount_to_produce)
		else:
			row.set_display_item(null, 0)
	
	worker_row_container.custom_minimum_size.y = worker_row_container.get_child_count() * 85


func add_worker_row(dest: Node) -> void:
	var new_row = worker_row.instantiate()
	new_row.init(curr_building)
	new_row.name = str(curr_building.worker_limit)
	new_row.slot_clicked.connect(recipe_menu.on_worker_slot_clicked)
	dest.add_child(new_row)


func pop_worker_row(target: Node) -> void:
	target.get_child(-1).slot_clicked.disconnect(recipe_menu.on_worker_slot_clicked)
	target.get_child(-1).queue_free()


func _on_worker_increase_pressed() -> void:
	if not is_instance_valid(curr_building):
		return
	
	if curr_building.increment_worker_rows():
		add_worker_row(worker_row_container)


func _on_worker_decrease_pressed() -> void:
	if not is_instance_valid(curr_building):
		return
	
	if curr_building.decrement_worker_rows():
		pop_worker_row(worker_row_container)


func clear_info() -> void:
	for inv in inventories_container.get_children():
		inv.queue_free()
	
	for worker in worker_row_container.get_children():
		worker_row_container.remove_child(worker)
		worker.queue_free()


func connect_to_building(building: Building = curr_building) -> void:
	if not building.request_inv_update.is_connected(update_inv):
		building.request_inv_update.connect(update_inv)
	
	if not building.request_worker_rows_update.is_connected(update_worker_rows):
		building.request_worker_rows_update.connect(update_worker_rows)
	
	if not building.destroyed.is_connected(_on_building_destroyed):
		building.destroyed.connect(_on_building_destroyed)
	
	if not destroy_button.pressed.is_connected(curr_building.destroy):
		destroy_button.pressed.connect(curr_building.destroy)


func _disconnect_from_building() -> void:
	if not is_instance_valid(curr_building):
		curr_building = null
		return
	
	# disconnect updates
	if curr_building.request_inv_update.is_connected(update_inv):
		curr_building.request_inv_update.disconnect(update_inv)
	
	if curr_building.request_worker_rows_update.is_connected(update_worker_rows):
		curr_building.request_worker_rows_update.disconnect(update_worker_rows)
	
	if curr_building.destroyed.is_connected(_on_building_destroyed):
		curr_building.destroyed.disconnect(_on_building_destroyed)
	
	if destroy_button.pressed.is_connected(curr_building.destroy):
		destroy_button.pressed.disconnect(curr_building.destroy)
	
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
	is_open = false


func _on_building_destroyed() -> void:
	_disconnect_from_building()
	clear_info()
	close()


func _on_scrolling_area_mouse_entered() -> void:
	is_mouse_in_area = true

func _on_scrolling_area_mouse_exited() -> void:
	is_mouse_in_area = false
