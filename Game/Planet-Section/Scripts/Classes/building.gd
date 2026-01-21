@abstract
class_name Building
extends Area2D

signal destroyed

var inventories: Dictionary[String, Inventory] = {}
var level: int = 0


func _ready() -> void:
	# Align elements to tilemap cells
	var tilemap: TileMapLayer = get_parent()
	var cell_size := tilemap.tile_set.tile_size as Vector2
	print(cell_size/2)
	$Sprite2D.offset = -cell_size / 2
	$CollisionShape2D.position -= cell_size / 2
	$ClickArea.position -= cell_size / 2


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
	queue_free()
