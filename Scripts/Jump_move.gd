extends Node2D
class_name JumpAndMove

signal firingbullet
signal ammo_count_changing(current_ammo_count, maxammo)

@export var jump_velocity = -300.0
@export var gravity = 800.0
@export var max_fall_speed = 500.0
@export var coyote_time = 0.15  # Time in seconds
@export var jump_cut_height = 0.5  # Percentage of jump height to keep when cut
@export var ground_acceleration = 300.0
@export var air_acceleration = 750.0  # Higher than ground acceleration
@export var ground_friction = 7
@export var air_friction = 10  
@export var max_ground_speed = 100.0
@export var max_air_speed = 150.0
@export var min_jump_mod = 1.0
@export var max_jump_mod = 1.5
@export var air_jump_velocity = -150.0
@export var max_air_jump = 10
@export var char : PlayerMasterAndMover 

@export var bounce_velocity = -250.0
@export var bounce_horizonal_boost = 100.0
@export var bounce_control_lock_time = 0.2

@export var wall_slide_speed = 50.0
@export var wall_jump_velocity = Vector2(300,-400)
@export var wall_jump_time = 0.2
 

var coyote_timer = 0.0
var was_on_floor = false
var is_jumping = false
var bounce_control_lock_timer = 0.0
var wall_jump_timer = 0.0
var last_wall_jump_normal = Vector2.ZERO

var _air_jumps_left = 0

var can_move : bool = false

func get_air_jumps_left() -> int:
	return _air_jumps_left

func set_air_jumps_left(value : int) -> void:
	if value < get_air_jumps_left():
		firingbullet.emit()
	_air_jumps_left = clamp(value, 0, max_air_jump)
	ammo_count_changing.emit(get_air_jumps_left(), max_air_jump)
	
func reset_air_jumps():
	set_air_jumps_left(max_air_jump)

func _ready():
	set_air_jumps_left(max_air_jump)

func _physics_process(delta):
	if !can_move:
		return
	var input_vector = Vector2.ZERO
	
	#this is for locking the controls after a wall jump or bounce
	if bounce_control_lock_timer <= 0 and wall_jump_timer <= 0:
		input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	else: 
		bounce_control_lock_timer-= delta
		wall_jump_timer -= delta  # make flip?
		char.anim.play("bounce")
		
	if input_vector.x != 0:
		char.sprite.flip_h = input_vector.x <0
	
	var is_on_ground = char.is_on_floor()
	var is_on_wall = char.is_on_wall()
	var current_acceleration = ground_acceleration if is_on_ground else air_acceleration
	var current_friction = ground_friction if is_on_ground else air_friction
	var current_max_speed = max_ground_speed if is_on_ground else max_air_speed

#wall slide
	if is_on_wall and !is_on_ground and char.velocity.y > 0:
		char.velocity.y = min(char.velocity.y, wall_slide_speed)
		last_wall_jump_normal = char.get_wall_normal()
		char.anim.play("wall_slide")

#acceleration and friction
	if input_vector.x != 0:
		#speeding
		char.anim.play("run")
		char.velocity.x = move_toward(char.velocity.x, input_vector.x * current_max_speed, current_acceleration * delta)
	else:
		#stopping
		char.anim.play("stop")
		char.velocity.x = move_toward(char.velocity.x, 0, current_max_speed*current_friction*delta)
		
#gravity
	if !is_on_ground and !(is_on_wall and char.velocity.y >0):
		char.velocity.y += gravity*delta
		char.velocity.y = min(char.velocity.y, max_fall_speed)
		char.anim.play("fall")
		
#coyote timer
	if is_on_ground:
		coyote_timer = coyote_time
		was_on_floor = true
		is_jumping = false
		set_air_jumps_left(max_air_jump) 
	elif was_on_floor:
		coyote_timer -= delta
		if coyote_timer <= 0:
			was_on_floor = false
	
	if Input.is_action_just_pressed("jump"):
		if char.is_on_floor() or coyote_timer>0:
			var speed_ratio = abs(char.velocity.x)/current_max_speed
			var jump_mod = lerp(min_jump_mod,max_jump_mod,speed_ratio)
			char.velocity.y = jump_velocity*jump_mod
			coyote_timer = 0
			is_jumping=true
			char.anim.play("jump")
		elif is_on_wall:
			char.velocity = wall_jump_velocity*Vector2(last_wall_jump_normal.x, 1.0)
			wall_jump_timer = wall_jump_time
			is_jumping=true
			char.anim.play("bounce")
		elif get_air_jumps_left()>0:
			char.velocity.y = air_jump_velocity
			set_air_jumps_left(get_air_jumps_left() - 1)
			is_jumping = true	
			char.anim.play("shoot")
		
	if Input.is_action_just_released("jump") and is_jumping and char.velocity.y <0:
		char.velocity.y *= jump_cut_height
		char.anim.play("fall")
		
	char.move_and_slide() 

	if char.is_on_floor():
		char.velocity.y = 0
		if char.velocity.x == 0:
			char.anim.play("idle")


