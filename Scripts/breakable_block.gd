extends StaticBody2D

var _life : int :set = set_life, get = get_life
var maxlife : int = 1


func _ready():
	maxlife = randi_range(1,2)
	set_life(maxlife)
	var random_frame = randi() % $Sprite2D.hframes
	$Sprite2D.frame = random_frame
	

func _on_area_2d_area_entered(area):
	set_life(get_life()-1)

func set_life(new:int):
	_life = new
	if get_life() <= 0:
		Pooler.get_pop().global_position = global_position
		queue_free()
	
func get_life():
	return _life
