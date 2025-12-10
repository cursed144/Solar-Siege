class_name Building
extends Area2D

@onready var build_info: Control = get_node("../../UI/BuildingInfo")

func _ready() -> void:
	print(get_node("..").name)


func _on_click_area_pressed() -> void:
	build_info.building_clicked(self)