func bounce_off_enemy(enemy_pos: Vector2) -> void:
	char.velocity.y = bounce_velocity
	var direction = sign(char.global_position.x - enemy_pos.x)
	char.velocity.x += direction * bounce_horizonal_boost

	bounce_control_lock_timer = bounce_control_lock_time
	
	set_air_jumps_left(max_air_jump)
	is_jumping = true


func _on_bounce_area_2d_area_entered(area):
	bounce_off_enemy(area.global_position)


#
#
#
#extends Node2D
#class_name JumpAndMove
#
#signal firingbullet
#signal ammo_count_changing(current_ammo_count, maxammo)
#
#@export var jump_velocity = -300.0
#@export var gravity = 800.0
#@export var max_fall_speed = 500.0
#@export var coyote_time = 0.15  # Time in seconds
#@export var jump_cut_height = 0.5  # Percentage of jump height to keep when cut
#@export var ground_acceleration = 300.0
#@export var air_acceleration = 750.0  # Higher than ground acceleration
#@export var ground_friction = 7
#@export var air_friction = 10  
#@export var max_ground_speed = 100.0
#@export var max_air_speed = 150.0
#@export var min_jump_mod = 1.0
#@export var max_jump_mod = 1.5
#@export var air_jump_velocity = -150.0
#@export var max_air_jump = 10
#@export var char : PlayerMasterAndMover 
#
#@export var bounce_velocity = -250.0
#@export var bounce_horizonal_boost = 100.0
#@export var bounce_control_lock_time = 0.2
#
#@export var wall_slide_speed = 50.0
#@export var wall_jump_velocity = Vector2(300,-400)
#@export var wall_jump_time = 0.2
 #
#
#var coyote_timer = 0.0
#var was_on_floor = false
#var is_jumping = false
#var bounce_control_lock_timer = 0.0
#var wall_jump_timer = 0.0
#var last_wall_jump_normal = Vector2.ZERO
#
#var _air_jumps_left = 0
#
#var can_move : bool = false
#
#func get_air_jumps_left() -> int:
	#return _air_jumps_left
#
#func set_air_jumps_left(value : int) -> void:
	#if value < get_air_jumps_left():
		#firingbullet.emit()
	#_air_jumps_left = clamp(value, 0, max_air_jump)
	#ammo_count_changing.emit(get_air_jumps_left(), max_air_jump)
	#
#func reset_air_jumps():
	#set_air_jumps_left(max_air_jump)
#
#func _ready():
	#set_air_jumps_left(max_air_jump)
	#
#enum State {IDLE, RUNNING, JUMPING, AIR_JUMPING, FALLING, WALL_SLIDING, }	
#
#var current_state = State.IDLE
#var previous_state = State.IDLE	
#
#func _physics_process(delta):
	#if !can_move:
		#return
	#var input_vector = Vector2.ZERO
	#
	##this is for locking the controls after a wall jump or bounce
	#if bounce_control_lock_timer <= 0 and wall_jump_timer <= 0:
		#input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	#else: 
		#bounce_control_lock_timer-= delta
		#wall_jump_timer -= delta
		#
	#if input_vector.x != 0:
		#char.sprite.flip_h = input_vector.x <0
	#
	#var is_on_ground = char.is_on_floor()
	#var is_on_wall = char.is_on_wall()
	#
	#previous_state = current_state
	#current_state = get_new_state(is_on_ground, is_on_wall, input_vector)
	#
	#match current_state:
		#State.IDLE:
			#handle_idle(delta)
		#State.RUNNING:
			#handle_running(delta, input_vector)
		#State.JUMPING:
			#handle_jumping(delta, input_vector)
		#State.AIR_JUMPING:
			#handle_air_jumping(delta, input_vector)
		#State.FALLING:
			#handle_falling(delta, input_vector)
		#State.WALL_SLIDING:
			#handle_wall_sliding(delta, input_vector)
	#
	#char.move_and_slide()
	#
	#if char.is_on_floor():
		#char.velocity.y = 0
	#
	#
