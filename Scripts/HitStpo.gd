extends Node

signal hitstop_started
signal hitstop_ended

var is_hitstop_active = false
var original_timescale = 1.0

func start_hitstop(duration: float, timescale: float = 0.05):
	if is_hitstop_active:
		return
	
	is_hitstop_active = true
	original_timescale = Engine.time_scale
	Engine.time_scale = timescale
	
	emit_signal("hitstop_started")
	
	get_tree().create_timer(duration * timescale).timeout.connect(_end_hitstop)

func _end_hitstop():
	if not is_hitstop_active:
		return
	
	is_hitstop_active = false
	Engine.time_scale = original_timescale
	
	emit_signal("hitstop_ended")
