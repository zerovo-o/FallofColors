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
const block_barrier : PackedScene = preload("res://Scenes/Blocks/barrier_block.tscn") 

const block_floor : PackedScene = preload("res://Scenes/Blocks/floor_block.tscn")
const block_break_floor : PackedScene = preload("res://Scenes/Blocks/breakable_block.tscn")
const block_spike_trap : PackedScene = preload("res://Scenes/Enemy/spike.tscn")
const enemy_bat : PackedScene = preload("res://Scenes/Enemy/bat.tscn")
const block_spike_static : PackedScene = preload("res://Scenes/Blocks/spike_block.tscn")
const enemy_turtle : PackedScene = preload("res://Scenes/Enemy/turtle.tscn")
const enemy_blob : PackedScene = preload("res://Scenes/Enemy/blob.tscn")
const enemy_frog : PackedScene = preload("res://Scenes/Enemy/frog.tscn")
const enemy_plant : PackedScene = preload("res://Scenes/Enemy/spore_shooter.tscn")

const Background_lava : PackedScene = preload("res://Scenes/Blocks/Background_lava.tscn")
const Background_lava2 : PackedScene = preload("res://Scenes/Blocks/Background_lava2.tscn")
const Background_sand : PackedScene = preload("res://Scenes/Blocks/Background_sand.tscn")
const Background_sea : PackedScene = preload("res://Scenes/Blocks/Background_sea.tscn")
const Background_wood : PackedScene = preload("res://Scenes/Blocks/Background_wood.tscn")


const enemy_bee : PackedScene = preload("res://Scenes/Enemy/bee.tscn")
const enemy_pig : PackedScene = preload("res://Scenes/Enemy/pig.tscn")
const enemy_ghost : PackedScene = preload("res://Scenes/Enemy/ghost.tscn")
const enemy_slime : PackedScene = preload("res://Scenes/Enemy/slime.tscn")
const enemy_scorpion : PackedScene = preload("res://Scenes/Enemy/scorpion.tscn")
const enemy_flyingfish : PackedScene = preload("res://Scenes/Enemy/flyingfish.tscn")
const enemy_nautilus : PackedScene = preload("res://Scenes/Enemy/nautilus.tscn")
const enemy_lavabat : PackedScene = preload("res://Scenes/Enemy/lavabat.tscn")
const enemy_bunny : PackedScene = preload("res://Scenes/Enemy/bunny.tscn")

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


#1206 canvas复用函数
# 确保父节点下存在指定 CanvasLayer（若无则创建）
func _ensure_canvas_layer(parent: Node, name: String, layer_idx: int) -> CanvasLayer:
	var layer := parent.get_node_or_null(name) as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = name
		layer.layer = layer_idx              # 高于覆盖层（覆盖层一般用 10）
		layer.follow_viewport_enabled = true # 世界坐标正确跟随相机
		parent.add_child(layer)
	return layer

# 在指定 CanvasLayer 下实例化一个“免疫变色”的 Node2D
func _spawn_immune_on_layer(scene: PackedScene, pos: Vector2i, layer_parent: Node, layer_name: String, layer_idx: int, extra_group: String = "") -> Node2D:
	var n := scene.instantiate() as Node2D
	n.global_position = pos
	n.add_to_group("NoRainbowTint")
	if extra_group != "":
		n.add_to_group(extra_group)
	n.set_meta("no_rainbow_tint", true)

	var layer := _ensure_canvas_layer(layer_parent, layer_name, layer_idx)
	var prev := n.global_position
	layer.add_child(n)            # 换父到 CanvasLayer
	n.global_position = prev      # 还原世界坐标
	return n

# 全局：宝石/回血 → Master 下 GemLayer(layer=40)，不随段删除
func _spawn_on_gem_layer(scene: PackedScene, pos: Vector2i) -> Node2D:
	return _spawn_immune_on_layer(scene, pos, get_parent(), "GemLayer", 40, "gem_ignore_modulate")

# 段内：静态物（如 ^）→ 当前段 Tiles 下 StaticHighLayer(layer=40)，随段删除
func _spawn_on_segment_static_high(scene: PackedScene, pos: Vector2i) -> Node2D:
	return _spawn_immune_on_layer(scene, pos, _static_parent(), "StaticHighLayer", 40)

