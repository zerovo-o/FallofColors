extends Node2D

class_name Map_Spawner

const block_wall : PackedScene = preload("res://Scenes/Blocks/wall_block.tscn")
const block_floor : PackedScene = preload("res://Scenes/Blocks/floor_block.tscn")
const block_break_floor : PackedScene = preload("res://Scenes/Blocks/breakable_block.tscn")
const block_spike_trap : PackedScene = preload("res://Scenes/Enemy/spike.tscn")
const enemy_bat : PackedScene = preload("res://Scenes/Enemy/bat.tscn")
const block_spike_static : PackedScene = preload("res://Scenes/Blocks/spike_block.tscn")
const enemy_turtle : PackedScene = preload("res://Scenes/Enemy/turtle.tscn")
const enemy_blob : PackedScene = preload("res://Scenes/Enemy/blob.tscn")
const enemy_frog : PackedScene = preload("res://Scenes/Enemy/frog.tscn")
const enemy_plant : PackedScene = preload("res://Scenes/Enemy/spore_shooter.tscn")

const big_fan : PackedScene = preload("res://Scenes/Blocks/bigfan.tscn")

const boss : PackedScene = preload("res://Scenes/Enemy/boss_1.tscn")
const boss_trigger : PackedScene = preload("res://Scenes/boss_trigger.tscn")

const PUSpread : PackedScene = preload("res://Scenes/PU - BulletSpread.tscn")
const PUAim : PackedScene = preload("res://Scenes/PU - BetterAim.tscn")
const PUBounce : PackedScene = preload("res://Scenes/PU - LessBounce.tscn")
const PUSBullets: PackedScene = preload("res://Scenes/PU - MoreBullets.tscn")
const PULife : PackedScene = preload("res://Scenes/PU - MoreLife.tscn")
const PUWall : PackedScene = preload("res://Scenes/PU - SlowerWallSlide.tscn")



@onready var enemy_node : Node2D = $"../EnemyHolder"

func set_starting_row():
	var offset = 0
	for i in 60:
		offset -= 16
		var temp : StaticBody2D
		temp = block_wall.instantiate()
		temp.global_position = Vector2i(offset,80)
		add_child(temp)

func spawn_block(in_shape : String, in_pos : Vector2i ):
	var tempshape 
	match in_shape:
		"|":
			tempshape = block_wall.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		"x":
			pass
		"_":
			tempshape = block_floor.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		".":
			tempshape = block_break_floor.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		"^":
			tempshape = block_spike_trap.instantiate()
			tempshape.hurt_player.connect(get_parent().hurt_player)
			tempshape.global_position = in_pos
			add_child(tempshape)
		"*":
			tempshape = block_spike_static.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		"b":
			tempshape = enemy_bat.instantiate()
			tempshape.global_position = in_pos
			enemy_node.add_child(tempshape)
		"t":
			tempshape = enemy_turtle.instantiate()
			tempshape.global_position = in_pos
			enemy_node.add_child(tempshape)
		"B":
			tempshape = boss.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		"T":
			tempshape = boss_trigger.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		"F":
			tempshape = enemy_frog.instantiate()
			tempshape.global_position = in_pos
			enemy_node.add_child(tempshape)
		"#": 
			tempshape = big_fan.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		"S":
			tempshape = enemy_plant.instantiate()
			tempshape.global_position = in_pos
			enemy_node.add_child(tempshape)
		"1":
			tempshape = PUSpread.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		"2":
			tempshape = PUAim.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		"3":
			tempshape = PUBounce.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		"4":
			tempshape = PUSBullets.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		"5":
			tempshape = PULife.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		"6":
			tempshape = PUWall.instantiate()
			tempshape.global_position = in_pos
			add_child(tempshape)
		
			
