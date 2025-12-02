extends Node2D
class_name Map_Spawner

# 这个脚本专门负责"把字符 → 实体"的那一步。
# MapDecider 会发射 spawning 信号给我们，告诉我们"在某个像素点放一个字符代表的东西"，
# 我们这边就把对应的 PackedScene 实例化挂到场景里。
# 关键改动（相对最初版）：
# 1) 新增 set_spawn_roots(...)，让 Master 在"按段生成"时，把所有地形/敌人挂到该段容器下。
#    这样整段删除时，不会漏节点。
# 2) 砖墙去掉了"每块挂一个随机脚本"的方式，改为生成时随机 frame（更省资源）。

const block_wall : PackedScene = preload("res://Scenes/Blocks/wall_block.tscn")
const lava_wall : PackedScene = preload("res://Scenes/Blocks/lava_wall.tscn")
const sand_wall : PackedScene = preload("res://Scenes/Blocks/sand_wall.tscn")
const sand_wall2 : PackedScene = preload("res://Scenes/Blocks/sand_wall2.tscn")
const leaf_wall : PackedScene = preload("res://Scenes/Blocks/leaf_wall.tscn")
const leaf_wall2 : PackedScene = preload("res://Scenes/Blocks/leaf_wall2.tscn")
const leaf_wall3 : PackedScene = preload("res://Scenes/Blocks/leaf_wall3.tscn")
const leaf_wall4 : PackedScene = preload("res://Scenes/Blocks/leaf_wall4.tscn")
const sea_wall : PackedScene = preload("res://Scenes/Blocks/sea_wall.tscn")
const sea_wall2 : PackedScene = preload("res://Scenes/Blocks/sea_wall2.tscn")
const block_mountain : PackedScene = preload("res://Scenes/Blocks/block_mountain.tscn")
const block_sand : PackedScene = preload("res://Scenes/Blocks/block_sand1.tscn")
const block_sand2 : PackedScene = preload("res://Scenes/Blocks/block_sand2.tscn")
const block_tree1 : PackedScene = preload("res://Scenes/Blocks/block_tree1.tscn")
const block_tree2 : PackedScene = preload("res://Scenes/Blocks/block_tree2.tscn")
const block_tree3 : PackedScene = preload("res://Scenes/Blocks/block_tree3.tscn")
const block_sand3 : PackedScene = preload("res://Scenes/Blocks/block_sand3.tscn")
const block_sea1 : PackedScene = preload("res://Scenes/Blocks/block_sea1.tscn")
const block_sea2 : PackedScene = preload("res://Scenes/Blocks/block_sea2.tscn")
const block_lava1 : PackedScene = preload("res://Scenes/Blocks/block_lava1.tscn")
const block_lava2 : PackedScene = preload("res://Scenes/Blocks/block_lava2.tscn")
const block_lava3 : PackedScene = preload("res://Scenes/Blocks/block_lava3.tscn")
const block_wood1 : PackedScene = preload("res://Scenes/Blocks/block_wood1.tscn")
const block_wood2 : PackedScene = preload("res://Scenes/Blocks/block_wood2.tscn")

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
const red_gem : PackedScene = preload("res://Scenes/colorGem/red_gem.tscn")
const yellow_gem : PackedScene = preload("res://Scenes/colorGem/yellow_gem.tscn")
const blue_gem : PackedScene = preload("res://Scenes/colorGem/blue_gem.tscn")
const rainbow_gem : PackedScene = preload("res://Scenes/colorGem/rainbow_gem.tscn")
const green_gem : PackedScene = preload("res://Scenes/colorGem/green_gem.tscn")


#狗儿
const enemy_dog : PackedScene = preload("res://Scenes/Enemy/dog.tscn")


