extends Node2D

var width := 0
var height := 0

func _ready() -> void:
	var space = get_parent()
	width = ceil(space.space_size.x / 64)
	height = ceil(space.space_size.y / 64)
	
	generate($StarsClose/TileMapLayer)
	generate($StarsMid/TileMapLayer)
	generate($StarsFar/TileMapLayer)


func generate(tilemap: TileMapLayer) -> void:
	tilemap.clear()
	
	for y in range(height+2):
		for x in range(width+2):
			var atlas_x := 0
			if randi_range(1, 3) == 1:
				atlas_x = randi_range(0, 9)
			else:
				continue
			
			tilemap.set_cell(Vector2i(x-1, y-1), atlas_x, Vector2i.ZERO, 0)
