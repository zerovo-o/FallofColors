extends Node

# 红色调效果管理器
# 负责管理游戏中所有与红色调相关的视觉效果

var red_effect_active = false
var red_modulate: CanvasModulate = null

# 不同类型的节点颜色调整
const BACKGROUND_RED = Color(1.2, 0.3, 0.3, 1.0) 
const BLOCK_RED = Color(0.9, 0.5, 0.5, 0.6)
const ENEMY_RED = Color(0.5, 0.0, 0.0, 1.0) 

func _ready():
	# 初始化为默认状态
	red_effect_active = false
	if red_modulate != null:
		red_modulate.queue_free()
		red_modulate = null
	
	# 监听红宝石收集事件
	Pooler.gem_collected.connect(_on_gem_collected)

func _on_gem_collected(value: int):
	# 如果是红宝石（价值5个普通宝石）
	if value == 5:
		activate_red_effect()

# 激活红色调效果
func activate_red_effect():
	red_effect_active = true
	apply_scene_red_tint()

# 应用场景红色调
func apply_scene_red_tint():
	# 创建或更新场景着色效果
	if get_tree() == null:
		return
	var root = get_tree().root
	# 移除其他可能存在的调制效果
	remove_other_modulates()
	
	if red_modulate == null:
		red_modulate = CanvasModulate.new()
		red_modulate.name = "RedModulate"
		red_modulate.color = BACKGROUND_RED
		root.add_child(red_modulate)
	else:
		red_modulate.color = BACKGROUND_RED

# 移除其他调制效果
func remove_other_modulates():
	var root = get_tree().root
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
	red_effect_active = false
	# 移除红色调效果
	if red_modulate != null:
		if is_instance_valid(red_modulate):
			red_modulate.queue_free()
		red_modulate = null

# 更新特定类型节点的颜色
func update_node_colors(node_type: String, parent_node: Node):
	if not red_effect_active:
		return
	
	match node_type:
		"block":
			# 更新方块颜色
			_update_children_color(parent_node, BLOCK_RED)
		"enemy":
			# 更新敌人颜色
			_update_children_color(parent_node, ENEMY_RED)

# 递归更新子节点颜色
func _update_children_color(parent: Node, color: Color):
	for child in parent.get_children():
		# 跳过角色节点和特定方块节点
		if child.name == "Player" or child.name == "Spike" or child.name == "Spike_Block" :
			continue
			
		if child is Sprite2D:
			# 检查是否是紫色方块或平台，如果是则跳过
			if child.name == "PurpleBlock" or child.name == "PurplePlatform":
				continue
				
			child.modulate = color
		elif child.get_child_count() > 0:
			_update_children_color(child, color)