extends Control

@onready var rocket = get_node("../../")


func use_fuel(amount: float) -> void:
	$Fuel.value -= amount
	
	if $Fuel.value <= 0: # no fuel left
		rocket.has_fuel = false

func add_fuel(amount: float) -> void:
	$Fuel.value += amount
	rocket.has_fuel = true
