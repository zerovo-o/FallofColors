extends Node2D
var player 
var is_active = false
@export var max_distance : float = 1000
@export var attraction_speed : float = 200
@export var pick_up_distance : float = 6

@onready var anim : AnimationPlayer = $AnimationPlayer

func _on_area_2d_area_entered(area):
		player = area.get_parent()
		is_active = true
		anim.play("coinspin")

		
func _physics_process(delta):
	if is_active and player:
		var dir = player.global_position - global_position
		var dis = dir.length()
		
		if dis > pick_up_distance and dis <= max_distance:
			dir = dir.normalized()
			var movement = dir * attraction_speed * delta 
			global_position += movement
			
		if dis <= pick_up_distance:
			Pooler.gem_collected.emit(1)
			Pooler.return_gem(self)
			is_active = false
			#print("pickup")
		elif dis > max_distance:
			Pooler.return_gem(self)
			#is_active = false
			print("lost it")
