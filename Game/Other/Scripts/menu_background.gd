extends Node2D

@export var width: float = 1500
@export var height: float = 1500

func _ready() -> void:
	width = ceil(width / 64)
	height = ceil(height / 64)
	
	generate($StarsClose/TileMapLayer)
	generate($StarsMid/TileMapLayer)
	generate($StarsFar/TileMapLayer)


func generate(tilemap: TileMapLayer) -> void:
	tilemap.clear()
	
	for y in range(height+2):
		for x in range(width+2):
			var atlas_x := 0
			if randi_range(1, 3) == 1:
				atlas_x = randi_range(0, 10)
				if atlas_x == 10:
					atlas_x += randi_range(1, 5) - 2
			else:
				continue
			
			tilemap.set_cell(Vector2i(x-1, y-1), atlas_x, Vector2i.ZERO, 0)
