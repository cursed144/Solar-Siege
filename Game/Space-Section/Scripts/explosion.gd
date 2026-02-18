extends Node2D

var _scale_tween: Tween
var _mod_tween: Tween

@onready var circle: MeshInstance2D = $Circle


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		play_boom()


func play_boom(expl_size: float = 25, speed_scale: float = 1.2) -> void:
	var sp := maxf(speed_scale, 0.001)
	
	# Start values at t = 0.0
	_set_uniform_scale(1.0)
	circle.modulate = Color(2.5, 2.5, 2.5, 1.0)
	
	# -----------------------
	# SCALE (sequential tween)
	# 0.0 -> 0.9 : 1 -> expl_size easing 0.3
	# 0.9 -> 1.5 : 25 -> 70% of expl_size linear
	# -----------------------
	_scale_tween = create_tween()
	
	_tween_float_ease(_scale_tween,
		func(s): _set_uniform_scale(s),
		1.0, expl_size,
		0.9 / sp, 0.3
	)
	
	# linear: curve = 1.0 makes ease(u,1) == u
	_tween_float_ease(_scale_tween,
		func(s): _set_uniform_scale(s),
		25.0, expl_size * 0.70,
		0.6 / sp, 1.0
	)
	
	# -----------------------
	# MODULATE (independent tween running in parallel)
	# 0.0 -> 1.1 : hold
	# 1.1 -> 1.5 : fade to (1,1,1,0)
	# -----------------------
	_mod_tween = create_tween()
	_mod_tween.tween_interval(1.1 / sp)
	
	_mod_tween.tween_method(
		func(u: float) -> void:
			circle.modulate = Color(2.5, 2.5, 2.5, 1.0).lerp(Color(1, 1, 1, 0), u),
		0.0, 1.0, 0.4 / sp
	)


func _set_uniform_scale(s: float) -> void:
	circle.scale = Vector2(s, s)


# e = ease(u, curve) to mimic AnimationPlayer key transition behavior
func _tween_float_ease(tween: Tween, setter: Callable, a: float, b: float, duration: float, curve: float) -> void:
	tween.tween_method(
		func(u: float) -> void:
			var e := ease(u, curve)
			setter.call(lerpf(a, b, e)),
		0.0, 1.0, duration
	)