# 段内：敌人 → 当前段 Enemies 下 EnemyHighLayer(layer=40)，随段删除
func _spawn_on_segment_enemy_high(scene: PackedScene, pos: Vector2i) -> Node2D:
	return _spawn_immune_on_layer(scene, pos, _enemy_parent(), "EnemyHighLayer", 40)












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
			var trap := _spawn_on_segment_static_high(block_spike_trap, in_pos)
			if trap.has_signal("hurt_player"):
				trap.hurt_player.connect(get_parent().hurt_player)
			tempshape = trap

		
		"*":
			tempshape = _spawn_on_segment_static_high(block_spike_static, in_pos)


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

		# 新的怪物
		"e": tempshape = _spawn_on_segment_enemy_high(enemy_bee, in_pos);          node_type = "enemy"
		"P": tempshape = _spawn_on_segment_enemy_high(enemy_pig, in_pos);          node_type = "enemy"
		"o": tempshape = _spawn_on_segment_enemy_high(enemy_ghost, in_pos);        node_type = "enemy"
		"s": tempshape = _spawn_on_segment_enemy_high(enemy_slime, in_pos);        node_type = "enemy"
		"X": tempshape = _spawn_on_segment_enemy_high(enemy_scorpion, in_pos);     node_type = "enemy"
		"f": tempshape = _spawn_on_segment_enemy_high(enemy_flyingfish, in_pos);   node_type = "enemy"
		"u": tempshape = _spawn_on_segment_enemy_high(enemy_nautilus, in_pos);     node_type = "enemy"
		"R": tempshape = _spawn_on_segment_enemy_high(enemy_lavabat, in_pos);      node_type = "enemy"
		"U": tempshape = _spawn_on_segment_enemy_high(enemy_bunny, in_pos);        node_type = "enemy"


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
			# 回血 PU：忽略局部着色，抬到高层，避免被覆盖层遮色
			var pu_local: Node2D = PULife.instantiate() as Node2D
			pu_local.global_position = in_pos
			# 标记：让 EffectManager 的局部调色跳过（与宝石/狗同款）
			pu_local.add_to_group("NoRainbowTint")
			pu_local.add_to_group("pickup_ignore_modulate")  # 可选，便于自定义筛选
			pu_local.set_meta("no_rainbow_tint", true)
			# 抬层：放到 Master 下的 GemLayer（layer=40，高于覆盖层 layer=10）
			var master: Node = get_parent()
			var gem_layer: CanvasLayer = master.get_node_or_null("GemLayer") as CanvasLayer
			if gem_layer == null:
				var cl := CanvasLayer.new()
				cl.name = "GemLayer"
				cl.layer = 40
				cl.follow_viewport_enabled = true
				master.add_child(cl)
				gem_layer = cl
			# 保持世界坐标不跳变
			var prev_pos: Vector2 = pu_local.global_position
			gem_layer.add_child(pu_local)
			pu_local.global_position = prev_pos
			tempshape = pu_local
			
			
			
		"6":
			tempshape = PUWall.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			
			
			
		# 红/黄/蓝/绿宝石
		"r": tempshape = _spawn_on_gem_layer(red_gem, in_pos);    node_type = "gem"
		"y": tempshape = _spawn_on_gem_layer(yellow_gem, in_pos); node_type = "gem"
		"l": tempshape = _spawn_on_gem_layer(blue_gem, in_pos);   node_type = "gem"
		"g": tempshape = _spawn_on_gem_layer(green_gem, in_pos);  node_type = "gem"
			
		# 彩虹宝石
		"p": tempshape = _spawn_on_gem_layer(rainbow_gem, in_pos); node_type = "gem"
		
		
		"O": tempshape = _spawn_on_segment_static_high(lava_wall, in_pos)
		"z": tempshape = _spawn_on_segment_static_high(sand_wall, in_pos)
		"Z": tempshape = _spawn_on_segment_static_high(sand_wall2, in_pos)
		"c": tempshape = _spawn_on_segment_static_high(leaf_wall, in_pos)
		"C": tempshape = _spawn_on_segment_static_high(leaf_wall2, in_pos)
		"v": tempshape = _spawn_on_segment_static_high(leaf_wall3, in_pos)
		"V": tempshape = _spawn_on_segment_static_high(leaf_wall4, in_pos)
		"n": tempshape = _spawn_on_segment_static_high(sea_wall, in_pos)
		"N": tempshape = _spawn_on_segment_static_high(sea_wall2, in_pos)
		"M": tempshape = _spawn_on_segment_static_high(block_mountain, in_pos)
		"k": tempshape = _spawn_on_segment_static_high(block_sand, in_pos)
		"K": tempshape = _spawn_on_segment_static_high(block_sand2, in_pos)
		"h": tempshape = _spawn_on_segment_static_high(block_sand3, in_pos)
		"J": tempshape = _spawn_on_segment_static_high(block_tree1, in_pos)
		"j": tempshape = _spawn_on_segment_static_high(block_tree2, in_pos)
		"H": tempshape = _spawn_on_segment_static_high(block_tree3, in_pos)
		"d": tempshape = _spawn_on_segment_static_high(block_sea1, in_pos)
		"D": tempshape = _spawn_on_segment_static_high(block_sea2, in_pos)
		"a": tempshape = _spawn_on_segment_static_high(block_lava1, in_pos)
		"A": tempshape = _spawn_on_segment_static_high(block_lava2, in_pos)
		"Q": tempshape = _spawn_on_segment_static_high(block_lava3, in_pos)
		"W": tempshape = _spawn_on_segment_static_high(block_wood1, in_pos)
		"w": tempshape = _spawn_on_segment_static_high(block_wood2, in_pos)
		"+": tempshape = _spawn_on_segment_static_high(block_barrier, in_pos)



