extends Node2D
class_name Shockwave

@export var color: Color = Color.WHITE
@export var duration: float = 0.5
@export var start_radius: float = 8.0
@export var end_radius: float = 120.0
@export var ring_width: float = 6.0
@export var point_count: int = 128
@export var fade_out: bool = true
@export var autoplay: bool = false

var tween: Tween

var radius: float = 0.0:
	set(value):
		radius = value
		queue_redraw()

var alpha_mult: float = 1.0:
	set(value):
		alpha_mult = value
		queue_redraw()


static func new_shockwave(_start_radius: float = 8.0,\
				   _end_radius: float = 120.0,\
				   _ring_width: float = 6.0,\
				   _duration: float = 0.5,\
				   _color: Color = Color.WHITE,\
				   _fade_out: bool = true,\
				   _autoplay: bool = true) -> Shockwave:
	
	var new_shock := Shockwave.new()
	await new_shock.ready
	new_shock.start_radius = _start_radius
	new_shock.end_radius = _end_radius
	new_shock.ring_width = _ring_width
	new_shock.duration = _duration
	new_shock.color = _color
	new_shock.fade_out = _fade_out
	new_shock.autoplay = _autoplay
	new_shock._ready()
	
	return new_shock


func _ready() -> void:
	radius = start_radius
	if autoplay:
		play()


func _draw() -> void:
	var c := color
	c.a *= alpha_mult
	
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		point_count,
		c,
		ring_width,
		true
	)


func play() -> void:
	if tween:
		tween.kill()
	
	radius = start_radius
	alpha_mult = 1.0
	show()
	
	tween = create_tween()
	tween.set_parallel()
	
	tween.tween_property(self, "radius", end_radius, duration)
	
	if fade_out:
		tween.tween_property(self, "alpha_mult", 0.0, duration)
	
	tween.chain().tween_callback(queue_free)


func stop() -> void:
	if tween:
		tween.kill()
	hide()
