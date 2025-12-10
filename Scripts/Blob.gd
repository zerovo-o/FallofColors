extends EnemyMain

enum State {IDLE, MOVE, ATTACK}

@export var idle_time: float = 2.0
@export var move_time: float = 3.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.5

var current_state: State = State.IDLE
var time_in_state: float = 0.0
var move_direction: Vector2 = Vector2.RIGHT
var gravity_direction: Vector2 = Vector2.DOWN
var last_attack_time: float = 0.0

@onready var rays : Node2D =  $Rays
#@onready var player = get_node("/root/Main/Player")  # Adjust this path to your scene structure

func _ready():
	randomize()

func _physics_process(delta):
	time_in_state += delta
	
	match current_state:
		State.IDLE:
			idle_state(delta)
		State.MOVE:
			move_state(delta)
		State.ATTACK:
			attack_state(delta)
	
	apply_gravity()
	move_and_slide()
	adjust_to_surface()

func idle_state(delta):
	velocity = Vector2.ZERO
	if time_in_state >= idle_time:
		change_state(State.MOVE)

func move_state(delta):
	for i : RayCast2D in rays.get_children():
		if i.is_colliding():
			#print(i.get_collision_point())
			move_direction = i.get_collision_point()		
			
	velocity = move_direction * speed 
	if time_in_state >= move_time:
		change_state(State.IDLE)
	
	#if player and position.distance_to(player.position) <= attack_range:
	 #   change_state(State.ATTACK)

func attack_state(delta):
	velocity = Vector2.ZERO
	if time_in_state >= attack_cooldown:
		perform_attack()
		change_state(State.MOVE)

func perform_attack():
	# Implement attack logic here
	print("Slime Mold attacks!")
	last_attack_time = time_in_state



func get_closest_ray(rays) -> RayCast2D:
	var shortest_distance = INF  # Initialize with infinity
	var closest_raycast = null

	for raycast in rays:  # Assuming 'raycasts' is an array or group of RayCast nodes
		if raycast.is_colliding():
			var collision_point = raycast.get_collision_point()
			var distance = raycast.global_position.distance_to(collision_point)
		
			if distance < shortest_distance:
				shortest_distance = distance
				closest_raycast = raycast

# After the loop, 'closest_raycast' will be the one with the shortest collision distance
	if closest_raycast:
		return closest_raycast
		print("Closest raycast collision distance: ", shortest_distance)
	# Do something with closest_raycast
	else:
		return null
		print("No raycasts are colliding")

func apply_gravity():
	var group = rays.get_children()
	var ray: RayCast2D = get_closest_ray(group) 
	if ray:
		gravity_direction = ray.get_collision_normal()
	else: 
		gravity_direction = Vector2.DOWN
	velocity = gravity_direction * gravity
			#velocity.y += gravity + move_direction
		
	#raycast.target_position = Vector2(1,0)
	#if not is_on_floor() and not is_on_ceiling() and not is_on_wall():
	#	velocity.y += gravity  # Increased gravity for stickiness

func adjust_to_surface():
	pass
	#if raycast.is_colliding():
	#	pass
		#var collision_normal = raycast.get_collision_normal()
		#gravity_direction = -collision_normal
		#rotation = Vector2.RIGHT.angle_to(collision_normal) - PI/2

func change_state(new_state: State):
	velocity = Vector2.ZERO
	current_state = new_state
	time_in_state = 0.0
	
	if new_state == State.MOVE:
		move_direction = Vector2(randi_range(-1, 1), 0)
		#move_direction = move_direction.rotated(rotation)

func _on_player_detected():
	if current_state == State.IDLE:
		change_state(State.MOVE)
