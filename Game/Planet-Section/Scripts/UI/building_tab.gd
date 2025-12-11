extends TextureButton

signal tab_pressed(node_name: String)

@export var icon: Texture2D


func _ready() -> void:
	$Title.text = name
	$TextureRect.texture = icon


func _on_pressed() -> void:
	tab_pressed.emit(name)
