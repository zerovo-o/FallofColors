extends Label
class_name ComboController

var _current_combo = 0
var max_combo = 100

func _ready():
	set_combo_count(0)

func get_combo_count() -> int:
	return _current_combo

func set_combo_count(value : int) -> void:
	_current_combo = clamp(value, 0, max_combo)
	if get_combo_count() > 0:
		text = str(get_combo_count()) 
	else: 
		text = ""

func add_one_combo():
	set_combo_count(get_combo_count()+1)
	
				#return State.IDLE if input_vector.x == 0 else State.RUNNING
	
func reset_combo():
	get_parent().get_parent().calculate_bonus.emit(get_combo_count())
	set_combo_count(0)
