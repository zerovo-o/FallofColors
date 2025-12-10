extends EnemyMain

enum State {IDLE, JUMP, JUMP_PREP, RELEASE_GAS}

@onready var anim : AnimationPlayer = $AnimationPlayer

@export var jump_force: float = 200.0
@export var idle_time: float = 2.0
@export var jump_interval: float = 3.0
@export var gas_release_time: float = 1.0
@export var jump_prep_time : float = 0.5

var current_state: State = State.IDLE
var time_in_state: float = 0.0
var direction: Vector2 = Vector2.ZERO

@onready var hurt_area : Area2D = $HurtArea2D
@onready var gas_particles = $GasParticles  # Assume you have a Particles2D node for gas
@onready var sprite : spriteEffect = $Sprite2D

const  spore_scene: PackedScene = preload("res://Scenes/Enemy/spore.tscn")
@onready var spore_spawn_point = $SporeSpawnPoint

var player: CharacterBody2D

func _ready():
	player = get_node("/root/Master/Player") 

func _physics_process(delta):
	time_in_state += delta
	if direction.x < 0:
		$Sprite2D.flip_h = false
	else:
		$Sprite2D.flip_h = true
	if !is_on_floor():
		velocity.y += 9.8 * delta * 100
	
	match current_state:
		State.IDLE:
			idle_state(delta)
		State.JUMP:
			jump_state(delta)
		State.RELEASE_GAS:
			release_gas_state(delta)
		State.JUMP_PREP:
			jump_prep_state(delta)
	move_and_slide()
	
func jump_prep_state(delta):
	anim.play("prep")
	if time_in_state > jump_prep_time:
		change_state(State.JUMP)

func idle_state(delta):
	anim.play("idle")
	if is_on_floor():
		velocity = Vector2.ZERO
	if time_in_state >= idle_time:
		change_state(State.JUMP_PREP)

func jump_state(delta):
		if time_in_state <= 0.1:
		# Initial jump
			velocity = direction * jump_force
			anim.play("jump")
		else:
		# Apply gravity
			if is_on_floor():
				anim.play("idle")		
				velocity = Vector2.ZERO
		if is_on_floor() and time_in_state > 1:  # Small delay to ensure we've left the ground
			change_state(State.RELEASE_GAS)

var launched: bool = false
func release_gas_state(delta):
	velocity = Vector2.ZERO
	if time_in_state <= 0.1:
		if gas_particles.emitting == true:
			gas_particles.emitting = false
			gas_particles.restart()
		gas_particles.emitting = true
	if time_in_state >= gas_release_time:
		change_state(State.IDLE)
	if !launched:
		launch_spore()
		launched = true

func launch_spore():
	if spore_scene and player:
		var spore = spore_scene.instantiate()
		get_parent().get_parent().add_child(spore)
		spore.global_position = spore_spawn_point.global_position
		spore.set_target(player)

func change_state(new_state: State):
	if new_state == State.JUMP_PREP:
		var value = 1 if randi() % 2 == 0 else -1
		direction = Vector2(value, -1)	
	if new_state == State.JUMP:
		hurt_area.monitorable = true
	else:
		hurt_area.monitorable = false
		
	launched = false
	current_state = new_state
	jump_force = randf_range(150,250)
	time_in_state = 0.0
	idle_time = randf_range(2,5)
	jump_interval = randf_range(2,5)
	gas_release_time = randf_range(1,2)
	
	
func _on_player_detected():
	# This function would be called when the player enters the frog's detection area
	if current_state == State.IDLE:
		change_state(State.JUMP)

func _on_bounce_area_2d_area_entered(area):
		life -= 1
		sprite.hitting = true
		SoundManager.play_sound( "frog", 0.4, false)
		Pooler.get_pop().global_position = global_position
		if life <= 0:
			SoundManager.play_sound( "explosion", 0.1, false)
			Pooler.get_pop().global_position = global_position
			Pooler.get_gem().global_position = global_position
			queue_free()
