extends Node2D

const PLANET_MAX_OFFSET = 120
const PLANET_Y_ORIGIN = 324

var anim_tween: Tween

@onready var camera: Camera2D = get_node("../Camera2D")
@onready var camera_origin = camera.global_position


func _ready() -> void:
	for planet: Area2D in get_children():
		planet.global_position.y += randf_range(-PLANET_MAX_OFFSET, PLANET_MAX_OFFSET)


func _on_planet_clicked(planet: Area2D) -> void:
	choose_planet(planet)


func choose_planet(planet: Area2D) -> void:
	var tex: Texture2D = planet.get_node("Sprite2D").texture
	var size := tex.get_size().x
	
	anim_tween = create_tween()
	anim_tween.set_trans(Tween.TRANS_CUBIC)
	anim_tween.set_ease(Tween.EASE_OUT)
	
	anim_tween.tween_property(camera, "global_position", Vector2(planet.global_position.x, PLANET_Y_ORIGIN), 1)
	anim_tween.parallel().tween_property(camera, "zoom", Vector2(10, 10) / (size/32), 1.5)
	for i: Area2D in get_children():
		anim_tween.parallel().tween_property(i, "global_position", Vector2(i.global_position.x, PLANET_Y_ORIGIN), 1)
