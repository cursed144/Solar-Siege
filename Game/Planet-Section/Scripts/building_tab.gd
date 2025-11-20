extends TextureButton

@export var icon: Texture2D
signal tab_pressed(node_name: String)


func _ready() -> void:
	$Title.text = name
	$TextureRect.texture = icon


func _on_pressed() -> void:
	tab_pressed.emit(name)