# 老的敌人统一挂在这个节点下（如果没覆盖的话）
@onready var enemy_node : Node2D = $"../EnemyHolder"
@onready var red_effect_manager = $"../Scripts/colorGem/RedEffectManager"
@onready var yellow_effect_manager = $"../Scripts/colorGem/YellowEffectManager"
@onready var blue_effect_manager = $"../Scripts/colorGem/BlueEffectManager"
@onready var rainbow_full_effect_manager = $"../Scripts/colorGem/RainbowFullEffectManager"
@onready var green_effect_manager = $"../Scripts/colorGem/GreenEffectManager"

# ========= 按段容器覆盖（关键） =========
# Master 生成一段时，会建一个 Segment_X 节点：
# - Tiles: 所有地形/PU/Boss 等静态东西
# - Enemies: 所有敌人
# 我们这里允许把"生成目标父节点"改成这两个，从而实现"整段删掉不留垃圾"。

var _static_root: Node = null
var _enemy_root_override: Node = null

func set_spawn_roots(static_root: Node = null, enemy_root: Node = null) -> void:
	# Master 在建段前会调这个，把目标父节点暂时切换到段容器
	_static_root = static_root
	_enemy_root_override = enemy_root

func _static_parent() -> Node:
	# 没有覆盖就用自己（兼容老逻辑）
	return _static_root if _static_root else self

func _enemy_parent() -> Node:
	return _enemy_root_override if _enemy_root_override else enemy_node

# ========= 旧开场用的"起始墙"工具（可不用） =========
# 注意：它还是用 add_child 加到本节点下，不跟着段容器。
# 如果未来还想用它，也建议改成 _static_parent().add_child(temp) 以便随段清理。
func set_starting_row():
	var offset = 0
	for i in 60:
		offset -= 16
		var temp : StaticBody2D = block_wall.instantiate()
		temp.global_position = Vector2i(offset,80)
		add_child(temp)

