extends Control


func _on_health_value_changed(_value: float) -> void:
	update_hp_bar()


func update_hp_bar():
	var max_value = $Health.max_value
	var value = $Health.value
	var ratio = value / max_value
	var bar_color: Color
	
	if value > max_value:
		# 1.0 = 100% hp, 1.5 = 150% hp
		var shield_ratio = clamp((ratio - 1.0) / 0.5, 0.0, 1.0)
		bar_color = Color(0.0, 0.65, 0.0, 1.0).lerp(Color(0.4, 1.0, 1.0), shield_ratio)
	else:
		if ratio > 0.5:
			bar_color = Color(0.75, 0.75, 0.0, 1.0).lerp(Color(0, 1, 0), (ratio - 0.5) * 2.0)
		else:
			bar_color = Color(1, 0, 0).lerp(Color(1, 1, 0), ratio * 2.0)
	
	$Image.self_modulate = bar_color
