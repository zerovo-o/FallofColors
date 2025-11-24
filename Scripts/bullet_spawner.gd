extends Node2D
class_name BulletSpawner
const basic_bullet : PackedScene = preload("res://Scenes/bullets/basic_bullet.tscn")

@export var player : PlayerMasterAndMover 
@export var bullet_flash : Sprite2D
signal restock_and_combo
@onready var bullet_anim : AnimationPlayer = $"../bulletflash/AnimationPlayer"

func spawn_bullet():
	SoundManager.play_sound("shoot", 1,false)
	bullet_anim.stop()
	bullet_anim.play("flash")
	for i in player.bullet_count:
		var temp = basic_bullet.instantiate()
		temp.hit_enemy.connect(RestockAmmoAddCombo)
		temp.global_position = global_position + Vector2(randi_range(-3,3),0)
		player.bullet_holder.add_child(temp) 

func RestockAmmoAddCombo():
	#connected FROM Bullet  
	#connected TO parent, then goes to UI
	restock_and_combo.emit()
