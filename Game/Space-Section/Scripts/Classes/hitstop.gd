extends CanvasLayer

class HitStopData:
	var duration: float
	var has_flash: bool

signal one_hitstop_finished
signal all_histstops_finished

var hitstop_timer: Timer = null
var hitstop_flash: ColorRect = null
var hitstop_player: AudioStreamPlayer = null
var is_hitstop_happening: bool = false
var hitstops: Array[HitStopData] = []


func _ready() -> void:
	layer = 3
	
	hitstop_timer = Timer.new()
	hitstop_timer.ignore_time_scale = true
	add_child(hitstop_timer)
	
	hitstop_flash = ColorRect.new()
	hitstop_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	hitstop_flash.color = Color(1, 1, 1, 0.1)
	add_child(hitstop_flash)
	hitstop_flash.hide()
	
	hitstop_player = AudioStreamPlayer.new()
	hitstop_player.stream = load("res://Space-Section/Sounds/hitstop.wav")
	hitstop_player.max_polyphony = 3
	add_child(hitstop_player)


func queue_hitstop(duration: float = 0.4, has_flash: bool = true) -> void:
	var data = HitStopData.new()
	data.duration = duration
	data.has_flash = has_flash
	hitstops.append(data)
	
	if not is_hitstop_happening:
		_trigger_next_hitstop()


func _trigger_next_hitstop() -> void:
	is_hitstop_happening = true
	var hitstop: HitStopData = hitstops.pop_front()
	
	hitstop_timer.start(hitstop.duration)
	hitstop_player.play()
	if hitstop.has_flash:
		hitstop_flash.show()
	
	Engine.time_scale = 0
	await hitstop_timer.timeout
	Engine.time_scale = 1
	
	one_hitstop_finished.emit()
	await get_tree().process_frame
	hitstop_flash.hide()
	
	if not hitstops.is_empty():
		_trigger_next_hitstop()
	else:
		is_hitstop_happening = false
		all_histstops_finished.emit()
