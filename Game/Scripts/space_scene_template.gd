extends Node2D

@export_range(100, 9999, 0.1) var arena_size := 2000.0
@export_range(1, 999, 0.1) var wall_size := 15.0


func _ready() -> void:
	ready_arena()


func ready_arena() -> void:
	$Walls.global_position = Vector2(arena_size/2, arena_size/2)
	$Walls/Right.global_position = Vector2(arena_size, arena_size/2)
	$Walls/Down.global_position = Vector2(arena_size/2, arena_size)
	$Walls/Left.global_position = Vector2(-10, arena_size/2)
	$Walls/Up.global_position = Vector2(arena_size/2, -10)
	
	for wall in $Walls.get_children():
		wall.scale.x = wall_size
		wall.scale.y = arena_size
	
	$Rocket.global_position = Vector2(arena_size/2, arena_size/2)
	$Rocket/Camera2D.limit_right = $Walls/Right.global_position.x - wall_size/2
	$Rocket/Camera2D.limit_bottom = $Walls/Down.global_position.y - wall_size/2
	$Rocket/Camera2D.limit_left = $Walls/Left.global_position.x + wall_size/2
	$Rocket/Camera2D.limit_top = $Walls/Up.global_position.y + wall_size/2
