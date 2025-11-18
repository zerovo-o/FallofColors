extends CharacterBody2D
class_name PlayerMasterAndMover

signal calculate_bonus(amount)
@onready var jumpmove : JumpAndMove = $JumpAndMove
@onready var bulletspawn : BulletSpawner = $BulletSpawner
@onready var UI : MainUI = $CanvasLayer/MainUI
@onready var sprite : Sprite2D = $Sprite2D
@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var camera_effect : CameraEffects = $Camera2D
@onready var combo_ctrl : ComboController = $JumpAndMove/ComboTracker

@onready var deathparticle : GPUParticles2D = $deathparticle


@export var areas_to_turnoff_on_death : Array[Area2D]

@export var bullet_holder : Node2D
@export var life_max : int = 5

@export var bullet_count : int = 1

func apply_upgrade(upgrade : Upgrade):
	SoundManager.play_sound( "powerup", 1, false)
	HitStpo.start_hitstop(0.5)
	match  upgrade.type:
		Upgrade.UpgradeType.MORE_LIFE:
			life_max += 2
			set_life_current(life_max)
		Upgrade.UpgradeType.MORE_BULLETS:
			jumpmove.max_air_jump += 2
			jumpmove.set_air_jumps_left(jumpmove.max_air_jump)
		Upgrade.UpgradeType.BIGGER_BULLETS:
			bullet_count += 2
		Upgrade.UpgradeType.NO_BOUNCE:
			jumpmove.bounce_control_lock_time *= 0.5
		Upgrade.UpgradeType.SLOW_WALL:
			jumpmove.wall_slide_speed *= 0.5


var _life_current = 5

func get_current_life() -> int:
	return _life_current

signal dead
func set_life_current(value : int) -> void:
	if value < get_current_life():
		camera_effect.add_trauma(0.1)
	if value <= 0:
		deathparticle.emitting = true
		#where does this connect to?
		#master
		dead.emit()
		jumpmove.is_dead = true
		
		
	_life_current = clamp(value, 0, life_max)
	UI.display_life_count(get_current_life(), life_max)
	
	#who does this connect to?
signal take_damage()

func _ready():
	jumpmove.firingbullet.connect(bulletspawn.spawn_bullet)
	jumpmove.ammo_count_changing.connect(UI.display_bullet_count)
	bulletspawn.restock_and_combo.connect(jumpmove.reset_air_jumps)
	jumpmove.adding_to_combo.connect(combo_ctrl.add_one_combo)
	jumpmove.reset_combo.connect(combo_ctrl.reset_combo)
	
	
	#SHOULDBNT BE HARD CODED
func start_game():
	sprite.show()
	jumpmove.can_move = true
	set_life_current(life_max)
	UI.display_bullet_count(4,4)
	await get_tree().create_timer(1.4).timeout
	
	UI.show()
	UI.start_fade_in()
	
func _physics_process(delta):
	if global_position.y > camera_effect.global_position.y:
		camera_effect.target = self
	
	if global_position. x < -20:
		global_position.x = -20
		velocity.x = 0
	elif global_position.x > 245:
		global_position.x = 245
		velocity.x = 0
		
