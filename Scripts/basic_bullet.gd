extends RigidBody2D

@export var speed = 200
@onready var flash :GPUParticles2D = $GPUParticles2D
@onready var sprite : Sprite2D = $Sprite2D
@onready var collision_inpact : GPUParticles2D = $ExplosionParticle
@onready var area2d : Area2D = $Area2D

signal hit_enemy

func _ready():
	linear_velocity = Vector2(randf_range(-140, 140),speed)
	flash.emitting = true


#this is the signal emit for hitting emey
#where is it connected to?
func _on_area_2d_area_entered(area):
	if area.is_in_group("enemy"):
		hit_enemy.emit()	
		
	for i in 8:
		i = i+1
		area2d.set_collision_layer_value(i, false)
		area2d.set_collision_mask_value(i, false)
	linear_velocity = Vector2.ZERO
	collision_inpact.emitting = true
	sprite.hide()
	await get_tree().create_timer(0.6).timeout
	queue_free()


func _on_area_2d_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	for i in 8:
		i = i+1
		area2d.set_collision_layer_value(i, false)
		area2d.set_collision_mask_value(i, false)
		
	linear_velocity = Vector2.ZERO
	collision_inpact.emitting = true
	sprite.hide()
	await get_tree().create_timer(0.6).timeout
	queue_free()


func _on_area_2d_body_entered(body):
	#print("hits floors...")
	for i in 8:
		i = i+1
		area2d.set_collision_layer_value(i, false)
		area2d.set_collision_mask_value(i, false)
	linear_velocity = Vector2.ZERO
	collision_inpact.emitting = true
	sprite.hide()
	await get_tree().create_timer(0.6).timeout
	queue_free()
