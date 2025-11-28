extends Node

# 绿色调效果管理器
# 负责管理游戏中所有与绿色调相关的视觉效果

var green_effect_active = false
var green_modulate: CanvasModulate = null

# 不同类型的节点颜色调整
const BACKGROUND_GREEN = Color(0.2, 1.2, 0.2, 1.0) 
const BLOCK_GREEN = Color(0.5, 0.9, 0.5, 0.6)
const ENEMY_GREEN = Color(0.0, 0.5, 0.0, 1.0) 

func _ready():
	# 初始化为默认状态
	green_effect_active = false
	if green_modulate != null:
		green_modulate.queue_free()
		green_modulate = null
	
	# 监听绿宝石收集事件
	Pooler.gem_collected.connect(_on_gem_collected)

func _on_gem_collected(value: int):
	# 如果是绿宝石（价值20个普通宝石）
	if value == 20:
		activate_green_effect()

# 激活绿色调效果
func activate_green_effect():
	green_effect_active = true
	apply_scene_green_tint()

# 应用场景绿色调
func apply_scene_green_tint():
	# 创建或更新场景着色效果
	if get_tree() == null:
		return
	var root = get_tree().root
	# 移除其他可能存在的调制效果
	remove_other_modulates()
	
	if green_modulate == null:
		green_modulate = CanvasModulate.new()
		green_modulate.name = "GreenModulate"
		green_modulate.color = BACKGROUND_GREEN
		root.add_child(green_modulate)
	else:
		green_modulate.color = BACKGROUND_GREEN

# 移除其他调制效果
func remove_other_modulates():
	var root = get_tree().root
	# 移除红色调制
	var red_modulate = root.get_node_or_null("RedModulate")
	if red_modulate != null:
		red_modulate.queue_free()
	# 移除黄色调制
	var yellow_modulate = root.get_node_or_null("YellowModulate")
	if yellow_modulate != null:
		yellow_modulate.queue_free()
	# 移除蓝调制
	var blue_modulate = root.get_node_or_null("BlueModulate")
	if blue_modulate != null:
		blue_modulate.queue_free()
	# 移除彩虹调制
	var rainbow_modulate = root.get_node_or_null("RainbowModulate")
	if rainbow_modulate != null:
		rainbow_modulate.queue_free()

# 重置场景颜色为原始颜色
func reset_scene_colors():
	green_effect_active = false
	# 移除绿色调效果
	if green_modulate != null:
		if is_instance_valid(green_modulate):
			green_modulate.queue_free()
		green_modulate = null

# 更新特定类型节点的颜色
func update_node_colors(node_type: String, parent_node: Node):
	if not green_effect_active:
		return
	
	match node_type:
		"block":
			# 更新方块颜色
			_update_children_color(parent_node, BLOCK_GREEN)
		"enemy":
			# 更新敌人颜色
			_update_children_color(parent_node, ENEMY_GREEN)

# 递归更新子节点颜色
func _update_children_color(parent: Node, color: Color):
	for child in parent.get_children():
		# 跳过角色节点和特定方块节点
		   var skip_names = [
			   "player", "spike", "spike_block",
			   "blockmountain", "block_mountain",
			   "blocksand", "block_sand",
			   "blocksand2", "block_sand2",
			   "blocktree1", "block_tree1",
			   "blocktree2", "block_tree2",
			   "blocktree3", "block_tree3",
			   "lavawall", "lava_wall",
			   "leafwall", "leaf_wall",
			   "leafwall2", "leaf_wall2",
			   "leafwall3", "leaf_wall3",
			   "leafwall4", "leaf_wall4",
			   "sandwall", "sand_wall",
			   "sandwall2", "sand_wall2",
			   "seawall", "sea_wall",
			   "seawall2", "sea_wall2"
		   ]
		   if skip_names.has(child.name.to_lower()):
			   continue
			
		   if child is Sprite2D:
			   # 跳过指定方块Sprite2D节点
			   if skip_names.has(child.name.to_lower()):
				   continue
			   # 检查是否是紫色方块或平台，如果是则跳过
			   if child.name == "PurpleBlock" or child.name == "PurplePlatform":
				   continue
			   child.modulate = color
		elif child.get_child_count() > 0:
			_update_children_color(child, color)