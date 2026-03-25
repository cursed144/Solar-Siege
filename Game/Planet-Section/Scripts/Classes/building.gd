@abstract
class_name Building
extends Area2D

signal destroyed

@export var can_be_destroyed := true
@export var level_reqs: Array[UpgradeRequirement]

var inventories: Dictionary[String, Inventory] = {}
var internal_id: int = -1
var level: int = 0


@abstract
func _on_click_area_pressed() -> void


func begin_upgrade(time: float) -> void:
	$ClickArea.disabled = true
	$ClickArea.mouse_default_cursor_shape = Control.CURSOR_ARROW
	$AnimationPlayer.play("upgrade")
	$UpgradeTimer.start(time)

func _on_upgrade_finished() -> void:
	level += 1
	$ClickArea.disabled = false
	$ClickArea.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	$AnimationPlayer.play("RESET")


# Remove the building from the planet
func destroy() -> void:
	var planet = get_tree().current_scene
	planet.remove_building(self)
	destroyed.emit()
