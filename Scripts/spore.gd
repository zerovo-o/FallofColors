extends CharacterBody2D
@export var life : int = 1
@export var speed: float = 100.0
var target: PlayerMasterAndMover

@export var existing_time : float = 6
var counter : float = 0.0

func _physics_process(delta):
	counter += delta
	if counter > existing_time:
		Pooler.get_pop().global_position = global_position
		#Pooler.get_gem().global_position = global_position
		queue_free()
	if target:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		var direction = Vector2.UP
		velocity = direction * speed*2
		
	move_and_slide()

func set_target(new_target: PlayerMasterAndMover):
	target = new_target

#func _on_body_entered(body):
	#if body == target:
		## Deal damage to player
		#queue_free()
	#elif body.is_in_group("obstacles"):
		#queue_free()


func _on_bounce_area_2d_area_entered(area):
			Pooler.get_pop().global_position = global_position
			#Pooler.get_gem().global_position = global_position
			queue_free()

func _on_hurt_area_2d_area_entered(area):
			Pooler.get_pop().global_position = global_position
			#Pooler.get_gem().global_position = global_position
			queue_free()
