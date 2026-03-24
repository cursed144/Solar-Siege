extends Node2D

const PLANET_MAX_OFFSET = 120
const PLANET_Y_ORIGIN = 324
const CAMERA_ORIGIN := Vector2(576, 324)

var anim_tween: Tween
var zoomed := false

@onready var camera: Camera2D = get_node("../SolarCam")


func _ready() -> void:
	for planet: Area2D in get_children():
		planet.global_position.y += randf_range(-PLANET_MAX_OFFSET, PLANET_MAX_OFFSET)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("right_click") and zoomed:
		stop_selection()


func _on_planet_clicked(planet: Area2D) -> void:
	choose_planet(planet)


func choose_planet(planet: Area2D) -> void:
	var tex: Texture2D = planet.get_node("Sprite2D").texture
	var size := tex.get_size().x
	zoomed = true
	
	if anim_tween != null:
		anim_tween.kill()
	anim_tween = create_tween()
	anim_tween.set_trans(Tween.TRANS_SINE)
	anim_tween.set_ease(Tween.EASE_IN_OUT)
	
	anim_tween.tween_property(camera, "global_position", Vector2(planet.global_position.x, PLANET_Y_ORIGIN), 1)
	anim_tween.parallel().tween_property(camera, "zoom", Vector2(10, 10) / (size/32), 1.5)
	for i: Area2D in get_children():
		anim_tween.parallel().tween_property(i, "global_position", Vector2(i.global_position.x, PLANET_Y_ORIGIN), 0.5)


func stop_selection() -> void:
	anim_tween.kill()
	anim_tween = create_tween()
	anim_tween.set_trans(Tween.TRANS_SINE)
	anim_tween.set_ease(Tween.EASE_OUT)
	anim_tween.tween_property(camera, "global_position", CAMERA_ORIGIN, 1.5)
	anim_tween.parallel().tween_property(camera, "zoom", Vector2(1, 1), 1)
	for i: Area2D in get_children():
		anim_tween.parallel().tween_property(i, "global_position", Vector2(i.global_position.x, PLANET_Y_ORIGIN + randf_range(-PLANET_MAX_OFFSET, PLANET_MAX_OFFSET)), 1.5)
	zoomed = false