# 背景实体
		"@":
			# 背景熔岩 1（无碰撞）
			tempshape = Background_lava.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "background"
		"$":
			# 背景熔岩 2（无碰撞）
			tempshape = Background_lava2.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "background"
		"%":
			# 背景沙地（无碰撞）
			tempshape = Background_sand.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "background"
		"&":
			# 背景海洋（无碰撞）
			tempshape = Background_sea.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "background"
		"q":
			# 背景木材（无碰撞）
			tempshape = Background_wood.instantiate()
			tempshape.global_position = in_pos
			_static_parent().add_child(tempshape)
			node_type = "background"

# 狗儿～
		"G":
			# 实例化狗（显式类型，方便后续使用 global_position）
			var tempshape_local: Node2D = enemy_dog.instantiate() as Node2D
			tempshape_local.global_position = in_pos

			# 触碰后播放结束视频
			if tempshape_local.has_signal("touched_player"):
				tempshape_local.touched_player.connect(get_parent()._on_dog_touched_player)

			# MOD: 不参与彩虹期“局部着色”——分组与元数据双重标记，管理器会跳过
			tempshape_local.add_to_group("NoRainbowTint")
			tempshape_local.set_meta("no_rainbow_tint", true)

			# MOD: 不被“全屏覆盖层”染色——把狗放到更高的 CanvasLayer（绘制顺序更靠前）
			# 注意：这会让狗不在段容器内，段被删除时狗不会随段清理（终点狗一般可接受）
			var master: Node = get_parent()
			var dog_layer: CanvasLayer = master.get_node_or_null("DogLayer") as CanvasLayer
			if dog_layer == null:
				var cl: CanvasLayer = CanvasLayer.new()
				cl.name = "DogLayer"
				cl.layer = 50  # 高于覆盖层使用的层（确保画在覆盖层之上）
				cl.follow_viewport_enabled = true  # Godot 4：跟随视口，保持世界坐标运动
				master.add_child(cl)
				dog_layer = cl

			# 记录并还原世界坐标，防止换父节点导致位置跳变（显式类型，避免推断报错）
			var prev_pos: Vector2 = tempshape_local.global_position
			dog_layer.add_child(tempshape_local)
			tempshape_local.global_position = prev_pos

			# 保持原有行为：返回该实例和类型
			node_type = "enemy"
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
