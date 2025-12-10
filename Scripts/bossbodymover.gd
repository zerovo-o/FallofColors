extends CharacterBody2D

enum State {WALK, IDLE,}
var current_state : State = State.IDLE
var time_in_state : float = 0
var direction : Vector2 = Vector2.ZERO
@export var speed : float = 40
func _physics_process(delta):
	time_in_state += delta
	if !is_on_floor():
		velocity = Vector2(velocity.x, 1 * 30)
	match current_state:
		State.IDLE:
			idle_state(delta)
		State.WALK:
			walk_state(delta)
	move_and_slide()
	
func change_state(new_state: State):
	current_state = new_state
	time_in_state = 0.0
	var value = 1 if randi() % 2 == 0 else -1
	direction = Vector2(value, 0)	

func idle_state(delta):
	velocity.move_toward(Vector2.ZERO, 0.1)
	if time_in_state > 3:
		change_state(State.WALK)
	
func walk_state(delta):
	velocity = direction*speed
	if is_on_wall():
		direction.x *= -1
	if time_in_state> 1:
		change_state(State.IDLE)
