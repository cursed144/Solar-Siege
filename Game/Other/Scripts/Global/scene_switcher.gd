extends Node

enum Scene {
	MENU,
	PLANET_CHOICE,
	PLANET,
	SPACE
}

enum Planet {
	MERCURY,
	VENUS,
	EARTH,
	MARS,
	JUPITER,
	SATURN,
	URANUS,
	NEPTUNE,
	THENONPLANETNAMEDPLUTO
}

const main_menu := "res://Other/Scenes/main_menu.tscn"
const planet_choice := "res://Other/Scenes/planet_choice.tscn"
const planet := "res://Planet-Section/Scenes/planet_template.tscn"
const space := "res://Space-Section/Scenes/space_template.tscn"

var _current_scene: Scene
var _current_planet: Planet
var anim_tween: Tween


func _ready() -> void:
	_current_scene = Scene.MENU
	_current_planet = Planet.EARTH


func switch_to_planet_choice() -> void:
	match _current_scene:
		Scene.MENU:
			# Get everything needed from old scene
			var old_scene = get_tree().current_scene
			var anim_target: Control = old_scene.get_node("UI/Control")
			var background: Node2D = old_scene.get_node("Background")
			assert(is_instance_valid(anim_target))
			assert(is_instance_valid(background))
			
			# Start loading new + animate old one
			ResourceLoader.load_threaded_request(planet_choice)
			anim_tween = create_tween()
			anim_tween.set_trans(Tween.TRANS_CUBIC)
			
			anim_tween.set_ease(Tween.EASE_OUT)
			anim_tween.tween_property(anim_target, "global_position", anim_target.position + Vector2(0, 100), 0.75)
			anim_tween.set_ease(Tween.EASE_IN)
			anim_tween.tween_property(anim_target, "global_position", anim_target.position - Vector2(0, 1500), 1)
			await anim_tween.finished
			
			# Get new scene
			var loaded_scene: PackedScene = ResourceLoader.load_threaded_get(planet_choice)
			assert(is_instance_valid(loaded_scene))
			
			# Create instance
			var new_scene := loaded_scene.instantiate()
			await get_tree().process_frame
			assert(is_instance_valid(new_scene))
			
			# Move from old to new + animate and finish
			var camera: Camera2D = new_scene.get_node("Camera2D")
			assert(is_instance_valid(camera))
			camera.global_position = old_scene.get_node("Camera2D").global_position
			_move_node(background, new_scene)
			
			_finalize_switching(new_scene)
			
			anim_tween = create_tween()
			anim_tween.set_ease(Tween.EASE_IN_OUT)
			anim_tween.set_trans(Tween.TRANS_CUBIC)
			anim_tween.tween_property(camera, "global_position", Vector2(576, 324), 2.5)
		Scene.PLANET:
			# Load scene
			# Wait for the rocket to have launched
			# Instanciate and set things right
			# Delete old scene
			# Play animation
			pass
		Scene.SPACE:
			# Load scene
			# Play anim
			# Wait for anim to finish
			# Instanciate
			# Play anim
			pass
		_:
			push_error("Cannot switch to that scene from current scene! Aborting")
			return
	
	_current_scene = Scene.PLANET_CHOICE


func _move_node(node: Node, dest: Node) -> void:
	node.get_parent().remove_child(node)
	dest.add_child(node)


func _finalize_switching(new_scene: Node) -> void:
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
