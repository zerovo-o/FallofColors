extends EnemyMain

enum State {IDLE, CHARGING, LAUNCHING}

@export var charge_time: float = 1.0
@export var cooldown_time: float = 3.0
@export var time_in_launch_state: float = 0.6
@export var detection_range: float = 6000
const  spore_scene: PackedScene = preload("res://Scenes/Enemy/spore.tscn")

var current_state: State = State.IDLE
var time_in_state: float = 0.0
var player: CharacterBody2D


@onready var sprite : spriteEffect = $Sprite2D
@onready var spore_spawn_point = $SporeSpawnPoint

func _ready():
	player = get_node("/root/Master/Player")  # Adjust this path to your scene structure

func _process(delta):
	time_in_state += delta
	
	match current_state:
		State.IDLE:
			idle_state()
		State.CHARGING:
			charging_state()
		State.LAUNCHING:
			launching_state()

func idle_state():
	if player and position.distance_squared_to(player.position) <= detection_range:
		change_state(State.CHARGING)

func charging_state():
	if time_in_state >= charge_time:
		change_state(State.LAUNCHING)
var launched : bool = false
func launching_state():
	if !launched:
		launch_spore()
		launched = true
	if time_in_state > time_in_launch_state:
		change_state(State.IDLE)

func launch_spore():
	if spore_scene and player:
		SoundManager.play_sound( "shoot_spore", 0.1, false)
		var spore = spore_scene.instantiate()
		add_child(spore)
		spore.global_position = spore_spawn_point.global_position
		spore.set_target(player)

func change_state(new_state: State):
	current_state = new_state
	time_in_state = 0.0
	launched = false
	match new_state:
		State.IDLE:
			$AnimationPlayer.play("idle")
		State.CHARGING:
			$AnimationPlayer.play("charging")
		State.LAUNCHING:
			$AnimationPlayer.play("launching")


func _on_hurt_area_2d_area_entered(area):
	pass


func _on_bounce_area_2d_area_entered(area):
		life -= 1
		sprite.hitting = true
		SoundManager.play_sound( "plant", 1, false)
		Pooler.get_pop().global_position = global_position
		if life <= 0:
			SoundManager.play_sound( "explosion", 0.1, false)
			Pooler.get_pop().global_position = global_position
			Pooler.get_gem().global_position = global_position
			queue_free()
