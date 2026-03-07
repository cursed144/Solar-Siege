@tool
extends Node2D

const BOUNDING_WALL_OFFSET = 10
@export var space_size := Vector2(3000, 3000)


func _ready() -> void:
	init_bounding_walls()
	init_player()


func init_bounding_walls() -> void:
	$PlayingField.position = space_size/2
	$PlayingField.scale = space_size
	
	$BoundingWalls/TopWall.position = Vector2(space_size.x / 2, -BOUNDING_WALL_OFFSET)
	$BoundingWalls/LeftWall.position = Vector2(-BOUNDING_WALL_OFFSET, space_size.y / 2)
	$BoundingWalls/RightWall.position = Vector2(space_size.x + BOUNDING_WALL_OFFSET, space_size.y / 2)
	$BoundingWalls/BottomWall.position = Vector2(space_size.x / 2, space_size.y + BOUNDING_WALL_OFFSET)
	$BoundingWalls/TopWall.scale = Vector2(space_size.x / 20, 1)
	$BoundingWalls/LeftWall.scale = Vector2(1, space_size.y / 20)
	$BoundingWalls/RightWall.scale = Vector2(1, space_size.y / 20)
	$BoundingWalls/BottomWall.scale = Vector2(space_size.x / 20, 1)


func init_player() -> void:
	$Player.position = Vector2(space_size.x / 2, space_size.y / 2)
	$Player/Camera2D.limit_left = 0
	$Player/Camera2D.limit_top = 0
	$Player/Camera2D.limit_right = space_size.x
	$Player/Camera2D.limit_bottom = space_size.y