#func get_new_state(is_on_ground, is_on_wall, input_vector):
	#match current_state:
		#State.IDLE:
			#if !is_on_ground:
				#return State.FALLING
			#elif input_vector.x !=0: #maybe make sure they're on the ground
				#return State.RUNNING
			#elif Input.is_action_just_pressed("jump"):
				#return State.JUMPING
		#State.RUNNING:
			#if !is_on_ground:
				#return State.FALLING
			#elif input_vector.x == 0: #maybe make sure absvelocity <0.5
				#return State.IDLE
			#elif Input.is_action_just_pressed("jump"):
				#return State.JUMPING
		#State.JUMPING:
			#if char.velocity.y >= 0:
				#return State.FALLING
			#elif Input.is_action_just_pressed("jump") and get_air_jumps_left() > 0:
				#return State.AIR_JUMPING
		#State.AIR_JUMPING:
			#if char.velocity.y >= 0:
				#return State.FALLING
		#State.FALLING:
			#if is_on_ground:
				#return State.IDLE if input_vector.x == 0 else State.RUNNING #cool
			#elif is_on_wall or input_vector.x != 0:
				#return State.WALL_SLIDING
			#elif Input.is_action_just_pressed("jump") and get_air_jumps_left() > 0:
				#return State.AIR_JUMPING
		#State.WALL_SLIDING:
			#if is_on_ground:
				#return State.IDLE
			#elif !is_on_wall or input_vector.x == 0:
				#return State.FALLING
			#elif Input.is_action_just_pressed("jump"):
				#return State.JUMPING
	#return current_state
#
#func handle_idle(delta):
	#char.velocity.x = move_toward(char.velocity.x, 0, ground_friction * delta)
#
#func handle_running(delta, input_vector):
	#char.velocity.x = move_toward(char.velocity.x, input_vector.x * max_ground_speed, ground_acceleration * delta)
#
#func handle_jumping(delta, input_vector):
	#if previous_state != State.JUMPING:
		#char.velocity.y = jump_velocity
	#
	#char.velocity.x = move_toward(char.velocity.x, input_vector.x * max_air_speed, air_acceleration * delta)
	#
	## Jump cutoff
	#if Input.is_action_just_released("jump") and char.velocity.y < 0:
		#char.velocity.y *= jump_cut_height
#
#
#func handle_air_jumping(delta, input_vector):
	#if previous_state != State.AIR_JUMPING:
		#char.velocity.y = air_jump_velocity
		#set_air_jumps_left(get_air_jumps_left() - 1) 
	#
	#char.velocity.x = move_toward(char.velocity.x, input_vector.x * max_air_speed, air_acceleration * delta)
	#
	## Jump cutoff
	#if Input.is_action_just_released("jump") and char.velocity.y < 0:
		#char.velocity.y *= jump_cut_height
		#
#func handle_falling(delta, input_vector):
	#char.velocity.y += gravity * delta
	#char.velocity.y = min(char.velocity.y, max_fall_speed)
	#char.velocity.x = move_toward(char.velocity.x, input_vector.x * max_air_speed, air_acceleration * delta)
#
#
#func handle_wall_sliding(delta, input_vector):
	#
	#if is_on_wall and !is_on_ground and char.velocity.y > 0:
		#char.velocity.y = min(char.velocity.y, wall_slide_speed)
		#last_wall_jump_normal = char.get_wall_normal()
	#
	#
	#char.velocity.y = min(char.velocity.y, wall_slide_speed)
	#last_wall_jump_normal = char.get_wall_normal()
	#
	#if Input.is_action_just_pressed("jump"):
		#char.velocity = wall_jump_velocity * Vector2(last_wall_jump_normal.x, 1.0)
		#wall_jump_timer = wall_jump_time
		#current_state = State.JUMPING
		##air_jumps_left = max_air_jumps  
#
#func bounce_off_enemy(enemy_pos: Vector2) -> void:
	#char.velocity.y = bounce_velocity
	#var direction = sign(char.global_position.x - enemy_pos.x)
	#char.velocity.x += direction * bounce_horizonal_boost
#
	#bounce_control_lock_timer = bounce_control_lock_time
	#
	#set_air_jumps_left(max_air_jump)
	#is_jumping = true
#
#
#func _on_bounce_area_2d_area_entered(area):
	#bounce_off_enemy(area.global_position)
