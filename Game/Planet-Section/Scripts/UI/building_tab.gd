extends TextureButton

signal tab_pressed(node_name: String)

@export var icon: Texture2D


func _ready() -> void:
	$Title.text = name
	$TextureRect.texture = icon


func _on_pressed() -> void:
	if name != "Exit":
		var tabs = get_parent()
		for tab in tabs.get_children():
			tab.button_pressed = false
		button_pressed = true
	else:
		button_pressed = false
	
	tab_pressed.emit(name)
