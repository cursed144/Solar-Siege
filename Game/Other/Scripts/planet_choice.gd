extends Node2D

const PLANET_MAX_OFFSET = 100


func _ready() -> void:
	for planet in $Planets.get_children():
		planet.global_position.y += randf_range(-PLANET_MAX_OFFSET, PLANET_MAX_OFFSET)