# ========= 字符 → 实体 =========
func spawn_block(in_shape : String, in_pos : Vector2i ):
	var tempshape
	var node_type = ""
	match in_shape:
		
		"|":
			# 砖墙：生成时直接随机一下 Sprite2D 的帧，替代"每块一个随机脚本"的做法（更省内存/初始化）
			tempshape = block_wall.instantiate()
			tempshape.global_position = in_pos
			var s := tempshape.get_node_or_null("Sprite2D") as Sprite2D
			if s and s.hframes > 1:
				s.frame = randi() % s.hframes
			_static_parent().add_child(tempshape)
			node_type = "block"
		"x":
			# 空，不生成
			pass
		"_":
			tempshape = block_floor.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		".":
			tempshape = block_break_floor.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"^":
			# 弹出刺：有伤害信号，直接连接到 Master 的 hurt_player（MapSpawner 的父节点就是 Master）
			tempshape = block_spike_trap.instantiate()
			tempshape.hurt_player.connect(get_parent().hurt_player)
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"*":
			tempshape = block_spike_static.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"b":
			tempshape = enemy_bat.instantiate()
			tempshape.global_position = in_pos
			_enemy_parent().add_child(tempshape)
			node_type = "enemy"
		"t":
			tempshape = enemy_turtle.instantiate()
			tempshape.global_position = in_pos
			_enemy_parent().add_child(tempshape)
			node_type = "enemy"
		"B":
			tempshape = boss.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "enemy"
		"T":
			tempshape = boss_trigger.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
		"F":
			tempshape = enemy_frog.instantiate()
			tempshape.global_position = in_pos
			_enemy_parent().add_child(tempshape)
			node_type = "enemy"
		"#": 
			tempshape = big_fan.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"S":
			tempshape = enemy_plant.instantiate()
			tempshape.global_position = in_pos
			_enemy_parent().add_child(tempshape)
			node_type = "enemy"
		"1":
			tempshape = PUSpread.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
		"2":
			tempshape = PUAim.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
		"3":
			tempshape = PUBounce.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
		"4":
			tempshape = PUSBullets.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
		"5":
			tempshape = PULife.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
		"6":
			tempshape = PUWall.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
		"r":  # 红色宝石
			tempshape = red_gem.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "gem"
		"y":  # 黄色宝石
			tempshape = yellow_gem.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "gem"
		"l":  # 蓝色宝石
			tempshape = blue_gem.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "gem"
		"p":  # 彩色宝石
			tempshape = rainbow_gem.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "gem"
		"g":  # 绿色宝石
			tempshape = green_gem.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "gem"
		"O":
			# 熔岩墙体方块（静态）
			tempshape = lava_wall.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"z":
			# 沙墙体方块（静态）
			tempshape = sand_wall.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"Z":
			# 沙墙体方块2（静态）
			tempshape = sand_wall2.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"c":
			# 叶墙体方块1（静态）
			tempshape = leaf_wall.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"C":
			# 叶墙体方块2（静态）
			tempshape = leaf_wall2.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"v":
			# 叶墙体方块3（静态）
			tempshape = leaf_wall3.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"V":
			# 叶墙体方块4（静态）
			tempshape = leaf_wall4.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"n":
			# 海墙体方块1（静态）
			tempshape = sea_wall.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"N":
			# 海墙体方块2（静态）
			tempshape = sea_wall2.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"M":
			# 山体装饰（不带碰撞）
			tempshape = block_mountain.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "decor"
		"k":
			# 沙子装饰 1（带碰撞）
			tempshape = block_sand.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"K":
			# 沙子装饰 2（带碰撞）
			tempshape = block_sand2.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"h":
			# 沙子装饰 3（带碰撞）
			tempshape = block_sand3.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"		
		"J":
			# 树木装饰 1（带碰撞）
			tempshape = block_tree1.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"j":
			# 树木装饰 2（带碰撞）
			tempshape = block_tree2.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"H":
			# 树木装饰 3（带碰撞）	
			tempshape = block_tree3.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"d":
			# 海洋装饰 1（带碰撞）
			tempshape = block_sea1.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"D":
			# 海洋装饰 2（带碰撞）		
			tempshape = block_sea2.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"a":
			# 熔岩装饰 1（带碰撞）
			tempshape = block_lava1.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"A":
			# 熔岩装饰 2（带碰撞）
			tempshape = block_lava2.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"
		"Q":
			# 熔岩装饰 3（带碰撞）
			tempshape = block_lava3.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"	
		"W":
			# 木头装饰 1（带碰撞）
			tempshape = block_wood1.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"	
		"w":
			# 木头装饰 2（带碰撞）
			tempshape = block_wood2.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "block"	
#狗儿～
		"G":
			var tempshape_local = enemy_dog.instantiate()
			tempshape_local.global_position = in_pos
			_enemy_parent().add_child(tempshape_local)
			node_type = "enemy"
			#触碰后播放结束视频
			if tempshape_local.has_signal("touched_player"):
				tempshape_local.touched_player.connect(get_parent()._on_dog_touched_player)
			tempshape = tempshape_local



	# 如果红色调效果已激活，更新节点颜色
	if node_type != "" and red_effect_manager != null:
		red_effect_manager.update_node_colors(node_type, tempshape)
		
	# 如果暖色调效果已激活，更新节点颜色
	if node_type != "" and yellow_effect_manager != null:
		yellow_effect_manager.update_node_colors(node_type, tempshape)
		
	# 如果蓝色调效果已激活，更新节点颜色
	if node_type != "" and blue_effect_manager != null:
		blue_effect_manager.update_node_colors(node_type, tempshape)
		
	# 如果完整彩虹效果已激活，更新节点颜色
	if node_type != "" and rainbow_full_effect_manager != null:
		rainbow_full_effect_manager.update_node_colors(node_type, tempshape)
		
	# 如果绿色调效果已激活，更新节点颜色
	if node_type != "" and green_effect_manager != null:
		green_effect_manager.update_node_colors(node_type, tempshape)
