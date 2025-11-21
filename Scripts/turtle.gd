extends EnemyMain

@onready var sprite : spriteEffect = $Sprite2D

var direction = 1

func _ready():
	speed *= randf_range(0.5,1.5)

func _physics_process(delta):
	if !is_on_floor():
		velocity.y += gravity * delta
		
	velocity.x = speed * direction
	
	move_and_slide()
	
	if is_on_wall():
		direction *= -1
		
	if is_on_floor():
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, global_position+Vector2(direction *10, 10))
		var results = space_state.intersect_ray(query)
		
		if not results:
			direction *= -1
			
	if direction > 0:
		$Sprite2D.flip_h = false
	else:
		$Sprite2D.flip_h = true


func _on_bounce_area_2d_area_entered(area):
		life -= 1
		sprite.hitting = true
		SoundManager.play_sound("roach", 1, false)
		Pooler.get_pop().global_position = global_position
		if life <= 0:
			SoundManager.play_sound( "explosion", 0.1, false)
			Pooler.get_pop().global_position = global_position
			Pooler.get_gem().global_position = global_position
			queue_free()
