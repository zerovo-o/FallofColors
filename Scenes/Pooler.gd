extends Node2D
class_name obj_pool

var gem_pool = []
var pop_pool = []

const pop_effect : PackedScene= preload("res://Scenes/Enemy/pop_effect.tscn")
const gem : PackedScene = preload("res://Scenes/Enemy/gem.tscn")
signal gem_collected(amount)

signal start_boss
signal end_boss

func _ready():
	start_off_object(50,pop_effect,pop_pool)
	start_off_object(100, gem, gem_pool)

func start_off_object(pool_size: int, object : PackedScene, pool : Array):
	for i in range(pool_size):
		var obj = object.instantiate()
		obj.set_process(false)
		obj.set_physics_process(false)
		obj.hide()
		obj.global_position = Vector2(1000,1000)
		add_child(obj)
		pool.append(obj)

func get_pop():
	if pop_pool.size() > 0:
		var obj = pop_pool.pop_front()
		if obj != null and is_instance_valid(obj):
			obj.set_process(true)
			obj.set_physics_process(true)
			obj.show()
			return obj
		else:
			# 如果对象无效，则创建新实例
			return pop_effect.instantiate()
	else:
		return pop_effect.instantiate()
	
func return_pop(obj):
	if obj != null and is_instance_valid(obj):
		obj.set_process(false)
		obj.set_physics_process(false)
		obj.hide()
		pop_pool.append(obj)

func get_gem():
	if gem_pool.size() > 0:
		var obj = gem_pool.pop_front()
		if obj != null and is_instance_valid(obj):
			obj.set_process(true)
			obj.set_physics_process(true)
			obj.show()
			return obj
		else:
			# 如果对象无效，则创建新实例
			return gem.instantiate()
	else:
		return gem.instantiate()
	
func return_gem(obj):
	if obj != null and is_instance_valid(obj):
		obj.global_position = Vector2(1000,1000)
		obj.set_process(false)
		obj.set_physics_process(false)
		obj.hide()
		gem_pool.append(obj)
