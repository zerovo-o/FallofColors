extends CanvasLayer
class_name boss_life

@onready var prog_bar : ProgressBar = $ProgressBar
@onready var life_label : Label = $LifeLabel

@onready var left_hand = $"../Body"
@onready var right_hand =$"../RightHand"
@onready var body = $"../LeftHand"

const deathparticle : PackedScene = preload("res://Scenes/deathparticle.tscn")
var _life_current = 100
var life_max = 100

func _ready():
	set_life_current(life_max)
	prog_bar.hide()
	life_label.hide()
	Pooler.start_boss.connect(startem)
	
	
func startem():
	set_life_current(life_max)
	prog_bar.show()
	life_label.show()

func get_current_life() -> int:
	return _life_current

func set_life_current(value : int) -> void:
	if value < get_current_life():
		pass
	if value <= 0:
		var temp = deathparticle.instantiate()
		get_parent().get_parent().add_child(temp)
		temp.global_position = get_parent().global_position
		temp.emitting = true
		
		Pooler.end_boss.emit()
		get_parent().queue_free()
	_life_current = clamp(value, 0, life_max)
	prog_bar.value = get_current_life()
	prog_bar.max_value = life_max
