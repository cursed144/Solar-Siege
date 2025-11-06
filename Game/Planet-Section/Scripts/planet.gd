extends Node2D

@export var planet_size := Vector2(5000, 5000)


func _ready() -> void:
	$PlayingField.position = planet_size/2
	$PlayingField.scale = planet_size
	$PlayerCam.position = $PlayingField.position
