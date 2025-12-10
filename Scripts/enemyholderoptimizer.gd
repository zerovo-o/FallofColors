extends Node2D
@onready var master : Master =  $".."

func _physics_process(delta):
	for i : EnemyMain in get_children():
		if i.global_position.distance_squared_to(master.player.global_position) < 7000:
			i.set_process(true)
		else:
			i.set_process(false)
		
